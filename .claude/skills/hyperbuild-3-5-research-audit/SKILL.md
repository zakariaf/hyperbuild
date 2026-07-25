---
name: hyperbuild-3-5-research-audit
description: >
  Step 3.5 of the hyperbuild pipeline — the VERIFY + CRITIQUE + INDEX
  phases of research area 01-product-and-market, and the home of the
  REUSABLE VERIFICATION ENGINE that steps 5, 6 and 9 re-run over their
  own areas. Runs after steps 2 AND 3 (the 2 ∥ 3 pair) both complete.
  Reads the area claim registry runs/<run_tag>/temp/claims-01.json,
  spawns ONE hb-claim-verifier PER CLAIM in parallel batches — each told
  to REFUTE its single claim against primary sources and to write
  research/01-product-and-market/verify/<dimension>--<claim-slug>.md
  with a closed-vocabulary verdict (CONFIRMED | PARTIALLY_TRUE |
  REFUTED | UNVERIFIABLE) — then runs the CRITIQUE PANEL (2 standard /
  3 premier, distinct lenses) over the whole area corpus. The
  orchestrator then PATCHES the area's author/ syntheses per verdict:
  REFUTED claims leave the argument and are recorded under
  "## Refuted by verification", PARTIALLY_TRUE claims carry their
  correction inline, nothing is ever silently deleted — and closes the
  area with _INDEX.md. Invoked by the hyperbuild router via Skill(); not
  run directly by users.
---

# Step 3.5 — Area 01 verification (verify → critique → patch → index)

You are executing step 3.5 (research-audit) of the hyperbuild pipeline. Steps 2 and 3 ran concurrently as the 2 ∥ 3 pair and filled `research/01-product-and-market/research/` with competitor dossiers and per-platform sentiment files, then drafted the two `author/` syntheses. Those findings are UNVERIFIED BY CONSTRUCTION. Step 4, your successor, builds the PRD directly on the syntheses and must never cite a claim you refuted.

**BINDING FORMAT CONTRACT: `docs/RESEARCH-ARCHIVE.md`.** Read it before you spawn anything, and cite it BY PATH in every spawn prompt. Its violations are DEFECTS, not style disagreements — a file that breaks it is rejected and the agent re-spawned.

**THIS STEP IS ALSO THE ENGINE.** Steps 5, 6 and 9 do NOT re-derive this procedure — each cites "the verification engine described in step 3.5, applied to area `<NN>`", binds the parameter block below, and runs phases V1–V6 unchanged. Anything you change in the engine section changes all four research areas.

**Goal:** every load-bearing claim in area 01 has a `verify/` file whose verdict was reached by an agent trying to REFUTE it; a critique panel has read the whole area corpus; both `author/` syntheses have been patched so they rest only on claims that survived; and `research/01-product-and-market/_INDEX.md` lists every agent, grouped by phase, with file sizes.

**Why this step exists:** a top-5 "pain point" that is really one viral thread reposted five times becomes a must feature (step 4), a feature-spec file (4.5), three mockups (8), an epic of tasks (11), and days of implementation (14). One adversarial pass here costs a batch of cheap subagents; the same correction after step 8 costs re-mocking three design systems. Syndication is not consensus, and WHEN A FACT-CHECKER DISAGREES WITH A RESEARCHER, THE FACT-CHECKER IS USUALLY RIGHT — it checked primary sources against one specific claim while the researcher was surveying a whole dimension.

**Gear gate:** `standard` — 3–5 claims verified per dimension, area budget ≤25 verifiers, 2 critics. `premier` — 6–10 claims per dimension, area budget ≤60 verifiers, 3 critics. Read `gear` from the manifest first.

---

## Inputs

Read these before doing anything:

- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL.
- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`; confirm BOTH `steps["2"]` and `steps["3"]` are `"done"` — this step starts only after the full 2 ∥ 3 pair
- `docs/RESEARCH-ARCHIVE.md` — the BINDING format contract (§3.2 verify files, §4 provenance, §5 claim→verify, §6 verifier template, §7 synthesis rule)
- `runs/<run_tag>/temp/claims-01.json` — the area claim registry steps 2 and 3 appended to as their research files landed
- `research/01-product-and-market/research/competitors/<slug>.md` — the dossiers behind the landscape's claims
- `research/01-product-and-market/research/sentiment/<platform>.md` — the quote banks + ranked tables behind the sentiment synthesis
- `research/01-product-and-market/author/competitor-landscape.md` — patch target (step 2)
- `research/01-product-and-market/author/sentiment-synthesis.md` — patch target (step 3)

If either `author/` doc is missing, the responsible step failed silently — return to the router and resume at the missing step. Never verify from memory of steps 2–3.

Set `steps."3.5" = "running"` in the manifest, mark the step-3.5 todo in_progress, then
`mkdir -p research/01-product-and-market/verify research/01-product-and-market/critique runs/<run_tag>/temp`.

---

## Procedure — bind the parameters, then run the engine

Area 01 binds the engine like this, then runs phases **V1 → V6** below verbatim:

| Engine parameter | Area 01 binding |
|---|---|
| `AREA` | `01-product-and-market` |
| `AREA_TITLE` | `Product & market` |
| `CLAIMS` | `runs/<run_tag>/temp/claims-01.json` |
| `RESEARCH_DIR` | `research/01-product-and-market/research/` (`competitors/<slug>.md`, `sentiment/<platform>.md`) |
| `VERIFY_DIR` | `research/01-product-and-market/verify/` |
| `CRITIQUE_DIR` | `research/01-product-and-market/critique/` |
| `AUTHOR_DOCS` | `research/01-product-and-market/author/competitor-landscape.md`, `research/01-product-and-market/author/sentiment-synthesis.md` |
| `INDEX` | `research/01-product-and-market/_INDEX.md` |
| `PANEL` | completeness → `hb-corpus-critic` → `critique/completeness-critic.md` · skeptic → **`hb-research-critic`** → `critique/research-audit.md` · premier only: domain → `hb-corpus-critic` → `critique/domain-<slug>-critic.md` |
| `VERIFY_BUDGET` | ≤25 standard / ≤60 premier |
| `CONSUMER` | step 4 (the PRD) |

**Area-01 panel exception (deliberate, do not copy to other areas):** the skeptic seat is filled by `hb-research-critic`, not `hb-corpus-critic`. Area 01's evidence is social posts, store reviews and vendor pages, so its skeptic lens needs live fetches: syndication clustering (reposts, crossposts, aggregator mirrors and quote-tweets of one origin are ONE source) and verbatim quote integrity cannot be judged from the corpus alone. Areas 02–04 fill all seats with `hb-corpus-critic`.

---

## THE VERIFICATION ENGINE (reusable — steps 5, 6 and 9 run this section)

Bind this parameter block before phase V1. Every path below is written in terms of it, so the engine is area-agnostic:

```
AREA            = <NN-area-name>            # FIXED name, never platform-specific
AREA_TITLE      = <human title>
CLAIMS          = runs/<run_tag>/temp/claims-<NN>.json
RESEARCH_DIR    = research/<AREA>/research/
VERIFY_DIR      = research/<AREA>/verify/
CRITIQUE_DIR    = research/<AREA>/critique/
AUTHOR_DOCS     = research/<AREA>/author/<doc>.md  (one or more)
INDEX           = research/<AREA>/_INDEX.md
PANEL           = ≥2 DISTINCT lenses, one file each; THE AREA BINDS THE COUNT —
                  areas 01, 03, 04: 2 standard / 3 premier · area 02: 3 / 5
                  (engineering is the largest corpus and the only one whose
                  contradictions compile into code; the knobs tables in
                  README.md, PIPELINE.md, docs/SPEC.md and the router all
                  record this exception as "2–3 / 3–5, the area binds it")
