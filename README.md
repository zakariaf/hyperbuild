<p align="center">
  <img src="assets/banner.png" alt="hyperbuild" width="720">
</p>

<h3 align="center">One prompt in. A researched, designed, planned, implemented app out —<br>you make exactly one decision: which design.</h3>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/zakariaf/hyperbuild" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Claude%20Code-pipeline-6E56CF" alt="Claude Code pipeline">
  <img src="https://img.shields.io/badge/skills-23-45C4FF" alt="23 skills">
  <img src="https://img.shields.io/badge/agents-22-FFB224" alt="22 agents">
  <a href="https://github.com/zakariaf/hyperbuild/generate"><img src="https://img.shields.io/badge/use%20this-template-2ea44f" alt="Use this template"></a>
</p>

---

**hyperbuild turns Claude Code into an app factory.** It is a 19-step, two-stage pipeline harness: a thin router skill drives per-step skills, tool-locked subagents do the work in parallel, every artifact lands on disk, and crashed runs resume at the exact step where they died.

```
/hyperbuild a habit tracker that coaches you with weekly insights, mobile-first
        # … Stage A runs autonomously, then stops at the design gate …
/hyperbuild-choose b
        # … Stage B runs autonomously; a working app lands in app/
```

> **Architecture inspired by [hyperresearch](https://github.com/jordan-gibbs/hyperresearch)** by [@jordan-gibbs](https://github.com/jordan-gibbs). hyperbuild ports its deep-research harness design to app building: a thin router skill with per-step skills loaded fresh into context at the moment they run (so a long pipeline survives context compaction), subagents tool-locked to exactly what their role needs, adversarial critics feeding mechanical gates instead of self-review, and a disk manifest that resumes a crashed run at the step where it died.

## The promise: two steps

> 1. You: `/hyperbuild <my app idea>` → hours later: deep research done (competitors,
>    social sentiment, platform best practices), 3 complete design systems with HTML
>    mockups of every screen, project-specific Claude Code skills generated, epics/tasks
>    written — pipeline STOPS waiting for a design choice.
> 2. You: `/hyperbuild-choose <a|b|c>` → the harness implements the entire app from the
>    epics and tasks. At the end: a working app.

That design choice is the only decision the pipeline asks of you. Everything else — what to research, which stack conventions to commit to, how to break the product into epics, which tests to write — is decided by the pipeline and written down with its rationale, so you can audit every call it made.

## Install

### Mode A — Template (recommended)

One repo per app. The harness checkout **is** the workspace: research, specs, epics, and the app itself all land inside it.

1. Click **Use this template** on GitHub to mint a fresh repo for your app — or clone directly:

   ```bash
   git clone https://github.com/zakariaf/hyperbuild my-app
   cd my-app
   claude
   ```

2. In Claude Code:

   ```
   /hyperbuild a habit tracker that coaches you with weekly insights, mobile-first
   ```

3. Walk away. When the pipeline reaches the design gate it stops and tells you to open the design gallery:

   ```bash
   open runs/<run_tag>/designs/index.html   # all 3 designs, every screen, side by side
   ```

4. Pick one and resume:

   ```
   /hyperbuild-choose b
   ```

Stage B builds the app into `app/`. The final message tells you what was built, how to run it, the test count, and any known gaps.

Want a bigger run? Say `premier` anywhere in your idea prompt to shift gears (see [Scale gears](#scale-gears)).

**One checkout = one app.** A second idea gets a fresh copy of the template in a new folder.

### Mode B — Plugin (experimental)

Install hyperbuild as a Claude Code plugin into any project:

```
/plugin marketplace add zakariaf/hyperbuild
/plugin install hyperbuild
```

Skills arrive namespaced: `/hyperbuild:hyperbuild <idea>`, then `/hyperbuild:hyperbuild-choose a|b|c`. The pipeline writes its `runs/`, `research/`, `features/`, `epics/`, and `app/` directories into whatever project you run it from.

Caveats: template mode is the battle-tested path — plugin mode is newer and less exercised. The plugin packaging relies on the repo-root `skills/` and `agents/` symlinks into `.claude/`, which may not resolve on Windows checkouts. **On Windows, use template mode.**

## The pipeline

The entry skill `hyperbuild` is a thin ROUTER: it bootstraps the run, then invokes one step skill per phase via Claude Code's `Skill` tool. Each step's procedure loads into context only at the moment it runs — that is what stops a long pipeline from quietly dropping steps as its context rots. Full architecture: [PIPELINE.md](PIPELINE.md).

Steps run strictly in sequence, with exactly two concurrent pairs — **2 ∥ 3** and **8 ∥ 9** — whose members share no inputs:

```
Stage A:  1 → (2 ∥ 3) → 3.5 → 4 → 4.5 → 5 → 6 → 7 → (8 ∥ 9) → 8.5 → 10 → 11 → 12 → STOP
Stage B:  (checkpoint) → 13 → 14 → 15 → 16 → done
```

### Stage A — PLAN (autonomous, `/hyperbuild <idea>`)

| # | Step | What it does | Spawns (parallel) |
|---|------|--------------|-------------------|
| 1 | Intake | Verbatim idea → `idea.md`; mint run_tag; resolve platform (rationale in `decisions/platform.md`); init manifest + scaffold; seed TodoWrite | — |
| 2 | Market recon *(∥ 3)* | Competitor discovery → per-competitor dossiers in `research/01-product-and-market/research/competitors/`. Every price, tier, version and "they already ship this" claim is REGISTERED as a load-bearing claim, then fact-checked one agent per claim into the area's `verify/`; the corrected synthesis lands in `author/competitor-landscape.md` | 1 hb-competitor-scout, then one hb-competitor-analyst per competitor (6–8 standard / 12–15 premier), then one hb-claim-verifier **per claim** |
| 3 | Social mining *(∥ 2)* | What real users say on Reddit, HN, app stores, LinkedIn/X → pain points + wish lists ranked frequency × intensity. Claims registered and verified the same way (a "top complaint" that is one viral thread reposted five times does not survive) → `author/sentiment-synthesis.md` | 4 hb-sentiment-miner (one per platform group), then one hb-claim-verifier per registered claim |
| 3.5 | Research audit | The area-01 corpus pass: critics read the WHOLE product-and-market corpus for contradictions BETWEEN dimensions — the defect class no single-claim fact-check can see — plus cherry-picking and syndicated copies (derivative reposts argue with the weight of ONE source) → `01-product-and-market/critique/`, then the area's `_INDEX.md`. Every verify/ correction is applied to the synthesis docs: REFUTED claims never reach the PRD, and nothing is silently deleted | 2 critic seats (3 premier), one lens each — hb-research-critic takes the `live-evidence` seat on its enumerated 7-check list, hb-corpus-critic the rest |
| 4 | Product spec | Merge 2+3 (as audited by 3.5) → the PRD: personas, MoSCoW feature list, differentiators, evidence traces, canonical screen inventory with per-screen mockup-feasibility (full/partial/none) | 1 hb-spec-critic reviews; orchestrator patches |
| 4.5 | Feature specs | One deep spec file per must/should feature → `features/NN-<slug>.md` + `features/00-index.md` | 3–5 hb-feature-author (feature batches) |
| 5 | Stack research | Best practices for the chosen platform, ONE agent per dimension (6–8 standard / 10–14 premier): architecture, structure, state, testing, lints, CI, performance… → `research/02-engineering/research/`. Every version, package status, licence and API name a decision rests on is verified by its own fact-checker → `verify/`; corpus critics catch cross-dimension contradictions → `critique/`; then `author/stack-guide.md` with committed "we will do X" decisions | 6–8 / 10–14 hb-stack-researcher, then one hb-claim-verifier per claim (≤25 / ≤60 per area), then 3 / 5 hb-corpus-critic — area 02 runs the larger panel by design |
| 6 | Design research | Propose exactly 3 named design directions; deep research each → `research/03-design-system/research/`. Claims that later become code — the platform design system's real status, font licences, component/API names — are fact-checked into `verify/` before any system is authored | 3 hb-design-researcher (one per direction), then one hb-claim-verifier per claim, then 2–3 hb-corpus-critic |
| 7 | Design systems | 3 full design systems: `design-system.md` + `tokens.css` each — type, color (light+dark), spacing, components | 3 hb-design-system-author (one per direction) |
| 8 | Mockups *(∥ 9)* | Every mockable PRD screen × 3 designs as self-contained HTML with REAL content + headless-Chrome `screenshots/` renders + `designs/index.html` gallery | 3–6 hb-mockup-smith (screens split per design) |
| 8.5 | Visual QA | The pixels get reviewed before you do: one critic per direction OPENS every rendered screenshot and judges it against the binding craft bar in [docs/DESIGN-CRAFT.md](docs/DESIGN-CRAFT.md) + that direction's own design system — craft (signature element, type pairing, depth, shape language, data personality, empty-state art), layout integrity (nothing clipped, no FAB parked on a list row, deliberate truncation, 44px tap targets, contrast, safe areas), and whether the three directions actually look like three products. Defects re-spawn the smith that drew the screen, re-render, re-judge (≤2 critic rounds = one patch round) → `gates/visual-qa-{a,b,c}.json` | 3 hb-design-critic (one per direction) |
| 9 | Skill research *(∥ 8)* | How to author great Claude Code skills, one agent per dimension → `research/04-claude-skills/research/` (mines hyperresearch and `zakariaf/Flutter-Skills` as exemplars). Frontmatter fields, tool names and format rules that step 10 will BUILD against get verified into `verify/` — an invented field ships five broken skills → `author/skill-authoring-guide.md` | one hb-stack-researcher per dimension, then one hb-claim-verifier per claim, then 2–3 hb-corpus-critic |
| 10 | Skill forge | Generate PROJECT-SPECIFIC skills into `.claude/skills/`: `app-code-style`, `app-architecture`, `app-testing`, `app-components`, `app-review-checklist` | 5 hb-skill-smith (one per skill) |
| 11 | Epics | The full backlog: `epics/00-overview.md` + one dir per epic with `epic.md` + task files; every must/should feature → ≥1 task | 1 hb-epic-planner, then 3–6 hb-task-author, then hb-spec-critic coverage audit |
| 12 | Design gate | Verify EVERY Stage-A artifact + full coverage (missing mockup screenshots warn, never hard-fail) → `gates/design-gate-report.md`; write `research/README.md` — the areas index + reusability guide that tells your NEXT app what it can copy instead of re-researching; then STOP and ask for `/hyperbuild-choose a\|b\|c`. The report ends with `## What I am least confident about` — the pipeline's own short, skeptical list of where it may be wrong, which is the part worth reading first. The ONE permitted stop | 1 hb-gate-verifier |

### Checkpoint — `/hyperbuild-choose <a|b|c>`

Records your choice in `decisions/design-choice.md`, copies the chosen `tokens.css` + `design-system.md` to `app/design/`, flips the manifest to `stage=BUILD`, and re-invokes the router. An optional second argument overrides the platform (which re-runs steps 5, 10, 11 before building).

### Changing your mind at the gate

You are not stuck with a/b/c as drawn. While the run is parked at the design gate — and only there — two commands change things and park the run right back at the gate:

```
/hyperbuild-revise design b's cards feel formal — give it a real display face
        # … design scope: re-works direction b only — its design system, its mockups,
        #   its screenshots, its visual QA — then re-parks at the gate
/hyperbuild-revise drop the barcode scanner, add manual entry shortcuts
        # … feature scope: edits features/ + the PRD rows, re-runs the affected epics
/hyperbuild-redesign keep c, replace a and b — go bolder, this is for chefs not accountants
        # … archives a and b, regenerates just those two slots under your notes
        #   (6 → 7 → 8 → 8.5); c survives untouched. With no KEEP, all three regenerate.
```

`/hyperbuild-revise` takes plain English and works out the scope itself — **idea**, **feature**, **design**, or **epics** — then re-runs only what genuinely depends on the change. `/hyperbuild-redesign` takes free-form notes plus optional KEEP/REPLACE instructions; replaced directions are archived under `designs/archive/round-<N>/`, never deleted.

Your idea stays gospel: the verbatim body of `idea.md` is never rewritten — an idea-scope revision appends a dated `## Revisions` entry below it, and every steer is logged in `decisions/revisions.md`. Both commands end by re-parking the run at the design gate with a fresh gate report, so the pipeline still stops exactly once. Only `/hyperbuild-choose` releases Stage B. Run either command anywhere else in the pipeline and it refuses and tells you why.

### Stage B — BUILD (autonomous)

| # | Step | What it does | Spawns |
|---|------|--------------|--------|
| 13 | Scaffold | Init the real project in `app/` per stack-guide (`git init` + platform .gitignore + initial commit once the empty app builds); wire lint + formatter + tests + CI; implement design tokens in the target framework | orchestrator + 1 hb-implementer |
| 14 | Implement | Wave-based parallel implementation over the task DAG: each wave = ready tasks from any epic with disjoint `files:` lists, implemented + tested in parallel (visual/golden tests for UI tasks); between waves the full suite + skill gates go green, then the wave is committed; per epic: adversarial review of the real git diff + surgical patches, then a commit. Never start a wave on red | hb-implementer + hb-test-engineer pairs per wave; hb-code-critic + hb-patcher per epic |
| 15 | Adversarial review | Whole-app pass: 3 critics in parallel (code quality, spec coverage, mockup fidelity via app-vs-design screenshot comparison) → ranked findings → surgical patches; structural findings become new tasks (max 1 loop back through step 14). Two passes maximum, and the second runs only if a Tier-0 signal actually changed. Also records what the critics could NOT check, for the ship report's least-confidence section | 3 critics parallel, then hb-patcher |
| 16 | Ship gate | Tests green, lint clean, the FROZEN skill gates pass at their recorded hashes, every task done, acceptance criteria checked, the traceability chain walked mechanically (feature → spec file → done tasks → files in `app/` → passing tests), git tree clean with the wave/epic commit history present, app builds and runs → `gates/ship-report.md` — including `## What I am least confident about`. Max 2 fix rounds (the second only if a Tier-0 signal changed), else blocked + honest report | 1 hb-gate-verifier |

## The research archive

Most pipelines treat research as scaffolding: a few agents survey the web, a synthesis doc absorbs their conclusions, and the sources evaporate. hyperbuild treats it as **the durable asset of the run** — and holds it to a written contract, [docs/RESEARCH-ARCHIVE.md](docs/RESEARCH-ARCHIVE.md), that is binding on steps 2, 3, 3.5, 5, 6, 9 and 12. Every research step writes ONE area, and every area has the same four phases:

```
research/
├── README.md                    # areas index + REUSABILITY GUIDE (step 12)
├── product-spec.md              # the PRD (step 4) — the product contract, not a finding
├── harvest/                     # shallow-cloned repos + harvest-log.md
├── 01-product-and-market/       # steps 2, 3, 3.5
│   ├── _INDEX.md                #   every agent, every phase, every verdict, with file sizes
│   ├── research/                #   one file per dimension — independent, UNVERIFIED by construction
│   │   ├── competitors/<slug>.md
│   │   └── sentiment/<platform>.md
│   ├── verify/<dimension>--<claim-slug>.md   # one file per load-bearing CLAIM
│   ├── critique/<critic-name>.md             # critics reading the WHOLE corpus
│   └── author/competitor-landscape.md, author/sentiment-synthesis.md
├── 02-engineering/              # step 5 → author/stack-guide.md
├── 03-design-system/            # step 6 → author/design-directions.md
└── 04-claude-skills/            # step 9 → author/skill-authoring-guide.md
```

**`verify/` is the part that matters.** A surveying researcher optimizes for coverage, and will cheerfully repeat a 2023 blog post, a package archived last year, and an API name that never existed. So every claim a decision rests on — every version, price, licence, store policy, and API name — is handed to its OWN agent, one claim per agent, all in parallel, and that agent is told to **refute** it against primary sources: the maintainer's docs, the registry page, the official API reference, the actual repo. Verdicts come from a closed vocabulary — `CONFIRMED` / `PARTIALLY_TRUE` / `REFUTED` / `UNVERIFIABLE` — and **a REFUTED claim may never survive into a synthesis, the PRD, a feature spec, an epic, or a line of code.** It is corrected in `author/`, never silently deleted: the `verify/` file stays and the original `research/` file is left standing, because rewriting it would destroy the evidence that verification works. On the archive this format is modeled on, that pass caught a competitor already shipping the entire proposed MVP at a tenth of the assumed price, a licence change that made the core dependency store-incompatible, and a widely-cited statistic that appears to be fabricated.

**Every file ends with the prompt that produced it**, verbatim, in a collapsible block. A finding tells you what one agent concluded; the prompt tells you what it was asked, what context it was handed, and what it was never asked to consider — the only honest way to judge the blind spots, and the only way to re-run the same research later with a different brief.

**And it is built to be spent once.** A run burns millions of tokens establishing which state library is current, which package is abandoned, and what the store's privacy rules actually say — almost none of it specific to the app that paid for it. So step 12 writes `research/README.md`, a reusability guide that sorts every area into *portable to any app*, *portable to any app on this platform*, and *specific to this app — context only*, with capture dates and a re-verify rule. Area names are FIXED and never platform-specific (`02-engineering`, never `02-flutter-engineering`), so copying `02-engineering/`, `03-design-system/` and `04-claude-skills/` into your next hyperbuild checkout before running `/hyperbuild` is path-compatible with zero edits — and that run skips straight past research it already owns.

The honest trade: this costs *far* more agents than a survey. A `standard` engineering area is now something like 6–8 researchers, 20–40 fact-checkers, 2 corpus critics and an author, and the other three areas scale the same way — research dominates the token bill of a run. That is the price of an archive whose numbers are still worth reading in six months, paid once across every app you build from it.

## Agent roster

22 subagents in `.claude/agents/`. Tools are the enforcement mechanism, not documentation: critics physically cannot edit, the patcher physically cannot create files.

| Agent | Model | Tools | Role |
|-------|-------|-------|------|
| `hb-competitor-scout` | sonnet | WebSearch, WebFetch, Read, Write | Discover the competitor set + latest versions; ranked list w/ URLs |
| `hb-competitor-analyst` | sonnet | WebSearch, WebFetch, Read, Write | Deep dossier on ONE competitor: version, features, changelog, pricing, ratings |
| `hb-sentiment-miner` | sonnet | WebSearch, WebFetch, Read, Write | Mine ONE platform group for real user opinions; verbatim quotes + URLs |
| `hb-stack-researcher` | sonnet | WebSearch, WebFetch, Read, Write, Bash | Best practices for ONE topic on the chosen stack; harvest-first; committed decisions |
| `hb-claim-verifier` | sonnet | WebSearch, WebFetch, Read, Write | ADVERSARIAL FACT-CHECKER for ONE claim: told to REFUTE it against primary sources (registry, official reference, the actual repo); writes `verify/<dimension>--<claim-slug>.md` with a closed-vocabulary verdict |
| `hb-corpus-critic` | opus | Read, Grep, Glob, Write | Reads a WHOLE research area under ONE assigned lens and hunts contradictions BETWEEN dimensions — the defect class no single-claim check sees; writes `critique/<critic-name>.md`, separating `[VERIFIED]` from `[OPEN]`; NEVER edits another agent's file |
| `hb-research-critic` | opus | Read, Grep, Glob, WebSearch, WebFetch, Write | The LIVE-EVIDENCE seat of the step-3.5 critique panel (area 01 only). Not a renamed corpus critic — `hb-corpus-critic` has no web tools, so every claim it makes about the world is `[OPEN]` by its own contract, and area 01's evidence IS the world. Runs an enumerated **7-check list** over the two syntheses: C1 syndication clustering + `before → after` recount + rank re-derived from the scores · C2 source independence · C3 quote integrity verbatim at the URL · C4 staleness vs each competitor's own last release · C5 live spot-checks on claims `verify/` did NOT select · C6 sample-frame coverage (which audience segment nobody mined) · C7 demand-vs-supply collisions (a top pain point a competitor already ships). Writes `research/01-product-and-market/critique/research-audit.md`; NEVER edits the corpus |
| `hb-feature-author` | sonnet | Read, Write, Grep, Glob | Complete feature-spec files for ONE batch of PRD features; every claim evidenced |
| `hb-design-researcher` | sonnet | WebSearch, WebFetch, Read, Write, Bash | Deep research ONE design direction: reference systems, type, color, motion; harvest-first |
| `hb-design-system-author` | opus | Read, Write | Author ONE complete design system (design-system.md + tokens.css) |
| `hb-mockup-smith` | sonnet | Read, Write | Self-contained HTML mockups for assigned screens in ONE design |
| `hb-design-critic` | opus | Read, Grep, Glob, Write | VIEWS every rendered screenshot of ONE direction and judges craft + layout integrity against `docs/DESIGN-CRAFT.md` and the direction's design system; findings JSON; NEVER edits |
| `hb-skill-smith` | opus | Read, Write, WebSearch, WebFetch, Bash | Write ONE generated Claude Code skill (four-part anatomy) per the skill-authoring-guide |
| `hb-epic-planner` | opus | Read, Write | PRD → epic breakdown w/ dependency order + coverage matrix |
| `hb-task-author` | sonnet | Read, Write | Full task files for ONE epic (spec, files, testing, DoD) |
| `hb-implementer` | inherit | all tools | Implement ONE task end-to-end per the generated skills + mockups |
| `hb-test-engineer` | inherit | all tools | Write/extend tests for ONE task; run them; fix until green |
| `hb-code-critic` | opus | Read, Grep, Glob, Bash | Adversarial code review vs stack-guide; findings JSON; NEVER edits |
| `hb-spec-critic` | opus | Read, Grep, Glob | PRD coverage audit; findings JSON; NEVER edits |
| `hb-ux-critic` | opus | Read, Grep, Glob, Bash | Mockup-fidelity audit via screenshot comparison: captures the implemented app's screens and judges them against the chosen design's screenshots/ |
| `hb-patcher` | opus | Read, Edit, Grep, Glob | TOOL-LOCKED surgical patcher; physically cannot Write files |
| `hb-gate-verifier` | sonnet | Read, Grep, Glob, Bash | Runs a gate checklist mechanically; pass/fail JSON; never fixes anything |

## Layout

```
hyperbuild/                          # the harness (this repo)
├── README.md                         # you are here
├── CLAUDE.md                         # project memory for Claude Code
├── PIPELINE.md                       # deep architecture doc
├── docs/DESIGN-CRAFT.md              # the BINDING visual craft bar (steps 6, 7, 8, 8.5)
├── docs/RESEARCH-ARCHIVE.md          # the BINDING research output contract (steps 2, 3, 3.5, 5, 6, 9, 12)
├── docs/GUARDRAILS.md                # the enforcement layer: every rule the hooks apply
├── docs/IMPROVEMENTS.md              # the tracked backlog: what is known-missing, ranked
├── LICENSE                           # MIT
├── scripts/gate-design.sh            # the design gate, as code — unwritable while a run is in BUILD
├── scripts/gate-ship.sh              # the ship gate, as code
├── .claude/
│   ├── settings.json                 # the enforcement layer: deny hook, caps, telemetry
│   ├── skills/
│   │   ├── hyperbuild/               # ROUTER (entry)
│   │   ├── hyperbuild-choose/        # the human checkpoint
│   │   ├── hyperbuild-revise/        # gate-time: idea / feature / design / epics change
│   │   ├── hyperbuild-redesign/      # gate-time: new directions (KEEP the ones you like)
│   │   ├── hyperbuild-1-intake/ … hyperbuild-16-ship-gate/   # 19 step skills (incl. 3.5, 4.5, 8.5)
│   │   └── app-*/                    # PROJECT-SPECIFIC skills, generated by step 10
│   └── agents/hb-*.md                # the 22 subagents above
├── skills -> .claude/skills          # symlinks for plugin packaging (Mode B)
├── agents -> .claude/agents
├── runs/<run_tag>/                   # run state (see runs/README.md)
│   ├── idea.md                       # GOSPEL: your verbatim idea
│   ├── manifest.json                 # step transitions; resume point
│   ├── designs/{a,b,c}/              # design systems + HTML mockups + screenshots/ renders
│   ├── designs/index.html            # the comparison gallery you open
│   ├── decisions/                    # platform.md, design-choice.md, revisions.md
│   └── gates/                        # design-gate-report.md, visual-qa-{a,b,c}.json, ship-report.md
├── research/                         # the vault: steps 2–9, four areas × four phases
│   ├── 01-product-and-market/        #   research/ → verify/ → critique/ → author/ + _INDEX.md
│   ├── 02-engineering/               #   (see The research archive above, and docs/RESEARCH-ARCHIVE.md)
│   ├── 03-design-system/
│   ├── 04-claude-skills/
│   ├── product-spec.md               # the PRD (step 4)
│   └── README.md                     # areas index + reusability guide (step 12)
├── features/                         # one spec per feature: step 4.5 (see features/README.md)
├── epics/                            # the backlog: step 11 (see epics/README.md)
└── app/                              # THE ACTUAL APP: steps 13–16
```

Research is a first-class deliverable, not run debris: competitor dossiers, sentiment syntheses, the PRD, the stack guide, and design research all persist at the repo root as plain markdown, readable without any tooling — each area carrying its fact-checks in `verify/`, its cross-cutting critiques in `critique/`, and the prompt that produced every single file ([The research archive](#the-research-archive)). Harvest-first steps start from two pre-vetted GitHub sources: [`zakariaf/Flutter-Skills`](https://github.com/zakariaf/Flutter-Skills) (MIT — the anatomy exemplar for all generated skills, and a direct content source when the platform is Flutter) and [`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) (MIT — cherry-picked, never adopted wholesale: the three-layer token architecture and the token-validator script pattern are the keepers).

## Scale gears

Default gear: `standard`. Say "premier" in your idea prompt to opt in; step 1 records the gear in the manifest and every step reads its numbers from it.

| Knob | standard | premier |
|------|----------|---------|
| Competitors analyzed | 6–8 | 12–15 |
| Sources per competitor dossier | 5–8 | 10–15 |
| Sentiment posts mined per platform | 25–40 | 60–100 |
| Stack research sources per topic | 8–12 | 15–25 |
| Engineering research dimensions | 6–8 | 10–14 |
| Design research sources per direction | 6–10 | 12–18 |
| Claims verified per research file | 3–5 | 6–10 |
| Verify agents per area (hard ceiling) | ≤25 | ≤60 |
| Corpus critics per area *(the area binds the count: 01/03/04 = 2 / 3 · 02 = 3 / 5)* | 2–3 | 3–5 |
| Mockup screens | every PRD screen (cap 12) | every PRD screen (cap 20) |
| Feature spec files | every must/should (cap 15) | every must/should (cap 25) |
| Epics | 4–8 | 6–12 |
| Tasks per epic | 3–8 | 4–10 |
| Parallel implementers per wave (step 14) | 3–5 | 6–10 |
| Critic fix rounds (gates) *(round 2 only when a Tier-0 signal changed)* | ≤2 | ≤2 |

## Safety and limits

hyperbuild runs for hours without you. That is the product — and it is also the risk, so
the harness is built on the assumption that **an instruction in a context window is not a
control.** A context window gets compacted; the canonical incident is a user who told her
agent "confirm before acting", watched compaction drop the instruction, and lost thousands
of emails. Everything below holds regardless of what the model decides.

| | What it does |
|---|---|
| **Deny hooks** | Two `PreToolUse` hooks block the destructive and the outbound before they run: force-push and remote branch deletion, `git reset --hard`, history rewrites, recursive deletes *outside* the repo, package publishes, `gh release`/`gh repo delete`, credential writes, and any write outside the checkout. They block with `exit 2` — an `exit 1` hook logs an error and lets the action through, which is the single most common way a hook silently does nothing. A plain `git push` is not blocked; it prompts. Full rule list: [docs/GUARDRAILS.md](docs/GUARDRAILS.md) |
| **Cost, turn and time caps** | A per-step-class turn and wall-clock budget the router counts on disk in `manifest.usage` and blocks the run when one fires (`blocked_on: "cap: …"`). Be clear about the asymmetry: `--max-turns` and `--max-budget-usd` are hard flags that bound a whole *invocation*, not a step, so they only map onto steps where the harness is driven headless, one step per `claude -p` call; `--max-budget-usd` is print-mode only. `--max-turns` defaults to *no limit*, which is an infinite loop shipped as a default. The soft budgets are re-tuned from measured usage, not from guesses |
| **Rule of Two** | No step holds untrusted input + secrets + network egress at once. Research steps read the web and cannot write `app/`; build steps hold the repo, a shell and git, and run with web tools **disallowed** — everything they need was fetched, fact-checked and written to disk in Stage A |
| **A frozen oracle** | The generated `app-*` skills ship PASS/FAIL script gates, and the build agent wrote them. At the design gate they are copied to `runs/<run_tag>/gates/skill-scripts/` and hashed; steps 14 and 16 run **only** the frozen copies, a hash mismatch fails the ship gate, and the write hook refuses edits to either path once the run is in stage BUILD. The scripts stay readable — hiding tests from a model makes it hack them harder, not less |
| **Run lock** | `runs/<run_tag>/.lock` (pid + host + timestamp). Two sessions resuming one run would otherwise both execute |
| **Kill switch** | `touch runs/<run_tag>/ABORT` from any terminal. The router checks between every step and stops cleanly. It answers a real complaint: "I couldn't stop it from my phone" |
| **Gates are scripts** | `scripts/gate-design.sh` and `scripts/gate-ship.sh` are refused by the write hook while any run is in stage `BUILD` — the window in which the build agents are live — and are on the one-click `ask` list otherwise; each records its own `script_sha256` into every round's JSON, so a change is detectable as well as prevented. The gate verifier RUNS them and reports exit codes; it does not get to interpret them |
| **Audit trail** | Wall clock, agents spawned, turns and outcome recorded per step in `manifest.json` by the router, always. Cost and tokens only when a headless result object or `/cost` output was actually observed — otherwise `cost_usd` is `null` and `cost_source` is `"unavailable"`, because a running skill is not handed its own spend and one estimated number would corrupt every comparison the record exists for. (Tool-level OpenTelemetry events are tracked, not yet shipped — [docs/IMPROVEMENTS.md](docs/IMPROVEMENTS.md) item 18) |
| **Two fix rounds, not three** | Gates and critics get at most 2 attempts, and the second runs only when a *mechanical* signal changed — a test flipped, a script gate flipped, a re-render differs. Unaided re-attempts degrade rather than converge; a third round is the model talking itself into a different answer |
| **Calibrated uncertainty** | Both gate reports carry `## What I am least confident about` — 3–6 named, skeptical entries about where the pipeline may be wrong and would not know. It is not the known-gaps list, and it is the part to read first |

**Editing the harness is never blocked.** The deny rules cover destruction and outbound
actions, not authorship: `.claude/skills/hyperbuild*`, `.claude/agents/hb-*`,
`.claude/settings.json`, `docs/`, `scripts/`, `evals/` and the root docs stay fully
editable, by you and by Claude working for you. Changes there are surfaced and logged,
never refused. A guardrail that stops you maintaining your own harness is a bug in the
guardrail — every rule, and every deliberate allowance, is listed in
[docs/GUARDRAILS.md](docs/GUARDRAILS.md).

**What none of this buys you.** A green ship gate is a claim to audit, not a verdict to
trust — the gate proves the tests pass, the lint is clean, the frozen scripts exit 0 and
the traceability chain walks end to end. It does not prove the app is secure, performant,
or right for your market. Mockup-fidelity findings come from a model looking at
screenshots and are labelled in the report as a judge's opinion; they never block a ship.
Even a script gate is soft at the extreme: Claude Code overrides a `Stop` hook after 8
consecutive blocks. Read `gates/ship-report.md` — both its known gaps and its
least-confidence section — before anything reaches a user.

## Requirements

- [Claude Code](https://claude.com/claude-code) — **v2.1.217 or newer**. Below that floor
  `--max-budget-usd` does not enforce, so the per-step spend caps silently become
  decoration. The version in use is recorded in the run manifest
- The SDK for whatever platform your app targets — Flutter, Xcode, Node, whatever step 1 resolves (checked at step 13, not before)
- Chrome (strongly recommended) — step 8 renders mockup screenshots via headless Chrome and step 8.5's critics judge those renders. Without a Chrome binary there are no pixels to review: step 8.5 degrades to a source-level read of the mockup HTML and the design gate warns instead of failing, so you review the HTML mockups yourself

## What it doesn't do

- **It doesn't install your toolchain.** Stage B runs real platform commands (`flutter create`, Xcode builds, `npm` scaffolds). The SDK for your chosen platform must already be installed and on PATH, or step 13 blocks.
- **Research quality depends on web access.** Steps 2–9 live on WebSearch/WebFetch. Rate limits, blocked sites, and thin niches degrade the evidence base; the artifacts cite what they actually found, but they can't cite what they couldn't reach. The fact-checking pass is honest about this rather than papering over it: a claim no primary source settles comes back `UNVERIFIABLE` and is barred from carrying a `must`-level decision on its own.
- **You still review the code.** The ship gate proves the tests pass, the lint is clean, every task is done, and the app builds. It does not prove the app is secure, performant at scale, or right for your market. Read `gates/ship-report.md` — its "known gaps" section AND its "What I am least confident about" section, which are different lists on purpose: the first is what the pipeline found, the second is where it thinks it may be wrong ([Safety and limits](#safety-and-limits)).
- **It stops exactly once, on purpose.** One checkpoint, one question: a, b, or c. If none of the three fits, `/hyperbuild-revise` and `/hyperbuild-redesign` rebuild the designs *at that same stop* (see [Changing your mind](#changing-your-mind-at-the-gate)) — the pipeline never opens a second checkpoint somewhere else, and it never asks you to arbitrate an architecture decision.
- **One checkout, one app.** The vault, features, epics, and `app/` are singletons at the repo root. Don't point two ideas at one checkout.

## License

[MIT](LICENSE) © Zakaria Fatahi.

Architectural lineage: [hyperresearch](https://github.com/jordan-gibbs/hyperresearch) — the deep-research harness this design is modeled on.
