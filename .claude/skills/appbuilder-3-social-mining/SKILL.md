---
name: appbuilder-3-social-mining
description: >
  Step 3 of the appbuilder pipeline — social sentiment mining. Spawns 4
  ab-sentiment-miner subagents in parallel, one per platform group
  (reddit / HN+forums / app-store reviews / LinkedIn+X), each mining
  25–40 posts (standard) or 60–100 (premier) into
  research/sentiment/<platform>.md with verbatim quotes + URLs. The
  orchestrator merges them into research/sentiment-synthesis.md — pain
  points and wish lists ranked by frequency × intensity. Runs
  concurrently with step 2 as the 2 ∥ 3 pair; step 3.5 audits the
  synthesis before step 4 traces PRD features to these quotes. Invoked
  by the appbuilder router via Skill(); not run directly by users.
---

# Step 3 — Social mining (parallel, 4 miners)

You are executing step 3 (social mining) of the appbuilder pipeline. Step 2 (market recon) runs CONCURRENTLY with you as the 2 ∥ 3 pair — the router drives both steps' spawn waves in the same block; step 2's curated competitor names are your search seeds (read the landscape the moment its merge lands; until then, seed from `runs/<run_tag>/temp/competitor-shortlist.md`). Your shared successor is step 3.5 (research audit), which starts only after BOTH members of the pair are done and adversarially attacks your synthesis before step 4 merges it with the landscape into the PRD, where every must/should feature must trace to competitor evidence OR user demand. Your quotes ARE the user demand. No quote, no demand claim.

**Gear gate:** runs for both gears. `standard`: 25–40 posts mined per platform group. `premier`: 60–100 posts per platform group. Read `gear` from the manifest before spawning.

**Goal:** four platform-group sentiment files full of verbatim, URL-cited user speech, merged into one synthesis that ranks pain points and wish-list items by frequency × intensity — so the PRD prioritizes what users actually suffer from, not what sounds plausible.

**NEVER FABRICATE A QUOTE.** Every pair of quotation marks in this step's artifacts wraps text copied verbatim from a real, linkable post. Paraphrase lives OUTSIDE quotation marks. A single invented quote poisons the PRD's evidence chain — this rule binds you and all four miners.

---

## Inputs

- `runs/<run_tag>/idea.md` — the verbatim idea (GOSPEL)
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `platform`
- `research/competitor-landscape.md` — competitor names + slugs (search seeds) — IF it exists. It is step 2's FINAL artifact, so in the concurrent 2 ∥ 3 pair it usually does NOT exist yet: seed from `runs/<run_tag>/temp/competitor-shortlist.md` (the scout's shortlist) instead
- `research/competitors/<slug>.md` — whichever dossiers exist so far: skim "Store ratings & review themes" for themes worth chasing (skip when none have landed yet)

Set `steps.3 = "running"` in the manifest, mark the step-3 todo in_progress, then `mkdir -p research/sentiment`.

**Crash-resume rule:** if a `research/sentiment/<platform>.md` already exists with this run_tag in frontmatter and `posts_mined` at or above the gear minimum, do NOT re-spawn that miner — count it done.

---

## Procedure

### 3.1 — Prepare the seed list

Extract from the best source that EXISTS: `research/competitor-landscape.md` if step 2's merge has already landed, else `runs/<run_tag>/temp/competitor-shortlist.md` (the 2 ∥ 3 pair means the landscape is usually not written yet — the scout's shortlist is this step's real staging constraint, and step 3 may begin as soon as it exists). Take every competitor name + slug, the category vocabulary users actually type ("habit tracker", "streak app"), and the top review themes from whichever dossiers exist so far. Write the seed list to `runs/<run_tag>/temp/sentiment-seeds.md` — all four miners receive the same seeds.

### 3.2 — Spawn 4 ab-sentiment-miner subagents (parallel, ONE message)

One miner per platform group, **all four Task calls in ONE message**. Zero overlap: each miner works ONLY its group.

| platform_group | output_path | mine these |
|---|---|---|
| `reddit` | `research/sentiment/reddit.md` | relevant subreddits, "best <category> app reddit", `site:reddit.com <competitor>` threads |
| `hn-forums` | `research/sentiment/hn-forums.md` | HN via hn.algolia.com (Show HN / Ask HN / comment threads), niche forums, Discourse communities, product forums |
| `appstore-reviews` | `research/sentiment/appstore-reviews.md` | Apple App Store + Google Play review listings for each competitor — BOTH 1–2-star (pain) and 5-star (praise) reviews |
| `linkedin-x` | `research/sentiment/linkedin-x.md` | `site:linkedin.com/posts` commentary, X/Twitter posts via web search, professional takes on the category |

