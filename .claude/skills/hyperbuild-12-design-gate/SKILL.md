---
name: hyperbuild-12-design-gate
description: >
  Step 12 of the hyperbuild pipeline — the Stage-A hard gate and THE ONE
  permitted stop. Runs scripts/gate-design.sh FIRST (the Tier-0 half:
  artifact existence, frontmatter schemas, closed vocabularies, provenance
  blocks, epic DAG acyclicity, set coverage — code the pipeline cannot
  edit), then spawns 1 hb-gate-verifier for the JUDGMENT residue only, and
  merges both into one report. Between them they cover the full
  Stage-A checklist (research vault, PRD, feature specs, stack guide, 3
  complete design systems with every full/partial screen mocked +
  screenshotted and art-direction cards for none screens, step 8.5's
  visual-QA findings with zero unresolved criticals, generated skills, the
  FROZEN gate oracle (every .claude/skills/app-*/scripts/*.sh copied to
  runs/<run_tag>/gates/skill-scripts/ and SHA-256'd into manifest
  frozen_gates — steps 14 and 16 execute ONLY those copies), full
  backlog with PRD↔epics coverage, and the research archive's shape:
  the four FIXED-name areas, a non-empty verify/ in each, provenance blocks
  everywhere), writes runs/<run_tag>/gates/design-gate-report.md and — on
  pass — research/README.md (the areas index + REUSABILITY GUIDE,
  docs/RESEARCH-ARCHIVE.md §8), then stops the pipeline
  with a user-facing summary ending in "run /hyperbuild-choose a|b|c",
  setting manifest blocked_on: "design-choice". On fail: fix artifacts,
  re-run the gate, MAX 2 rounds (round 2 only if a Tier-0 signal changed),
  then blocked + honest report. Invoked by
  the hyperbuild router via Skill(); not run directly by users.
---

# Step 12 — Design gate (Stage-A hard gate + THE ONE PERMITTED STOP)

**⚠ READ FIRST — the two ways to violate this step.** (1) This is the ONLY point in
the entire pipeline where you intentionally end the turn with a bare-text, user-facing
message. Everywhere else bare text kills the run; HERE the stop IS the deliverable.
(2) The inverse: **if the gate passes, do NOT invoke `Skill(skill:
"hyperbuild-13-scaffold")`.** Stage B starts only when the user runs
`/hyperbuild-choose <a|b|c>`. If you find yourself about to continue into Stage B after
a pass, STOP. Set the manifest, emit the stop message, end the turn.

**⚠ THIS STEP FREEZES THE ORACLE.** `hb-skill-smith` (step 10) WRITES the
`.claude/skills/app-*/scripts/*.sh` PASS/FAIL gates that steps 14 and 16 then EXECUTE to
decide whether the build is good. Left alone, that is the build side authoring and able
to edit the check that grades it — the pipeline's one structural contradiction. Step 12
closes it by taking a hash-recorded copy of every gate script (12.1b) BEFORE the stop.
From here on, steps 14 and 16 run only the frozen copies, and any hash mismatch is a hard
failure.

**⚠ ANTI-HIDING RULE — the frozen scripts stay readable by everyone, forever.** Freezing
is about IMMUTABILITY, not secrecy. Every implementer, test engineer, critic and human
may read `.claude/skills/app-*/scripts/*.sh` and
`runs/<run_tag>/gates/skill-scripts/**` in full, and every skill that hands an
implementer its context keeps doing so. Do NOT chmod them unreadable, do NOT move them
somewhere the build agents cannot see, do NOT omit them from a spawn's reading list, and
do NOT write a gate whose criterion is undisclosed. The evidence is blunt: the highest
reward-hacking rate on record (~80% of attempts, Opus 4.6 on an early MirrorCode) was
measured with the test cases HIDDEN — the model responded by injecting logging into the
scoring script and binary-searching the scorer. Hidden checks buy nothing and provoke
attacks on the scorer itself. A build agent that can read the gate and cannot change it
is the configuration we want.

You are executing step 12 (design gate) of the hyperbuild pipeline. Steps 1–11 claim
Stage A is complete; this step proves it against artifacts on disk, freezes the gate
oracle Stage B will be graded by, then hands the user the one decision the pipeline
cannot make: which design to build.

**Goal:** a passing `runs/<run_tag>/gates/design-gate-report.md` and a final user-facing
summary ending with `run /hyperbuild-choose a|b|c` — or, after its 2 fix rounds are
spent (or round 2 is not earned), an honest blocked report. Gate failures are fixed by changing the artifacts, NEVER by
re-interpreting the checks.

---

## Inputs

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`; steps 1–11 (including 3.5, 4.5, 8.5) must read `done`; `screenshots_skipped` (when `true`, script checks D22 and D25 downgrade to WARNINGs); `visual_qa_skipped` (same effect on D25)
- `runs/<run_tag>/idea.md` — verbatim idea. GOSPEL.
- `research/product-spec.md` — the canonical screen inventory, including its `mockup_feasibility` column (script checks D21/D22 and the verifier's check 18 key off it)
- `features/00-index.md` — the must/should feature ids
- `runs/<run_tag>/gates/visual-qa-{a,b,c}.json` — step 8.5's visual-QA records (script checks D25 and D26; the pass path also quotes their accepted known issues into the stop message)
- `.claude/skills/app-*/scripts/*.sh` — step 10's generated PASS/FAIL gate scripts. **The subject of 12.1b's freeze and of check 24**; the LIVE originals stay in place and stay readable — 12.1b copies them, it never moves or hides them
- `scripts/gate-design.sh` — **the Tier-0 half of this gate, and it is not yours to edit.** It lives in `scripts/` at the repo root, and `guard-write.sh` rule 4 refuses any write to `scripts/gate-*.sh` while a run is in stage `BUILD`; outside a build an edit costs a human `ask` click and still shows up as a changed `script_sha256` in the round JSON. Step 12.1c runs it; its exit code is a fact. A gate the run can rewrite is not a gate
- Everything else Stage A wrote — enumerated check by check below

## The Stage-A checklist (canonical — paste VERBATIM into the verifier spawn)

Gear numbers: use the standard column unless manifest `gear` is `premier`.

| # | Check | Pass condition |
|---|-------|----------------|
| 1 | Idea | `runs/<run_tag>/idea.md` exists; frontmatter has run_tag, created, platform; body non-empty |
| 2 | Manifest | `runs/<run_tag>/manifest.json` is valid JSON; steps 1–11 all `"done"` — including the half-steps `"3.5"`, `"4.5"`, and `"8.5"` |
| 3 | Platform decision | `runs/<run_tag>/decisions/platform.md` exists; names the stack; contains a rationale |
| 4 | Competitor dossiers | ≥6 (standard) / ≥12 (premier) files in `research/01-product-and-market/research/competitors/`; each has frontmatter + a `## Sources` section |
| 5 | Landscape | `research/01-product-and-market/author/competitor-landscape.md` exists; contains a feature-matrix table |
| 6 | Sentiment | `research/01-product-and-market/research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md` all exist; `research/01-product-and-market/author/sentiment-synthesis.md` has a ranked pain-point list |
| 7 | PRD | `research/product-spec.md` exists; has a MoSCoW feature list AND a screen inventory section |
| 8 | Feature specs | `features/00-index.md` exists; one `features/NN-<slug>.md` per must/should PRD feature (≤15 standard / ≤25 premier files); each has moscow + screens frontmatter and all 8 body sections |
| 9 | Stack research | COUNT, do not name: the number of `research/02-engineering/research/*.md` files is within the gear range — ≥6 and ≤8 (standard) / ≥10 and ≤14 (premier) — and each carries `area: 02-engineering` + `phase: research` frontmatter. **There is NO fixed filename list.** Step 5 DERIVES its dimensions per platform (RENAME → DROP → MERGE → ADD), so `architecture.md`, `structure.md`, `testing.md` and `tooling-ci.md` are NOT expected filenames; a specific slug being absent is never a failure. The derivation record is `runs/<run_tag>/temp/dimensions-02.md` — read it to see what was dropped and why. `research/02-engineering/author/stack-guide.md` exists, contains committed "we will do X" decisions, and has a `## Code taxonomy` section. The area name is FIXED — a platform-specific directory (`02-flutter-engineering`, `02-swift-engineering`) is a FAIL, not a variant (`docs/RESEARCH-ARCHIVE.md` §2) |
| 10 | Design research | exactly 3 files under `research/03-design-system/research/` carry BOTH `direction:` and `letter:` in their frontmatter, one per row of `runs/<run_tag>/designs/directions.md` — count by FRONTMATTER, never by file count. The other files in that directory are step 6.3a's SHARED platform dimensions (2 standard / 3 premier: `framework-render-capability`, `type-availability-and-licensing`, plus `platform-design-conventions` OR `accessibility-and-contrast-constraints` at premier) and are EXPECTED — their presence is not a fourth direction. `research/03-design-system/author/design-directions.md` exists and carries a `## Corrections that override the research docs` table |
| 11 | Design systems | for EACH of a, b, c: `runs/<run_tag>/designs/<x>/design-system.md` AND `tokens.css` exist |
| 12 | Mockup completeness | for EACH of a, b, c: `designs/<x>/mockups/` has one `.html` per `full`/`partial` screen in the PRD screen inventory's `mockup_feasibility` column (cap 12 standard / 20 premier); NO `.html` for `none` screens; the SAME screen set across all three designs |
| 13 | Gallery | `runs/<run_tag>/designs/index.html` exists; references all three designs' mockups |
| 14 | Skill-authoring guide | `research/04-claude-skills/author/skill-authoring-guide.md` exists |
| 15 | Generated skills | `.claude/skills/<name>/SKILL.md` exists with valid frontmatter for ALL five: app-code-style, app-architecture, app-testing, app-components, app-review-checklist |
| 16 | Backlog shape | `epics/00-overview.md` exists with a PRD coverage matrix; epic count 4–8 (standard) / 6–12 (premier); every epic dir has `epic.md` + 3–8 (standard) / 4–10 (premier) task files; every task has valid frontmatter (id, epic, status: todo, depends_on, size, category, features, files — `category` naming a category present in `research/02-engineering/author/stack-guide.md`'s `## Code taxonomy`; `files` a non-empty list of planned repo-relative paths — step 14's wave-disjointness key) |
| 17 | PRD↔epics coverage | every must/should feature id from `features/00-index.md` appears in ≥1 task's `features:` frontmatter; zero blank Tasks cells on must/should rows of the coverage matrix |
| 18 | Art-direction cards | every `none` screen in the PRD inventory has a `## Art direction — <Screen>` card in EACH of the 3 `designs/<x>/design-system.md` files (vacuous pass when the inventory has no `none` screens) |
| 19 | Mockup screenshots | for EACH of a, b, c: `designs/<x>/screenshots/` has one non-empty `.png` per mockup `.html`; when manifest `screenshots_skipped` is `true`, missing screenshots are a WARNING (result `warn`), not a fail |
| 20 | Visual QA performed | for EACH of a, b, c: `runs/<run_tag>/gates/visual-qa-<x>.json` exists, is valid JSON, has `rounds` ≥ 1, and its `screens_reviewed` ∪ `screens_not_viewed` covers EVERY `.png` in `designs/<x>/screenshots/` — a screenshot named in neither list is a FAIL (it was never judged). A NON-EMPTY `screens_not_viewed` records `warn`, not `fail`, provided every entry carries a reason: step 8.5 legitimately lists a PNG it could not open rather than judging it from HTML, and those screens go in the report's `### Known visual issues` table so the user knows which screens are unreviewed. When manifest `screenshots_skipped` or `visual_qa_skipped` is `true`, the three files must still exist carrying `"status": "source-only-no-render"` (step 8.5's degraded mode) and the check records `warn`, not `fail` |
| 21 | No unresolved visual criticals | across the three `visual-qa-<x>.json` files, ZERO findings with `"severity": "critical"` and `"status": "open"` (`unresolved_critical` must equal 0 in each file and agree with its `findings`). A critical with `"status": "accepted-known-issue"` is legal ONLY when the file's `rounds` is ≥ 2 (step 8.5's two critic rounds — one patch round — were actually spent) and it carries a non-empty `acceptance_reason`; `"status": "unverifiable"` is legal ONLY in source-only mode (manifest `visual_qa_skipped: true`), also with a reason — either records `warn`, and every such finding MUST be listed in the gate report and in the stop message |
| 22 | Research archive shape | All four areas exist with the FIXED names `research/{01-product-and-market,02-engineering,03-design-system,04-claude-skills}/`, and each has a non-empty `_INDEX.md` plus non-empty `research/`, `verify/`, and `author/` subdirectories. `verify/` EMPTY in any area is a FAIL — that area's findings were never fact-checked (`docs/RESEARCH-ARCHIVE.md` §5). Per-area verify minimums, from the §5 selection rule (3–5 load-bearing claims per dimension standard, 6–10 premier): ≥3 (standard) / ≥6 (premier) `verify/*.md` files in EACH area — **per AREA, never per research FILE**: every area binds a hard `VERIFY_BUDGET` of ≤25 standard / ≤60 premier, so a per-file rule would be unsatisfiable by construction. Plus per-file coverage: every `research/` file that has at least one `"selected": true` claim in its area's registry (`runs/<run_tag>/temp/claims-0N.json`) has ≥1 `verify/<its-dimension>--*.md` file. Every `verify/*.md` frontmatter carries a `verdict:` from the closed vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE` — any other value is a FAIL |
| 23 | Provenance blocks | EVERY `.md` under each area's `research/`, `verify/`, `critique/`, and `author/` ends with a `<details>` provenance block containing the prompt that produced it (`docs/RESEARCH-ARCHIVE.md` §4). Run it as: `find research/0*-*/research research/0*-*/verify research/0*-*/critique research/0*-*/author -name '*.md' -print0 \| xargs -0 grep -L 'The prompt that produced this'` — any path printed is a FAIL, listed by path. (Do NOT use `research/*/{...}/**/*.md`: `**` needs `globstar`, and `research/*/` also matches `research/harvest/`, which has none of those subdirectories — bash then passes the unmatched patterns to grep literally and the per-pattern errors read like "returns nothing", i.e. a false PASS.) `_INDEX.md` is an index and correctly takes NO provenance block |
| 24 | Frozen gate oracle | The orchestrator ran 12.1b THIS round. Run the FROZEN-GATE VERIFY script (pasted below, `python3`, never by eye) and require **exit 0**. It proves three sets agree exactly: the `.sh` files under `runs/<run_tag>/gates/skill-scripts/`, the keys of manifest `frozen_gates`, and the live `.claude/skills/app-*/scripts/*.sh` set — key `<skill>/<script>.sh` ↔ live `.claude/skills/<skill>/scripts/<script>.sh` — and that every recorded SHA-256 matches BOTH the frozen copy and its live original. Exit 2 (`MISSING` / `TAMPERED` / `UNRECORDED`, or an absent/empty `frozen_gates`) and exit 3 (`LIVE-ADDED` / `LIVE-DELETED` / `LIVE-EDITED`) are both FAILS, with the offending paths quoted verbatim into the evidence. `frozen_gates` empty, or zero `.sh` across all five skills, is a FAIL — an empty oracle grades nothing. A single `app-*` skill with no `scripts/` prints `WARN no scripts/*.sh:` and records `warn`, not `fail`: step 10 owes every generated skill a gate, but one thin skill does not block the gate. **The frozen copies stay readable — freezing is immutability, not secrecy (see the ANTI-HIDING rule at the top of this skill).** |

### Who executes which row — the Tier-0 / Tier-2 split

**A gate executed by a model reading prose is a Tier-2 gate wearing Tier-0 clothes.**
Most of the table above is set coverage and referential integrity — that is code, and it
now runs as code. `scripts/gate-design.sh <run_tag>` (step 12.1c) discharges every row a
script can decide; `hb-gate-verifier` (step 12.2) is spawned for the residue that
genuinely needs a reader, and is told NOT to re-run what the script already decided.

| Script check | What it proves (all Tier 0) | Checklist rows it discharges |
|---|---|---|
| D01 | `idea.md` exists, frontmatter keys present, body non-empty | 1 |
| D02 | manifest is valid JSON; steps 1–11 incl. 3.5/4.5/8.5 all `done` | 2 |
| D03 | `decisions/platform.md` exists, non-empty | 3 (existence half) |
| D04 | PRD exists with a MoSCoW list, a screen inventory, a `mockup_feasibility` column | 7 (existence half) |
| D05 | `features/00-index.md` frontmatter + parseable `F-NN` rows | 8 (index half) |
| D06 | `epics/00-overview.md` frontmatter + a coverage-matrix section | 16 (overview half) |
| D07 | the four FIXED-name areas, each with `_INDEX.md` + non-empty research/verify/critique/author; a platform-specific area name FAILS | 22 (shape half) |
| D08 | all 5 `author/` syntheses + all 4 sentiment dimension files exist non-empty | 5, 6, 10, 14 (existence half) |
| D09 | RESEARCH-ARCHIVE §3 frontmatter on every phase file; `area:`/`phase:` must match the file's own path | 9 (frontmatter half), 22 |
| D10 | every `verify/*.md` carries a verdict from the CLOSED vocabulary | 22 (verdict half) |
| D11 | every phase file ends with its provenance block (the documented path-filtered `find`, never a `**` glob) | 23 |
| D12 | verify count per AREA vs the gear floor + per-file coverage against `temp/claims-0N.json` | 22 (coverage half) |
| D13 | competitor / dimension / direction / critic counts vs the gear range; area 03's 3 directions counted BY FRONTMATTER | 4 (count half), 9 (count half), 10 (count half) |
| D14 | every feature spec: id↔filename, closed `moscow`/`status` vocabularies, non-empty `screens`, all 8 body sections | 8 |
| D15 | every task + `epic.md`: full frontmatter schema, closed `status`/`size` vocabularies | 16 (schema half) |
| D16 | every task is `status: todo` at the design gate | 16 |
| D17 | every task's `files:` list is NON-EMPTY — step 14's wave-disjointness key | 16 |
| D18 | **the epic and task DAGs are ACYCLIC and every `depends_on` target exists** | *(new — no prose row ever checked this)* |
| D19 | feature↔task coverage in BOTH directions | 17 |
| D20 | all 3 designs have a non-empty `design-system.md` + `tokens.css` | 11 |
| D21 | mockup set == the PRD's `full`/`partial` screens, no `.html` for `none`, identical set across a/b/c | 12 |
| D22 | one non-empty `.png` per mockup, no orphan renders (`screenshots_skipped` → warn) | 19 |
| D23 | `designs/index.html` exists and references a, b and c | 13 |
| D24 | all 5 generated `app-*` skills exist with valid frontmatter | 15 |
| D25 | every rendered screenshot is accounted for in a visual-QA file | 20 |
| D26 | zero step-8.5 criticals still `open`; acceptances legal only after 2 rounds with a reason | 21 |

**The verifier's residue — the rows a script cannot decide, and the ONLY rows it runs:**

- **4** — each competitor dossier actually carries a `## Sources` section with real sources
- **5** — the landscape doc contains a real feature-matrix table
- **6** — `sentiment-synthesis.md` carries a genuinely RANKED pain-point list
- **7** — the PRD's MoSCoW list is a real prioritization, not a flat list of everything
- **9** — the stack-guide contains committed "we will do X" decisions (not a survey) and a `## Code taxonomy` section
- **10** — `design-directions.md` carries its `## Corrections that override the research docs` table, and the corrections match the `verify/` verdicts
- **16** — each task's `category` names a category that is actually present in the stack-guide's `## Code taxonomy`
- **18** — every `none` screen has a real `## Art direction — <Screen>` card in all three design systems
- **22 (judgment half)** — every CONFIRMED critic finding shows a resolution in the `author/` docs; NO REFUTED claim survives in any `author/` doc, the PRD, `features/`, or `epics/`; every PARTIALLY_TRUE claim appears in its corrected form; no UNVERIFIABLE claim is the sole support for a `must`
- **24** — the FROZEN-GATE VERIFY block (12.1b), run for its exit code

Severity in the script is deliberate and must not be re-litigated: schema violations,
closed-vocabulary violations, missing provenance, DAG breaks, coverage gaps and unresolved
criticals are hard FAILs; gear-range and cap deviations are WARNs, because they are scale
knobs rather than integrity. A WARN passes the gate and is printed in the report.

---

## Procedure

### Step 12.1 — Recover state

Read `runs/<run_tag>/manifest.json` (run_tag, gear) and `runs/<run_tag>/idea.md`. Set
round R = 1 (or resume: if `temp/design-gate-checks-round-*.json` files exist, R = max
round + 1).

### Step 12.1b — FREEZE THE ORACLE (every round, before the verifier)

**Why here.** Step 10's `hb-skill-smith` wrote the `app-*/scripts/*.sh` gates; steps 14
and 16 execute them to grade the build. Between them sits exactly one moment where
nothing on the build side is running: this one. Freeze the scripts here and Stage B is
graded by a check it cannot author or edit.

**Run this at the top of EVERY gate round**, before spawning the verifier. It is
idempotent by construction (wipe → re-copy → re-hash), so a round-1 freeze that a
check-15 fix invalidated is simply redone in round 2 — which is exactly why the freeze
precedes the verifier rather than following it.

**1 — copy every live gate script to the freeze root.** Layout is
`runs/<run_tag>/gates/skill-scripts/<skill-name>/<script>.sh` (e.g.
`.../skill-scripts/app-testing/check-coverage.sh`), which makes the manifest key
`<skill-name>/<script>.sh` map mechanically to both sides.

```bash
RUN_TAG=<run_tag>
FREEZE_ROOT="runs/$RUN_TAG/gates/skill-scripts"

chmod -R u+w "$FREEZE_ROOT" 2>/dev/null; rm -rf "$FREEZE_ROOT"; mkdir -p "$FREEZE_ROOT"
for src in .claude/skills/app-*/scripts/*.sh; do
  [ -f "$src" ] || continue                 # unmatched glob stays literal — skip it
  skill=$(basename "$(dirname "$(dirname "$src")")")   # .../app-testing/scripts/x.sh → app-testing
  mkdir -p "$FREEZE_ROOT/$skill"
  cp -p "$src" "$FREEZE_ROOT/$skill/"
done
```

**2 — hash every frozen copy.** `shasum -a 256` is present on macOS and Linux. The
sidecar it writes is in `shasum -c` format, so any human can re-check the freeze with
`cd runs/<run_tag>/gates/skill-scripts && shasum -a 256 -c ../frozen-gates.sha256`.

```bash
( cd "$FREEZE_ROOT" \
  && find . -type f -name '*.sh' -exec shasum -a 256 {} + | sed 's| \./| |' | sort -k2 ) \
  > "runs/$RUN_TAG/gates/frozen-gates.sha256"
cat "runs/$RUN_TAG/gates/frozen-gates.sha256"
```

**3 — record the hashes in the manifest as `frozen_gates`.** Keys are freeze-root-relative
(`<skill-name>/<script>.sh`), values are lowercase hex SHA-256. This is the single source
of truth steps 14 and 16 verify against:

```bash
python3 - "$RUN_TAG" <<'PY'
import hashlib, json, os, sys, datetime
run  = sys.argv[1]
root = f"runs/{run}/gates/skill-scripts"
frozen = {}
for d, _, fs in os.walk(root):
    for f in sorted(fs):
        if f.endswith(".sh"):
            p = os.path.join(d, f)
            frozen[os.path.relpath(p, root)] = hashlib.sha256(open(p, "rb").read()).hexdigest()
mp = f"runs/{run}/manifest.json"
m  = json.load(open(mp))
m["frozen_gates"] = dict(sorted(frozen.items()))
m["frozen_gates_frozen_at"] = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
json.dump(m, open(mp, "w"), indent=2)
print(f"frozen_gates: {len(frozen)} scripts recorded in {mp}")
PY
```

Resulting manifest shape (added alongside the existing keys, never replacing them):

```json
"frozen_gates": {
  "app-architecture/check-layers.sh": "9f2c…64 hex chars…",
  "app-code-style/check-format.sh":   "1a7b…",
  "app-testing/check-coverage.sh":    "c40e…"
},
"frozen_gates_frozen_at": "2026-07-25T14:02:11+02:00"
```

**4 — make the frozen copies read-only.** Defence in depth ONLY. The hash is the
guarantee; a permission bit is a speed bump, and 12.1b's own wipe re-grants write with
`chmod -R u+w` before `rm -rf`.

```bash
find "$FREEZE_ROOT" -type f -exec chmod a-w {} +
```

**5 — path-portability warning.** A frozen copy runs from a different directory than its
original, so a script that locates itself will behave differently:

```bash
grep -lE 'BASH_SOURCE|dirname[[:space:]]+"?\$0' "$FREEZE_ROOT"/*/*.sh 2>/dev/null
```

Any path printed is a WARNING in the report, not a failure: that script resolves paths
against its own location instead of the repo root. Note it under `### Frozen gate oracle`
so step 14's first sync point knows why a gate behaves oddly. Every gate script is
expected to use repo-root-relative paths and to be invoked from the repo root.

**FROZEN-GATE VERIFY (canonical — paste VERBATIM into the verifier spawn for check 24;
steps 14 and 16 reproduce this same block, and the copies MUST NOT drift).** Exit 0 =
clean, exit 2 = the frozen set or the manifest was tampered with, exit 3 = the LIVE
scripts diverged from the freeze.

```bash
python3 - "$RUN_TAG" <<'PY'
import hashlib, json, os, sys
run  = sys.argv[1]
root = f"runs/{run}/gates/skill-scripts"
rec  = (json.load(open(f"runs/{run}/manifest.json")).get("frozen_gates") or {})
sha  = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()
skills = ".claude/skills"
names  = sorted(os.listdir(skills)) if os.path.isdir(skills) else []
live = {}
for d in names:
    sd = f"{skills}/{d}/scripts"
    if not (d.startswith("app-") and os.path.isdir(sd)):
        continue
    for f in sorted(os.listdir(sd)):
        if f.endswith(".sh"):
            live[f"{d}/{f}"] = f"{sd}/{f}"
froz = {}
for d, _, fs in os.walk(root):
    for f in fs:
        if f.endswith(".sh"):
            p = os.path.join(d, f)
            froz[os.path.relpath(p, root)] = p
tamper, diverge = [], []
if not rec:
    tamper.append("manifest frozen_gates is missing or empty — the oracle was never frozen")
for k, want in sorted(rec.items()):
    if k not in froz:
        tamper.append(f"MISSING      {k} — frozen copy is gone")
    elif sha(froz[k]) != want:
        tamper.append(f"TAMPERED     {k} — frozen copy no longer matches its recorded sha")
for k in sorted(set(froz) - set(rec)):
    tamper.append(f"UNRECORDED   {k} — frozen file with no manifest entry")
for k in sorted(set(live) - set(rec)):
    diverge.append(f"LIVE-ADDED   {k} — live script added since the freeze")
for k in sorted(set(rec) - set(live)):
    diverge.append(f"LIVE-DELETED {k} — live script deleted since the freeze")
for k in sorted(set(live) & set(rec)):
    if sha(live[k]) != rec[k]:
        diverge.append(f"LIVE-EDITED  {k} — live script edited since the freeze")
nogate = [d for d in names
          if d.startswith("app-") and not any(k.startswith(d + "/") for k in live)]
for line in tamper + diverge:
    print(line)
if nogate:
    print("WARN no scripts/*.sh: " + ", ".join(nogate))
print(f"frozen_gates: {len(rec)} recorded, {len(froz)} frozen on disk, {len(live)} live "
      f"— {len(tamper)} tamper, {len(diverge)} divergence")
sys.exit(2 if tamper else (3 if diverge else 0))
PY
```

**Legitimate changes to a gate script are allowed — but they must be LOUD.** A
mid-run skill improvement is fine; a silent edit is not. Any accepted change to the
oracle is appended to `runs/<run_tag>/decisions/gate-changes.md` (create it on first
use) in this shape, and the run is then re-frozen through 12.1b:

```markdown
## <ISO timestamp> — <re-freeze | live edit accepted>
- script: app-testing/check-coverage.sh
- old_sha: <64 hex, or "n/a — new script">
- new_sha: <64 hex>
- decided_by: <human | step 12 round <R> | /hyperbuild-choose platform override>
- why: <one line — what the gate now checks that it did not before>
```

### Step 12.1c — Run the Tier-0 script gate (every round, before the verifier)

The deterministic half of this gate is a script the pipeline cannot edit. Run it FIRST,
every round, and let its exit code be a fact:

```bash
scripts/gate-design.sh <run_tag> \
  --json-out runs/<run_tag>/temp/design-gate-script-round-<R>.json
```

- **Exit 0** = every hard check passed (WARNs may still be present and MUST be carried
  into the report). **Exit 1** = at least one hard check FAILED — the round is already a
  fail; you still spawn the verifier (12.2) so the fix round sees the complete picture,
  exactly as with a failing checklist row. **Exit 2** = usage/environment error (no such
  run, no `python3`): that is a broken gate, not a passing one — fix the environment and
  re-run; never proceed as though it passed.
- The JSON it writes is the canonical gate-verdict schema (`checks[]` with
  `id`/`description`/`result`/`evidence`, `overall`, `failed`), plus `script_sha256` —
  record that hash in the report so the round's oracle is identifiable after the fact.
- **NEVER edit `scripts/gate-design.sh` to make a round pass.** It is not a pipeline
  artifact, it is not in any agent's write path, and a failing script check is a fact
  about `runs/`, `research/`, `features/`, `epics/` or `designs/` — fix those. If the
  script is genuinely wrong, that is a HARNESS change: stop the run, say so plainly in
  the report, and let a human edit it (same rule as `gate-changes.md` above, one level
  up). The scripts are readable by everyone and writable by nobody in the loop.
- If `scripts/gate-design.sh` is MISSING, the gate cannot pass. Record it as a hard
  failure and block — a missing oracle is not a silent pass.

### Step 12.2 — Spawn ONE `hb-gate-verifier` (the JUDGMENT residue only)

The script already decided every row it owns (see "Who executes which row"). The verifier
is spawned for the residue — and is told, in its own prompt, not to re-run the script's
checks. Re-doing them costs opus-class tokens to reproduce an exit code, and a model that
disagrees with the script is a model arguing with a fact.

**Spawn template:**
```
subagent_type: hb-gate-verifier
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 12 (design gate) of the hyperbuild
  pipeline — the Stage-A hard gate. Steps 1–11 claim to be done; you verify
  their artifacts mechanically. The DETERMINISTIC half of this gate already
  ran as code (scripts/gate-design.sh, step 12.1c) and its verdict is a
  fact you consume, not a claim you re-check: your job is the JUDGMENT
  RESIDUE listed below. You NEVER fix, edit, create, or delete any
  artifact you are checking — you check, gather evidence, and report. The
  orchestrator fixes failures and re-spawns you (max 2 rounds; round 2
  only if a Tier-0 signal changed). On your
  pass verdict the pipeline stops and waits for the user's design choice.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - round: <R>
  - script_verdict: runs/<run_tag>/temp/design-gate-script-round-<R>.json —
    the Tier-0 verdict from scripts/gate-design.sh. READ IT FIRST. Every
    check id in it (D01..D27) is ALREADY DECIDED: do not re-run it, do not
    re-litigate it, do not restate it in your own checks array. If it says
    a row failed, that row failed. You may cite its evidence when a
    judgment check of yours depends on the same artifact.
  - script_exit_code: <0|1> — the exit code of scripts/gate-design.sh this
    round, handed to you by the orchestrator
  - screen_inventory_source: research/product-spec.md — parse the screen
    inventory (including its mockup_feasibility column) FIRST; checks 16
    and 18 key off it
  - frozen_gates_root: runs/<run_tag>/gates/skill-scripts/ — check 24's
    subject. The orchestrator froze the app-*/scripts/*.sh gate oracle
    into it THIS round (step 12.1b) and recorded a SHA-256 per file in
    manifest `frozen_gates`. Steps 14 and 16 will execute ONLY these
    copies, so check 24 is the last chance to catch a mis-freeze. The
    frozen scripts are READABLE by design — freezing is immutability, not
    secrecy; never propose hiding them.
  - feature_index: features/00-index.md
  - output_path: runs/<run_tag>/temp/design-gate-checks-round-<R>.json
    (you have no Write tool — write it with a Bash heredoc)

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/manifest.json
  - research/product-spec.md
  - features/00-index.md

  YOUR CHECKS — the judgment residue, and NOTHING ELSE. Run exactly these
  and emit exactly these ids:
   4  Each competitor dossier in research/01-product-and-market/research/
      competitors/ carries a `## Sources` section with real, dated sources
      (the script already counted the dossiers; you judge whether they are
      sourced).
   5  research/01-product-and-market/author/competitor-landscape.md
      contains a real feature-matrix table.
   6  research/01-product-and-market/author/sentiment-synthesis.md carries
      a genuinely RANKED pain-point list, not an unordered pile.
   7  research/product-spec.md's MoSCoW list is a real prioritization
      (musts are not simply everything) and its screen inventory names
      every screen the feature specs reference.
   9  research/02-engineering/author/stack-guide.md contains committed
      "we will do X" decisions rather than a survey, and has a
      `## Code taxonomy` section.
  10  research/03-design-system/author/design-directions.md carries its
      `## Corrections that override the research docs` table, and those
      corrections match the area's verify/ verdicts.
  16  Every task's `category` names a category actually present in the
      stack-guide's `## Code taxonomy` (the script validated the schema;
      you validate the value against the taxonomy).
  18  Every `none` screen in the PRD inventory has a real
      `## Art direction — <Screen>` card in ALL THREE
      designs/<x>/design-system.md files (vacuous pass when there are no
      `none` screens).
  22j NO REFUTED claim survives in any author/ doc, in
      research/product-spec.md, in features/*.md, or in epics/** ; every
      PARTIALLY_TRUE claim appears only in its corrected form; no
      UNVERIFIABLE claim is the sole support for a `must` feature; every
      CONFIRMED critic finding shows a resolution in the author/ docs.
      Walk the verify/ frontmatter verdicts, then grep the downstream
      artifacts for the claim's load-bearing strings.
  24  Frozen gate oracle — run the FROZEN-GATE VERIFY block below and
      report its exit code.

  DO NOT run checks 1, 2, 3, 8, 11, 12, 13, 14, 15, 17, 19, 20, 21, 23, or
  the mechanical halves of 4/5/9/10/16/22 — scripts/gate-design.sh decided
  them this round (D01..D27 in script_verdict). Reproducing them wastes the
  round and produces a second opinion about a fact.

  STAGE-A CHECKLIST (for context — the full 24 rows, so you can see where
  your residue sits): <paste the full 24-row checklist table from this
  skill's "The Stage-A checklist" section here, verbatim, with the <gear>
  numbers applied>

  FROZEN-GATE VERIFY (check 24's executable — run it, read its exit code,
  quote every offending line into check 24's evidence): <paste the
  FROZEN-GATE VERIFY bash+python3 block from this skill's step 12.1b here,
  VERBATIM, with RUN_TAG set to <run_tag>>

  RESEARCH ARCHIVE: checks 4, 5, 6, 9, 10, and 22j all read the
  research archive, whose BINDING format contract is
  docs/RESEARCH-ARCHIVE.md — read §2 (the area layout and the FIXED area
  names), §3.2 (the closed verdict vocabulary), §4 (the provenance rule),
  and §5 (how many claims must be verified) before running them. Every
  research path is deterministic: research/<NN>-<area>/{research,verify,
  critique,author}/. A step that wrote to the OLD flat paths
  (research/competitors/, research/stack/, research/design/,
  research/stack-guide.md, ...) FAILS its check — do not "find" the file
  at a legacy path and pass the check.

  Run EVERY check with commands (ls, wc -l, grep -c, python3 for JSON and
  frontmatter validation) — never by impression. A check you cannot execute
  is FAIL with evidence "unverifiable: <reason>", not PASS. Record one
  evidence line per check: the command run + the observed value (for FAILs,
  name exactly what is missing, e.g. "designs/b/mockups has 9 of 11
  inventory screens; missing: settings.html, onboarding.html").

  OUTPUT SCHEMA (write to output_path via Bash — this is the canonical
  gate-verdict schema, identical to your agent prompt's):
  {"gate": "design", "run_tag": "<run_tag>", "round": <R>,
   "checks": [{"id": 1, "description": "Idea",
               "result": "pass" | "fail" | "warn",
               "evidence": "<command → observed value>"}],
   "overall": "pass" | "fail", "failed": <count of failing checks>}
  Your checks array holds ONLY your residue ids (4, 5, 6, 7, 9, 10, 16,
  18, 22j, 24) — never a D-id, never a row the script owns. The
  orchestrator merges your JSON with script_verdict into one report.
  "warn" is legal ONLY on check 24, and ONLY for the verify script's
  "WARN no scripts/*.sh:" line at exit 0 (an app-* skill that shipped no
  gate) — a non-zero exit is always a FAIL, never a warn. Everything else
  in your residue is pass or fail. "overall" is "pass" ONLY when zero of
  YOUR checks are "fail" — the orchestrator combines that with the
  script's exit code, and the GATE passes only when both are clean. Your
  final message: overall verdict + failed check ids + output_path. Data,
  not prose.
```

While the verifier runs, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`
— never bare text. If the verifier dies without writing its JSON, re-spawn it ONCE; if
it dies again, run the RESIDUE checks yourself via Bash/Read and write the JSON in the
canonical schema (the lock against fixing applies to the verifier's role, not to
verification itself). The script half never has this failure mode — it is a script.

### Step 12.3 — Write/append `runs/<run_tag>/gates/design-gate-report.md`

The orchestrator (not the verifier) owns the report, and it MERGES the two verdicts:
`temp/design-gate-script-round-<R>.json` (Tier 0, ids D01..D27) and
`temp/design-gate-checks-round-<R>.json` (the verifier's residue, ids 4–24). **The round
passes only when both are clean** — the script exited 0 AND the verifier's `overall` is
`pass`. Round 1 creates the report; later rounds append a `## Round <R>` section. Format:

```markdown
---
run_tag: <run_tag>
gate: design
verdict: pass | fail | blocked
rounds: <R>
created: <ISO date>
---
# Design gate report — <run_tag>

## Round <R> — <pass|fail>

### Tier 0 — scripts/gate-design.sh (exit <code> · sha256 <first 12>)
| id | Check | Status | Evidence |
|----|-------|--------|----------|
| D01 | idea.md + frontmatter | pass | <evidence line from the script JSON> |

### Tier 2 — hb-gate-verifier (judgment residue)
| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 9 | stack-guide holds committed decisions | pass | <evidence line from the verifier JSON> |

### Failures & remedies (fail rounds only)
- Check 12 → step 8 → re-spawned hb-mockup-smith for design b, screens: settings, onboarding

### Known visual issues (step 8.5 criticals: accepted after 2 rounds, or unverifiable)
| Design | Screen | Severity | What the render shows | Why it was accepted |
|--------|--------|----------|-----------------------|---------------------|
| c | item-edit | critical | "Save item" CTA is 8px under the nav | patch round moved it; re-render still clipped |

### Frozen gate oracle (step 12.1b — what steps 14 and 16 will execute)
Frozen at: <manifest frozen_gates_frozen_at> · <N> scripts · sidecar:
`runs/<run_tag>/gates/frozen-gates.sha256`

| Frozen path (manifest key) | SHA-256 (first 12) |
|---|---|
| app-testing/check-coverage.sh | c40e1f7b93a2 |

Steps 14 and 16 execute ONLY `runs/<run_tag>/gates/skill-scripts/*/*.sh` and re-verify
every hash before each execution round. The live `.claude/skills/app-*/scripts/*.sh`
originals are untouched and stay readable — freezing is immutability, not secrecy.
Warnings, when any: `app-*` skills that shipped no `scripts/*.sh` (check-24 `warn`), and
any frozen script that locates itself via `$0`/`BASH_SOURCE` (12.1b step 5).

## What I am least confident about

<3-6 entries. Each names an artifact by path and says what might be wrong with it and
why this gate would not know. Distinct from the warnings above and from
`### Known visual issues` — those are what the gate FOUND; this is where it may be
wrong and could not tell.>

- `research/02-engineering/verify/claim-07.md` — the only CONFIRMED verdict for the
  offline-sync decision rests on one vendor blog post; no independent source was found,
  so the whole storage choice in `stack-guide.md` inherits that single point of failure.
- `runs/<run_tag>/gates/visual-qa-c.json` — direction c's `item-edit` critical was
  accepted after two patch rounds. I am recording it as a known issue, but I cannot tell
  whether it is a rendering artifact of the headless screenshot or a real layout bug.
```

Update the frontmatter `verdict`/`rounds` on every round. Status cells are
`pass` | `fail` | `warn`: a D22 `warn` (screenshots skipped — no Chrome
binary, manifest `screenshots_skipped: true`), a D25 `warn` (visual QA
could not run for the same reason, or screens legitimately not viewed), a D26 `warn`
(criticals accepted as known issues after step 8.5's two rounds), and the script's
gear-range warns (D12, D13, D14, D21) each get a `⚠ WARNING` line under
the table but do NOT make the round a fail. **A D26 warn also requires the
`### Known visual issues` table**, one row per `accepted-known-issue` or
`unverifiable` critical, quoted verbatim from the `visual-qa-<x>.json` finding
(`design_letter`, `screen`, `what_is_wrong`, `acceptance_reason`) — the same
rows the stop message prints. **A D25 warn caused by a non-empty
`screens_not_viewed`** adds one row per unviewed screen to the same table
(severity `unreviewed`, "what the render shows" = the reason step 8.5 recorded)
— a screen nobody could open is exactly the thing the user must be told about.
Omit the section entirely when there are none.

A check-24 `warn` (an `app-*` skill with no `scripts/*.sh`) gets a `⚠ WARNING` line
naming the skill and does NOT fail the round. **The `### Frozen gate oracle` section is
NOT optional** — it is written on every round, pass or fail, because it is the audit
record of exactly which bytes will grade Stage B. Build its table from
`runs/<run_tag>/gates/frozen-gates.sha256`, never from memory.

**`## What I am least confident about` is MANDATORY and is written on PASS and BLOCKED
alike** — it is the pipeline's calibrated-uncertainty record, a Gate 1 checklist item
(PIPELINE.md, [Calibrated uncertainty](../../../PIPELINE.md#calibrated-uncertainty--what-i-am-least-confident-about)),
and the part of the report README tells the reader to read first. It appears ONCE, at
the end of the file, covering the whole gate — not once per round. Rules:

- **3–6 entries**, each citing an artifact by path. Fewer than 3 means you did not look;
  more than 6 means you are listing findings, not calibrating.
- **Source it from what the gate could not settle:** critic findings left unresolved;
  any `UNVERIFIABLE` verdict in a `verify/` file; areas whose claim coverage is thin
  (a D12 gear-range warn); degraded visual QA (manifest `screenshots_skipped` or
  `visual_qa_skipped` true, or a non-empty `screens_not_viewed`); and **every check this
  gate passed as a `warn`** — a warn is precisely a check that did not fully pass.
- **It is NOT a copy of `### Known visual issues`, and not a copy of the warning lines.**
  Those say what was found. This says where the verdict itself may be wrong. If an entry
  could be pasted into either of those tables unchanged, it does not belong here.
- Write it even when every check is green. A clean gate with nothing to be unsure about
  is a claim about the gate's coverage, not about the artifacts, and it is almost always
  false.

**Verify it mechanically after you write the file** — `scripts/gate-design.sh` runs at
12.1c, before the report exists, so on a clean single-round pass its D27 check records
`skip`. Close that gap with one command, and fix the report (never the command) if it
prints `MISSING`:

```bash
awk '/^## What I am least confident about[[:space:]]*$/{f=1;next} f&&/^## /{f=0}
     f&&/^[[:space:]]*[-*][[:space:]]+[^[:space:]]/{n++} END{print (n>=3 ? "OK "n : "MISSING "n+0)}' \
  runs/<run_tag>/gates/design-gate-report.md
```

### Step 12.4 — On FAIL: fix the artifacts, re-run (MAX 2 ROUNDS, the second one earned)

**The check is law.** Fix by changing artifacts; never by arguing a check is too strict,
skipping it, editing the checklist, or **editing `scripts/gate-design.sh`** — the script
is the one thing in this gate the run may not touch. Map each failed check to its
responsible step and remedy — re-spawn the responsible agent ONCE per round, per that
step's own spawn contract (verbatim idea block-quoted, pipeline position, inputs, exact
output path, read-first list), with the missing/defective artifact named as its explicit
required output.

Script failures (D-ids) map to the same lanes through the "Who executes which row" table:
D01–D03 → row 1–3, D04 → 7, D05/D14 → 8, D06/D15/D16/D17 → 16, D07/D09/D10/D12 → 22,
D08 → 5/6/10/14, D11 → 23, D13 → 4/9/10, D19 → 17, D20 → 11, D21 → 12, D22 → 19,
D23 → 13, D24 → 15, D25 → 20, D26 → 21, D27 → 12.3 (the report's own
`## What I am least confident about` section — write it, never delete the heading). **D18 (a DAG cycle or a dangling `depends_on`)
has no legacy row: its lane is step 11** — re-spawn `hb-task-author` for the offending
epic with the cycle named verbatim, or fix the `depends_on` edge directly; never "fix" a
cycle by deleting the dependency that made it visible.

| Failed check | Responsible step | Re-spawn / remedy |
|---|---|---|
| 1–3 | 1 (intake) | bootstrap artifacts — orchestrator repairs directly (frontmatter, missing rationale) |
| 4–5 | 2 (market recon) | `hb-competitor-analyst` per missing dossier; landscape → orchestrator rebuilds the matrix from dossiers |
| 6 | 3 (social mining) | `hb-sentiment-miner` for the missing platform file; synthesis → orchestrator re-merges |
| 7 | 4 (product spec) | orchestrator patches the missing PRD section (surgical edit, never regenerate the PRD) |
| 8 | 4.5 (feature specs) | write the missing feature file(s) per the features/ contract, or patch missing sections |
| 9 | 5 (stack research) | Read `runs/<run_tag>/temp/dimensions-02.md` — the derivation record names every dimension step 5 committed to. Re-spawn `hb-stack-researcher` per dimension NAMED THERE whose `research/<dimension>.md` is missing (never for a filename this check imagined); if the derivation itself is short of the gear floor, re-enter step 5 at its DERIVE step. stack-guide → orchestrator re-authors the missing decisions from the surviving claims in `runs/<run_tag>/temp/claims-02.json` |
| 10 | 6 (design research) | `hb-design-researcher` for the missing direction |
| 11 | 7 (design systems) | `hb-design-system-author` for the affected direction |
| 12–13 | 8 (mockups) | `hb-mockup-smith` scoped to exactly the missing screens × design; gallery → orchestrator patches index.html |
| 14 | 9 (skill research) | `hb-stack-researcher` re-spawn per step 9's template |
| 15 | 10 (skill forge) | `hb-skill-smith` for the missing/invalid skill |
| 16–17 | 11 (epics) | step 11's patch procedure: orchestrator writes missing tasks or re-spawns `hb-task-author` for the gap epic; rebuild the coverage matrix from disk |
| 18–19 | 8 (mockups) | check 18: re-spawn that design's `hb-mockup-smith` with only `art_direction_screens` (or orchestrator writes the missing card from the design's design-system.md + direction research); check 19: re-run step 8's headless-Chrome render for the missing PNGs — if no Chrome binary exists anywhere, set manifest `screenshots_skipped: true` and D22 warns instead of failing |
| 20 | 8.5 (visual QA) | a missing/invalid `visual-qa-<x>.json`, or a screenshot in NEITHER `screens_reviewed` nor `screens_not_viewed`: re-run `Skill(skill: "hyperbuild-8-5-visual-qa")` in its **SCOPED ENTRY** mode (that skill's "Scoped entry" section) with `scope_letters` = the affected direction(s) and `scope_screens` = the unjudged screens — it re-spawns `hb-design-critic` for those screens only and MERGES into the existing JSON, preserving prior rounds, statuses and acceptance_reasons. A non-empty `screens_not_viewed` whose entries all state a reason is a `warn`, not a defect to re-run: re-running produces the same unreadable PNG. NEVER hand-write a visual-QA file: a findings file nobody looked at pixels for is the exact failure this gate exists to catch |
| 21 | 8.5 (visual QA) | criticals still `"status": "open"` means the patch round never ran or never landed: re-run `Skill(skill: "hyperbuild-8-5-visual-qa")` in **SCOPED ENTRY** mode for those directions and screens (patch round → re-render → round-2 verdict, merged into the existing file). If its 2 rounds are already spent, step 8.5 flips them to `accepted-known-issue` with a reason — then this check warns instead of failing and the report + stop message carry them. Relabeling WITHOUT a spent patch round is forbidden |
| 22 | 2/3/3.5, 5, 6, or 9 — whichever area is malformed | A MISSING area, a platform-specific area name, or an empty `verify/` is a research-step failure, not a formatting nit. Wrong area name: `git mv` it to the FIXED name and fix the writing step's skill. Empty or thin `verify/`: re-enter that area's step and run the §5 claim→verify pass — extract the load-bearing H3 claims from its `research/` files and spawn ONE `hb-claim-verifier` PER CLAIM, all in parallel in one message, with the §6 prompt template verbatim. Never satisfy this check by writing verify files yourself from memory: an unchecked claim labelled CONFIRMED is worse than an unverified one |
| 23 | the step that wrote the file | Missing provenance block: re-spawn the agent that produced the file with the §4 requirement stated inside the prompt (it must reproduce its own prompt verbatim at the end of the file). Only when the producing agent cannot be re-spawned may the orchestrator append the exact spawn prompt it sent, from its own notes — never a reconstruction from the file's content |
| 24 | 12.1b (freeze), or 10 (skill forge) | Exit 3 (`LIVE-*` divergence) or exit 2 with only `UNRECORDED`/`MISSING` lines almost always means the live scripts changed after the round's freeze — a check-15 fix re-spawned `hb-skill-smith`, or the run came back through `/hyperbuild-revise`. Remedy: re-run 12.1b (wipe → copy → hash → chmod) and re-verify. Exit 2 with `TAMPERED` on a frozen copy that the live original still matches means someone edited inside the freeze root: re-run 12.1b and record the event in `runs/<run_tag>/decisions/gate-changes.md`. `frozen_gates` empty or zero `.sh` anywhere: step 10 shipped no gate at all — re-spawn `hb-skill-smith` per check 15's lane with `scripts/*.sh` named as a required output, THEN re-freeze. **NEVER satisfy this check by hand-writing a hash into the manifest, by deleting a live script so the sets match, or by hiding a script from the comparison** — each converts a real oracle into a decorative one |


**RUN CONTROL AT THIS ROUND BOUNDARY** (the router owns these mechanics — this is the
tool call; the authority is `hyperbuild/SKILL.md` "Run control", cited by section).
Fix rounds are one of the few in-step boundaries the router named but cannot reach from
its own text, and its file is the first thing compaction eats. Before starting the next
round:

```bash
[ -f "runs/<run_tag>/ABORT" ] && echo "ABORTED" || echo "CONTINUE"
echo "elapsed_s=$(( $(date +%s) - $(cat runs/<run_tag>/temp/step-12.start) ))"
```

- **ABORT present** (§2) → do not start the round. Write what this round proved, return
  to the router; it sets `blocked_on: "aborted-by-user"`.
- **Elapsed past this step's class ceiling** (§3 — gate class: 20 turns / 45 min) → stop and report the cap
  fired rather than trimming the round to fit underneath.
- **Bump `usage.turns`** for this step in the manifest (§4). Measured, never estimated.

After fixing, increment R and re-run 12.1b (the freeze is redone every round — a
check-15 or check-24 fix changed the very scripts being frozen), re-run
`scripts/gate-design.sh` (12.1c), then re-spawn `hb-gate-verifier` fresh (step 12.2).
Both halves re-run in FULL every round, not just the failed checks: a fix can break a
neighbour — a re-mocked screen from D21 invalidates its visual-QA review, so D25/D26
re-run too.

**MAX 2 ROUNDS TOTAL (≤2 at both gears — see the router's knobs table, where fix rounds
are the one row that does not widen with the gear). Round 2 runs ONLY if a Tier-0 signal
changed between attempts** — a test flipped, a script gate's exit code flipped, a
re-render differs, a file that was absent now exists, or a count that was short now
clears. Record WHICH signal changed, with the evidence (the two values, before → after),
in `runs/<run_tag>/temp/orchestrator-notes.md` before you re-run anything. Same red
checks + same evidence + no changed signal → **do NOT re-run the gate**: set
`blocked_on` and write the honest report immediately (12.6). Re-running an unchanged
gate is the model talking itself into a different answer; unaided re-attempts degrade
rather than converge (PIPELINE.md principle 7).

Never mark the gate passed by hand — it passes only when `scripts/gate-design.sh` exits
0 AND the verifier JSON says `"overall": "pass"`. One of the two alone is half a gate.

### Step 12.5 — On PASS: set the manifest, then make THE ONE PERMITTED STOP

Order matters — the stop message ends the turn, so bookkeeping comes FIRST:

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "done"`,
   `blocked_on = "design-choice"`. `stage` stays `"PLAN"` —
   `/hyperbuild-choose` flips it to `"BUILD"`; the router and
   `hyperbuild-choose` both key the parked state off `blocked_on`.
   (Read the JSON, modify, Write it back whole.)
2. Set report frontmatter `verdict: pass`. Mark the step-12 todo complete.
3. **Write `research/README.md` — the areas index + THE REUSABILITY GUIDE.** This is
   step 12's only authored artifact, and `docs/RESEARCH-ARCHIVE.md` §8 is its binding
   format. The research the run just paid for is the most portable thing it produced;
   without this file the next checkout re-buys it. Build it FROM DISK, never from
   memory of the run:
   - The areas table — one row per area: link to its `_INDEX.md`, the `run_tag`, the
     agent count (count files under `research/`, `verify/`, `critique/`, `author/`),
     and the reusability verdict.
   - The THREE portability buckets from §8, with EVERY area — and, where an area
     splits, every file — named in exactly one of them: **Portable to ANY app** (store
     policy, privacy labels, licensing, pricing mechanics, skill-authoring craft);
     **Portable to any app on this platform (`<platform>` — from
     `decisions/platform.md`)** (architecture, project structure, the state library's
     API, testing corpus, lints, CI, performance, the platform's design-system status);
     **Specific to THIS app — context only** (domain research, the competitor set,
     audience pain points). A bucket assignment nobody can act on ("mostly reusable")
     is a defect; name files.
   - The mechanics: copy `02-engineering/`, `03-design-system/`, and/or
     `04-claude-skills/` into a new checkout's `research/` BEFORE running
     `/hyperbuild` — the FIXED area names make the copy path-compatible with zero
     edits; record the capture date and RE-VERIFY any specific version, price, or
     policy older than 90 days with the §6 verifier prompt.
   - The honest gaps: every REFUTED and PARTIALLY_TRUE verdict a downstream artifact
     rests on (read the `verify/` frontmatter), every dimension whose claims were
     never fact-checked, every unresolved critic finding, and any known bad premise
     (§6's premise trap). An honest gap beats a clean-looking index.
4. Gather the summary numbers FROM DISK: competitor count
   (`research/01-product-and-market/research/competitors/`),
   top 5 pain points (first 5 of the ranked list in
   `research/01-product-and-market/author/sentiment-synthesis.md`),
   platform + one-line rationale (`runs/<run_tag>/decisions/platform.md`), epic/task
   counts (`epics/00-overview.md` frontmatter), design names (each
   `designs/<x>/design-system.md`), mockable screen count (PRD inventory
   `full`/`partial` rows), whether manifest `screenshots_skipped` is true, and —
   from the three `gates/visual-qa-<x>.json` files — the visual-QA totals
   (screens reviewed, findings fixed) plus EVERY finding with
   `"status": "accepted-known-issue"` or `"unverifiable"` (design letter, screen,
   `what_is_wrong`).
5. Emit the stop message — bare text, user-facing, the LAST thing you output:

```markdown
## Stage A complete — pick a design to start the build

**<app name>** (run `<run_tag>`, gear <gear>) is researched, designed, and planned.

- **Market:** <N> competitors analyzed — full matrix in
  research/01-product-and-market/author/competitor-landscape.md
- **Top 5 user pain points**
  (research/01-product-and-market/author/sentiment-synthesis.md):
  1. <pain point one-liner>
  2. <...>  3. <...>  4. <...>  5. <...>
- **Platform:** <platform> — <one-sentence rationale from decisions/platform.md>
- **Backlog:** <E> epics, <T> tasks — every must/should feature covered (epics/00-overview.md)
- **Designs:** 3 complete systems, all <K> full/partial screens mocked in each:
  - **a — <design name>**: <one-line character>
  - **b — <design name>**: <one-line character>
  - **c — <design name>**: <one-line character>
- **Visual QA:** every rendered screen was reviewed against docs/DESIGN-CRAFT.md — <N> defects found, <M> fixed and re-rendered

**Known visual issues** (found by visual QA, still present after 2 fix rounds — look at these before you choose):
- **<letter> / <Screen>** — <what_is_wrong>

**Compare them side by side** — open the gallery in your browser:

    open runs/<run_tag>/designs/index.html

(macOS: `open` · Linux: `xdg-open` · Windows: `start`)

When you've picked, run `/hyperbuild-choose a|b|c`
(optionally `/hyperbuild-choose <a|b|c> <platform>` to override the platform)

Not ready to pick? Two levers, both of which change things and park the run back here:
- `/hyperbuild-revise <what to change>` — change the idea, a feature, one direction's look, or how the epics are split
- `/hyperbuild-redesign [notes]` — new design directions; say what to KEEP ("keep c, replace a and b") and what to fix
```

Drop the **Known visual issues** block entirely when every visual-QA critical
was fixed (D26 `pass`) — never print an empty heading. When it IS printed,
one bullet per `accepted-known-issue` / `unverifiable` finding, `what_is_wrong`
quoted verbatim from the JSON: the user is choosing a design and deserves to
know which screens are still broken.

If the passing round's D22 was `warn`, insert one line above the gallery
instructions: `- **Warning:** mockup screenshots were skipped (no Chrome binary
found) — step 15's fidelity review will lack rendered references.` If D25
was `warn`, add: `- **Warning:** visual QA could not run without renders — no
screen in these designs has been checked for clipping, overlap, or craft.`

The message MUST end with the `/hyperbuild-choose a|b|c` line plus the two
change-of-mind lines that follow it (`/hyperbuild-revise`, `/hyperbuild-redesign`) —
`/hyperbuild-choose` is the only lever that RESUMES the pipeline, and the other two are
the only way a user who dislikes what they see learns that changing it is supported
instead of starting over. Nothing else may follow that block. Then END THE TURN.

When `/hyperbuild-revise` or `/hyperbuild-redesign` is what drove this gate run, that
skill injects its own summary lines directly ABOVE the `/hyperbuild-choose` line; the
three command lines stay in the same order regardless.

### Step 12.6 — Rounds spent (or round 2 not earned): BLOCKED, honestly

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "blocked"`,
   `blocked_on = "design-gate"`. Leave `stage` unchanged.
2. Set report frontmatter `verdict: blocked`; the final round section lists every
   still-failing check with its evidence and what was attempted each round. **Write
   `## What I am least confident about` here too** (12.3's rules, verified with the same
   awk one-liner) — a blocked gate is exactly when the reader most needs to know which of
   its red checks the gate itself is unsure about.
3. Emit an honest final message: which checks still fail, verbatim evidence, what was
   tried, and what a human can do (fix the named artifacts, then re-run `/hyperbuild` —
   the router resumes at step 12). **Never soften a failing gate into a pass.** A
   blocked run that says so is a working pipeline; a passed gate over missing artifacts
   is a broken one.

---

## Artifacts

- `runs/<run_tag>/temp/design-gate-script-round-<R>.json` — one per round, written by `scripts/gate-design.sh` (12.1c): the Tier-0 verdict, ids D01..D27, carrying the script's own `script_sha256` so the round's oracle is identifiable after the fact
- `runs/<run_tag>/temp/design-gate-checks-round-<R>.json` — one per round (verifier-written, canonical schema above): the judgment residue only
- `runs/<run_tag>/gates/design-gate-report.md` — frontmatter: run_tag, gate, verdict, rounds, created; per-round Tier-0 + Tier-2 check tables + the `### Frozen gate oracle` section + the mandatory `## What I am least confident about` section (3–6 entries, each citing an artifact by path), written on PASS and BLOCKED alike
- `runs/<run_tag>/gates/skill-scripts/<skill-name>/<script>.sh` — THE FROZEN ORACLE (12.1b): a read-only copy of every `.claude/skills/app-*/scripts/*.sh`. Steps 14 and 16 execute these and nothing else. Rewritten from the live scripts at the top of every gate round; never edited in place, by anyone
- `runs/<run_tag>/gates/frozen-gates.sha256` — the `shasum -c`-format sidecar of the same hashes, so a human can re-verify the freeze in one command
- `runs/<run_tag>/decisions/gate-changes.md` — appended ONLY when a gate script legitimately changed (re-freeze or accepted live edit): script, old/new sha, who decided, why. Absent on a clean run
- `runs/<run_tag>/manifest.json` — updated: `frozen_gates` (freeze-root-relative path → SHA-256) + `frozen_gates_frozen_at` every round; pass → `steps.12="done"`, `blocked_on="design-choice"` (stage stays `"PLAN"`); blocked → `steps.12="blocked"`, `blocked_on="design-gate"`
- `research/README.md` — REWRITTEN on pass (12.5 step 3): the areas index + the REUSABILITY GUIDE, per `docs/RESEARCH-ARCHIVE.md` §8. This step's only authored artifact.

## Exit criteria

- Final round's `design-gate-script-round-<R>.json` exists with an `overall` verdict, and `scripts/gate-design.sh` was actually executed this round (never assumed, never transcribed by hand)
- Final round's `design-gate-checks-round-<R>.json` exists with an `overall` verdict
- `runs/<run_tag>/gates/design-gate-report.md` exists; frontmatter verdict is `pass` or `blocked` (never silently absent), carries BOTH the Tier-0 and Tier-2 check tables, the `### Frozen gate oracle` section, and a non-empty `## What I am least confident about` section with 3–6 entries that each cite an artifact by path — on PASS and on BLOCKED
- THE ORACLE IS FROZEN: `runs/<run_tag>/gates/skill-scripts/` holds ≥1 `.sh`, manifest `frozen_gates` is a non-empty map whose keys and hashes match those files AND their live originals, and the FROZEN-GATE VERIFY script exits 0. Stage B may not start without this — steps 14 and 16 execute the frozen copies exclusively, and a run with no freeze has an oracle its own build agents can rewrite
- PASS: manifest shows `steps.12="done"` + `blocked_on="design-choice"` (stage still `"PLAN"`); step-12 todo complete; stop message emitted, ending with the `/hyperbuild-choose a|b|c` line followed by the two change-of-mind lines (`/hyperbuild-revise <what to change>`, `/hyperbuild-redesign [notes]`) and nothing else
- PASS: `scripts/gate-design.sh <run_tag>` exited 0 in the final round AND the verifier's residue JSON says `"overall": "pass"` — both halves, or the gate did not pass
- PASS with a D26 `warn`: every `accepted-known-issue` critical appears BOTH as a row in the report's `### Known visual issues` table and as a bullet in the stop message — a passing gate never hides a broken screen from the person choosing the design
- PASS: `research/README.md` exists, links all four `_INDEX.md` files, and classifies every area (and every split file) into exactly one of the three portability buckets by name, with the capture date and the honest-gaps section filled in — the run's research is worthless to the next checkout without it
- BLOCKED: manifest shows `steps.12="blocked"` + `blocked_on="design-gate"`; honest failure message emitted

## Next step

There is none — **do NOT invoke any Skill()**. Stage A ends here. The pipeline resumes
when the user runs `/hyperbuild-choose <a|b|c>`, which records
`runs/<run_tag>/decisions/design-choice.md`, copies the chosen tokens to `app/design/`,
sets manifest `stage=BUILD`, and re-invokes the router to drive Stage B (steps 13–16).
