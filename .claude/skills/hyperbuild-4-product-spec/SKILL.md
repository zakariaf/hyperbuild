---
name: hyperbuild-4-product-spec
description: >
  Step 4 of the hyperbuild pipeline — merges the competitor landscape (step 2)
  and sentiment synthesis (step 3), as audited by step 3.5, into the PRD at
  research/product-spec.md:
  personas, a MoSCoW feature list where every must/should traces to competitor
  evidence or user-demand quotes, differentiators, and THE CANONICAL SCREEN
  INVENTORY (each screen classified mockup_feasibility: full | partial | none)
  that steps 8, 11, and 14 all key off. Spawns 1 hb-spec-critic to
  attack the draft PRD; the orchestrator patches the findings itself via
  surgical Edits. Invoked by the hyperbuild router via Skill(); not run
  directly by users.
---

# Step 4 — Product spec (the PRD)

You are executing step 4 (product-spec) of the hyperbuild pipeline. Steps 2 ∥ 3 (run as the concurrent pair) filled the research vault with competitor dossiers and real-user sentiment, and step 3.5 — your immediate predecessor — adversarially audited their two synthesis docs, annotating weakened claims and moving refuted ones to `## Refuted by verification` sections (that exact heading — grep for it, not for any other wording); this step compresses the audited corpus into the single PRD that step 4.5 expands into per-feature specs and that steps 6–8 (design + mockups), 11 (epics), and 14 (implementation) all build from.

**Goal:** write `research/product-spec.md` — personas, differentiators, a fully-traced MoSCoW feature list, and the canonical screen inventory — then have `hb-spec-critic` attack it and patch every finding via Edit.

**Why this step exists:** everything downstream is derivative of this file. An untraced "must" here becomes a feature spec nobody asked for (4.5), three mockups of it (8), an epic of tasks for it (11), and days of implementation (14). Corrections applied here cost one Edit hunk; corrections applied after step 8 cost re-mocking three design systems.

---

## Inputs

