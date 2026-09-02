use cssparser::Parser;
use markup5ever::{expanded_name, local_name, ns};

use crate::document::AcquiredNodes;
use crate::element::{ElementTrait, set_attribute};
use crate::error::*;
use crate::node::{CascadedValues, Node};
use crate::parse_identifiers;
use crate::parsers::{NumberOptionalNumber, Parse, ParseValue};
use crate::properties::ColorInterpolationFilters;
use crate::rect::IRect;
use crate::rsvg_log;
use crate::session::Session;
use crate::surface_utils::{
    ImageSurfaceDataExt, Pixel, PixelOps,
    shared_surface::{ExclusiveImageSurface, SurfaceType},
};
use crate::util::clamp;
use crate::xml::Attributes;

use std::cell::RefCell;
use std::fs::File;
use std::io::{BufWriter, Write};
use std::path::PathBuf;

use super::bounds::BoundsBuilder;
use super::context::{FilterContext, FilterOutput};
use super::{
    FilterEffect, FilterError, FilterResolveError, InputRequirements, Primitive, PrimitiveParams,
    ResolvedPrimitive,
};

// ---------------------------------------------------------------------------
// feTurbulence kernel boundary capture (diagnostic only).
//
// Controlled by the KSVG_TURB_CAPTURE environment variable holding the path of
// the dump file (created/truncated per process). When set, `render()` records
// the full kernel input state once per filter render, and `turbulence()` appends
// one record per (pixel, color channel) kernel call containing the exact input
// arguments (point, tile coords, post-stitch base frequency, per-octave lattice
// coordinates / stitch wrap state / raw noise result / running sum). The dump is
// write-only: nothing is read back into the computation, so the rendered result
// is unchanged by the instrumentation. This is the librsvg-side instrumentation
// for the KSVG feTurbulence kernel-parity experiment.
// ---------------------------------------------------------------------------
#[allow(dead_code)]
mod capture_dump {
    use super::*;
    use crate::transform::Transform;

    pub const MAGIC: &[u8; 8] = b"KSVGTURB";
    const VERSION: u32 = 1;
    pub const MAX_CAPTURE_OCTAVES: usize = 9;

    thread_local! {
        static STATE: RefCell<Option<State>> = const { RefCell::new(None) };
    }

    struct State {
        buf: Vec<u8>,
        file: Option<BufWriter<File>>,
    }

    /// Whether a capture file was successfully opened (KSVG_TURB_CAPTURE set).
    pub fn is_active() -> bool {
        STATE.with(|s| s.borrow().is_some())
    }

