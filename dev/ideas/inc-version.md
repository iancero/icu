# inc_version() — save-as the active file with version incremented

**Status:** backlog — design discussion needed. Most of the open questions
below are still open; question 1 was resolved for free by retire()'s
ordering decision and has moved to Design notes.
**Proposed file:** R/paths.R family (grammar consumer)
**Raised:** 2026-08-26. Reconciled against the shipped repo 2026-08-30.

**Depends on:** nothing outstanding. The shared filename grammar
`{stem}[_vN]_{date}[_HH-MM-SS].{ext}` is **shipped**, factored into the
internal `parse_dated_filename()` in R/paths.R with exhaustive grammar
tests in test-paths.R. This would be its **third** consumer, after
`new_main()`'s version probe and `retire()`'s sweep. Per CLAUDE.md that
grammar is parsed in one place and nowhere else — this function inherits
it and owns none of its own.

## Motivation

The scaffold lifecycle names the move: "Major revision -> save-as main_v2;
retire() eventually sweeps v1 to old/". Save-as-increment IS the
versioning system (no git on Box), and it is currently the only step in
that lifecycle still done by hand-typing a filename. One call:

    # active file: main_v2_2026-08-23.qmd, today 2026-08-26
    icu::inc_version()
    # -> creates main_v3_2026-08-26.qmd, opens it in the editor

Identical content, incremented name, old file left in place. **Write-only**
— archival is `retire()`'s job, the same separate-blast-radii principle
that governs `new_main()`.

## Design notes

**1. The date refreshes to today. (DECIDED — follows from retire().)**

Lean was YES, pending joint confirmation with retire()'s ordering rule.
That rule was settled on 2026-08-30, and it settles this: **version
outranks date; date only breaks ties within a version; unversioned sorts
oldest** (see done/retire.md, ordering decision 1).

The original worry was that a refreshed date lets version and date
disagree across a group. Under version-first that disagreement is
harmless — `main_v3` beats `main_v2` on version before date is ever
consulted, whichever day each was stamped. The conflict the question was
guarding against cannot arise, so the date refreshes and no special
handling is needed.

Note this depends on the rule that was *chosen*, not the one this file
originally assumed. The rejected date-first proposal is what made the
question load-bearing; readers coming from the old cross-reference should
disregard it.

Rationale for refreshing, unchanged: the date segment marks creation
vintage everywhere else in the system — `new_main()` names with creation
date, `dated_path()` stamps today. A `main_v3` created today is a
2026-08-30 file.

## Open questions

2. **Increment = active + 1, or directory max + 1?** Lean DIRECTORY MAX:
   if v3 exists and you inc from the v2 window, active+1 collides; max+1
   never does. Warn when the probe skips past the active file's own
   version (you may be branching from a non-latest version — legitimate,
   but worth a message).

   **Sub-question this raises:** `new_main()`'s probe is *inline* at
   R/document.R:95-118, not a shared helper. Reusing it means extracting
   one — cheap and probably right, since the probe would then have two
   callers and the grammar already lives one layer down in
   `parse_dated_filename()`. But it edits a shipped function, so decide
   deliberately rather than as a side effect.

3. **Unversioned-but-dated active file** (`figure_1a_2026-08-23.png`):
   insert `_v2`, treating the existing file as implicit v1? Or refuse?
   Lean: works, inserts version — this is the natural "first revision of
   an unversioned artifact" gesture, and it agrees with retire()'s
   grouping, which already treats versioned and unversioned files of the
   same stem as one group. Decide with the grammar owner's hat on.

4. **Non-participating filenames** (`main.qmd`, unsaved Untitled, anything
   that doesn't parse): ERROR, with a message naming the expected
   grammar. Never guess a name.

   **Not** "consistent with retire()", as this file previously said —
   retire() marks non-participating files `ignored` and moves on
   (R/paths.R:405). The two differ for a good reason: retire() sweeps a
   whole directory, where ignoring the unparseable is the only sane
   behavior; inc_version() is handed exactly one file and asked to act on
   it, so silence would be a failure to do the job. Worth stating that
   contrast wherever this gets documented.

5. **Unsaved changes in the active document:** the on-disk copy would
   silently lack them — a sharp edge worth handling explicitly. Options:
   save first via `rstudioapi::documentSave()` (lean), or error and tell
   the user to save. Untitled (never-saved) documents are question 4's
   error.

6. **Name:** `inc_version()` is descriptive; `new_version()` would join
   the `new_main()` / `new_project()` family vocabulary — and both of
   those have now shipped, so that family is real rather than
   prospective. Counter-argument: both `new_*` functions create something
   from a template, while this one copies an existing file, so the
   vocabulary match may be surface-level. Pick at design time, and run
   the standard conflict check.

7. **Open the new file** (navigateToFile, active window) and leave the old
   tab open — or attempt to close the old tab? Lean: leave it; closing
   other tabs is surprising. The old file on disk is untouched either
   way.

## Mechanics sketch

- Active file path via `rstudioapi::getSourceEditorContext()`, guarded by
  the internal **`rstudio_available()`** in R/document.R — *not* a raw
  `rstudioapi::isAvailable()` call. That is a hard house rule (CLAUDE.md,
  "Editor side effects"): `isAvailable()` is TRUE when `devtools::test()`
  runs inside RStudio, so an inlined check makes the suite take the
  editor branch for real. Every test that reaches this function must mock
  that binding with `testthat::local_mocked_bindings()`.
- Headless usability and testability want a `path` argument:
  `inc_version(path = NULL)`, NULL meaning "active document".
- Core is a **pure planning function**: path in -> new path out (parse,
  probe, increment, restamp date). `file.copy()` for the write. All
  testable in a temp dir with zero rstudioapi.
- rstudioapi stays in Suggests (established posture).

## Validation (per package conventions)

`stopifnot()` block of named conditions whose names read as user-facing
messages, checked separately so the failure pinpoints the problem:

- `path` (if supplied): character, length 1, non-NA, existing file.
- Grammar non-participation and unsaved-document cases per questions 4-5:
  errors with pinned message text. Remember that editing any of these
  strings breaks the tests that assert on them.

## Testing notes

- The pure core carries the tests: increment cases (versioned,
  unversioned-dated, max-probe skip with warning), date restamp, error
  cases (no parse, missing file) matched on message text. Temp-dir
  fixtures follow retire()'s established style in test-paths.R.
- Copy fidelity: `expect_identical` on file lines — identical content is
  the whole contract.
- Editor paths (active-document detection, save, navigate) are
  untestable; keep them thin and isolated, per house convention.
- Midnight-flake note applies to the date restamp, same as `dated_path()`.

## Related

- [done/retire.md](done/retire.md) — the ordering rule that resolved
  question 1, and the fixture style the tests should follow.
- [done/new-main.md](done/new-main.md) — the version probe this would
  reuse, and the write-only posture it copies.
- [done/project-scaffold.md](done/project-scaffold.md) — the lifecycle
  step this automates.
