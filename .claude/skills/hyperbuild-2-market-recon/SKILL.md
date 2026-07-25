---
name: hyperbuild-2-market-recon
description: >
  Step 2 of the hyperbuild pipeline — competitor recon. Spawns ONE
  hb-competitor-scout to discover and rank the competitor set, then a
  parallel wave of hb-competitor-analyst subagents (one per curated
  competitor: 6–8 standard, 12–15 premier) that each write a dossier to
  research/01-product-and-market/research/competitors/<slug>.md in the
  docs/RESEARCH-ARCHIVE.md research-file format (H3 claims written as
  complete assertions) covering latest version, feature set, changelog
  cadence, pricing, and store ratings. The orchestrator then registers
  those claims in runs/<run_tag>/temp/claims-01.json and merges the
  dossiers into
  research/01-product-and-market/author/competitor-landscape.md with a
  feature matrix.
  Runs concurrently with step 3 as the 2 ∥ 3 pair; step 3.5 audits
  these artifacts before step 4 builds the PRD on them. Invoked by the
  hyperbuild router via Skill(); not run directly by users.
---

# Step 2 — Market recon (1 scout, then parallel analysts)

You are executing step 2 (market recon) of the hyperbuild pipeline. Step 1 persisted the gospel idea and resolved the platform. Step 3 (social mining) runs CONCURRENTLY with you as the 2 ∥ 3 pair — the router drives both steps' spawn waves in the same block; your scout shortlist and landscape seed its searches as they land. Your shared successor is step 3.5 (research audit), which starts only after BOTH members of the pair are done and adversarially attacks your landscape before step 4 merges it into the PRD — every must/should feature there must trace to competitor evidence or user demand, so thin dossiers here become an unsupported PRD there.

**Gear gate:** runs for both gears. `standard`: 6–8 competitors, 5–8 sources per dossier. `premier`: 12–15 competitors, 10–15 sources per dossier. Read `gear` from the manifest before choosing counts.

**Goal:** a ranked competitor landscape with one evidence-dense dossier per competitor — current version, full feature inventory, changelog mining, pricing, store ratings — plus a cross-competitor feature matrix that shows table stakes vs whitespace.

**FORMAT CONTRACT — `docs/RESEARCH-ARCHIVE.md` is BINDING on this step.** Read it before you spawn anything: §2 (the area layout), §3.1 (the research-file format), §4 (the provenance rule), §5 (the claim → verify mechanism). Violations are DEFECTS, not style disagreements — a file that misses the format is rejected and its agent re-spawned. This step owns the `research/` phase of area `01-product-and-market`: dossiers are research-phase files, the landscape is an `author/` file. Step 3 fills the same area's sentiment files; step 3.5 owns that area's `verify/`, `critique/`, and `_INDEX.md`. Every spawn prompt in this step cites `docs/RESEARCH-ARCHIVE.md` by path, and every subagent READS IT BEFORE producing anything.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim idea (GOSPEL)
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`
- `runs/<run_tag>/decisions/platform.md` — the platform decision + rationale
- `runs/<run_tag>/scaffold.md` — "Competitor guesses" seeds for the scout
- `docs/RESEARCH-ARCHIVE.md` — the BINDING output format (§2, §3.1, §4, §5)

Set `steps.2 = "running"` in the manifest, mark the step-2 todo in_progress, then:

```bash
mkdir -p research/01-product-and-market/research/competitors \
         research/01-product-and-market/verify \
         research/01-product-and-market/critique \
         research/01-product-and-market/author \
         runs/<run_tag>/temp
