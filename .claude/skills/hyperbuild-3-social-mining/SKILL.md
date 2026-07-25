---
name: hyperbuild-3-social-mining
description: >
  Step 3 of the hyperbuild pipeline — social sentiment mining. Spawns 4
  hb-sentiment-miner subagents in parallel, one per platform group
  (reddit / HN+forums / app-store reviews / LinkedIn+X), each mining
  25–40 posts (standard) or 60–100 (premier) into
  research/01-product-and-market/research/sentiment/<platform>.md in the
  docs/RESEARCH-ARCHIVE.md research-file format (H3 claims written as
  complete assertions) with verbatim quotes + URLs. The orchestrator
  registers those claims in runs/<run_tag>/temp/claims-01.json and
  merges the files into
  research/01-product-and-market/author/sentiment-synthesis.md — pain
  points and wish lists ranked by frequency × intensity. Runs
  concurrently with step 2 as the 2 ∥ 3 pair; step 3.5 audits the
  synthesis before step 4 traces PRD features to these quotes. Invoked
  by the hyperbuild router via Skill(); not run directly by users.
---

# Step 3 — Social mining (parallel, 4 miners)

You are executing step 3 (social mining) of the hyperbuild pipeline. Step 2 (market recon) runs CONCURRENTLY with you as the 2 ∥ 3 pair — the router drives both steps' spawn waves in the same block; step 2's curated competitor names are your search seeds (read the landscape the moment its merge lands; until then, seed from `runs/<run_tag>/temp/competitor-shortlist.md`). Your shared successor is step 3.5 (research audit), which starts only after BOTH members of the pair are done and adversarially attacks your synthesis before step 4 merges it with the landscape into the PRD, where every must/should feature must trace to competitor evidence OR user demand. Your quotes ARE the user demand. No quote, no demand claim.

**Gear gate:** runs for both gears. `standard`: 25–40 posts mined per platform group. `premier`: 60–100 posts per platform group. Read `gear` from the manifest before spawning.

**Goal:** four platform-group sentiment files full of verbatim, URL-cited user speech, merged into one synthesis that ranks pain points and wish-list items by frequency × intensity — so the PRD prioritizes what users actually suffer from, not what sounds plausible.

**NEVER FABRICATE A QUOTE.** Every pair of quotation marks in this step's artifacts wraps text copied verbatim from a real, linkable post. Paraphrase lives OUTSIDE quotation marks. A single invented quote poisons the PRD's evidence chain — this rule binds you and all four miners.

**FORMAT CONTRACT — `docs/RESEARCH-ARCHIVE.md` is BINDING on this step.** Read it before you spawn anything: §2 (the area layout), §3.1 (the research-file format), §4 (the provenance rule), §5 (the claim → verify mechanism). Violations are DEFECTS, not style disagreements — a file that misses the format is rejected and its miner re-spawned. You share area `01-product-and-market` with step 2: your platform files are `research/` phase, your synthesis is an `author/` file, and step 3.5 owns the area's `verify/`, `critique/`, and `_INDEX.md`. Every spawn prompt in this step cites `docs/RESEARCH-ARCHIVE.md` by path, and every miner READS IT BEFORE producing anything.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim idea (GOSPEL)
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`
- `docs/RESEARCH-ARCHIVE.md` — the BINDING output format (§2, §3.1, §4, §5)
- `research/01-product-and-market/author/competitor-landscape.md` — competitor names + slugs (search seeds) — IF it exists. It is step 2's FINAL artifact, so in the concurrent 2 ∥ 3 pair it usually does NOT exist yet: seed from `runs/<run_tag>/temp/competitor-shortlist.md` (the scout's shortlist) instead
- `research/01-product-and-market/research/competitors/<slug>.md` — whichever dossiers exist so far: skim their `## Summary` claims and "Store ratings & review themes" for themes worth chasing (skip when none have landed yet)

