# research/ — the archive contract

The research archive: every research artifact the pipeline produces (steps 2–9) lives
here, at the repo root — NOT inside `runs/`. Research is a first-class, human-readable
deliverable: markdown is truth, readable without any tooling, and a later run (or a
later CHECKOUT — see the reusability guide below) reuses the archive before re-fetching.
This directory is pipeline-owned — never hand-edit.

**The binding format authority is [`docs/RESEARCH-ARCHIVE.md`](../docs/RESEARCH-ARCHIVE.md).**
It defines the area layout (§2), the four file formats (§3), the provenance rule (§4),
the claim→verify mechanism (§5), the canonical verifier prompt (§6), the synthesis rule
(§7), and this guide (§8). Every research-producing step cites it by path in its spawn
prompts, and every research-phase subagent reads it before producing anything. A file
that violates it is a DEFECT: rejected, agent re-spawned — not a style disagreement.
This README is the directory-level summary; where the two disagree, RESEARCH-ARCHIVE
wins.

**Step 12 REWRITES this file.** At the design gate it replaces this contract with the
run's own areas index + filled-in reusability guide, built from disk (§8). What you are
reading is the pre-run version: the contract plus the skeleton step 12 must reproduce.

## Layout

One AREA per research step-group; every area holds the same four phases:

```
research/
├── README.md                    # this file → the areas index + REUSABILITY GUIDE (step 12)
├── product-spec.md              # the PRD (step 4) — stays at root: product contract, not research
├── harvest/                     # shallow clones + harvest-log.md (steps 5, 6, 9, 10)
├── 01-product-and-market/       # steps 2, 3, 3.5
│   ├── _INDEX.md
│   ├── research/competitors/<slug>.md, research/sentiment/<platform>.md
│   ├── verify/<dimension>--<claim-slug>.md
│   ├── critique/<critic-name>.md
│   └── author/competitor-landscape.md, author/sentiment-synthesis.md
├── 02-engineering/              # step 5
│   ├── _INDEX.md
│   ├── research/<dimension>.md          # architecture, structure, testing, tooling-ci, …
│   ├── verify/, critique/
│   └── author/stack-guide.md
├── 03-design-system/            # step 6
│   ├── _INDEX.md
│   ├── research/<direction-slug>.md     # EXACTLY 3 live direction briefs
│   ├── verify/, critique/
│   └── author/design-directions.md
└── 04-claude-skills/            # step 9
    ├── _INDEX.md
    ├── research/<dimension>.md
    ├── verify/, critique/
    └── author/skill-authoring-guide.md
```

**AREA NAMES ARE FIXED — NEVER PLATFORM-SPECIFIC.** Not `02-flutter-engineering`, not
`03-material-design-system`. The platform is chosen BY the research inside area 02, so a
platform in the path makes every downstream path conditional on a decision not yet made
when the path was written. Fixed names let every step, skill, and gate hardcode
`research/02-engineering/author/stack-guide.md` and be right on every run, on every
platform, forever — and they are what makes an area copy-paste portable into the next
checkout with zero edits. Platform goes in frontmatter and prose, NEVER in paths. Step
12's check 9 fails a platform-specific area name.

### What each phase directory holds

| Phase | One file per | Written by | Trust |
|---|---|---|---|
| `research/` | dimension (or competitor / sentiment platform / design direction) | ONE agent each, independent web research | **UNVERIFIED by construction.** Breadth. |
| `verify/` | load-bearing CLAIM | one agent per claim, told to REFUTE it against primary sources | Depth. **OVERRIDES the `research/` file it checked.** |
| `critique/` | critic | critics reading the WHOLE area corpus | Catches contradictions BETWEEN dimensions — what no single-claim check sees. |
| `author/` | synthesis doc | the orchestrator/author | The only files downstream steps MUST read. Carries the corrections. |
| `_INDEX.md` | area | the area's step | Every agent, grouped by phase, with file sizes and verify verdicts. |

**Read order: `research/` for breadth, then `verify/` before trusting any number,
price, version, licence, or API name.** A `verify/` verdict is one of exactly four
values — `CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE` — and §7 binds every
consumer: a REFUTED claim MUST NOT appear as fact anywhere downstream (not in an
`author/` file, the PRD, a feature spec, an epic, a task, or a code comment);
PARTIALLY_TRUE carries its correction wherever it appears; UNVERIFIABLE is never the
sole support for a `must`-level decision.

**Refuted claims are RECORDED, never silently deleted.** The `verify/` file stays and
the `research/` file is NOT rewritten — it is the honest record of what one surveying
agent believed, and rewriting it destroys the evidence that verification works. The
correction lives in `verify/` and is APPLIED in `author/`; `_INDEX.md` says which is
authoritative.

