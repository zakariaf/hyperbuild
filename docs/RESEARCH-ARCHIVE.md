# RESEARCH-ARCHIVE.md — the research output contract

BINDING on every research-producing step — 2 (market recon), 3 (social mining), 3.5 (research
audit), 5 (stack research), 6 (design research), 9 (skill research) — and on step 12, which
writes the reusability guide. Each cites this file by path in its spawn prompts, and EVERY
research-phase subagent READS IT BEFORE producing anything. Violations are DEFECTS, not style
disagreements: the file is rejected and the agent re-spawned, like any other failed check.

## 1. Why

Research is spent ONCE and must survive the run. A hyperbuild checkout is one app; the user
builds many. A run burns millions of tokens establishing which state library is current, which
package is abandoned, what the store's privacy rules actually say — and almost none of that is
specific to the app that paid for it. If findings evaporate into a synthesis with no sources,
no dates, and no prompts, the NEXT app re-buys them at full price. PORTABLE FINDINGS ARE THE
ASSET; the synthesis is just the receipt.

Findings are an asset only if they are TRUE. A surveying researcher optimizes for coverage and
will confidently repeat a 2023 blog post, a package archived last year, and an API name that
never existed. ADVERSARIAL VERIFICATION IS WHAT MAKES A FINDING TRUSTWORTHY: a second agent,
handed ONE claim and told to REFUTE it against primary sources. In the exemplar that pass
caught a competitor already shipping the whole proposed MVP at a tenth of the assumed price, a
licence change that made the core dependency store-incompatible, and a widely-cited statistic
that appears to be fabricated. WHEN A FACT-CHECKER DISAGREES WITH A RESEARCHER, THE
FACT-CHECKER IS USUALLY RIGHT — it checked primary sources against one specific claim while
the researcher was surveying a whole dimension.

## 2. The area layout

One AREA per research step-group; every area holds the same four phases. Reproduce exactly:

```
research/
├── README.md                    # areas index + REUSABILITY GUIDE (written at step 12)
├── product-spec.md              # the PRD (step 4) — stays at root: product contract, not research
├── harvest/                     # shallow clones + harvest-log.md (unchanged)
├── 01-product-and-market/       # steps 2, 3, 3.5
│   ├── _INDEX.md
│   ├── research/competitors/<slug>.md, research/sentiment/<platform>.md
│   ├── verify/<dimension>--<claim-slug>.md
│   ├── critique/<critic-name>.md
│   └── author/competitor-landscape.md, author/sentiment-synthesis.md
├── 02-engineering/              # step 5   (NOTE: FIXED name — never platform-specific, so
│   ├── _INDEX.md                #          every downstream consumer path is deterministic)
│   ├── research/<dimension>.md
│   ├── verify/, critique/
│   └── author/stack-guide.md
├── 03-design-system/            # step 6
│   ├── _INDEX.md
│   ├── research/<direction-slug>.md
│   ├── verify/, critique/
│   └── author/design-directions.md
└── 04-claude-skills/            # step 9
    ├── _INDEX.md
    ├── research/<dimension>.md
    ├── verify/, critique/
    └── author/skill-authoring-guide.md
```

- **`research/`** — one file per dimension, ONE agent each, independent web research. Breadth.
  UNVERIFIED by construction.
- **`verify/`** — one file per load-bearing claim, each by an agent told to REFUTE that claim.
  Depth. The most valuable and least obvious directory here.
- **`critique/`** — critics reading the WHOLE area corpus, hunting contradictions BETWEEN
  dimensions — the defect class no single-claim fact-check sees (three dimensions each
  shipping a different, internally consistent API for one service).
- **`author/`** — the synthesis; the only files downstream steps must read. **`_INDEX.md`** —
  every agent in the area, grouped by phase, with file sizes.
- **`harvest/`** and **`product-spec.md`** keep their contracts and stay at root: the PRD is
  the product contract, not a research finding.

**AREA NAMES ARE FIXED — NEVER PLATFORM-SPECIFIC.** Not `02-flutter-engineering`, not
`02-swift-engineering`, not `03-material-design-system`. The platform is chosen BY the
research inside area 02, so a platform in the path makes every downstream path conditional on
a decision not yet made when the path was written. FIXED names let every step, skill, and gate
hardcode `research/02-engineering/author/stack-guide.md` and be right on every run, on every
platform, forever. Platform goes in frontmatter and prose, NEVER in paths.

