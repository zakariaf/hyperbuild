---
name: hyperbuild-5-stack-research
description: >
  Step 5 of the hyperbuild pipeline — spawns 4 parallel hb-stack-researcher
  subagents (architecture / project structure + state management / testing
  strategy / tooling + CI + lint) to deep-research best practices for the
  platform chosen in step 1, 8–12 sources per topic (standard) / 15–25
  (premier), then merges the four topic docs into research/stack-guide.md —
  a committed "we will do X" guide, not a survey. Steps 10, 13, 14 build by
  it and the step-15 code critic enforces it. Invoked by the hyperbuild
  router via Skill(); not run directly by users.
---

# Step 5 — Stack research (parallel, 4 researchers)

You are executing step 5 (stack-research) of the hyperbuild pipeline. Steps 4 and 4.5 fixed WHAT to build (the PRD + feature specs); this step fixes HOW to build it — step 10 forges the project skills from the stack guide, step 13 scaffolds by it, step 14 implements by it, and step 15's `hb-code-critic` treats deviations from it as findings.

**Goal:** 4 topic docs under `research/stack/` + a merged `research/stack-guide.md`, every doc ending in committed "we will do X" decisions.

**Why decisions, not surveys:** a survey ("popular options include Riverpod, Bloc, and Provider...") pushes the choice downstream to step 14, where six parallel implementers each choose differently and the codebase becomes four state-management libraries in a trench coat. Every choice gets made HERE, once, with evidence.

---

## Inputs