### File formats

`docs/RESEARCH-ARCHIVE.md` §3 is the authority; the shape, in one breath:

- **`research/<dimension>.md`** — §3.1. Frontmatter (`run_tag`, `created`, `area`,
  `dimension`, `phase`), a `## Summary` whose every H3 IS A COMPLETE ASSERTION (subject,
  verb, something that can be proven wrong — a topic label is a defect: it cannot be
  verified), each with a confidence line and `**LOAD-BEARING**` where a decision rests
  on it; `## Recommendations` as imperative decisions with per-item justification;
  a mandatory `## Sources` (URL + access date + one-line takeaway).
- **`verify/<dimension>--<claim-slug>.md`** — §3.2. The claim verbatim in frontmatter,
  a `verdict:` from the closed vocabulary, a `**Correction:**` naming the exact right
  version/API/number when PARTIALLY_TRUE, and evidence quoting the PRIMARY source.
- **`critique/<critic-name>.md`** — §3.3. Separates `[VERIFIED]` (what it ran or read)
  from `[OPEN]` (what it only reasoned about). A critic NEVER edits another agent's file.
- **`author/<doc>.md`** — §3.3. Synthesizes; never introduces a fact absent from its
  inputs; may only rest on claims that survived verification.
- **`_INDEX.md`** — §3.4. All four phases, every agent under its phase, with file size
  (the cheap signal that an agent returned a stub) and each verify verdict.

**THE PROVENANCE RULE (§4) IS UNIVERSAL.** Every file in `research/`, `verify/`,
`critique/`, and `author/` ENDS with the prompt that produced it, verbatim, inside a
`<details><summary>The prompt that produced this</summary>` block. No summary, no
paraphrase. The prompt is what makes the archive reusable: a finding says what one agent
concluded; the prompt says what it was asked, what context it was handed, and what it
was never asked to consider — the only way a later reader judges the blind spots, and
the only way the next app re-runs this research with a different brief. A file without
its prompt block is incomplete and gets re-spawned (step 12, check 23).

## Provenance frontmatter (every archive file)

Every markdown file here carries `run_tag` and `created`, plus `area` and `phase`, plus
the fields its step contract adds (`platform_group`/`posts_mined` for sentiment files,
`competitor`/`slug`/`latest_version` for dossiers, `dimension` for research files,
`claim`/`verdict` for verify files, `critic` for critiques). Provenance survives
multi-run archives: a later run can see which run produced a file and how old it is.

**Reuse rules:** step 2 reuses a competitor dossier whose `created` is within 90 days
instead of re-spawning its analyst; step 3 counts a sentiment file done when its
`run_tag` matches and `posts_mined` meets the gear minimum. A reused file's verify
verdicts age with it — see the 90-day rule below.

## Source discipline (every research artifact)

- A `## Sources` section is mandatory: one line per source — URL (or repo path) +
  access date + one-line takeaway.
