# research/ — the vault contract

The research vault: every research artifact the pipeline produces (steps 2–9) lives
here, at the repo root — NOT inside `runs/`. Research is a first-class, human-readable
deliverable: markdown is truth, readable without any tooling, and later runs reuse the
vault before re-fetching (mirroring hyperresearch's vault-before-fetch rule). This
directory is pipeline-owned — never hand-edit.

## Layout

```
research/
├── competitors/<slug>.md      # one dossier per competitor (step 2)
├── competitor-landscape.md    # feature matrix + positioning map (step 2)
├── sentiment/<platform>.md    # reddit.md, hn-forums.md, appstore-reviews.md, linkedin-x.md (step 3)
├── sentiment-synthesis.md     # ranked pain points + wish lists (step 3)
├── research-audit.md          # adversarial audit findings + resolutions (step 3.5)
├── product-spec.md            # the PRD, incl. the canonical screen inventory (step 4)
├── stack/<topic>.md           # architecture.md, structure.md, testing.md, tooling-ci.md (step 5)
├── stack-guide.md             # merged committed best-practices guide (step 5)
├── design/<direction-slug>.md # one research doc per design direction (step 6)
├── skill-authoring-guide.md   # Claude Code skill-authoring research (step 9)
└── harvest/                   # shallow-cloned GitHub repos + harvest-log.md (steps 5, 6, 9, 10)
    └── harvest-log.md
```

## Provenance frontmatter (every vault file)

Every markdown file here carries `run_tag` and `created` in its frontmatter, plus the
fields its step contract adds (e.g. `platform_group`/`posts_mined` for sentiment files,
`competitor`/`slug`/`latest_version` for dossiers, `step`/`topic` for stack docs).
Provenance survives multi-run vaults: a later run can see which run produced a file and
how old it is.

**Reuse rules:** step 2 reuses a competitor dossier whose `created` is within 90 days
instead of re-spawning its analyst; step 3 counts a sentiment file done when its
`run_tag` matches and `posts_mined` meets the gear minimum.

## Source discipline (every research artifact)

- A `## Sources` section is mandatory: one line per source — URL (or repo path) +
  access date + one-line takeaway.
- At least one adversarial search per topic ("X criticism", "X problems", "why I
  stopped using X").
- Recency rule: prioritize sources from the last 18 months; version/feature claims must
  cite a dated source.
- Sentiment quotes are VERBATIM with URLs — paraphrase lives outside quotation marks.

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

## Rules

- Pipeline-owned: only steps 2–10 write here (step 10 reads; step 3.5 patches the two
  synthesis docs per its audit findings — annotate/downgrade, never silently delete;
  steps 4/5 edit their own artifacts during critic rounds). Never hand-edit.
- The landscape/synthesis/guide files SYNTHESIZE — they never introduce facts absent
  from the per-source files they merge.
- An honest gap ("platform thin", "dossier dropped after two failed spawns") beats a
  padded artifact. Gaps are named in the merging file's coverage/gaps section.