## 3. File formats

### 3.1 `research/<dimension>.md`

```markdown
---
run_tag: <run_tag>
created: <YYYY-MM-DD>
area: 02-engineering
dimension: <dimension-slug>
phase: research
---
# <dimension>

> Phase: **research** · Agent `<agent-id>` · Run `<run_tag>`

## Summary
<One dense paragraph: what you found, what it changes, what the reader must not miss.>

### <A LOAD-BEARING CLAIM, WRITTEN AS A COMPLETE ASSERTION>
*Confidence: high|medium|low[, **LOAD-BEARING**]*
<Evidence and reasoning. Numbers, versions, dates, exact API names.>
- <source URL>

### <the next claim — same shape>

## Recommendations
- **[must|should|avoid]** <A concrete decision, in the imperative.>
  - <Why — tied to THIS app's constraints, not to general good practice.>

## Sources
- <URL> — accessed <YYYY-MM-DD> — <one-line takeaway>
```

**EVERY H3 UNDER `## Summary` IS A CLAIM, AND EVERY CLAIM IS A COMPLETE ASSERTION** — a
subject, a verb, and something that can be proven wrong. A topic label is a DEFECT: it cannot
be verified, refuted, or carried into a synthesis.

- GOOD: `Automatic retry is ON by default in Riverpod 3 and is actively harmful here.`
- GOOD: `Alpha's free tier already ships the entire proposed MVP on both platforms.`
- BAD: `Provider lifecycle` · `Retry behavior` · `Competitor pricing` · `Testing`

Mark every claim a decision RESTS ON `**LOAD-BEARING**` — those get fact-checked.
Recommendations are DECISIONS ("set X", "never do Y"), not observations, each with its own
justification. `## Sources` is mandatory: URL + access date + one-line takeaway.

### 3.2 `verify/<dimension>--<claim-slug>.md`

CLAIM SLUG = the first ~50 characters of the claim, lowercased, every non-alphanumeric run
collapsed to one hyphen, trailing hyphens trimmed. Mid-word truncation is expected —
`riverpod--stateprovider-statenotifierprovider-and-chan.md`. It is an identifier, not a
sentence.

```markdown
---
<§3.1 frontmatter, with phase: verify>
claim: "<the claim, verbatim>"
verdict: CONFIRMED|PARTIALLY_TRUE|REFUTED|UNVERIFIABLE
---
# <dimension>--<claim-slug>

> Phase: **verify** · Agent `<agent-id>` · Run `<run_tag>`

## Verdict
**PARTIALLY_TRUE**

**Correction:** <ONLY for PARTIALLY_TRUE. Name the exact right version, API, number, or
scope. "Directionally right" is not a correction — state the fix.>

**Evidence:** <What you checked, against WHICH PRIMARY SOURCE, and what it said — quoted
verbatim where the wording decides it. Say which parts confirmed and which are wrong.>
```

THE VERDICT VOCABULARY IS CLOSED: **CONFIRMED | PARTIALLY_TRUE | REFUTED | UNVERIFIABLE**. No
"mostly true", no percentages, no hedging in the verdict line.

### 3.3 `critique/<critic-name>.md` and `author/<doc>.md`

Critique: `phase: critique` + `critic: <name>`, same title and provenance line, the critic's
own body structure — but it MUST separate what it actually ran or read from what it merely
reasoned about: `[VERIFIED]` vs `[OPEN]`. A critic NEVER edits another agent's file.

Author: `phase: author`. The synthesis, and the only research file downstream steps must read.
It carries the corrections (§7) and SYNTHESIZES — never a fact absent from its inputs.

### 3.4 `_INDEX.md`

