<p align="center">
  <img src="assets/banner.png" alt="hyperbuild" width="720">
</p>

<h3 align="center">One prompt in. A researched, designed, planned, implemented app out —<br>you make exactly one decision: which design.</h3>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/zakariaf/hyperbuild" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/Claude%20Code-pipeline-6E56CF" alt="Claude Code pipeline">
  <img src="https://img.shields.io/badge/skills-23-45C4FF" alt="23 skills">
  <img src="https://img.shields.io/badge/agents-20-FFB224" alt="20 agents">
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
| 2 | Market recon *(∥ 3)* | Competitor discovery → per-competitor dossiers + `competitor-landscape.md` feature matrix | 1 hb-competitor-scout, then one hb-competitor-analyst per competitor (6–8 standard / 12–15 premier) |
| 3 | Social mining *(∥ 2)* | What real users say on Reddit, HN, app stores, LinkedIn/X → pain points + wish lists ranked frequency × intensity → `sentiment-synthesis.md` | 4 hb-sentiment-miner (one per platform group) |
| 3.5 | Research audit | Adversarial audit of steps 2+3: tries to REFUTE the top pain points + wish-list items, clusters syndicated copies (they argue with the weight of ONE source), spot-checks version claims against live sources → `research/research-audit.md`; confirmed findings patch the synthesis docs — downgraded/annotated, never silently deleted | 1 hb-research-critic |
| 4 | Product spec | Merge 2+3 (as audited by 3.5) → the PRD: personas, MoSCoW feature list, differentiators, evidence traces, canonical screen inventory with per-screen mockup-feasibility (full/partial/none) | 1 hb-spec-critic reviews; orchestrator patches |
| 4.5 | Feature specs | One deep spec file per must/should feature → `features/NN-<slug>.md` + `features/00-index.md` | 3–5 hb-feature-author (feature batches) |
| 5 | Stack research | Best practices for the chosen platform: architecture, structure, testing, tooling/CI → `stack-guide.md` with committed "we will do X" decisions | 4 hb-stack-researcher (one per topic) |
| 6 | Design research | Propose exactly 3 named design directions; deep research each | 3 hb-design-researcher (one per direction) |
| 7 | Design systems | 3 full design systems: `design-system.md` + `tokens.css` each — type, color (light+dark), spacing, components | 3 hb-design-system-author (one per direction) |
| 8 | Mockups *(∥ 9)* | Every mockable PRD screen × 3 designs as self-contained HTML with REAL content + headless-Chrome `screenshots/` renders + `designs/index.html` gallery | 3–6 hb-mockup-smith (screens split per design) |
| 8.5 | Visual QA | The pixels get reviewed before you do: one critic per direction OPENS every rendered screenshot and judges it against the binding craft bar in [docs/DESIGN-CRAFT.md](docs/DESIGN-CRAFT.md) + that direction's own design system — craft (signature element, type pairing, depth, shape language, data personality, empty-state art), layout integrity (nothing clipped, no FAB parked on a list row, deliberate truncation, 44px tap targets, contrast, safe areas), and whether the three directions actually look like three products. Defects re-spawn the smith that drew the screen, re-render, re-judge (≤2 critic rounds = one patch round) → `gates/visual-qa-{a,b,c}.json` | 3 hb-design-critic (one per direction) |
| 9 | Skill research *(∥ 8)* | How to author great Claude Code skills → `skill-authoring-guide.md` (mines hyperresearch as the exemplar) | 1–2 hb-stack-researcher |
| 10 | Skill forge | Generate PROJECT-SPECIFIC skills into `.claude/skills/`: `app-code-style`, `app-architecture`, `app-testing`, `app-components`, `app-review-checklist` | 5 hb-skill-smith (one per skill) |
| 11 | Epics | The full backlog: `epics/00-overview.md` + one dir per epic with `epic.md` + task files; every must/should feature → ≥1 task | 1 hb-epic-planner, then 3–6 hb-task-author, then hb-spec-critic coverage audit |
| 12 | Design gate | Verify EVERY Stage-A artifact + full coverage (missing mockup screenshots warn, never hard-fail) → `gates/design-gate-report.md`; then STOP and ask for `/hyperbuild-choose a\|b\|c`. The ONE permitted stop | 1 hb-gate-verifier |

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
| 15 | Adversarial review | Whole-app pass: 3 critics in parallel (code quality, spec coverage, mockup fidelity via app-vs-design screenshot comparison) → ranked findings → surgical patches; structural findings become new tasks (max 1 loop back through step 14) | 3 critics parallel, then hb-patcher |
| 16 | Ship gate | Tests green, lint clean, skill gates pass, every task done, acceptance criteria checked, the traceability chain walked mechanically (feature → spec file → done tasks → files in `app/` → passing tests), git tree clean with the wave/epic commit history present, app builds and runs → `gates/ship-report.md`. Max 3 fix rounds, else blocked + honest report | 1 hb-gate-verifier |

## Agent roster

20 subagents in `.claude/agents/`. Tools are the enforcement mechanism, not documentation: critics physically cannot edit, the patcher physically cannot create files.

