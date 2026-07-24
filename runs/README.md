# runs/ — run workspaces

One directory per pipeline run, created at runtime by step 1 (`appbuilder-1-intake`).
This directory holds RUN STATE: the gospel idea, the manifest, the three candidate
designs, the decisions, and the gate reports. It is pipeline-owned — NEVER hand-edit
anything under `runs/` (the one interface for human input is `/appbuilder-choose`, and
even that writes its file through the skill, not your editor).

One harness checkout = one app, so there is normally exactly one run workspace here.
A second idea gets a fresh clone of the harness in a new folder.

## Run tag

`<idea-slug>-<6 random hex chars>`, e.g. `habit-coach-3f9a2c`. Minted once by step 1;
it names this directory, appears in `idea.md` and `manifest.json`, and is stamped into
the frontmatter of every research artifact for provenance.

## The workspace tree

```
runs/<run_tag>/
├── idea.md                    # GOSPEL: verbatim user idea + frontmatter (run_tag, created, platform)
├── manifest.json              # {run_tag, stage, platform, gear, steps, design_choice, blocked_on}
├── scaffold.md                # orchestrator's private planning doc (never ships)
├── temp/
│   ├── orchestrator-notes.md  # anti-idle thinking log while subagents run
│   └── wave-log.md            # step 14's wave ledger: `wave <N>: [<task ids>]`, logged BEFORE each wave spawns
├── designs/
│   ├── index.html             # gallery comparing all three designs (step 8) — OPEN THIS
│   └── {a,b,c}/
│       ├── design-system.md   # full system: principles, type scale, color, spacing, components
│       ├── tokens.css         # CSS custom properties
│       ├── mockups/<screen>.html      # one self-contained HTML per mockable (full/partial) screen
│       └── screenshots/<screen>.png   # headless-Chrome render of every mockup (step 8) — the visual spec steps 14–15 compare against
├── decisions/
│   ├── platform.md            # chosen stack + rationale (step 1)
│   └── design-choice.md       # written by /appbuilder-choose
└── gates/
    ├── design-gate-report.md  # step 12
    └── ship-report.md         # step 16
```

## File contracts

### idea.md — the gospel

The user's idea, VERBATIM — byte-for-byte, never paraphrased, never "cleaned up".
Written exactly once by step 1; read by every step and block-quoted into every subagent
spawn prompt for the rest of the run.

```markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
platform: flutter
---

a habit tracker that coaches you with weekly insights, mobile-first
```

### manifest.json — the resume point

Records step transitions. The router reads it FIRST on any resume.

```json
{
  "run_tag": "habit-coach-3f9a2c",
  "stage": "PLAN",
  "platform": "flutter",
  "gear": "standard",
  "steps": {"1": "done", "2": "done", "3": "done", "3.5": "done", "4": "done", "4.5": "done"},
  "design_choice": null,
  "blocked_on": null
}
```

- `stage` — `"PLAN"` (steps 1–12) or `"BUILD"` (steps 13–16). Flipped to `"BUILD"` by
  `/appbuilder-choose`.
- `gear` — `"standard"` (default) or `"premier"`; recorded by step 1, read by every step
  for its scale numbers.
- `steps` — map of step number (`"1"` … `"16"`, including `"3.5"` and `"4.5"`) → `"done"`, written
  at each step's exit. The resume point is the first step in pipeline order without a
  `"done"` entry.
- `design_choice` — `null` until `/appbuilder-choose` writes `"a"`, `"b"`, or `"c"`.
- `blocked_on` — `null`, `"design-choice"` (set by step 12 at the gate), or an honest
  description of a ship-gate failure after 3 exhausted fix rounds (step 16).

Resume ladder (owned by the router skill `appbuilder`): manifest first, TodoWrite
second, artifact scan third — the router carries the full step→canonical-artifact
table. If `design_choice` is set and `stage` is `BUILD`, the router continues at the
first unfinished build step.

### scaffold.md

The orchestrator's private planning document: working notes, spawn bookkeeping, open
questions. It never ships and is never an input contract for any subagent.

### temp/orchestrator-notes.md

The anti-idle log. While subagent Tasks are in flight the orchestrator MUST NOT emit
bare text (in headless mode a text-only response ends the turn and kills the pipeline);
instead it appends evolving thoughts here. Ephemeral by definition — step 14's
per-epic findings and patch logs land here too. (Step 15's whole-app critic findings
live under `gates/` instead: `review-findings-{code,spec,ux}.json`,
`review-merged.json`, `review-patch-log.json`.)

### temp/wave-log.md

Step 14's wave ledger: one `wave <N>: [<task ids>]` line per implementation wave,
appended BEFORE the wave spawns. The matching `wave <N>:` git commit in `app/` lands
at the wave's sync point — so a logged wave with NO matching commit is a dead
(crashed) wave, which is exactly what step 14's crash-resume ladder keys on (dead
lines get a ` — DEAD` annotation on resume). Step 14 owns and reads it; the ship
gate's git-clean check requires a `wave <N>:` commit for every non-DEAD logged wave.

### designs/

Written by steps 7 (`design-system.md`, `tokens.css`) and 8 (`mockups/`, `index.html`).
Three complete, competing design systems — `a`, `b`, `c` — each with one self-contained
HTML mockup per screen in the PRD's screen inventory (cap 12 standard / 20 premier),
built with real PRD content, never lorem ipsum. `designs/index.html` is the side-by-side
gallery you open at the design gate to make the run's one human decision.

### decisions/

- `platform.md` — step 1's resolved stack + rationale (stated in the idea wins;
  otherwise inferred, with the inference explained).
- `design-choice.md` — written by `/appbuilder-choose`: which design won, and the
  recorded paths of the `tokens.css` + `design-system.md` copies placed in `app/design/`.

### gates/

- `design-gate-report.md` — step 12's per-check evidence for the Stage-A checklist.
- `ship-report.md` — step 16's per-check evidence: what was built, how to run it, test
  count, known gaps. If the run is blocked, this file says exactly what is red and why.

## What does NOT live here

The pipeline's durable deliverables live at the repo root, not in the run workspace:
`research/` (steps 2–9, incl. step 3.5's `research-audit.md`), `features/` (step 4.5),
`epics/` (step 11), and `app/`
(steps 13–16). Each research file's frontmatter carries `run_tag` + `created`, so
provenance survives even when a vault outlives its run. See each directory's README for
its format contract.

## Rules

- **NEVER hand-edit files under `runs/`.** The manifest is the resume point; a
  hand-edited manifest makes the router resume into a lie.
- **idea.md is written once and never modified.** If the idea was wrong, that's a new
  run (a fresh harness clone), not an edit.
- **`scaffold.md` and `temp/` never ship** and are never cited as evidence in gate
  reports.
- **Only `/appbuilder-choose` writes `decisions/design-choice.md`.** Editing it directly
  skips the manifest update and the `app/design/` copy, and Stage B will build against
  nothing.
