---
name: hyperbuild-4-5-feature-specs
description: >
  Step 4.5 of the hyperbuild pipeline — expands every must/should PRD
  feature into its own deep spec file at the repo root:
  features/NN-<slug>.md (frontmatter id, name, moscow, status: specced,
  screens; eight required body sections) plus the features/00-index.md
  roster. Cap 15 files (standard) / 25 (premier). Spawns 3–5
  hb-feature-author subagents in parallel, features split into batches,
  every claim evidenced from the research vault. Steps 6–8 draw real
  flows and content from these specs, step 11 tasks cite feature ids,
  and the step 12 and 16 gates check feature coverage and status flips.
  Invoked by the hyperbuild router via Skill(); not run directly by users.
---

# Step 4.5 — Feature specs (parallel, 3–5 authors)

You are executing step 4.5 (feature-specs) of the hyperbuild pipeline. Step 4 froze the PRD — its MoSCoW list and canonical screen inventory; this step expands every must/should feature into a complete spec file that steps 6–8 (design + mockups) read for real content and flows, step 11 tasks cite by id (`features: [F-NN]`), and step 14 implementers treat as primary spec alongside the task file.

**Gear gate:** runs for both gears. Cap: **15 feature files (standard) / 25 (premier)**. Every must/should gets a file; could-features get files only if the cap still allows.