VERIFY_BUDGET   = 25 (standard) | 60 (premier)
CONSUMER        = the step that reads AUTHOR_DOCS next
```

### V1 — Load and complete the claim registry

1. Read `CLAIMS`. Schema — one object per candidate claim, appended by the research-phase steps as each `research/` file landed:

   ```json
   {
     "run_tag": "habit-coach-3f9a2c", "area": "01-product-and-market",
     "gear": "standard", "created": "2026-07-24",
     "claims": [{
       "id": "C-01",
       "dimension": "competitor-streaks",
       "source_file": "research/01-product-and-market/research/competitors/streaks.md",
       "claim": "<the H3 heading under ## Summary, verbatim>",
       "claim_slug": "<per the slug rule in V2>",
       "detail": "<the claim's body, verbatim>",
       "sources": ["https://…"],
       "confidence": "high|medium|low",
       "load_bearing": true,
       "selected": true,
       "verdict": null,
       "correction": null
     }]
   }
   ```

   The registry is the same shape in every area (`claims-01.json` … `claims-04.json`), and
   it is the authority step 12's reusability guide reads: `verdict` + `selected` are what
   make "the synthesis may only rest on surviving claims" mechanically checkable instead of
   a good intention.

2. **If `CLAIMS` is missing, empty, or covers fewer than half the files in `RESEARCH_DIR`, build it yourself** — do not skip verification because an upstream step forgot to register. Per ARCHIVE §5: read EVERY `research/` file in the area, take every `###` heading under `## Summary` as one candidate claim, and write the registry to `CLAIMS`. A heading that is a topic label (`Competitor pricing`) rather than a complete assertion is a DEFECT in the research file: register it with `"defect": "topic-label"`, exclude it from the verify surface, and list it in `_INDEX.md` under `## Unverified`.

3. **THE PREMISE TRAP (ARCHIVE §6).** A fact stated in a brief is the one claim nobody checks. Sweep `runs/<run_tag>/idea.md`, `decisions/platform.md` and your own spawn prompts for asserted environment facts — today's date, an SDK or "stable is X" version, a price, a store policy — and register EACH as a claim with `"dimension": "premise"` and `"load_bearing": true`. They go into the verify surface ahead of everything else.

### V2 — Select the verify surface

Per ARCHIVE §5, keep per dimension: **3–5 claims (standard) / 6–10 (premier)**, ranked —

1. every claim marked `load_bearing`, `premise` first;
2. every claim carrying a version, price, licence, policy, statistic or API/feature name;
3. every claim `CONSUMER` would turn into a `must`-level decision.

