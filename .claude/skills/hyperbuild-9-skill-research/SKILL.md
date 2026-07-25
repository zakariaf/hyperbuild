---
name: hyperbuild-9-skill-research
description: >
  Step 9 of the hyperbuild pipeline — deep research on Claude Code skill
  authoring: SKILL.md format, frontmatter fields, progressive disclosure,
  reference-file splitting, and richness norms. Spawns 2 hb-stack-researcher
  subagents in parallel (one on format mechanics via web research, one mining
  this harness's own hyperresearch-lineage skills and agents as the exemplar
  corpus) and merges their output into research/skill-authoring-guide.md,
  ending in a binding "Rules for our generated skills" section that step 10's
  five hb-skill-smith spawns treat as law. Invoked by the hyperbuild router
  via Skill(); not run directly by users.
---

# Step 9 — Skill research (parallel, 2 researchers)

You are executing step 9 (skill-research) of the hyperbuild pipeline. Step 8 (mockups)
runs CONCURRENTLY with you as the 8 ∥ 9 pair — the router drives both steps' spawn waves
in the same block; you share no inputs with it and never wait on it. Your successor is
step 10 (skill-forge), which will consume this step's guide as authoring law when it
generates the five project skills that steer every Stage-B implementer.

**Goal:** produce `research/skill-authoring-guide.md` — a researched, committed guide to
writing excellent Claude Code skills, ending in a numbered **"Rules for our generated
skills"** section. A weak guide here becomes five weak generated skills becomes sloppy
step 14 implementation. This step is small but load-bearing.

## Inputs

Read these before doing anything:

- `runs/<run_tag>/manifest.json` — `run_tag`, `gear`, `steps` (confirm steps.7 = done;
  step 8 is your concurrent pair member — do NOT wait on it)
- `runs/<run_tag>/idea.md` — the verbatim app idea. GOSPEL. Paste into every spawn.
- `runs/<run_tag>/decisions/platform.md` — chosen platform + language (the guide's
  example snippets must speak this language)
- `research/stack-guide.md` — committed stack decisions from step 5
- `.claude/skills/hyperbuild-*/SKILL.md` and `.claude/agents/hb-*.md` — the in-repo
  exemplar corpus: this harness is written in the hyperresearch lineage style and is
  itself the best available specimen of skill anatomy. Researcher B mines it.

## Procedure

1. **Recover state.** Read the inputs above. Note `gear` — it sets the source targets
   below (stack-research knob: 8–12 sources per topic for `standard`, 15–25 for
   `premier`).

