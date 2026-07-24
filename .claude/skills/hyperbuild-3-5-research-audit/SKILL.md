---
name: hyperbuild-3-5-research-audit
description: >
  Step 3.5 of the hyperbuild pipeline — the adversarial research audit,
  running after steps 2 AND 3 (the 2 ∥ 3 concurrent pair) both
  complete. Spawns ONE hb-research-critic to attack
  research/competitor-landscape.md and research/sentiment-synthesis.md:
  refute the top 5 pain points and top 5 wish-list items (cherry-picked?
  one viral thread reposted five times? syndicated copies cluster as ONE
  source), live spot-check the version/feature claims most load-bearing
  for the PRD, and verify the top quotes verbatim against their URLs.
  The critic returns the complete research/research-audit.md document
  (per-claim verdict upheld | weakened | refuted); the orchestrator
  persists it and patches the two synthesis docs via surgical Edits —
  downgrade and annotate confirmed findings, move refuted claims to a
  "Refuted by audit" section, NEVER silently delete. Step 4 builds the
  PRD only on claims that survived. Invoked by the hyperbuild router via
  Skill(); not run directly by users.
---

# Step 3.5 — Research audit (1 critic, then orchestrator patches)

You are executing step 3.5 (research-audit) of the hyperbuild pipeline. It runs after steps 2 AND 3 both complete — they ran concurrently as the 2 ∥ 3 pair and filled the vault with the competitor landscape and the sentiment synthesis; step 4, your successor, builds the PRD directly on their top-ranked claims and must not cite a claim you refuted.

**Goal:** `research/research-audit.md` — a per-claim adversarial audit of the two synthesis docs (verdict `upheld | weakened | refuted`, with evidence) — then patch every confirmed finding into `research/competitor-landscape.md` and `research/sentiment-synthesis.md` via surgical Edits: annotate weakened claims, move refuted claims to a `## Refuted by audit` section, NEVER silently delete.

**Why this step exists:** a top-5 "pain point" that is really one viral thread reposted five times becomes a must feature (step 4), a feature-spec file (4.5), three mockups (8), an epic of tasks (11), and days of implementation (14). One adversarial pass here costs a single subagent; the same correction after step 8 costs re-mocking three design systems. Syndication is not consensus.

**Gear gate:** runs identically for both gears. The audit surface is fixed — top 5 pain points + top 5 wish-list items + the load-bearing landscape claims — regardless of gear; gear only sets how deep the corpus behind them is.

---

## Inputs

