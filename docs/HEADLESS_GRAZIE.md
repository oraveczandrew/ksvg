# Headless Grazie spellcheck (grammar)

How to run JetBrains' Grazie proofreading (grammar) over the whole project
without opening the IDE, then triage the findings and fix them. Calibrated on
2026-10-02; the procedure below reproduced 85 fixable findings in committable
sources (plus ~980 in ignored/vendored noise) and verified the fix round-trip
back to zero.

## 1. Prerequisites

- **The IDE must be closed.** `inspect.sh` cannot lock/index a project that a
  live IDE instance holds open. Check first:
  ```bash
  pgrep -fl "Android Studio" || echo "no-studio"
  pgrep -fl "IntelliJ IDEA" || echo "no-idea"
  ```
  If either is running, stop and ask the user to close it.
- **Use IntelliJ IDEA's inspector, not Android Studio's.** Android Studio's
  headless `inspect.sh` is silent on Grazie: every run reports zero problems,
  even for blatant errors. The IDEA one works:
  `"$HOME/Applications/IntelliJ IDEA.app/Contents/bin/inspect.sh"`
  (quote the path — it contains a space).
- **Android SDK** must resolve: `export ANDROID_HOME=<sdk-root>` for every
  command and check `sdk.dir` in `local.properties`.
- Define the project root once; every path in this document is absolute:
  ```bash
  PROJECT=/path/to/ksvg   # e.g., /Volumes/samu/_projects/ksvg
  ```

## 2. Inspection profile (Grazie-only)

A minimal one-entry profile does **not** scope the run: tools not listed in
the profile run with IDE defaults (mostly enabled). A single-entry run
produced ~95 000 noise findings. The profile must therefore explicitly
disable every tool except `GrazieInspection` (kept at `level="ERROR"` so the
findings surface at default verbosity). Generate it from a previous full
run's `.descriptions.xml` (`shortName` doubles as `class` for the vast
majority of tools):

```bash
python3 - <<EOF
import re
desc = open('$PROJECT/tmp/inspection/.descriptions.xml', errors='replace').read()
names = set(re.findall(r'shortName="([^"]+)"', desc))
names.discard('GrazieInspection')
out = ['<profile version="1.0">', '  <option name="myName" value="GrazieOnly" />',
       '  <inspection_tool class="GrazieInspection" enabled="true" level="ERROR" enabled_by_default="true" />']
for n in sorted(names):
    out.append(f'  <inspection_tool class="{n}" enabled="false" level="WARNING" enabled_by_default="false" />')
out.append('</profile>')
open('$PROJECT/tmp/grazie-profile.xml', 'w').write('\n'.join(out) + '\n')
print('disabled:', len(names))
EOF
```

Bootstrap note: the very first run has no `.descriptions.xml` yet — run once
with any profile to produce it, then generate the real profile and re-run.
If a run's log reports `Descriptions are missed for tools: ...` (SEVERE),
re-run the generator against the newest `.descriptions.xml` to cover the
newly seen tool names.

`tmp/` is git-ignored, so the profile and the output never pollute commits.

## 3. Run

```bash
export ANDROID_HOME="$SDK_ROOT"  # your Android SDK root
rm -rf "$PROJECT/tmp/inspection"
"$HOME/Applications/IntelliJ IDEA.app/Contents/bin/inspect.sh" \
  "$PROJECT" \
  "$PROJECT/tmp/grazie-profile.xml" \
  "$PROJECT/tmp/inspection" -v2
```

- Takes a few minutes (project indexing and analysis). `-v2` prints progress
  (`Analyzing code in …`, ~12 000 files here) ending with `Done.`
- **Health check:** a healthy Grazie-only run leaves `GrazieInspection.xml`
  behind. If the run finishes in seconds and only `.descriptions.xml` exists
  (zero findings), it is a bogus run — re-run unchanged.

## 4. Parse and filter noise

Output is XML: `<problem>` elements with `file`, `line`, `description`,
plus `highlighted_element` (the exact flagged word) and `problem_class`
(expect only `Grammar`).

