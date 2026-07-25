# runs/ — run workspaces

One directory per pipeline run, created at runtime by step 1 (`hyperbuild-1-intake`).
This directory holds RUN STATE: the gospel idea, the manifest, the three candidate
designs, the decisions, and the gate reports. It is pipeline-owned — NEVER hand-edit
anything under `runs/` (the one interface for human input is `/hyperbuild-choose`, and
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
├── manifest.json              # {run_tag, stage, platform, gear, steps, usage, usage_summary,
│                              #  frozen_gates, design_choice, blocked_on}
├── .lock                      # concurrency guard: {pid, host, claimed} — claimed by the router
│                              #   before any step, released at every stop. Machine-local, never committed
├── ABORT                      # THE KILL SWITCH — created by the HUMAN (`touch`), checked by the
│                              #   router between every step. Absent on a healthy run
├── scaffold.md                # orchestrator's private planning doc (never ships)
├── temp/
│   ├── orchestrator-notes.md  # anti-idle thinking log while subagents run
│   ├── step-<N>.start         # unix start stamp per step — the router's wall-clock measurement
│   └── wave-log.md            # step 14's wave ledger: `wave <N>: [<task ids>]`, logged BEFORE each wave spawns
├── designs/
│   ├── index.html             # gallery comparing all three designs (step 8) — OPEN THIS
│   ├── {a,b,c}/
│   │   ├── design-system.md   # full system: principles, type scale, color, spacing, components
│   │   ├── tokens.css         # CSS custom properties
│   │   ├── mockups/<screen>.html      # one self-contained HTML per mockable (full/partial) screen
│   │   └── screenshots/<screen>.png   # headless-Chrome render of every mockup (step 8) — the visual spec steps 14–15 compare against
│   └── archive/round-<N>/     # written by /hyperbuild-redesign: the directions a round replaced
│       ├── round.md           # what was kept/replaced, the verbatim notes, why each was replaced
│       ├── directions.md      # snapshot of the mapping as it stood before the round
│       └── <letter>/          # that slot's design-system.md, tokens.css, mockups/, screenshots/,
│                              #   research-<slug>.md, visual-qa-<letter>.json — INERT, read by nothing
├── decisions/
│   ├── platform.md            # chosen stack + rationale (step 1)
│   ├── design-choice.md       # written by /hyperbuild-choose
│   ├── gate-changes.md        # ON FIRST USE ONLY — the log that legalises a gate-script change
│   │                          #   mid-run; absent on a clean run. Read by scripts/gate-ship.sh
│   └── revisions.md           # shared ledger, appended by /hyperbuild-revise + /hyperbuild-redesign
└── gates/
    ├── design-gate-report.md  # step 12 (incl. ## What I am least confident about)
    ├── visual-qa-{a,b,c}.json # step 8.5 — one visual-QA record per direction (findings + verdicts)
    ├── skill-scripts/         # step 12's FROZEN copies of the generated-skill script gates;
    │                          #   steps 14/16 execute only these, hashes recorded in manifest.frozen_gates
    ├── frozen-gates.sha256    # step 12.1b's `shasum -a 256 -c` sidecar for the freeze above
    ├── review-uncertainty.md  # step 15, EVERY pass — what the three critics could NOT check
    └── ship-report.md         # step 16 (incl. ## What I am least confident about)
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
  "usage": {
    "2": {
      "agents_spawned": 27,
      "turns": 14,
      "wall_clock_s": 1893,
      "outcome": "done",
      "cost_usd": null,
      "cost_source": "unavailable",
      "notes": "1 scout + 7 analysts + 19 verifiers; 1 analyst re-spawned (missing provenance block)"
    }
  },
  "usage_summary": null,
  "frozen_gates": null,
  "design_choice": null,
  "blocked_on": null
}
```

- `stage` — `"PLAN"` (steps 1–12) or `"BUILD"` (steps 13–16). Flipped to `"BUILD"` by
  `/hyperbuild-choose`.
- `gear` — `"standard"` (default) or `"premier"`; recorded by step 1, read by every step
  for its scale numbers.
- `steps` — map of step number (`"1"` … `"16"`, including `"3.5"` and `"4.5"`) → `"done"`, written
  at each step's exit. The resume point is the first step in pipeline order without a
  `"done"` entry.
- `usage` — one record per step key, written by the ROUTER (not by the step skill):
  `{agents_spawned, turns, wall_clock_s, outcome, cost_usd, cost_source, notes}`, plus an
  optional `tokens` sub-object when a result object was actually observed. `outcome` is
  one of `running` · `done` · `blocked` · `capped` · `aborted` · `redo` — the record is
  opened at `running` when the step starts and finalized when it returns, so a `running`
  record under a stale lock names the step that crashed. **Wall clock and agent counts are
  measured (start stamps in `temp/step-<N>.start`, spawn bookkeeping in `scaffold.md`);
  tokens and dollars are not available to a running skill**, so `cost_usd` is written only
  from an observed source
  (`/cost` output, a headless `--output-format json` result object, or configured
  telemetry — named in `cost_source`) and is otherwise `null` with
  `cost_source: "unavailable"`. Estimating it is forbidden: a fabricated cost corrupts
  every comparison the record exists to enable, and a null is a correct answer. When a
  headless result object exists, its fields are copied verbatim — `total_cost_usd`,
  `num_turns`, and `usage.{input_tokens, output_tokens, cache_read_input_tokens,
  cache_creation_input_tokens}`. Concurrent pairs (2 ∥ 3, 8 ∥ 9) get one record each and
  their clocks overlap by design.
- `usage_summary` — `null` until the design gate; then `{stage_a: {...}}`, and
  `{stage_a, stage_b}` after the ship gate (also written partially on an abort or a cap
  block). Each stage carries `written_at`, `steps_recorded`, `steps_missing`,
  `agents_spawned`, `turns`, `wall_clock_s_summed` (per-step clocks added, overlapping),
  `wall_clock_s_elapsed` (`written_at` − `created`), `cost_usd`, `cost_source`, `notes`.
  Missing steps are LISTED, never interpolated; if any counted step's cost is unavailable
  the stage cost is `null` + `"partial-unavailable"`, because a partial sum of costs is a
  wrong number wearing the shape of a right one.
- `frozen_gates` — `null` until step 12 freezes the generated-skill script gates: the
  frozen copies live in `gates/skill-scripts/` and their SHA-256 hashes are recorded here.
  Steps 14 and 16 execute ONLY the frozen copies and fail on a hash mismatch — the point
  is that the agent that authors a check cannot also edit the copy that grades it. Step 12
  owns this field's shape; every other writer preserves it untouched.
- `design_choice` — `null` until `/hyperbuild-choose` writes `"a"`, `"b"`, or `"c"`.
- `blocked_on` — `null`, `"design-choice"` (set by step 12 at the gate), an honest
  description of a ship-gate failure after its 2 fix rounds (step 16), or one of the
  two run-control markers the router sets: `"aborted-by-user"` (an `ABORT` file was found
  at a step boundary) and `"cap: <what fired>"` (a turn or wall-clock ceiling was hit —
  e.g. `"cap: step 14 wave 3 wall clock 120m"`).

**Read-modify-write it, always.** The manifest now carries state from several owners
(`steps` from every step, `usage` from the router, `frozen_gates` from step 12). Anything
that regenerates it from memory silently drops the keys it wasn't thinking about.

Resume ladder (owned by the router skill `hyperbuild`): manifest first, TodoWrite
second, artifact scan third — the router carries the full step→canonical-artifact
table. If `design_choice` is set and `stage` is `BUILD`, the router continues at the
first unfinished build step. Two run-control preflights run BEFORE the ladder: is
`ABORT` present, and is `.lock` live.

### .lock — the concurrency guard

One line of JSON, claimed by the router before any step runs and released at every stop:

```json
{"pid": 57609, "host": "mbp.local", "claimed": "2026-07-25T09:14:07Z"}
```

Nothing in the manifest stops two sessions from resuming the same run — both would spawn
the same waves, write the same files, and flip the same keys, interleaved. The lock does.
It is created atomically (`set -o noclobber`, so a race cannot produce two winners), and
`pid` is the Claude Code process that owns the claiming session.

- **My lock** (`pid` == this session's `$PPID` AND same host) → the router already holds it:
  it proceeds without re-claiming. This branch is tested FIRST and is the common case after
  a context compaction, when the router re-reads its own procedure mid-run. Without it the
  liveness test would find its own trivially-alive pid, read "live lock", and refuse the run
  it is itself driving.
- **Live lock** (a DIFFERENT pid, alive on this host) → the router REFUSES to start and names
  the pid, host, and claim time.
- **Foreign lock** (claimed on another host) → also a refusal: liveness across hosts is
  untestable, so the safe reading is "someone may still be running this."
- **Stale lock** (pid gone) → reclaimed automatically, with the reclaim written to
  `temp/orchestrator-notes.md` and to the next step's `usage.notes` — never silently.

Released at the design-gate stop, at run completion, on any blocked state (exhausted gate,
failed preflight, fired cap, abort), and at the end of any turn that leaves the run PARKED
or BLOCKED. An ordinary between-steps turn boundary does NOT release it — the run is still
the router's — and if the file has gone missing the router simply re-claims it before the
next step. Machine-local and disposable: `runs/*/.lock` and `runs/*/ABORT` are gitignored
alongside `runs/*/temp/`. It is one of only two files under `runs/` a human ever touches by
hand — `rm runs/<run_tag>/.lock`, when they know the session that claimed it is dead (see
Rules).

### ABORT — the kill switch

An empty flag file, and the only file under `runs/` a human ever creates by hand. It needs
no session, no permission, and no running Claude:

```bash
touch runs/<run_tag>/ABORT
```

The router checks for it between every step, before claiming the lock on any resume, and at
the long in-step sync points where a step comes up for air — step 14's per-wave sync point
and the critic fix-round boundaries in steps 8.5, 12, 15, and 16. When it finds the file,
the run stops cleanly rather than mid-write: the completed step's `usage` record is
written, `blocked_on` becomes `"aborted-by-user"`, `steps` is left telling the truth (an
unfinished step is never marked `"done"` to tidy the abort), a partial `usage_summary` is
written, the lock is released, and the user gets a report of what completed and what is on
disk. Aborting at a wave sync point is safe by construction: that wave's commit has already
landed, so `app/` is clean and the run resumes from a real boundary.

**What it does not do, stated plainly:** it does not interrupt work already in flight. The
check happens the next time the router runs a tool, so if a wave of subagents is mid-flight
the abort lands when they return — the flag stops the *next* unit of work. To stop
something immediately, interrupt the session itself (Esc / Ctrl-C); the `ABORT` file is then
what stops the *next* session from resuming into more work.

Resume path: `rm runs/<run_tag>/ABORT`, then `/hyperbuild`. While the file exists, the
router refuses to start — a leftover `ABORT` means somebody stopped this run on purpose.

### scaffold.md

The orchestrator's private planning document: working notes, spawn bookkeeping, open
questions. It never ships and is never an input contract for any subagent. The router's
per-step `agents_spawned` count is derived from the spawn bookkeeping here, not from
memory.

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

### `temp/step-<N>.start`

One unix timestamp per step, written by the router immediately BEFORE it invokes that
step's skill and read immediately after the step returns — the difference is the
`wall_clock_s` in that step's `usage` record. It lives on disk rather than in the
router's head so that a compaction or a crash cannot quietly turn a measurement into a
guess. Scratch, like everything under `temp/`; the derived number is what survives, in
the manifest.

### designs/

Written by steps 7 (`design-system.md`, `tokens.css`) and 8 (`mockups/`, `index.html`).
Three complete, competing design systems — `a`, `b`, `c` — each with one self-contained
HTML mockup per screen in the PRD's screen inventory (cap 12 standard / 20 premier),
built with real PRD content, never lorem ipsum. `designs/index.html` is the side-by-side
gallery you open at the design gate to make the run's one human decision.

### decisions/

- `platform.md` — step 1's resolved stack + rationale (stated in the idea wins;
  otherwise inferred, with the inference explained).
- `design-choice.md` — written by `/hyperbuild-choose`: which design won, and the
  recorded paths of the `tokens.css` + `design-system.md` copies placed in `app/design/`.
- `gate-changes.md` — **created on first use only; its absence on a clean run is normal
  and correct.** The log that turns a live/freeze divergence in a generated gate script
  from a hard ship-gate FAIL into a downgraded `warn`. `scripts/gate-ship.sh` reads it and
  step 16's check 10 branches on it, so the format is load-bearing: one `##` entry per
  changed script, carrying all FIVE fields — the script path (as it appears in
  `manifest.frozen_gates`, `<skill-name>/<script>.sh`), `old_sha`, `new_sha`, `decided_by`
  (who authorised it), and `why`. A divergence with no matching entry stays a hard fail,
  and an entry written *after* discovering a divergence is laundering, not a decision.

  ```markdown
  ## app-testing/verify-widgets.sh
  - old_sha: 3f2a…c81
  - new_sha: 9b7e…40d
  - decided_by: human, /hyperbuild-choose platform override 2026-07-25
  - why: step 10 regenerated the skill for flutter; the widget matcher changed names
  ```

### gates/

- `design-gate-report.md` — step 12's per-check evidence for the Stage-A checklist,
  ending with `## What I am least confident about`.
- `skill-scripts/` — step 12's frozen copies of the generated-skill `scripts/*.sh` gates,
  hashed into `manifest.frozen_gates`. Steps 14 and 16 run these copies and nothing else,
  so the build agents cannot edit the checks that grade them. A hash mismatch fails the
  ship gate.
- `frozen-gates.sha256` — step 12.1b's sidecar for that freeze, in `shasum -a 256 -c`
  format so a human can re-verify the whole oracle in one command
  (`cd runs/<run_tag>/gates/skill-scripts && shasum -a 256 -c ../frozen-gates.sha256`).
  It is a convenience mirror of `manifest.frozen_gates`; the manifest is authoritative.
- `review-uncertainty.md` — step 15's account of what its three critics could NOT check,
  written on EVERY pass (including a pass skipped for want of a changed Tier-0 signal).
  Step 16 folds it into `ship-report.md`'s `## What I am least confident about`.
- `ship-report.md` — step 16's per-check evidence: what was built, how to run it, test
  count, known gaps, and `## What I am least confident about`. If the run is blocked, this
  file says exactly what is red and why.

## What does NOT live here

The pipeline's durable deliverables live at the repo root, not in the run workspace:
`research/` (steps 2–9, incl. step 3.5's `research-audit.md`), `features/` (step 4.5),
`epics/` (step 11), and `app/`
(steps 13–16). Each research file's frontmatter carries `run_tag` + `created`, so
provenance survives even when a vault outlives its run. See each directory's README for
its format contract.

## Rules

- **NEVER hand-edit files under `runs/`.** The manifest is the resume point; a
  hand-edited manifest makes the router resume into a lie. **Two files are the sanctioned
  exceptions**, and only these two: `touch runs/<run_tag>/ABORT` to stop the run at the
  next step boundary, and `rm runs/<run_tag>/.lock` to clear a lock whose session you know
  is dead. Creating or deleting either of those is a control action, not an edit — you are
  never asked to write *content* anywhere under `runs/`.
- **Never hand-write a cost or token number into `usage`.** The router leaves them `null`
  with `cost_source: "unavailable"` when it cannot observe them, and that null is load-
  bearing: these records exist to price the gears and to settle which parts of the fan-out
  earn their cost, and a single plausible-looking invented figure poisons every comparison
  built on the set. If you have real numbers (`/cost`, a headless JSON result), they go in
  with their source named.
- **idea.md's frontmatter and verbatim idea body are written once and never modified.**
  Not reworded, not reordered, not "reconciled" with anything that happened later — every
  spawn prompt block-quotes that body, so an edit silently redirects the whole pipeline.
  The ONE permitted exception is append-only and pipeline-driven: at the design gate,
  `/hyperbuild-revise` at IDEA scope may APPEND a dated `## Revisions` section BELOW the
  original body, quoting the user's request verbatim (that append is how the change
  reaches every downstream subagent). Hand edits remain banned, and if the "revision" is
  really a different app, that's a new run (a fresh harness clone), not an edit.
- **`scaffold.md` and `temp/` never ship** and are never cited as evidence in gate
  reports.
- **Only `/hyperbuild-choose` writes `decisions/design-choice.md`.** Editing it directly
  skips the manifest update and the `app/design/` copy, and Stage B will build against
  nothing.