```

Create all four phase directories even though this step only fills two — step 3.5 writes into `verify/` and `critique/`, and an area with missing phase dirs reads as an area that skipped verification. Do NOT write `research/01-product-and-market/_INDEX.md` here: it indexes all four phases and is written at step 3.5, when the area is complete.

---

## Procedure

### 2.1 — Spawn ONE hb-competitor-scout

Discovery is one spawn, always. The scout overshoots (finds ~12 candidates for standard, ~20 for premier) so YOU can curate down.

````
subagent_type: hb-competitor-scout
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon — competitor discovery)
  of the hyperbuild pipeline. Step 1 resolved the target platform. After
  you return, the orchestrator curates your ranked list down to
  <6–8 standard | 12–15 premier> competitors and spawns one
  hb-competitor-analyst per competitor, each writing
  research/01-product-and-market/research/competitors/<slug>.md; those
  dossiers feed the PRD in step 4. You discover and rank — you do NOT
  write dossiers.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - platform: <platform slug from manifest>
  - candidate_target: <12 for standard | 20 for premier> ranked candidates
  - seed_guesses: [<competitor guesses from scaffold.md, may be empty>]
  - output_path: runs/<run_tag>/temp/competitor-shortlist.md

  CONTEXT FILES (read these first):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - docs/RESEARCH-ARCHIVE.md (§4 — the provenance rule binds your file too)

  NO CANDIDATE WITHOUT A SOURCE URL: every shortlist row carries at least
  one URL you fetched live this run. A candidate you cannot link is
  dropped, not hedged.

  PROVENANCE (mandatory): END your shortlist with a collapsible block
  reproducing THIS ENTIRE PROMPT VERBATIM — no summary, no paraphrase —
  in the docs/RESEARCH-ARCHIVE.md §4 format:

  <details>
  <summary>The prompt that produced this</summary>

  ```
  <this prompt, verbatim>
  ```

  </details>

  The archive must be able to reconstruct HOW the competitor set was
  chosen, not just what it contains. A file without its prompt block is
  incomplete and gets re-spawned.
````

The scout's shortlist gives, per candidate: name, homepage URL, store URLs (App Store / Google Play / marketplace where applicable), platforms, latest version if spotted, one-line positioning, relevance rationale, rank. Discovery MUST include "best alternatives to X" and "X vs Y" searches — alternative-roundup pages are the densest competitor-discovery sources on the web.

### 2.2 — Curate the competitor list

From the shortlist, pick the final set: **6–8 for standard, 12–15 for premier**. Curation rules:

- Majority direct competitors (same job-to-be-done, same audience); include 1–2 adjacent or aspirational products whose features users will compare against.
- Prefer actively maintained products (a release within 18 months). Include at most ONE dead/legacy product, and only if it still dominates search results for this category — its abandonment is itself market evidence.
- Assign each a slug: lowercase hyphenated product name (`streaks`, `loop-habit-tracker`).
- **Dossier reuse (vault rule):** before spawning an analyst, check `research/01-product-and-market/research/competitors/<slug>.md`. If a dossier already exists, its `created` date is within 90 days, AND it is in the `docs/RESEARCH-ARCHIVE.md` §3.1 format (H3 claims under `## Summary`, `## Sources`, a provenance block), REUSE it — skip that spawn and mark it "(reused)" in the landscape. Older than 90 days, or a pre-archive-format dossier with no claim headings: re-spawn to refresh. A reused dossier still contributes its claims to the register (§2.4).

Record the curated list (slug, name, rank, reused?) in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 2.3 — Spawn the analyst wave (parallel, ONE message)

Spawn **one `hb-competitor-analyst` per non-reused competitor, all in ONE message** — true parallel execution. That is 6–8 Task calls for standard, 12–15 for premier. Zero overlap: each analyst gets exactly one competitor.

