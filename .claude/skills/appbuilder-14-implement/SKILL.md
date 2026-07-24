---
name: appbuilder-14-implement
description: >
  Step 14 of the appbuilder pipeline — THE WAVE LOOP, the longest step in
  Stage B. Schedules the task DAG across ALL epics in waves: each wave is a
  set of ready tasks with PAIRWISE-DISJOINT files: lists (3–5 standard /
  6–10 premier); all of a wave's ab-implementers spawn in ONE parallel batch
  (idea, PRD section, task file, all generated app-* skills, the chosen
  design's mockup HTML + screenshots for its screens), each followed by its
  ab-test-engineer (writes/extends tests — incl. visual/golden-snapshot
  tests for UI tasks — runs the suite, fixes until green). SYNC POINT
  between waves: full suite + every generated skill's script gates green —
  NEVER starts a wave on red — then ONE git commit per wave. When a wave
  completes an epic's last task: ab-code-critic on the epic's REAL git diff,
  findings applied by the TOOL-LOCKED (Read+Edit) ab-patcher, structural
  findings escalate as NEW task files, then an epic commit. Wave plans go to
  temp/wave-log.md for crash resume; per-epic progress notes live in
  manifest.json. Invoked by the appbuilder router via Skill(); not run
  directly by users.
---

# Step 14 — Implement (THE WAVE LOOP)

**⚠ CRITICAL ANTI-PATTERN: writing app code in the orchestrator context is a PIPELINE
VIOLATION.** Long-running orchestrators drift into "I'll just implement this one myself" —
and produce code that read none of the generated skills, mockups, or feature specs. If
you find yourself about to Edit a file under `app/` to implement a task or apply a critic
finding, STOP. Spawn `ab-implementer` / `ab-patcher`. Your Edit calls in this step are
for frontmatter status flips, manifest updates, patch-log stubs, and new task files —
NEVER for code under `app/` (sole carve-out: the hunk-revert recovery in 14.4.6).

You are executing step 14 (implement) of the appbuilder pipeline. Step 13 scaffolded a
green, themed, tool-wired app in `app/`; step 15 runs the whole-app adversarial review
after every epic here is done.

**Stage gate:** Stage B ONLY. Requires manifest `stage: "BUILD"`, `design_choice` set,
and `steps."13" = "done"`. Anything missing → STOP, return to the router.

**Goal:** every task `done`, every epic reviewed and patched, full test suite green. Why
this shape: waves parallelize across the WHOLE task DAG — small tasks with explicit
`depends_on` + `files:` make that safe (Implementation granularity rule 4) — while sync
points keep every gate honest; a fresh implementer per task survives context rot; a
separate test engineer breaks author bias (whoever wrote the code is the wrong one to
declare it works); critic + patcher at each epic's completion catch drift while the diff
is small — the same defect found in step 15 costs an escalation task.

## Inputs

Recover `run_tag` from disk (the `runs/*/manifest.json` with `stage: "BUILD"`). Then read:

- `runs/<run_tag>/manifest.json` — `design_choice`, `gear`, `epics` progress notes (if resuming)
- `runs/<run_tag>/idea.md` — verbatim app idea. GOSPEL.
- `runs/<run_tag>/scaffold.md` — `## Toolchain` section: build / test / lint commands (step 13 wrote them; use them verbatim)
- `epics/00-overview.md` — epic list, dependency order, PRD coverage matrix
- `epics/NN-<slug>/epic.md` + `epics/NN-<slug>/task-NN-<slug>.md` — the backlog (step 11);
  task frontmatter is (id, epic, status, depends_on, size, features, category, files) —
  `files:` is the wave scheduler's disjointness key
- `runs/<run_tag>/temp/wave-log.md` — prior wave plans, if resuming (created in 14.0;
  appended before every wave)
- `features/NN-<slug>.md` — feature specs; each task's `features:` frontmatter names its files
- `research/product-spec.md` — the PRD; implementers read only their task's sections
- `runs/<run_tag>/designs/<design_choice>/mockups/<screen>.html` — the CHOSEN design's mockups
- `runs/<run_tag>/designs/<design_choice>/screenshots/<screen>.png` — rendered screenshots of
  those mockups (absent only if step 8 logged `screenshots_skipped` in the manifest)
- The five generated skills (step 10): `.claude/skills/app-code-style/SKILL.md`,
  `.claude/skills/app-architecture/SKILL.md`, `.claude/skills/app-testing/SKILL.md`,
  `.claude/skills/app-components/SKILL.md`, `.claude/skills/app-review-checklist/SKILL.md`

## Procedure

### 14.0 Recover + resume

1. Read the manifest's `epics` object (schema in 14.2) and `runs/<run_tag>/temp/wave-log.md`
   (fresh run → create it with a `# Wave log — <run_tag>` header). No positional bookmark
   is needed: the wave loop's ready-set computation (14.1) is self-healing — it resumes
   wherever the task statuses say.
2. Run the full test suite ONCE. Step 13's exit guarantees green; a red suite or dirty
   tree means a crashed prior session. **Crash-resume ladder:** a wave-log entry with no
   matching `wave <N>:` commit in `git -C app log` is a DEAD WAVE. RE-VERIFY every task
   stuck `in-progress` (from the dead wave or otherwise): does every path in its `files:`
   list exist in `app/`, and do its tests pass? Both yes → flip it `done` (the next
   wave's sync-point commit picks its work up). Either no → revert exactly its files —
   per `files:` entry `p`: `git -C app checkout -- "${p#app/}"` (files: paths are
   harness-root-relative with an `app/` prefix, but the pathspec resolves inside the
   repo at `app/`, so STRIP the prefix; untracked entries are deleted at the
   harness-root path as written) — and flip it back to
   `todo`. Then annotate the dead wave's line in `temp/wave-log.md` via Edit — append
   ` — DEAD, recovered on resume; no commit` — so the exit criteria and the ship
   gate's git check expect no `wave <N>:` commit for it (recovered work rides in the
   next wave's sync-point commit). After the sweep, if the suite is still red →
   `git -C app checkout -- . && git -C app clean -fd` back to the last wave commit, and
   flip any task you just recovered to `done` back to `todo` (its uncommitted work was
   discarded). THE LAST COMMIT IS ALWAYS GREEN — that invariant makes discarding safe.
3. Gear sanity check: `standard` = 4–8 epics with 3–8 tasks each; `premier` = 6–12 epics
   with 4–10 tasks each. Wildly off → log it to `temp/orchestrator-notes.md` and proceed;
   do NOT rewrite the backlog (step 11 owns it).

### 14.1 THE WAVE LOOP

Step 14 schedules the TASK DAG, not the epic order (Implementation granularity rule 4):
parallel within a wave, honest gates between waves. Contracts/foundation tasks come first
and assembly tasks come late automatically — they depend on their parts. Repeat until no
`todo` task remains:

1. **READY SET.** Every task across ALL epics with `status: todo` whose `depends_on`
   tasks are all `done` AND whose epic's `depends_on` epics are fully done (every task
   `done`). Ready set empty while `todo` tasks remain → a `blocked` upstream task or a
   dependency cycle: set manifest `blocked_on`, report honestly, stop.
2. **PICK THE WAVE.** Walk the ready set in epic/task numeric order, greedily keeping
   each task whose `files:` list is PAIRWISE-DISJOINT with every task already picked; a
   conflicting task DEFERS to a later wave. Cap per the parallel-implementers knob:
   3–5 tasks (`standard`) / 6–10 (`premier`). A task with a missing or empty `files:`
   list conflicts with EVERYTHING — it runs alone in its own wave (and gets logged to
   `temp/orchestrator-notes.md` as a step-11 defect).
3. **LOG THE PLAN.** BEFORE spawning anything, append one line to
   `runs/<run_tag>/temp/wave-log.md`: `wave <N>: [<task ids>]`. This is the
   crash-resume record (14.0).
4. **RUN THE WAVE.** Flip every wave task to `in-progress`, then spawn ALL of the
   wave's ab-implementers in ONE parallel batch (one Task call per task, same block —
   per-task mechanics in 14.3). As EACH implementer returns, spawn its
   ab-test-engineer immediately — never hold a task's test engineer hostage to the
   wave's slowest implementer. The wave's work is complete only when every task's
   implementer + test-engineer pair has returned and every green task is flipped `done`.
