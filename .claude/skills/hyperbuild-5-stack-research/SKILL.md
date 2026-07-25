---
name: hyperbuild-5-stack-research
description: >
  Step 5 of the hyperbuild pipeline — builds the engineering research area
  `research/02-engineering/` to the docs/RESEARCH-ARCHIVE.md contract. The
  orchestrator probes the real toolchain, runs a bounded harvest DISCOVER
  sweep, then DERIVES 6–8 (standard) / 10–14 (premier) engineering dimensions
  for the platform chosen in step 1 from a documented base set; spawns ONE
  hb-stack-researcher per dimension (harvest-first) → research/; extracts
  every load-bearing claim into temp/claims-02.json; runs the verification
  engine (one hb-claim-verifier per claim, each told to REFUTE it) → verify/;
  runs the hb-corpus-critic panel → critique/; writes _INDEX.md; and only THEN
  authors `research/02-engineering/author/stack-guide.md` on the claims that
  survived. Steps 10, 13, 14 build by that guide and the step-15 code critic
  enforces it. Invoked by the hyperbuild router via Skill(); not run directly
  by users.
---

# Step 5 — Engineering research (area `02-engineering`: research → verify → critique → author)

You are executing step 5 (stack-research) of the hyperbuild pipeline. Steps 4 and 4.5 fixed WHAT to build (the PRD + feature specs); this step fixes HOW to build it — step 10 forges the project skills from the stack guide, step 13 scaffolds by it, step 14 implements by it, and step 15's `hb-code-critic` treats deviations from it as findings.

**Goal:** a complete research AREA at `research/02-engineering/` — all four phases — ending in `research/02-engineering/author/stack-guide.md`, a committed "we will do X" guide whose every decision rests on a claim that survived adversarial verification.

**Why four phases and not four topic docs.** The old shape of this step spawned four researchers and shipped their merge. A surveying researcher optimizes for coverage: it will confidently repeat a 2023 blog post, a package archived last year, and an API name that never existed — and step 14 will then write six files against that API name. In the exemplar corpus the verification pass caught a discontinued golden-test toolkit still being recommended, a state library whose entire test idiom had changed, a lint package that cannot be used on the installed SDK, and a widely-cited test-pyramid ratio that appears to be fabricated. **A survey is a hypothesis; only `verify/` turns it into a finding.**

**BINDING FORMAT: `docs/RESEARCH-ARCHIVE.md`.** Every file this step produces obeys it — the area layout (§2), the file formats (§3), the provenance rule (§4), the claim→verify mechanism (§5), the canonical verifier prompt (§6), and the synthesis rule (§7). Cite it by path in every spawn prompt; every subagent READS IT BEFORE producing anything. Violations are DEFECTS: the file is rejected and the agent re-spawned.

**THE AREA NAME IS `02-engineering`. FIXED. NEVER PLATFORM-SPECIFIC.** Not `02-flutter-engineering`, not `02-swift-engineering`, not `02-godot-engineering` — even though the exemplar corpus you may have seen uses a platform-specific name. The platform is chosen by step 1 and elaborated by the research INSIDE this area, so a platform in the path makes every downstream path conditional. Steps 10, 13, 14, 15, and 16 hardcode `research/02-engineering/author/stack-guide.md`. Platform goes in frontmatter and prose, never in a directory name. (Individual dimension SLUGS may name real tools — `riverpod.md`, `drift-persistence.md` are fine; it is the AREA that is fixed.)

---

## Inputs