````
subagent_type: hb-competitor-analyst
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 2 (market recon — competitor analyst) of
  the hyperbuild pipeline. The hb-competitor-scout discovered the set; the
  orchestrator assigned you exactly ONE competitor. Other analysts are
  covering the others in parallel — do NOT research any competitor but
  yours. After you return, the orchestrator harvests the H3 claims out of
  your ## Summary into the area claim register, step 3.5 spawns one
  adversarial fact-checker PER CLAIM to REFUTE it, and step 4 traces PRD
  features to your dossier. Your dossier is evidence; weak evidence
  becomes an unsupported PRD, and a topic label instead of a claim is a
  finding nobody can verify.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 01-product-and-market
  - dimension: competitor-<slug>
  - competitor: <name>
  - slug: <slug>
  - homepage: <URL from the shortlist>
  - store_urls: [<store URLs from the shortlist, may be empty>]
  - source_budget: <5–8 standard | 10–15 premier> distinct sources
  - claim_budget: <3–5 standard | 6–10 premier> H3 claims under ## Summary
  - output_path: research/01-product-and-market/research/competitors/<slug>.md

  CONTEXT FILES (read these first):
  - docs/RESEARCH-ARCHIVE.md — THE BINDING OUTPUT FORMAT. Read §3.1 (the
    research-file format), §4 (the provenance rule) and §5 (why your
    claims must be verifiable) BEFORE you write anything.
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/decisions/platform.md
  - runs/<run_tag>/temp/competitor-shortlist.md (your competitor's row only)

  FORMAT: docs/RESEARCH-ARCHIVE.md §3.1, with the dossier evidence
  sections. In order: frontmatter (run_tag, created, area, dimension,
  phase: research, plus competitor, slug, homepage, latest_version,
  version_date, platforms, price_model, store_rating) → title → the
  provenance line, exactly:
      > Phase: **research** · Agent `hb-competitor-analyst` · Run `<run_tag>`
  → ## Summary → the evidence
  sections (## Feature inventory, ## Changelog mining, ## Pricing,
  ## Positioning & audience, ## Store ratings & review themes,
  ## Strengths / weaknesses, ## Relevance to our idea) →
  ## Recommendations → ## Sources → the provenance block.

  EVERY H3 UNDER ## Summary IS A CLAIM, AND EVERY CLAIM IS A COMPLETE
  ASSERTION — a subject, a verb, and something that can be proven wrong.
  A topic label is a DEFECT: it cannot be verified or refuted.
    GOOD: "Streaks charges $4.99 one-time with no subscription tier and
           shipped Apple Watch complications in 9.0 (2026-03-11)."
    GOOD: "Streaks has shipped no release in 14 months; its changelog
           stops at 9.2 (2025-05-14)."
    BAD:  "Pricing" · "Changelog" · "Feature set" · "Weaknesses"
  Write <3–5 | 6–10> such claims — the load-bearing ones, the facts a
  PRD decision would rest on (price, version, dated feature, store
  rating, discontinued capability), not one claim per section. Each
  carries `*Confidence: high|medium|low[, **LOAD-BEARING**]*`, then
  evidence with exact numbers/versions/dates/feature names, then its
  source URLs as a bullet list. The evidence sections below hold the raw
  tables; the claim extractor reads ONLY H3s under ## Summary, so
  anything load-bearing must appear there and not only in a table.

  NO CLAIM WITHOUT AT LEAST ONE SOURCE URL. A claim you cannot link to a
  page you actually fetched is dropped, not hedged, not softened.

  Dossier requirements (all mandatory): latest version + its release date
  from a dated source; full feature inventory; changelog mining (release
  cadence + notable releases of the last 18 months); pricing; store
  ratings with rating counts; at least ONE adversarial search
  ("<competitor> problems", "<competitor> review negative", "why I
  stopped using <competitor>"); ## Recommendations as DECISIONS in the
  imperative ("**[must]** match X's one-tap widget entry — it is table
  stakes"), each with its own justification tied to THIS app; a
  ## Sources section (URL + access date + one-line takeaway per source).
  Version/feature claims MUST cite a dated source. Prioritize sources
  from the last 18 months.

  PROVENANCE (mandatory, docs/RESEARCH-ARCHIVE.md §4): END the file with
  a collapsible block reproducing THIS ENTIRE PROMPT VERBATIM — no
  summary, no paraphrase, no "the prompt asked me to…":

  <details>
  <summary>The prompt that produced this</summary>

  ```
  <this prompt, verbatim>
  ```

  </details>

  If the prompt body contains a triple backtick, use a FOUR-backtick
  outer fence. A file without its prompt block is INCOMPLETE and gets
  re-spawned — the prompt is what tells a later reader what you were
  asked, what context you had, and what you were never asked to consider.
````

**CRITICAL: never emit bare text while analysts are in flight.** A text-only response ends the turn and kills the pipeline. While waiting, append evolving thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` (emerging table stakes, whitespace hypotheses, which axes will split the positioning map) with Edit/Write every 30–60 seconds.

**Partial failure policy:** if an analyst returns nothing, its dossier is missing, or the dossier VIOLATES THE FORMAT CONTRACT (no H3 claims under `## Summary`, claims written as topic labels, a claim with no source URL, or a missing provenance block), re-spawn it ONCE with the output path and the violated rule restated as explicit required deliverables — a format violation is a defect, exactly like an empty return. If it fails twice, drop that competitor, note the gap in the landscape's "Coverage gaps" line, and proceed — but if the surviving dossier count falls below the gear minimum (6 standard / 12 premier), spawn analysts for the next-ranked shortlist candidates to backfill.

### 2.4 — Build the CLAIM REGISTER (orchestrator, after the wave returns)

The dossiers are UNVERIFIED by construction — a surveying agent optimizing for coverage will confidently repeat a stale price and an app that shipped its last release two years ago. Step 3.5 fixes that by spawning one adversarial fact-checker PER CLAIM (`docs/RESEARCH-ARCHIVE.md` §5, §6). This register is what that fan-out consumes; without it, 3.5 has nothing to fan out over.

1. **Extract EVERY claim.** Open every dossier that landed (INCLUDING reused ones) and read every H3 under `## Summary`. Each is one candidate claim, and **every one of them gets an entry** — nothing is discarded at this step.
2. **Mark the verify surface: `standard` 3–5 per dossier, `premier` 6–10.** Those entries get `"selected": true`; every other claim gets `"selected": false` and stays in the register. Select by LOAD-BEARINGNESS, NEVER by order of appearance: claims marked `**LOAD-BEARING**` go first (`"load_bearing": true`), then every claim carrying a version, price, licence, policy, store rating, or exact feature/API name, then whatever a PRD decision would rest on. A dossier that offered fewer claims than the budget contributes what it has — do not invent claims to hit a quota, and do not promote a decorative claim over a load-bearing one to fill the count. **The unselected entries are not bookkeeping:** they are how step 3.5's `_INDEX.md` (`## Verdict tally` — "<k> were NOT selected for verification and were NOT checked") and step 12's reusability guide state honestly what was never checked. A claim nobody wrote down cannot be counted as unchecked.
3. **Append-merge** into `runs/<run_tag>/temp/claims-01.json`. **Steps 2 and 3 are the concurrent 2 ∥ 3 pair and SHARE THIS ONE FILE.** Read it first if it exists, merge your entries into `.claims[]` by `id`, and write the union — NEVER truncate or overwrite entries you did not create. If the file does not exist, create it with the wrapper below.

**THE REGISTER IS A JSON OBJECT, NOT A BARE ARRAY.** This is the exact schema step 3.5's verification engine reads in phase V1, and it is the same shape in all four areas (`claims-01.json` … `claims-04.json`). An array here means 3.5 iterates `.claims[]` over nothing and the whole area goes unverified.

```json
{
  "run_tag": "habit-coach-3f9a2c",
  "area": "01-product-and-market",
  "gear": "standard",
  "created": "2026-07-24",
  "claims": [
    {
      "id": "competitor-streaks-01",
      "dimension": "competitor-streaks",
      "source_file": "research/01-product-and-market/research/competitors/streaks.md",
      "claim": "Streaks charges $4.99 one-time with no subscription tier and shipped Apple Watch complications in 9.0 (2026-03-11).",
      "claim_slug": "streaks-charges-4-99-one-time-with-no-subscription",
      "detail": "<the claim's body, verbatim from the dossier — numbers, versions, dates, exact feature names>",
      "sources": ["https://apps.apple.com/us/app/streaks/id963034692", "https://streaksapp.com/pricing"],
      "confidence": "high",
      "load_bearing": true,
      "selected": true,
      "verdict": null,
      "correction": null
    }
  ]
}
```

Field rules: `id` = `<dimension>-<nn>`, `nn` zero-padded and sequential WITHIN that dimension (`competitor-streaks-01`, `competitor-streaks-02`) — unique across the whole area, and the handle 3.5 reports verdicts against. `dimension` = `competitor-<slug>` — already flat, so 3.5's verifier files land at `research/01-product-and-market/verify/competitor-<slug>--<claim-slug>.md`. `source_file` = the dossier path the claim came from; 3.5 pastes it into each verifier's CONTEXT FILES, so an entry without it sends a fact-checker in blind. `claim` and `detail` are VERBATIM from the dossier — a paraphrase here sends the fact-checker after a claim nobody made. `claim_slug` is computed, never eyeballed (`-2`, `-3` if two claims in one dimension slug identically):

```bash
python3 -c "import re,sys; s=sys.argv[1][:50].lower(); print(re.sub(r'-+$','',re.sub(r'[^a-z0-9]+','-',s)))" "<the claim, verbatim>"
```

`sources` is a non-empty array of URLs; **a claim with zero sources does not enter the register** — log it in `runs/<run_tag>/temp/orchestrator-notes.md` as a dropped unsourced claim instead. `confidence` is `high | medium | low`, copied from the claim's confidence line. `load_bearing` mirrors the claim's `**LOAD-BEARING**` marking. `verdict` and `correction` start `null` — step 3.5 folds the fact-checkers' results into them.

Record the register's per-dossier counts in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 2.5 — Write `research/01-product-and-market/author/competitor-landscape.md` (orchestrator, after ALL dossiers land)

Read every dossier end to end, then write the landscape yourself:

1. **The set (ranked)** — table: rank, name, slug, latest version + date, platforms, price model, store rating, one-line positioning.
2. **Feature matrix** — rows = every distinct feature found across dossiers (deduplicate names), columns = competitors, cells = `Y` / `N` / `~` (partial, footnote why). Wide tables are fine in markdown.
3. **Positioning map** — pick the TWO axes that best split this market (e.g. simple↔power-user, free↔premium) and place every competitor in a textual 2×2.
4. **Pricing landscape** — models present, price points, where the market clusters.
5. **Table stakes vs differentiators** — table stakes = features in ≥70% of the set (the app MUST have these or justify absence); differentiators = features 1–2 competitors use as their wedge.
6. **Whitespace & opportunities** — what NOBODY does well, judged strictly against the verbatim idea.
7. **Coverage gaps** — competitors dropped after two failed spawns, thin dossiers, anything step 4 should distrust. State plainly here that these dossiers are UNVERIFIED at the moment of writing: step 3.5's `verify/` files OVERRIDE them, and a reader must check `verify/` before trusting any price, version, rating, or licence.
8. **Sources** — the dossier files consulted, plus any URLs you consulted directly (URL + access date + one-line takeaway).

This is an `author/` file (`docs/RESEARCH-ARCHIVE.md` §3.3): frontmatter `run_tag`, `created`, `area: 01-product-and-market`, `phase: author`, `competitor_count`; then the title; then the provenance line

```
> Phase: **author** · Agent `hyperbuild-2-market-recon` (orchestrator) · Run `<run_tag>`
```

then the sections above; then the §4 provenance block. You were not spawned with a prompt, so that block reproduces YOUR instruction verbatim: the `Skill(skill: "hyperbuild-2-market-recon")` invocation line plus this §2.5 numbered synthesis brief, copied verbatim.

Every claim in the landscape must trace to a dossier — the landscape SYNTHESIZES, it never introduces un-dossiered facts.

**Step 3.5 patches this file after its verify fan-out returns** (`docs/RESEARCH-ARCHIVE.md` §7): refuted claims move to `## Refuted by verification`, weakened claims carry their correction inline. Never pre-empt that here, and never rewrite a dossier to match a later correction — the `research/` file is the honest record of what one surveying agent believed.

---

## Artifacts

**`research/01-product-and-market/research/competitors/<slug>.md`** — one per competitor, written by its analyst, in the `docs/RESEARCH-ARCHIVE.md` §3.1 research-file format:

````markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
area: 01-product-and-market
dimension: competitor-streaks
phase: research
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

> Phase: **research** · Agent `hb-competitor-analyst` · Run `habit-coach-3f9a2c`

## Summary
<One dense paragraph: what this product is, who it is for, what about it
 changes our plan, what the reader must not miss.>

### Streaks charges $4.99 one-time with no subscription tier, against a category that has moved to $3–5/month
*Confidence: high, **LOAD-BEARING***
<Evidence: exact prices, tiers, what is paywalled, dates. Numbers, versions,
 dates, exact feature names — never "about" or "roughly".>
- https://apps.apple.com/us/app/streaks/id963034692
- https://streaksapp.com/pricing

### <the next claim — a complete assertion, same shape>

## Feature inventory   <!-- table: Feature | Details | Since version (if dated) | [S<n>] -->
## Changelog mining    <!-- release cadence (releases/yr) + table of last-18-months
                            notable releases: version | date | highlights | source -->
## Pricing             <!-- model, price points, what's paywalled -->
## Positioning & audience
## Store ratings & review themes  <!-- rating + count per store; recurring themes -->
## Strengths / weaknesses         <!-- incl. adversarial-search findings -->
## Relevance to our idea          <!-- judged against the verbatim idea only -->

## Recommendations
- **[must|should|avoid]** <A concrete decision, in the imperative.>
  - <Why — tied to THIS app's constraints, not to general good practice.>

## Sources             <!-- one line per source: URL — accessed YYYY-MM-DD — takeaway -->

<details>
<summary>The prompt that produced this</summary>

```
<the analyst's full spawn prompt, verbatim>
```

</details>
````

The evidence sections are the raw record; the H3s under `## Summary` are the CLAIMS — complete assertions, each with a confidence line and at least one source URL. Only those H3s enter the claim register and get fact-checked.

**`research/01-product-and-market/author/competitor-landscape.md`** — frontmatter `run_tag`, `created`, `area`, `phase: author`, `competitor_count`; provenance line; sections listed in 2.5; provenance block. Both artifact types live in the top-level research vault (NOT under runs/) so later runs reuse them.

**`runs/<run_tag>/temp/claims-01.json`** — the area-01 claim register (2.4), shared append-merge with step 3, consumed by step 3.5's verify fan-out. Run-scoped and disposable; the durable record is the `verify/` files 3.5 writes from it.

---

## Exit criteria

- Curated set size within gear range (6–8 standard / 12–15 premier), counting reused dossiers
- One `research/01-product-and-market/research/competitors/<slug>.md` per curated competitor; each has the full section skeleton, a dated `latest_version` claim, store ratings (or an explicit "not store-distributed" note), a `## Recommendations` section of imperative decisions, and a `## Sources` section meeting the gear's source budget
- **Every dossier's `## Summary` carries ≥3 H3 claims WRITTEN AS COMPLETE ASSERTIONS** (subject + verb + something refutable), each with a confidence line and **at least one source URL**. A topic-label heading ("Pricing", "Feature set") is a defect — re-spawn.
- **Every file written this step ENDS with its provenance block** reproducing the producing prompt verbatim (`docs/RESEARCH-ARCHIVE.md` §4) — dossiers, the shortlist, and the landscape alike
- Each dossier shows at least one adversarial search reflected in Strengths / weaknesses
- `runs/<run_tag>/temp/claims-01.json` exists as a JSON OBJECT with `run_tag`, `area`, `gear`, `created` and a `claims` array (the engine's V1 schema — never a bare array), holding EVERY H3 claim from every dossier: `"selected": true` on the gear budget per dossier (3–5 standard / 6–10 premier, or all of them if fewer) and `"selected": false` on the rest; every entry carries `id`, `dimension`, `source_file`, `claim`, `claim_slug`, `detail`, a non-empty `sources` array, `confidence`, `load_bearing`, `selected`, and `verdict`/`correction` set to `null`; step 3's entries (if already written) preserved
- `research/01-product-and-market/author/competitor-landscape.md` exists with `phase: author`, the feature matrix covering EVERY curated competitor, a non-empty Table stakes vs differentiators section, and the "unverified until 3.5" note in Coverage gaps
- Frontmatter `run_tag`, `created`, `area`, `phase` present on every research/author file written this step

If a dossier is thin after two spawn attempts, keep it, flag it in Coverage gaps, and proceed — an honest gap beats a stalled run.

Then update the manifest: `steps.2 = "done"`, mark the step-2 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Step 3 (social mining) is your concurrent pair member — it mines what real users say about exactly these competitors, seeded by your curated list — and may already be running or done. Once BOTH members of the 2 ∥ 3 pair are done, the router invokes:

```
Skill(skill: "hyperbuild-3-5-research-audit")
```

Step 3.5 owns the rest of area `01-product-and-market`: it reads `runs/<run_tag>/temp/claims-01.json`, spawns ONE adversarial fact-checker PER CLAIM to REFUTE it into `research/01-product-and-market/verify/`, runs the cross-cutting critics into `critique/`, patches your landscape (and step 3's synthesis) with the surviving corrections, and writes the area's `_INDEX.md`. Step 4 cites only what survived.
