---
name: hyperbuild-9-skill-research
description: >
  Step 9 of the hyperbuild pipeline — research area 04-claude-skills: deep
  research on Claude Code skill authoring. Spawns 4 hb-stack-researcher
  subagents in ONE parallel wave, one per dimension (skill format and
  frontmatter; progressive disclosure and file splitting; check-script
  gates; harvested-collection survey), each writing
  research/04-claude-skills/research/<dimension>.md in the
  docs/RESEARCH-ARCHIVE.md format (claims as H3 assertions + Sources +
  provenance block). Claude Code mechanics are EXACTLY where invented
  frontmatter fields, invented size limits and invented triggering
  behaviour appear, so the orchestrator registers every claim in
  runs/<run_tag>/temp/claims-04.json, drafts
  research/04-claude-skills/author/skill-authoring-guide.md, and RUNS THE
  VERIFICATION ENGINE (step 3.5, phases V1-V6: one hb-claim-verifier per
  claim hunting invented names first, a 2/3-seat hb-corpus-critic panel,
  the author patch, and _INDEX.md). The guide ends in a binding "Rules for
  our generated skills" section that step 10's five hb-skill-smith spawns
  treat as law — every mechanic in it traced to a surviving claim. Invoked by the hyperbuild router via
  Skill(); not run directly by users.
---

# Step 9 — Skill research (area `04-claude-skills`)

You are executing step 9 (skill-research) of the hyperbuild pipeline. Step 8 (mockups)
runs CONCURRENTLY with you as the 8 ∥ 9 pair — the router drives both steps' spawn waves
in the same block; you share no inputs with it and never wait on it. Your successor is
step 10 (skill-forge), which will consume this area's `author/` guide as authoring law when
it generates the five project skills that steer every Stage-B implementer.

**Goal:** fill research area `research/04-claude-skills/` with all four phases —
`research/` (4 dimensions), `verify/` (one adversarial fact-checker per load-bearing
claim), `critique/`, `author/skill-authoring-guide.md`, plus `_INDEX.md` — where the guide
ends in a numbered **"Rules for our generated skills"** section. A weak guide here becomes
five weak generated skills becomes sloppy step 14 implementation. This step is small but
load-bearing.

**BINDING: `docs/RESEARCH-ARCHIVE.md`.** Area `04-claude-skills` obeys it exactly: the
four-phase layout (§2), the file formats (§3), the universal provenance rule (§4), the
claim→verify mechanism (§5), the canonical verifier prompt (§6) and the synthesis rule
(§7). Violations are DEFECTS: the file is rejected and the agent re-spawned. Cite the file
by path in every spawn prompt.

**WHY VERIFICATION MATTERS MORE HERE THAN ANYWHERE ELSE.** Claude Code mechanics are the
single most fertile ground for invented-feature claims in this whole pipeline: a
frontmatter field that does not exist, an `allowed-tools` spelling that was renamed, a
"512-line limit" that no document states, a triggering rule inferred from one blog post,
a repo that was archived last year. A researcher surveying "skill format" will state all
five confidently, and every one of them becomes law for five generated skills and then for
every implementer subagent in Stage B. **A frontmatter field the loader ignores is a silent
failure: the skill simply never fires, and nothing in the pipeline reports it.** So the
`verify/` pass here is not ceremony — hunt failure mode 3 (invented or misremembered
API/feature names) first.

**This area is PORTABLE TO ANY APP** (RESEARCH-ARCHIVE §8). Skill-authoring craft is not
specific to the app that paid for it — write every file so the next checkout can copy
`research/04-claude-skills/` wholesale. Keep app-specific reasoning in the `## Rules`
section where it belongs, and mark it as such.

## Inputs

Read these before doing anything:

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `steps` (confirm steps.7 = done;
  step 8 is your concurrent pair member — do NOT wait on it)
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Paste into every spawn.
- `docs/RESEARCH-ARCHIVE.md` — the BINDING archive format. Read §2–§7 before spawning.
- `runs/<run_tag>/decisions/platform.md` — chosen platform + language (the guide's
  example snippets must speak this language)