Read these before doing anything:

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear` (standard | premier); confirm `steps["4.5"]` is `"done"`
- `runs/<run_tag>/decisions/platform.md` — the chosen platform/stack + rationale. **This is the stack you research. Not the trendiest one, not your favorite one — the one step 1 committed to.**
- `research/product-spec.md` — the PRD (root, unchanged). Skim: feature count, screen count, data model, and offline/sync/auth needs shape which dimensions exist and how much architecture is right-sized.
- `features/00-index.md` — skim: which features are `must`. A dimension the must-features depend on is never the one you drop.
- `docs/RESEARCH-ARCHIVE.md` — the format contract. Read it fully; you enforce it on every returned file.

Set `steps.5 = "running"` in the manifest, mark the step-5 todo `in_progress`, then:

```bash
mkdir -p research/02-engineering/{research,verify,critique,author} runs/<run_tag>/temp
```

Create all four phase directories up front even though the later phases fill them — an area with missing phase dirs reads as an area that SKIPPED verification, and design-gate check 22 then reports "missing verify/" instead of the honest "empty verify/", pointing the remedy at the wrong diagnosis. Do NOT write `_INDEX.md` yet: it indexes all four phases and is written at item 11, when the area is complete.

## Gear knobs

| Knob | standard | premier |
|---|---|---|
| Dimensions (`research/` agents) | 6–8 | 10–14 |
| Sources per dimension | 8–12 | 15–25 |
| Claims verified per dimension | 3–5 | 6–10 |
| Verify budget (`hb-claim-verifier` spawns for the whole area) | ≤25 | ≤60 |
| Corpus critics (area 02 — see note) | 3 | 5 |

**The verify budget is a HARD CEILING on the area**, the same `VERIFY_BUDGET` steps 3.5, 6 and 9 bind. Per-dimension counts multiply: 8 dimensions × 5 claims is 40 spawns against a ceiling of 25, and 14 × 10 is 140 against 60. Item 7 says exactly how to truncate.

**Critic count — area 02 is the deliberate exception.** The pipeline-wide knob is *2–3 (standard) / 3–5 (premier) corpus critics per area, and the AREA binds the count*: areas 01, 03 and 04 use 2 / 3; area 02 uses **3 / 5** because it is the largest corpus (up to 14 dimensions) and it is the only area whose contradictions compile into code. This exception is recorded in the knobs tables of `README.md`, `PIPELINE.md`, `docs/SPEC.md` and the router — never quietly lower it to 2 / 3 to match a table you half-remember.

---

## Procedure

### 1. Preflight — kill the premise trap BEFORE spawning anything

`docs/RESEARCH-ARCHIVE.md` §6: *a fact stated in the prompt is the one claim NOBODY checks.* Verifiers are pointed at what the researcher SAID, not at what your brief ASSUMED. In the exemplar, three runs were told "stable is 3.44.0"; the installed toolchain was 3.41.2, and that bad premise survived ~10 references until code failed to compile against the real SDK.

So: **measure the environment, never assert it.**

1. Probe the real toolchain with Bash — whatever the platform uses: `flutter --version`, `dart --version`, `node -v && npm -v`, `swift --version && xcodebuild -version`, `python3 -V`, `go version`, `dotnet --info`, `godot --version`, `ruby -v && rails -v`, `cargo --version`. Also probe the OS and the package manager. If a toolchain is not installed, RECORD THAT — "not installed on this machine" is itself a load-bearing fact for step 13.
2. Write `runs/<run_tag>/temp/environment-02.md`: one line per fact — the value, the exact command that produced it, and the date. This file is the ONLY thing you are allowed to state to researchers as a fact.
3. Everything else you might be tempted to assert — "the current stable release is X", "the recommended state library is Y", "the store requires Z" — goes into the spawn prompt AS A QUESTION: *"verify the current stable release yourself against the vendor's release notes; do not assume."*

**INVARIANT: no spawn prompt in this step states a version, price, licence, or API name that is not in `environment-02.md`.** Grep your own prompts before sending them.

### 2. DISCOVER — the harvest-first sweep that feeds the dimension list

Harvest-first is preserved, and it now has a job at TWO altitudes. At this altitude it is a bounded discovery sweep whose only product is the dimension list; the deep harvesting happens inside each researcher (step 4).

Do this yourself, bounded — **3–6 WebSearches, zero clones, no synthesis**:

- `site:github.com <platform> style guide OR best practices OR architecture` — find the official org's guide and the high-star community guides.
- `<platform> official architecture guide` / `<platform> project layout` — find whether the vendor publishes an opinionated structure at all (some do, some pointedly refuse).
- `site:github.com awesome-<platform>` — the awesome-list's own section headings are a free, curated map of the platform's real concern set.
- One search for the app's distinctive subsystem from the PRD (offline sync, on-device inference, real-time multiplayer, payments…).

Append every candidate repo you saw — kept or rejected, with reason — to `research/harvest/harvest-log.md` (repo URL, stars, last-commit date, licence, verdict). You are NOT cloning here; you are recording the map and handing the keepers to the researchers as seed repos so they don't each rediscover the same three URLs.

**What you are reading for:** not answers — CONCERN NAMES. If the awesome-list has a "Scene organization" section and no "State management" section, that is the platform telling you its dimension set. If the vendor's guide has a chapter on "Migrations" the base set calls "persistence", rename to their word.

### 3. DERIVE the dimensions

**The base set** — twelve engineering concerns that recur across platforms. This is a MENU, not a checklist:

| # | Base dimension | The concern | Status |
|---|---|---|---|
| B1 | `architecture` | Layering, boundaries, data flow, DI shape, navigation, and WHAT KINDS OF CODE the pattern implies (input to the Code taxonomy) | core |
| B2 | `project-structure` | Folder layout, module boundaries, naming, and WHERE each kind of code lives (input to the Code taxonomy) | core |
| B3 | `state-management-di` | The state library/pattern + how dependencies are provided and overridden in tests | conditional |
| B4 | `language-idioms` | The language's current idioms and coding standards: error types, null/optional handling, immutability, async, generated code | core |
| B5 | `testing-strategy` | The pyramid for THIS platform: what to cover, what not to, test doubles, fixtures, coverage bar | core |
| B6 | `ui-component-testing` | Testing the view layer: component/widget tests, snapshot/golden tests, the test harness's real defaults | conditional |
| B7 | `accessibility-testing` | Automatable a11y: contrast, tap targets, screen-reader traversal, the platform's own a11y test APIs | conditional |
| B8 | `persistence-data-layer` | Storage engine, schema, migrations, and MIGRATION TESTING — the failure that destroys user data | conditional |
| B9 | `error-handling` | Result/exception policy, crash capture, what a failure looks like to the user and to the developer | core |
| B10 | `lints-tooling` | Formatter, analyzer, the exact lint rule set, which rules get promoted to errors, pre-commit | core |
| B11 | `ci-release` | CI shape, caching, the release/signing/publishing path, artifact size | core |
| B12 | `performance-startup` | The platform's real budget: cold start, frame budget, p99 latency, memory ceiling — and how it is MEASURED | core |

**THE ADAPTATION RULE — four moves, applied in this order.** Write down the result of each move; it goes in the dimension record and, later, in `_INDEX.md`.

1. **RENAME.** Every surviving base dimension takes the platform's own vocabulary — the words the DISCOVER sweep found in the vendor's docs and the awesome-list headings. A researcher searching for "UI component testing" on a platform whose community says "golden tests" finds nothing. `ui-component-testing` → `widget-golden-testing` (Flutter) / `snapshot-testing` (iOS) / `component-and-e2e-testing` (web). `performance-startup` → `frame-budget-and-profiling` (game engine) / `latency-and-throughput` (backend).
2. **DROP.** Drop a base dimension only when the platform genuinely does not have that concern — never to save budget. `accessibility-testing` on a headless backend. `ui-component-testing` on a CLI. `persistence-data-layer` on an app that stores nothing. **The test: if a wrong answer here could not show up in this app's code, drop it.** A dropped dimension is NAMED in `_INDEX.md` with its one-line reason; a silently missing dimension is a defect.
3. **MERGE (standard gear only, and only to reach the ceiling).** Standard's 6–8 slots cannot hold eight core dimensions plus platform-specific additions, so merge PAIRS THAT SHARE A SOURCE CORPUS: `lints-tooling` + `ci-release` → `tooling-and-ci`; `architecture` + `error-handling` → `architecture-and-error-handling`; `project-structure` + `state-management-di` → `structure-and-state`. **Never merge a dimension the must-features depend on** (an offline-first PRD does not get `persistence` merged into anything), and never merge more than two.
4. **ADD.** **At least ONE dimension MUST come from THIS platform + THIS PRD and not from the base set** — this is a hard invariant. The base set is what every app shares; the additions are what makes this corpus worth 15 agents instead of a search. Sources: the awesome-list headings the base set has no slot for, the vendor's own chapter titles, and the PRD's distinctive subsystem. At premier, 3–6 additions.

**Worked adaptations** (illustrative, not prescriptive — derive yours from the DISCOVER sweep, do not copy these):

- **Flutter / mobile app.** RENAME B6 → `widget-golden-testing`, B8 → `drift-persistence-and-migration-testing`, B3 → the actual library once research names it (`riverpod`). ADD `platform-channel-testing` (every native interop bug lives here), ADD `build-flavors-and-signing`. Premier also splits B4 into `language-idioms` + `codegen-policy`.
- **Unity / Godot game.** RENAME B2 → `scene-and-prefab-organization`, B12 → `frame-budget-and-profiling`. DROP B7 unless the PRD claims accessibility. ADD `asset-pipeline-and-build-size`, `save-serialization-and-migration`, `input-and-device-matrix`, `determinism-and-fixed-timestep`. Note how little of the base set survives intact — that is the rule working.
- **Backend API service.** DROP B6, B7. RENAME B3 → `dependency-injection-and-configuration`, B12 → `latency-and-throughput-budgets`. ADD `api-contract-and-versioning`, `schema-migrations-and-zero-downtime`, `authn-authz`, `observability-and-tracing`, `idempotency-and-retries`, `deployment-topology`.
- **Web SPA / full-stack JS.** RENAME B6 → `component-and-e2e-testing`. ADD `rendering-mode` (SSR/CSR/streaming — the decision everything else hangs off), `bundling-and-code-splitting`, `forms-and-validation`, `seo-and-metadata`.
- **CLI tool / library.** DROP B6, B7. RENAME B11 → `distribution-and-packaging`. ADD `public-api-surface-and-semver`, `backwards-compatibility-policy`.

**Dimension slug rules.** Lowercase kebab-case, ≤ 32 chars, one file each: `research/02-engineering/research/<dimension>.md`. Unique — the slug becomes the prefix of every `verify/` filename for that dimension.

**Record the derivation** in `runs/<run_tag>/temp/dimensions-02.md`: the final list, and for EVERY base dimension what happened to it (kept / renamed to X / dropped because Y / merged with Z) plus every addition with its evidence from the DISCOVER sweep. This record is what makes `_INDEX.md` honest and what a re-run reads to know what was never looked at.

**⚠ If you find yourself about to research these dimensions yourself instead of spawning one agent each, STOP.** Ten dimensions researched serially in one context produces one exhausted context and ten shallow files. Spawn the researchers.

### 4. Spawn the research wave — ONE `hb-stack-researcher` per dimension, ALL IN ONE MESSAGE

All Task calls in a single message, true parallel execution. Each researcher owns exactly one dimension. Overlap is expected and fine at this phase (two dimensions may both discuss the state library) — cross-dimension contradictions are the CRITICS' prey in phase 3, not something to design away by starving a researcher of context.

````
subagent_type: hb-stack-researcher
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 5 (engineering researcher, dimension:
  <dimension>) of the hyperbuild pipeline, working in research area
  02-engineering. Step 1 chose the platform — read
  runs/<run_tag>/decisions/platform.md and research THAT stack.
  <N-1> sibling researchers are covering the other dimensions in
  parallel (<the full dimension list>); stay inside yours. You are the
  RESEARCH phase: breadth, unverified by construction. After the wave,
  every load-bearing claim you write gets handed to a separate
  adversarial fact-checker whose ONLY job is to refute it, then a critic
  panel reads the whole area for contradictions between dimensions, and
  only THEN does the orchestrator author
  research/02-engineering/author/stack-guide.md — which step 10 turns
  into project skills, step 13 scaffolds from, step 14 implements by,
  and the step-15 code critic enforces. Write claims a fact-checker can
  win or lose an argument with.

  FORMAT CONTRACT (BINDING — READ IT BEFORE PRODUCING ANYTHING):
  docs/RESEARCH-ARCHIVE.md, §3.1 for your file shape and §4 for the
  provenance rule. A file that violates it is rejected and re-spawned.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 02-engineering
  - dimension: <dimension-slug> — <the one-line concern>
  - output_path: research/02-engineering/research/<dimension-slug>.md
  - source_target: <8–12 standard | 15–25 premier per gear>
  - platform: <one line pasted from decisions/platform.md>
  - seed_repos: <the keepers from the DISCOVER sweep relevant to this
    dimension, with URLs — start here, don't rediscover them>
  - VERIFIED ENVIRONMENT FACTS (measured on this machine — the only
    facts in this prompt you may trust):
    <paste runs/<run_tag>/temp/environment-02.md verbatim>
  - EVERYTHING ELSE IS A QUESTION: current versions, current stable
    releases, current recommended packages, current store/registry
    policy — verify each one yourself against a dated primary source.
    This prompt asserts none of them, deliberately.

  READ FIRST (context files, in this order):
  - docs/RESEARCH-ARCHIVE.md (§3.1, §4)
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - research/product-spec.md (skim — feature scale, screen count, data
    model, and offline/auth needs right-size your recommendations)
  - features/00-index.md (skim — which features are must)

  RESEARCH RULES:
  - HARVEST-FIRST: before blank-page web research, start from
    seed_repos and search GitHub for more authoritative repos on YOUR
    dimension (official org style guides, high-star best-practices
    repos, awesome-lists — WebSearch with site:github.com). Vet each
    candidate (meaningful stars, commits within ~12–18 months,
    authoritative origin); log EVERY candidate — kept or rejected,
    with reason — in research/harvest/harvest-log.md (repo URL, stars,
    last-commit date, license, verdict); shallow-clone keepers via
    Bash: git clone --depth 1 <url>
    research/harvest/<dimension>/<repo>/. License rule:
    MIT/Apache/BSD/CC — adapt with attribution in your Sources;
    GPL/AGPL/unlicensed — learn and cite, never copy. Harvested repos
    count toward your source target. Only then GAP-FILL with web
    research for what is missing, stale (>18 months), or contradicted
    across harvested sources.
  - PRIMARY SOURCES for anything datable: the vendor's own docs and
    release notes, the package registry page (for the real current
    version, publisher, and maintenance status), the official API
    reference (for real signatures), the actual GitHub repo (for
    whether it is archived). A tutorial, a blog post, an aggregator
    answer, or your own recollection is NOT a primary source.
  - Recency rule: prioritize sources from the last 18 months. Any
    version, API, licence, price, or policy claim MUST carry a dated
    primary source — "as of <lib> vX.Y (<month year>), per <URL>".
  - MANDATORY adversarial searches: at least one per serious option you
    evaluate — "<X> criticism", "<X> problems", "why I stopped using
    <X>", "<X> deprecated". A recommendation that has never been
    attacked is not a recommendation. Also check: is the repo archived?
    when was the last release? does the registry mark it discontinued?
  - CODE TAXONOMY (dimensions covering architecture and/or project
    structure ONLY): your ## Recommendations MUST name the project's
    code categories — the platform's analogue of Rails' models / views
    / controllers / concerns / services / apis. The architecture side
    names WHAT kinds of code exist under the chosen pattern; the
    structure side names WHERE each kind lives (directory + naming
    rule). The categories come from YOUR research — they differ per
    platform and architecture; HAVING named categories is
    non-negotiable. A generic copy of Rails' list is a defect unless
    the research genuinely lands there.
  - RIGHT-SIZE to THIS app. A 12-screen v1 does not need the
    architecture of a 400-screen bank. "The docs recommend it" is not
    a reason; "the docs recommend it AND this app has the condition
    the recommendation is for" is.

  OUTPUT — write output_path in the docs/RESEARCH-ARCHIVE.md §3.1
  shape. Non-negotiables:
  - Frontmatter: run_tag, created (YYYY-MM-DD), area: 02-engineering,
    dimension: <dimension-slug>, phase: research. Then the title and
    the "> Phase: **research** · Agent `<your agent id>` · Run
    `<run_tag>`" provenance line.
  - ## Summary — one dense paragraph: what you found, what it changes,
    what the reader must not miss.
  - Then EVERY H3 under ## Summary IS A CLAIM, AND EVERY CLAIM IS A
    COMPLETE ASSERTION — subject, verb, and something that can be
    proven wrong. A topic label is a DEFECT: it cannot be verified,
    refuted, or carried into a synthesis.
      GOOD: "Automatic retry is ON by default in <lib> 3 and is
            actively harmful here."
      GOOD: "<tool> was discontinued in March 2025; <successor> is the
            maintained replacement."
      BAD:  "Provider lifecycle" · "Retry behavior" · "Testing"
    Under each H3: "*Confidence: high|medium|low[, **LOAD-BEARING**]*",
    then evidence and reasoning with numbers, versions, dates, and
    exact API names, then its source URLs as bullets. Mark every claim
    a decision RESTS ON as **LOAD-BEARING** — those get fact-checked.
    Target at least <5 standard | 8 premier> claims, of which at least
    3 are LOAD-BEARING.
  - ## Recommendations — "- **[must|should|avoid]** <a concrete
    decision, in the imperative.>" each with a sub-bullet of WHY, tied
    to THIS app's constraints, not to general good practice. These are
    DECISIONS ("set X", "never do Y"), not observations. Banned words
    in this section: "consider", "optionally", "either/or", "you may
    want to" — a hedge here becomes an unmade decision at
    implementation time.
  - ## Sources — mandatory: URL + accessed <YYYY-MM-DD> + one-line
    takeaway, <8–12 | 15–25> entries, adversarial ones marked
    "[adversarial]".
  - END THE FILE with the provenance block of docs/RESEARCH-ARCHIVE.md
    §4: a <details> block titled "The prompt that produced this"
    containing THIS ENTIRE PROMPT, VERBATIM, inside a fenced block —
    no summary, no paraphrase, no "the prompt asked me to". A file
    without its prompt block is incomplete and gets re-spawned.

  Report back: output path, claim count, LOAD-BEARING count, source
  count (and how many adversarial), and the one claim you are least
  sure of — name it, so the fact-checkers get pointed at it. Data, not
  prose.
````

### 5. While the wave runs

**NEVER emit bare text** — a text-only response ends the turn and kills the pipeline. Append to `runs/<run_tag>/temp/orchestrator-notes.md`: which dimensions you expect to contradict each other (the DI framework vs. the state library; CI assuming a monorepo the structure dimension won't create; the testing dimension's harness vs. the persistence dimension's fixtures), and which claims you would bet are version-rotted. Those bets become the critic panel's brief in step 10. One file-existence check per minute max — write your thoughts, don't just poll.

### 6. Validate every `research/` file mechanically

Researchers fail independently. Check each returned file:

- Frontmatter has `run_tag`, `created`, `area: 02-engineering`, `dimension`, `phase: research`; the `> Phase: **research** · Agent … · Run …` line follows the title.
- `## Summary` exists and is a paragraph, not a list.
- **Claim shape.** `rg -n '^### ' research/02-engineering/research/<dim>.md` — every H3 must be a complete assertion. Reject any H3 that is ≤ 4 words, has no verb, or reads as a topic label ("Retry behavior", "Testing"). This is the single most common defect and it silently guts the verify phase, because a topic label cannot be refuted.
- ≥ 5 (standard) / 8 (premier) claims; ≥ 3 marked `**LOAD-BEARING**` (`rg -c 'LOAD-BEARING'`).
- `## Recommendations` exists; every bullet starts `**[must|should|avoid]**`; zero hedge words (`rg -in 'consider|optionally|either/or|you may want to' ` inside that section → any hit means a survey in decision clothing).
- `## Sources` ≥ 8 (standard) / 15 (premier), each URL + access date + takeaway, ≥ 1 `[adversarial]`.
- **Provenance block present and non-empty** (`rg -c 'The prompt that produced this'`) and its body is the actual prompt, not a summary.
- Architecture/structure dimensions only: the Code taxonomy categories are named.

