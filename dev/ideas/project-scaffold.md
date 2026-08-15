# New R project scaffolder

**Status:** deliberately underspecified — structure to be discussed when we
get here (per Ian). Do not propose a structure until that conversation.
**Depends on:** dated-path helper, qmd-creator (likely orchestrates both)

## Motivation

One call creates a new consulting project with templated structure.

## Known so far

- Likely creates an `output/` folder (target of the dated-path helper) and
  seeds an initial `main.qmd` via the qmd-creator — so this is the
  *outermost* of the three filesystem functions and should be designed last.
- Side-effecting: creates directories/files, possibly initializes git,
  possibly opens the project in a new RStudio session.

## Testing notes

- Temp dir per test; assert the resulting file tree, not return values.
- Anything involving opening RStudio sessions is untestable — keep that part
  thin and isolated.

## To discuss when we get here

- Directory structure
- Git init? .gitignore contents?
- RStudio .Rproj generation and whether to open it
- Whether renv or any dependency management is in scope