- `research/02-engineering/author/stack-guide.md` — committed stack decisions from step 5
- `.claude/skills/hyperbuild-*/SKILL.md` and `.claude/agents/hb-*.md` — the in-repo
  exemplar corpus: this harness is written in the hyperresearch lineage style and is
  itself the best available specimen of skill anatomy. The `harvested-collection-survey`
  researcher mines it.

Create the area skeleton before spawning anything:

```bash
mkdir -p research/04-claude-skills/{research,verify,critique,author} runs/<run_tag>/temp
```

All four phase dirs, up front — an area with missing phase dirs reads as an area that SKIPPED verification, and design-gate check 22 then reports "missing verify/" instead of the honest "empty verify/", pointing the remedy at the wrong diagnosis. `_INDEX.md` is written last, by engine phase V6.

## Procedure

1. **Recover state.** Read the inputs above. Note `gear` — it sets the source targets
   (8–12 sources per dimension for `standard`, 15–25 for `premier`) and the verification
   depth (3–5 claims per dimension standard, 6–10 premier).

2. **Spawn all FOUR researchers in ONE message** — true parallel execution. Four Task
   calls, all `subagent_type: hb-stack-researcher`. ZERO overlap between assignments.
   Dimension slugs are FIXED — `_INDEX.md`, the claim register and every later reader
   depend on them:

   | dimension (= output filename) | topic |
   |---|---|
   | `skill-format-and-frontmatter` | The SKILL.md file format and the frontmatter contract: which fields EXIST (and their exact spellings), which are required vs optional, which commonly-cited fields do NOT exist, where skills live and how they are discovered and loaded (project `.claude/skills/` vs user vs plugin), the directory-name↔`name` rule, and how the `description` drives triggering — what makes a description fire reliably and what makes a skill silently never fire |
   | `progressive-disclosure-and-splitting` | Progressive disclosure: what belongs in the core SKILL.md vs `references/*.md`, when one file is right and when to split, the size bands actually evidenced (and whether any hard limit is real or folklore), how referenced files get loaded and what that costs in context, and the conventions for `examples/`, `assets/` and bundled resources |
   | `check-script-gates` | Mechanical enforcement: `scripts/*.sh` PASS/FAIL gates — which rule classes CAN be checked mechanically on the target platform (analyzer, formatter, linter, grep), exit-code and output conventions, portability (no app-hardcoded paths, no assumed cwd), how an implementer subagent is expected to invoke a gate, and the evidence that gated rules survive where prose rules decay |
   | `harvested-collection-survey` | HARVEST-FIRST survey of real high-quality skill collections. Shallow-clone `https://github.com/zakariaf/Flutter-Skills` (MIT, 33 skills — the canonical anatomy exemplar for ALL platforms, and a direct step-10 content source when the platform is Flutter), `anthropics/skills`, and `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill` (MIT — enters the harvest-log pre-vetted with verdict CHERRY-PICK: its three-layer token architecture and token-validator script pattern are valuable; its slides/banner/brand skills are out of scope; overall quality is mixed — vet each piece) into `research/harvest/skills/<repo>/` (`git clone --depth 1`), plus 1–2 vetted community collections (awesome-claude-code / claude-skills lists). MANDATORY per-platform skill search: the platform is known from `decisions/platform.md` — search for existing high-quality Claude Code skills FOR THAT PLATFORM before anything is written from scratch; every major stack has some (Flutter → zakariaf/Flutter-Skills above; Rails → 37signals' published Claude Code skills; any stack → `anthropics/skills` + the community lists), with concrete searches like `"<framework> claude code skills" site:github.com` and `claude skills <platform>`. Mine the clones AND this harness's own `.claude/skills/hyperbuild-*/SKILL.md` + `.claude/agents/hb-*.md` corpus for richness and register norms, with VERBATIM excerpts. End with a shortlist of harvested skills adaptable in step 10, each with its license, its last-commit date, and which `app-*` skill it maps to |

   **The one permitted reduction to 3 dimensions:** if the target platform has no runnable
   check tooling available in this environment, `check-script-gates` is dropped and its
   questions fold into `progressive-disclosure-and-splitting`'s brief. Record the reason in
   `_INDEX.md` under `## Gaps`. Otherwise run all four on both gears.

   **Spawn template** (fill the `<>` placeholders per the table):

   ```
   subagent_type: hb-stack-researcher
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the full body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 9 (skill-research) of the hyperbuild
     pipeline, producing ONE dimension of research area 04-claude-skills.
     Your research topic is NOT the app itself — it is how to author
     excellent Claude Code skills, because step 10 will generate five
     project-specific skills (app-code-style, app-architecture,
     app-testing, app-components, app-review-checklist) that guide the
     implementation of the app described above. Three sibling researchers
     are covering the other dimensions in parallel — cover ONLY yours.
     After you return, the orchestrator extracts your load-bearing claims
     and spawns ONE ADVERSARIAL FACT-CHECKER PER CLAIM told to refute it,
     then merges what survives into
     research/04-claude-skills/author/skill-authoring-guide.md.

     YOUR INPUTS:
     - run_tag: <run_tag>
     - area: 04-claude-skills
     - dimension: <skill-format-and-frontmatter |
       progressive-disclosure-and-splitting | check-script-gates |
       harvested-collection-survey>
     - topic: <the topic cell from the assignment table, verbatim>
     - output_path: research/04-claude-skills/research/<dimension>.md
     - source_target: <8-12 for standard gear | 15-25 for premier gear>
     - target_language: <language/framework from decisions/platform.md>

     CONTEXT FILES (read these FIRST, in order):
     - docs/RESEARCH-ARCHIVE.md — the BINDING output format: §3.1 (the
       file format, claims as H3 assertions), §4 (the provenance rule),
       §5 (what makes a claim load-bearing).
     - runs/<run_tag>/decisions/platform.md
     - research/02-engineering/author/stack-guide.md
     - <harvested-collection-survey only: every
       .claude/skills/hyperbuild-*/SKILL.md and .claude/agents/hb-*.md
       file in this repo — they ARE part of your corpus>

     FORMAT (BINDING — docs/RESEARCH-ARCHIVE.md §3.1): frontmatter
     (run_tag, created: <YYYY-MM-DD>, area: 04-claude-skills,
     dimension: <dimension>, phase: research), then the line
     `> Phase: **research** · Agent <your agent id> · Run <run_tag>`,
     then:
     - `## Summary` — one dense paragraph, then your findings as H3
       headings. EVERY H3 UNDER `## Summary` IS A CLAIM AND EVERY CLAIM
       IS A COMPLETE ASSERTION: subject, verb, something that can be
       proven wrong, carrying the exact field name / limit / version /
       licence / repo state it asserts. Under each: `*Confidence:
       high|medium|low[, **LOAD-BEARING**]*`, the evidence, and the
       source URLs. A topic label ("Frontmatter", "Triggering") is a
       DEFECT — it cannot be verified, refuted, or carried into a
       synthesis. GOOD: "The frontmatter contract is exactly `name` and
       `description`; a `<field>` key is ignored by the loader." BAD:
       "Frontmatter fields". At least 5 such claims (standard) / 8
       (premier) — the orchestrator selects the most load-bearing of
       them for fact-checking, so a doc with three claims starves the
       verification pass.
     - `## Recommendations` — candidate rules for our generated skills as
       "we will do X" / "never do Y" DECISIONS in the imperative, each
       with its own one-line justification tied to THIS pipeline's
       constraints. Take sides. No surveys, no "it depends".
     - `## Sources` — every source: URL **or repo path** + access date +
       one-line takeaway. In-repo exemplar files count toward your source
       target; list them with repo paths instead of URLs.
     - END THE FILE with the provenance block (RESEARCH-ARCHIVE §4): a
       <details><summary>The prompt that produced this</summary> block
       containing THIS ENTIRE PROMPT, verbatim, inside a fenced code
       block. No summary, no paraphrase. A file without its prompt block
       is INCOMPLETE and gets re-spawned. (This prompt contains triple
       backticks — use a FOUR-backtick outer fence.)

     RESEARCH DISCIPLINE:
     - PRIMARY SOURCES for every mechanic: the official Claude Code /
       Agent Skills documentation and changelog, the anthropics/skills
       repo itself, and the actual files in a cloned collection. A
       tutorial, a listicle, an aggregator answer, or your own
       recollection is NOT a primary source for a field name, a limit,
       or a loading rule.
     - NAME EXACT SPELLINGS. If you assert a frontmatter key, a
       directory name, a file convention, or a CLI flag, quote it
       character-for-character from the source that defines it, and say
       WHICH source. A fact-checker will be spawned to prove that exact
       string does not exist.
     - SAY WHAT DOES NOT EXIST. Fields you looked for and could not find
       documented, limits that are folklore rather than specification,
       behaviours everyone repeats with no primary source — these are
       among the most valuable claims you can return. State them as
       claims ("No official source states a line limit for SKILL.md; the
       widely-repeated <N> comes from <where>").
     - DATE EVERYTHING. Prioritize sources from the last 18 months —
       Claude Code evolves fast — and any claim about frontmatter
       fields, size limits, or triggering behaviour MUST cite a dated
       source. For a repo, cite its last-commit date and its licence
       file, not just its README.
     - Run at least ONE adversarial search (e.g. "Claude Code skill not
       triggering", "SKILL.md mistakes", "agent skills criticism",
       "skill description ignored").
     - Quote, don't paraphrase: concrete VERBATIM excerpts from real
       skills are what make this area reusable.
     - HARVEST-FIRST where it applies: log every candidate repo — kept or
       rejected, with license and reason — in
       research/harvest/harvest-log.md (URL, stars, last-commit date,
       license, verdict), and shallow-clone keepers with
       `git clone --depth 1 <url> research/harvest/skills/<repo>/`.
       License rule: MIT/Apache/BSD/CC — adapt with attribution;
       GPL/AGPL/unlicensed — learn and cite, never copy.

     PROHIBITIONS: Do NOT write any file other than output_path (and the
     harvest-log if you harvest). Do NOT research the app's market or
     design — steps 2-8 own that. Do NOT generate the five app-* skills —
     step 10 owns that. Do NOT assert a mechanic you did not fetch this
     run.
   ```

3. **Never emit bare text while the researchers are in flight.** While waiting, append
   your own candidate rules and merge notes to
   `runs/<run_tag>/temp/orchestrator-notes.md` via Write/Edit. Productive thinking time
   AND keeps the turn alive.

4. **Validate returns, then partial-failure policy.** For each of the four files: it
   exists at `research/04-claude-skills/research/<dimension>.md`; frontmatter carries
   `area`, `dimension`, `phase: research`; every H3 under `## Summary` is a complete
   assertion, not a topic label; `## Sources` meets the gear target with access dates;
   and **the file ends with its provenance block containing the full prompt verbatim**.
   A missing provenance block or a `## Summary` of topic labels is a DEFECT — re-spawn
   that ONE researcher with the offending headings quoted and one rewritten as an
   assertion to show the shape. If a researcher fails (missing or empty output), re-spawn
   it ONCE with its output path named as the explicit required output. If it fails again,
   proceed: mine the in-repo exemplar corpus yourself for the missing dimension, write the
   file in the same format with `phase: research` and a provenance block saying the
   orchestrator wrote it after two failed spawns, and record the degradation in
   `_INDEX.md` under `## Gaps`. If ALL FOUR fail twice, stop and report the blockage
   honestly to the router — do not fabricate a "researched" guide from memory alone.
5. **Register the claims** (`runs/<run_tag>/temp/claims-04.json`) — RESEARCH-ARCHIVE §5
   steps 1–2, in the registry schema the engine reads (`hyperbuild-3-5-research-audit`
   phase V1). Read EVERY H3 under `## Summary` in all four research docs; each is one
   candidate claim. Rank the verify surface in this order — the engine's V2 then keeps
   3–5 per dimension (`standard`) / 6–10 (`premier`):

   1. **Premises (ARCHIVE §6).** Sweep your own spawn prompts and `decisions/platform.md`
      for asserted environment facts and register each with `"dimension": "premise"`,
      `"load_bearing": true`. A fact stated in a brief is the one claim nobody checks.
   2. **Exact-name claims** — any asserted frontmatter key, directory convention, file
      name, CLI flag, or tool identifier. These are the invented-feature hazard and they
      go first among the researched claims, every time.
   3. **Limits and thresholds** — line counts, size caps, context costs, "skills over N
      lines stop being read". Folklore hides here.
   4. **Triggering and loading behaviour** — what makes a skill fire, when reference files
      load, what the model actually sees.
   5. **Repo facts** — a collection's licence, its skill count, its last-commit date,
      whether it is archived. Cheap to check, and a dead repo in the step-10 shortlist
      wastes a whole skill-smith.
   6. **Any claim a floor rule in item 8 rests on.**

   Registry entry shape (the engine's schema — `claim_slug` is COMPUTED, never eyeballed;
   see the engine's V2):

   ```json
   {
     "run_tag": "<run_tag>", "area": "04-claude-skills",
     "gear": "standard", "created": "<YYYY-MM-DD>",
     "claims": [{
       "id": "C-01",
       "dimension": "skill-format-and-frontmatter",
       "source_file": "research/04-claude-skills/research/skill-format-and-frontmatter.md",
       "claim": "<the H3 heading under ## Summary, verbatim>",
       "claim_slug": "<computed>",
       "detail": "<the claim's body, verbatim>",
       "sources": ["https://…"],
       "confidence": "high",
       "load_bearing": true,
       "selected": true,
       "verdict": null,
       "correction": null
     }]
   }
   ```

6. **Draft the guide BEFORE verification.** The engine PATCHES author docs (phase V5); it
   does not write them. So write `research/04-claude-skills/author/skill-authoring-guide.md`
   now, as an honest pre-verification synthesis: dedupe the four research docs, resolve
   conflicts by preferring the more recent dated source, keep verbatim excerpts, and draft
   every section in the Artifacts contract below including the numbered **"Rules for our
   generated skills"** (the floor rules are in item 8). The engine then corrects it in
   place — which is what makes the corrections visible instead of invisible.

   Close it with the provenance block (§4). The orchestrator wrote this file, so the block
   carries the authoring brief it followed: quote procedure items 6 and 8 verbatim inside
   the fenced block (FOUR-backtick outer fence — they contain code fences) and add the line
   `Authored by the step 9 orchestrator (Skill hyperbuild-9-skill-research), not a
   subagent.`

7. **Run the VERIFICATION ENGINE over area 04.** **Do NOT re-derive the procedure.** Read
   `.claude/skills/hyperbuild-3-5-research-audit/SKILL.md`, section **THE VERIFICATION
   ENGINE**, bind the parameter block below, and run phases **V1 → V6 unchanged** —
   including the canonical `hb-claim-verifier` spawn prompt (ARCHIVE §6, used verbatim),
   the batching rule (≤15 Task calls per message), the verdict fold-back into `CLAIMS`,
   the V5 patch semantics, and V6's `_INDEX.md`.

   | Engine parameter | Area 04 binding |
   |---|---|
   | `AREA` | `04-claude-skills` |
   | `AREA_TITLE` | `Claude Code skill authoring` |
   | `CLAIMS` | `runs/<run_tag>/temp/claims-04.json` |
   | `RESEARCH_DIR` | `research/04-claude-skills/research/` (`<dimension>.md` × 4, or the documented 3) |
   | `VERIFY_DIR` | `research/04-claude-skills/verify/` |
   | `CRITIQUE_DIR` | `research/04-claude-skills/critique/` |
   | `AUTHOR_DOCS` | `research/04-claude-skills/author/skill-authoring-guide.md` |
   | `INDEX` | `research/04-claude-skills/_INDEX.md` |
   | `PANEL` | completeness → `hb-corpus-critic` → `critique/completeness-critic.md` · skeptic → `hb-corpus-critic` → `critique/invented-mechanics-critic.md` · premier only: domain → `hb-corpus-critic` → `critique/domain-harvest-license-critic.md` |
   | `VERIFY_BUDGET` | ≤25 standard / ≤60 premier |
   | `CONSUMER` | step 10 (the five `hb-skill-smith` spawns) |

   **Area-04 additions to the engine — two, and only two:**

   1. **Point every verifier at failure mode 3 first.** Add ONE line to each filled §6
      prompt, after the failure-mode list:
      `FAILURE MODE 3 IS THE PRIMARY HUNT HERE: if this claim names a frontmatter key, a directory convention, a file name, a flag, or a numeric limit, your first job is to prove that exact string or number appears in no primary source. An unsupported field name is REFUTED, not PARTIALLY_TRUE.`
      And name the area's primary sources in the prompt's source list: the official Claude
      Code / Agent Skills documentation and its changelog, the `anthropics/skills`
      repository itself, the actual cloned files under `research/harvest/skills/`, and each
      repo's own LICENSE file and commit history. A blog post about skills is not
      documentation of skills.
   2. **Area-04 lens briefs for the V4 panel** (the brief column, replaced — the seats,
      agent and file count are the engine's):
      - `completeness-critic.md` — which authoring question did NOBODY research? What did
        every dimension assume without checking? Where is the corpus silent on something
        step 10 must decide when it writes five skills and their check scripts?
      - `invented-mechanics-critic.md` — sweep EVERY mechanic asserted anywhere in the area
        (field names, directory rules, limits, loading behaviour, flags) and list each with
        the primary source that defines it or the label NO PRIMARY SOURCE. Cross-check the
        dimensions against each other: two docs describing the same mechanic differently is
        the defect class this seat exists for. Then check the drafted guide's rules: is any
        rule unenforceable as written (no check script possible, no observable failure), or
        contradicted by a `verify/` verdict, or dependent on a platform capability the
        stack-guide does not provide?
      - `domain-harvest-license-critic.md` *(premier)* — take the adaptable-skills
        shortlist at face value and try to disqualify each entry: is the licence actually
        what the doc says (READ THE LICENSE FILE), is the repo alive, does the skill
        genuinely map to the `app-*` skill claimed, and would adapting it cost more than
        writing from zero?

   **Never emit bare text while the verifier or critic waves run** — append to
   `runs/<run_tag>/temp/orchestrator-notes.md` instead.

8. **The floor rules for `## Rules for our generated skills`** (drafted in item 6, patched
   by the engine's V5). They are numbered, committed decisions — not options. Extend and
   sharpen them with what research surfaced, never drop them. **If a `verify/` verdict
   contradicts a floor rule's specifics, ship the corrected specifics and say so inline —
   the rule survives, the wrong detail does not:**

   1. Directory name == frontmatter `name`, exactly; kebab-case; `app-` prefix.
   2. Frontmatter carries `name` and `description` only; the description is written for
      the triggering model — it starts "Use when ..." and names concrete file types,
      paths, and actions.
   3. One skill = one concern; zero scope overlap among the five generated skills.
   4. The RICH four-part anatomy (modeled on zakariaf/Flutter-Skills and
      anthropics/skills): a lean SKILL.md core (~100–250 lines: non-negotiable rules,
      one pointer per reference file, anti-patterns, definition-of-done) +
      `references/*.md` deep dives read on demand (one topic per file, 60–200 lines) +
      `examples/*` in the target language + `scripts/*.sh` PASS/FAIL check gates.
      Simple skills (e.g. app-review-checklist) may omit examples/ or scripts/ when
      they'd be padding; any skill with code rules gets all four parts.
   5. Every rule ships as rule + compliant example + violating example, in the target
      language from `decisions/platform.md`.
   6. A `## Anti-patterns` section is mandatory: named anti-pattern, why it fails, what
      to do instead.
   7. Imperative voice throughout; ALL-CAPS reserved for load-bearing rules.
   8. Cite ground truth (`research/02-engineering/author/stack-guide.md`,
      `research/product-spec.md`) instead of restating it wholesale.
   9. No TBD/TODO/placeholder text; every path referenced must exist in this repo.
   10. Each skill must stand alone for a fresh implementer subagent with zero
       conversation context.
   11. Every non-negotiable rule that CAN be checked mechanically gets a line in a
       `scripts/*.sh` gate (grep/analyzer based, exit non-zero on hard failure, no
       app-hardcoded paths) — a rule with a check script is enforced; a rule without
       one is a suggestion. Step 14 runs the gates per epic; step 16 runs them all.
   12. ADAPT before authoring: when a harvested skill from the shortlist covers a need,
       keep its structure and rewrite specifics for this app, with attribution and a
       license check (MIT/Apache/BSD/CC only; GPL/AGPL/unlicensed — learn, cite, never
       copy). Write from zero only for gaps.
   13. Every mechanic a generated skill relies on (a frontmatter key, a directory
       convention, a limit) traces to a CONFIRMED claim in this area — never to a
       plausible-sounding memory. Cite the `verify/` file inline when the mechanic is
       load-bearing.

9. **Fill `## Corrections from verification`.** V5 has patched the guide
   (`## Refuted by verification`, inline `[corrected by verification: …]`,
   `## Open critique findings`). One area-04 extra remains, because step 10's five
   skill-smiths read the guide and nothing else from this area: generate the
   `## Corrections from verification` section mechanically from `claims-04.json` — one row
   per non-CONFIRMED verdict, with the `verify/` file path and what shipped instead.

   ```markdown
   ## Corrections from verification
   | Dimension | Claim (short) | Verdict | What ships instead | verify/ |
   |---|---|---|---|---|
   | skill-format-and-frontmatter | "<claim>" | REFUTED | <the corrected mechanic> | [file](../verify/….md) |
   ```

   **A REFUTED mechanic must not survive anywhere in the guide as fact** — not in a rule,
   not in an example frontmatter block, not in a snippet. An invented frontmatter key that
   reaches step 10 produces five skills that silently never fire, and nothing downstream
   reports it.

10. **Validate the area** against the Artifacts contract below before declaring done.

## Artifacts

`research/04-claude-skills/author/skill-authoring-guide.md` — frontmatter:

```
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
area: 04-claude-skills
phase: author
---
```

followed by `> Phase: **author** · Orchestrator (step 9, Skill `hyperbuild-9-skill-research`) · Run `<run_tag>``.

Required sections, in order:

- `## Frontmatter contract` — every field that EXISTS, with a valid exemplar block, and
  the commonly-cited fields that do not
- `## Triggering and the description field` — what makes descriptions fire reliably
- `## Progressive disclosure and reference splitting` — when one file, when many
- `## Richness norms` — length bands, examples-per-rule, register, with verbatim
  excerpts from the exemplar corpus
- `## Check-script gates` — what is mechanically checkable on this platform, the exit-code
  and portability conventions, and how step 14/16 invoke them
- `## Adaptable skills shortlist` — harvested skills step 10 should adapt instead of
  writing from zero: skill name, repo, license, last-commit date, which app-* skill it
  maps to
- `## Corrections from verification` — every REFUTED / PARTIALLY_TRUE verdict and what
  shipped instead, each citing its `verify/` file
- `## Rules for our generated skills` — numbered, binding, ≥ 13 rules including the
  floor rules from Procedure item 8
- `## Sources` — every source: URL or repo path + access date + one-line takeaway
- the provenance block (§4)

Also produced:

- `research/04-claude-skills/research/<dimension>.md` × 4 (or 3, with the reason recorded)
  — §3.1 format, provenance block, `## Summary` claims as complete assertions
- `research/04-claude-skills/verify/<dimension>--<claim-slug>.md` — one per SELECTED
  claim, §3.2 format, closed verdict vocabulary, provenance block (engine V3)
- `research/04-claude-skills/critique/completeness-critic.md`,
  `critique/invented-mechanics-critic.md`, and (premier)
  `critique/domain-harvest-license-critic.md` — §3.3 format, `[VERIFIED]` vs `[OPEN]`
  separated, `## Recommended patches`, provenance block (engine V4)
- `research/04-claude-skills/_INDEX.md` — all four phases with per-file sizes, the verdict
  tally and `## Unverified` (engine V6). Takes NO provenance block.
- `runs/<run_tag>/temp/claims-04.json` — the claim registry, with `selected`, `verdict` and
  `correction` folded back in (kept, not shipped)

## Exit criteria

- All four (or the documented three) `research/04-claude-skills/research/<dimension>.md`
  files exist with archive frontmatter (`area`, `dimension`, `phase: research`), a
  `## Summary` whose H3s are complete assertions (≥5 per doc, ≥8 premier),
  `## Recommendations`, `## Sources`, and a closing provenance block containing the full
  prompt verbatim
- **Every file in the area ends with its provenance block** (RESEARCH-ARCHIVE §4) —
  research, verify, critique and author alike; `_INDEX.md` is an index and takes none
- `runs/<run_tag>/temp/claims-04.json` exists with one entry per H3 claim in the area, each
  carrying `selected` and — for every `"selected": true` entry — a `verdict`; every claim
  on the verify surface has a `verify/` file with a verdict from the closed vocabulary
  (unchecked claims listed under `_INDEX.md` `## Unverified` with a reason); every
  exact-name claim (frontmatter key, directory convention, flag, numeric limit) asserted
  anywhere in the area is either verified or explicitly labelled unverified in the guide
- The critique panel ran at the gear's seat count (2 standard / 3 premier) with DISTINCT
  lenses, one file each, including `invented-mechanics-critic.md`, every finding naming
  files and separating `[VERIFIED]` from `[OPEN]`
- `research/04-claude-skills/author/skill-authoring-guide.md` exists with all nine
  required sections in order; `## Rules for our generated skills` has ≥ 13 numbered rules
  and contains every floor rule from Procedure item 8; `## Corrections from verification`
  accounts for every non-CONFIRMED verdict and every REFUTED claim is also findable under
  `## Refuted by verification` (nothing silently deleted); no refuted mechanic appears as
  fact anywhere in the guide — not in a rule, not in an example frontmatter block; every
  PARTIALLY_TRUE claim carries its correction inline and no UNVERIFIABLE claim is the sole
  support of a `must`-level rule; `## Adaptable skills shortlist` is present (honestly
  empty only if harvesting found nothing adaptable)
- `research/harvest/harvest-log.md` records the cloned skill collections (incl.
  zakariaf/Flutter-Skills, anthropics/skills, and nextlevelbuilder/ui-ux-pro-max-skill
  with its CHERRY-PICK verdict) with licenses and verdicts, plus the candidates from
  the mandatory per-platform skill search
- Each research doc's `## Sources` lists ≥ 8 sources (`standard`) / ≥ 15 (`premier`), each
  with an access date; at least one adversarial search is reflected in the findings
- `research/04-claude-skills/_INDEX.md` lists all four phases with per-file sizes, the
  verdict tally and `## Unverified`, and states that `verify/` overrides `research/` and
  that the area is portable to any app
- No `research/` file was rewritten to hide a refutation

Then update the manifest: `steps.9 = done`, mark the step-9 todo complete, and return to
the router.

**Do NOT route to step 10 yourself.** Step 8.5 (`hyperbuild-8-5-visual-qa`) runs on step
8's output — the visual QA of every rendered screen — and you are normally the LAST member
of the 8 ∥ 9 pair to finish, so the temptation to jump straight to step 10 is exactly the
bug that skips visual QA. The router invokes `Skill(skill: "hyperbuild-10-skill-forge")`
only once BOTH step 8.5 and step 9 are done; if `steps["8"] == "done"` but
`steps["8.5"] != "done"`, the next call is `Skill(skill: "hyperbuild-8-5-visual-qa")`.