Set `steps.3 = "running"` in the manifest, mark the step-3 todo in_progress, then:

```bash
mkdir -p research/01-product-and-market/research/sentiment \
         research/01-product-and-market/verify \
         research/01-product-and-market/critique \
         research/01-product-and-market/author \
         runs/<run_tag>/temp
```

`mkdir -p` is idempotent, so it is safe that step 2 creates the same area dirs concurrently. Do NOT write `research/01-product-and-market/_INDEX.md` here — it indexes all four phases and is written at step 3.5, when the area is complete.

**Crash-resume rule:** if a `research/01-product-and-market/research/sentiment/<platform>.md` already exists with this run_tag in frontmatter, `posts_mined` at or above the gear minimum, AND H3 claims under `## Summary` plus a provenance block, do NOT re-spawn that miner — count it done. A file from a pre-archive-format run (no claim headings, no prompt block) does NOT count as done: re-spawn it.

---

## Procedure

### 3.1 — Prepare the seed list

Extract from the best source that EXISTS: `research/01-product-and-market/author/competitor-landscape.md` if step 2's merge has already landed, else `runs/<run_tag>/temp/competitor-shortlist.md` (the 2 ∥ 3 pair means the landscape is usually not written yet — the scout's shortlist is this step's real staging constraint, and step 3 may begin as soon as it exists). Take every competitor name + slug, the category vocabulary users actually type ("habit tracker", "streak app"), and the top review themes from whichever dossiers exist so far. Write the seed list to `runs/<run_tag>/temp/sentiment-seeds.md` — all four miners receive the same seeds.

### 3.2 — Spawn 4 hb-sentiment-miner subagents (parallel, ONE message)

One miner per platform group, **all four Task calls in ONE message**. Zero overlap: each miner works ONLY its group.

All four output paths sit under `research/01-product-and-market/research/sentiment/`; the `dimension` is `sentiment-<platform_group>`, which is what step 3.5's verifier filenames key off.

| platform_group | output_path (under `research/01-product-and-market/research/sentiment/`) | mine these |
|---|---|---|
| `reddit` | `reddit.md` | relevant subreddits, "best <category> app reddit", `site:reddit.com <competitor>` threads |
| `hn-forums` | `hn-forums.md` | HN via hn.algolia.com (Show HN / Ask HN / comment threads), niche forums, Discourse communities, product forums |
| `appstore-reviews` | `appstore-reviews.md` | Apple App Store + Google Play review listings for each competitor — BOTH 1–2-star (pain) and 5-star (praise) reviews |
| `linkedin-x` | `linkedin-x.md` | `site:linkedin.com/posts` commentary, X/Twitter posts via web search, professional takes on the category |