    fn with<T>(f: impl for<'a> FnOnce(&'a mut Option<State>) -> T) -> T {
        STATE.with(|s| f(&mut *s.borrow_mut()))
    }

    /// Creates/truncates the dump file when KSVG_TURB_CAPTURE is set and pushes the
    /// file magic. Does nothing (returns without touching the computation) otherwise.
    pub fn init() {
        if std::env::var_os("KSVG_TURB_CAPTURE").is_none() {
            return;
        }
        let path: PathBuf = std::env::var_os("KSVG_TURB_CAPTURE").unwrap().into();
        let file = File::create(&path).ok().map(BufWriter::new);
        let mut st = State {
            buf: Vec::with_capacity(1 << 20),
            file,
        };
        st.buf.extend_from_slice(MAGIC);
        push_u32(&mut st.buf, VERSION);
        with(|s| *s = Some(st));
    }

    fn push_u8(b: &mut Vec<u8>, v: u8) {
        b.push(v);
    }

    fn push_u16(b: &mut Vec<u8>, v: u16) {
        b.extend_from_slice(&v.to_le_bytes());
    }

    fn push_u32(b: &mut Vec<u8>, v: u32) {
        b.extend_from_slice(&v.to_le_bytes());
    }

    fn push_i32(b: &mut Vec<u8>, v: i32) {
        b.extend_from_slice(&v.to_le_bytes());
    }

    fn push_i64(b: &mut Vec<u8>, v: i64) {
        b.extend_from_slice(&v.to_le_bytes());
    }

    fn push_f64(b: &mut Vec<u8>, v: f64) {
        b.extend_from_slice(&v.to_le_bytes());
    }

    #[allow(clippy::too_many_arguments)]
    pub fn write_header(
        seed: i32,
        base_frequency: (f64, f64),
        num_octaves: i32,
        noise_type: NoiseType,
        stitch_tiles: StitchTiles,
        tile_width: f64,
        tile_height: f64,
        gradient: &[[[f64; 2]; B_SIZE + B_SIZE + 2]; 4],
        lattice_selector: &[usize; B_SIZE + B_SIZE + 2],
        canvas_width: u32,
        canvas_height: u32,
        bounds: IRect,
        affine: &Transform,
    ) {
        STATE.with(|slot| {
            let state = &mut slot.borrow_mut();
            if let Some(state) = state.as_mut() {
            let b = &mut state.buf;
            push_u32(b, canvas_width);
            push_u32(b, canvas_height);
            push_i32(b, bounds.x0);
            push_i32(b, bounds.y0);
            push_i32(b, bounds.x1);
            push_i32(b, bounds.y1);
            push_i32(b, seed);
            push_f64(b, base_frequency.0);
            push_f64(b, base_frequency.1);
            push_i32(b, num_octaves);
            push_u8(
                b,
                match noise_type {
                    NoiseType::Turbulence => 0,
                    NoiseType::FractalNoise => 1,
                },
            );
            push_u8(
                b,
                match stitch_tiles {
                    StitchTiles::NoStitch => 0,
                    StitchTiles::Stitch => 1,
                },
            );
            push_u16(b, 0);
            push_f64(b, tile_width);
            push_f64(b, tile_height);
            push_f64(b, affine.xx);
            push_f64(b, affine.yx);
            push_f64(b, affine.xy);
            push_f64(b, affine.yy);
            push_f64(b, affine.x0);
            push_f64(b, affine.y0);
            for k in 0..4 {
                for i in 0..B_SIZE + B_SIZE + 2 {
                    push_f64(b, gradient[k][i][0]);
                    push_f64(b, gradient[k][i][1]);
                }
            }
            for i in 0..B_SIZE + B_SIZE + 2 {
                push_i32(b, lattice_selector[i] as i32);
            }
            }
        });
    }

    /// Appends one per-call record. Layout (all little-endian):
    ///   pointX f64, pointY f64, tileX f64, tileY f64,
    ///   baseFx f64, baseFy f64,
    ///   colorChannel u32, numOctaves u32,
    ///   then numOctaves × { vecX f64, vecY f64, stW u32, stH u32, wrapX i64,
    ///                        wrapY i64, noise f64, sum f64 }.
    #[allow(clippy::too_many_arguments)]
    pub fn write_record(
        color_channel: usize,
        point: [f64; 2],
        tile_x: f64,
        tile_y: f64,
        base_frequency: (f64, f64),
        num_octaves: i32,
        oct_vec_x: &[f64; MAX_CAPTURE_OCTAVES],
        oct_vec_y: &[f64; MAX_CAPTURE_OCTAVES],
        oct_st_w: &[u32; MAX_CAPTURE_OCTAVES],
        oct_st_h: &[u32; MAX_CAPTURE_OCTAVES],
        oct_wrap_x: &[i64; MAX_CAPTURE_OCTAVES],
        oct_wrap_y: &[i64; MAX_CAPTURE_OCTAVES],
        oct_noise: &[f64; MAX_CAPTURE_OCTAVES],
        oct_sum: &[f64; MAX_CAPTURE_OCTAVES],
    ) {
        STATE.with(|slot| {
            let state = &mut slot.borrow_mut();
            if let Some(state) = state.as_mut() {
                let b = &mut state.buf;
                push_f64(b, point[0]);
                push_f64(b, point[1]);
                push_f64(b, tile_x);
                push_f64(b, tile_y);
                push_f64(b, base_frequency.0);
                push_f64(b, base_frequency.1);
                push_u32(b, color_channel as u32);
                push_u32(b, num_octaves.max(0) as u32);
                let n = num_octaves.clamp(0, MAX_CAPTURE_OCTAVES as i32) as usize;
                for o in 0..n {
                    push_f64(b, oct_vec_x[o]);
                    push_f64(b, oct_vec_y[o]);
                    push_u32(b, oct_st_w[o]);
                    push_u32(b, oct_st_h[o]);
                    push_i64(b, oct_wrap_x[o]);
                    push_i64(b, oct_wrap_y[o]);
                    push_f64(b, oct_noise[o]);
                    push_f64(b, oct_sum[o]);
                }
            }
        });
    }

    /// Flushes the accumulated buffer to the dump file (best effort).
    pub fn finish() {
        with(|s| {
            if let Some(mut st) = s.take() {
                if let Some(mut f) = st.file.take() {
                    let _ = f.write_all(&st.buf);
                    let _ = f.flush();
                }
            }
        });
    }
}

