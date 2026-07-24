# Brand assets

The mark is a **gated wave stack**: layers of work rising through one opened gate — the single
human decision hyperbuild asks for. Cyan waves brighten as they ascend; the amber layer is split
at its apex, the doorway they pass through before the top wave ships.

| File | Use |
|---|---|
| `logo.svg` | Square mark, 512×512, self-contained tile. Favicon, avatar, app icon source. |
| `logo.png` | Rasterized mark, 512×512, transparent outside the tile. |
| `banner.svg` | Horizontal lockup (mark + wordmark), 1200×300. |
| `banner.png` | Rasterized lockup at 2× (2400×600) — used in the README hero, immune to font fallback. |
| `social-preview.png` | 1280×640 card for GitHub's social preview (Settings → General → Social preview). |
| `candidates/` | The five concepts the mark was chosen from. Kept as design provenance. |

## Palette

| Token | Hex | Role |
|---|---|---|
| Wave cyan | `#45C4FF` | Primary accent, ascending waves, the `hyper` half of the wordmark |
| Gate amber | `#FFB224` | The gate — reserve it for the one thing that matters most |
| Tile top | `#1B2340` | Backdrop gradient start |
| Tile bottom | `#0B101F` | Backdrop gradient end |
| Off-white | `#EAEFFA` | The `build` half of the wordmark, light text on the tile |

The mark carries its own rounded backdrop tile, so it stays legible on light and dark pages
without a second variant.

## Regenerating the rasters

Both PNGs are rendered from the SVGs with headless Chrome — the same mechanism step 8 of the
pipeline uses for mockup screenshots:

```bash
chrome --headless=new --hide-scrollbars --default-background-color=00000000 \
  --screenshot=assets/banner.png --window-size=2400,600 file://<wrapper>.html
```

Edit the SVG, re-render, commit both.

## Usage

MIT-licensed with the rest of the repository. Please don't use the mark or wordmark to imply
endorsement of a fork, or as the identity of a different project.