```markdown
# <Area title>

`<run_tag>` · **<N> agents** · every agent's result + the prompt that produced it.
Methodology: [docs/RESEARCH-ARCHIVE.md](../../docs/RESEARCH-ARCHIVE.md) — the phase
structure, the claim→verify mechanism, and the verifier prompt template.

## research (<n>)  — one agent per dimension, independent web research
- [<dimension>](research/<dimension>.md) — <N,NNN> chars
## verify (<n>)  — one fact-checker per load-bearing claim, each told to *refute* it
- [<dimension>--<claim-slug>](verify/...md) — <N,NNN> chars — **<VERDICT>**
## critique (<n>)  — cross-cutting critics
## author (<n>)  — the synthesis
```

ALL FOUR PHASES APPEAR, every agent under its phase, with its file size — size is the cheap
signal that an agent returned a stub. State here that `research/` is unverified and that
`verify/` overrides it (§7).

## 4. THE PROVENANCE RULE (universal)

EVERY file in `research/`, `verify/`, `critique/`, and `author/` ENDS with the prompt that
produced it:

````markdown
<details>
<summary>The prompt that produced this</summary>

```
<the full prompt the agent received, verbatim>
```

</details>
````

THIS IS PART OF THE SPAWN CONTRACT FOR EVERY RESEARCH-PHASE SUBAGENT: it MUST reproduce,
verbatim, the prompt it was given — no summary, no paraphrase, no "the prompt asked me to…".
The orchestrator puts that requirement INSIDE the prompt, so every prompt carries its own
reproduction instruction. If the prompt body contains a triple backtick, use a FOUR-backtick
outer fence.

The prompt is what makes the archive reusable: a finding says what one agent concluded; the
prompt says what it was asked, what context it was handed, and what it was never asked to
consider — the only way a later reader judges the blind spots, and the only way the next app
re-runs this research with a different brief. A FILE WITHOUT ITS PROMPT BLOCK IS INCOMPLETE
and gets re-spawned.

## 5. The claim → verify mechanism

1. **Extract.** When a research file lands, read EVERY H3 under `## Summary` — each is one
   candidate claim.
2. **Select.** The claims a decision rests on, plus every claim carrying a version, price,
   licence, policy, or API name. **STANDARD: the 3–5 most load-bearing per dimension. PREMIER:
   6–10.** Claims marked `**LOAD-BEARING**` go first.
3. **Spawn ONE VERIFIER AGENT PER CLAIM, ALL IN PARALLEL, IN ONE MESSAGE.** One agent handed
   five claims confirms all five — it has no budget to lose an argument with itself. One agent
   per claim is what makes refutation cheap.
4. **Every verifier is told to REFUTE**, not to "check". The asymmetry IS the mechanism.
5. **Record.** Every verifier writes its `verify/` file whatever the verdict; the REFUTED
   files are the most valuable ones in the archive.

FINDINGS THAT WERE NOT VERIFIED WERE NOT CHECKED — say so in `_INDEX.md` and the reusability
guide. Read `research/` for breadth, then check `verify/` before trusting any number, price,
version, or licence.

## 6. The canonical adversarial-verifier prompt template

Use it verbatim, filling the bracketed slots. Do not improvise a shorter one.

````
You are an ADVERSARIAL FACT-CHECKER for the <area title> research corpus of <app, one
line>. Today is **<YYYY-MM-DD>**.

A researcher studying "<dimension>" made this claim, and a project decision depends on it.

CLAIM: <the H3 heading, verbatim>
DETAIL: <the claim's body, verbatim>
CLAIMED SOURCES: <the claim's source URLs, comma-separated>
CONFIDENCE: <high|medium|low>

REFUTE IT. Use WebSearch and WebFetch against PRIMARY sources: the vendor's or maintainer's
own documentation, the package registry page (for the real current version, publisher, and
maintenance status), the official API reference (for real signatures), the standards-body
or store-policy text itself, and the actual GitHub repo (for whether it is archived or
discontinued). A tutorial, a blog post, an aggregator answer, or your own recollection is
NOT a primary source.

The failure modes you are hunting for, in order of likelihood:
1. **Version rot** — the claim was true two years ago. APIs get deprecated and removed,
   defaults flip, prices change, store policies change.
2. **Dead or abandoned tools presented as alive.** CHECK THE REPO: is it archived? When was
   the last release? Does the registry mark it discontinued or deprecated?