**Goal:** one `features/NN-<slug>.md` per must/should PRD feature plus `features/00-index.md`, every claim traceable into `research/`. A feature spec nobody evidenced is a requirement nobody asked for — the authors cite the vault, never their imagination.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`; confirm `steps["4"]` is `"done"`
- `research/product-spec.md` — the PRD: MoSCoW feature list (with Evidence lines) + the canonical screen inventory. FROZEN — never rename a screen or feature here.
- `research/sentiment-synthesis.md`, `research/sentiment/*.md`, `research/competitor-landscape.md`, `research/competitors/*.md` — the evidence vault the authors cite
- `features/README.md` — the directory format contract (the schemas below mirror it)

Set `steps."4.5" = "running"` in the manifest, mark the step-4.5 todo in_progress, then `mkdir -p features`.

---

## Procedure

### 4.5.1 — Freeze the feature roster (orchestrator)

1. Extract every **must**, then every **should**, from the PRD in its order. Number them `NN` two-digit from `01` (priority order), id `F-NN`, slug = kebab-case of the feature name (`F-03`, `03-weekly-insights`).
2. Copy each feature's screen names **verbatim from the PRD screen inventory** — a renamed screen here orphans mockups in step 8 and task references in step 11.
3. must+should count must be ≤ **15 (standard) / 25 (premier)** — step 4's exit criteria guarantee this. If it is over the cap anyway, the PRD is defective: return to the router and resume at step 4. Never trim the list yourself here.
4. Could-features: add to the roster ONLY while the count stays under the cap AND the PRD records real evidence for them; note each inclusion in `runs/<run_tag>/temp/orchestrator-notes.md`.
5. Record the full roster (NN, id, slug, name, moscow, screens) in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 4.5.2 — Spawn 3–5 `hb-feature-author` subagents (parallel, ONE message)

Split the roster into contiguous batches, zero overlap: **3 authors for ≤9 features, 4 for 10–16, 5 for 17+**. Spawn all authors in ONE message — true parallel execution.

**Spawn template (fill one per batch):**

```
subagent_type: hb-feature-author
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 4.5 (feature specs) of the hyperbuild
  pipeline. Step 4 froze the PRD — its MoSCoW list and screen inventory
  are law. You expand YOUR assigned batch of features into full spec
  files; sibling authors cover the other batches in parallel — never
  write outside your batch. After all authors return, the orchestrator
  writes features/00-index.md; steps 6-8 read your specs for real flows
  and content, step 11 tasks cite your feature ids, and step 14
  implements from them. You write specs, not code and not tasks.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - batch: [<one line per feature: F-NN | NN-<slug> | "<name>" |
    <moscow> | screens: [<verbatim screen names>]>]
  - output_files: features/<NN>-<slug>.md, one per batch feature
  - prd: research/product-spec.md

  READ FIRST (in order):
  - runs/<run_tag>/idea.md
  - research/product-spec.md — your features' sections + the screen inventory
  - research/sentiment-synthesis.md — the demand evidence
  - the research/competitors/*.md and research/sentiment/*.md files the
    PRD's Evidence lines cite for your features — verify each citation
    before repeating it

  FEATURE SPEC FORMAT — write every file exactly this shape:

  ---
  id: F-<NN>
  name: <feature name>
  moscow: must | should | could
  status: specced
  screens: [<screen names from the PRD screen inventory, verbatim>]
  ---

  # F-<NN> — <feature name>

  ## Overview            (what + why, plain language, 1-2 paragraphs)
  ## User stories        (as-a / I-want / so-that; at least 2)
  ## UX flow             (numbered primary flow + alternate flows, citing
                          screens by their verbatim inventory names)
  ## States & edge cases (empty, loading, error, offline,
                          permission-denied — every state relevant to
                          this feature, with expected behavior)
  ## Data touchpoints    (entities read/written, and by which flow step)
  ## Acceptance criteria (checkable bullets — step 11 tasks and step 14
                          tests are written against these)
  ## Evidence            (links into research/: competitor dossiers that
                          ship this, verbatim sentiment quotes demanding
                          it — real paths, real quotes, nothing invented)
  ## Open questions      (what evidence could not settle; "None." if none)

  All eight body sections non-empty. NEVER invent a requirement the PRD
  and vault do not support — a thin honest spec beats a padded one.
  NEVER rename a screen or re-scope MoSCoW. No TBD/TODO placeholders.

  Report back: files written, per-feature acceptance-criteria count, and
  any feature whose PRD evidence looked weak. Data, not prose.
```

### 4.5.3 — Wait discipline

**CRITICAL: never emit bare text while authors are in flight** — a text-only response ends the turn and kills the pipeline. Append thoughts (index one-liners, which features look design-heavy for step 6) to `runs/<run_tag>/temp/orchestrator-notes.md`.

### 4.5.4 — Partial-failure policy

Authors fail independently. If a batch's files are missing or defective, re-spawn that ONE author ONCE with the missing files named as its explicit required deliverables. If it fails twice, write that batch's files yourself from the FEATURE SPEC FORMAT (the PRD + vault give you everything needed) and log the failure in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 4.5.5 — Validate mechanically

For every roster feature:

1. `features/<NN>-<slug>.md` exists; frontmatter has `id`, `name`, `moscow`, `status: specced`, `screens`.
2. All eight body sections present and non-empty (`grep -c '^## '` = 8).
3. Every `screens:` entry appears verbatim in the PRD screen inventory.
4. Every path cited under `## Evidence` exists on disk.
5. Total file count ≤ 15 (standard) / 25 (premier); every must/should covered.

Defects: re-spawn the owning author ONCE with the failed checks named; still failing → patch the gaps yourself via Edit (surgical, never a rewrite).

### 4.5.6 — Write `features/00-index.md` (orchestrator)

After all files validate, read every feature file from disk (trust disk, not report-backs) and write:

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
features: <N>
---

# Feature index — <app name>

| id | Feature | MoSCoW | Screens | One-liner |
|----|---------|--------|---------|-----------|
| F-01 | <name> | must | Home, Habit Detail | <one line from its Overview> |
```

One row per feature file, in NN order. Statuses live in the feature files (steps 8 and 14 flip them there) — the index deliberately carries none, so it never goes stale.

---

## Artifacts

- `features/<NN>-<slug>.md` — one per feature; frontmatter `id`, `name`, `moscow`, `status: specced`, `screens`; the eight body sections in the FEATURE SPEC FORMAT
- `features/00-index.md` — frontmatter `run_tag`, `created`, `features`; one table row per feature (id, name, moscow, screens, one-liner)

---

## Exit criteria

- Every must/should PRD feature has a `features/NN-<slug>.md` passing all five 4.5.5 checks; total files ≤ 15 (standard) / 25 (premier)
- Every `## Evidence` section cites at least one existing `research/` path (competitor dossier or verbatim sentiment quote)
- `features/00-index.md` exists with one row per feature file, ids and screens matching the files
- Screen names everywhere match the PRD screen inventory verbatim

Then update the manifest: `steps."4.5" = "done"`, mark the step-4.5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). It invokes:

```
Skill(skill: "hyperbuild-5-stack-research")
```

Step 5 researches HOW to build what these specs describe; the specs next matter at step 6 (design research reads them for real flows).