Read these before doing anything:

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear` (standard | premier); confirm `steps["4.5"]` is `done`
- `runs/<run_tag>/decisions/platform.md` — the chosen platform/stack + rationale. **This is the stack you research. Not the trendiest one, not your favorite one — the one step 1 committed to.**
- `research/product-spec.md` — skim: feature count, screen count, and offline/sync/auth needs shape which architecture is right-sized

---

## Procedure

1. **Fix the four topic assignments.** These are structural constants — always 4 researchers, always these files:

   | topic_id | Output file | Scope |
   |----------|-------------|-------|
   | `architecture` | `research/stack/architecture.md` | App architecture for this platform: layering pattern, navigation/routing, dependency injection, error handling, data flow, offline/persistence approach, AND the kinds of code the chosen architecture implies (its named code categories — input to the stack-guide's Code taxonomy) |
   | `structure` | `research/stack/structure.md` | Project/folder structure, module boundaries, naming conventions, the state-management choice (library + patterns), AND where each of the architecture's code categories lives (placement rules — input to the stack-guide's Code taxonomy) |
   | `testing` | `research/stack/testing.md` | Testing strategy: the platform's test pyramid (unit / component-or-widget / integration / e2e), what to cover and what not to, mocking approach, test data, coverage bar |
   | `tooling-ci` | `research/stack/tooling-ci.md` | Formatter, linter + specific rule set, static analysis, pre-commit hooks, CI pipeline shape, build/release commands |

2. **Spawn 4 `hb-stack-researcher` subagents in ONE message** — all four Task calls together, true parallel execution. Each researcher gets ONLY its topic. Zero overlap: the `structure` researcher owns state management; the `architecture` researcher references that choice as an open input rather than making it. Spawn template (fill per topic from the table above):

   ```
   subagent_type: hb-stack-researcher
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 5 (stack researcher, topic:
     <topic_id>) of the hyperbuild pipeline. Step 1 chose the platform —
     read runs/<run_tag>/decisions/platform.md and research THAT stack.
     Three sibling researchers are covering the other topics in parallel
     (architecture / structure+state / testing / tooling-ci); stay strictly
     inside your topic. After all four return, the orchestrator merges your
     ## Decisions section into research/stack-guide.md, which step 10 turns
     into project-specific Claude Code skills, step 13 scaffolds the app
     from, step 14 implements by, and the step-15 code critic enforces.
     A hedge you write today becomes an inconsistency in the codebase.

     YOUR INPUTS:
     - run_tag: <run_tag>
     - topic: <topic_id> — <the one-line Scope from the table>
     - output_path: <output file from the table>
     - source_target: 8–12 sources (standard) / 15–25 (premier) — gear for
       this run is <gear>, so target <the matching range>
     - platform: <one line pasted from decisions/platform.md, e.g.
       "Flutter (Dart), mobile-first, iOS + Android">

     READ FIRST (context files, in this order):
     - runs/<run_tag>/idea.md
     - runs/<run_tag>/decisions/platform.md
     - research/product-spec.md (skim — feature scale, screen count, and
       offline/auth needs are inputs to right-sizing your decisions)

     RESEARCH RULES:
     - HARVEST-FIRST: before any blank-page web research, search GitHub
       for authoritative repos on your topic (official org style guides,
       high-star best-practices repos, awesome-lists — WebSearch with
       site:github.com). Vet each candidate (meaningful stars, commits
       within ~12-18 months, authoritative origin); log EVERY candidate
       — kept or rejected, with reason — in
       research/harvest/harvest-log.md (repo URL, stars, last-commit
       date, license, verdict); shallow-clone keepers via Bash:
       git clone --depth 1 <url> research/harvest/<topic>/<repo>/.
       License rule: MIT/Apache/BSD/CC — adapt with attribution in your
       Sources; GPL/AGPL/unlicensed — learn and cite, never copy.
       Harvested repos count toward your source target. Only then
       GAP-FILL with web research for what is missing, stale (>18
       months), or contradicted across harvested sources.
     - Recency rule: prioritize sources from the last 18 months. Any
       version or feature claim MUST cite a dated source — "as of <lib>
       vX.Y (<month year>)".
     - MANDATORY adversarial searches: at least one per serious option you
       evaluate — "<X> criticism", "<X> problems", "why I stopped using
       <X>". A recommendation that has never been attacked is not a
       recommendation.
     - Source quality ladder: official docs and release notes first, then
       maintainer/practitioner post-mortems and migration stories, then
       tutorials; marketing pages last and never as sole support.
     - CODE TAXONOMY (topics `architecture` and `structure` ONLY): your
       ## Decisions MUST name the project's code categories — the
       platform's analogue of Rails' models / views / controllers /
       concerns / services / apis. `architecture` names WHAT kinds of
       code exist under its chosen pattern; `structure` names WHERE
       each kind lives (directory + naming rule). The categories come
       from YOUR research — they differ per platform and architecture;
       HAVING named categories is non-negotiable. A generic copy of
       Rails' list is a defect unless the research genuinely lands there.
     - COMMIT. Your doc MUST end with a ## Decisions section of "We will
       do X because Y" statements covering every concern in your scope. A
       survey with no verdicts is a defective artifact and will be
       re-spawned. Right-size to THIS app: a 12-screen v1 does not need
       the architecture of a 400-screen bank.

     OUTPUT FORMAT — write to output_path exactly this shape:

     ---
     run_tag: <run_tag>
     created: <YYYY-MM-DD>
     step: 5
     topic: <topic_id>
     platform: <platform one-liner>
     ---

     # Stack research — <topic>

     ## Landscape
     The 2–4 realistic options for each concern in scope, one paragraph
     each, INCLUDING the adversarial findings against each (what the
     criticism searches surfaced, cited).

     ## Decisions
     - **We will <decision>.** Because <evidence, cited>. Rejected:
       <alternative> — <the criticism that killed it, cited>.
     (One bullet per concern in your scope. No "consider", no "either/or".)

     ## Consequences for this app
     How the decisions map onto this PRD's screens and features — 3–6
     bullets, concrete.

     ## Sources
     - <URL> — accessed <YYYY-MM-DD> — <one-line takeaway>
     (8–12 standard / 15–25 premier; mark adversarial sources with
     "[adversarial]".)

     Report back: output path, decision count, source count (and how many
     adversarial), and the single most consequential decision. Data, not
     prose.
   ```

   **⚠ If you find yourself about to research these topics yourself instead of spawning 4 researchers, STOP.** Four topics researched serially in one context produces one exhausted context and four shallow docs. Spawn the researchers.

3. **While the researchers run: NEVER emit bare text** — a text-only response ends the turn and kills the pipeline. Append merge hypotheses (where you expect the topic docs to conflict, e.g. DI framework vs. state library) to `runs/<run_tag>/temp/orchestrator-notes.md`. One file-existence check per minute max — write your thoughts, don't just poll.

4. **Wait for all 4. Partial-failure policy:** researchers can fail independently. If one topic doc is missing or defective, re-spawn that ONE researcher ONCE with the missing requirement stated explicitly in the prompt. If ≥2 topics are still missing after re-spawns, stop and report to the user — a stack guide with holes scaffolds a broken app.

5. **Validate each topic doc mechanically:**
   - Frontmatter has `run_tag`, `created`, `step: 5`, `topic`, `platform`
   - `## Decisions` exists, every bullet starts "We will", covers every concern in the topic's Scope cell
   - `## Sources` has ≥8 entries (standard) / ≥15 (premier), each with URL + access date + takeaway, ≥1 marked `[adversarial]`
   - `architecture` and `structure` docs only: Decisions name the code categories per the CODE TAXONOMY rule (architecture: what kinds of code exist; structure: where each kind lives)
   - No hedge words in Decisions: "consider", "optionally", "either", "you may want to" — any hit means the doc is a survey in decision clothing; re-spawn per step 4's policy

   **INVARIANT:** every topic doc ends in committed decisions. A doc ending with a comparison table and no verdicts is defective — re-spawn that researcher with the COMMIT rule emphasized.

