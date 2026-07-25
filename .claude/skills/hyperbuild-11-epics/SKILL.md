---
name: hyperbuild-11-epics
description: >
  Step 11 of the hyperbuild pipeline — turns the PRD and feature specs into
  the full backlog: epics/00-overview.md with the PRD coverage matrix, one
  epics/NN-<slug>/ dir per epic, one task file per task with the frontmatter
  contract step 14 keys off. Spawns 1 hb-epic-planner (orchestrator approves
  the breakdown), then parallel hb-task-author subagents (one per epic),
  then an hb-spec-critic coverage audit — every must/should PRD feature maps
  to ≥1 task. Invoked by the hyperbuild router via Skill(); not run directly
  by users.
---

# Step 11 — Epics & tasks (the full backlog)

You are executing step 11 (epics) of the hyperbuild pipeline. Step 10 forged the
project-specific skills; step 12 gates the backlog you write here; step 14 implements it.

**Goal:** a complete, dependency-ordered backlog under `epics/` where every must/should
PRD feature traces to ≥1 task, each executable by a fresh hb-implementer with zero
conversation context.

**Why this step exists:** the backlog is Stage B's entire work order — step 14 reads
task files, not your intentions. A feature with no task here silently does not exist in
the shipped app. Coverage is enforced twice (11.5 audit, then the step 12 gate): a gap
caught now costs one task file; after step 16 it costs a re-plan.

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Never paraphrased.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`; confirm steps 1–10 are `done`
- `research/product-spec.md` — the PRD: MoSCoW feature list + the canonical screen inventory
- `features/00-index.md` — every feature: id, name, moscow, screens (and each `features/NN-<slug>.md` on demand)
- `research/02-engineering/author/stack-guide.md` — committed structure/testing decisions AND the `## Code taxonomy` (named code categories + placement rules); "files to touch" paths must follow it, and every task names the category its files belong to
- `runs/<run_tag>/decisions/platform.md` — chosen stack

Scale knobs (gear from manifest):

| Knob | standard | premier |
|------|----------|---------|
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Critic fix rounds | ≤3 | ≤3 |