/// Limit the `numOctaves` parameter to avoid unbounded CPU consumption.
///
/// <https://drafts.fxtf.org/filter-effects/#element-attrdef-feturbulence-numoctaves>
const MAX_OCTAVES: i32 = 9;

/// Enumeration of the tile stitching modes.
#[derive(Debug, Default, Clone, Copy, Eq, PartialEq, Hash)]
enum StitchTiles {
    Stitch,
    #[default]
    NoStitch,
}

/// Enumeration of the noise types.
#[derive(Debug, Default, Clone, Copy, Eq, PartialEq, Hash)]
enum NoiseType {
    FractalNoise,
    #[default]
    Turbulence,
}

/// The `feTurbulence` filter primitive.
#[derive(Default)]
pub struct FeTurbulence {
    base: Primitive,
    params: Turbulence,
}

/// Resolved `feTurbulence` primitive for rendering.
#[derive(Clone)]
pub struct Turbulence {
    base_frequency: NumberOptionalNumber<f64>,
    num_octaves: i32,
    seed: f64,
    stitch_tiles: StitchTiles,
    type_: NoiseType,
    color_interpolation_filters: ColorInterpolationFilters,
}

impl Default for Turbulence {
    /// Constructs a new `Turbulence` with empty properties.
    #[inline]
    fn default() -> Turbulence {
        Turbulence {
            base_frequency: NumberOptionalNumber(0.0, 0.0),
            num_octaves: 1,
            seed: 0.0,
            stitch_tiles: Default::default(),
            type_: Default::default(),
            color_interpolation_filters: Default::default(),
        }
    }
}

impl ElementTrait for FeTurbulence {
    fn set_attributes(&mut self, attrs: &Attributes, session: &Session) {
        self.base.parse_no_inputs(attrs, session);

        for (attr, value) in attrs.iter() {
            match attr.expanded() {
                expanded_name!("", "baseFrequency") => {
                    set_attribute(&mut self.params.base_frequency, attr.parse(value), session);
                }
                expanded_name!("", "numOctaves") => {
                    set_attribute(&mut self.params.num_octaves, attr.parse(value), session);
                    if self.params.num_octaves > MAX_OCTAVES {
                        let n = self.params.num_octaves;
                        rsvg_log!(
                            session,
                            "ignoring numOctaves={n}, setting it to {MAX_OCTAVES}"
                        );
                        self.params.num_octaves = MAX_OCTAVES;
                    }
                }
                // Yes, seed needs to be parsed as a number and then truncated.
                expanded_name!("", "seed") => {
                    set_attribute(&mut self.params.seed, attr.parse(value), session);
                }
                expanded_name!("", "stitchTiles") => {
                    set_attribute(&mut self.params.stitch_tiles, attr.parse(value), session);
                }
                expanded_name!("", "type") => {
                    set_attribute(&mut self.params.type_, attr.parse(value), session)
                }
                _ => (),
            }
        }
    }
}