Spawn template (fill `<platform_group>`, `<output_path>`, and the group's mining row):

````
subagent_type: hb-sentiment-miner
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 3 (social mining) of the hyperbuild
  pipeline. Step 2 produced the competitor landscape; you mine ONE
  platform group for what real users say. Three sibling miners cover the
  other groups in parallel — do NOT stray into their platforms. After all
  four return, the orchestrator harvests the H3 claims out of your
  ## Summary into the area claim register, step 3.5 spawns one
  adversarial fact-checker PER CLAIM to REFUTE it, and step 4 traces PRD
  features to your verbatim quotes. An unquoted pain point is invisible
  to the PRD; a topic label instead of a claim is a finding nobody can
  verify.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: 01-product-and-market
  - dimension: sentiment-<platform_group>
  - platform_group: <reddit | hn-forums | appstore-reviews | linkedin-x>
  - mine_these: <the group's "mine these" cell from the table>
  - post_quota: <25–40 standard | 60–100 premier> posts read and assessed
  - claim_budget: <3–5 standard | 6–10 premier> H3 claims under ## Summary
  - competitor_seeds: [<names + slugs from sentiment-seeds.md>]
  - output_path: research/01-product-and-market/research/sentiment/<platform_group>.md

  CONTEXT FILES (read these first):
  - docs/RESEARCH-ARCHIVE.md — THE BINDING OUTPUT FORMAT. Read §3.1 (the
    research-file format), §4 (the provenance rule) and §5 (why your
    claims must be verifiable) BEFORE you write anything.
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/temp/sentiment-seeds.md
  - research/01-product-and-market/author/competitor-landscape.md (The set
    + Feature matrix sections) if present, otherwise
    runs/<run_tag>/temp/competitor-shortlist.md (the seeds file — step 2
    runs concurrently and may not have merged yet)

  FORMAT: docs/RESEARCH-ARCHIVE.md §3.1, with the sentiment evidence
  sections. In order: frontmatter (run_tag, created, area, dimension,
  phase: research, platform_group, posts_mined) → title → the provenance
  line, exactly:
      > Phase: **research** · Agent `hb-sentiment-miner` · Run `<run_tag>`
  → ## Summary → the evidence sections (## Method,
  ## Pain points (ranked), ## Wish list (ranked), ## Praised features,
  ## Quote bank, ## Competitor-specific signals) → ## Recommendations →
  ## Sources → the provenance block.

  EVERY H3 UNDER ## Summary IS A CLAIM, AND EVERY CLAIM IS A COMPLETE
  ASSERTION — a subject, a verb, and something that can be proven wrong.
  A topic label is a DEFECT: it cannot be verified or refuted.
    GOOD: "Losing a streak to a single missed day is the top churn
           trigger on Reddit — 11 independent posts, 4 of them
           'I deleted the app' (freq 5 × intensity 5 = 25)."
    GOOD: "Every complaint about Streaks' pricing is one 2024 thread
           reposted across four subreddits, so it carries the weight of
           ONE source, not four."
    BAD:  "Pain points" · "Pricing complaints" · "What users want"
  Write <3–5 | 6–10> such claims — the ones the PRD's priority order
  would rest on (a top-scored pain point, a wish item nothing ships, a
  praised feature that is table stakes, a churn-grade quote pattern), not
  one claim per section. Each carries
  `*Confidence: high|medium|low[, **LOAD-BEARING**]*`, then evidence with
  the score arithmetic, the post counts, the dates, and its verbatim
  quotes, then its source URLs as a bullet list. The ranked tables below
  hold the full inventory; the claim extractor reads ONLY H3s under
  ## Summary, so anything load-bearing must appear there too.

  NO CLAIM WITHOUT AT LEAST ONE SOURCE URL — the URL of a post you
  actually opened. A claim you cannot link is dropped, not hedged, not
  softened into "users seem to feel".

  Mining rules (all mandatory):
  - Run at least ONE adversarial search on your platform ("<competitor>
    sucks", "why I stopped using <competitor>", "alternative to
    <competitor>", "<category> app frustrating").
  - Every quote is VERBATIM with its URL; paraphrase goes outside
    quotation marks. Record each post's date (or "undated"). Cite by
    platform + date + URL only — never include usernames or real names.
  - Prioritize posts from the last 18 months; older posts only when a
    thread is canonical for this category.
  - Score every pain point / wish item: frequency (1–5: 1 = one post,
    2 = two, 3 = 3–5, 4 = 6–9, 5 = ten or more independent posts) ×
    intensity (1–5: 1 = passing mention, 2 = mild annoyance, 3 =
    recurring friction with emotion, 4 = blocks a core workflow, 5 =
    churn-grade — cancelled/deleted/data loss). Score = frequency ×
    intensity, max 25 — mechanical arithmetic, never rounded upward.
  - If your platform is genuinely thin for this category (e.g. LinkedIn
    for a casual consumer app), say so honestly in ## Method and report
    the real count — NEVER pad with marginal or off-topic posts. "This
    platform is thin for this category: 9 on-topic posts found in 40
    results" is itself a legitimate ## Summary claim.
  - ## Recommendations are DECISIONS in the imperative addressed to the
    PRD ("**[must]** ship streak-freeze — losing a streak to one missed
    day is the top churn trigger here"), each with its own justification
    tied to THIS app.
  - End with a ## Sources section: URL + access date + one-line takeaway.

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
  re-spawned — the prompt is what tells a later reader which venues you
  were pointed at, which seeds you had, and which platforms you were
  never asked to touch.
````

**CRITICAL: never emit bare text while miners are in flight.** A text-only response ends the turn and kills the pipeline. While waiting, append evolving thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` (cross-platform patterns you expect, which pain points will likely top the synthesis, contradictions between store reviews and Reddit mood) every 30–60 seconds.

**Partial failure policy:** if a miner returns without its file, or its file VIOLATES THE FORMAT CONTRACT (no H3 claims under `## Summary`, claims written as topic labels, a claim with no source URL, or a missing provenance block), re-spawn it ONCE with the output path and the violated rule restated as explicit required deliverables — a format violation is a defect, exactly like an empty return. If it fails twice, write the platform file yourself as a stub with `posts_mined: 0`, an honest "## Method" note explaining the failure, empty sections, and a Sources section listing whatever it did report — then proceed. A stub still carries the archive frontmatter and a provenance block whose prompt is the spawn prompt you sent; its `## Summary` carries the single honest claim that this platform returned nothing and why. Three good platforms beat a stalled run; the synthesis must NAME the missing platform as a coverage gap.

### 3.3 — The frequency × intensity rubric (used by miners AND your synthesis)

**frequency** (independent posts raising the same point): 1 = one post; 2 = two; 3 = 3–5; 4 = 6–9; 5 = ten or more.
**intensity** (emotional charge / stakes): 1 = passing mention; 2 = mild annoyance; 3 = recurring friction, complaint with emotion; 4 = blocks a core workflow, user describes a workaround; 5 = churn-grade — "I cancelled", "deleted the app", refund demands, data loss.
**score = frequency × intensity** (max 25). Score arithmetic is mechanical — never round a favorite pain point upward.

### 3.4 — Build the CLAIM REGISTER (orchestrator, after the wave returns)

The platform files are UNVERIFIED by construction — a miner optimizing for coverage will count one viral thread reposted across four subreddits as four independent posts, and read a two-year-old complaint as current. Step 3.5 fixes that by spawning one adversarial fact-checker PER CLAIM (`docs/RESEARCH-ARCHIVE.md` §5, §6). This register is what that fan-out consumes; without it, 3.5 has nothing to fan out over.

1. **Extract EVERY claim.** Open all four platform files (including any you stubbed) and read every H3 under `## Summary`. Each is one candidate claim, and **every one of them gets an entry** — nothing is discarded at this step.
2. **Mark the verify surface: `standard` 3–5 per platform file, `premier` 6–10.** Those entries get `"selected": true`; every other claim gets `"selected": false` and stays in the register. Select by LOAD-BEARINGNESS, NEVER by order of appearance: claims marked `**LOAD-BEARING**` go first (`"load_bearing": true`), then every claim carrying a score, a post count, a churn assertion, a competitor name, or a "nobody ships this" gap, then whatever the PRD's priority order would rest on. A thin platform contributes what it has — do not invent claims to hit a quota, and do not promote a decorative claim over a load-bearing one to fill the count. **The unselected entries are not bookkeeping:** they are how step 3.5's `_INDEX.md` (`## Verdict tally` — "<k> were NOT selected for verification and were NOT checked") and step 12's reusability guide state honestly what was never checked. A claim nobody wrote down cannot be counted as unchecked.
3. **Append-merge** into `runs/<run_tag>/temp/claims-01.json`. **Steps 2 and 3 are the concurrent 2 ∥ 3 pair and SHARE THIS ONE FILE.** Read it first if it exists, merge your entries into `.claims[]` by `id`, and write the union — NEVER truncate or overwrite step 2's competitor claims. If the file does not exist, create it with the wrapper below.

**THE REGISTER IS A JSON OBJECT, NOT A BARE ARRAY.** This is the exact schema step 3.5's verification engine reads in phase V1, and it is the same shape in all four areas (`claims-01.json` … `claims-04.json`). An array here means 3.5 iterates `.claims[]` over nothing and the whole area goes unverified.

```json
{
  "run_tag": "habit-coach-3f9a2c",
  "area": "01-product-and-market",
  "gear": "standard",
  "created": "2026-07-24",
  "claims": [
    {
      "id": "sentiment-reddit-01",
      "dimension": "sentiment-reddit",
      "source_file": "research/01-product-and-market/research/sentiment/reddit.md",
      "claim": "Losing a streak to a single missed day is the top churn trigger on Reddit — 11 independent posts, 4 of them 'I deleted the app' (freq 5 × intensity 5 = 25).",
      "claim_slug": "losing-a-streak-to-a-single-missed-day-is-the-top",
      "detail": "<the claim's body, verbatim from the platform file — the score arithmetic, the post counts and dates, the verbatim quotes>",
      "sources": ["https://reddit.com/r/productivity/comments/…", "https://reddit.com/r/getdisciplined/comments/…"],
      "confidence": "high",
      "load_bearing": true,
      "selected": true,
      "verdict": null,
      "correction": null
    }
  ]
}
```

Field rules: `id` = `<dimension>-<nn>`, `nn` zero-padded and sequential WITHIN that dimension (`sentiment-reddit-01`, `sentiment-reddit-02`) — unique across the whole area, and the handle 3.5 reports verdicts against. `dimension` = `sentiment-<platform_group>` — already flat, so 3.5's verifier files land at `research/01-product-and-market/verify/sentiment-<platform_group>--<claim-slug>.md`. `source_file` = the platform file the claim came from; 3.5 pastes it into each verifier's CONTEXT FILES, so an entry without it sends a fact-checker in blind. `claim` and `detail` are VERBATIM from the platform file — a paraphrase here sends the fact-checker after a claim nobody made, and a re-typed quote is a fabricated quote. `claim_slug` is computed, never eyeballed (`-2`, `-3` if two claims in one dimension slug identically):

```bash
python3 -c "import re,sys; s=sys.argv[1][:50].lower(); print(re.sub(r'-+$','',re.sub(r'[^a-z0-9]+','-',s)))" "<the claim, verbatim>"
```

`sources` is a non-empty array of post URLs; **a claim with zero sources does not enter the register** — log it in `runs/<run_tag>/temp/orchestrator-notes.md` as a dropped unsourced claim instead. `confidence` is `high | medium | low`, copied from the claim's confidence line. `load_bearing` mirrors the claim's `**LOAD-BEARING**` marking. `verdict` and `correction` start `null` — step 3.5 folds the fact-checkers' results into them.

Record the register's per-platform counts in `runs/<run_tag>/temp/orchestrator-notes.md`.

### 3.6 — Write `research/01-product-and-market/author/sentiment-synthesis.md` (orchestrator, after ALL four land)

*(Numbered 3.6, not 3.5: "step 3.5" is the research-audit half-step — a different skill — and reusing that number for a subsection of step 3 would be ambiguous.)*

Read all four platform files end to end, then synthesize yourself:

1. **Merge duplicates across platforms** — the same pain point worded four ways is ONE pain point. For each merged item: combined frequency = total independent posts across all four files, re-mapped to the 1–5 scale; intensity = the MAX observed on any platform; score = frequency × intensity.
2. **Top pain points** — ranked table: rank, pain point, freq, intensity, score, platforms seen on, competitor(s) concerned, then 1–3 verbatim quotes (with URL + date) under each entry.
3. **Wish list** — same structure, for asked-for-but-nonexistent capabilities.
4. **Praised features — do not break these** — what users love about competitors; the app must match or consciously diverge. Quote-backed.
5. **Platform mood summaries** — 3–5 lines per platform group; note any group reported thin or stubbed.
6. **Implications for the PRD** — 5–10 bullets addressed to step 4: which pain points demand must-features, which wishes are differentiators, which praised features are table stakes. Each bullet cites at least one quote already in this file.
7. **Coverage gaps** — thin or stubbed platforms, themes you expected and did not find. State plainly here that these platform files are UNVERIFIED at the moment of writing: step 3.5's `verify/` files OVERRIDE them (a "10 independent posts" count is exactly the kind of claim a syndication recount deflates), and a reader must check `verify/` before trusting any score or frequency.
8. **Sources** — the four platform files, plus any URLs you opened directly (URL + access date + one-line takeaway).

This is an `author/` file (`docs/RESEARCH-ARCHIVE.md` §3.3): frontmatter `run_tag`, `created`, `area: 01-product-and-market`, `phase: author`; then the title; then the provenance line

```
> Phase: **author** · Agent `hyperbuild-3-social-mining` (orchestrator) · Run `<run_tag>`
```

then the sections above; then the §4 provenance block. You were not spawned with a prompt, so that block reproduces YOUR instruction verbatim: the `Skill(skill: "hyperbuild-3-social-mining")` invocation line plus this §3.6 numbered synthesis brief, copied verbatim.

Every ranked item in the synthesis must carry at least one verbatim quote with a URL. An item you cannot quote does not appear.

**Step 3.5 patches this file after its verify fan-out returns** (`docs/RESEARCH-ARCHIVE.md` §7): refuted items move to `## Refuted by verification`, weakened items carry their recomputed score inline. Never pre-empt that here, and never rewrite a platform file to match a later correction — the `research/` file is the honest record of what one surveying miner believed.

---

## Artifacts

**`research/01-product-and-market/research/sentiment/<platform>.md`** — four files (`reddit.md`, `hn-forums.md`, `appstore-reviews.md`, `linkedin-x.md`), written by the miners, in the `docs/RESEARCH-ARCHIVE.md` §3.1 research-file format:

````markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
area: 01-product-and-market
dimension: sentiment-reddit
phase: research
platform_group: reddit
posts_mined: 34
---

# Sentiment — Reddit

> Phase: **research** · Agent `hb-sentiment-miner` · Run `habit-coach-3f9a2c`

## Summary
<One dense paragraph: what this platform's users actually complain about
 and ask for, what it changes for the PRD, what the reader must not miss.>

### Losing a streak to a single missed day is the top churn trigger on Reddit — 11 independent posts, 4 of them "I deleted the app"
*Confidence: high, **LOAD-BEARING***
<Evidence: the score arithmetic (freq 5 × intensity 5 = 25), the post
 counts and dates, 1–3 verbatim quotes with their Q-ids.>
- https://reddit.com/r/productivity/comments/…
- https://reddit.com/r/getdisciplined/comments/…

### <the next claim — a complete assertion, same shape>

## Method              <!-- queries run (incl. the adversarial ones), venues covered,
                            honest thinness note if applicable -->
## Pain points (ranked)  <!-- table: Rank | Pain point | Freq | Intensity | Score |
                              Competitor(s) | Quotes (Q-ids) -->
## Wish list (ranked)    <!-- same table shape -->
## Praised features      <!-- what users love; quote-backed -->
## Quote bank            <!-- Q1, Q2, ...: "verbatim text" — platform, YYYY-MM-DD
                              (or "undated"), URL -->
## Competitor-specific signals  <!-- per-competitor mood in 1-3 lines each -->

## Recommendations
- **[must|should|avoid]** <A concrete decision for the PRD, in the imperative.>
  - <Why — tied to THIS app's constraints, not to general good practice.>

## Sources               <!-- one line per source: URL — accessed YYYY-MM-DD — takeaway -->

<details>
<summary>The prompt that produced this</summary>

```
<the miner's full spawn prompt, verbatim>
```

</details>
````

Ranked tables cite quotes by Q-id; the Quote bank holds the verbatim text. The H3s under `## Summary` are the CLAIMS — complete assertions, each with a confidence line and at least one source URL; only those enter the claim register and get fact-checked. All of it lives in the top-level research vault (NOT under runs/) so later runs reuse it.

**`research/01-product-and-market/author/sentiment-synthesis.md`** — frontmatter `run_tag`, `created`, `area`, `phase: author`; provenance line; sections listed in 3.6; provenance block. This is step 4's primary demand-evidence input.

**`runs/<run_tag>/temp/claims-01.json`** — the area-01 claim register (3.4), shared append-merge with step 2, consumed by step 3.5's verify fan-out. Run-scoped and disposable; the durable record is the `verify/` files 3.5 writes from it.

---

## Exit criteria

- All four `research/01-product-and-market/research/sentiment/<platform>.md` files exist with frontmatter `run_tag`, `created`, `area`, `dimension`, `phase: research`, `platform_group`, `posts_mined`
- Each non-stubbed file meets the gear quota (25–40 standard / 60–100 premier posts mined) OR documents genuine platform thinness in `## Method` with the real count
- **Every file's `## Summary` carries ≥3 H3 claims WRITTEN AS COMPLETE ASSERTIONS** (subject + verb + something refutable), each with a confidence line and **at least one source URL**. A topic-label heading ("Pain points", "What users want") is a defect — re-spawn. A stub file carries one honest claim about the platform returning nothing.
- **Every file written this step ENDS with its provenance block** reproducing the producing prompt verbatim (`docs/RESEARCH-ARCHIVE.md` §4) — platform files, stubs, and the synthesis alike
- Each file shows at least one adversarial search in `## Method`, a populated Quote bank, a `## Recommendations` section of imperative decisions, and a `## Sources` section
- Every pain-point and wish-list row in every file cites at least one Q-id resolving to a verbatim quote with a URL
- `runs/<run_tag>/temp/claims-01.json` exists as a JSON OBJECT with `run_tag`, `area`, `gear`, `created` and a `claims` array (the engine's V1 schema — never a bare array), holding EVERY H3 claim from all four platform files: `"selected": true` on the gear budget per platform file (3–5 standard / 6–10 premier, or all of them if fewer) and `"selected": false` on the rest; every entry carries `id`, `dimension`, `source_file`, `claim`, `claim_slug`, `detail`, a non-empty `sources` array, `confidence`, `load_bearing`, `selected`, and `verdict`/`correction` set to `null`; step 2's competitor entries (if already written) preserved
- `research/01-product-and-market/author/sentiment-synthesis.md` exists with `phase: author`; every ranked item carries a quote + URL; scores follow the 3.3 rubric; Implications for the PRD is non-empty; Coverage gaps carries the "unverified until 3.5" note
- Any stubbed platform is named as a coverage gap in the synthesis

Then update the manifest: `steps.3 = "done"`, mark the step-3 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Once BOTH members of the 2 ∥ 3 pair are done, it invokes:

```
Skill(skill: "hyperbuild-3-5-research-audit")
```

Step 3.5 owns the rest of area `01-product-and-market`: it reads `runs/<run_tag>/temp/claims-01.json` — your sentiment claims alongside step 2's competitor claims — spawns ONE adversarial fact-checker PER CLAIM to REFUTE it into `research/01-product-and-market/verify/`, runs the cross-cutting critics into `critique/`, patches your synthesis and step 2's landscape with the surviving corrections, and writes the area's `_INDEX.md`. The ranked claims that survive become step 4's feature-priority spine.