5. **SYNC POINT.** Run the FULL test suite AND every generated skill's check gates:
   `for s in .claude/skills/app-*/scripts/*.sh; do bash "$s" || echo "GATE FAIL: $s"; done`
   (run from the repo root; a skill with no scripts/ contributes nothing). ALL green —
   red is fixed via 14.3.8 before the wave may close; a red skill gate is fixed like a
   red test (fix the app code, never the script). NEVER START THE NEXT WAVE ON RED.
   Then commit the wave:
   `git -C app add -A && git -C app commit -m "wave <N>: <task ids> — <one-line summary>"`.
6. **EPIC COMPLETION.** If this wave finished any epic's LAST task, run 14.4
   (critic + patcher) for each such epic NOW — after the wave commit, before planning
   the next wave.

### 14.2 Epic progress notes

When a wave first includes one of an epic's tasks, write the epic's manifest note.
Canonical shape (top-level `epics` key in `runs/<run_tag>/manifest.json`):

```json
"epics": {
  "01-foundation": {
    "status": "done", "commits": ["3f9a2c1", "9be4d02", "c41e7aa"],
    "tasks_total": 6, "tasks_done": 6,
    "suite": {"tests": 87, "status": "green"},
    "review": {"findings": 9, "applied": 7, "skipped": 2, "escalated": 1},
    "note": "data layer + navigation shell"
  },
  "02-tracking": {"status": "in-progress", "commits": ["9be4d02"], "tasks_total": 7, "tasks_done": 2}
}
```