**Partial-failure policy:** re-spawn ONE defective researcher ONCE, with the failed check quoted verbatim in the prompt. If a dimension still fails after its re-spawn, DROP IT and name it in `_INDEX.md` and in the stack-guide's affected section as a known gap — an honest gap beats a fabricated dimension. If more than a third of the dimensions fail twice, stop and report to the user: a stack guide with holes scaffolds a broken app.

### 7. Extract the claims → `runs/<run_tag>/temp/claims-02.json`

`docs/RESEARCH-ARCHIVE.md` §5, steps 1–2. Read EVERY H3 under `## Summary` in every research file — each is one candidate claim. Then SELECT: the claims a decision rests on, plus **every claim carrying a version, price, licence, policy, or API name**. Claims marked `**LOAD-BEARING**` go first. **3–5 per dimension (standard) / 6–10 (premier).**

Write the file with Write (durable state on disk survives a crash mid-verification):

```json
{
  "area": "02-engineering",
  "run_tag": "<run_tag>",
  "gear": "standard",
  "created": "<YYYY-MM-DD>",
  "claims": [
    {
      "id": "C-01",
      "dimension": "<dimension-slug>",
      "claim": "<the H3 heading, VERBATIM>",
      "claim_slug": "<per the slug rule below>",
      "detail": "<the claim's body, verbatim>",
      "sources": ["<url>", "<url>"],
      "confidence": "high|medium|low",
      "load_bearing": true,
      "selected": true,
      "verdict": null,
      "correction": null
    }
  ]
}
```

