# features/ — the feature-spec contract

One markdown file per feature, written by step 4.5 (`appbuilder-4-5-feature-specs`,
spawning 3–5 `ab-feature-author` in parallel). Every must/should PRD feature gets a
file; could-features get files only if the cap allows. **Cap: 15 files at `standard`
gear / 25 at `premier`.** This directory is pipeline-owned — never hand-edit.

## Directory shape

```
features/
├── 00-index.md          # the roster: one row per feature
├── 01-habit-crud.md
├── 02-daily-checkin.md
└── 03-weekly-insights.md
```

`NN` is two-digit priority order (musts first, then shoulds, in PRD order). Slug =
kebab-case feature name. Feature ids are `F-NN`, matching the file prefix.

## features/NN-<slug>.md

```markdown
---
id: F-03
name: Weekly insights
moscow: must | should | could
status: specced          # specced → designed → implemented (steps 8/14 flip it)
screens: [Home, Insights]
---

# F-03 — Weekly insights

## Overview              (what + why, in plain language)
## User stories          (as-a / I-want / so-that; at least 2)
## UX flow               (numbered primary flow + alternate flows, screens cited
                          by their verbatim PRD screen-inventory names)
## States & edge cases   (empty, loading, error, offline, permission-denied —
                          wherever relevant, with expected behavior)
## Data touchpoints      (entities read/written)
## Acceptance criteria   (checkable bullets — tasks and tests are written
                          against these)
## Evidence              (links into research/: competitor dossiers that ship
                          this feature, verbatim sentiment quotes demanding it)
## Open questions        ("None." if none)
```

All eight body sections are required and non-empty. `screens:` entries are copied
verbatim from the PRD's canonical screen inventory — a renamed screen orphans mockups
(step 8) and task references (step 11).

## Status lifecycle

```
specced → designed → implemented
```

- **specced** — as written by step 4.5.
- **designed** — flipped by step 8 once every screen the feature names is mocked in
  all three designs.
- **implemented** — flipped by step 14 once every task citing the feature is `done`.
  The step 16 ship gate verifies every must/should feature reads `implemented`.

Status changes are surgical frontmatter edits by the pipeline only; the body of a
feature file is never rewritten after step 4.5.

## 00-index.md

Frontmatter `run_tag`, `created`, `features` (count); then one table row per feature:

```markdown
| id | Feature | MoSCoW | Screens | One-liner |
|----|---------|--------|---------|-----------|
| F-01 | Habit CRUD | must | Home, Habit Editor | Create, edit, archive habits |
```

The index carries no status column (statuses live in the files, so the index never
goes stale).

## Downstream contract

- **Steps 6–8** (design research, design systems, mockups) read feature specs for real
  content, flows, and states — never lorem ipsum.
- **Step 11** tasks MUST cite the feature ids they implement (`features: [F-03]` in
  task frontmatter); every must/should feature maps to ≥1 task.
- **Step 12** (design gate) checks every must/should feature file exists with all
  eight sections and is covered by ≥1 task.
- **Step 14** implementers read the feature file as primary spec alongside the task
  file; **step 16** verifies the status flips.