Read these before doing anything:

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`; confirm BOTH `steps["2"]` and `steps["3"]` are `"done"` — this step starts only after the full 2 ∥ 3 pair
- `research/competitor-landscape.md` — audit target (step 2)
- `research/sentiment-synthesis.md` — audit target (step 3)
- `research/sentiment/<platform>.md` — the quote banks + ranked tables behind the synthesis (the critic recounts from these)
- `research/competitors/<slug>.md` — the dossiers behind the landscape's version/feature claims

If either synthesis doc is missing, the responsible step failed silently — return to the router and resume at the missing step. Never audit from memory of steps 2–3.

Set `steps."3.5" = "running"` in the manifest, mark the step-3.5 todo in_progress.

---

## Procedure

1. **Select the audit surface (orchestrator).** From `research/sentiment-synthesis.md`: the top 5 pain points and top 5 wish-list items, verbatim, each with the Q-ids of its quotes. From `research/competitor-landscape.md`: the version/feature claims most load-bearing for the PRD — the table-stakes rows, the whitespace/opportunity claims, and any "only X ships this" positioning fact a differentiator would rest on (5–10 claims). Record the surface in `runs/<run_tag>/temp/orchestrator-notes.md`; it goes verbatim into the spawn prompt.

2. **Spawn ONE `hb-research-critic` to attack the surface.** Spawn template:

   ```
   subagent_type: hb-research-critic
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are the step 3.5 research critic of the
     hyperbuild pipeline. Steps 2 (market recon) and 3 (social mining)
     ran concurrently as the 2 ∥ 3 pair and are both done; step 4 will
     build the PRD directly on the top claims of their two synthesis
     docs, so you attack those claims BEFORE they become feature
     evidence. After you return, the orchestrator persists your document
     to research/research-audit.md and patches the synthesis docs itself
     via surgical Edits — weakened claims annotated, refuted claims
     moved to a "Refuted by audit" section, nothing silently deleted.
     You audit; you NEVER edit. You have no Write tool — your final
     message IS the complete research-audit.md document.

     YOUR INPUTS:
     - run_tag: <run_tag>
     - targets: research/competitor-landscape.md,
       research/sentiment-synthesis.md
     - audit_surface:
       - top_pain_points: [<the top 5, verbatim from the synthesis
         ranking, each with its Q-ids>]
       - top_wishes: [<the top 5 wish-list items, verbatim, with Q-ids>]
       - load_bearing_claims: [<the 5–10 version/feature claims
         selected in procedure item 1>]
       - top_quotes: [<Q-id + first words for every quote under the top
         pain points and wishes>]
     - output: the complete research-audit.md markdown document as your
       final message; frontmatter run_tag: <run_tag>,
       created: <YYYY-MM-DD>

     READ FIRST (context files, in this order):
     - runs/<run_tag>/idea.md
     - research/sentiment-synthesis.md
     - research/competitor-landscape.md
     - the research/sentiment/*.md files behind every audited pain
       point, wish, and quote — trace each Q-id to its quote-bank entry
       and URL
     - the research/competitors/*.md dossiers behind every audited
       version/feature claim

     ATTACK AXES (work every one):
     - Cherry-picking: recount each top claim's frequency from the
       platform files — does the per-source evidence actually support
       the rank, or was one loud thread quoted five times?
     - Syndication: cluster reposts, crossposts, syndicated articles,
       and quote-tweets of one origin BEFORE recounting — a cluster
       argues with the weight of ONE source. Syndication is not
       consensus.
     - Single viral thread: a pain point whose every quote traces to
       one thread is one anecdote, not a top-5 ranking.
     - Live spot-checks: for each load_bearing claim, check the live
       source (WebFetch/WebSearch: release notes, store listings,
       changelogs, pricing pages) — a stale or contradicted claim is
       refuted, with the live URL and access date.
     - Quote integrity: fetch each top quote's URL; the quoted text
       must appear VERBATIM at the source.
     - Internal inconsistency: the synthesis contradicting its own
       platform files (scores that don't multiply, claims with no
       source row anywhere).

     VERDICTS: upheld | weakened | refuted, per claim. Every weakened
     or refuted verdict carries evidence — a live URL, a recount
     (before → after clustering), or a named internal inconsistency —
     NEVER your own skepticism alone. Include a one-line suggested
     annotation for every weakened/refuted claim; the orchestrator owns
     the final wording.
   ```

3. **While the critic runs: NEVER emit bare text** — a text-only response ends the turn and kills the pipeline. Append your own doubts (which top claim you'd bet is syndication-inflated, which version claim looked stale) to `runs/<run_tag>/temp/orchestrator-notes.md` while you wait.

4. **Persist the audit.** The critic has no Write tool — its final message IS the document. Write it verbatim to `research/research-audit.md` yourself (durable state on disk survives a crash mid-patch). Then validate: frontmatter `run_tag` + `created` present; EVERY audit-surface item appears as an `A-NN` entry with a verdict `upheld | weakened | refuted`; every weakened/refuted verdict carries evidence (a live URL, a recount, or a named internal inconsistency). If an item is missing or a verdict is evidence-free, re-spawn the critic ONCE with the gaps named. Max 2 spawns total; after that, list still-unaudited items under a `## Audit gaps` section in the file and proceed — an honest gap beats a fabricated verdict.

5. **Patch the synthesis docs yourself via Edit — surgical, refuted first, then weakened.** The ORCHESTRATOR patches; the critic never does.
   - **Refuted claims:** MOVE the claim out of its ranked table/section into a `## Refuted by audit` section at the bottom of the SAME doc (create it on first use): the claim text, the audit id, the one-line reason. NEVER silently delete — a deleted claim gets innocently re-mined by a later run; a recorded refutation cannot. Renumber the ranked table mechanically; never invent a new claim to fill the hole.
   - **Weakened claims:** annotate in place — append the caveat to the claim's row/entry in the form `[weakened by audit: <one-line reason> — research/research-audit.md A-NN]`. Where a syndication recount corrected a frequency, recompute the score with step 3's frequency × intensity rubric — mechanical arithmetic, never rounded back up.
   - **Upheld claims:** no edit.
   - Patch, never regenerate: each fix is a small Edit hunk; never rewrite a section.
   - Reject a finding ONLY if it violates the critic's own contract (a "refutation" with no source and no named inconsistency); log each rejection with one line of reasoning in `runs/<run_tag>/temp/orchestrator-notes.md`.

6. **Spot-check your own patching.** Grep the two synthesis docs: every A-NN marked `weakened` has an inline `[weakened by audit: …]` annotation at its claim; every `refuted` claim appears under `## Refuted by audit` and NOT in its original ranked position.

---

## Artifacts

- `research/research-audit.md` — frontmatter `run_tag` + `created`; Method, per-claim `A-NN` audits (verdict `upheld | weakened | refuted`, evidence, syndication clusters, suggested annotation), version/feature spot-check table, quote-integrity table, Sources
- Patched `research/competitor-landscape.md` + `research/sentiment-synthesis.md` — inline `[weakened by audit: …]` annotations and `## Refuted by audit` sections per confirmed findings

---

## Exit criteria

- `research/research-audit.md` exists with frontmatter `run_tag` + `created`; every audit-surface item carries a verdict `upheld | weakened | refuted` with evidence (or is honestly listed under `## Audit gaps` after two failed spawns)
- Every refuted top claim is MOVED to a `## Refuted by audit` section in its synthesis doc; every weakened top claim carries its inline `[weakened by audit: …]` annotation citing an A-NN id
- No claim silently deleted — every refuted claim's text is still findable in its synthesis doc, under `## Refuted by audit`
- Scores corrected by syndication recounts follow step 3's frequency × intensity rubric

Then update the manifest: `steps."3.5" = "done"`, mark the step-3.5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). It invokes:

```
Skill(skill: "hyperbuild-4-product-spec")
```

Step 4 builds the PRD on the audited corpus — it must not cite a claim you moved to `Refuted by audit`, and it cites weakened claims only together with their caveat.