**CLAIM SLUG** (§3.2): the first ~50 characters of the claim, lowercased, every non-alphanumeric run collapsed to one hyphen, trailing hyphens trimmed. Mid-word truncation is expected — it is an identifier, not a sentence. Compute it, never eyeball it:

```bash
python3 -c "import re,sys; s=sys.argv[1][:50].lower(); print(re.sub(r'-+$','',re.sub(r'[^a-z0-9]+','-',s)))" "<the claim, verbatim>"
```

If two claims in the same dimension slug identically, append `-2`, `-3`. Every unselected claim still gets an entry with `"selected": false` — that record is how `_INDEX.md` and the reusability guide state honestly what was never checked.

**Then apply the AREA VERIFY BUDGET: ≤25 selected claims (standard) / ≤60 (premier), summed across ALL dimensions.** The per-dimension range is what each dimension deserves; the budget is what the area can afford, and it binds. If the per-dimension selection overshoots, rank across the whole area — premises first, then `**LOAD-BEARING**`, then every claim carrying a version, price, licence, policy or exact API name, then whatever step 13/14 would compile against — and keep the highest-ranked until the budget is full. **Never drop a whole dimension to make room:** every dimension keeps at least its top-ranked claim, so no dimension ships entirely unchecked. Everything cut stays in the register with `"selected": false`, and `_INDEX.md` says how many were never checked.

