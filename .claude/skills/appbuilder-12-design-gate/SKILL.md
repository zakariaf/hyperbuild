---
name: appbuilder-12-design-gate
description: >
  Step 12 of the appbuilder pipeline — the Stage-A hard gate and THE ONE
  permitted stop. Spawns 1 ab-gate-verifier to mechanically run the full
  Stage-A checklist (research vault, PRD, feature specs, stack guide, 3
  complete design systems with every full/partial screen mocked +
  screenshotted and art-direction cards for none screens, generated skills, full
  backlog with PRD↔epics coverage), writes
  runs/<run_tag>/gates/design-gate-report.md, and on pass stops the pipeline
  with a user-facing summary ending in "run /appbuilder-choose a|b|c",
  setting manifest blocked_on: "design-choice". On fail: fix artifacts,
  re-run the gate, max 3 rounds, then blocked + honest report. Invoked by
  the appbuilder router via Skill(); not run directly by users.
---

# Step 12 — Design gate (Stage-A hard gate + THE ONE PERMITTED STOP)

**⚠ READ FIRST — the two ways to violate this step.** (1) This is the ONLY point in
the entire pipeline where you intentionally end the turn with a bare-text, user-facing
message. Everywhere else bare text kills the run; HERE the stop IS the deliverable.
(2) The inverse: **if the gate passes, do NOT invoke `Skill(skill:
"appbuilder-13-scaffold")`.** Stage B starts only when the user runs
`/appbuilder-choose <a|b|c>`. If you find yourself about to continue into Stage B after
a pass, STOP. Set the manifest, emit the stop message, end the turn.

You are executing step 12 (design gate) of the appbuilder pipeline. Steps 1–11 claim
Stage A is complete; this step proves it against artifacts on disk, then hands the user
the one decision the pipeline cannot make: which design to build.

**Goal:** a passing `runs/<run_tag>/gates/design-gate-report.md` and a final user-facing
summary ending with `run /appbuilder-choose a|b|c` — or, after 3 failed fix rounds, an
honest blocked report. Gate failures are fixed by changing the artifacts, NEVER by
re-interpreting the checks.

---