- At least one adversarial search per topic ("X criticism", "X problems", "why I
  stopped using X").
- Recency rule: prioritize sources from the last 18 months; version/feature claims must
  cite a dated source.
- Sentiment quotes are VERBATIM with URLs — paraphrase lives outside quotation marks.
- PRIMARY sources settle a `verify/` file: the vendor's own docs, the package registry
  page, the official API reference, the standards-body or store-policy text, the actual
  GitHub repo. A tutorial, a blog post, an aggregator answer, or recollection is not one.

## harvest/ — the disposable clone cache

Steps 5, 6, 9, and 10 run HARVEST-FIRST: search GitHub for authoritative repos before
doing blank-page web research, vet candidates (meaningful stars, commits within ~12–18
months, authoritative origin), then shallow-clone keepers:

```bash
git clone --depth 1 <repo-url> research/harvest/<topic>/<repo>/
```

- **`harvest-log.md`** records EVERY candidate — kept or rejected — one line each:
  repo URL, stars, last-commit date, license, verdict + reason.
- **License rule:** MIT/Apache/BSD/CC → adapt freely with attribution in the consuming
  artifact's Sources section. GPL/AGPL/unlicensed → learn from it, cite it, never copy
  text or code into our artifacts.
- **Named canonical source:** `https://github.com/zakariaf/Flutter-Skills` (MIT) — the
  anatomy exemplar for all generated skills on any platform, and a direct content
  source in step 10 when the chosen platform is Flutter.
- The clones are a **disposable cache** — the distilled artifacts above are truth;
  `harvest/` is provenance and may be deleted after a run without losing anything the
  pipeline needs.

---

## REUSABILITY GUIDE

**This is the section step 12 fills in from disk, and it is the point of the whole
archive.** A hyperbuild checkout is one app; you will build many. A run burns millions
of tokens establishing which state library is current, which package is abandoned, and
what the store's privacy rules actually say — and almost none of that is specific to the
app that paid for it. PORTABLE FINDINGS ARE THE ASSET; the synthesis is just the
receipt. Without this section the next checkout re-buys them at full price.

### The areas index

| Area | Run | Agents | Reusable elsewhere? |
|---|---|---|---|
| [`01-product-and-market/`](01-product-and-market/_INDEX.md) | `<run_tag>` | `<n>` | **Partly** |
| [`02-engineering/`](02-engineering/_INDEX.md) | `<run_tag>` | `<n>` | **Almost entirely** |
| [`03-design-system/`](03-design-system/_INDEX.md) | `<run_tag>` | `<n>` | **Mostly** |
| [`04-claude-skills/`](04-claude-skills/_INDEX.md) | `<run_tag>` | `<n>` | **Entirely** |

### The three portability classes

Classify EVERY area — and, where an area splits, every FILE in it — into exactly one
bucket, BY NAME. "Mostly reusable" with no file names is a defect: nobody can act on it.

1. **Portable to ANY app.** Store-policy and privacy-label rules, licensing, pricing and
   business-model mechanics, Claude-skill-authoring craft. Copy as-is.
   Typically: all of `04-claude-skills/`, plus the legal/regulatory and business-model
   dimensions of `01-product-and-market/research/`.
2. **Portable to any app on this platform (`<platform>`).** Architecture, project
   structure, the state library's current API, the testing corpus, lints, CI,
   performance, the platform's design-system status and what it can actually render.
   Copy when the next app targets the same platform.
   Typically: all of `02-engineering/`, most of `03-design-system/`.
3. **Specific to THIS app — context only.** Domain research, the competitor set,
   audience pain points, failure-mode analysis, the three named design directions. Keep
   for provenance; do not reuse.
   Typically: most of `01-product-and-market/`, the direction briefs in
   `03-design-system/research/`.

### How to reuse it

1. **Copy whole areas, before the run.** Copy `02-engineering/`, `03-design-system/`,
   and/or `04-claude-skills/` into the new checkout's `research/` BEFORE running
   `/hyperbuild`. The FIXED area names make the copy path-compatible with zero edits —
   every consumer path in the harness is already hardcoded to them. Copy the WHOLE area
   (all four phases + `_INDEX.md`), never just the `author/` synthesis: without
   `verify/` the next reader cannot tell a fact-checked claim from a survey guess, and
   without the prompts they cannot tell what was never asked.
2. **EVERYTHING HERE HAS A DATE — record the capture date.** Versions, prices, store
   policies, and API surfaces rot fast; that rot is the entire reason the verification
   pass exists. **RE-VERIFY any specific value older than 90 days**, and re-run the §6
   verifier prompt over any claim a NEW decision rests on. A copied area whose dates you
   did not check is worse than no research, because it reads authoritative.
3. **Name the gaps.** Every REFUTED and PARTIALLY_TRUE verdict a downstream artifact
   rests on, every dimension whose claims were never fact-checked, every unresolved
   critic finding, and every known bad premise. An honest gap beats a clean-looking
   index.

### Known gaps and bad premises

**THE PREMISE TRAP (§6).** A fact stated in a spawn prompt is the one claim NOBODY
checks: verifiers are pointed at what the researcher SAID, not at what the brief
ASSUMED. State environment facts as questions ("verify the installed SDK version
first"), or verify them before spawning. List here, for this run: every premise that
entered as given context, every claim carried into an `author/` file with a
non-CONFIRMED verdict, and every dimension that went unverified.

## Rules

- Pipeline-owned: only steps 2–12 write here (step 10 reads; step 3.5's critics patch
  the two area-01 syntheses per their audit findings — annotate/downgrade, never
  silently delete; steps 4/5 edit their own artifacts during critic rounds; step 12
  rewrites this README). Never hand-edit.
- The `author/` syntheses SYNTHESIZE — they never introduce facts absent from the
  per-source files they merge, and they may only rest on claims that survived
  verification (§7).
- An honest gap ("platform thin", "dossier dropped after two failed spawns", "this
  dimension's claims were never fact-checked") beats a padded artifact. Gaps are named
  in the merging file's coverage/gaps section, in `_INDEX.md`, and here.
