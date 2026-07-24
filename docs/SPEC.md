# hyperbuild — Master Build Spec

This spec defines a Claude Code multi-skill pipeline harness called **hyperbuild**, modeled
directly on [hyperresearch](https://github.com/jordan-gibbs/hyperresearch).
It turns one prompt — an app idea — into a fully researched, designed, planned, and
implemented application, with exactly ONE human checkpoint (picking a design).

Target directory for ALL output files: the repository root.

## The product promise (the user's own words)

Two steps only:
1. User: `/hyperbuild <my app idea>` → hours later: deep research done (competitors,
   social sentiment, platform best practices), 3 complete design systems with HTML
   mockups of every screen, project-specific Claude Code skills generated, epics/tasks
   written — pipeline STOPS waiting for a design choice.
2. User: `/hyperbuild-choose <a|b|c>` → the harness implements the entire app from the
   epics and tasks. At the end: a working app.

## Architecture principles (inherited from hyperresearch — cite these in PIPELINE.md)

1. **Router + step skills.** The entry skill `hyperbuild` is a thin ROUTER: bootstrap,
   sequence, recover. It never does step work. Each pipeline step is its own skill,
   invoked via `Skill(skill: "hyperbuild-N-name")`, loaded fresh into context at the
   moment it's needed. (hyperresearch's V8 lesson: one 1200-line skill gets compacted
   away mid-run; per-step skills survive context rot.)
2. **Canonical idea is gospel.** The verbatim user idea is persisted once to
   `runs/<run_tag>/idea.md` and re-read by every step and every subagent. Never
   paraphrased.
3. **Durable state on disk.** Every step writes canonical artifacts to known paths.
   `runs/<run_tag>/manifest.json` records step transitions. A crashed run resumes at
   the exact step where it died via artifact scan + manifest.