## Inputs

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`; steps 1–11 must read `done`; `screenshots_skipped` (when `true`, check 19 downgrades to a WARNING)
- `runs/<run_tag>/idea.md` — verbatim idea. GOSPEL.
- `research/product-spec.md` — the canonical screen inventory, including its `mockup_feasibility` column (checks 12, 17, 18, and 19 key off it)
- `features/00-index.md` — the must/should feature ids
- Everything else Stage A wrote — enumerated check by check below

## The Stage-A checklist (canonical — paste VERBATIM into the verifier spawn)

Gear numbers: use the standard column unless manifest `gear` is `premier`.

| # | Check | Pass condition |
|---|-------|----------------|
| 1 | Idea | `runs/<run_tag>/idea.md` exists; frontmatter has run_tag, created, platform; body non-empty |
| 2 | Manifest | `runs/<run_tag>/manifest.json` is valid JSON; steps 1–11 all `"done"` |
| 3 | Platform decision | `runs/<run_tag>/decisions/platform.md` exists; names the stack; contains a rationale |
| 4 | Competitor dossiers | ≥6 (standard) / ≥12 (premier) files in `research/competitors/`; each has frontmatter + a `## Sources` section |
| 5 | Landscape | `research/competitor-landscape.md` exists; contains a feature-matrix table |
| 6 | Sentiment | `research/sentiment/{reddit,hn-forums,appstore-reviews,linkedin-x}.md` all exist; `research/sentiment-synthesis.md` has a ranked pain-point list |
| 7 | PRD | `research/product-spec.md` exists; has a MoSCoW feature list AND a screen inventory section |
| 8 | Feature specs | `features/00-index.md` exists; one `features/NN-<slug>.md` per must/should PRD feature (≤15 standard / ≤25 premier files); each has moscow + screens frontmatter and all 8 body sections |
| 9 | Stack research | `research/stack/{architecture,structure,testing,tooling-ci}.md` + `research/stack-guide.md` exist; stack-guide contains committed "we will do X" decisions |
| 10 | Design research | exactly 3 direction docs in `research/design/` |
| 11 | Design systems | for EACH of a, b, c: `runs/<run_tag>/designs/<x>/design-system.md` AND `tokens.css` exist |
| 12 | Mockup completeness | for EACH of a, b, c: `designs/<x>/mockups/` has one `.html` per `full`/`partial` screen in the PRD screen inventory's `mockup_feasibility` column (cap 12 standard / 20 premier); NO `.html` for `none` screens; the SAME screen set across all three designs |
| 13 | Gallery | `runs/<run_tag>/designs/index.html` exists; references all three designs' mockups |
| 14 | Skill-authoring guide | `research/skill-authoring-guide.md` exists |
| 15 | Generated skills | `.claude/skills/<name>/SKILL.md` exists with valid frontmatter for ALL five: app-code-style, app-architecture, app-testing, app-components, app-review-checklist |
| 16 | Backlog shape | `epics/00-overview.md` exists with a PRD coverage matrix; epic count 4–8 (standard) / 6–12 (premier); every epic dir has `epic.md` + 3–8 (standard) / 4–10 (premier) task files; every task has valid frontmatter (id, epic, status: todo, depends_on, size, category, features, files — `category` naming a category present in `research/stack-guide.md`'s `## Code taxonomy`; `files` a non-empty list of planned repo-relative paths — step 14's wave-disjointness key) |
| 17 | PRD↔epics coverage | every must/should feature id from `features/00-index.md` appears in ≥1 task's `features:` frontmatter; zero blank Tasks cells on must/should rows of the coverage matrix |
| 18 | Art-direction cards | every `none` screen in the PRD inventory has a `## Art direction — <Screen>` card in EACH of the 3 `designs/<x>/design-system.md` files (vacuous pass when the inventory has no `none` screens) |
| 19 | Mockup screenshots | for EACH of a, b, c: `designs/<x>/screenshots/` has one non-empty `.png` per mockup `.html`; when manifest `screenshots_skipped` is `true`, missing screenshots are a WARNING (result `warn`), not a fail |

---

## Procedure

### Step 12.1 — Recover state

Read `runs/<run_tag>/manifest.json` (run_tag, gear) and `runs/<run_tag>/idea.md`. Set
round R = 1 (or resume: if `temp/design-gate-checks-round-*.json` files exist, R = max
round + 1).

### Step 12.2 — Spawn ONE `ab-gate-verifier`

**Spawn template:**
```
subagent_type: ab-gate-verifier
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 12 (design gate) of the appbuilder
  pipeline — the Stage-A hard gate. Steps 1–11 claim to be done; you verify
  their artifacts mechanically. You NEVER fix, edit, create, or delete any
  artifact you are checking — you check, gather evidence, and report. The
  orchestrator fixes failures and re-spawns you (max 3 rounds). On your
  pass verdict the pipeline stops and waits for the user's design choice.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - round: <R>
  - screen_inventory_source: research/product-spec.md — parse the screen
    inventory (including its mockup_feasibility column) FIRST; checks 12,
    17, 18, and 19 key off it
  - screenshots_flag: manifest `screenshots_skipped` (absent/false/true) —
    when true, check 19 records `warn` instead of `fail`
  - feature_index: features/00-index.md
  - output_path: runs/<run_tag>/temp/design-gate-checks-round-<R>.json
    (you have no Write tool — write it with a Bash heredoc)

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/manifest.json
  - research/product-spec.md
  - features/00-index.md

  STAGE-A CHECKLIST: <paste the full 19-row checklist table from this
  skill's "The Stage-A checklist" section here, verbatim, with the <gear>
  numbers applied>

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
  "warn" is legal ONLY on check 19 and ONLY when manifest
  screenshots_skipped is true. "overall" is "pass" ONLY when zero checks
  are "fail" — a check-19 "warn" passes the gate but MUST appear in the
  report as a WARNING. Your final message: overall verdict + failed
  check ids + output_path. Data, not prose.
```