Spawn template (fill `<platform_group>`, `<output_path>`, and the group's mining row):

```
subagent_type: ab-sentiment-miner
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the full body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are step 3 (social mining) of the appbuilder
  pipeline. Step 2 produced the competitor landscape; you mine ONE
  platform group for what real users say. Three sibling miners cover the
  other groups in parallel — do NOT stray into their platforms. After all
  four return, the orchestrator merges your files into
  research/sentiment-synthesis.md, and step 4 traces PRD features to
  your verbatim quotes. An unquoted pain point is invisible to the PRD.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - platform_group: <reddit | hn-forums | appstore-reviews | linkedin-x>
  - mine_these: <the group's "mine these" cell from the table>
  - post_quota: <25–40 standard | 60–100 premier> posts read and assessed
  - competitor_seeds: [<names + slugs from sentiment-seeds.md>]
  - output_path: <output_path>

  CONTEXT FILES (read these first):
  - runs/<run_tag>/idea.md
  - runs/<run_tag>/temp/sentiment-seeds.md
  - research/competitor-landscape.md (The set + Feature matrix sections) if
    present, otherwise runs/<run_tag>/temp/competitor-shortlist.md (the
    seeds file — step 2 runs concurrently and may not have merged yet)

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
    the real count — NEVER pad with marginal or off-topic posts.
  - End with a ## Sources section: URL + access date + one-line takeaway.
```

**CRITICAL: never emit bare text while miners are in flight.** A text-only response ends the turn and kills the pipeline. While waiting, append evolving thoughts to `runs/<run_tag>/temp/orchestrator-notes.md` (cross-platform patterns you expect, which pain points will likely top the synthesis, contradictions between store reviews and Reddit mood) every 30–60 seconds.

**Partial failure policy:** if a miner returns without its file, re-spawn it ONCE with the output path restated as its explicit required deliverable. If it fails twice, write the platform file yourself as a stub with `posts_mined: 0`, an honest "## Method" note explaining the failure, empty sections, and a Sources section listing whatever it did report — then proceed. Three good platforms beat a stalled run; the synthesis must NAME the missing platform as a coverage gap.

### 3.3 — The frequency × intensity rubric (used by miners AND your synthesis)

**frequency** (independent posts raising the same point): 1 = one post; 2 = two; 3 = 3–5; 4 = 6–9; 5 = ten or more.
**intensity** (emotional charge / stakes): 1 = passing mention; 2 = mild annoyance; 3 = recurring friction, complaint with emotion; 4 = blocks a core workflow, user describes a workaround; 5 = churn-grade — "I cancelled", "deleted the app", refund demands, data loss.
**score = frequency × intensity** (max 25). Score arithmetic is mechanical — never round a favorite pain point upward.

### 3.4 — Write `research/sentiment-synthesis.md` (orchestrator, after ALL four land)

Read all four platform files end to end, then synthesize yourself:

1. **Merge duplicates across platforms** — the same pain point worded four ways is ONE pain point. For each merged item: combined frequency = total independent posts across all four files, re-mapped to the 1–5 scale; intensity = the MAX observed on any platform; score = frequency × intensity.
2. **Top pain points** — ranked table: rank, pain point, freq, intensity, score, platforms seen on, competitor(s) concerned, then 1–3 verbatim quotes (with URL + date) under each entry.
3. **Wish list** — same structure, for asked-for-but-nonexistent capabilities.
4. **Praised features — do not break these** — what users love about competitors; the app must match or consciously diverge. Quote-backed.
5. **Platform mood summaries** — 3–5 lines per platform group; note any group reported thin or stubbed.
6. **Implications for the PRD** — 5–10 bullets addressed to step 4: which pain points demand must-features, which wishes are differentiators, which praised features are table stakes. Each bullet cites at least one quote already in this file.
7. **Sources** — the four platform files, plus any URLs you opened directly (URL + access date + one-line takeaway).

Every ranked item in the synthesis must carry at least one verbatim quote with a URL. An item you cannot quote does not appear.

---

## Artifacts

**`research/sentiment/<platform>.md`** — four files (`reddit.md`, `hn-forums.md`, `appstore-reviews.md`, `linkedin-x.md`), written by the miners:

```markdown
---
run_tag: habit-coach-3f9a2c
created: 2026-07-24
platform_group: reddit
posts_mined: 34
---

# Sentiment — Reddit

## Method              <!-- queries run (incl. the adversarial ones), venues covered,
                            honest thinness note if applicable -->
## Pain points (ranked)  <!-- table: Rank | Pain point | Freq | Intensity | Score |
                              Competitor(s) | Quotes (Q-ids) -->
## Wish list (ranked)    <!-- same table shape -->
## Praised features      <!-- what users love; quote-backed -->
## Quote bank            <!-- Q1, Q2, ...: "verbatim text" — platform, YYYY-MM-DD
                              (or "undated"), URL -->
## Competitor-specific signals  <!-- per-competitor mood in 1-3 lines each -->
## Sources               <!-- one line per source: URL — accessed YYYY-MM-DD — takeaway -->
```

Ranked tables cite quotes by Q-id; the Quote bank holds the verbatim text. Both live in the top-level research vault (NOT under runs/) so later runs reuse them.

**`research/sentiment-synthesis.md`** — frontmatter `run_tag`, `created`; sections listed in 3.4. This is step 4's primary demand-evidence input.

---

## Exit criteria

- All four `research/sentiment/<platform>.md` files exist with frontmatter `run_tag`, `created`, `platform_group`, `posts_mined`
- Each non-stubbed file meets the gear quota (25–40 standard / 60–100 premier posts mined) OR documents genuine platform thinness in `## Method` with the real count
- Each file shows at least one adversarial search in `## Method` and has a populated Quote bank + `## Sources` section
- Every pain-point and wish-list row in every file cites at least one Q-id resolving to a verbatim quote with a URL
- `research/sentiment-synthesis.md` exists; every ranked item carries a quote + URL; scores follow the 3.3 rubric; Implications for the PRD is non-empty
- Any stubbed platform is named as a coverage gap in the synthesis

Then update the manifest: `steps.3 = "done"`, mark the step-3 todo complete, return to the router.

---

## Next step

Return to the router (`appbuilder`). Once BOTH members of the 2 ∥ 3 pair are done, it invokes:

```
Skill(skill: "appbuilder-3-5-research-audit")
```

Step 3.5 tries to refute your top pain points and wish-list items before step 4 merges the audited synthesis with the landscape into the PRD — the ranked claims that survive become its feature-priority spine.