`commits` = every wave commit whose task ids include one of this epic's tasks (the wave
commit messages carry the ids), plus the epic's critic-pass commit once made — this list
IS the epic's real diff (14.4 feeds it to the critic). Update the note at every wave
sync point that touched the epic and at epic close — this is the resumability contract.

### 14.3 PER-TASK MECHANICS (each task in the wave)

**PART-BY-PART (Implementation granularity rule 3 — binding):** step 11 decomposed UI
screens into small composable subcomponent tasks plus a final assembly task. Honor that
decomposition: each small piece's tests are green BEFORE it is composed into anything
larger (the ready-set rule + `depends_on` + the sync-point commit-only-on-green enforce
this); composition tasks
integrate the already-tested parts and add integration/visual tests on top; a whole
screen is NEVER built in one shot when the task list decomposed it.

1. **Flip** the task frontmatter `status: todo` → `in-progress` (Edit).
2. **Assemble spawn inputs:** the task's `features:` list → feature files → their
   `screens:` lists — then FILTER by the PRD screen inventory's `mockup_feasibility`
   (cross-checked against the frozen list in `runs/<run_tag>/temp/mockup-screens.md`):
   - `full`/`partial` screens on the frozen list → mockup paths
     `runs/<run_tag>/designs/<design_choice>/mockups/<screen>.html` + screenshot paths
     `runs/<run_tag>/designs/<design_choice>/screenshots/<screen>.png` (omit a
     screenshot only when step 8 skipped it).
   - `none` screens and screens dropped by step 8's cap have NO mockup and NO
     screenshot — NEVER pass those paths. For each `none` screen, pass the chosen
     design's `## Art direction — <Screen>` section from
     `runs/<run_tag>/designs/<design_choice>/design-system.md` as the visual-direction
     input instead (the `art_direction` key in the templates below).
3. **Spawn ONE `ab-implementer`:**

