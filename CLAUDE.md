# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**icu** ("Ian Cero's Utils") is an R package: a catch-all for frequently used utility functions that have no home in another package, plus convenient re-exports of functions from other packages. Standard `devtools`/`usethis`/`roxygen2`/`testthat` (edition 3) toolchain.

## Commands

**Canonical R version: 4.6.1**, at `%LOCALAPPDATA%\Programs\R\R-4.6.1`. It is first on the user PATH, so a bare `Rscript` resolves to it — but note that `Rscript` is *not* on PATH inside an already-running shell that was launched before the PATH change, so a fresh Claude Code session may need the full path:

```powershell
& "$env:LOCALAPPDATA\Programs\R\R-4.6.1\bin\Rscript.exe" -e "devtools::test()"
```

R 4.5.2 is also installed and has its own complete toolchain, but it carries roxygen2 8.0.0 against 4.6.1's 8.1.0 — running `devtools::document()` under it rewrites `Config/roxygen2/version` in DESCRIPTION back to `RoxygenNote`, producing a spurious diff. **Always regenerate docs under 4.6.1.**

Run from an R console in the project root, or from PowerShell via `Rscript -e "..."`.

```r
devtools::load_all(".")        # load package for interactive work
devtools::document()           # regenerate NAMESPACE + man/*.Rd from roxygen comments
devtools::test()               # run all tests
devtools::test(filter = "rounding")  # run one test file (tests/testthat/test-rounding.R)
devtools::check()              # full R CMD check — slow; Ian runs it manually, periodically
devtools::build_readme()       # regenerate README.md from README.Rmd

usethis::use_r("topic")        # scaffold R/topic.R
usethis::use_test("topic")     # scaffold tests/testthat/test-topic.R
usethis::use_package("pkg")    # add a dependency to DESCRIPTION Imports
pak::local_install_dev_deps()  # install deps declared in DESCRIPTION
```

Generated files — never hand-edit: `NAMESPACE`, `man/*.Rd` (run `devtools::document()`), `README.md` (edit `README.Rmd`, then `devtools::build_readme()`).

**Don't run `devtools::check()` automatically.** It takes long enough to be disruptive as a routine step, and Ian runs it himself periodically. The default verification for a change is `devtools::document()` (when roxygen comments changed) plus `devtools::test()` — that's sufficient to call work done. Run `check()` only if Ian asks for it.

## Layout and conventions

Flat package: one topic file per area in [R/](R/), with a matching `tests/testthat/test-<topic>.R`. Currently [R/paths.R](R/paths.R), [R/random.R](R/random.R), [R/reexports.R](R/reexports.R), [R/rounding.R](R/rounding.R).

**Input validation is a load-bearing contract.** Every exported function opens with a `stopifnot()` block of named conditions whose names read as user-facing messages (`'unit must be greater than 0' = unit > 0`). Tests assert on those strings via `expect_error(..., "unit must be greater than 0")`, so **editing a message breaks tests** — update both together. New functions should follow the same pattern: check length, type, finiteness, and range separately so the failure message pinpoints the problem.

**Deliberate divergence from base R gets documented.** These functions intentionally behave differently from their base/legacy counterparts, and the divergence is spelled out in an `@details` block and pinned by a test:
- `rbernoulli()` **errors** on `NA` in `prob` (base `rbinom()` warns and returns `NA`), refuses partial recycling (`prob` must be length 1 or `n`), and returns integer `0`/`1` rather than the logical values the deprecated `purrr::rbernoulli()` gave.
- `round_with_min()` sets exact zeros to `min` with a warning, and takes the sign from the *original* value, not the rounded one (so `-0.0004` → `-0.001`).

**Test file structure** uses `# --- Section ---` comment banners: correctness, edge cases / special values, then input validation.

**Always use `pkg::fn()` prefixes** for anything outside base R (`stats::rbinom()`, `dplyr::mutate()`, `tidyselect::where()`). A prior commit existed solely to fix `R CMD check` warnings from missing prefixes.

**Re-export pattern** ([R/reexports.R](R/reexports.R)): add the package to `Imports` via `usethis::use_package()`, then

```r
#' @importFrom janitor clean_names
#' @export
janitor::clean_names
```

and `devtools::document()`. All re-exports share the generated `man/reexports.Rd`.

`round_cols()` is a thin `dplyr::across()` wrapper over `round_with_min()` — behavior changes to the latter propagate, including the per-column zeros warning.

## Idea backlog: dev/ideas/

Function ideas are drafted as markdown in [dev/ideas/](dev/ideas/), one file per idea, before any code exists. See [dev/ideas/README.md](dev/ideas/README.md) for the folder's own rules and the current ordering constraints between ideas — read it whenever the backlog is in play, since it changes as items land. `dev/` is a development-only folder and never ships with the package.

**Capturing a new idea.** When a function idea comes up in conversation and Ian wants it deferred — "add that to the backlog", "note that for later", or an idea that clearly isn't today's work — write the file, don't write the function. Match the existing files' shape:

```markdown
# <Short title>

**Status:** <see below>
**Proposed file:** R/<topic>.R, tests/testthat/test-<topic>.R   # or: **Depends on:** <other idea>

## Motivation        — the real usage that prompted it, with a before/after snippet
## Design notes      — decisions already made, and why
## Open questions    — numbered, each one a decision Ian needs to make
## Testing notes     — what must be pinned; any new testing regime required
## Related           — other backlog items this blocks, shares logic with, or should ship beside
```

Capture the reasoning and the *rejected* alternatives, not just the conclusion — these sit untouched for weeks and the "why not X" is what's expensive to reconstruct. Sketches are expected to be incomplete; an idea file with only Motivation and Open questions is a valid file. Don't invent answers to fill sections out.

**The `Status:` line is a gate, and it is binding.** Read it before doing anything else:
- *ready* — no design discussion needed; implement it.
- *design discussion needed* — resolve the open questions with Ian **before writing code**.
- *deliberately underspecified* — Ian has explicitly reserved the design. Don't propose one until that conversation happens; ask, don't fill the vacuum.

Some files also carry a caution (e.g. "touches an existing exported function — check tests first"). Honor it as part of the task.

**Working an idea.** Read the whole file first, plus any file it depends on. As open questions get resolved, **write the answers back into the file** and move them out of Open questions into Design notes — do this when the decision is made, even if implementation stops there. A decision recorded only in chat is lost. When the function ships, delete the file or move it to `dev/ideas/done/`, and update any other idea file that referenced it.

**Ideas are not commitments.** The backlog is a staging area, not a to-do list to burn down. Don't start on a backlogged item because it's there — only when Ian asks. Surfacing that a relevant idea already exists ("dev/ideas/project-scaffold.md covers this — want me to pick it up?") is useful; silently implementing it is not.

## Notes

- `practice.qmd` is a personal scratchpad; it is both git-ignored and `.Rbuildignore`d. Don't treat it as part of the package.