**Task-sizing rules (binding on the planner, the authors, and your own patches):** one
component / model / service / screen-section per task where feasible; a task an
implementer can't finish with full focus in one sitting gets SPLIT. `size: S` is the
default; `M` needs a one-line justification in `## Context`; **`L` MUST be split — no
task ships as L**. UI screens decompose into SMALL composable subcomponents — each its
own task or an explicit checklist item within one — plus a final assembly task that
composes the screen from already-tested parts (the assembly task's `depends_on` lists
every one of its screen's subcomponent task ids). Every task names the taxonomy category
(or categories) its files belong to, per stack-guide's `## Code taxonomy`.

## Procedure

### Step 11.1 — Spawn ONE `hb-epic-planner` (the breakdown draft)

**Spawn template:**
```
subagent_type: hb-epic-planner
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 11 (epic planner) of the hyperbuild
  pipeline. Step 4 produced the PRD, step 4.5 the feature specs, step 5 the
  stack guide. You draft the epic breakdown ONLY — the orchestrator
  approves it, then parallel hb-task-author subagents (one per epic) write
  the actual epic and task files from your draft. You write no task files.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - epic_count_range: 4–8 (standard) / 6–12 (premier)
  - output_path: runs/<run_tag>/temp/epic-breakdown.md

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - research/product-spec.md — MoSCoW list + screen inventory
  - features/00-index.md — the feature ids you must assign
  - research/02-engineering/author/stack-guide.md +
    runs/<run_tag>/decisions/platform.md —
    architecture shapes the epic seams

  Write output_path with: (1) an "## Epics (dependency order)" table —
  columns NN | slug | name | depends_on | features | est. tasks — NN
  two-digit from 01, slug kebab-case, depends_on listing earlier epics
  only; (2) "## Rationale" — why this split and this order; (3)
  "## Assignment check" — every must/should feature id from
  features/00-index.md in ≥1 epic's features column (prefer exactly one
  owning epic), plus any deliberately deferred could-features. Estimate
  tasks for SMALL one-kind tasks — one component/model/service/
  screen-section each; plan each mockable screen as small composable
  subcomponent tasks (or explicit checklist items within one task) plus
  a final assembly task that composes the screen from already-tested
  parts, and count these in est. tasks. Do NOT create a
  setup/scaffolding epic — step 13 owns project init, lint, CI,
  theme wiring; epic 01 assumes a scaffolded app. Do NOT invent features
  absent from the PRD. Your final message: epic count, dependency chain as
  one line, any feature you could not place. Data, not prose.
```

### Step 11.2 — Approve the breakdown (orchestrator judgment, checkable)

Read `runs/<run_tag>/temp/epic-breakdown.md` and verify ALL of:

1. Epic count within gear range (4–8 standard / 6–12 premier).
2. Every must/should id from `features/00-index.md` appears in ≥1 epic row. Zero orphans.
3. `depends_on` references only earlier epics — the order is a valid topological order.
4. No scaffolding/setup epic (step 13's job), no epic for won't-features.
5. Estimated tasks per epic within gear range (3–8 standard / 4–10 premier).
6. Estimates reflect the task-sizing rules: screens counted as subcomponent tasks + an assembly task, not one monolithic task per screen.

Fix small defects by editing the breakdown directly (it is a working doc, not a shipped
artifact). If the split is structurally wrong (features scattered, order cyclic),
re-spawn the planner ONCE with the specific defects named. Then proceed.

### Step 11.3 — Spawn `hb-task-author` subagents, ONE PER EPIC, in parallel

Spawn one author per epic **in ONE message** — true parallel execution. Cap 6 in
flight: with more than 6 epics, spawn in waves of ≤6 (the 3–6 concurrent authors the
pipeline budgets for). Each author owns exactly one epic directory — **zero overlap**.
**CRITICAL: never emit bare text while authors are in flight** — it ends the turn and
kills the pipeline; append hypotheses to `runs/<run_tag>/temp/orchestrator-notes.md`.

**Spawn template (one per epic; fill from the approved breakdown row):**
```
subagent_type: hb-task-author
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 11 (task author) of the hyperbuild
  pipeline — one of <K> parallel authors, one per epic. The approved
  breakdown assigned you ONE epic; you write its epic.md and all its task
  files. After all authors return, the orchestrator builds the PRD coverage
  matrix and an hb-spec-critic audits it; in Stage B, step 14 implementers
  execute your task files verbatim — write for a reader with zero
  conversation context.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - epic_number: <NN>
  - epic_slug: <slug>
  - epic_name: "<name>"
  - depends_on: [<E-NN ids from the breakdown, [] if none>]
  - assigned_features: [<F-NN ids from the breakdown row>]
  - task_count_range: 3–8 (standard) / 4–10 (premier) — gear: <gear>
  - output_dir: epics/<NN>-<slug>/

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - research/product-spec.md — your features' PRD sections + the screen inventory
  - features/<NN>-<slug>.md for EVERY id in assigned_features — the primary spec (UX flows, states, acceptance criteria)
  - research/02-engineering/author/stack-guide.md — "Files to touch" must use its committed project structure (paths under app/), "Testing requirements" its committed test strategy
  - runs/<run_tag>/temp/epic-breakdown.md + epics/README.md — your epic's position in the order + the directory format contract

  Write epics/<NN>-<slug>/epic.md and one task-<MM>-<slug>.md per task
  (MM two-digit from 01, in execution order), using EXACTLY the schemas
  below. Every task lists the feature ids it implements in `features:`;
  every assigned feature appears in ≥1 task; tasks that touch a screen
  name it exactly as the PRD screen inventory spells it. Slice vertically
  (feature slice + its tests), not by layer. SIZE: one component / model /
  service / screen-section per task where feasible; a task an implementer
  can't finish with full focus in one sitting gets split — split, don't
  bloat. size: S is the default; M needs a one-line justification in
  ## Context; L means you split it before writing — no task ships as L.
  UI screens: decompose into SMALL composable subcomponents — each its
  own task or an explicit checklist item within one task — plus a final
  assembly task that composes the screen from already-tested parts. The
  assembly task's `depends_on` MUST list EVERY subcomponent task id of
  its screen — step 14's blocked-task routing ("continue with tasks
  that don't depend on it") keys off those declared edges.
  Every task's `category:` names the category (or categories) its files
  belong to, per research/02-engineering/author/stack-guide.md's
  ## Code taxonomy. Every
  task's `files:` lists the planned repo-relative paths it will create
  or modify (under app/, placed per the taxonomy) — REQUIRED, realistic,
  minimal, never empty: step 14's wave scheduler runs only tasks with
  pairwise-disjoint files: lists in parallel. An assembly task's files:
  may overlap its subcomponent tasks' files: ONLY for the composition
  file(s) the assembly task itself owns. Do NOT
  write tasks for other epics' features. Do NOT invent features. Do NOT
  write scaffolding tasks (step 13 owns project init).

  EPIC SCHEMA (epics/<NN>-<slug>/epic.md):
  ---
  id: E-<NN>
  name: <epic name>
  depends_on: [<E-NN ids, [] if none>]
  ---
  # Epic <NN> — <name>
  ## Goal            (one paragraph: the user-visible capability when done)
  ## Scope           (bullets: what this epic delivers, by feature id)
  ## Out of scope    (bullets: adjacent work explicitly deferred, and to where)
  ## Acceptance criteria   ("- [ ]" checkbox bullets, each naming where its
                            evidence lives — step 14 verifies and checks them
                            off at epic close; step 16 requires every box [x].
                            An epic has no status frontmatter — epic status
                            lives in the manifest's epics object.)

  TASK SCHEMA (epics/<NN>-<slug>/task-<MM>-<slug>.md):
  ---
  id: T-<NN>-<MM>
  epic: E-<NN>
  status: todo
  depends_on: [<T-NN-MM ids that must be done first, [] if none>]
  size: <S|M|L>       # S (default) = one focused change + its test; M = a small slice across a few files — justify in ## Context; L = cross-cutting — MUST be split before writing, no task ships as L
  category: <taxonomy category (or categories) from stack-guide's ## Code taxonomy>
  features: [<F-NN ids this task implements>]
  files: [<planned repo-relative paths this task will create/modify>]   # REQUIRED, machine-readable — step 14's wave scheduler runs only tasks with pairwise-disjoint files: lists in parallel
  ---
  # T-<NN>-<MM> — <task name>
  ## Context               (why this task exists; what exists before it starts)
  ## Spec                  (exact behavior: flows, states, edge cases — pull from the feature file, cite screens by inventory name)
  ## Files to touch        (real paths under app/ per stack-guide; mark new vs modified)
  ## Testing requirements  (which test types per stack-guide, what they must prove)
  ## Definition of done    (checkable bullets; ALWAYS includes "tests pass" and "status flipped to done")

  Every section non-empty. `status: todo` on every file — step 14 flips
  statuses, never you. Your final message: task count, task ids with
  one-line names, feature ids covered, any you could NOT cover. Data, not
  prose.
```

**Partial-failure policy:** authors fail independently. If one fails, re-spawn it ONCE
for its epic only; if it fails twice, write that epic's files yourself from the schemas
above and log the failure in `runs/<run_tag>/temp/orchestrator-notes.md`.

### Step 11.4 — Write `epics/00-overview.md` (orchestrator)

After ALL authors return, read every `epic.md` and task file on disk (trust disk, not report-backs) and write:

```markdown
---
run_tag: <run_tag>
created: <ISO date>
epics: <E>
tasks: <T>
---
# Backlog overview — <app name>
## Epics (dependency order)
| # | Epic | Depends on | Tasks | Features |
|---|------|-----------|-------|----------|
| 01 | <name> | — | 5 | F-01, F-02 |
## PRD coverage matrix
| Feature | MoSCoW | Epic | Tasks |
|---------|--------|------|-------|
| F-01 <name> | must | E-01 | T-01-02, T-01-03 |
## Build order
<one short paragraph: the topological order step 14 will follow, and why>
```

ONE matrix row per must/should feature from `features/00-index.md` (could-features with
tasks go below a separator). **A blank Tasks cell on a must/should row is a defect here
and a gate failure at step 12** — do not write the file with one.

### Step 11.5 — Spawn ONE `hb-spec-critic` (coverage audit)

**Spawn template:**
```
subagent_type: hb-spec-critic
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md, verbatim}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are the step 11 coverage auditor of the hyperbuild
  pipeline. Task authors just wrote the backlog under epics/; you audit it
  against the PRD and feature specs; the orchestrator patches the gaps you
  find (max 3 rounds). A gap you miss surfaces as a step 12 gate failure —
  or worse, a feature silently missing from the shipped app. You are
  tool-locked to [Read, Grep, Glob] — you audit; you NEVER edit.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - gear: <standard|premier>
  - prd: research/product-spec.md
  - feature_index: features/00-index.md
  - backlog: epics/ (00-overview.md, every epic.md, every task file)
  - output: return your findings JSON as your ENTIRE final message — you
    cannot Write; the orchestrator saves it to disk

  CHECKS (run all):
  1. Every must/should feature id in features/00-index.md appears in ≥1 task's `features:` frontmatter.
  2. Every `features:` id in every task exists in features/00-index.md — no invented ids.
  3. The coverage matrix in epics/00-overview.md matches the task files on disk — no phantom rows, no missing rows, no blank must/should Tasks cells.
  4. Every screen in the PRD screen inventory is named in ≥1 task's Spec or Files-to-touch section.
  5. Both depends_on graphs (epic-level, task-level) are acyclic and reference only existing ids.
  6. Every task file has valid frontmatter (id, epic, status: todo, depends_on, size, category, features, files) and all five body sections non-empty.
  7. Epic count and per-epic task counts within gear range: epics 4–8 / tasks 3–8 (standard); epics 6–12 / tasks 4–10 (premier).
  8. Sizing rules hold: zero tasks with size: L; every size: M task carries a one-line size justification in ## Context; every `category:` value names a category present in research/02-engineering/author/stack-guide.md's ## Code taxonomy; every screen implemented by tasks decomposes into subcomponent tasks (or explicit checklist items) plus an assembly task — no single build-the-whole-screen task; every assembly task's depends_on lists ALL of its screen's subcomponent task ids (an assembly task omitting a part is a finding).
  9. Every task's `files:` is non-empty and lists planned repo-relative paths; an assembly task's `files:` may overlap its subcomponent tasks' `files:` ONLY for the composition file(s) the assembly task owns — any other overlap between an assembly task and its parts is a finding.

  FINDINGS SCHEMA:
  {"verdict": "pass" | "gaps",
   "findings": [{"id": "COV-1", "check": <1-9>, "severity": "critical" | "major" | "minor",
     "detail": "F-07 (offline mode, must) appears in no task's features: frontmatter",
     "fix": "add a task to E-04 implementing F-07 per features/07-offline-mode.md"}]}

  Severity: critical = uncovered must/should feature, cyclic deps, invented
  id; major = matrix drift, uncovered screen, malformed frontmatter, a
  size: L task, a category absent from the stack-guide taxonomy, an
  assembly task whose depends_on omits a subcomponent task, an empty or
  missing files: list, an assembly files: overlap beyond its owned
  composition file(s); minor = the rest. At most 15 findings — return
  the most load-bearing.
```

Save the returned JSON verbatim to `runs/<run_tag>/temp/epic-coverage-findings.json`.

### Step 11.6 — Patch the gaps (orchestrator; patch, never regenerate)

For every `critical`/`major` finding: fix the ARTIFACT. 1–2 missing tasks → write them
yourself using the task schema exactly. 3+ gaps in one epic → re-spawn that epic's
`hb-task-author` with `assigned_features` narrowed to the gap ids. Matrix drift →
re-derive `00-overview.md` from disk. Then re-spawn `hb-spec-critic` fresh. **Max 3
audit rounds** (≤3 both gears). Zero criticals is mandatory to exit; log residual minor
findings to `orchestrator-notes.md` and proceed. Never regenerate the whole backlog.

## Artifacts

- `runs/<run_tag>/temp/epic-breakdown.md` (approved working doc) and `runs/<run_tag>/temp/epic-coverage-findings.json` (final audit, verdict `pass`)
- `epics/00-overview.md` — epic table, PRD coverage matrix, build order (frontmatter: run_tag, created, epics, tasks)
- `epics/<NN>-<slug>/epic.md` — one per epic (frontmatter: id, name, depends_on — no status; acceptance criteria as `- [ ]` checkboxes)
- `epics/<NN>-<slug>/task-<MM>-<slug>.md` — one per task (frontmatter: id, epic, status: todo, depends_on, size, category, features, files; body: Context, Spec, Files to touch, Testing requirements, Definition of done)

## Exit criteria

- `epics/00-overview.md` exists; coverage matrix has zero blank Tasks cells on must/should rows
- Epic count within gear range; every epic dir has `epic.md` + task count within gear range; every task file has valid frontmatter with `status: todo`, a `category` naming a stack-guide `## Code taxonomy` category, a non-empty `files:` list of planned repo-relative paths (assembly tasks overlapping their parts' `files:` only on the composition file(s) they own), and all five body sections
- Task-sizing rules hold: zero `size: L` tasks (split instead); every `size: M` task justified in `## Context`; every screen with tasks decomposed into subcomponent tasks/checklist items + an assembly task
- Final `epic-coverage-findings.json` verdict is `pass` (or all critical/major findings patched within 3 rounds — if criticals remain after round 3, STOP: set manifest `blocked_on: "epic-coverage"` and report honestly instead of proceeding)
- Then update manifest: `steps.11 = "done"`, mark the step-11 todo complete, return to the router.

## Next step

Return to the router (`hyperbuild`). Invoke step 12:

```
Skill(skill: "hyperbuild-12-design-gate")
```
