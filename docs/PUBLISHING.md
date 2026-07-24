# PUBLISHING.md — release checklist

The owner's checklist for taking this harness public at
`github.com/zakariaf/hyperbuild`. Work top to bottom; the ordering is deliberate —
plugin mode gets **verified before it gets announced**, and an example run lands
**before** the announcement post.

## 1. Pre-flight (local)

- [ ] Working tree clean; no `runs/`, `research/`, `features/`, `epics/`, or `app/`
      artifacts from private shakedown runs staged for the public history.
- [ ] Sweep for leaks — all three greps must come back empty:

  ```bash
  grep -rn "/Users/\|/private/tmp/" .claude/ .claude-plugin/ *.md docs/    # absolute local paths
  grep -rni "<your personal email>" .claude/ .claude-plugin/ *.md docs/    # substitute it literally
  grep -rniE "appbuilder|app_builder|app-builder" .claude/ .claude-plugin/ *.md docs/  # pre-release project name
  ```

- [ ] Optional: rename the local checkout folder to `hyperbuild` so the local path,
      repo name, and README quickstart (`cd hyperbuild`) agree.
- [ ] Confirm LICENSE says MIT, Zakaria Fatahi; README credits
      [hyperresearch](https://github.com/jordan-gibbs/hyperresearch) as the
      architectural ancestor (the lineage table in PIPELINE.md is the long form).

## 2. Create the repo and push

```bash
gh repo create zakariaf/hyperbuild --public
git remote add origin git@github.com:zakariaf/hyperbuild.git
git push -u origin main
```

## 3. Repo settings

- [x] **Settings → General → "Template repository"** — DONE. This is the primary
      install path: the harness is one-checkout-one-app (runs write into the repo
      root), so "Use this template → new repo per app idea" fits the design exactly.
- [x] Description and topics (`claude-code`, `ai-agents`, `app-generator`, `skills`,
      `deep-research`, `design-systems`) — DONE via `gh repo edit`.
- [ ] **Social preview image — the one setting the CLI cannot set.** Upload
      `assets/social-preview.png` (1280×640, already in the repo) at
      Settings → General → Social preview → Edit → Upload an image. Without it,
      links to the repo on X/Slack/LinkedIn render as a plain grey card.

## 4. Plugin mode — VERIFY BEFORE ANNOUNCING

Template mode is known-good. Plugin mode is a separate distribution channel with its
own failure modes; do not mention it in the README as supported until every box below
is checked, from a **clean directory that is not this repo**:

- [ ] The repo ships both plugin files: `.claude-plugin/marketplace.json` and the
      plugin manifest (`plugin.json`). No files → plugin mode does not exist yet;
      stop here and say nothing about it.
- [ ] `/plugin marketplace add zakariaf/hyperbuild` succeeds.
- [ ] Install the plugin from that marketplace; restart Claude Code.
- [ ] The **namespaced router command loads**: `/hyperbuild:hyperbuild <idea>` appears
      in the command list and starts step 1.
- [ ] **Internal `Skill()` calls resolve in plugin mode.** This is the critical check:
      the router invokes bare names — `Skill(skill: "hyperbuild-1-intake")` — and
      every step skill bounces back the same way. Watch a run through at least steps
      1 → 2: if the router loads but step skills fail to resolve under the plugin
      namespace, the pipeline dies on its very first hop.
- [ ] Artifacts land in the **user's project** (cwd), not the plugin cache: after
      step 1, `runs/<run_tag>/idea.md` exists in the directory where you ran Claude
      Code.

If any box fails: mark plugin mode **unsupported** in the README ("install via
template repository; plugin packaging tracked in issue #N") until fixed. A README that
promises a broken install path costs more trust than one that offers a single good one.

**Windows caveat:** plugin installs materialize the repo on disk, and anything
symlink-shaped (or scripts assuming a POSIX shell) can break on Windows without
Developer Mode / `core.symlinks=true`. If plugin mode ships, note in the README that
it is verified on macOS/Linux, Windows untested — until someone actually tests it.

## 5. First release: example run BEFORE the announcement

hyperresearch's `example-reports/` is a large part of why it lands — people can see
the output before spending hours of compute. Mirror that:

1. In a **fresh clone**, run one small shakedown app (`/hyperbuild <small idea>`)
   through the design gate; pick a design; let Stage B run to the ship gate.
2. Scrub the artifacts of anything personal (usernames, machine paths, local URLs).
3. Commit an `example-run/` directory to the public repo containing at minimum:
   - a design-gallery screenshot (the `designs/index.html` view, all three systems),
   - `design-gate-report.md` and `ship-report.md`,
   - optionally a trimmed `research/` sample (one competitor dossier, the sentiment
     synthesis) and the epics overview.
4. Link `example-run/` from the README.
5. **Then** announce. Not before — an empty harness repo is a claim; an example run
   is evidence.

## 6. Versioning

- [ ] Tag the first public commit: `git tag v0.1.0 && git push --tags`; create the
      GitHub release from the tag with the example run linked in the notes.
- [ ] Every subsequent release: bump the `version` field in the plugin manifest
      (`plugin.json`) in the same commit as the tag — marketplace installs read the
      manifest version, and a tag that disagrees with it ships a lie.
- [ ] Breaking changes to run-state contracts (manifest shape, task frontmatter,
      artifact paths) are at minimum a minor bump and a release note — existing
      checkouts have in-flight runs keyed to the old contract.
