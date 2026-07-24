# epics/ — the backlog contract

The full implementation backlog for the app, written by step 11 (`hyperbuild-11-epics`):
`hb-epic-planner` drafts the breakdown (a temp working doc), 3–6 `hb-task-author` write
each epic's `epic.md` + task files in parallel, the orchestrator writes
`00-overview.md` from disk, and `hb-spec-critic` audits coverage. Consumed by the
step 12 design gate (existence + coverage checks), step 14 (the wave loop schedules
this directory's task DAG in parallel waves across ALL epics), and the step 16 ship
gate (every task must be `done`).

This directory is pipeline-owned. The ONLY hands that touch it after step 11 are
step 14 — flipping task `status` frontmatter and checking off epic acceptance-criteria
boxes with evidence at epic close — and step 15, appending new task files (and, when
no epic fits, one new epic dir) for structural findings. Never hand-edit.

Scale: 4–8 epics at `standard` gear (6–12 at `premier`); 3–8 tasks per epic at
`standard` (4–10 at `premier`). Every must/should PRD feature maps to ≥1 task — no
exceptions; the design gate blocks on it.

## Directory shape

```
epics/
├── 00-overview.md                     # epic list, dependency order, PRD coverage matrix
├── 01-foundation/
│   ├── epic.md
│   ├── task-01-project-shell.md
│   └── task-02-navigation-frame.md
├── 02-habit-core/
│   ├── epic.md
│   ├── task-01-habit-model.md
│   ├── task-02-habit-list-screen.md
│   └── task-03-habit-editor.md
└── ...
```

`NN` prefixes are two-digit and zero-padded. **`depends_on` is the ONLY ordering
guarantee**: step 14 (the wave loop) schedules the task DAG, not the numbering — it
runs ready tasks from ANY epic in parallel waves, honoring epic and task `depends_on`
edges. The `NN` numbering is step 14's ready-set walk / tie-break order and the
human narrative order, nothing more; an ordering that MUST hold has to be a
`depends_on` edge. `depends_on` MUST be consistent with the numbering — an epic may
only depend on lower-numbered epics, a task only on lower-numbered tasks in the same
epic. No forward references, no cycles.

## 00-overview.md

Written by the orchestrator (step 11.4) after all task authors return. Frontmatter
(`run_tag`, `created`, `epics`, `tasks`) plus three required sections:

```markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
epics: 4
tasks: 18
---
# Backlog overview — Habit Coach

## Epics (dependency order)
| # | Epic | Depends on | Tasks | Features |
|---|------------|-----------|-------|------------|
| 01 | Foundation | — | 2 | F-01 |
| 02 | Habit core | E-01 | 3 | F-01, F-02 |

## PRD coverage matrix
| Feature | MoSCoW | Epic | Tasks |
|---------|--------|------|-----------------------|
| F-01 habit CRUD | must | E-02 | T-02-01, T-02-02, T-02-03 |
| F-03 weekly insights | must | E-03 | T-03-01, T-03-02 |

## Build order
One short paragraph: the topological order step 14 follows, and why.
```

The coverage matrix is checked in BOTH directions at the design gate: every must/should
feature id from `features/00-index.md` appears in ≥1 task's `features:` list, and every
feature id a task cites exists as a `features/NN-<slug>.md` file.

## epic.md

```markdown
---
id: E-02
name: Habit core
depends_on: [E-01]
---

## Goal
One paragraph: what the app can do when this epic is done that it couldn't before.

## Scope
Bulleted list of what this epic delivers.

## Out of scope
Explicitly named non-goals, so implementers don't gold-plate.

## Acceptance criteria
- [ ] Checkable bullets, verifiable against the built app or its tests.
- [ ] Each criterion names WHERE the evidence lives (screen, test file, command).
```

Epic ids are `E-NN`, matching the directory prefix. An epic has no status field of its
own (epic status lives in the manifest's `epics` object): an epic is done when every
one of its tasks is `status: done` AND its acceptance criteria are checked off — step
14 verifies each criterion at epic close and flips `- [ ]` to `- [x]` with evidence.
The step 16 ship gate verifies both.

## task-NN-<slug>.md

```markdown
---
id: T-02-01
epic: E-02
status: todo
depends_on: []
size: M
category: ui-component
features: [F-01]
files: [app/lib/widgets/habit_card.dart, app/test/widgets/habit_card_test.dart]
---

## Context
Why this task exists; where it sits in the epic; what already exists when it starts.

## Spec
Exactly what to build. Concrete, checkable, references the feature file and the
chosen mockup HTML for its screens — not a vibe.

## Files to touch
Expected paths under app/ (create or modify). Implementers may deviate with a stated
reason, never silently.

## Testing requirements
What tests hb-test-engineer must write/extend, and what they must prove.

## Definition of done
- [ ] Checkable bullets. Code merged, tests green, feature wired end-to-end.
```

Frontmatter fields — ALL required:

- `id` — `T-<epicNN>-<taskNN>` (e.g. `T-02-01`): globally unique, sortable, cited by
  the coverage matrix.
- `epic` — the owning epic's id (`E-NN`).
- `status` — the lifecycle field. See below.
- `depends_on` — list of task ids in the SAME epic that must be `done` first (`[]` if
  none). Cross-epic ordering is expressed by epic `depends_on`, never here.
- `size` — `S` | `M`. `S` is the default (one focused change + its test); `M` (a small
  slice across a few files) needs a one-line justification in `## Context`; `L` means
  the task MUST be split before writing — **no task ships as `L`** (step 11's audit
  flags any `size: L` as a major finding).
- `category` — the code-taxonomy category (or categories) this task's files belong to,
  from `research/stack-guide.md`'s `## Code taxonomy`. MANDATORY; step 11's audit
  rejects a value not present in the taxonomy.
- `features` — the feature ids this task implements (`features: [F-03]`). MANDATORY:
  a task that cites no feature is either infrastructure (cite the epic's goal in
  Context and use `features: []` deliberately) or a coverage-matrix bug.
- `files` — the planned repo-relative paths this task will create or modify
  (`files: [app/lib/widgets/habit_card.dart, app/test/widgets/habit_card_test.dart]`).
  MANDATORY and machine-readable: step 14's wave scheduler parallelizes only tasks
  with pairwise-disjoint `files:` lists — this list is what makes that safe. It is
  a PLAN, not a log: step 14 holds implementers to it, and deviating needs a stated
  reason, never silence.

## Status lifecycle

```
todo  →  in-progress  →  done
              └→  blocked   (3x-red task: files reverted, reason recorded)
```

- **todo** — as written by step 11. The design gate requires EVERY task at `todo`.
- **in-progress** — set by step 14 the moment the task's wave spawns. ALL of a wave's
  tasks — from the same epic or different ones — are `in-progress` simultaneously;
  that is safe because a wave's `files:` lists are pairwise-disjoint. A crashed run
  resumes via step 14's wave-log + re-verification ladder: a logged wave with no
  matching `wave <N>:` commit is dead, and every stuck `in-progress` task is
  re-verified (its `files:` exist and its tests pass → flipped `done`; otherwise its
  files are reverted and it flips back to `todo`) — never by hunting for a single
  `in-progress` task.
- **blocked** — set by step 14 after 3 red implement/test rounds: the task's `files:`
  are reverted, a one-line reason recorded, and its dependents leave the ready set.
  A `blocked` task blocks the step 16 ship gate honestly — never fake a `done`.
- **done** — set by step 14 only after `hb-test-engineer` reports the task's tests
  green. NEVER set `done` on red tests; NEVER skip `in-progress`.

Status changes are surgical frontmatter edits — the body of a task file is never
rewritten after step 11. Step 15 may APPEND new task files (structural findings from
the whole-app review, max 1 loop back through step 14); it never deletes or rewrites
existing ones. The step 16 ship gate requires every task in `epics/**/task-*.md` —
including step 15 additions — at `status: done`.