```bash
python3 - <<'EOF'
import glob, os, xml.etree.ElementTree as ET
ROOT = os.environ['PROJECT']
for f in sorted(glob.glob(ROOT + '/tmp/inspection/*.xml')):
    try:
        t = ET.parse(f).getroot()
    except Exception:
        continue
    for p in t.iter('problem'):
        g = lambda tag: (p.findtext(tag) or '').strip().replace('\n', ' ')[:200]
        fp = g('file').replace('file://$PROJECT_DIR$/', '')
        if fp.startswith('tmp/') or '/build/' in fp or fp.startswith('.artifacts/') or '/.cxx/' in fp:
            continue  # ignored/vendored/generated noise, never fix
        print(f"{fp}:{g('line')} | {g('highlighted_element')} | {g('description')[:150]}")
EOF
```

Typical noise to skip: anything under `tmp/` (incl. vendored virtualenvs),
`build/`, `.cxx/`, `.artifacts/`. Never edit third-party code.

## 5. Triage and fix

Review every finding **in context** before touching it — Grazie produces
false positives on identifiers, proper nouns and technical terms:

- **Plain prose errors** (comments, KDoc, Markdown): fix as suggested —
  frequent ones here were `antialiasing`, `handwritten`, `spotlight(s)`,
  `afterward` (American, no `-s`), `e.g.,`/`i.e.,` (always with trailing
  comma), missing commas after `Therefore,`/`However,`/`Instead,`/
  `Currently,`, `independently of`, `45-degree`, `multivalued`, `Javadoc`,
  `CSS`/`XML`/`ID` capitalized.
- **Identifiers / spec terms that must keep their form** (e.g., the `xml:space`
  attribute, arch labels like `armv7a`, loop variables): do NOT rewrite —
  wrap them in KDoc `` `code` `` spans, which proofreading skips. (Precedent:
  backticked terms in this repo are never flagged.)
- **Spec-notation comments** (e.g., CSS grammar `a-z A-Z` ranges): rephrase
  with comma-separated lists so they read as prose.
- **Line-wrap artifacts** (`Avail-`/`ability` split across comment lines):
  rewrap so the hyphenated word stays intact on one line.
- **Established terms / trademarks that cannot change** (e.g., ARM
  `big.LITTLE`, math prime `R'`): reword the surrounding sentence instead.
- **Genuine false positives on correct text**: `//noinspection
  GrazieInspection` in the narrowest applicable scope, only with justification.
- **Never "fix" `.S` assembly files**: mnemonics and labels are not typos.
- **Project dictionary** (`.idea/dictionaries/project.xml`, `<w>word</w>`,
  roughly alphabetical, committed): for spelling-level jargon. Note it does
  **not** suppress grammar-rule findings — those need one of the above.

## 6. Verify and close

1. Re-run sections 3–4: committable sources must report zero remaining
   findings (noise in ignored dirs is fine and stays).
2. Review `git status` / `git diff`: only intended files. All changes here
   are comment/documentation-only, so no behavior change is expected; still,
   run the standard compile per `AGENTS.md` before committing.
3. Commit with a terse message and no agent-attribution footer.
4. Tell the user they can reopen the IDE.

## 7. Known limitations (verified 2026-10-02)

Two rule classes never fire headless, so findings of these kinds (e.g., from
the live editor) must be fixed by hand — the headless run cannot confirm them:

- **Cloud-ML rules** (`MlecChecker`, `Grazie.MLEC.*`, e.g., "Incorrect verb
  tense form"): they call a server-side grammar-correction service via
  `GrazieCloudConnector`, unavailable to offline `inspect.sh`.
- **NLP parse-based native rules** (e.g., "Missing comma before direct
  speech", `Punctuation.DIRECT_SPEECH`): they need dependency parsing, which
  does not initialize headless — even the textbook example sentence is not
  flagged, while neighboring token-level rules fire normally.