While the verifier runs, append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`
— never bare text. If the verifier dies without writing its JSON, re-spawn it ONCE; if
it dies again, run the checklist yourself via Bash and write the JSON in the canonical
schema (the lock against fixing applies to the verifier's role, not to verification
itself).

### Step 12.3 — Write/append `runs/<run_tag>/gates/design-gate-report.md`

The orchestrator (not the verifier) owns the report. Round 1 creates it; later rounds
append a `## Round <R>` section. Format:

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
| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 1 | Idea | pass | <evidence line from the JSON> |

### Failures & remedies (fail rounds only)
- Check 12 → step 8 → re-spawned ab-mockup-smith for design b, screens: settings, onboarding
```

Update the frontmatter `verdict`/`rounds` on every round. Status cells are
`pass` | `fail` | `warn`: a check-19 `warn` (screenshots skipped — no Chrome
binary, manifest `screenshots_skipped: true`) gets a `⚠ WARNING` line under the
table but does NOT make the round a fail.

### Step 12.4 — On FAIL: fix the artifacts, re-run (max 3 rounds)

**The check is law.** Fix by changing artifacts; never by arguing a check is too strict,
skipping it, or editing the checklist. Map each failed check to its responsible step and
remedy — re-spawn the responsible agent ONCE per round, per that step's own spawn
contract (verbatim idea block-quoted, pipeline position, inputs, exact output path,
read-first list), with the missing/defective artifact named as its explicit required
output:

| Failed check | Responsible step | Re-spawn / remedy |
|---|---|---|
| 1–3 | 1 (intake) | bootstrap artifacts — orchestrator repairs directly (frontmatter, missing rationale) |
| 4–5 | 2 (market recon) | `ab-competitor-analyst` per missing dossier; landscape → orchestrator rebuilds the matrix from dossiers |
| 6 | 3 (social mining) | `ab-sentiment-miner` for the missing platform file; synthesis → orchestrator re-merges |
| 7 | 4 (product spec) | orchestrator patches the missing PRD section (surgical edit, never regenerate the PRD) |
| 8 | 4.5 (feature specs) | write the missing feature file(s) per the features/ contract, or patch missing sections |
| 9 | 5 (stack research) | `ab-stack-researcher` for the missing topic doc; stack-guide → orchestrator re-merges decisions |
| 10 | 6 (design research) | `ab-design-researcher` for the missing direction |
| 11 | 7 (design systems) | `ab-design-system-author` for the affected direction |
| 12–13 | 8 (mockups) | `ab-mockup-smith` scoped to exactly the missing screens × design; gallery → orchestrator patches index.html |
| 14 | 9 (skill research) | `ab-stack-researcher` re-spawn per step 9's template |
| 15 | 10 (skill forge) | `ab-skill-smith` for the missing/invalid skill |
| 16–17 | 11 (epics) | step 11's patch procedure: orchestrator writes missing tasks or re-spawns `ab-task-author` for the gap epic; rebuild the coverage matrix from disk |
| 18–19 | 8 (mockups) | check 18: re-spawn that design's `ab-mockup-smith` with only `art_direction_screens` (or orchestrator writes the missing card from the design's design-system.md + direction research); check 19: re-run step 8.6's headless-Chrome render for the missing PNGs — if no Chrome binary exists anywhere, set manifest `screenshots_skipped: true` and check 19 warns instead of failing |

After fixing, increment R and re-spawn `ab-gate-verifier` fresh (step 12.2 — full 19
checks again, not just the failed ones: a fix can break a neighbor). **Max 3 rounds
total** (≤3 both gears). Never mark the gate passed by hand — only a verifier JSON with
`"overall": "pass"` passes it.

### Step 12.5 — On PASS: set the manifest, then make THE ONE PERMITTED STOP

Order matters — the stop message ends the turn, so bookkeeping comes FIRST:

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "done"`,
   `blocked_on = "design-choice"`. `stage` stays `"PLAN"` —
   `/appbuilder-choose` flips it to `"BUILD"`; the router and
   `appbuilder-choose` both key the parked state off `blocked_on`.
   (Read the JSON, modify, Write it back whole.)