3. **Invented or misremembered API/feature names.** If the claim names a method, class,
   parameter, plan tier, or setting, VERIFY THAT EXACT NAME EXISTS in the official
   reference. Plausible-sounding names are a specific hazard here.
4. **Cargo cult** — one team's practice, or a big-company practice, presented as universal
   when the cited source does not say that.
5. **Overstated consensus** — "the community recommends X" when it is one blog post.

Default to refuted=true if you cannot independently substantiate it. CONFIRMED if it checks
out. PARTIALLY_TRUE + a correction if directionally right but wrong in specifics (name the
exact right version/API/number). UNVERIFIABLE if no source settles it — and say that
plainly rather than guessing.

Write research/<area>/verify/<dimension>--<claim-slug>.md in the format of
docs/RESEARCH-ARCHIVE.md §3.2, and END THE FILE with this prompt verbatim inside the
provenance block (§4).
````

**THE PREMISE TRAP.** A fact stated in the prompt is the one claim NOBODY checks — verifiers
are pointed at what the researcher SAID, not at what the brief ASSUMED. The exemplar told
three runs "stable is 3.44.0"; the installed toolchain was 3.41.2, and it survived ~10
references until a design author compiled against the real SDK. STATE ENVIRONMENT FACTS AS
QUESTIONS ("verify the installed SDK version first"), or verify them before spawning.

## 7. Synthesis rule

AN `author/` SYNTHESIS MAY ONLY REST ON CLAIMS THAT SURVIVED VERIFICATION.

- **REFUTED** — MUST NOT appear as fact anywhere downstream: not in the synthesis, the PRD, a
  feature file, an epic, or a code comment. A recommendation built on it is re-derived or
  dropped.
- **PARTIALLY_TRUE** — carries its correction wherever it appears; the corrected version
  ships, the original phrasing does not survive into the synthesis.
- **UNVERIFIABLE** — usable only when labelled unverified, NEVER the sole support for a
  `must`-level decision.
- **CONFIRMED** — usable as written. Unverified claims (not selected in §5) stay usable, but a
  synthesis MUST NOT present an unverified version, price, licence, or policy as fact.

**REFUTED CLAIMS ARE RECORDED, NEVER SILENTLY DELETED.** The `verify/` file stays and the
`research/` file is NOT rewritten — it is the honest record of what one surveying agent
believed, and rewriting it destroys the evidence that verification works. The correction lives
in `verify/` and is APPLIED in `author/`; say so in `_INDEX.md`, so no later reader trusts a
`research/` file over a `verify/` file.

## 8. The reusability guide (`research/README.md`, step 12)

Two jobs: point at the areas, and tell the NEXT checkout what it can copy instead of
re-researching.

```markdown
| Area | Run | Agents | Reusable elsewhere? |
|---|---|---|---|
| [`01-product-and-market/`](01-product-and-market/_INDEX.md) | `<run_tag>` | <n> | **Partly** |
| [`02-engineering/`](02-engineering/_INDEX.md) | `<run_tag>` | <n> | **Almost entirely** |
```

Then classify EVERY area — and, where an area splits, every file in it — into exactly three
buckets, BY NAME:

- **Portable to ANY app** — store policy and privacy-label rules, licensing, pricing and
  business-model mechanics, skill-authoring craft. Copy as-is.
- **Portable to any app on this platform (`<platform>`)** — architecture, project structure,
  the state library's current API, the testing corpus, lints, CI, performance, the platform's
  design-system status. Copy when the next app targets that platform.
- **Specific to THIS app — context only** — domain research, the competitor set, audience pain
  points, failure-mode analysis. Keep for provenance; do not reuse.

Then the mechanics: (1) TO REUSE, copy `02-engineering/`, `03-design-system/`, and/or
`04-claude-skills/` into the new checkout's `research/` BEFORE running `/hyperbuild` — the
FIXED area names make the copy path-compatible with zero edits. (2) EVERYTHING HERE HAS A
DATE: record the capture date, because versions, prices, store policies, and API surfaces rot
fast — that rot is the entire reason the verification pass exists. RE-VERIFY any specific
value older than 90 days, and re-run the §6 verifier over any claim a NEW decision rests on.
(3) Name the known bad premises and the unresolved critic findings explicitly — an honest gap
beats a clean-looking index.