| Agent | Model | Tools | Role |
|-------|-------|-------|------|
| `hb-competitor-scout` | sonnet | WebSearch, WebFetch, Read, Write | Discover the competitor set + latest versions; ranked list w/ URLs |
| `hb-competitor-analyst` | sonnet | WebSearch, WebFetch, Read, Write | Deep dossier on ONE competitor: version, features, changelog, pricing, ratings |
| `hb-sentiment-miner` | sonnet | WebSearch, WebFetch, Read, Write | Mine ONE platform group for real user opinions; verbatim quotes + URLs |
| `hb-stack-researcher` | sonnet | WebSearch, WebFetch, Read, Write, Bash | Best practices for ONE topic on the chosen stack; harvest-first; committed decisions |
| `hb-research-critic` | opus | Read, Grep, Glob, WebSearch, WebFetch | Adversarial audit of the research corpus: refutes pain points, clusters syndicated copies, live spot-checks claims; NEVER edits |
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
├── LICENSE                           # MIT
├── .claude/
│   ├── skills/
│   │   ├── hyperbuild/               # ROUTER (entry)
│   │   ├── hyperbuild-choose/        # the human checkpoint
│   │   ├── hyperbuild-revise/        # gate-time: idea / feature / design / epics change
│   │   ├── hyperbuild-redesign/      # gate-time: new directions (KEEP the ones you like)
│   │   ├── hyperbuild-1-intake/ … hyperbuild-16-ship-gate/   # 19 step skills (incl. 3.5, 4.5, 8.5)
│   │   └── app-*/                    # PROJECT-SPECIFIC skills, generated by step 10
│   └── agents/hb-*.md                # the 20 subagents above
├── skills -> .claude/skills          # symlinks for plugin packaging (Mode B)
├── agents -> .claude/agents
├── runs/<run_tag>/                   # run state (see runs/README.md)
│   ├── idea.md                       # GOSPEL: your verbatim idea
│   ├── manifest.json                 # step transitions; resume point
│   ├── designs/{a,b,c}/              # design systems + HTML mockups + screenshots/ renders
│   ├── designs/index.html            # the comparison gallery you open
│   ├── decisions/                    # platform.md, design-choice.md, revisions.md
│   └── gates/                        # design-gate-report.md, visual-qa-{a,b,c}.json, ship-report.md
├── research/                         # the vault: steps 2–9 (see research/README.md)
├── features/                         # one spec per feature: step 4.5 (see features/README.md)
├── epics/                            # the backlog: step 11 (see epics/README.md)
└── app/                              # THE ACTUAL APP: steps 13–16
```

Research is a first-class deliverable, not run debris: competitor dossiers, sentiment syntheses, the PRD, the stack guide, and design research all persist at the repo root as plain markdown, readable without any tooling. Harvest-first steps start from two pre-vetted GitHub sources: [`zakariaf/Flutter-Skills`](https://github.com/zakariaf/Flutter-Skills) (MIT — the anatomy exemplar for all generated skills, and a direct content source when the platform is Flutter) and [`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) (MIT — cherry-picked, never adopted wholesale: the three-layer token architecture and the token-validator script pattern are the keepers).

## Scale gears

Default gear: `standard`. Say "premier" in your idea prompt to opt in; step 1 records the gear in the manifest and every step reads its numbers from it.

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

## Requirements

- [Claude Code](https://claude.com/claude-code)
- The SDK for whatever platform your app targets — Flutter, Xcode, Node, whatever step 1 resolves (checked at step 13, not before)
- Chrome (strongly recommended) — step 8 renders mockup screenshots via headless Chrome and step 8.5's critics judge those renders. Without a Chrome binary there are no pixels to review: step 8.5 degrades to a source-level read of the mockup HTML and the design gate warns instead of failing, so you review the HTML mockups yourself

## What it doesn't do

- **It doesn't install your toolchain.** Stage B runs real platform commands (`flutter create`, Xcode builds, `npm` scaffolds). The SDK for your chosen platform must already be installed and on PATH, or step 13 blocks.
- **Research quality depends on web access.** Steps 2–9 live on WebSearch/WebFetch. Rate limits, blocked sites, and thin niches degrade the evidence base; the artifacts cite what they actually found, but they can't cite what they couldn't reach.
- **You still review the code.** The ship gate proves the tests pass, the lint is clean, every task is done, and the app builds. It does not prove the app is secure, performant at scale, or right for your market. Read `gates/ship-report.md` — including its "known gaps" section — before you ship anything to a user.
- **It stops exactly once, on purpose.** One checkpoint, one question: a, b, or c. If none of the three fits, `/hyperbuild-revise` and `/hyperbuild-redesign` rebuild the designs *at that same stop* (see [Changing your mind](#changing-your-mind-at-the-gate)) — the pipeline never opens a second checkpoint somewhere else, and it never asks you to arbitrate an architecture decision.
- **One checkout, one app.** The vault, features, epics, and `app/` are singletons at the repo root. Don't point two ideas at one checkout.

## License

[MIT](LICENSE) © Zakaria Fatahi.

Architectural lineage: [hyperresearch](https://github.com/jordan-gibbs/hyperresearch) — the deep-research harness this design is modeled on.
