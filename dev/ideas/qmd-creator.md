# .qmd document creator

**Status:** design discussion needed (4 open questions below)
**Depends on:** `dated_path()` — **shipped**, see dev/ideas/done/dated-path.md.
The dependency is narrower than originally drafted: `dated_path()` is a pure
string function with **no versioning and no collision detection**, so it
cannot supply the "if `main_vX` exists, increment and warn" behavior. This
function owns that probe-and-increment logic itself and calls `dated_path()`
only to assemble the final name. Note `dated_path()` takes the version as part
of the name (`dated_path('main_v2.qmd')` → `main_v2_2026-08-12.qmd`), which
matches the filename spec below.

## Motivation

One call scaffolds a new analysis document with house conventions baked in.

## Spec so far

- **Filename:** `main_v1_2026-08-12.qmd`
  - defaults to `main`
  - integer version number; if `main_vX` already exists, increment and warn
  - date stamp at the end
- **YAML front matter:** current date, author name, a title, output format
  (leaning `gfm` — confirm, see open questions)
- **Opens in source mode**, not visual
- **Initial code block** loading the tidyverse

## Design notes

- First *side-effecting* function in icu (writes a file, opens the editor).
  Different testing regime: assert the created file's name/contents in a temp
  dir; the "opens in source mode" part is untestable, manual-check only.
- Opening the file: `usethis::edit_file()` or `file.edit()` / RStudio API —
  investigate which can force source mode (may be an `editor: source` YAML
  key rather than an API concern).
- Template should live as a real file under `inst/templates/main.qmd`, copied
  and interpolated — not a giant string in R code. Standard usethis-style
  approach.
- `library(tidyverse)` in the *generated document* is fine — the package's
  no-`library()` rule governs icu's own source, not user-facing templates.

## Open questions

1. **Author name source** — hardcoded default? `Sys.getenv()`? an
   `options()`/config value? function argument each time?
2. **Title** — function argument, or `"Untitled"` placeholder edited by hand?
3. **Output format default** — `gfm` (renders on GitHub) vs `html` (better if
   docs are mostly emailed/shared as reports). Confirm against actual sharing
   habits.
4. **Source mode mechanism** — YAML `editor: source` key vs editor API. Check
   which actually works.

## Testing notes

- Temp dir per test; assert filename pattern, version increment + warning,
  YAML fields, presence of tidyverse chunk.
- Warning on version collision is this function's contract — match message
  text per package convention.
