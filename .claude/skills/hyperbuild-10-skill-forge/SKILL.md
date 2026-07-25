---
name: hyperbuild-10-skill-forge
description: >
  Step 10 of the hyperbuild pipeline — generates the five PROJECT-SPECIFIC
  Claude Code skills into .claude/skills/ (app-code-style, app-architecture,
  app-testing, app-components, app-review-checklist) in the rich four-part
  anatomy (SKILL.md + references/ + examples/ + scripts/ PASS-FAIL gates)
  by spawning 5 hb-skill-smith subagents in parallel, each grounded in
  research/02-engineering/author/stack-guide.md + research/product-spec.md,
  bound by step 9's
  research/04-claude-skills/author/skill-authoring-guide.md, and adapting harvested skills from
  step 9's shortlist where they fit. These skills steer every step 14
  implementer and arm the step 15 critics; app-components gets its concrete
  design-token references wired later by step 13. Invoked by the hyperbuild
  router via Skill(); not run directly by users.
---

# Step 10 — Skill forge (parallel, 5 smiths)

You are executing step 10 (skill-forge) of the hyperbuild pipeline. Step 9 produced
`research/04-claude-skills/author/skill-authoring-guide.md` (authoring law for
everything written here); step 11
(epics) runs next. The five skills you forge now are loaded by every step 14
implementer and test engineer, and they are the standard the step 15 critics review the
finished app against — a vague rule here becomes an unreviewable defect there.

**Goal:** five complete, immediately-loadable project skills in `.claude/skills/`, each
using the RICH four-part anatomy (lean SKILL.md core + `references/` deep dives +
`examples/` in the target language + `scripts/*.sh` PASS/FAIL check gates), with valid
frontmatter and an anti-pattern list. The script gates are structural enforcement:
step 14 runs them after every epic and step 16's ship gate runs them all — a rule with
a check script is enforced; a rule without one is a suggestion.

**⚠ CRITICAL: `.claude/skills/` is SHARED with this pipeline's own `hyperbuild-*`
skills. Each smith writes ONLY its assigned `app-*` directory. If you find yourself (or
a smith) about to touch any `hyperbuild-*` file, STOP — that is the harness, not the
product.**

## Inputs

Read these before spawning anything:

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `steps` (confirm steps.9 = done)
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Paste into every spawn.
- `research/04-claude-skills/author/skill-authoring-guide.md` — step 9's guide; its
  "Rules for our generated skills" section is LAW for every file this step writes
- `research/02-engineering/author/stack-guide.md` — committed stack decisions (step 5)
- `research/product-spec.md` — the PRD, including the canonical screen inventory (step 4)
- `runs/<run_tag>/decisions/platform.md` — chosen platform + target language
- `research/02-engineering/research/*.md` — the per-dimension stack docs. **There is NO
  fixed filename set here.** Step 5 DERIVES 6–8 (standard) / 10–14 (premier) dimensions
  for the chosen platform and RENAMES them into the platform's own vocabulary
  (`ui-component-testing` → `widget-golden-testing`, `lints-tooling` + `ci-release` →
  `tooling-and-ci`, …), so the slugs differ per run. Read
  `research/02-engineering/_INDEX.md` (and `runs/<run_tag>/temp/dimensions-02.md` for the
  full kept/renamed/dropped/merged record) and bind each smith's inputs to the files that
  actually exist. **UNVERIFIED by construction** (`docs/RESEARCH-ARCHIVE.md` §5): before a
  generated skill states a version, API name, or lint rule as fact, check
  `research/02-engineering/verify/` — a verify file OVERRIDES the research file it
  checked, and a REFUTED claim must never become a project rule.
- `research/02-engineering/_INDEX.md` — the area map: which dimensions exist under their
  real slugs, which claims were fact-checked, and their verdicts
- `features/00-index.md` — feature index (step 4.5)