```
subagent_type: ab-implementer
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 14 (implementer) of the appbuilder pipeline.
  Stage A produced the PRD, feature specs, the chosen design's mockups, and
  five generated app-* skills; step 13 scaffolded app/ with tooling and theme.
  You implement EXACTLY ONE task, running IN PARALLEL with the other
  implementers of this wave — the wave was scheduled so that no two tasks
  share a file, which holds only if you respect your files_allowlist. After
  you return, ab-test-engineer writes
  and runs tests for your change, and at epic close ab-code-critic reviews the
  whole epic diff — write code you would defend in that review. You do not
  write tests beyond what the task's testing requirements name (the test
  engineer owns coverage), and you do not implement neighboring tasks, however
  tempting.

  YOUR INPUTS:
  - task_file: epics/NN-<slug>/task-NN-<slug>.md — your spec; its definition of done is your contract
  - epic_file: epics/NN-<slug>/epic.md
  - files_allowlist: [<the task's `files:` frontmatter list>] — the ONLY paths you may create or modify
  - feature_files: [features/NN-<slug>.md, ...] — primary spec alongside the task file: UX flow, states & edge cases, acceptance criteria
  - prd_path: research/product-spec.md — read ONLY the sections covering this task's features and screens
  - mockups: [runs/<run_tag>/designs/<design_choice>/mockups/<screen>.html, ...] — the CHOSEN design; match layout, spacing, and states
  - screenshots: [runs/<run_tag>/designs/<design_choice>/screenshots/<screen>.png, ...] — rendered views of the same mockups; the Read tool renders images — LOOK at them before building the screen
  - art_direction: <`none`-feasibility screens only: the `## Art direction — <Screen>` section(s) from runs/<run_tag>/designs/<design_choice>/design-system.md — the visual direction for screens that have no mockup; omit when every screen has one>
  - tokens: app/design/tokens.css — never hard-code a value a token covers; use the theme files
  - app_root: app/
  - build_command: <from scaffold.md ## Toolchain>
  - test_command: <from scaffold.md ## Toolchain>

  CONTEXT FILES — READ FIRST, in order:
  1. runs/<run_tag>/idea.md
  2. epics/NN-<slug>/epic.md, then your task file
  3. every feature file listed above
  4. .claude/skills/app-code-style/SKILL.md
  5. .claude/skills/app-architecture/SKILL.md
  6. .claude/skills/app-testing/SKILL.md
  7. .claude/skills/app-components/SKILL.md — names the concrete theme files; use them
  8. .claude/skills/app-review-checklist/SKILL.md — the critic will hold your diff to this
  9. the mockup HTML files and screenshot PNGs listed above (and the
     art-direction card(s), when passed)

  Implement the task fully: every acceptance criterion, every state the
  feature file names (empty, loading, error, offline where relevant).
  Build PART-BY-PART: a small-piece task builds ONLY its piece; a
  composition/assembly task composes the already-tested parts without
  rebuilding them — never a whole screen in one shot when the task list
  decomposed it. The
  build must pass when you finish; run the test command and do not break
  existing tests. HARD FILE BOUNDARY: create or modify ONLY paths in
  files_allowlist (plus test files ONLY if your task's testing requirements
  name them) — other implementers are editing other files RIGHT NOW; if the
  task genuinely needs any other file, STOP and report back — never edit it.
  Do NOT commit (the orchestrator commits once per wave). Do NOT edit task
  or feature frontmatter (the orchestrator flips status). Do NOT touch files
  outside app/.

  REPORT BACK (data, not prose): files created/changed; acceptance criteria
  status (per bullet: done/partial + where in the code); deviations from the
  mockup and why; anything the task spec got wrong — flag it, never silently
  redesign.