### 8. RUN THE VERIFICATION ENGINE — one `hb-claim-verifier` per selected claim

This is step 3.5's procedure, applied to area 02. **Spawn ONE VERIFIER PER CLAIM, ALL IN PARALLEL, IN ONE MESSAGE.** One agent handed five claims confirms all five — it has no budget to lose an argument with itself. One agent per claim is what makes refutation cheap. If the selection exceeds ~15 claims, send back-to-back messages of ≤ 15 Task calls each — **never collapse claims onto one agent to save spawns.** The total across all batches is the area's `"selected": true` count, which item 7 already capped at the verify budget (≤25 standard / ≤60 premier); if you are about to exceed it, the selection was wrong — go back to item 7 and truncate there, never here.

Use the canonical §6 template VERBATIM in the filled slots; do not improvise a shorter one. Wrap it in the standard spawn-contract header:

```
subagent_type: hb-claim-verifier
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are a step-5 adversarial fact-checker in
  research area 02-engineering of the hyperbuild pipeline. A dimension
  researcher surveyed a whole topic; you have ONE of its claims and a
  mandate to destroy it. Whatever survives you becomes an engineering
  decision in research/02-engineering/author/stack-guide.md, which step
  13 scaffolds from and step 14 writes code against. WHEN A
  FACT-CHECKER DISAGREES WITH A RESEARCHER, THE FACT-CHECKER IS USUALLY
  RIGHT — you check primary sources against one specific claim while
  the researcher was surveying a whole dimension. You write exactly one
  file and you NEVER edit the researcher's.

  FORMAT CONTRACT (BINDING): docs/RESEARCH-ARCHIVE.md §3.2 (your file
  shape and the CLOSED verdict vocabulary) and §4 (the provenance
  rule). Read it before producing anything.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 02-engineering
  - claim_id: <C-NN>
  - output_path:
    research/02-engineering/verify/<dimension>--<claim-slug>.md
  - VERIFIED ENVIRONMENT FACTS (measured on this machine):
    <paste runs/<run_tag>/temp/environment-02.md verbatim>

  READ FIRST: docs/RESEARCH-ARCHIVE.md (§3.2, §4), then
  runs/<run_tag>/idea.md.

  ---

  You are an ADVERSARIAL FACT-CHECKER for the Engineering research
  corpus of <the app, one line>. Today is **<YYYY-MM-DD>**.

  A researcher studying "<dimension>" made this claim, and a project
  decision depends on it.

  CLAIM: <the H3 heading, verbatim>
  DETAIL: <the claim's body, verbatim>
  CLAIMED SOURCES: <the claim's source URLs, comma-separated>
  CONFIDENCE: <high|medium|low>

  REFUTE IT. Use WebSearch and WebFetch against PRIMARY sources: the
  vendor's or maintainer's own documentation, the package registry page
  (for the real current version, publisher, and maintenance status),
  the official API reference (for real signatures), the standards-body
  or store-policy text itself, and the actual GitHub repo (for whether
  it is archived or discontinued). A tutorial, a blog post, an
  aggregator answer, or your own recollection is NOT a primary source.

  The failure modes you are hunting for, in order of likelihood:
  1. **Version rot** — the claim was true two years ago. APIs get
     deprecated and removed, defaults flip, prices change, store
     policies change.
  2. **Dead or abandoned tools presented as alive.** CHECK THE REPO: is
     it archived? When was the last release? Does the registry mark it
     discontinued or deprecated?
  3. **Invented or misremembered API/feature names.** If the claim
     names a method, class, parameter, plan tier, or setting, VERIFY
     THAT EXACT NAME EXISTS in the official reference.
     Plausible-sounding names are a specific hazard here.
  4. **Cargo cult** — one team's practice, or a big-company practice,
     presented as universal when the cited source does not say that.
  5. **Overstated consensus** — "the community recommends X" when it is
     one blog post.

  Default to refuted=true if you cannot independently substantiate it.
  CONFIRMED if it checks out. PARTIALLY_TRUE + a correction if
  directionally right but wrong in specifics (name the exact right
  version/API/number). UNVERIFIABLE if no source settles it — and say
  that plainly rather than guessing.

  Write research/02-engineering/verify/<dimension>--<claim-slug>.md in
  the format of docs/RESEARCH-ARCHIVE.md §3.2, and END THE FILE with
  this prompt verbatim inside the provenance block (§4).
```