2. **Spawn both researchers in ONE message** — true parallel execution. Two Task calls,
   both `subagent_type: hb-stack-researcher`. Assignments:

   | researcher_id | topic | output path |
   |---|---|---|
   | `format-mechanics` | SKILL.md file format, frontmatter fields (name, description, optional fields), how skills are discovered and triggered off the description, progressive disclosure, when to split reference files, size limits and norms | `runs/<run_tag>/temp/skill-research-format.md` |
   | `exemplar-mining` | Richness and register norms mined from real high-quality skills. HARVEST-FIRST: shallow-clone `https://github.com/zakariaf/Flutter-Skills` (MIT, 33 skills — the canonical anatomy exemplar for ALL platforms, and a direct step-10 content source when the platform is Flutter), `anthropics/skills`, and `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill` (MIT — an anatomy example that enters the harvest-log pre-vetted with verdict CHERRY-PICK: its three-layer token architecture and token-validator script pattern are valuable; its slides/banner/brand skills are out of scope; overall quality is mixed — vet each piece) into `research/harvest/skills/<repo>/` (`git clone --depth 1`), plus 1–2 vetted community collections (awesome-claude-code / claude-skills lists). MANDATORY per-platform skill search: the platform is known from `decisions/platform.md` — search for existing high-quality Claude Code skills FOR THAT PLATFORM before anything is written from scratch; every major stack has some (Flutter → zakariaf/Flutter-Skills above; Rails → 37signals' published Claude Code skills; any stack → `anthropics/skills` + the community awesome-claude-code / claude-skills lists), with concrete searches like `"<framework> claude code skills" site:github.com` and `claude skills <platform>`; found collections enter the harvest-log with a verdict and step 10 adapts the winners. Log every candidate — kept or rejected, with license and reason — in `research/harvest/harvest-log.md`. Mine the clones AND this harness's own `.claude/skills/hyperbuild-*/SKILL.md` + `.claude/agents/hb-*.md` corpus. End with a shortlist of harvested skills adaptable in step 10, each with its license | `runs/<run_tag>/temp/skill-research-exemplars.md` |

   **Spawn template** (fill the `<>` placeholders per the table; ZERO overlap between
   the two assignments):

   ```
   subagent_type: hb-stack-researcher
   prompt: |
     APP IDEA (verbatim, gospel):
     > {{paste the full body of runs/<run_tag>/idea.md}}

     IDEA FILE: runs/<run_tag>/idea.md

     PIPELINE POSITION: You are step 9 (skill-research) of the hyperbuild
     pipeline. Your research topic is NOT the app itself — it is how to
     author excellent Claude Code skills, because step 10 will generate
     five project-specific skills (app-code-style, app-architecture,
     app-testing, app-components, app-review-checklist) that guide the
     implementation of the app described above. One sibling researcher is
     covering the other half of the topic in parallel — cover ONLY yours.
     After you return, the orchestrator merges both outputs into
     research/skill-authoring-guide.md.

     YOUR INPUTS:
     - researcher_id: <format-mechanics | exemplar-mining>
     - topic: <the topic cell from the assignment table, verbatim>
     - output_path: <the output path from the assignment table>
     - source_target: <8-12 for standard gear | 15-25 for premier gear>
     - target_language: <language/framework from decisions/platform.md>

     CONTEXT FILES (read these FIRST, in order):
     - runs/<run_tag>/decisions/platform.md
     - research/stack-guide.md
     - <exemplar-mining only: every .claude/skills/hyperbuild-*/SKILL.md
       and .claude/agents/hb-*.md file in this repo — they ARE your corpus>

     Research discipline: prioritize sources from the last 18 months —
     Claude Code evolves fast, and any claim about frontmatter fields,
     size limits, or triggering behavior MUST cite a dated source. Run at
     least one adversarial search (e.g. "Claude Code skill not
     triggering", "SKILL.md mistakes", "agent skills criticism"). In-repo
     exemplar files count toward your source target; list them in your
     Sources section with repo paths instead of URLs.

     Write ONE markdown doc at output_path with: your findings organized
     by sub-topic; concrete verbatim excerpts from real skills (quote,
     don't paraphrase); a "## Committed decisions" section of "we will do
     X" statements (candidate rules for our generated skills — take
     sides, no surveys); and a "## Sources" section (URL or repo path +
     access date + one-line takeaway per source). Do NOT write any other
     file. Do NOT research the app's market or design — steps 2-8 own
     that.
   ```

3. **Never emit bare text while the researchers are in flight.** While waiting, append
   your own candidate rules and merge notes to
   `runs/<run_tag>/temp/orchestrator-notes.md` via Write/Edit. Productive thinking time
   AND keeps the turn alive.

4. **Partial-failure policy.** If one researcher fails (missing or empty output file),
   re-spawn it ONCE with its output path named as the explicit required output. If it
   fails again, proceed: mine the in-repo exemplar corpus yourself for the missing half
   and note the degradation in the guide's Sources section. If BOTH fail twice, stop and
   report the blockage honestly to the router — do not fabricate a "researched" guide
   from memory alone.

5. **Merge into the guide.** You (the orchestrator) write
   `research/skill-authoring-guide.md` yourself — dedupe the two docs, resolve
   conflicts by preferring the more recent dated source, keep verbatim excerpts. Then
   author the final **"Rules for our generated skills"** section as numbered, committed
   decisions (not options). The section MUST include at least these floor rules — extend
   and sharpen them with what research surfaced, never drop them:

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
   8. Cite ground truth (`research/stack-guide.md`, `research/product-spec.md`) instead
      of restating it wholesale.
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

6. **Validate the guide** against the Artifacts contract below before declaring done.

## Artifacts

`research/skill-authoring-guide.md` — frontmatter:

```
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
---
```

Required sections, in order:

- `## Frontmatter contract` — every field, with a valid exemplar block
- `## Triggering and the description field` — what makes descriptions fire reliably
- `## Progressive disclosure and reference splitting` — when one file, when many
- `## Richness norms` — length bands, examples-per-rule, register, with verbatim
  excerpts from the exemplar corpus
- `## Adaptable skills shortlist` — harvested skills step 10 should adapt instead of
  writing from zero: skill name, repo, license, which app-* skill it maps to
- `## Rules for our generated skills` — numbered, binding, ≥ 12 rules including the
  floor rules from Procedure item 5
- `## Sources` — every source: URL or repo path + access date + one-line takeaway

Intermediate (kept, not shipped): `runs/<run_tag>/temp/skill-research-format.md`,
`runs/<run_tag>/temp/skill-research-exemplars.md`.

## Exit criteria

- `research/skill-authoring-guide.md` exists with `run_tag` + `created` frontmatter and
  all seven required sections in order
- `## Rules for our generated skills` has ≥ 12 numbered rules and contains every floor
  rule from Procedure item 5; `## Adaptable skills shortlist` is present (honestly
  empty only if harvesting found nothing adaptable)
- `research/harvest/harvest-log.md` records the cloned skill collections (incl.
  zakariaf/Flutter-Skills, anthropics/skills, and nextlevelbuilder/ui-ux-pro-max-skill
  with its CHERRY-PICK verdict) with licenses and verdicts, plus the candidates from
  the mandatory per-platform skill search
- `## Sources` lists ≥ 8 sources (`standard`) / ≥ 15 (`premier`), each with an access
  date; at least one adversarial search is reflected in the findings
- Both temp research docs exist (or the degraded path is documented in the guide's
  Sources section)

Then update the manifest: `steps.9 = done`, mark the step-9 todo complete, and return to
the router.

**Do NOT route to step 10 yourself.** Step 8.5 (`hyperbuild-8-5-visual-qa`) runs on step
8's output — the visual QA of every rendered screen — and you are normally the LAST member
of the 8 ∥ 9 pair to finish, so the temptation to jump straight to step 10 is exactly the
bug that skips visual QA. The router invokes `Skill(skill: "hyperbuild-10-skill-forge")`
only once BOTH step 8.5 and step 9 are done; if `steps["8"] == "done"` but
`steps["8.5"] != "done"`, the next call is `Skill(skill: "hyperbuild-8-5-visual-qa")`.
