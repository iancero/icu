# Normalize line endings to one convention

**Status:** decision needed — one choice (which convention the *working
tree* uses), after which the work is mechanical and takes minutes.
**Scope:** whole repo; adds a `.gitattributes`. No package code changes, no
history rewriting.
**Raised:** 2026-08-23, while shipping `new_main()`.

## Motivation

The working tree is a mix of CRLF and LF, file by file, and it will keep
re-mixing on every edit until something pins it. Two costs, one of them
already paid:

1. **Silent tool failures.** A multi-line regex (`perl -0p`, `sed -z`,
   anything matching across `\n`) matches on the LF files and silently
   *no-ops* on the CRLF ones — no error, just an edit that didn't happen.
   This bit the `new_main()` work: four backlog edits appeared to apply,
   two of them hadn't, and one file was left with mixed endings that had
   to be hand-normalized. A future Claude session will hit it again; the
   failure is invisible unless someone re-reads every file afterward.
2. **Diff and editor noise**, and a working tree that differs between
   machines — a second machine, a collaborator, or CI on Linux would each
   check out something different from what's on this one.

## What is actually true today (measured 2026-08-23)

Better than it looks, and it narrows the job:

- **The repository is already consistent.** All 36 tracked files are `i/lf`
  in the index (`git ls-files --eol`). Committed content is LF; nothing in
  history needs rewriting, and nothing is currently *broken*.
- **Only the working tree is mixed:** 21 files `w/lf`, 15 `w/crlf`.
- `core.autocrlf = true` on this machine; no `.gitattributes`; `core.eol`
  unset. So the working-tree form is decided per-machine and per-tool,
  which is exactly why it drifts.
- The split runs by **who wrote the file**, not by file type: things
  checked out or saved by RStudio are CRLF (`R/rounding.R`,
  `test-rounding.R`, `icu.Rproj`, `README.md`, most of `dev/ideas/*.md`);
  things written by other tooling are LF (`R/paths.R`, `R/random.R`,
  `test-paths.R`, `DESCRIPTION`, `NAMESPACE`, most of `man/`).
- `inst/templates/main.qmd` is CRLF today (copied verbatim from a CRLF
  working copy).

## The decision

Which convention the working tree should use. The index stays LF either
way — this is purely about the files on disk.

- **A. `* text=auto eol=lf`** — one form everywhere, matching what the
  index already stores and what most of the tree already is. Every machine
  and every tool then agrees. Cost: RStudio on Windows writes CRLF for new
  files unless told otherwise, so pair it with the `.Rproj`
  `LineEndingConversion: Posix` setting (or Global Options > Code >
  Saving). **Lean: this one** — it is the form the repo already commits,
  and it is the one that makes the Bash-side tooling and the R-side tooling
  produce identical bytes.
- **B. `* text=auto eol=crlf`** — the working tree matches Windows-native
  editors with nothing to remember in RStudio. Cost: any Unix-side tooling
  (including a Claude session's shell edits) still writes LF, so the tree
  re-mixes unless every edit goes through git.
- **C. Leave it.** Defensible, since the index is already clean and nothing
  is broken. It just means the silent-no-match trap stays, and the answer
  to "why didn't that edit apply?" has to be rediscovered each time.

Whichever is chosen, it only fixes the trap if the tree is refreshed once
(step 3 below) rather than just declared.

## The work, once decided

1. Add `.gitattributes` with `* text=auto eol=<lf|crlf>`. No binary
   exceptions needed today — git reports no binary files in the repo, and
   there is no `man/figures/`; add `*.png binary` when README figures
   arrive.
2. `git add --renormalize .`
3. Refresh the working tree so the files on disk actually take the new
   form, on an otherwise **clean tree**: `git rm --cached -r .` then
   `git reset --hard`. Commit as one isolated "normalize line endings"
   commit, with nothing else in it.
4. If A: set `LineEndingConversion: Posix` in `icu.Rproj` so RStudio stops
   reintroducing CRLF, and note the convention in CLAUDE.md.
5. Re-run `devtools::check()`. **Watch for a new top-level-files NOTE:**
   `.gitattributes` is a top-level file R CMD check may not recognize. If
   it complains, add `^\.gitattributes$` to `.Rbuildignore` — the package
   currently checks at 0 errors / 0 warnings / 0 notes and should stay
   there.
6. Verify: `git ls-files --eol` should show a single `w/` value on every
   row.

## Notes and risks

- **Do it on a clean tree with nothing in flight.** The renormalize commit
  touches many files and will conflict with any open branch.
- **Nothing in the test suite pins this**, so nothing will break: the
  content tests compare `readLines()` output, which strips endings either
  way. That also means the suite won't catch a regression — `git ls-files
  --eol` is the check.
- `inst/templates/main.qmd` is user-visible output: whatever form it ends
  up in becomes the form of every document `new_main()` creates, since the
  copy is verbatim. Harmless (Quarto and RStudio read either), but worth
  knowing it isn't an internal-only change.

## Related

- Surfaced by the `new_main()` implementation — see
  [../ideas/done/new-main.md](../ideas/done/new-main.md).
- Affects any future bulk edit of `dev/ideas/*.md`, which are mostly CRLF
  and are exactly the files Claude sessions edit with shell tooling.