**Validate each verify file:** frontmatter carries `phase: verify`, `claim:` (verbatim), and `verdict:` from the CLOSED vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE` — no "mostly true", no percentages, no hedging. Every `PARTIALLY_TRUE` carries a **Correction** that names the exact right version/API/number ("directionally right" is not a correction). Every verdict carries **Evidence** naming WHICH primary source was checked. Provenance block present. Re-spawn a defective verifier ONCE; a verifier that returns no file leaves its claim `"verdict": "UNVERIFIABLE"` with `"note": "verifier failed"`.

**Every verifier writes its file whatever the verdict.** The REFUTED files are the most valuable ones in the archive.

### 9. Fold the verdicts back into `claims-02.json`

Edit each claim's `verdict` and `correction` from its verify file. This JSON is now the authority the synthesis reads in step 12 — it is what makes "may only rest on surviving claims" mechanically checkable rather than a good intention.

**DO NOT EDIT THE `research/` FILES.** §7: a refuted claim's research file is the honest record of what one surveying agent believed, and rewriting it destroys the evidence that verification works. (This replaces the old step-5 "back-propagate the losing decision into the losing doc" rule, which is now a violation.) The correction lives in `verify/` and is APPLIED in `author/`.

### 10. The critique panel — `hb-corpus-critic`, all in ONE message

Critics read the WHOLE area corpus and hunt the defect class no single-claim fact-check can see: **contradictions BETWEEN dimensions** — three dimensions each shipping a different, internally consistent API for one tool; a testing dimension whose harness the persistence dimension's fixtures cannot use; a CI dimension building a layout the structure dimension never created.

**STANDARD — 3 critics. PREMIER — 5.** (Area 02's deliberate exception to the 2 / 3 the other three areas run — see the note under Gear knobs.)

| Critic name | Its question |
|---|---|
| `contradiction-hunter` | Where do two dimensions commit to incompatible things? Read every `## Recommendations` side by side and list every pair that cannot both be true. (standard) |
| `skeptic-staff-engineer` | Which of these recommendations is over-engineered for THIS app's scale, and which would a staff engineer refuse in review? Ceremony that costs a solo developer a week. (standard) |
| `completeness-critic` | What did all N dimensions collectively fail to cover? The concern the fan-out designed away — the thing no dimension owned. (standard) |
| `test-engineer-review` | Is the testing story actually EXECUTABLE on this platform with the measured toolchain, end to end, or does it assume a harness/runner/API that the persistence and UI dimensions contradict? (premier) |
| `dependency-risk-critic` | Across every package recommended anywhere in this area: archived? single-maintainer? licence incompatible with shipping? version pins that conflict with each other or with the measured SDK? (premier) |

Spawn template:

```
subagent_type: hb-corpus-critic
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are the `<critic-name>` critic of research area
  02-engineering in the hyperbuild pipeline. The research phase
  (<N> dimensions) and the verification phase (<M> per-claim
  fact-checks) are complete; you are the LAST pass before the
  orchestrator authors research/02-engineering/author/stack-guide.md,
  the guide step 13 scaffolds from, step 14 implements by, and the
  step-15 code critic enforces. Per-claim fact-checkers each saw ONE
  claim; you see the whole corpus, so you are the only agent that can
  catch a contradiction BETWEEN dimensions. You NEVER edit another
  agent's file — you write exactly one file, your own.

  FORMAT CONTRACT (BINDING): docs/RESEARCH-ARCHIVE.md §3.3 (critique
  files) and §4 (the provenance rule). Read it before producing
  anything.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 02-engineering
  - critic: <critic-name>
  - output_path: research/02-engineering/critique/<critic-name>.md
  - your question: <the row from the critic table, verbatim>
  - orchestrator's suspicions (leads, not conclusions — confirm or kill
    each): <the merge hypotheses from temp/orchestrator-notes.md>

  READ FIRST (all of it — you are the corpus reader):
  - docs/RESEARCH-ARCHIVE.md (§3.3, §4)
  - runs/<run_tag>/idea.md
  - research/product-spec.md and features/00-index.md (scale — most
    over-engineering findings are scale findings)
  - EVERY research/02-engineering/research/*.md
  - EVERY research/02-engineering/verify/*.md — the verdicts OVERRIDE
    the research files. A research file's claim that was REFUTED is not
    evidence; do not build a finding on it, and DO flag any
    recommendation that still rests on one.
  - runs/<run_tag>/temp/dimensions-02.md — what was dropped and why;
    a dropped dimension is a legitimate completeness finding only if
    the drop reason is wrong.

  OUTPUT: frontmatter run_tag, created, area: 02-engineering,
  phase: critique, critic: <critic-name>; the title and provenance
  line; then your own body structure. THE ONE STRUCTURAL REQUIREMENT:
  every finding is tagged `[VERIFIED]` (you actually read the file, ran
  the command, or fetched the source — say which) or `[OPEN]` (you
  reasoned about it but did not confirm). An untagged finding is a
  defect. Rank findings by what they would cost if shipped into
  step 14. For each contradiction, name BOTH files and quote BOTH
  lines. END THE FILE with this prompt verbatim inside the provenance
  block (§4).
```