// Produces results in the range [1, 2**31 - 2].
// Algorithm is: r = (a * r) mod m
// where a = 16807 and m = 2**31 - 1 = 2147483647
// See [Park & Miller], CACM vol. 31 no. 10 p. 1195, Oct. 1988
// To test: the algorithm should produce the result 1043618065
// as the 10,000th generated number if the original seed is 1.
const RAND_M: i32 = 2147483647; // 2**31 - 1
const RAND_A: i32 = 16807; // 7**5; primitive root of m
const RAND_Q: i32 = 127773; // m / a
const RAND_R: i32 = 2836; // m % a

fn setup_seed(mut seed: i32) -> i32 {
    if seed <= 0 {
        seed = -(seed % (RAND_M - 1)) + 1;
    }
    if seed > RAND_M - 1 {
        seed = RAND_M - 1;
    }
    seed
}

fn random(seed: i32) -> i32 {
    let mut result = RAND_A * (seed % RAND_Q) - RAND_R * (seed / RAND_Q);
    if result <= 0 {
        result += RAND_M;
    }
    result
}

const B_SIZE: usize = 0x100;
const PERLIN_N: i32 = 0x1000;

#[derive(Clone, Copy)]
struct NoiseGenerator {
    base_frequency: (f64, f64),
    num_octaves: i32,
    stitch_tiles: StitchTiles,
    type_: NoiseType,

    tile_width: f64,
    tile_height: f64,

    lattice_selector: [usize; B_SIZE + B_SIZE + 2],
    gradient: [[[f64; 2]; B_SIZE + B_SIZE + 2]; 4],
}

#[derive(Clone, Copy)]
struct StitchInfo {
    width: usize, // How much to subtract to wrap for stitching.
    height: usize,
    wrap_x: usize, // Minimum value to wrap.
    wrap_y: usize,
}

impl NoiseGenerator {
    fn new(
        seed: i32,
        base_frequency: (f64, f64),
        num_octaves: i32,
        type_: NoiseType,
        stitch_tiles: StitchTiles,
        tile_width: f64,
        tile_height: f64,
    ) -> Self {
        let mut rv = Self {
            base_frequency,
            num_octaves,
            type_,
            stitch_tiles,

            tile_width,
            tile_height,

            lattice_selector: [0; B_SIZE + B_SIZE + 2],
            gradient: [[[0.0; 2]; B_SIZE + B_SIZE + 2]; 4],
        };

        let mut seed = setup_seed(seed);

        for k in 0..4 {
            for i in 0..B_SIZE {
                rv.lattice_selector[i] = i;
                for j in 0..2 {
                    seed = random(seed);
                    rv.gradient[k][i][j] =
                        ((seed % (B_SIZE + B_SIZE) as i32) - B_SIZE as i32) as f64 / B_SIZE as f64;
                }
                let s = (rv.gradient[k][i][0] * rv.gradient[k][i][0]
                    + rv.gradient[k][i][1] * rv.gradient[k][i][1])
                    .sqrt();
                rv.gradient[k][i][0] /= s;
                rv.gradient[k][i][1] /= s;
            }
        }
        for i in (1..B_SIZE).rev() {
            let k = rv.lattice_selector[i];
            seed = random(seed);
            let j = seed as usize % B_SIZE;
            rv.lattice_selector[i] = rv.lattice_selector[j];
            rv.lattice_selector[j] = k;
        }
        for i in 0..B_SIZE + 2 {
            rv.lattice_selector[B_SIZE + i] = rv.lattice_selector[i];
            for k in 0..4 {
                for j in 0..2 {
                    rv.gradient[k][B_SIZE + i][j] = rv.gradient[k][i][j];
                }
            }
        }

        rv
    }