4. **Subagent spawn contract.** Every Task prompt includes: (1) the verbatim idea,
   block-quoted; (2) a pipeline-position statement ("You are step N... step N-1 produced
   X... step N+1 will consume Y"); (3) the subagent's specific inputs and exact output
   path; (4) the list of context files it must read first.
5. **Parallel within a step, sequential across steps.** Steps never overlap; inside a
   step, spawning subagents in parallel is mandatory when there are multiple.
6. **Adversarial by construction.** Drafts/plans/code are attacked by critics; fixes are
   applied as surgical edits by a tool-locked patcher (Read+Edit only) — patch, never
   regenerate.
7. **Hard gates.** A stage is complete only when its gate's checklist passes. Gate
   failures are fixed by changing the artifacts, never by re-interpreting the checks.
   Max 3 fix rounds, then the run stays blocked and says so honestly.
8. **Never emit bare text while subagent tasks are in flight** (headless-mode survival
   rule — a text-only response ends the turn and kills the pipeline). While waiting,
   append thoughts to `runs/<run_tag>/temp/orchestrator-notes.md`.
9. **Git is the safety net.** The generated app lives in a git repo from the moment
   step 13 scaffolds it (git init + platform .gitignore + initial commit once the empty
   app builds). Step 14 commits after EVERY wave (message: `wave <N>: <task ids> — <one
   line>`) and after each epic's critic+patcher pass; step 15 commits after its patch
   pass. Rollback is `git revert`, the epic critics review real diffs, and the audit
   trail runs task → commit. The ship gate requires a clean working tree.

## Repository layout to create

```
hyperbuild/
├── README.md            # banner-style: what it is, install-free quickstart, pipeline table, agent roster
├── CLAUDE.md            # project memory: "this repo is the hyperbuild harness", entry points, layout
├── PIPELINE.md          # deep architecture doc: the 16 steps, the principles, hyperresearch lineage
├── .claude/
│   ├── skills/
│   │   ├── hyperbuild/SKILL.md               # ROUTER (entry)
│   │   ├── hyperbuild-choose/SKILL.md        # human checkpoint #2 (records choice, resumes router)
│   │   ├── hyperbuild-1-intake/SKILL.md
│   │   ├── hyperbuild-2-market-recon/SKILL.md
│   │   ├── hyperbuild-3-social-mining/SKILL.md
│   │   ├── hyperbuild-3-5-research-audit/SKILL.md
│   │   ├── hyperbuild-4-product-spec/SKILL.md
│   │   ├── hyperbuild-4-5-feature-specs/SKILL.md
│   │   ├── hyperbuild-5-stack-research/SKILL.md
│   │   ├── hyperbuild-6-design-research/SKILL.md
│   │   ├── hyperbuild-7-design-systems/SKILL.md
│   │   ├── hyperbuild-8-mockups/SKILL.md
│   │   ├── hyperbuild-9-skill-research/SKILL.md
│   │   ├── hyperbuild-10-skill-forge/SKILL.md
│   │   ├── hyperbuild-11-epics/SKILL.md
│   │   ├── hyperbuild-12-design-gate/SKILL.md
│   │   ├── hyperbuild-13-scaffold/SKILL.md
│   │   ├── hyperbuild-14-implement/SKILL.md
│   │   ├── hyperbuild-15-adversarial-review/SKILL.md
│   │   └── hyperbuild-16-ship-gate/SKILL.md
│   └── agents/
│       └── (19 agent files, listed below)
├── runs/README.md       # explains run workspaces (dir created at runtime)
├── research/README.md   # explains the research vault (content created by steps 2-9)
├── features/README.md   # explains the feature-spec format (content created by step 4.5)
└── epics/README.md      # explains epic/task format (content created by step 11)
```

At runtime (NOT created now, but documented everywhere):

```
runs/<run_tag>/
├── idea.md                    # GOSPEL: verbatim user idea + frontmatter (run_tag, created, platform)
├── manifest.json              # {run_tag, stage, platform, steps:{"1":"done",...}, design_choice, blocked_on}
├── scaffold.md                # orchestrator's private planning doc (never ships)
├── temp/orchestrator-notes.md
├── designs/
│   ├── index.html             # gallery comparing all three (step 8)
│   └── {a,b,c}/
│       ├── design-system.md   # full system: principles, type scale, color, spacing, components
│       ├── tokens.css         # CSS custom properties
│       ├── mockups/<screen>.html      # one self-contained HTML per mockable screen
│       └── screenshots/<screen>.png   # headless-Chrome renders of every mockup (step 8)
├── decisions/
│   ├── platform.md            # chosen stack + rationale (step 1)
│   └── design-choice.md       # written by /hyperbuild-choose
└── gates/
    ├── design-gate-report.md  # step 12
    └── ship-report.md         # step 16
```

**The research vault — top-level `research/`, NOT inside runs/.** All research artifacts
are first-class, human-readable deliverables that persist at the repo root (mirroring
hyperresearch's root-level vault: markdown is truth, readable without any tooling, and
later runs reuse it before re-fetching):

```
research/
├── competitors/<slug>.md      # one dossier per competitor (step 2)
├── competitor-landscape.md    # feature matrix + positioning map (step 2)
├── sentiment/<platform>.md    # reddit.md, hn-forums.md, appstore-reviews.md, linkedin-x.md (step 3)
├── sentiment-synthesis.md     # ranked pain points + wish lists (step 3)
├── research-audit.md          # adversarial audit findings + resolutions (step 3.5)
├── product-spec.md            # the PRD, incl. the canonical screen inventory (step 4)
├── stack/<topic>.md           # architecture.md, structure.md, testing.md, tooling-ci.md (step 5)
├── stack-guide.md             # merged committed best-practices guide (step 5)
├── design/<direction-slug>.md # one research doc per design direction (step 6)
├── skill-authoring-guide.md   # Claude Code skill-authoring research (step 9)
└── harvest/                   # shallow-cloned GitHub repos + harvest-log.md (disposable cache;
    └── harvest-log.md         #   the distilled artifacts above are truth, this is provenance)
```

Every step that formerly wrote research under the run workspace writes here instead; the
run's manifest still tracks step completion, and each research file's frontmatter carries
`run_tag` + `created` so provenance survives multi-run vaults.

And at repo root, produced by the pipeline: `research/` (steps 2–9), `features/`
(step 4.5), `epics/` (step 11), and `app/` (steps 13–16). One harness checkout = one app.
(A second idea → clone the harness to a new folder.)

## Feature specs (step 4.5) — the features/ contract

One md file per feature, at repo root: `features/NN-<slug>.md` (NN = two-digit priority
order). Every PRD must/should feature gets a file (cap 15 standard / 25 premier; could
features get files only if the cap allows). Frontmatter:
```
---
id: F-NN
name: <feature name>
moscow: must | should | could
status: specced          # specced → designed → implemented (steps 8/14 flip it)
screens: [<screen names from the PRD screen inventory>]
---
```
Body sections (ALL required): Overview (what + why, in plain language); User stories
(as-a/I-want/so-that, ≥2); UX flow (step-by-step primary flow + alternate flows);
States & edge cases (empty, loading, error, offline, permission-denied where relevant);
Data touchpoints (entities read/written); Acceptance criteria (checkable bullets);
Evidence (links into research/: competitor dossiers that have this feature,
verbatim sentiment quotes demanding it); Open questions.
`features/00-index.md` lists every feature: id, name, moscow, screens, one-liner.
DOWNSTREAM CONTRACT: steps 6–8 (design/mockups) read feature specs for real content and
flows; step 11 tasks MUST cite the feature ids they implement (`features: [F-03]` in task
frontmatter); the step 12 gate checks every must/should feature file exists and is
covered by ≥1 task; step 14 implementers read the feature file as primary spec alongside
the task file.

## The 16-step pipeline (two stages)

### STAGE A — PLAN (autonomous, `/hyperbuild <idea>`)

| # | Skill | What it does | Spawns (parallel) |
|---|-------|--------------|-------------------|
| 1 | hyperbuild-1-intake | Verbatim idea → `idea.md`; mint run_tag (slug + 6 random hex chars, e.g. `habit-coach-3f9a2c`); resolve platform (stated > inferred; record rationale in `decisions/platform.md`); write scaffold.md; init manifest.json; seed TodoWrite with all 16 steps | — |
| 2 | hyperbuild-2-market-recon | Competitor discovery → latest versions, feature sets, changelogs, pricing → per-competitor dossiers + `competitor-landscape.md` with feature matrix | 1 hb-competitor-scout, then 6–10 hb-competitor-analyst (one per competitor) |
| 3 | hyperbuild-3-social-mining | What real users say: Reddit, HN, app-store reviews, LinkedIn/X, forums → pain points, wish lists, praised features, ranked by frequency × intensity → `sentiment-synthesis.md` | 4 hb-sentiment-miner (one per platform group) |
| 3.5 | hyperbuild-3-5-research-audit | ADVERSARIAL RESEARCH AUDIT (runs after 2 AND 3 both complete): 1 hb-research-critic attacks `competitor-landscape.md` + `sentiment-synthesis.md` — tries to REFUTE the top pain points and wish-list items (cherry-picked? one viral thread reposted five times? syndication is not consensus — cluster derivative copies, they argue with the weight of ONE source), spot-checks version/feature claims against live sources, flags anything unsupported → `research/research-audit.md`; orchestrator patches the synthesis docs per confirmed findings (claims downgraded/annotated, never silently deleted) | 1 hb-research-critic |
| 4 | hyperbuild-4-product-spec | Merge steps 2+3 (as audited by 3.5) → the PRD: personas, feature list (MoSCoW: must/should/could/won't for v1), differentiators, every feature traced to competitor evidence or user demand, full screen inventory (canonical list of app screens with names — steps 8, 11, 14 all key off this list; each screen classified `mockup_feasibility: full \| partial \| none` — `full` = standard UI, fully mockable in HTML; `partial` = engine/camera/map/canvas content with mockable chrome (HUD, overlays, menus) around a placeholder viewport; `none` = pure engine-rendered, not mockable — with a one-line note of what IS mockable for partial screens) | 1 hb-spec-critic reviews the draft PRD; orchestrator patches |
| 4.5 | hyperbuild-4-5-feature-specs | Expand every must/should PRD feature into a complete spec file at repo root: `features/NN-<slug>.md` per the features contract (overview, user stories, UX flows, states & edge cases, data touchpoints, acceptance criteria, evidence links into research/, open questions) + `features/00-index.md`. Cap 15 std / 25 premier. Downstream: design + mockups draw real flows/content from these; every task cites feature ids; gates check feature coverage | 3–5 hb-feature-author (features split into batches) |
| 5 | hyperbuild-5-stack-research | HARVEST-FIRST (official style guides + high-star best-practices repos per topic), then gap-fill research: app architecture, project structure, state management, testing strategy, tooling/CI/lint → 4 topic docs + merged `stack-guide.md` with "we will do X" decisions (not surveys) — including a committed architecture choice appropriate to the platform and app, decided by the research itself | 4 hb-stack-researcher (one per topic) |
| 6 | hyperbuild-6-design-research | Propose exactly 3 named design directions suited to this app + audience (reading product-spec.md + the feature specs) (e.g. "Soft Focus", "Swiss Utility", "Neon Playful"); per direction: HARVEST-FIRST (public design-system repos, open token sets, HIG/Material resources), then deep research: typography, color theory, motion, component patterns | 3 hb-design-researcher (one per direction) |
| 7 | hyperbuild-7-design-systems | Build the 3 full design systems: `design-system.md` + `tokens.css` per direction — type scale, color palette (light+dark), spacing, radii, elevation, component specs (buttons, cards, inputs, nav, lists, empty states). tokens.css uses the three-layer token structure (primitive → semantic → component) unless the direction's research argues otherwise | 3 hb-design-system-author (one per direction) |
| 8 | hyperbuild-8-mockups | For every `full`/`partial` screen in the PRD inventory × each of 3 designs: a self-contained HTML mockup (inline CSS from tokens, REAL content and flows from the PRD + the relevant `features/*.md` specs — never lorem ipsum, phone-frame wrapper for mobile; `partial` screens: real HUD/chrome/overlays over a clearly-marked placeholder viewport; `none` screens: no mockup — instead an art-direction card in that design's design-system.md (mood, palette applied, HUD typography, reference language)). THEN the orchestrator renders `screenshots/<screen>.png` for every mockup via headless Chrome (`chrome --headless=new --screenshot=<out> --window-size=390,844 file://<mockup>` — desktop apps use a desktop viewport; if Chrome is missing, log a warning in the manifest and continue — screenshots become a design-gate warning, not a hard fail). Finally `designs/index.html` gallery (side-by-side iframes per screen, design names, jump nav) | 3–6 hb-mockup-smith (screens split per design) |
| 9 | hyperbuild-9-skill-research | HARVEST-FIRST (clone `zakariaf/Flutter-Skills` — the canonical anatomy exemplar — plus `anthropics/skills` + top community collections), then research Claude Code skill authoring: SKILL.md format, frontmatter, progressive disclosure (SKILL.md core + references/ + examples/ + scripts/ check gates), richness norms → `skill-authoring-guide.md` incl. a shortlist of harvested skills adaptable in step 10 (with licenses) | 1–2 hb-stack-researcher spawns |
| 10 | hyperbuild-10-skill-forge | Generate PROJECT-SPECIFIC skills into `.claude/skills/` from stack-guide + PRD: `app-code-style`, `app-architecture`, `app-testing`, `app-components` (wires chosen design tokens later), `app-review-checklist`. Each uses the RICH four-part anatomy (SKILL.md core + references/ + examples/ in the target language + scripts/ PASS-FAIL gates — see "Two kinds of skills"). ADAPT harvested skills from step 9's shortlist where they fit (license-checked, attributed; for Flutter apps, zakariaf/Flutter-Skills is the primary source); write from zero only for gaps | 5 hb-skill-smith (one per skill) |
| 11 | hyperbuild-11-epics | The full backlog: `epics/00-overview.md` (epic list, dependency order, PRD coverage matrix) + one dir per epic: `epics/NN-<slug>/epic.md` (goal, scope, out-of-scope, depends_on, acceptance criteria) + one `NN-<slug>/task-NN-<slug>.md` per task (frontmatter: id, epic, status: todo, depends_on, size; body: context, spec, files to touch, testing requirements, definition of done; frontmatter also carries `features: [F-NN]` — the feature ids the task implements — and `files: [<planned paths>]` — the machine-readable list of files the task will create/modify, which step 14's wave scheduler uses to run only non-overlapping tasks in parallel). Every feature file (and thus every must/should PRD feature) maps to ≥1 task | 1 hb-epic-planner (breakdown), then 3–6 hb-task-author (one per epic batch), then hb-spec-critic coverage audit |
| 12 | hyperbuild-12-design-gate | Verify EVERY Stage-A artifact exists + every must/should feature has a spec file covered by ≥1 task + PRD↔features↔epics coverage complete + all 3 designs have all screens → `gates/design-gate-report.md`; then STOP: message the user a summary (competitor count, top pain points, platform decision, epic/task counts) + how to open `designs/index.html` + "run `/hyperbuild-choose a|b|c`". This is the ONE permitted stop | 1 hb-gate-verifier |

### CHECKPOINT — `/hyperbuild-choose <a|b|c>`

Thin skill: validates a run exists at the design gate; writes `decisions/design-choice.md`;
copies chosen `tokens.css` + design-system.md to `app/design/` (path recorded); updates
manifest (`design_choice`, stage=BUILD); optional second arg overrides platform (then
re-run steps 5, 10, 11 before building — document this); finally invokes
`Skill(skill: "hyperbuild")` — the router's resume logic takes over and drives Stage B.

### STAGE B — BUILD (autonomous)

| # | Skill | What it does | Spawns |
|---|-------|--------------|--------|
| 13 | hyperbuild-13-scaffold | Init the real project in `app/` per stack-guide (flutter create / Xcode project / npm scaffold...); `git init` in app/ + platform .gitignore + INITIAL COMMIT once the empty app builds and its smoke test passes; wire lint + formatter + test harness + CI config; implement the design tokens in the target framework (e.g. `theme.dart` / `Theme.swift` from tokens.css); commit-ready structure; update `app-components` skill with concrete theme references | orchestrator + 1 hb-implementer |
| 14 | hyperbuild-14-implement | WAVE-BASED PARALLEL implementation over the task DAG (not epic-sequential). Loop: (1) READY SET = every task across ALL epics whose `depends_on` tasks are done and whose epic's `depends_on` epics are done; (2) WAVE = a subset of the ready set with PAIRWISE-DISJOINT `files:` lists (conflicting tasks defer to a later wave), capped at the parallel-implementers knob; (3) spawn implementer+test-engineer pairs for the whole wave IN PARALLEL; (4) SYNC POINT: full test suite + all generated-skill script gates green before the next wave — never start a wave on red — then COMMIT the wave (`wave <N>: <task ids> — <summary>`); (5) when an epic's last task completes, run that epic's hb-code-critic (reviewing the epic's REAL git diff) + hb-patcher pass as before, then commit. Assembly tasks come late automatically (they depend on their parts). Per-task mechanics below unchanged: mark task in-progress → spawn hb-implementer (reads: idea, PRD section, feature specs, task file, generated skills, chosen design's mockup HTML + screenshots/<screen>.png for its screens) → spawn hb-test-engineer (writes/extends tests, runs them, fixes failures; for UI tasks ALSO writes visual/golden-snapshot tests per stack-guide where the platform supports them — Flutter golden tests, iOS snapshot tests, RN/web screenshot tests — with the chosen design's mockup + screenshot as the visual spec) → task status: done (frontmatter edit). After each epic: run full test suite AND every generated skill's scripts/*.sh gate; spawn hb-code-critic on the epic's diff; findings → hb-patcher (Read+Edit locked). Never start epic N+1 with epic N's tests or skill gates red | hb-implementer, hb-test-engineer per task; hb-code-critic + hb-patcher per epic |
| 15 | hyperbuild-15-adversarial-review | Whole-app adversarial pass, 3 critics in parallel: hb-code-critic (quality/security/idioms vs stack-guide), hb-spec-critic (every must/should feature actually present & wired), hb-ux-critic (SCREENSHOT COMPARISON: captures the implemented app's screens via platform tooling — golden-test outputs, simulator/emulator screenshots, or running the app — and compares them side-by-side against the chosen design's `screenshots/<screen>.png`; judges layout, tokens, spacing, typography, and states fidelity, NOT pixel-identity — rendering engines differ; only `full`/`partial` screens are judged, and `partial` only on their mocked chrome/HUD). Findings JSONs → ranked → hb-patcher applies surgical fixes; structural findings become new tasks (max 1 loop back through step 14 for them); commit after the patch pass | 3 critics parallel, then hb-patcher |
| 16 | hyperbuild-16-ship-gate | THE gate: full test suite green; lint/analyzer clean; ALL generated-skill scripts/*.sh gates pass; every task status=done; every epic's acceptance criteria checked; PRD coverage matrix complete; TRACEABILITY CHAIN walked mechanically — every must/should feature F-NN → its `features/NN-*.md` exists → ≥1 task with `features: [F-NN]` all status done → every file in those tasks' `files:` lists exists in app/ → the tests those tasks added pass — a break ANYWHERE in the chain blocks the ship; git working tree clean with wave/epic commit history present; app builds/runs (platform-appropriate build cmd) → `gates/ship-report.md`. Failures: fix artifacts, re-run gate, max 3 rounds, else blocked + honest report. Final message: what was built, how to run it, test count, known gaps | 1 hb-gate-verifier |

## Router (`hyperbuild/SKILL.md`) requirements

Mirror hyperresearch's router structure (READ IT: `src/hyperresearch/skills/hyperresearch.md`):
- frontmatter: name + description ("turns one app idea into a researched, designed,
  planned, implemented app via a 16-step two-stage pipeline; this skill is a ROUTER...")
- "How the chain works" section w/ Skill() invocation mechanics + why (context rot)
- The two-stage step table
- Bootstrap procedure (mint run_tag; idea.md; manifest; scaffold; TodoWrite seeding; then Skill 1)
- Resume/recovery: manifest first, TodoWrite second, artifact table third (list every
  step's canonical artifact path); "if design_choice exists and stage=BUILD → continue at
  first unfinished build step"
- Scale profile section (the knobs table — see below)
- **Concurrent step pairs (the ONLY exceptions to sequential steps):** steps 2 ∥ 3
  (market recon and social mining share no inputs) and steps 8 ∥ 9 (mockups and skill
  research share no inputs) run CONCURRENTLY — the orchestrator drives both step skills'
  spawn waves in the same block, tracks both in the manifest independently, and proceeds
  only when BOTH exit criteria are met (3.5 needs 2 and 3; 10 needs 9; 11 needs 8's
  gallery only at gate time). Recovery rule: on resume, an unfinished member of a pair
  re-runs alone. No other steps may overlap — recovery complexity is why.
- The canonical rules (numbered, ALL-CAPS lead-ins like hyperresearch):
  bare-text rule, idea-is-gospel, spawn contract, sequential-steps/parallel-within
  (except the two named concurrent pairs), patch-never-regenerate (Stage B),
  the-gate-is-final, ONE-stop-only (design gate), git-is-the-safety-net (Stage B)
- Subagent spawn contract section
- "Now begin" closer

## Scale profile ("weights") — put this table in the router; steps cite their numbers

| Knob | standard | premier |
|------|----------|---------|
| Competitors analyzed | 6–8 | 12–15 |
| Sources per competitor dossier | 5–8 | 10–15 |
| Sentiment posts mined per platform | 25–40 | 60–100 |
| Stack research sources per topic | 8–12 | 15–25 |
| Design research sources per direction | 6–10 | 12–18 |
| Mockup screens | every PRD screen (cap 12) | every PRD screen (cap 20) |
| Feature spec files | every must/should (cap 15) | every must/should (cap 25) |
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Parallel implementers per wave (step 14) | 3–5 | 6–10 |
| Critic fix rounds (gates) | ≤3 | ≤3 |

Default gear: `standard`. The user opts into premier by saying "premier" in the idea
prompt; step 1 records `gear` in manifest; steps read it.

## Agent roster — `.claude/agents/hb-*.md` (19 files)

Frontmatter format (Claude Code agents):
```
---
name: hb-competitor-scout
description: <when the orchestrator should spawn it — third person, specific>
tools: <comma-separated allowlist — ONLY what the role needs>
model: sonnet | opus | inherit
---
<system prompt: role, exact inputs it will receive, procedure, output contract
(exact file format/path conventions), quality bar, what it must never do>
```

| Agent | Model | Tools | Role |
|-------|-------|-------|------|
| hb-competitor-scout | sonnet | WebSearch, WebFetch, Read, Write | Discover the competitor set + latest versions; output ranked list w/ URLs |
| hb-competitor-analyst | sonnet | WebSearch, WebFetch, Read, Write | Deep dossier on ONE competitor: current version, feature list, changelog/release cadence, pricing, positioning, store ratings |
| hb-sentiment-miner | sonnet | WebSearch, WebFetch, Read, Write | Mine ONE platform group (reddit / HN+forums / app-store reviews / LinkedIn+X) for real user opinions; verbatim quotes + URLs; frequency×intensity ranking |
| hb-stack-researcher | sonnet | WebSearch, WebFetch, Read, Write, Bash | Best practices for ONE topic (architecture/structure/testing/tooling) on the chosen stack; HARVEST-FIRST (GitHub repos, then gap-fill); ends with committed "we will do X" decisions |
| hb-research-critic | opus | Read, Grep, Glob, WebSearch, WebFetch | Adversarial audit of the research corpus: refute top pain points/wish-list items, cluster syndicated/derivative copies (they count as ONE source), live spot-check version/feature claims; findings to research/research-audit.md; NEVER edits the synthesis docs itself |
| hb-feature-author | sonnet | Read, Write, Grep, Glob | Write complete feature-spec files for a BATCH of PRD features per the features/ contract; every claim evidenced from research/; no invented requirements |
| hb-design-researcher | sonnet | WebSearch, WebFetch, Read, Write, Bash | Deep research ONE design direction: reference systems, typography, color, motion, accessibility; HARVEST-FIRST (public design-system repos/token sets, then gap-fill) |
| hb-design-system-author | opus | Read, Write | Author ONE complete design system (design-system.md + tokens.css) from its research doc |
| hb-mockup-smith | sonnet | Read, Write | Build self-contained HTML mockups for assigned screens in ONE design; real PRD content; tokens.css inlined |
| hb-skill-smith | opus | Read, Write, WebSearch, WebFetch, Bash | Write ONE generated Claude Code skill per the skill-authoring-guide; adapts a harvested existing skill when one fits (license-checked), writes from zero only for gaps |
| hb-epic-planner | opus | Read, Write | PRD → epic breakdown w/ dependency order + coverage matrix |
| hb-task-author | sonnet | Read, Write | Write full task files for ONE epic (spec, files, testing, DoD) |
| hb-implementer | inherit | (omit tools field = all tools) | Implement ONE task end-to-end per the generated skills + mockups |
| hb-test-engineer | inherit | (omit = all tools) | Write/extend tests for ONE task; run them; fix until green |
| hb-code-critic | opus | Read, Grep, Glob, Bash | Adversarial code review vs stack-guide + generated skills; findings JSON; NEVER edits |
| hb-spec-critic | opus | Read, Grep, Glob | PRD coverage audit (of epics in Stage A; of the app in Stage B); findings JSON; NEVER edits |
| hb-ux-critic | opus | Read, Grep, Glob, Bash | Mockup-fidelity audit: captures implemented-app screenshots (platform tooling) and compares against the chosen design's mockup screenshots (Read renders images); layout/token/spacing/state fidelity, not pixel-identity; findings JSON |
| hb-patcher | opus | Read, Edit, Grep, Glob | TOOL-LOCKED surgical patcher: applies critic findings as small Edit hunks; per-hunk cap; escalates structural findings; physically cannot Write files |
| hb-gate-verifier | sonnet | Read, Grep, Glob, Bash | Runs a gate checklist mechanically; emits pass/fail JSON w/ per-check evidence; never fixes anything |

## Step-skill authoring conventions (every hyperbuild-N file)

- Frontmatter: `name`, `description` starting "Step N of the hyperbuild pipeline — ...
  Invoked by the hyperbuild router via Skill(); not run directly by users."
- Opening line: "You are executing step N (<name>) of the hyperbuild pipeline." + one
  sentence of position (what came before / what comes after).
- `## Inputs` — exact file paths it reads (+ manifest fields).
- `## Procedure` — numbered, imperative, concrete. Include verbatim Task-spawn prompt
  templates (like hyperresearch's spawn templates) with placeholder fields, honoring the
  spawn contract. State the standard/premier numbers inline where relevant.
- `## Artifacts` — exact output paths + format (frontmatter fields for md artifacts).
- `## Exit criteria` — checkable bullets; "then update manifest: steps.N=done, mark the
  step-N todo complete, return to the router."
- Research steps: require a `## Sources` section (URL + access date + one-line takeaway)
  in every research artifact; require at least one adversarial search per topic
  ("X criticism", "X problems", "why I stopped using X").
- Research recency rule: prioritize sources from the last 18 months; version/feature
  claims must cite a dated source.
- Length target 120–300 lines each. Match hyperresearch's register: direct, imperative,
  occasionally ALL-CAPS for load-bearing rules.

## Implementation granularity (binding for steps 5, 11, 14)

The app is built in SMALL, WELL-CATEGORIZED pieces — small parts are easier to test,
easier to review, and easier to implement with focus. Three binding rules:

1. **The stack-guide names a code taxonomy** (step 5). Whatever architecture the research
   commits to, the stack-guide MUST define the project's named code categories and
   placement rules — the platform's analogue of Rails' models / views / controllers /
   concerns / services / apis: what kinds of code exist in this project, where each kind
   lives, and a one-second answer to "where does this belong?". The categories come from
   the research (they differ per platform and architecture); HAVING named categories is
   non-negotiable.
2. **Tasks are small and one-kind** (step 11). One component / model / service / screen
   section per task where feasible. A task an implementer can't finish with full focus in
   one sitting gets split. UI screens decompose into SMALL composable subcomponents
   (each a task or an explicit checklist item within one), then a final assembly task
   composes the screen from already-tested parts — many small renders combined into a
   bigger one.
3. **Implement and test part-by-part** (step 14). Each small piece gets its own tests
   green BEFORE it's composed into anything larger; composition tasks integrate
   previously-tested parts and add integration/visual tests on top. The implementer
   never builds a whole screen in one shot when the task list decomposed it.
4. **Parallelize across the task DAG, not the epic order** (step 14). Small tasks with
   explicit `depends_on` + `files:` make wave-based parallelism safe: any ready tasks
   from ANY epic run concurrently as long as their file lists are pairwise-disjoint,
   capped by the parallel-implementers knob. TRUST GUARDRAILS (non-negotiable): disjoint
   files within a wave; a full-suite + skill-gates sync point between waves (never start
   a wave on red); epic-completion critic passes unchanged; contracts/foundation tasks
   first via the DAG. Parallel within a wave, honest gates between waves.

## Harvest-first research protocol (binding for steps 5, 6/7, 9, 10)

The research steps do NOT start from a blank page. Curated, battle-tested material on
GitHub beats freshly-synthesized web research — so every applicable step runs this
sequence (the hyperbuild analogue of hyperresearch's vault-before-fetch and
academic-APIs-before-web-search rules):

1. **DISCOVER.** Search GitHub FIRST for authoritative repos on the topic: official org
   repos and style guides, high-star best-practices repos and awesome-lists, and — for
   steps 9/10 — existing Claude Code skills collections (start with `anthropics/skills`
   and community awesome-claude-code / claude-skills lists). WebSearch with
   `site:github.com` + GitHub's own search.
2. **VET.** Keep a candidate only if: meaningful stars for its niche, commits within
   ~12–18 months, and authoritative origin (official org > well-known author > random).
   Record every candidate — kept or rejected, with reason — in `research/harvest/harvest-log.md`
   (repo URL, stars, last-commit date, license, verdict).
3. **HARVEST.** Shallow-clone keepers into `research/harvest/<topic>/<repo>/`
   (`git clone --depth 1`); read the relevant files. LICENSE RULE: MIT/Apache/BSD/CC —
   adapt freely with attribution in the artifact's Sources section; GPL/AGPL/unlicensed —
   learn from it, cite it, but do NOT copy text or code into our artifacts.
4. **ADAPT, don't copy-paste.** Distill harvested material into OUR artifacts
   (stack-guide decisions, design systems, generated skills), reconciled with our PRD and
   platform decision. For step 10: when a harvested Claude Code skill already covers a
   need (e.g. a Flutter best-practices skill, a design-system skill), adapt it to this
   project instead of writing from zero — keep its structure, rewrite specifics.
5. **GAP-FILL.** Only after harvesting, run deep web research for what's missing, stale
   (>18 months), or contradicted across harvested sources. The step's normal source
   targets then apply to the gaps, not to re-deriving what was harvested.

Per-step application: step 5 — official style guides + best-practices repos per topic;
steps 6/7 — reference design systems' public repos/docs (Material, HIG resources,
open-source token sets); step 9 — skill collections as format exemplars; step 10 —
adaptable existing skills. Steps 2–3 (market/social) are exempt: opinions and versions
must come from live sources.

**Named harvest sources** (pre-vetted; the DISCOVER phase still looks for more):

1. `https://github.com/zakariaf/Flutter-Skills` (MIT, 33 skills) — BOTH (a) the anatomy
   exemplar for ALL generated skills on any platform (see "Two kinds of skills" below)
   and (b) a direct content source when the chosen platform is Flutter — steps 9/10
   clone it, and step 10 adapts its matching skills (architecture, testing-strategy,
   lint-and-style-config, design-system-structure, naming-conventions, ...) to this app
   instead of writing those from zero.
2. `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill` (MIT) — a UI/UX skill
   collection for steps 6/7/9. CHERRY-PICK, don't adopt wholesale: its valuable parts
   are the three-layer token architecture (primitive → semantic → component CSS
   variables — step 7's tokens.css should follow this structure unless design research
   argues otherwise) and its token-validator script pattern (validate-tokens /
   html-token-validator — the model for a step-8 mockup↔tokens consistency gate). Its
   slides/banner/brand skills are out of scope; treat overall quality as mixed and vet
   each piece.

**Per-platform skill search is MANDATORY in step 9's DISCOVER phase.** As soon as the
platform is known, step 9 searches for existing high-quality Claude Code skills FOR THAT
PLATFORM before anything is written from scratch — every major stack has some: Flutter →
zakariaf/Flutter-Skills (above); Rails → 37signals' published Claude Code skills;
plus `anthropics/skills` and the community awesome-claude-code / claude-skills lists for
any stack. Searches like "<framework> claude code skills site:github.com" and
"claude skills <platform>". Found collections enter the harvest-log with a verdict and
step 10 adapts the winners.

## Two kinds of skills — and the generated-skill anatomy (step 10 output contract)

The harness contains two fundamentally different kinds of skill; do not confuse them:

1. **Pipeline step skills** (`hyperbuild-N-*`): PROCEDURAL, executed once at a specific
   pipeline moment, loaded fresh in full via Skill(). A single self-contained SKILL.md is
   CORRECT here — the whole procedure must be in context when the step runs; splitting it
   into reference files would add read round-trips for content that is always needed.
   (This is hyperresearch's deliberate design.)
2. **Generated app skills** (`app-*`, written by step 10): KNOWLEDGE/DISCIPLINE skills,
   triggered repeatedly across many implementation tasks. These MUST use the rich
   four-part anatomy (modeled on zakariaf/Flutter-Skills and anthropics/skills), because
   progressive disclosure is what keeps them cheap to trigger yet deep when needed:

```
.claude/skills/app-<name>/
├── SKILL.md          # lean core, always loaded: frontmatter with a trigger-rich
│                     #   description; the non-negotiable rules (numbered, concrete);
│                     #   a pointer per reference file ("read references/X.md when …");
│                     #   anti-patterns; definition-of-done checklist; related skills
├── references/*.md   # deep dives read ON DEMAND (one topic per file, 60-200 lines)
├── examples/*        # real, compilable code in the TARGET language — not pseudocode
└── scripts/*.sh      # mechanical PASS/FAIL check gates (grep/analyze-based, exit
                      #   non-zero on hard failure, no app-hardcoded paths)
```

RULES: SKILL.md stays lean (~100-250 lines) — depth lives in references/. Every
non-negotiable rule that CAN be checked mechanically gets a line in a scripts/ gate —
a rule with a check script is enforced; a rule without one is a suggestion. Simple
skills (e.g. app-review-checklist) may omit examples/ or scripts/ when they'd be
padding, but any skill with code rules gets all four parts.

**Skill gates are wired into the build loop:** step 14 runs every generated skill's
`scripts/*.sh` after each epic (alongside the test suite); step 16's ship gate runs ALL
of them as a hard check. This is the hyperbuild analogue of hyperresearch's lint gate —
structural enforcement, not prompted good intentions.

## Docs

- **README.md**: positioning ("hyperresearch for building apps"), the two-step promise,
  quickstart (open Claude Code in this dir → `/hyperbuild <idea>` → later
  `/hyperbuild-choose b`), the pipeline table, agent roster table, layout diagram,
  scale gears, "what it doesn't do" honesty section (needs the platform SDKs installed —
  flutter/Xcode/node; research quality depends on web access; you still review the code).
- **CLAUDE.md**: short; this repo is the hyperbuild harness; entry `/hyperbuild`;
  resume rule (check runs/*/manifest.json); never edit files under runs/ by hand;
  epics/ and app/ are pipeline-owned.
- **PIPELINE.md**: the architecture doc — principles above, per-step deep description,
  state layout, gate specs, spawn contract, lineage notes mapping each mechanism to the
  hyperresearch mechanism that inspired it.
- **runs/README.md**, **epics/README.md**: format contracts for their directories.

## Quality bar

Every file must be immediately usable in Claude Code with zero edits: valid frontmatter,
real relative paths, consistent names/numbers everywhere. No placeholders like TBD/TODO.
Any number cited in a step skill must match this spec's knobs table. Skill names in
Skill() calls must exactly match directory names. Agent names in spawn instructions must
exactly match `.claude/agents/*.md` names.
