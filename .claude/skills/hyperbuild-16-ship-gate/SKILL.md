---
name: hyperbuild-16-ship-gate
description: >
  Step 16 of the hyperbuild pipeline — THE ship gate (FINAL STEP). Spawns
  hb-gate-verifier to run the ship checklist mechanically: full test suite
  green, lint/analyzer clean, every task status done, every epic acceptance
  criterion checked, PRD coverage matrix complete, platform-appropriate
  build succeeds, every generated-skill scripts/*.sh gate passes, the
  feature→task→file→test TRACEABILITY CHAIN holds for every must/should
  feature, and app/ is a clean git repo with scaffold/wave/epic history.
  Produces
  runs/<run_tag>/gates/ship-report.md. The gate's
  verdict is final — failures are fixed by changing the app, never by
  re-interpreting checks; max 3 fix rounds, then blocked with an honest
  report. On pass, delivers the final user message. Invoked by the
  hyperbuild router via Skill(); not run directly by users.
---

# Step 16 — Ship gate (FINAL STEP)

You are executing step 16 (ship-gate) of the hyperbuild pipeline. Step 15's adversarial review has been applied and its tests were green; nothing runs after this step — when the gate passes you deliver the final message and the run is complete.

**Goal:** a mechanical, evidence-backed verdict that the app is done — and the final message to the user.

**THE GATE'S VERDICT IS FINAL.** You may not re-run individual checks and re-classify their failures as false positives, downgrade a check to "advisory", shrink the checklist between rounds, or memo away a failure. If a check fails, change the APP (or the genuinely stale artifact, with named evidence) until the gate passes. A blocked run with a true manifest beats a shipped app that lies.

---

## Inputs

Read these before spawning:
- `runs/<run_tag>/manifest.json` — run_tag, gear, platform, stage. If the router did not name the active run_tag, take the run whose manifest has `stage: BUILD`.
- `runs/<run_tag>/idea.md` — verbatim app idea. GOSPEL.
- `runs/<run_tag>/decisions/platform.md` — chosen platform + rationale (step 1).
- `runs/<run_tag>/scaffold.md` — the `## Toolchain` section: the VERIFIED build / test / lint commands (step 13 recorded them; steps 14–16 read them verbatim and never re-derive).
- `research/02-engineering/author/stack-guide.md` — the committed tooling decisions (step 5) — cross-check only; scaffold.md's verified commands win.
- `research/product-spec.md` — feature list + screen inventory (for the final message).
- `epics/00-overview.md` — epic list + PRD coverage matrix; every `epics/NN-<slug>/epic.md` and `task-NN-<slug>.md`.
- `features/00-index.md` — must/should feature ids.
- `app/` — the implemented application.
- `runs/<run_tag>/gates/review-loop-log.md` (if exists) — step 15's known gaps, reported honestly at the end.

---

## The ship gate checklist (canonical)

Nine checks. ALL must pass. Every round runs ALL nine fresh — a fix for one check can break another.

| # | Check id | Passes when | Evidence required |
|---|----------|-------------|-------------------|
| 1 | tests-green | The FULL test suite exits 0 with zero failures (exact command from scaffold.md `## Toolchain`) | Command, total test count, failure count |
| 2 | lint-clean | Lint/analyzer exits 0 with zero errors and zero warnings | Command, issue count |
| 3 | tasks-done | Every `epics/*/task-*.md` has frontmatter `status: done` | Offender list (empty) |
| 4 | epic-acceptance | Every acceptance-criteria checkbox in every `epics/*/epic.md` is `[x]` (step 14 checks them off at each epic close, with evidence) | Unchecked list (empty) |
| 5 | prd-coverage | Every must/should feature in the `epics/00-overview.md` coverage matrix maps to ≥1 done task, and every must/should `features/NN-*.md` has `status: implemented` | Uncovered/unflipped list (empty) |
| 6 | build-succeeds | The platform-appropriate build command exits 0 | Command, artifact path or closing output lines |
| 7 | skill-gates | Every generated-skill check script `.claude/skills/app-*/scripts/*.sh` exits 0 (run from the repo root; a skill with no scripts/ contributes nothing) | Script list with exit codes |
| 8 | traceability-chain | HARD. The chain holds, walked MECHANICALLY per feature: every must/should feature F-NN in `features/00-index.md` → `features/NN-*.md` exists → ≥1 task with `features: [F-NN]` in frontmatter and ALL such tasks `status: done` → every path in those tasks' `files:` lists exists in `app/` → the test files those tasks name/added pass (they ran inside check 1's full-suite run; the verifier greps the mapping and spot-checks per feature) | Per-feature chain walk; a break ANYWHERE names the feature id AND the broken link — broken-link list (empty) |
| 9 | git-clean | HARD. `app/` is a git repo, the working tree is clean (`git -C app status --porcelain` outputs nothing), and `git -C app log --oneline` shows a non-trivial history with the scaffold commit, a `wave <N>:` commit for every wave in `runs/<run_tag>/temp/wave-log.md` not annotated `DEAD`, and an `epic <NN>: critic pass` commit for every epic whose patch log (`runs/<run_tag>/temp/epic-NN-patch-log.json`) has a non-empty `applied` array — an epic with zero applied hunks has NO epic commit, and that is a pass | Both commands + decisive output (porcelain empty; log tail with commit count) |

---

## Procedure

1. **Resolve the exact commands from `runs/<run_tag>/scaffold.md` `## Toolchain`.** Step 13 recorded the VERIFIED build / test / lint commands there precisely so steps 14–16 never re-derive them — read them verbatim. Cross-check against `research/02-engineering/author/stack-guide.md` and `decisions/platform.md`; if scaffold.md's Toolchain section is missing (it shouldn't be — step 13's exit criteria require it), fall back to the stack-guide's committed commands and note the gap in the ship report. Examples of the shape you are looking for — the recorded commands win over these:

   | Platform | test_command | lint_command | build_command |
   |----------|-------------|--------------|---------------|
   | Flutter | `cd app && flutter test` | `cd app && flutter analyze` | `cd app && flutter build <target> --release` |
   | Node/web | `cd app && npm test` | `cd app && npm run lint` | `cd app && npm run build` |
   | iOS native | `cd app && xcodebuild test -scheme <scheme>` | `cd app && swiftlint` | `cd app && xcodebuild build -scheme <scheme>` |

   Update manifest: `steps."16": "in-progress"`. Set `round = 1`.

2. **Spawn hb-gate-verifier.** Spawn ONCE per round. The verifier runs checks and reports; it NEVER fixes anything. You fix; you never verify — separation of powers holds in both directions.

   **Spawn template:**
   ```
   subagent_type: hb-gate-verifier
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste runs/<run_tag>/idea.md body}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 16 (ship gate) of the hyperbuild
     pipeline — the FINAL step. Steps 13–15 built, tested, and
     adversarially reviewed the app in app/. You run THE SHIP GATE
     checklist mechanically and report pass/fail with per-check evidence.
     You NEVER fix anything — the orchestrator owns fixes. Checks are
     facts, not opinions: never re-interpret a failing check as a false
     positive, never soften a threshold.

     YOUR INPUTS:
     - round: <round number>
     - app_root: app/
     - test_command: <exact command resolved in procedure item 1>
     - lint_command: <exact command resolved in procedure item 1>
     - build_command: <exact command resolved in procedure item 1>
     - epics_dir: epics/
     - coverage_matrix: epics/00-overview.md
     - features_index: features/00-index.md
     - wave_log: runs/<run_tag>/temp/wave-log.md — check 9 keys off it
     - verdict_path: runs/<run_tag>/gates/ship-verdict.json

     READ FIRST:
     - runs/<run_tag>/scaffold.md — its ## Toolchain section is the source
       of the commands above
     - research/02-engineering/author/stack-guide.md — the committed
       tooling decisions
     - epics/00-overview.md — the PRD coverage matrix
     - features/00-index.md — the must/should feature ids

     THE SHIP GATE CHECKLIST — run every check, in order, even after the
     first failure (the orchestrator needs the complete picture):
     1. tests-green: run test_command; PASS only on exit 0 with zero
        failures; record the total test count.
     2. lint-clean: run lint_command; PASS only on zero errors AND zero
        warnings.
     3. tasks-done: read the frontmatter status of EVERY epics/*/task-*.md;
        PASS only if all are "done"; list every offender path.
     4. epic-acceptance: PASS only if every acceptance-criteria checkbox in
        every epics/*/epic.md is checked "[x]"; list every unchecked
        criterion with its epic path.
     5. prd-coverage: PASS only if every must/should feature row in the
        coverage matrix maps to ≥1 task that check 3 found done, AND every
        must/should features/NN-*.md has frontmatter status "implemented";
        list every gap.
     6. build-succeeds: run build_command; PASS only on exit 0; record the
        artifact path or the closing output lines.
     7. skill-gates: run every .claude/skills/app-*/scripts/*.sh from the
        repo root; PASS only if every script exits 0; list each script
        with its exit code.
     8. traceability-chain: walk the chain MECHANICALLY, per feature, for
        EVERY must/should feature id F-NN in features/00-index.md:
        (a) features/NN-*.md exists; (b) grep epics/*/task-*.md
        frontmatter for `features:` containing F-NN — at least ONE task
        must cite it AND every citing task must be status "done";
        (c) every path in those citing tasks' `files:` lists exists in
        app/; (d) the test files those tasks name/added pass — they ran
        inside check 1's full-suite run; spot-check per feature that the
        named test files exist and were part of that run. PASS only when
        every feature's chain is intact end-to-end. A break ANYWHERE
        fails the check; evidence names the feature id AND the broken
        link (missing spec file / no citing task / citing task not done /
        missing files: path / missing or failing test).
     9. git-clean: `git -C app status --porcelain` must output NOTHING
        (real repo, clean working tree) AND `git -C app log --oneline`
        must show a non-trivial history containing the scaffold commit
        (step 13), a `wave <N>:` commit for every wave logged in
        runs/<run_tag>/temp/wave-log.md that is not annotated DEAD, and
        an `epic <NN>: critic pass` commit for every epic whose
        runs/<run_tag>/temp/epic-NN-patch-log.json has a non-empty
        "applied" array — step 14 commits a critic pass ONLY when the
        patcher applied hunks, so an epic with zero applied findings
        legitimately has no epic commit. PASS only on both commands;
        record the porcelain result and the log tail as evidence.

     Write the verdict JSON to verdict_path via a Bash heredoc, exactly
     this canonical schema (identical to your agent prompt's):
     {"gate": "ship", "run_tag": "<run_tag>", "round": <round>,
      "checks": [{"id": "tests-green", "description": "...",
                  "result": "pass|fail", "evidence": "<command → observed>"}],
      "overall": "pass|fail", "failed": <count>}
     "overall" is "pass" only when all nine checks pass. Your final
     message: overall verdict + per-check pass/fail + the verdict path.
     Data, not prose.
   ```

3. **NEVER emit bare text while the verifier is in flight.** Test and build commands take minutes. While waiting, append round notes to `runs/<run_tag>/temp/orchestrator-notes.md` via Edit/Write.

4. **Read the verdict.** `runs/<run_tag>/gates/ship-verdict.json` (canonical schema — the same one pasted into the spawn):
   ```json
   {
     "gate": "ship",
     "run_tag": "habit-coach-3f9a2c",
     "round": 1,
     "checks": [
       { "id": "tests-green", "description": "full suite green",
         "result": "fail",
         "evidence": "cd app && flutter test → 247 tests, 3 failures: test/habit_streak_test.dart ..." }
     ],
     "overall": "fail",
     "failed": 1
   }
   ```
   The gate passes ONLY on `"overall": "pass"`. If the verifier crashed or wrote nothing, re-spawn it ONCE. If it fails a second time, run the nine checks yourself via Bash — checklist unchanged, evidence recorded — and write the verdict JSON yourself in the same schema. This is the ONE documented collapse of the verify/fix separation; the checklist itself never shrinks.

5. **All nine passed → skip to item 8.** Otherwise run a fix round. Fix lanes by failing check — fix the APP, never the check:

   | Failing check | Fix lane |
   |---------------|----------|
   | tests-green | Spawn hb-test-engineer with the failing test list. Production bug → fix the code. NEVER weaken, skip, or delete a test to go green. |
   | lint-clean | Run the stack's auto-fixer first (e.g. `dart fix --apply` / `npm run lint -- --fix`). For the remainder: stub a patch log (`echo '{"total_findings": 0, "applied": [], "skipped": [], "conflicts": [], "escalated": []}' > runs/<run_tag>/gates/ship-lint-patch-log.json`), convert lint output into the step-15 finding shape, spawn hb-patcher on it. |
   | tasks-done | Verify the work EXISTS first (read the code, run its tests). Genuinely done but stale frontmatter → flip `status: done`, citing file + test evidence in the ship report. Not actually implemented → spawn hb-implementer then hb-test-engineer on that task, step-14 discipline. |
   | epic-acceptance | Verify each unchecked criterion against the app. Met → check the box, citing evidence in the ship report. Not met → hb-implementer task for the gap. |
   | prd-coverage | A must/should feature uncovered this late is the worst case: spawn hb-implementer (+ hb-test-engineer) scoped to that feature. Flip the feature file to `status: implemented` only after its acceptance criteria verifiably hold. |
   | build-succeeds | Read the build error. Surgical (import, config, signature) → hand-craft the Edit or route through hb-patcher. Structural → hb-implementer. |
   | skill-gates | Read the failing script's output — it names the violated rule. Fix the offending app code (hb-patcher for surgical hits, hb-implementer for structural ones). NEVER edit or delete the script to go green; a genuinely wrong script is fixed only with the named evidence recorded in the ship report. |
   | traceability-chain | Repair the NAMED broken link, per feature. Missing `features/NN-*.md` → an upstream artifact was lost; restore it from the PRD before anything else. No citing task, citing task not done, or a `files:` path missing from app/ → the feature was not fully built: spawn hb-implementer (+ hb-test-engineer) scoped to the gap, step-14 discipline. A `files:` entry that is genuinely stale (the file verifiably moved) → fix the task's `files:` list, citing the real path + its passing tests in the ship report. NEVER trim the feature index or a task's `features:` list to shorten the chain. |
   | git-clean | Dirty tree → commit the legitimate fix-round work (`ship-gate round <N>: <what changed>`); NEVER discard real changes to fake cleanliness. `app/` not a repo, or the log missing the scaffold commit, a non-DEAD logged wave's commit, or a required epic critic-pass commit (one with applied hunks in its patch log) → a step 13/14 discipline failure that cannot be reconstructed honestly: do NOT fabricate history with a catch-all commit — record it and let the round fail toward BLOCKED. |

   **NEVER flip a task status, feature status, or acceptance checkbox without verified evidence named in the ship report.** Flipping state to satisfy the gate without the work is the exact lie this gate exists to prevent.

6. **Re-run the gate.** Increment `round`; re-spawn hb-gate-verifier fresh (item 2) — ALL nine checks, not just the previously failing ones.

7. **MAX 3 fix rounds** (the knobs table: critic fix rounds ≤3 for BOTH standard and premier gears; round 1 + up to 3 fix rounds = at most 4 verifier spawns). Still failing after round limit → the run is BLOCKED:
   - Manifest: `steps."16": "blocked"`, `blocked_on: "ship-gate: <comma-separated failing check ids>"`.
   - Write `runs/<run_tag>/gates/ship-report.md` with `verdict: BLOCKED` (format below), including what each round attempted and why it did not clear.
   - Tell the user honestly: which checks fail, the evidence, what was tried, and what a human should do next. Do NOT soften it. Then stop.

8. **On pass — write the ship report** to `runs/<run_tag>/gates/ship-report.md`:
   ```markdown
   ---
   run_tag: <run_tag>
   verdict: PASSED
   rounds: <N>
   test_count: <total from tests-green evidence>
   date: <YYYY-MM-DD>
   ---

   # Ship gate report — <run_tag>

   ## Checklist (final round)
   | # | Check | Result | Evidence |
   |---|-------|--------|----------|
   | 1 | tests-green | PASS | <command> — <N> tests, 0 failures |
   ...all nine rows...

   ## Round history
   - Round 1: <failing checks> → <fix lane used, what changed>
   - Round <N>: all checks passed

   ## Evidence for flipped artifacts
   - <task/criterion flipped> — <file + test that proves it> (or "none flipped")

   ## Known gaps
   - <from runs/<run_tag>/gates/review-loop-log.md ## Known gaps, plus PRD could/won't features not built>
   ```

9. **Close out the run.** Manifest: `steps."16": "done"`, `stage: "DONE"`, `blocked_on: null`. Mark ALL 20 todos complete (the 19 step todos — including the half-steps 3.5, 4.5 and 8.5 — plus the checkpoint todo). Then deliver the final user message — the ONLY prose message this stage sends, and it follows this contract exactly:
   - **What was built:** one short paragraph — the app (quote the idea's core), the platform, N must + M should features implemented across K screens (counts from the PRD and coverage matrix).
   - **How to run it:** the exact commands, fenced — dependency install, run, test (from the stack-guide, e.g. `cd app && flutter pub get`, `flutter run`, `flutter test`).
   - **Test count:** "<N> tests, all green" (from the ship verdict evidence).
   - **Known gaps:** the honest list from the ship report — review known gaps, unbuilt could/won't features. If empty, say so.
   - **Where things live:** `app/` (the code), `runs/<run_tag>/gates/ship-report.md` (the verdict), `runs/<run_tag>/designs/index.html` (the design gallery), `epics/` and `features/` (the paper trail).

---

## Artifacts

- `runs/<run_tag>/gates/ship-verdict.json` — written by hb-gate-verifier (via Bash heredoc), one per round, overwritten each round; schema in procedure item 4.
- `runs/<run_tag>/gates/ship-report.md` — written by the orchestrator after the final round; format in procedure item 8; `verdict: PASSED | BLOCKED`.
- `runs/<run_tag>/gates/ship-lint-patch-log.json` — only if the lint-clean fix lane ran hb-patcher.
- Manifest flipped to `steps."16": "done"` + `stage: "DONE"` (or `"blocked"` + `blocked_on`).

---

## Exit criteria

- `runs/<run_tag>/gates/ship-verdict.json` exists from the final round, valid JSON, all nine checks present
- `runs/<run_tag>/gates/ship-report.md` exists with `verdict: PASSED` — or `verdict: BLOCKED` after 3 fix rounds with every failing check and round history honestly recorded
- Manifest updated (`steps."16"` and `stage` per procedure items 7/9); all todos complete
- The final user message (pass) or the honest blocked message (fail) has been delivered

## Pipeline complete

There is no next step and no further `Skill()` invocation. On PASS: the app lives in `app/`, the verdict in `runs/<run_tag>/gates/ship-report.md`. On BLOCKED: the manifest says so, the report says why, and the user knows exactly what is left. Either way the manifest tells the truth. You're done.