```

4. **While ANY spawn is in flight: NEVER emit bare text** — a text-only response ends
   the turn and kills the pipeline. Append to `runs/<run_tag>/temp/orchestrator-notes.md`.
5. **Validate the report-back**; spot-check one changed file against the definition of done.
6. **Spawn ONE `ab-test-engineer`:**

```
subagent_type: ab-test-engineer
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 14 (test engineer) of the appbuilder
  pipeline. ab-implementer just implemented task NN-<slug>; you are the
  independent check — the implementer does not grade its own work. When you
  return green, the orchestrator marks the task done and commits; a red suite
  blocks the entire epic. You may fix APP code when a test exposes a real
  defect, but the tests define correctness from the acceptance criteria —
  never weaken, skip, or delete a test to reach green. If the spec and the
  code disagree, the spec wins.

  YOUR INPUTS:
  - task_file: epics/NN-<slug>/task-NN-<slug>.md — its testing requirements are your floor, not your ceiling
  - feature_files: [features/NN-<slug>.md, ...] — every checkable acceptance criterion gets a test; cover the states & edge cases section
  - changed_files: [<from the implementer's report-back>]
  - files_allowlist: [<the task's `files:` frontmatter list>] — any app-code fix you make stays inside it
  - mockups: [runs/<run_tag>/designs/<design_choice>/mockups/<screen>.html, ...] — UI tasks only: the visual spec
  - screenshots: [runs/<run_tag>/designs/<design_choice>/screenshots/<screen>.png, ...] — UI tasks only: the rendered visual spec (the Read tool renders images)
  - art_direction: <`none`-feasibility screens only: the same `## Art direction — <Screen>` section(s) passed to the implementer — such screens get behavioral/state tests, never golden comparisons against a mockup that does not exist>
  - test_command: <from scaffold.md ## Toolchain>
  - app_root: app/

  CONTEXT FILES — READ FIRST, in order:
  1. epics/NN-<slug>/task-NN-<slug>.md
  2. every feature file listed above
  3. .claude/skills/app-testing/SKILL.md — structure, naming, and coverage rules are BINDING
  4. the changed files listed above
  5. UI tasks: the mockup HTML + screenshot PNG files listed above

  Write or extend tests for this task, run the FULL suite with test_command,
  and fix failures until green. You run inside a parallel wave: other tasks'
  implementers may still be editing THEIR files. A failure rooted in files
  outside your task's files_allowlist and your own test files is not yours
  to fix — report it and move on; the wave's sync point gates it. For UI tasks, ALSO write visual/golden-
  snapshot tests per the stack-guide's testing decisions where the platform
  supports them (Flutter golden tests, iOS snapshot tests, RN/web screenshot
  tests), with the chosen design's mockup + screenshot as the visual spec
  (screens with no mockup — `none` feasibility or dropped by step 8's cap —
  are exempt from mockup-based golden tests: cover their states behaviorally,
  guided by the art-direction card when passed); composition tasks add
  integration/visual coverage ON TOP of the parts' already-green tests. If after 3 fix rounds the suite is still red,
  STOP and report the failures — do not thrash.

  REPORT BACK (data, not prose): tests added/extended (count + files);
  full-suite result (pass/fail counts); app-code fixes you made and why;
  acceptance criteria you could not cover with a test (name them — silent
  gaps become step 15 findings).
```

7. **On green:** flip the task frontmatter to `status: done`; bump `tasks_done` in the
   epic's manifest note. NO per-task commit — the wave's sync point (14.1.5) makes ONE
   commit for the whole wave, and only on green. COMMIT ONLY ON GREEN — no exceptions.
8. **On red** (test engineer stopped): re-spawn ab-implementer ONCE with the failure log
   appended as a `FAILURE LOG:` block, then the test engineer again. Max 3 rounds per
   task; still red → revert ONLY this task's work (per `files:` entry `p`:
   `git -C app checkout -- "${p#app/}"` — strip the harness-root `app/` prefix, the
   pathspec resolves inside the repo at `app/` — and delete the untracked files it
   created at their harness-root paths as written — its `files:` list scopes the revert, and
   wave disjointness keeps every other task's work safe), set the task `status: blocked`
   with a one-line reason, record it in the manifest note, and let the wave close without
   it (its dependents drop out of the ready set until it is fixed). A blocked task means
   step 16 blocks the run honestly — never fake a `done`.

### 14.4 EPIC COMPLETION — adversarial review + patch

Runs when a wave's sync point finishes an epic's LAST task (14.1.6) — after the wave
commit, before the next wave is planned.

1. The triggering wave's sync point (14.1.5) just proved the suite and every skill gate
   green — the review starts from green by construction. Arriving here any other way
   (crash resume), re-run both checks first; red → fix via the wave loop before
   reviewing.
2. **Spawn ONE `ab-code-critic`** on the epic diff:

```
subagent_type: ab-code-critic
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are the step 14 per-epic reviewer of the appbuilder
  pipeline. Epic NN-<slug> just went green; you review ONLY its diff. Your
  findings JSON is consumed by ab-patcher (TOOL-LOCKED to Read+Edit), which
  applies findings as surgical hunks — so findings must be patch-sized,
  anchored, and evidence-backed. You NEVER edit files. Do NOT include exact
  old/new text — the patcher owns the wording; you identify the problem,
  locate it, cite the violated rule, and describe what the fix must
  accomplish.

  YOUR INPUTS:
  - epic_commits: [<the epic's manifest-note `commits` list>] — the wave commits whose
    messages name this epic's task ids: the epic's REAL diff. Run
    `git -C app show <sha>` per commit (you have Bash), read the touched files'
    current state, and review the union.
  - app_root: app/
  - epic_file: epics/NN-<slug>/epic.md — review against its acceptance criteria too
  - output_path: runs/<run_tag>/temp/epic-NN-findings.json — write it via Bash (you have no Write tool)

  CONTEXT FILES — READ FIRST, in order:
  1. runs/<run_tag>/idea.md
  2. epics/NN-<slug>/epic.md
  3. research/stack-guide.md
  4. .claude/skills/app-review-checklist/SKILL.md — walk it item by item
  5. .claude/skills/app-code-style/SKILL.md and .claude/skills/app-architecture/SKILL.md

  Severity: critical (bug / security / data loss) > major (violates a
  committed stack-guide or generated-skill rule) > minor (idiom, clarity).
  A finding a surgical hunk cannot fix gets "structural": true with
  the structural reason. Return only the most load-bearing findings —
  burying a critical under dozens of minors defeats the patcher.

  Findings schema (the canonical finding shape — identical to step 15's):
  {"epic": "NN-<slug>", "findings": [{"id": "E<NN>-1",
    "severity": "critical|major|minor", "file": "app/...",
    "location": "<function/widget name + short snippet>",
    "issue": "<what is wrong>", "evidence": "<rule or criterion violated, cited>",
    "fix": "<what the patch must accomplish — not the exact wording>",
    "structural": false}]}

  REPORT BACK: findings count per severity + the output path. Data, not prose.
```

3. Findings file missing on return? Parse the JSON out of the critic's Task result and
   write it to the output path yourself via Bash — the patcher needs a file, not a memory.
   If `findings` is empty: record `review: {"findings": 0}` in the manifest note, skip to 14.6.
4. **Pre-stub the patch log.** The patcher is tool-locked to Read+Edit — Edit cannot
   create files, so YOU must stub first. If you skip this, the patcher inlines its log in
   its response and you may drop the data. The schema is canonical; the patcher MUST NOT
   invent alternates:

```bash
echo '{"total_findings": 0, "applied": [], "skipped": [], "conflicts": [], "escalated": []}' > runs/<run_tag>/temp/epic-NN-patch-log.json
```

5. **Spawn ONE `ab-patcher`:**

```
subagent_type: ab-patcher
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are the step 14 per-epic patcher of the appbuilder
  pipeline. ab-code-critic reviewed epic NN-<slug>'s diff and wrote findings;
  you apply them to the code in app/ as surgical Edit hunks. You are
  TOOL-LOCKED to [Read, Edit, Grep, Glob] — you cannot Write, cannot Bash,
  cannot run tests. The orchestrator re-runs the full suite after you return;
  a hunk that breaks it gets reverted. Patch, never regenerate.

  YOUR INPUTS:
  - findings_path: runs/<run_tag>/temp/epic-NN-findings.json
  - patch_log_path: runs/<run_tag>/temp/epic-NN-patch-log.json — already stubbed; Edit the existing keys, the schema is canonical
  - app_root: app/
  - stack_guide: research/stack-guide.md
  - review_checklist: .claude/skills/app-review-checklist/SKILL.md

  For each finding, in severity order: read the file, apply the smallest Edit
  hunk(s) that resolve the issue (your per-hunk size cap is binding), log it
  under "applied". Skip — with reason — findings that are wrong on re-read or
  don't serve the app idea. Any finding marked "structural": true, or
  any fix you cannot express as small hunks, goes under "escalated"
  with the structural reason; the orchestrator turns those into new task
  files. Never delete-and-retype a whole function, file, or widget — that is
  regeneration wearing a patch costume.

  REPORT BACK: counts (applied / skipped / escalated) + patch_log_path. Data,
  not prose.
```

6. **Re-run the full suite.** If red, a patch hunk broke it: find the failing test's
   subject, revert just the hunk(s) touching it (orchestrator Edit — this recovery is the
   ONE code-edit carve-out), move that finding to `skipped` with reason `broke-suite`,
   re-run. Max 3 rounds; still red → `git -C app checkout -- . && git -C app clean -fd`
   (drops ALL patch hunks — the epic ships unpatched but green; log every dropped finding
   in the manifest note). Green beats patched, always.

### 14.5 Escalated findings → NEW TASKS

For each entry in the patch log's `escalated` array: write a NEW task file in the epic's dir with the
next free task number, matching the frontmatter shape of the epic's existing task files
exactly (id, epic, `status: todo`, depends_on, size, category, features, files —
`category` naming a `research/stack-guide.md` `## Code taxonomy` category, matching the
sibling task files; `files:` an HONEST list of the paths the fix will touch — the wave
scheduler keys disjointness off it, and a lied-about list causes in-wave collisions)
plus one extra frontmatter
line `source: escalation — epic NN code review, finding <id>`. Body: the critic's issue +
evidence and the patcher's escalation reason as Context, then Spec / Files to touch /
Testing requirements / Definition of done. Escalation tasks enter the READY SET like any
other `todo` task and run through later waves (14.1 + 14.3); the epic's manifest note
stays `in-progress` — 14.7's close deferred — until they are `done`. Escalation tasks do
NOT get a second critic pass — one review
per epic; step 15's whole-app pass covers their diffs.

### 14.6 Feature status flips

For every feature whose tasks (per the coverage matrix in `epics/00-overview.md` and the
tasks' `features:` frontmatter) are ALL `done`: Edit `features/NN-<slug>.md` frontmatter
`status: designed` → `implemented`. (Step 8 flipped `specced` → `designed`; this is the
final flip. Step 16 checks it.)

### 14.7 Epic close

- If patch hunks were applied: `git -C app add -A && git -C app commit -m "epic <NN>: critic pass"`
  and append the sha to the epic's manifest-note `commits`. (Patcher changed nothing →
  no commit; nothing to record.)
- **Check off the epic's acceptance criteria — with evidence.** For each `- [ ]`
  bullet in the epic's `epic.md` `## Acceptance criteria`, verify it against the app
  and its tests (the criterion names where its evidence lives), then flip it to
  `- [x]` via Edit, appending ` — evidence: <file/test/command>` to the bullet. A
  criterion that does NOT hold means the epic is not done: treat it like a red suite
  (fix via the wave loop) before closing. Step 16's epic-acceptance check requires
  every box `[x]` — an unchecked box here is a guaranteed ship-gate failure.
- Update the manifest note to the full 14.2 shape: `status: "done"`, real counts.
- **NEVER PLAN THE NEXT WAVE WITH A RED SUITE.** The 14.1.5 sync point plus the
  wave-commit invariant enforce this; if you somehow arrive at wave planning red, STOP
  and go back.

## Constraints

- **Do not implement tasks or apply findings yourself.** Spawn ab-implementer /
  ab-patcher. Bypassing the patcher defeats the adversarial-review architecture
  (carve-out: the 14.4.6 hunk-revert recovery only).
- **Do not re-spawn the patcher on identical findings** — a second run on the same input
  is waste. Modify the findings first or handle via 14.4.6.
- **One task per implementer spawn; one WAVE of spawns at a time.** Tasks share a working
  tree — parallel spawns are safe ONLY because wave tasks' `files:` lists are
  pairwise-disjoint. Never batch two tasks into one spawn; never put two
  file-overlapping tasks in one wave; never spawn a task outside the logged wave plan.
- **Task and feature frontmatter flips are orchestrator-only.** Subagents never touch them.

## Artifacts

- `app/` — implemented features and tests; one `wave <N>: <task ids> — <summary>` commit
  per wave, one `epic <NN>: critic pass` commit per patched epic; HEAD always green
- Every task file in `epics/*/` at `status: done` (or `blocked`, honestly recorded);
  escalation task files where the patcher escalated
- `features/NN-<slug>.md` — must/should features at `status: implemented`
- `runs/<run_tag>/temp/wave-log.md` — one `wave <N>: [<task ids>]` line per wave,
  appended BEFORE the wave spawns (the crash-resume record); dead waves get a
  ` — DEAD, recovered on resume; no commit` annotation in 14.0.2
- `runs/<run_tag>/temp/epic-NN-findings.json` + `epic-NN-patch-log.json` per epic
- `runs/<run_tag>/manifest.json` — `epics` progress notes per the 14.2 schema

## Exit criteria

- Every epic in `epics/00-overview.md` is `done` in the manifest's `epics` object
- Every task file (including escalation tasks) has frontmatter `status: done`; any
  `blocked` task → set manifest `blocked_on`, report honestly, and stop instead of exiting
- Full test suite green AND every generated-skill `scripts/*.sh` gate passing — run
  both one final time NOW, mechanically; never from memory
- `git -C app log` shows a `wave <N>:` commit for every wave in `temp/wave-log.md` NOT
  annotated ` — DEAD` (a dead wave's recovered work rides in a later wave's commit) and an
  `epic <NN>: critic pass` commit for every epic whose patcher applied hunks — the audit
  trail runs task → wave commit
- Every epic's acceptance criteria checked `- [x]` with evidence (14.7)
- Every must/should feature file at `status: implemented`
- Per-epic findings JSON + patch log exist for every epic that had findings

Then update manifest: `steps."14" = "done"`, mark the step-14 todo complete, return to
the router.

## Next step

Return to the router (`appbuilder`). Invoke step 15:

```
Skill(skill: "appbuilder-15-adversarial-review")
```