Read these before doing anything:

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear` (standard | premier), `platform`; confirm `steps["2"]`, `steps["3"]`, and `steps["3.5"]` are `done`
- `runs/<run_tag>/decisions/platform.md` — chosen stack + rationale (shapes what screens are idiomatic)
Everything from steps 2, 3, and 3.5 lives in ONE area — `research/01-product-and-market/` — laid out in the four phases of `docs/RESEARCH-ARCHIVE.md` (`research/` → `verify/` → `critique/` → `author/`). Start at `_INDEX.md`, which lists every agent and file in it.

- `research/01-product-and-market/_INDEX.md` — the area map: every agent, grouped by phase, with file sizes and verify verdicts
- `research/01-product-and-market/author/competitor-landscape.md` — feature matrix + positioning map (step 2)
- `research/01-product-and-market/research/competitors/<slug>.md` — one dossier per competitor; skim all, deep-read the top 3
- `research/01-product-and-market/author/sentiment-synthesis.md` — ranked pain points + wish lists (step 3)
- `research/01-product-and-market/research/sentiment/<platform>.md` — verbatim user quotes; pull quotes from here, never paraphrase
- `research/01-product-and-market/verify/<dimension>--<claim-slug>.md` — the adversarial fact-checks, one per load-bearing claim, each with a closed-vocabulary verdict (`CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE`). **A `verify/` file OVERRIDES the `research/` file it checked** (`docs/RESEARCH-ARCHIVE.md` §7): a REFUTED claim MUST NOT appear as fact in the PRD, a PARTIALLY_TRUE claim carries its correction wherever it appears, and an UNVERIFIABLE claim may never be the sole support for a `must`.
- `research/01-product-and-market/critique/research-audit.md` — step 3.5's per-claim verdicts (`upheld | weakened | refuted`). **THE PRD MUST NOT CITE A CLAIM THE AUDIT REFUTED; a weakened claim may be cited only together with its audit caveat.**

**The `research/` phase is UNVERIFIED by construction.** Read it for breadth, then check `verify/` before you put any version, price, licence, or policy claim into the PRD.

If `author/competitor-landscape.md`, `author/sentiment-synthesis.md`, or `critique/research-audit.md` is missing, the responsible step failed silently — return to the router and resume at the missing step. Do NOT draft a PRD from memory of steps 2–3.5.

---

## Procedure

1. **Draft personas (2–4).** Each persona is grounded in sentiment evidence, not invented: name, one-line context, top 2 goals, top 2 frustrations — each frustration backed by a verbatim quote from `research/01-product-and-market/research/sentiment/*.md` with the file path. A persona with zero quotes behind it is fiction; cut it.

2. **Build the feature candidate pool from BOTH evidence streams.**
   - From the competitor matrix: features that appear in most competitors (table stakes), features only leaders have (competitive bar), features nobody has that pain points demand (openings).
   - From `sentiment-synthesis.md`: the ranked pain points and wish lists — every top-5 pain point MUST map to at least one candidate feature or be explicitly declined in Won't with a reason.

3. **Classify MoSCoW (must / should / could / won't for v1).** The tracing rule is absolute:

   **NO EVIDENCE ⇒ NOT A MUST. Every must and every should carries an Evidence line citing either (a) a competitor dossier path + what the competitor ships, or (b) a sentiment file path + a verbatim user quote demanding it. A candidate with neither gets demoted to could — never fabricate a citation.**

   Scope discipline: step 4.5 gives every must/should its own spec file, capped at **15 files (standard) / 25 (premier)**. A must+should list longer than the cap is a scoping failure — trim NOW, here, where trimming is one deleted bullet. Populate Won't (v1) aggressively: every plausible scope trap you decline (accounts vs. local-only, multi-device sync, social features, monetization) is written down with a one-line reason so step 11 doesn't re-invent it.

4. **Write differentiators (2–4).** Each names the positioning gap from `competitor-landscape.md` it exploits and the sentiment evidence that users want it. A "differentiator" that every competitor already ships is a table stake — the spec critic will catch this, so check the matrix yourself first.

5. **Write THE CANONICAL SCREEN INVENTORY.** This is the single highest-leverage artifact in the PRD. It is the definitive, named list of every screen in the app:
   - Each entry: human name (e.g. "Habit Detail"), kebab-case slug (e.g. `habit-detail`), purpose (one line), features served (MoSCoW ids), key states (empty / loading / error where relevant), and a `mockup_feasibility` classification.
   - **Classify `mockup_feasibility` for EVERY screen: `full` | `partial` | `none`.** `full` = standard UI, fully mockable in HTML — the default; most screens. `partial` = engine/camera/map/canvas content whose CHROME (HUD, overlays, menus) IS mockable around a clearly-marked placeholder viewport — every `partial` entry carries a one-line note of what IS mockable (e.g. "HUD + pause menu mockable; 3D viewport is placeholder"). `none` = pure engine-rendered, nothing mockable — step 8 gives it an art-direction card in each design's design-system.md instead of a mockup. Misclassification costs both ways: `full` on engine content forces step 8 to fake the unfakeable; `none` on ordinary UI silently deletes three mockups.
   - **Downstream contract — say-once, use-everywhere:** step 8 builds `designs/{a,b,c}/mockups/<slug>.html` for EVERY `full`/`partial` screen listed here (`none` screens get an art-direction card per design instead); step 4.5 feature files list these names verbatim in `screens:` frontmatter; step 11 tasks reference them; step 14 implementers open the chosen mockup by slug. After this step exits, the inventory is FROZEN — a rename downstream orphans mockups and breaks task references.
   - **Cap: 12 screens (standard) / 20 (premier)** — step 8 mocks every `full`/`partial` screen up to this cap, so an over-cap inventory means unmockable screens. Consolidate (tabs within one screen, sheets/dialogs as states of a parent screen) until you fit.
   - Every must/should feature maps to ≥1 screen; every screen serves ≥1 must/should feature. Include the screens everyone forgets: onboarding/first-run, settings, and auth if the platform decision requires it.

   **⚠ If you find yourself about to write the PRD without a named screen inventory, STOP.** A PRD whose screens are implied ("obviously there's a list view...") forces steps 8, 11, and 14 to each invent their own screen list — three inconsistent inventions. Name every screen here, once.

6. **Write `research/product-spec.md`.** Skeleton (all sections required, this order):

   ```markdown
   ---
   run_tag: <run_tag>
   created: <YYYY-MM-DD>
   step: 4
   platform: <platform from decisions/platform.md>
   gear: <standard|premier>
   ---

   # <App name> — Product Spec

   ## Product statement
   Two sentences: what it is, who it's for, why it wins. Must be recognizably
   the user's idea — re-read runs/<run_tag>/idea.md before writing this.

   ## Personas
   ### P1 — <name>
   - Context: ...
   - Goals: ...
   - Frustrations: "<verbatim quote>"
     — research/01-product-and-market/research/sentiment/reddit.md

   ## Differentiators
   1. **<differentiator>** — gap: <from author/competitor-landscape.md>; demand:
      "<verbatim quote>"
      — research/01-product-and-market/research/sentiment/<platform>.md

   ## Features (MoSCoW)
   ### Must
   #### M1 — <feature name>
   - What: ...
   - Why: ...
   - Evidence: research/01-product-and-market/research/competitors/<slug>.md
     (<competitor> ships this since v<X>);
     research/01-product-and-market/research/sentiment/appstore-reviews.md
     — > "<verbatim quote>"
   - Screens: <Screen Name>, <Screen Name>
   ### Should
   #### S1 — ... (same shape as M1)
   ### Could
   - <name> — one line each; Evidence optional
   ### Won't (v1)
   - <name> — declined because <one line>

   ## Screen inventory (CANONICAL)
   | # | Screen | slug | Purpose | Features served | Key states | mockup_feasibility |
   |---|--------|------|---------|-----------------|------------|--------------------|
   | 1 | Home   | home | ...     | M1, M3, S2      | empty, loading | full |
   | 2 | Race   | race | ...     | M2              | loading        | partial — HUD + pause menu mockable; 3D viewport is placeholder |

   ## Open questions
   - <anything evidence couldn't settle — step 4.5 and step 11 read these>

   ## Sources
   - research/01-product-and-market/author/competitor-landscape.md — feature matrix consumed
   - research/01-product-and-market/author/sentiment-synthesis.md — pain-point ranking consumed
   - <every dossier and sentiment file actually cited above, one line each>
   - <every verify/ file whose verdict changed a claim you used — with the verdict>
   ```

   This step does no web research — its Sources section lists the vault files it consumed. Every Evidence line in the body must point at a real file written by step 2 or 3; spot-check your own citations before spawning the critic.

7. **Spawn ONE `hb-spec-critic` to attack the draft.** Spawn template:

   ```
   subagent_type: hb-spec-critic
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are the step 4 spec critic of the hyperbuild
     pipeline. The orchestrator has just drafted the PRD at
     research/product-spec.md from the step-2 competitor research and the
     step-3 sentiment research. After you return, the orchestrator patches
     your findings into the PRD via surgical Edits; step 4.5 then expands
     every must/should into its own feature-spec file, and steps 8, 11, and
     14 key off the PRD's screen inventory verbatim. You review; you NEVER
     edit. You have no Write tool — your final message IS your findings
     artifact.

     YOUR INPUTS:
     - run_tag: <run_tag>
     - draft_prd: research/product-spec.md
     - gear: <standard|premier> (screen cap <12|20>, feature-file cap <15|25>)
     - output: a findings JSON object returned as your final message (schema below)

     READ FIRST (context files, in this order):
     - runs/<run_tag>/idea.md
     - runs/<run_tag>/decisions/platform.md
     - research/product-spec.md
     - research/01-product-and-market/_INDEX.md — the area map: which
       claims were fact-checked and with what verdict
     - research/01-product-and-market/author/competitor-landscape.md
     - research/01-product-and-market/author/sentiment-synthesis.md
     - spot-check research/01-product-and-market/research/competitors/*.md
       and research/01-product-and-market/research/sentiment/*.md wherever
       the PRD cites them — verify the citation says what the PRD claims it
       says
     - research/01-product-and-market/verify/*.md — a verify file OVERRIDES
       the research file it checked (docs/RESEARCH-ARCHIVE.md §7). A PRD
       claim resting on a REFUTED verdict, or a PARTIALLY_TRUE claim cited
       without its correction, is a `critical` finding.

     ATTACK AXES (check every one):
     - Untraced must/should: any M/S feature with no Evidence line, or an
       Evidence line pointing at a file that doesn't exist
     - Trace-washing: Evidence cited that does not actually support the
       feature when you read it
     - Unanswered pain: a top-5 pain point in sentiment-synthesis.md with no
       feature answering it and no Won't entry declining it
     - Fake differentiator: a differentiator the competitor matrix shows
       most competitors already ship
     - Screen gaps: a must feature whose primary flow has no screen to
       happen on; a screen serving no must/should feature; inventory over
       the cap; missing onboarding or settings
     - Feasibility errors: a screen with no mockup_feasibility value; a
       `full` classification on engine/camera/map/canvas content; a
       `none` classification on ordinary UI; a `partial` screen missing
       its one-line note of what IS mockable
     - Scope bloat: a must list that cannot plausibly ship as v1, or
       must+should exceeding the feature-file cap
     - Ungrounded persona: a persona with no sentiment quote behind it
     - Idea drift: anything in the PRD the verbatim idea does not support

     FINDINGS SCHEMA (your entire final message is this JSON, nothing else):
     {"findings": [{"severity": "critical|major|minor",
       "section": "<the H2/H3 heading it anchors to>",
       "problem": "<one sentence>",
       "evidence": "<vault path + what it actually says>",
       "fix": "<what the edit should accomplish — NOT exact wording>"}]}

     At most 12 findings, most load-bearing first. Do NOT include exact
     old_text/new_text patches — the orchestrator owns the wording. A
     finding that doesn't serve the verbatim idea is a finding the
     orchestrator will reject.
   ```

8. **While the critic runs: NEVER emit bare text** — a text-only response ends the turn and kills the pipeline. Append your own second-pass doubts about the draft to `runs/<run_tag>/temp/orchestrator-notes.md` while you wait.

9. **Persist the findings.** When the critic returns, write its JSON verbatim to `runs/<run_tag>/temp/prd-critic-findings.json` yourself (the critic has no Write tool; durable state on disk survives a crash mid-patch).

10. **Patch the findings yourself via Edit — surgical, in severity order (critical → major → minor).**
    - Each fix is a small Edit hunk to `research/product-spec.md`. Never regenerate a section; never rewrite the file. Patch, never regenerate.
    - Fixing an untraced must: find real evidence in the vault, or DEMOTE the feature. Never invent a citation to satisfy the critic.
    - Screen-inventory fixes (add/rename/merge screens) are legal HERE and only here — this is the last moment before the inventory freezes.
    - Reject findings that contradict the verbatim idea; log each rejection with one line of reasoning appended to `runs/<run_tag>/temp/prd-critic-findings.json` under a `"rejected"` key.
    - If any finding was `critical`, re-spawn the critic ONCE (same template) to verify the patches. Max 2 critic rounds total; after round 2, move any still-open finding into the PRD's `## Open questions` honestly and proceed.

---

## Artifacts

- `research/product-spec.md` — the PRD, frontmatter `run_tag` + `created` + `step: 4`, all sections from the skeleton above
- `runs/<run_tag>/temp/prd-critic-findings.json` — the critic's findings + your rejections (audit trail)

---

## Exit criteria

- `research/product-spec.md` exists with every skeleton section present
- Every must and should feature has a non-empty Evidence line citing an existing `research/` file
- Every top-5 pain point in `sentiment-synthesis.md` is answered by a feature or declined in Won't
- Screen inventory: every screen named + slugged; count ≤ 12 (standard) / ≤ 20 (premier); every must/should maps to ≥1 screen; every screen classified `mockup_feasibility: full | partial | none`, every `partial` with its one-line what-IS-mockable note
- must+should count ≤ 15 (standard) / ≤ 25 (premier)
- Critic ran ≥1 round; every finding is patched, rejected-with-reason, or moved to Open questions (≤2 rounds)

Then update manifest: `steps.4 = done`, mark the step-4 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). Invoke step 4.5:

```
Skill(skill: "hyperbuild-4-5-feature-specs")
```

Step 4.5 expands every must/should into `features/NN-<slug>.md` — it copies screen names from your inventory verbatim, so the inventory you just froze is now load-bearing.