**While the critics run:** keep writing to `runs/<run_tag>/temp/orchestrator-notes.md` — never bare text.

### 11. Write `_INDEX.md`

`research/02-engineering/_INDEX.md`, per §3.4. ALL FOUR PHASES APPEAR, every agent under its phase, with its file size — size is the cheap signal that an agent returned a stub. Compute sizes, never estimate:

Write it now (it is the map you author the guide from), then RE-RUN the size command after step 12 and fill in the `author/stack-guide.md` row — the only row that cannot exist yet.

```bash
for f in research/02-engineering/research/*.md research/02-engineering/verify/*.md \
         research/02-engineering/critique/*.md research/02-engineering/author/*.md; do
  printf '%s — %s chars\n' "$f" "$(wc -c < "$f" | tr -d ' ')"
done
```

```markdown
# Engineering — <platform>

`<run_tag>` · **<N> agents** · every agent's result + the prompt that produced it.
Methodology: [docs/RESEARCH-ARCHIVE.md](../../docs/RESEARCH-ARCHIVE.md) — the phase
structure, the claim→verify mechanism, and the verifier prompt template.

Platform: <platform one-liner>. Area name is deliberately platform-neutral so a later
checkout can copy this directory in unchanged.

**`research/` is UNVERIFIED by construction; `verify/` OVERRIDES it.** Read `research/`
for breadth, then check `verify/` before trusting any version, price, licence, API name,
or policy. Refuted claims were NOT deleted from `research/` — the correction lives in
`verify/` and is applied in `author/stack-guide.md`.

## research (<n>)  — one agent per dimension, independent web research
- [<dimension>](research/<dimension>.md) — <N,NNN> chars
## verify (<n>)  — one fact-checker per load-bearing claim, each told to *refute* it
- [<dimension>--<claim-slug>](verify/<dimension>--<claim-slug>.md) — <N,NNN> chars — **<VERDICT>**
## critique (<n>)  — cross-cutting critics
- [<critic-name>](critique/<critic-name>.md) — <N,NNN> chars
## author (<n>)  — the synthesis
- [stack-guide](author/stack-guide.md) — <N,NNN> chars

## Verdict tally
CONFIRMED <n> · PARTIALLY_TRUE <n> · REFUTED <n> · UNVERIFIABLE <n>
of <total> claims extracted; <k> were NOT selected for verification and were NOT checked.

## Unverified
- <claim> — <dimension> — <why: verify budget, topic-label defect, or two failed verifier spawns>

## Dimension derivation
Base set adapted per docs/RESEARCH-ARCHIVE.md consumers — kept / renamed / dropped /
merged / added, one line each. Dropped: <dimension> — <why>. (Full record:
runs/<run_tag>/temp/dimensions-02.md.)
```

`_INDEX.md` is an index, not a research file — it takes no provenance block.

### 12. Author `research/02-engineering/author/stack-guide.md` — LAST, and only on survivors

**THE SYNTHESIS RULE (§7) IS THE POINT OF THIS ENTIRE STEP.** You write this file yourself, after everything above exists. Apply the verdicts mechanically from `claims-02.json`:

- **REFUTED** — MUST NOT appear as fact anywhere downstream. The decision that rested on it is re-derived from surviving claims or DROPPED. It goes in `## Refuted by verification`, never silently deleted.
- **PARTIALLY_TRUE** — the CORRECTED version ships; the original phrasing does not survive into the guide. Cite the verify file so a reader sees where the correction came from.
- **UNVERIFIABLE** — usable only when labelled unverified, and NEVER the sole support for a `must`-level decision.
- **CONFIRMED** — usable as written.
- **Unverified** (never selected) — usable, but the guide MUST NOT present an unverified version, price, licence, or policy as fact.

Then resolve the critics' contradictions HERE — in the synthesis, not by editing research files. Rank by (a) verdict strength (a CONFIRMED claim beats an unverified one, always), (b) strength of cited evidence, (c) fit with the PRD's scale, (d) simplicity. Record each resolution in `## Conflicts resolved`.

**Citation form — every decision bullet carries its provenance:**

```
- We will <decision>. (<one clause of why> — research/<dimension>.md · verify/<dimension>--<slug>.md **CONFIRMED**)
- We will <corrected decision>. (<why> — research/<dimension>.md · verify/<dimension>--<slug>.md **PARTIALLY_TRUE**, corrected: <the correction>)
- We will <decision>. (<why> — research/<dimension>.md, unverified)
```

Paths are relative to the area root (`research/02-engineering/`), so the guide reads correctly from inside its own directory.

Skeleton:

````markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
area: 02-engineering
phase: author
step: 5
platform: <platform one-liner>
---
# Stack guide — <platform>

> Phase: **author** · Orchestrator (step 5) · Run `<run_tag>`

Committed engineering decisions for this app. Steps 10, 13, and 14 follow this guide;
the step-15 code critic treats deviations as findings. Rationale and rejected
alternatives live in `../research/`; every verified claim's evidence is in `../verify/`.

Every decision below rests on a claim that survived verification, or is labelled
unverified. Nothing here rests on a REFUTED claim — those are listed at the bottom.

## Architecture
- We will <decision>. (<why> — research/<dim>.md · verify/<dim>--<slug>.md **CONFIRMED**)

## Project structure & state management
- We will <decision>. (...)

## Code taxonomy
The project's named code categories and placement rules — the platform's analogue of
Rails' models / views / controllers / concerns / services / apis. Merge the
architecture dimension's category list (what kinds of code exist) with the structure
dimension's placement rules (where each kind lives). REQUIRED — a stack guide without
this section is defective.

