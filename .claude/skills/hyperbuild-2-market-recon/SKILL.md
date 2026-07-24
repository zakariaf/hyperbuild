---
name: hyperbuild-2-market-recon
description: >
  Step 2 of the hyperbuild pipeline — competitor recon. Spawns ONE
  hb-competitor-scout to discover and rank the competitor set, then a
  parallel wave of hb-competitor-analyst subagents (one per curated
  competitor: 6–8 standard, 12–15 premier) that each write a dossier to
  research/competitors/<slug>.md covering latest version, feature set,
  changelog cadence, pricing, and store ratings. The orchestrator merges
  dossiers into research/competitor-landscape.md with a feature matrix.
  Runs concurrently with step 3 as the 2 ∥ 3 pair; step 3.5 audits
  these artifacts before step 4 builds the PRD on them. Invoked by the
  hyperbuild router via Skill(); not run directly by users.
---

# Step 2 — Market recon (1 scout, then parallel analysts)

You are executing step 2 (market recon) of the hyperbuild pipeline. Step 1 persisted the gospel idea and resolved the platform. Step 3 (social mining) runs CONCURRENTLY with you as the 2 ∥ 3 pair — the router drives both steps' spawn waves in the same block; your scout shortlist and landscape seed its searches as they land. Your shared successor is step 3.5 (research audit), which starts only after BOTH members of the pair are done and adversarially attacks your landscape before step 4 merges it into the PRD — every must/should feature there must trace to competitor evidence or user demand, so thin dossiers here become an unsupported PRD there.

**Gear gate:** runs for both gears. `standard`: 6–8 competitors, 5–8 sources per dossier. `premier`: 12–15 competitors, 10–15 sources per dossier. Read `gear` from the manifest before choosing counts.

**Goal:** a ranked competitor landscape with one evidence-dense dossier per competitor — current version, full feature inventory, changelog mining, pricing, store ratings — plus a cross-competitor feature matrix that shows table stakes vs whitespace.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim idea (GOSPEL)
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`
- `runs/<run_tag>/decisions/platform.md` — the platform decision + rationale
- `runs/<run_tag>/scaffold.md` — "Competitor guesses" seeds for the scout

Set `steps.2 = "running"` in the manifest, mark the step-2 todo in_progress, then `mkdir -p research/competitors runs/<run_tag>/temp`.

---

## Procedure

### 2.1 — Spawn ONE hb-competitor-scout

Discovery is one spawn, always. The scout overshoots (finds ~12 candidates for standard, ~20 for premier) so YOU can curate down.

```
subagent_type: hb-competitor-scout
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon — competitor discovery)
  of the hyperbuild pipeline. Step 1 resolved the target platform. After
  you return, the orchestrator curates your ranked list down to
  <6–8 standard | 12–15 premier> competitors and spawns one
  hb-competitor-analyst per competitor; their dossiers feed the PRD in
  step 4. You discover and rank — you do NOT write dossiers.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - platform: <platform slug from manifest>
  - candidate_target: <12 for standard | 20 for premier> ranked candidates
  - seed_guesses: [<competitor guesses from scaffold.md, may be empty>]
  - output_path: runs/<run_tag>/temp/competitor-shortlist.md

  CONTEXT FILES (read these first):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