    fn noise2(&self, color_channel: usize, vec: [f64; 2], stitch_info: Option<StitchInfo>) -> f64 {
        #![allow(clippy::many_single_char_names)]

        const BM: usize = 0xff;

        let s_curve = |t| t * t * (3. - 2. * t);
        let lerp = |t, a, b| a + t * (b - a);

        let t = vec[0] + f64::from(PERLIN_N);
        let mut bx0 = t as usize;
        let mut bx1 = bx0 + 1;
        let rx0 = t.fract();
        let rx1 = rx0 - 1.0;
        let t = vec[1] + f64::from(PERLIN_N);
        let mut by0 = t as usize;
        let mut by1 = by0 + 1;
        let ry0 = t.fract();
        let ry1 = ry0 - 1.0;

        // If stitching, adjust lattice points accordingly.
        if let Some(stitch_info) = stitch_info {
            if bx0 >= stitch_info.wrap_x {
                bx0 -= stitch_info.width;
            }
            if bx1 >= stitch_info.wrap_x {
                bx1 -= stitch_info.width;
            }
            if by0 >= stitch_info.wrap_y {
                by0 -= stitch_info.height;
            }
            if by1 >= stitch_info.wrap_y {
                by1 -= stitch_info.height;
            }
        }
        bx0 &= BM;
        bx1 &= BM;
        by0 &= BM;
        by1 &= BM;
        let i = self.lattice_selector[bx0];
        let j = self.lattice_selector[bx1];
        let b00 = self.lattice_selector[i + by0];
        let b10 = self.lattice_selector[j + by0];
        let b01 = self.lattice_selector[i + by1];
        let b11 = self.lattice_selector[j + by1];
        let sx = s_curve(rx0);
        let sy = s_curve(ry0);
        let q = self.gradient[color_channel][b00];
        let u = rx0 * q[0] + ry0 * q[1];
        let q = self.gradient[color_channel][b10];
        let v = rx1 * q[0] + ry0 * q[1];
        let a = lerp(sx, u, v);
        let q = self.gradient[color_channel][b01];
        let u = rx0 * q[0] + ry1 * q[1];
        let q = self.gradient[color_channel][b11];
        let v = rx1 * q[0] + ry1 * q[1];
        let b = lerp(sx, u, v);
        lerp(sy, a, b)
    }