| Category | What belongs in it | Where it lives |
|----------|--------------------|----------------|
| <name> | <one line> | <path pattern under app/> |

One-second rule: a reader with a new file in hand answers "where does this belong?"
from this table alone. Step 11 tasks name the category their files belong to; step 14
implementers place code by it.

## Language idioms & coding standards
- We will <decision>. (...)

## Error handling
- We will <decision>. (...)

## Testing strategy
- We will <decision>. (...)

## Tooling, lint & CI
- We will <decision>. (...)

## Performance budget
- We will <decision>, measured by <the command from the research>. (...)

## <one section per remaining dimension>

## Conflicts resolved
- <dimension A> recommended <X>, <dimension B> recommended <Y> → chose <winner>
  because <one line>; found by critique/<critic>.md.
(Write "None." if there were none.)

## Refuted by verification
Claims a researcher made that the fact-checkers destroyed, and what this guide does
instead. Recorded, never deleted — a deleted refutation gets innocently re-derived by
the next run.

| Claim (verbatim) | Dimension | Verify file | What we do instead |
|---|---|---|---|
| <claim> | <dimension> | verify/<dim>--<slug>.md | <the re-derived decision, or "dropped"> |

## Known gaps
- <dimension that failed twice and was dropped, or a concern no dimension owned per
  critique/completeness-critic.md> — named honestly, never silently thin.

<details>
<summary>The prompt that produced this</summary>

```
Authored by the step-5 orchestrator via Skill(skill: "hyperbuild-5-stack-research"),
procedure item 12, on <YYYY-MM-DD>.
Inputs: runs/<run_tag>/idea.md · research/product-spec.md · features/00-index.md ·
runs/<run_tag>/temp/dimensions-02.md · runs/<run_tag>/temp/environment-02.md ·
runs/<run_tag>/temp/claims-02.json · every research/02-engineering/research/*.md ·
every verify/*.md · every critique/*.md.
Rule applied: docs/RESEARCH-ARCHIVE.md §7 — the synthesis may only rest on claims that
survived verification; REFUTED claims are recorded in "## Refuted by verification" and
never presented as fact; PARTIALLY_TRUE claims ship corrected; UNVERIFIABLE claims are
labelled and never sole support for a must-level decision.
```

</details>
````

Every bullet is imperative and self-contained — step 10's skill-smiths quote these lines into project skills verbatim, so a vague line here becomes a vague rule the implementers follow forever. The hedge-word ban applies to the guide.

**Self-check before you finish** — grep the guide against `claims-02.json`: no claim whose `verdict` is `REFUTED` appears outside the `## Refuted by verification` table; every `PARTIALLY_TRUE` claim referenced carries its correction; no unverified version/price/licence/policy string is stated as fact. Then re-run the size command from item 11 and fill the `author/stack-guide.md` row in `_INDEX.md`.

---

## Artifacts

- `research/02-engineering/research/<dimension>.md` — one per dimension, §3.1 format, claims-as-assertions + `## Sources` + provenance block
- `research/02-engineering/verify/<dimension>--<claim-slug>.md` — one per selected claim, §3.2 format, closed verdict vocabulary
- `research/02-engineering/critique/<critic-name>.md` — 3 (standard) / 5 (premier), §3.3 format, every finding `[VERIFIED]`/`[OPEN]`
- `research/02-engineering/author/stack-guide.md` — the synthesis; the ONLY file downstream steps must read
- `research/02-engineering/_INDEX.md` — all four phases, every agent, file sizes, verdict tally, `## Unverified`, dimension derivation
- `research/harvest/` — clones + the harvest log, appended by the DISCOVER sweep and every researcher
- `runs/<run_tag>/temp/environment-02.md`, `dimensions-02.md`, `claims-02.json` — the run-local working record

---

## Exit criteria

- `research/02-engineering/` exists with all four phase directories populated and `_INDEX.md` listing every agent under its phase with real file sizes
- Dimension count within gear (6–8 standard / 10–14 premier); the derivation is recorded; **at least one dimension came from ADD, not the base set**; every dropped base dimension is named with its reason
- Every `research/` file: valid frontmatter (`area: 02-engineering`, `phase: research`), ≥5/≥8 claims that are complete assertions (no topic labels), ≥3 LOAD-BEARING, `## Recommendations` with zero hedge words, ≥8/≥15 sources incl. ≥1 adversarial, **and a provenance block containing its verbatim prompt**
- `claims-02.json` exists; 3–5 (standard) / 6–10 (premier) claims selected per dimension, with the area total inside the verify budget (≤25 standard / ≤60 premier) and every dimension keeping at least one selected claim; every selected claim has a `verify/` file with a verdict from the CLOSED vocabulary; every `PARTIALLY_TRUE` carries a concrete correction
- `_INDEX.md` has a `## Unverified` section naming every claim that never got a verdict and why (budget, topic-label defect, or two failed spawns) — a verifier that failed twice leaves `"verdict": "UNVERIFIABLE"` in the register and a line here, never silence
- No `research/` file was edited after the fact — refutations live in `verify/` and are applied in `author/`
- 3 (standard) / 5 (premier) critique files exist, every finding tagged `[VERIFIED]` or `[OPEN]`
- `author/stack-guide.md` exists at `research/02-engineering/author/stack-guide.md`; every decision bullet cites its research file and, where the claim was verified, the verdict; zero hedge words
- The guide has a `## Code taxonomy` section: named code categories with placement rules, derived from the architecture + structure research (not a generic template), answering "where does this belong?" in one second
- The guide has a `## Refuted by verification` section (or an explicit "None." — there were no refutations), and NO refuted claim appears as fact anywhere in it
- Gaps are named honestly under `## Known gaps` — never silently thin

Then update the manifest: `steps.5 = "done"`, mark the step-5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Invoke step 6:

```
Skill(skill: "hyperbuild-6-design-research")
```

Step 6 builds area `03-design-system/` the same way — it reads the PRD, the feature specs, and the platform decision, not the stack guide; the guide next matters at step 10 (skill forge), which reads `research/02-engineering/author/stack-guide.md`.