```

The scout's shortlist gives, per candidate: name, homepage URL, store URLs (App Store / Google Play / marketplace where applicable), platforms, latest version if spotted, one-line positioning, relevance rationale, rank. Discovery MUST include "best alternatives to X" and "X vs Y" searches — alternative-roundup pages are the densest competitor-discovery sources on the web.

### 2.2 — Curate the competitor list

From the shortlist, pick the final set: **6–8 for standard, 12–15 for premier**. Curation rules:

- Majority direct competitors (same job-to-be-done, same audience); include 1–2 adjacent or aspirational products whose features users will compare against.
- Prefer actively maintained products (a release within 18 months). Include at most ONE dead/legacy product, and only if it still dominates search results for this category — its abandonment is itself market evidence.
- Assign each a slug: lowercase hyphenated product name (`streaks`, `loop-habit-tracker`).
- **Dossier reuse (vault rule):** before spawning an analyst, check `research/competitors/<slug>.md`. If a dossier already exists and its `created` date is within 90 days, REUSE it — skip that spawn and mark it "(reused)" in the landscape. Older than 90 days: re-spawn to refresh.

Record the curated list (slug, name, rank, reused?) in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 2.3 — Spawn the analyst wave (parallel, ONE message)

Spawn **one `hb-competitor-analyst` per non-reused competitor, all in ONE message** — true parallel execution. That is 6–8 Task calls for standard, 12–15 for premier. Zero overlap: each analyst gets exactly one competitor.

```
subagent_type: hb-competitor-analyst
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon — competitor analyst) of
  the hyperbuild pipeline. The hb-competitor-scout discovered the set; the
  orchestrator assigned you exactly ONE competitor. Other analysts are
  covering the others in parallel — do NOT research any competitor but
  yours. After you return, the orchestrator merges all dossiers into
  research/competitor-landscape.md, and step 4 traces PRD features to
  your dossier. Your dossier is evidence; weak evidence becomes an
  unsupported PRD.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - competitor: <name>
  - slug: <slug>
  - homepage: <URL from the shortlist>
  - store_urls: [<store URLs from the shortlist, may be empty>]
  - source_budget: <5–8 standard | 10–15 premier> distinct sources
  - output_path: research/competitors/<slug>.md

  CONTEXT FILES (read these first):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - runs/<run_tag>/temp/competitor-shortlist.md (your competitor's row only)

  Dossier requirements (all mandatory): latest version + its release date
  from a dated source; full feature inventory; changelog mining (release
  cadence + notable releases of the last 18 months); pricing; store
  ratings with rating counts; at least ONE adversarial search
  ("<competitor> problems", "<competitor> review negative", "why I
  stopped using <competitor>"); a ## Sources section (URL + access date +
  one-line takeaway per source). Version/feature claims MUST cite a dated
  source. Prioritize sources from the last 18 months.
```

**CRITICAL: never emit bare text while analysts are in flight.** A text-only response ends the turn and kills the pipeline. While waiting, append evolving thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` (emerging table stakes, whitespace hypotheses, which axes will split the positioning map) with Edit/Write every 30–60 seconds.

**Partial failure policy:** if an analyst returns nothing or its dossier is missing, re-spawn it ONCE with the output path restated as its explicit required deliverable. If it fails twice, drop that competitor, note the gap in the landscape's "Coverage gaps" line, and proceed — but if the surviving dossier count falls below the gear minimum (6 standard / 12 premier), spawn analysts for the next-ranked shortlist candidates to backfill.

### 2.4 — Write `research/competitor-landscape.md` (orchestrator, after ALL dossiers land)

Read every dossier end to end, then write the landscape yourself:

1. **The set (ranked)** — table: rank, name, slug, latest version + date, platforms, price model, store rating, one-line positioning.
2. **Feature matrix** — rows = every distinct feature found across dossiers (deduplicate names), columns = competitors, cells = `Y` / `N` / `~` (partial, footnote why). Wide tables are fine in markdown.
3. **Positioning map** — pick the TWO axes that best split this market (e.g. simple↔power-user, free↔premium) and place every competitor in a textual 2×2.
4. **Pricing landscape** — models present, price points, where the market clusters.
5. **Table stakes vs differentiators** — table stakes = features in ≥70% of the set (the app MUST have these or justify absence); differentiators = features 1–2 competitors use as their wedge.
6. **Whitespace & opportunities** — what NOBODY does well, judged strictly against the verbatim idea.
7. **Coverage gaps** — competitors dropped after two failed spawns, thin dossiers, anything step 4 should distrust.
8. **Sources** — the dossier files consulted, plus any URLs you consulted directly (URL + access date + one-line takeaway).

Every claim in the landscape must trace to a dossier — the landscape SYNTHESIZES, it never introduces un-dossiered facts.

---

## Artifacts

**`research/competitors/<slug>.md`** — one per competitor, written by its analyst:

```markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
competitor: Streaks
slug: streaks
homepage: https://streaksapp.com
latest_version: "9.2"
version_date: 2026-05-14
platforms: [ios, watchos]
price_model: paid-upfront
store_rating: "4.8 (App Store, 21.4K ratings)"
---

# Streaks — competitor dossier

## Snapshot            <!-- 5-line summary: what it is, who for, why it wins -->
## Feature inventory   <!-- table: Feature | Details | Since version (if dated) -->
## Changelog mining    <!-- release cadence (releases/yr) + table of last-18-months
                            notable releases: version | date | highlights | source -->
## Pricing             <!-- model, price points, what's paywalled -->
## Positioning & audience
## Store ratings & review themes  <!-- rating + count per store; recurring themes -->
## Strengths / weaknesses         <!-- incl. adversarial-search findings -->
## Relevance to our idea          <!-- judged against the verbatim idea only -->
## Sources             <!-- one line per source: URL — accessed YYYY-MM-DD — takeaway -->
```

**`research/competitor-landscape.md`** — frontmatter `run_tag`, `created`, `competitor_count`; sections listed in 2.4. Both artifact types live in the top-level research vault (NOT under runs/) so later runs reuse them.

---

## Exit criteria

- Curated set size within gear range (6–8 standard / 12–15 premier), counting reused dossiers
- One `research/competitors/<slug>.md` per curated competitor; each has all nine sections of the dossier skeleton, a dated `latest_version` claim, store ratings (or an explicit "not store-distributed" note), and a `## Sources` section meeting the gear's source budget
- Each dossier shows at least one adversarial search reflected in Strengths / weaknesses
- `research/competitor-landscape.md` exists with the feature matrix covering EVERY curated competitor and a non-empty Table stakes vs differentiators section
- Frontmatter `run_tag` + `created` present on every file written this step

If a dossier is thin after two spawn attempts, keep it, flag it in Coverage gaps, and proceed — an honest gap beats a stalled run.

Then update the manifest: `steps.2 = "done"`, mark the step-2 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Step 3 (social mining) is your concurrent pair member — it mines what real users say about exactly these competitors, seeded by your curated list — and may already be running or done. Once BOTH members of the 2 ∥ 3 pair are done, the router invokes:

```
Skill(skill: "hyperbuild-3-5-research-audit")
```

Step 3.5 adversarially audits your landscape (and step 3's synthesis) before step 4 cites either.