2. Set report frontmatter `verdict: pass`. Mark the step-12 todo complete.
3. Gather the summary numbers FROM DISK: competitor count (`research/competitors/`),
   top 5 pain points (first 5 of the ranked list in `research/sentiment-synthesis.md`),
   platform + one-line rationale (`runs/<run_tag>/decisions/platform.md`), epic/task
   counts (`epics/00-overview.md` frontmatter), design names (each
   `designs/<x>/design-system.md`), mockable screen count (PRD inventory
   `full`/`partial` rows), and whether manifest `screenshots_skipped` is true.
4. Emit the stop message — bare text, user-facing, the LAST thing you output:

```markdown
## Stage A complete — pick a design to start the build

**<app name>** (run `<run_tag>`, gear <gear>) is researched, designed, and planned.

- **Market:** <N> competitors analyzed — full matrix in research/competitor-landscape.md
- **Top 5 user pain points** (research/sentiment-synthesis.md):
  1. <pain point one-liner>
  2. <...>  3. <...>  4. <...>  5. <...>
- **Platform:** <platform> — <one-sentence rationale from decisions/platform.md>
- **Backlog:** <E> epics, <T> tasks — every must/should feature covered (epics/00-overview.md)
- **Designs:** 3 complete systems, all <K> full/partial screens mocked in each:
  - **a — <design name>**: <one-line character>
  - **b — <design name>**: <one-line character>
  - **c — <design name>**: <one-line character>

**Compare them side by side** — open the gallery in your browser:

    open runs/<run_tag>/designs/index.html

(macOS: `open` · Linux: `xdg-open` · Windows: `start`)

When you've picked, run `/appbuilder-choose a|b|c`
```

If the passing round's check 19 was `warn`, insert one line above the gallery
instructions: `- **Warning:** mockup screenshots were skipped (no Chrome binary
found) — step 15's fidelity review will lack rendered references.`

The message MUST end with the `/appbuilder-choose a|b|c` line — it is the user's only
lever to resume the pipeline. Then END THE TURN. Nothing after it.

### Step 12.6 — After 3 failed rounds: BLOCKED, honestly

1. Update `runs/<run_tag>/manifest.json`: `steps.12 = "blocked"`,
   `blocked_on = "design-gate"`. Leave `stage` unchanged.
2. Set report frontmatter `verdict: blocked`; the final round section lists every
   still-failing check with its evidence and what was attempted each round.
3. Emit an honest final message: which checks still fail, verbatim evidence, what was
   tried, and what a human can do (fix the named artifacts, then re-run `/appbuilder` —
   the router resumes at step 12). **Never soften a failing gate into a pass.** A
   blocked run that says so is a working pipeline; a passed gate over missing artifacts
   is a broken one.

---

## Artifacts

- `runs/<run_tag>/temp/design-gate-checks-round-<R>.json` — one per round (verifier-written, canonical schema above)
- `runs/<run_tag>/gates/design-gate-report.md` — frontmatter: run_tag, gate, verdict, rounds, created; per-round check tables
- `runs/<run_tag>/manifest.json` — updated: pass → `steps.12="done"`, `blocked_on="design-choice"` (stage stays `"PLAN"`); blocked → `steps.12="blocked"`, `blocked_on="design-gate"`

## Exit criteria

- Final round's `design-gate-checks-round-<R>.json` exists with an `overall` verdict
- `runs/<run_tag>/gates/design-gate-report.md` exists; frontmatter verdict is `pass` or `blocked` (never silently absent)
- PASS: manifest shows `steps.12="done"` + `blocked_on="design-choice"` (stage still `"PLAN"`); step-12 todo complete; stop message emitted ending with `run /appbuilder-choose a|b|c`
- BLOCKED: manifest shows `steps.12="blocked"` + `blocked_on="design-gate"`; honest failure message emitted

## Next step

There is none — **do NOT invoke any Skill()**. Stage A ends here. The pipeline resumes
when the user runs `/appbuilder-choose <a|b|c>`, which records
`runs/<run_tag>/decisions/design-choice.md`, copies the chosen tokens to `app/design/`,
sets manifest `stage=BUILD`, and re-invokes the router to drive Stage B (steps 13–16).