**Pre-flight gate:** if `research/04-claude-skills/author/skill-authoring-guide.md` is
missing or lacks its
"Rules for our generated skills" section, step 9 failed silently. Delete the
`steps["9"]` key from the manifest (or set it to `"running"` — `"done"` is the only
value that skips a step) and return to the router — its resume logic re-runs step 9.
Do NOT forge skills without the authoring law.

## Procedure

1. **Recover state.** Read every input above. Extract the target language (e.g. "Dart /
   Flutter", "Swift / SwiftUI", "TypeScript / React") from `decisions/platform.md` —
   every code example in every generated skill is written in it.

2. **Spawn all 5 smiths in ONE message** — five Task calls, all
   `subagent_type: hb-skill-smith`, true parallel execution. One smith per skill, zero
   scope overlap. Assignments:

   **⚠ BIND `primary inputs` BY CONCERN, NOT BY FILENAME.** Step 5's dimension slugs are
   derived per platform, so the table below names CONCERNS. Before you fill any spawn
   template: open `research/02-engineering/_INDEX.md`, list the dimension files that
   actually exist, map each concern to the real slug(s), and substitute those EXACT paths
   into that smith's prompt. If step 5 DROPPED or MERGED a concern (named with its reason
   in `_INDEX.md` and `runs/<run_tag>/temp/dimensions-02.md`), fall back to the matching
   section of `research/02-engineering/author/stack-guide.md` and say so in the prompt.
   **Never hand a smith a path that does not exist** — a READ-FIRST file that is missing
   is silently skipped, and the skill gets forged without its stack evidence.

   | skill_name | scope (paste verbatim into the spawn) | primary inputs beyond the common set — resolve the CONCERN to real slugs | extra_directives |
   |---|---|---|---|
   | `app-code-style` | Language idioms, naming, formatting, imports, error handling, and the lint/formatter rules this project commits to. Good/bad example pairs for each rule. | the LINTS/FORMATTER/TOOLING dimension + the LANGUAGE-IDIOMS dimension (typical slugs: `lints-tooling.md`, `tooling-and-ci.md`, `language-idioms.md`, `error-handling.md`) | none |
   | `app-architecture` | Layering, module boundaries, state management, dependency direction, and "where does new code go" placement rules for this project's structure. | the ARCHITECTURE dimension + the PROJECT-STRUCTURE dimension + the STATE/DI dimension (typical slugs: `architecture.md`, `architecture-and-error-handling.md`, `project-structure.md`, `structure-and-state.md`, `state-management-di.md`) | none |
   | `app-testing` | Test pyramid and framework choices, test file naming/placement, what every task MUST cover (happy path, edge cases, error states), how to run the suite, coverage expectations. | the TESTING-STRATEGY dimension + any UI/COMPONENT-TESTING dimension (typical slugs: `testing-strategy.md`, `widget-golden-testing.md`, `snapshot-testing.md`, `component-and-e2e-testing.md`) | none |
   | `app-components` | UI component construction: how screens compose from components, required UI states for every screen (empty, loading, error, offline where relevant), accessibility baseline, and how components consume design tokens. | `research/product-spec.md` screen inventory, `features/00-index.md` | Design-token directive below |
   | `app-review-checklist` | The concrete checklist hb-code-critic and the step 15 critics apply: checkable bullets covering style, architecture, testing, and UI conformance, each phrased as a yes/no question with the evidence to look for. | the same LINTS/TOOLING files bound for `app-code-style` plus the same TESTING files bound for `app-testing` | Derive ONLY from the shared ground truth (stack docs, PRD, authoring guide) — your four sibling skills do not exist yet; the orchestrator reconciles overlap after all five land. |

   **Design-token directive (app-components only, paste verbatim as extra_directives):**
   "No design has been chosen yet — that happens at the step 12 checkpoint. Do NOT
   invent token values. Reference tokens by semantic role (e.g. primary color, base
   spacing unit) and include an H2 exactly `## Design tokens (wired by step 13)` whose
   body states: the chosen design's `tokens.css` + `design-system.md` land in
   `app/design/` at the checkpoint, and step 13 replaces/extends this section with
   concrete theme-file references for the target framework. That body is real,
   binding instruction — not a placeholder."

   **Spawn template** (fill `<>` placeholders from the table above):

   ```
   subagent_type: hb-skill-smith
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the full body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 10 (skill-forge) of the hyperbuild
     pipeline. Step 9 produced
     research/04-claude-skills/author/skill-authoring-guide.md — its
     "Rules for our generated skills" section is LAW for the file you
     write. Four sibling smiths are writing the other four project skills
     in parallel; you write ONLY yours. Your skill is loaded by every
     step 14 implementer and test engineer, and it is the standard the
     step 15 critics review the app against. Step 13 later wires concrete
     design-token references into app-components only.

     YOUR INPUTS:
     - skill_name: <skill_name from the table>
     - output_dir: .claude/skills/<skill_name>/   (you own this whole
       directory: SKILL.md + references/ + examples/ + scripts/)
     - scope: <the scope cell from the table, verbatim>
     - target_language: <target language/framework from decisions/platform.md>
     - extra_directives: <the extra_directives cell, or "none">

     CONTEXT FILES (read ALL of these FIRST, in this order):
     - research/04-claude-skills/author/skill-authoring-guide.md
       (authoring law — read the Rules section twice, and the Adaptable
       skills shortlist)
     - research/02-engineering/author/stack-guide.md (committed stack
       decisions — your rules must agree, never contradict)
     - research/product-spec.md            (the PRD — personas, MoSCoW features, screen inventory)
     - runs/<run_tag>/decisions/platform.md
     - <primary inputs: the REAL dimension-file paths you resolved from
       research/02-engineering/_INDEX.md for this smith's concern, each
       listed explicitly — or, for a concern step 5 dropped/merged, the
       named section of research/02-engineering/author/stack-guide.md
       that covers it instead>
     - research/02-engineering/verify/*.md — BEFORE you turn any version,
       API name, lint rule, or package claim from a research/ file into a
       project rule, check whether a fact-checker already ruled on it. A
       verify file OVERRIDES the research file it checked
       (docs/RESEARCH-ARCHIVE.md §7): never encode a REFUTED claim as a
       rule; carry the correction with a PARTIALLY_TRUE one.
     - research/harvest/ clones the shortlist points you at (step 9
       harvested them; for Flutter, zakariaf/Flutter-Skills is primary)

     ADAPT, don't author from zero: when a shortlisted harvested skill
     covers your scope, keep its structure and rewrite specifics for
     this app — attribute it (repo + license) in SKILL.md; licenses
     other than MIT/Apache/BSD/CC may be learned from and cited, never
     copied. Write from zero only for gaps.

     Write the FOUR-PART skill into output_dir:
     - SKILL.md (~100-250 lines, the always-loaded core). Frontmatter:
       name (== skill_name exactly) and description only; the
       description starts "Use when ..." and names the concrete
       files/actions that should trigger it. Body: a one-paragraph scope
       statement; the numbered non-negotiable rules — every rule ships
       as rule + compliant example + violating example in
       <target_language> (long example sets live in examples/, referenced
       by path); one pointer line per reference file ("read
       references/X.md when ..."); a `## Anti-patterns` section (named
       anti-pattern, why it fails, what to do instead); a
       definition-of-done checklist; a `## When in doubt` closer pointing
       at research/02-engineering/author/stack-guide.md and
       research/product-spec.md.
     - references/*.md — deep dives read on demand, one topic per file,
       60-200 lines each (e.g. the full lint-rule table, the layer map).
     - examples/* — real, compilable code in <target_language> using
       this app's real domain names. Not pseudocode.
     - scripts/*.sh — mechanical PASS/FAIL gates: every rule of yours
       that CAN be checked mechanically gets a line in a gate
       (grep/analyzer based, exit non-zero on hard failure, no
       app-hardcoded paths — resolve app/ relative to the repo root).
       Run each script once via Bash to prove it executes. Step 14 runs
       these per epic; step 16 runs them all as a hard ship check.
     Omit examples/ or scripts/ ONLY when they would be padding for your
     scope (plausible for app-review-checklist alone); any skill with
     code rules gets all four parts. Rules must be project-specific
     commitments ("we do X"), not generic language advice — every rule
     traceable to stack-guide or the PRD.

     Do NOT write outside output_dir. Do NOT touch any hyperbuild-*
     skill or any sibling app-* skill. Do NOT restate stack-guide
     wholesale — cite it. No TBD/TODO/placeholder text.

     Report back: files written (SKILL.md line count; reference,
     example, script counts), rule count, harvested skills adapted
     (repo + license), anti-pattern count. Data, not prose.
   ```

3. **Never emit bare text while the smiths are in flight.** Append validation notes and
   overlap suspicions to `runs/<run_tag>/temp/orchestrator-notes.md` while waiting.

4. **Validate every skill** once all five return. Mechanical checklist per skill:

   - `.claude/skills/<skill_name>/SKILL.md` exists; frontmatter parses; `name` ==
     directory name exactly; description present and starts "Use when"
   - SKILL.md is ~100–250 lines (lean core — depth belongs in references/); ≥ 5
     numbered rules; a `## Anti-patterns` H2 with ≥ 3 entries; a definition-of-done
     checklist; one pointer line per reference file
   - Four-part anatomy present: ≥ 1 `references/*.md` (60–200 lines each); code in
     the target language (≥ 3 fenced blocks in SKILL.md and/or files under
     `examples/`); ≥ 1 `scripts/*.sh` that runs (`bash <script>`; exits 0 or a
     clean documented failure) — for any skill with code rules. A missing part is a
     defect unless the smith's report justifies it as padding for this scope
   - `scripts/*.sh` contain no app-hardcoded absolute paths
   - Zero hits for `grep -riE 'TBD|TODO|FIXME|lorem'` across the skill dir
   - Every repo path cited in the body exists
   - Adapted harvested material is attributed (repo + license) and the license is
     MIT/Apache/BSD/CC
   - `app-components` only: the H2 `## Design tokens (wired by step 13)` present
     verbatim — step 13 keys off that exact heading
   - No `hyperbuild-*` file was modified (check `git status` / mtimes if available)

5. **Coherence pass on app-review-checklist.** Read the other four finished skills and
   verify every checklist item maps to a rule that actually exists in one of them (or in
   stack-guide directly). Add missing items and delete orphans yourself via Edit —
   surgical hunks, not a rewrite.

6. **Fix rounds.** For any skill failing checklist items: re-spawn its smith ONCE with
   the failing items pasted as explicit findings. Still failing → fix the remaining
   items yourself via Edit (Stage A permits orchestrator authorship; keep the edits
   surgical). Never delete and regenerate a whole skill for a checklist miss.

## Artifacts

Five skill directories, each in the four-part anatomy (`SKILL.md` +
`references/*.md` + `examples/*` + `scripts/*.sh`, with the omission carve-out for
padding-only parts):

- `.claude/skills/app-code-style/`
- `.claude/skills/app-architecture/`
- `.claude/skills/app-testing/`
- `.claude/skills/app-components/` — SKILL.md contains the verbatim H2
  `## Design tokens (wired by step 13)`
- `.claude/skills/app-review-checklist/`

Each SKILL.md: YAML frontmatter with `name` (== directory) and `description`
("Use when ...") only; body per the spawn template's section order; all code examples
in the target language from `decisions/platform.md`.

## Exit criteria

- All five skill directories exist at the exact paths above and pass every item of the
  Procedure-4 checklist (four-part anatomy included)
- Every `scripts/*.sh` executed at least once this step without a crash
- `app-components` carries the `## Design tokens (wired by step 13)` heading verbatim
- The coherence pass ran: every app-review-checklist item maps to a real rule
- No `hyperbuild-*` skill was created, modified, or deleted

Then update the manifest: `steps.10 = done`, mark the step-10 todo complete, and return
to the router, which invokes `Skill(skill: "hyperbuild-11-epics")`.