If the per-dimension selection exceeds `VERIFY_BUDGET`, keep the highest-ranked claims until the budget is full — never drop a whole dimension to make room. Mark every kept claim `"selected": true` and every dropped one `"selected": false` in `CLAIMS` (the unselected entries are how `_INDEX.md` and step 12's guide state honestly what was never checked), and record the surface in `runs/<run_tag>/temp/orchestrator-notes.md`. FINDINGS THAT WERE NOT VERIFIED WERE NOT CHECKED, and the index must say so.

Compute each output path now: `VERIFY_DIR<dimension>--<claim_slug>.md`. **The `dimension` value is ALREADY FLAT — use it VERBATIM, never re-derive or shorten it.** The registering steps choose it precisely so this path is deterministic and every citation resolves: area 01 uses `competitor-<slug>` (step 2) and `sentiment-<platform_group>` (step 3); areas 02–04 use the dimension slug itself. If a registry entry ever carries a slash, fix the entry, not the filename. CLAIM SLUG (ARCHIVE §3.2) = the first ~50 characters of the claim, lowercased, every non-alphanumeric run collapsed to one hyphen, trailing hyphens trimmed. Compute it, never eyeball it:

```bash
python3 -c "import re,sys; s=sys.argv[1][:50].lower(); print(re.sub(r'-+$','',re.sub(r'[^a-z0-9]+','-',s)))" "<the claim, verbatim>"
```

Mid-word truncation is expected — it is an identifier, not a sentence. If two claims in one dimension slug identically, append `-2`, `-3`.

### V3 — Fan out ONE `hb-claim-verifier` PER CLAIM (parallel, batched)

ONE AGENT PER CLAIM IS THE MECHANISM. One agent handed five claims confirms all five — it has no budget to lose an argument with itself. Spawn ALL IN PARALLEL, IN ONE MESSAGE; if the surface exceeds ~15 claims, send back-to-back messages of **≤15 Task calls each**. NEVER collapse claims onto one agent to save spawns, and never send one claim per message.

```
subagent_type: hb-claim-verifier
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are a claim verifier in the VERIFY phase of
  research area <AREA> of the hyperbuild pipeline. The research phase
  surveyed this area for breadth and its findings are UNVERIFIED by
  construction; you hold exactly ONE of its claims. Other verifiers hold
  the others in parallel — do NOT check any claim but yours. After you
  return, a critique panel reads the whole area corpus and the
  orchestrator patches <AUTHOR_DOCS> per your verdict; <CONSUMER> then
  builds on claims that survived you. You write ONE file. You NEVER edit
  a research/ or author/ file.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: <AREA>
  - dimension: <dimension>
  - claim_id: <C-NN>
  - output_path: <VERIFY_DIR><dimension>--<claim-slug>.md
  - today: <YYYY-MM-DD>

  CONTEXT FILES (read these first):
  - docs/RESEARCH-ARCHIVE.md — §3.2 (your file format), §4 (the
    provenance rule), §6 (the assignment below IS that template)
  - <source_file> — your claim's own section ONLY; you are checking the
    claim, not reviewing the file

  ---- THE ASSIGNMENT (docs/RESEARCH-ARCHIVE.md §6) ----

  You are an ADVERSARIAL FACT-CHECKER for the <AREA_TITLE> research
  corpus of <the app, one line>. Today is **<YYYY-MM-DD>**.

  A researcher studying "<dimension>" made this claim, and a project
  decision depends on it.

  CLAIM: <the H3 heading, verbatim>
  DETAIL: <the claim's body, verbatim>
  CLAIMED SOURCES: <the claim's source URLs, comma-separated>
  CONFIDENCE: <high|medium|low>

  REFUTE IT. Use WebSearch and WebFetch against PRIMARY sources: the
  vendor's or maintainer's own documentation, the package registry page
  (for the real current version, publisher, and maintenance status), the
  official API reference (for real signatures), the standards-body or
  store-policy text itself, and the actual GitHub repo (for whether it
  is archived or discontinued). A tutorial, a blog post, an aggregator
  answer, or your own recollection is NOT a primary source.

  The failure modes you are hunting for, in order of likelihood:
  1. **Version rot** — the claim was true two years ago. APIs get
     deprecated and removed, defaults flip, prices change, store
     policies change.
  2. **Dead or abandoned tools presented as alive.** CHECK THE REPO: is
     it archived? When was the last release? Does the registry mark it
     discontinued or deprecated?
  3. **Invented or misremembered API/feature names.** If the claim names
     a method, class, parameter, plan tier, or setting, VERIFY THAT
     EXACT NAME EXISTS in the official reference. Plausible-sounding
     names are a specific hazard here.
  4. **Cargo cult** — one team's practice, or a big-company practice,
     presented as universal when the cited source does not say that.
  5. **Overstated consensus** — "the community recommends X" when it is
     one blog post.

  Default to refuted=true if you cannot independently substantiate it.
  CONFIRMED if it checks out. PARTIALLY_TRUE + a correction if
  directionally right but wrong in specifics (name the exact right
  version/API/number). UNVERIFIABLE if no source settles it — and say
  that plainly rather than guessing.

  Write <VERIFY_DIR><dimension>--<claim-slug>.md in the format of
  docs/RESEARCH-ARCHIVE.md §3.2, and END THE FILE with THIS ENTIRE
  PROMPT, verbatim, inside the provenance block (§4).
```

**Never emit bare text while verifiers are in flight** — a text-only response ends the turn and kills the pipeline. Between batches, append your own doubts (which claim you'd bet is syndication-inflated, which version claim looked stale, which price nobody sourced) to `runs/<run_tag>/temp/orchestrator-notes.md` with Edit/Write.

**Validation, per returned file:** it exists at its computed path; frontmatter carries `phase: verify`, `claim` (verbatim) and a `verdict` from the CLOSED vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE` — no "mostly true", no percentages, no hedging; a `PARTIALLY_TRUE` verdict names the exact right value in its **Correction** ("directionally right" is not a correction); the Evidence names WHICH primary source was fetched; the file ends with its provenance block. A file that fails any of these is re-spawned ONCE with the failed check quoted verbatim. Max 2 spawns per claim; a claim whose verifier never returns a valid file gets `"verdict": "UNVERIFIABLE"`, `"note": "verifier failed"` in `CLAIMS` and a line in `_INDEX.md` under `## Unverified`.

**Fold every verdict back into `CLAIMS`** — write each claim's `verdict` and `correction` from its verify file before you patch anything. V5 patches from that JSON, and step 12 reads it.

### V4 — The critique panel (parallel, ONE message)

Single-claim fact-checks cannot see the defect class where three dimensions each ship a different, internally consistent story. Spawn the panel **after** V3 lands, all seats in ONE message, each with a DISTINCT lens and its own output file:

| Lens | Critic file | Std | Prem | Lens brief |
|---|---|---|---|---|
| completeness | `completeness-critic.md` | yes | yes | Which dimension was NEVER researched? What did every agent assume without checking? Where is the corpus silent on something `CONSUMER` must decide? |
| skeptic | `research-audit.md` (area 01) | yes | yes | Which conclusions does the evidence NOT support? Name the claims whose support is one source, one blog post, or one syndicated cluster; name what verification changed. |
| domain | `domain-<slug>-critic.md` | — | yes | The area's own expert lens (regulatory/clinical/security/accessibility/market — pick from the idea), attacking the corpus on domain grounds the generalists cannot see. |

```
subagent_type: hb-corpus-critic          # area 01 skeptic seat: hb-research-critic
prompt: |
  APP IDEA (verbatim, gospel):
  > {{paste the body of runs/<run_tag>/idea.md}}

  IDEA FILE: runs/<run_tag>/idea.md

  PIPELINE POSITION: You are the <lens> critic of research area <AREA>
  of the hyperbuild pipeline. The research phase surveyed this area, and
  one adversarial fact-checker per load-bearing claim has already
  written <VERIFY_DIR> — each verdict is CONFIRMED, PARTIALLY_TRUE,
  REFUTED or UNVERIFIABLE. You read the WHOLE corpus under ONE lens and
  hunt the defects no single-claim check can see. After you return, the
  orchestrator patches <AUTHOR_DOCS>; <CONSUMER> builds on the result.
  You NEVER edit another agent's file.

  YOUR INPUTS:
  - run_tag: <run_tag>
  - area: <AREA>
  - lens: <completeness | skeptic | domain:<slug>>
  - lens_brief: <the row from the panel table, verbatim>
  - output_path: <CRITIQUE_DIR><critic-file>
  - other_seats: [<the other lenses running in parallel — do not
    duplicate their brief>]
  - orchestrator's suspicions (leads, not conclusions — confirm or kill
    each): <your notes from runs/<run_tag>/temp/orchestrator-notes.md>

  CONTEXT FILES (read these first):
  - docs/RESEARCH-ARCHIVE.md — §3.3 (your file format), §4 (provenance),
    §7 (the synthesis rule your findings feed)
  - every file in <RESEARCH_DIR> (breadth — unverified by construction)
  - every file in <VERIFY_DIR> (the verdicts — these OVERRIDE research/)
  - <AUTHOR_DOCS> (the syntheses your findings will patch)

  Mark every finding [VERIFIED] (you read or ran the thing) or [OPEN]
  (you reasoned about it). Every criticism NAMES FILES. End with
  ## Recommended patches — one line per edit you want made to
  <AUTHOR_DOCS>. END THE FILE with THIS ENTIRE PROMPT, verbatim, inside
  the provenance block (§4).
```

**While the critics run: never emit bare text** — keep appending to `runs/<run_tag>/temp/orchestrator-notes.md`.

Area 01's skeptic seat spawns `hb-research-critic` instead, and its prompt adds an `audit_surface`: the top 5 pain points + top 5 wish-list items verbatim with their Q-ids, the load-bearing landscape claims, the top quotes, and THE SYNDICATION RULE — cluster reposts, crossposts, syndicated articles and quote-tweets by origin BEFORE any frequency verdict, recount over clusters, and fetch each top quote's URL to confirm the text appears verbatim. It returns per-claim `A-NN` entries with SYNTHESIS-level verdicts `upheld | weakened | refuted`; V5 treats a `refuted` A-NN exactly like a REFUTED claim (same `## Refuted by verification` section, citing `critique/research-audit.md` A-NN) and a `weakened` one like PARTIALLY_TRUE, annotated `[weakened by audit: <reason> — critique/research-audit.md A-NN]`.

### V5 — Patch the `AUTHOR_DOCS` yourself (orchestrator only, surgical Edits)

THE ORCHESTRATOR PATCHES. Critics and verifiers never do. Work verdict by verdict — REFUTED first, then PARTIALLY_TRUE, then UNVERIFIABLE — and per ARCHIVE §7 **never rewrite a `research/` file**: it is the honest record of what one surveying agent believed, and rewriting it destroys the evidence that verification works.

- **REFUTED** — REMOVE the claim from the argument: delete its row from the ranked table / its bullet from the recommendation, renumber mechanically, and never invent a replacement to fill the hole. Then RECORD it under a `## Refuted by verification` section at the bottom of the SAME author doc (create on first use), one line per claim: the claim verbatim, the `verify/` file path, and the one-line reason. Any recommendation that rested on it is re-derived from surviving claims or dropped — say which, in that section.
- **PARTIALLY_TRUE** — annotate INLINE at the claim, in the form `[corrected by verification: <the exact correction> — verify/<file>.md]`, and replace the wrong specific with the right one wherever the doc states it: the corrected version ships, the original phrasing does not survive into the synthesis. Where a syndication recount corrected a frequency, recompute the score with step 3's frequency × intensity rubric — mechanical arithmetic, never rounded back up.
- **UNVERIFIABLE** — annotate `[unverified: no primary source settles this — verify/<file>.md]`. It may stay in the doc, but it may NOT be the sole support for a `must`-level decision; if it was, downgrade the decision and say so.
- **CONFIRMED** — no edit.
- **Critique findings** — apply every `[VERIFIED]` recommended patch that names a file. Findings you cannot apply as a small Edit (structural: a whole dimension missing) go under `## Open critique findings` in the relevant author doc, one line each with the critique file path. Reject a finding ONLY if it violates the critic's own contract (a criticism with no file named, or a "refutation" with no source); log each rejection with one line of reasoning in `runs/<run_tag>/temp/orchestrator-notes.md`.
- Patch, never regenerate: each fix is a small Edit hunk; never rewrite a section wholesale.

**Then spot-check your own patching.** Grep the author docs: every `REFUTED` claim's text appears under `## Refuted by verification` and NOT in its original ranked position; every `PARTIALLY_TRUE` claim carries its `[corrected by verification: …]` annotation; no verdict file is unaccounted for.

### V6 — Write `INDEX`

Per ARCHIVE §3.4 — ALL FOUR PHASES APPEAR, every agent under its phase, with its file size (the cheap signal that an agent returned a stub). Compute sizes, never estimate:

```bash
shopt -s nullglob
for f in research/<AREA>/research/*.md research/<AREA>/research/*/*.md \
         research/<AREA>/verify/*.md research/<AREA>/critique/*.md \
         research/<AREA>/author/*.md; do
  printf '%s — %s chars\n' "$f" "$(wc -c < "$f" | tr -d ' ')"
done
```

Both `research/` globs are deliberate: area 01 NESTS its research files (`competitors/`, `sentiment/`) while areas 02–04 are FLAT. Do not "simplify" this to `research/**/*.md` — bash does not expand `**` recursively without `shopt -s globstar`, so it silently degrades to one level and the flat areas list nothing.

```markdown
# <AREA_TITLE>

`<run_tag>` · **<N> agents** · every agent's result + the prompt that produced it.
Methodology: [docs/RESEARCH-ARCHIVE.md](../../docs/RESEARCH-ARCHIVE.md) — the phase
structure, the claim→verify mechanism, and the verifier prompt template.

`research/` is UNVERIFIED by construction; where a `verify/` file disagrees with it,
THE VERIFY FILE WINS, and `author/` already carries the correction.

## research (<n>)  — one agent per dimension, independent web research
- [<dimension>](research/<dimension>.md) — <N,NNN> chars
## verify (<n>)  — one fact-checker per load-bearing claim, each told to *refute* it
- [<dimension>--<claim-slug>](verify/<dimension>--<claim-slug>.md) — <N,NNN> chars — **<VERDICT>**
## critique (<n>)  — cross-cutting critics
- [<critic-name>](critique/<critic-name>.md) — <N,NNN> chars
## author (<n>)  — the synthesis; the only files downstream steps must read
- [<doc>](author/<doc>.md) — <N,NNN> chars

## Verdict tally
CONFIRMED <n> · PARTIALLY_TRUE <n> · REFUTED <n> · UNVERIFIABLE <n>
of <total> claims extracted; <k> were NOT selected for verification and were NOT checked.

## Unverified
- <claim> — <dimension> — <why: budget, topic-label defect, or two failed spawns>
```

`_INDEX.md` is an index, not a research file — it takes NO provenance block.

---

## Artifacts

- `research/01-product-and-market/verify/<dimension>--<claim-slug>.md` — one per selected claim, ARCHIVE §3.2 format: frontmatter with `claim` verbatim + `verdict`, `## Verdict`, a **Correction** when PARTIALLY_TRUE, **Evidence** citing primary sources, and the §4 provenance block
- `research/01-product-and-market/critique/completeness-critic.md`, `critique/research-audit.md`, and (premier) `critique/domain-<slug>-critic.md` — ARCHIVE §3.3 format, `[VERIFIED]`/`[OPEN]` marked, files named, `## Recommended patches`, provenance block
- Patched `research/01-product-and-market/author/competitor-landscape.md` + `author/sentiment-synthesis.md` — inline corrections, `## Refuted by verification`, `## Open critique findings`
- `runs/<run_tag>/temp/claims-01.json` — every claim with its `selected` flag, `verdict` and `correction` folded back in
- `research/01-product-and-market/_INDEX.md` — all four phases, every agent, file sizes, verdicts, verdict tally, `## Unverified`

---

## Exit criteria

- EVERY claim on the selected verify surface has a `verify/` file with a verdict from the closed vocabulary `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE`; claims that never got one are listed under `_INDEX.md` `## Unverified` with a reason (max 2 spawns each)
- ZERO UNPATCHED REFUTED CLAIMS: no REFUTED claim survives as fact in either author doc, and every one is findable under `## Refuted by verification` — nothing silently deleted
- Every PARTIALLY_TRUE claim carries its correction inline wherever it appears; every UNVERIFIABLE claim is labelled and is nowhere the sole support of a `must`-level decision
- The critique panel ran with the gear's seat count (2 standard / 3 premier), DISTINCT lenses, one file each, every finding naming files
- `research/01-product-and-market/_INDEX.md` exists, lists all four phases with per-file sizes, and states that `verify/` overrides `research/`
- Every `verify/` and `critique/` file written this step carries `run_tag` + `created` frontmatter and ENDS with its provenance block (ARCHIVE §4) containing the prompt verbatim — `_INDEX.md` is an index and takes none
- `runs/<run_tag>/temp/claims-01.json` carries a `verdict` for every `"selected": true` claim

Then update the manifest: `steps."3.5" = "done"`, mark the step-3.5 todo complete, return to the router.

---

## Next step

Return to the router (`hyperbuild`). It invokes:

```
Skill(skill: "hyperbuild-4-product-spec")
```

Step 4 builds the PRD on the verified corpus — it reads `research/01-product-and-market/author/*.md` only, must not cite a claim recorded under `## Refuted by verification`, and cites a corrected or unverified claim only together with its annotation. Steps 5, 6 and 9 re-run the engine above over areas `02-engineering`, `03-design-system` and `04-claude-skills`.