    fn turbulence(&self, color_channel: usize, point: [f64; 2], tile_x: f64, tile_y: f64) -> f64 {
        let mut stitch_info = None;
        let mut base_frequency = self.base_frequency;

        // Adjust the base frequencies if necessary for stitching.
        if self.stitch_tiles == StitchTiles::Stitch {
            // When stitching tiled turbulence, the frequencies must be adjusted
            // so that the tile borders will be continuous.
            if base_frequency.0 != 0.0 {
                let freq_lo = (self.tile_width * base_frequency.0).floor() / self.tile_width;
                let freq_hi = (self.tile_width * base_frequency.0).ceil() / self.tile_width;
                if base_frequency.0 / freq_lo < freq_hi / base_frequency.0 {
                    base_frequency.0 = freq_lo;
                } else {
                    base_frequency.0 = freq_hi;
                }
            }
            if base_frequency.1 != 0.0 {
                let freq_lo = (self.tile_height * base_frequency.1).floor() / self.tile_height;
                let freq_hi = (self.tile_height * base_frequency.1).ceil() / self.tile_height;
                if base_frequency.1 / freq_lo < freq_hi / base_frequency.1 {
                    base_frequency.1 = freq_lo;
                } else {
                    base_frequency.1 = freq_hi;
                }
            }

            // Set up initial stitch values.
            let width = (self.tile_width * base_frequency.0 + 0.5) as usize;
            let height = (self.tile_height * base_frequency.1 + 0.5) as usize;
            stitch_info = Some(StitchInfo {
                width,
                wrap_x: (tile_x * base_frequency.0) as usize + PERLIN_N as usize + width,
                height,
                wrap_y: (tile_y * base_frequency.1) as usize + PERLIN_N as usize + height,
            });
        }

        // Diagnostic per-octave capture arrays (never read back into the math).
        let mut oct_vec_x = [0.0f64; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_vec_y = [0.0f64; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_st_w = [0u32; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_st_h = [0u32; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_wrap_x = [0i64; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_wrap_y = [0i64; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_noise = [0.0f64; capture_dump::MAX_CAPTURE_OCTAVES];
        let mut oct_sum = [0.0f64; capture_dump::MAX_CAPTURE_OCTAVES];

        let mut sum = 0.0;
        let mut vec = [point[0] * base_frequency.0, point[1] * base_frequency.1];
        let mut ratio = 1.0;
        for octave in 0..self.num_octaves {
            let n = self.noise2(color_channel, vec, stitch_info);

            if capture_dump::is_active() && self.num_octaves > 0 {
                let o = octave.clamp(0, capture_dump::MAX_CAPTURE_OCTAVES as i32 - 1) as usize;
                oct_vec_x[o] = vec[0];
                oct_vec_y[o] = vec[1];
                if let Some(si) = stitch_info {
                    oct_st_w[o] = si.width as u32;
                    oct_st_h[o] = si.height as u32;
                    oct_wrap_x[o] = si.wrap_x as i64;
                    oct_wrap_y[o] = si.wrap_y as i64;
                }
                oct_noise[o] = n;
            }

            if self.type_ == NoiseType::FractalNoise {
                sum += n / ratio;
            } else {
                sum += n.abs() / ratio;
            }

            if capture_dump::is_active() && self.num_octaves > 0 {
                let o = octave.clamp(0, capture_dump::MAX_CAPTURE_OCTAVES as i32 - 1) as usize;
                oct_sum[o] = sum;
            }

            vec[0] *= 2.0;
            vec[1] *= 2.0;
            ratio *= 2.0;
            if let Some(stitch_info) = stitch_info.as_mut() {
                // Update stitch values. Subtracting PerlinN before the multiplication and
                // adding it afterward simplifies to subtracting it once.
                stitch_info.width *= 2;
                stitch_info.wrap_x = 2 * stitch_info.wrap_x - PERLIN_N as usize;
                stitch_info.height *= 2;
                stitch_info.wrap_y = 2 * stitch_info.wrap_y - PERLIN_N as usize;
            }
        }

        capture_dump::write_record(
            color_channel,
            point,
            tile_x,
            tile_y,
            base_frequency,
            self.num_octaves,
            &oct_vec_x,
            &oct_vec_y,
            &oct_st_w,
            &oct_st_h,
            &oct_wrap_x,
            &oct_wrap_y,
            &oct_noise,
            &oct_sum,
        );

        sum
    }
}

impl Turbulence {
    pub fn render(
        &self,
        bounds_builder: BoundsBuilder,
        ctx: &FilterContext,
    ) -> Result<FilterOutput, FilterError> {
        capture_dump::init();
        let bounds: IRect = bounds_builder.compute(ctx).clipped.into();

        let affine = ctx.paffine().invert().unwrap();

        let seed = clamp(
            self.seed.trunc(), // per the spec, round towards zero
            f64::from(i32::MIN),
            f64::from(i32::MAX),
        ) as i32;

        // "Negative values are unsupported" -> set to the initial value which is 0.0
        //
        // https://drafts.fxtf.org/filter-effects/#element-attrdef-feturbulence-basefrequency
        //
        // Later in the algorithm, the base_frequency gets multiplied by the coordinates within the
        // tile.  So, limit the base_frequency to avoid overflow later.  We impose an arbitrary
        // upper limit for the frequency.  If it crosses that limit, we consider it invalid
        // and revert back to the initial value.  See bug #1115.
        let base_frequency = {
            let NumberOptionalNumber(base_freq_x, base_freq_y) = self.base_frequency;

            let x = if base_freq_x > 32768.0 {
                0.0
            } else {
                base_freq_x.max(0.0)
            };

            let y = if base_freq_y > 32768.0 {
                0.0
            } else {
                base_freq_y.max(0.0)
            };

            (x, y)
        };

        let noise_generator = NoiseGenerator::new(
            seed,
            base_frequency,
            self.num_octaves,
            self.type_,
            self.stitch_tiles,
            f64::from(bounds.width()),
            f64::from(bounds.height()),
        );

        // The generated color values are in the color space determined by
        // color-interpolation-filters.
        let surface_type = SurfaceType::from(self.color_interpolation_filters);

        let mut surface = ExclusiveImageSurface::new(
            ctx.source_graphic().width(),
            ctx.source_graphic().height(),
            surface_type,
        )?;

        capture_dump::write_header(
            seed,
            noise_generator.base_frequency,
            noise_generator.num_octaves,
            noise_generator.type_,
            noise_generator.stitch_tiles,
            noise_generator.tile_width,
            noise_generator.tile_height,
            &noise_generator.gradient,
            &noise_generator.lattice_selector,
            ctx.source_graphic().width() as u32,
            ctx.source_graphic().height() as u32,
            bounds,
            &affine,
        );

        surface.modify(&mut |data, stride| {
            for y in bounds.y_range() {
                for x in bounds.x_range() {
                    let point = affine.transform_point(f64::from(x), f64::from(y));
                    let point = [point.0, point.1];

                    let generate = |color_channel| {
                        let v = noise_generator.turbulence(
                            color_channel,
                            point,
                            f64::from(x - bounds.x0),
                            f64::from(y - bounds.y0),
                        );

                        let v = match self.type_ {
                            NoiseType::FractalNoise => (v * 255.0 + 255.0) / 2.0,
                            NoiseType::Turbulence => v * 255.0,
                        };

                        (clamp(v, 0.0, 255.0) + 0.5) as u8
                    };

                    let pixel = Pixel {
                        r: generate(0),
                        g: generate(1),
                        b: generate(2),
                        a: generate(3),
                    }
                    .premultiply();

                    data.set_pixel(stride, pixel, x as u32, y as u32);
                }
            }
        });

        capture_dump::finish();

        Ok(FilterOutput {
            surface: surface.share()?,
            bounds,
        })
    }

    pub fn get_input_requirements(&self) -> InputRequirements {
        InputRequirements::default()
    }
}

impl FilterEffect for FeTurbulence {
    fn resolve(
        &self,
        _acquired_nodes: &mut AcquiredNodes<'_>,
        node: &Node,
    ) -> Result<Vec<ResolvedPrimitive>, FilterResolveError> {
        let cascaded = CascadedValues::new_from_node(node);
        let values = cascaded.get();

        let mut params = self.params.clone();
        params.color_interpolation_filters = values.color_interpolation_filters();

        Ok(vec![ResolvedPrimitive {
            primitive: self.base.clone(),
            params: PrimitiveParams::Turbulence(params),
        }])
    }
}

impl Parse for StitchTiles {
    fn parse<'i>(parser: &mut Parser<'i, '_>) -> Result<Self, ParseError<'i>> {
        Ok(parse_identifiers!(
            parser,
            "stitch" => StitchTiles::Stitch,
            "noStitch" => StitchTiles::NoStitch,
        )?)
    }
}

impl Parse for NoiseType {
    fn parse<'i>(parser: &mut Parser<'i, '_>) -> Result<Self, ParseError<'i>> {
        Ok(parse_identifiers!(
            parser,
            "fractalNoise" => NoiseType::FractalNoise,
            "turbulence" => NoiseType::Turbulence,
        )?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn turbulence_rng() {
        let mut r = 1;
        r = setup_seed(r);

        for _ in 0..10_000 {
            r = random(r);
        }

        assert_eq!(r, 1043618065);
    }
}