6. **Reconcile cross-topic conflicts.** Read all four `## Decisions` sections side by side. Where two docs commit to incompatible choices (architecture assumed Bloc, structure chose Riverpod; CI assumes a monorepo the structure doc didn't create), YOU decide the winner — rank by (a) strength of cited evidence, (b) fit with the PRD's scale, (c) simplicity. Then **back-propagate: Edit the losing doc's Decisions bullet to match**, so no vault artifact contradicts another. Record every resolution for the guide's `## Conflicts resolved` section.

7. **Write `research/stack-guide.md` yourself.** Decisions only — rationale detail stays in the topic docs. Skeleton:

   ```markdown
   ---
   run_tag: <run_tag>
   created: <YYYY-MM-DD>
   step: 5
   platform: <platform one-liner>
   ---

   # Stack guide — <platform>

   Committed engineering decisions for this app. Steps 10, 13, and 14
   follow this guide; the step-15 code critic treats deviations as
   findings. Rationale and rejected alternatives live in the four topic
   docs under research/stack/.

   ## Architecture
   - We will <decision>. (<one clause of why> — research/stack/architecture.md)

   ## Project structure & state management
   - We will <decision>. (... — research/stack/structure.md)

   ## Code taxonomy
   The project's named code categories and placement rules — the
   platform's analogue of Rails' models / views / controllers /
   concerns / services / apis. Merge the architecture doc's category
   list (what kinds of code exist) with the structure doc's placement
   rules (where each kind lives). REQUIRED — a stack-guide without
   this section is defective.

   | Category | What belongs in it | Where it lives |
   |----------|--------------------|----------------|
   | <name> | <one line> | <path pattern under app/> |

   One-second rule: a reader with a new file in hand answers "where
   does this belong?" from this table alone. Step 11 tasks name the
   category their files belong to; step 14 implementers place code
   by it.

   ## Testing strategy
   - We will <decision>. (... — research/stack/testing.md)

   ## Tooling, CI & lint
   - We will <decision>. (... — research/stack/tooling-ci.md)

   ## Conflicts resolved
   - <topic A> wanted <X>, <topic B> wanted <Y> → chose <winner> because
     <one line>; losing doc edited to match.
   (Write "None." if there were none.)
   ```

   Every bullet is imperative and self-contained — step 10's skill-smiths will quote these lines into project skills verbatim, so a vague line here becomes a vague rule the implementers follow forever. The same hedge-word ban from step 5 applies to the guide.

---

## Artifacts

- `research/stack/architecture.md`, `research/stack/structure.md`, `research/stack/testing.md`, `research/stack/tooling-ci.md` — one per researcher, format above
- `research/stack-guide.md` — orchestrator-merged, decisions only, frontmatter `run_tag` + `created`

---

## Exit criteria

- All 4 topic docs exist with valid frontmatter, "We will"-only Decisions covering their full Scope, and ≥8 (standard) / ≥15 (premier) sources each incl. ≥1 adversarial
- `research/stack-guide.md` exists; every decision bullet cites its topic doc; zero hedge words
- The guide has a `## Code taxonomy` section: named code categories with placement rules, derived from the architecture + structure docs (from the research, not a generic template), answering "where does this belong?" in one second
- No contradiction between the guide and any topic doc (conflicts resolved AND back-propagated)
- If a researcher failed twice, the gap is named honestly in the guide under the affected section — never silently thin

Then update manifest: `steps.5 = done`, mark the step-5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Invoke step 6:

```
Skill(skill: "hyperbuild-6-design-research")
```

Step 6 proposes the 3 named design directions — it reads the PRD and platform decision, not the stack guide; the guide next matters at step 10 (skill forge).
