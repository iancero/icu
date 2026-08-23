# retire() — sweep superseded dated/versioned files to old/

**Status:** design discussion needed (ordering rule + scope). ~~grammar must
be settled jointly with dated-path~~ **Grammar now pinned by qmd-creator**
(2026-08-23) — see "Shared parser" below.
**Proposed file:** R/paths.R family (shares the filename grammar)
**Depends on:** the filename grammar as pinned in qmd-creator.md

## Motivation

The dated-path / qmd-creator conventions deliberately accumulate files:

    main_v3_2026-08-23.qmd     <- keep (latest of main/.qmd group)
    main_v3_2026-08-22.qmd     -> old/
    main_v2_2026-08-22.qmd     -> old/
    main_v1_2026-08-21.qmd     -> old/
    figure_1a_2026-08-23.png   <- keep (latest of figure_1a/.png group)
    figure_1a_2026-08-22.png   -> old/

`retire()` periodically sweeps: group files by (stem, extension), keep the
most recent in place, move the rest to an `old/` directory.

**Standing decision (2026-08-23):** qmd-creator is write-only — creating
`main_v3` leaves `main_v2` in place. retire() is the *only* mechanism that
moves files to `old/`, replicating the manual move step of the pre-package
workflow. This separation is deliberate: one function writes one file, one
function relocates files; different blast radii, separate contracts.

## Shared parser (grammar now pinned upstream)

The grammar is:

    {stem}[_vN]_{YYYY-MM-DD}[_HH-MM-SS].{ext}

Changes from the original draft of this file:

- **Pinned by qmd-creator, not here.** qmd-creator's version probe is the
  first consumer (it must recognize `{stem}_v*` files to increment), so the
  grammar is fixed at its implementation time. retire() inherits it.
- **Version segment optional** (unchanged from draft — figure_1a files have
  none).
- **Time segment optional** (NEW — the draft omitted it, but
  `dated_path(hms = TRUE)` emits `_HH-MM-SS` and those files exist in real
  folders; retire() must parse them).

The one-internal-parser plan stands: a non-exported
`parse_dated_filename()` returning stem / version (NA if absent) / date /
time (NA if absent) / ext, consumed by every function speaking the grammar.
Whether it gets built during qmd-creator's implementation or during
retire()'s is a timing choice; the exhaustive grammar tests live with the
parser, wherever and whenever it is built.

## Ordering rule (decision needed)

Example only shows date and version agreeing. When they conflict
(`main_v3_2026-08-22` vs `main_v2_2026-08-23`), proposal:

- **Date first, version as tiebreaker within a date; time as tiebreaker
  within a version** (time added now that the grammar includes it).
  Rationale: "later date = more recent work" matches actual usage.
- Tie on all (shouldn't happen, but filesystems are filesystems): error
  loudly rather than pick arbitrarily.

## Non-participation is the safe failure mode

Files that don't parse under the grammar are ignored (left in place),
optionally listed in the dry-run report as "not recognized". Real folders
will contain near-misses — e.g. `figure_1a_2026_08-22.png` (underscore in
the date) from the motivating example itself. Strict matching means a
malformed name is left alone, never "helpfully" retired. Undated files
(`main.qmd`) likewise never participate.

## Scope questions (decision needed)

1. **Per-directory, not per-project (proposal):** operate on one directory
   (`path = "."` default?), each file moving to `old/` *within that same
   directory* (`output/figure_1a_... -> output/old/`). A whole-project
   recursive sweep is scarier and can come later as `recursive = TRUE`.
2. Create `old/` if missing (obviously), but decide: is the name `old`
   fixed or an argument? Fixed keeps the convention legible; argument
   costs nothing. Lean: argument with default `"old"`.
3. Should `old/` itself be excluded from scanning (yes — never recurse into
   the retirement home).

## Non-negotiables (same as transcript organizer)

- **`dry_run = TRUE` default:** print the keep/move plan; touch nothing
  unless `dry_run = FALSE`.
- **Idempotent:** running again immediately after a sweep is a no-op.
- **Never overwrite:** if a target name already exists in `old/` (possible
  if a file was restored and re-retired), error — do not clobber history.

## Open questions

1. Ordering rule confirmation (date-first proposal above, now with time
   tiebreaker).
2. Scope: per-directory default confirmed? recursive option ever?
3. Return value: invisible data frame of the plan (file, group, action,
   destination)? Useful for logging and makes dry-run output testable as
   data rather than printed text.
4. Keep-count argument (`keep = 1` default, `keep = 2` to retain the two
   most recent)? Cheap to add, plausibly useful.
5. Name: `retire()` is good — short, unambiguous, no known conflicts in
   common packages. Confirm no clash at design time.

## Validation (per package conventions)

- Strict on parameters: `path` character length-1 non-NA existing directory;
  `dry_run` logical length-1 non-NA; `keep` (if added) whole number >= 1 via
  `keep == trunc(keep)`.
- Permissive on data: empty directory or nothing-to-retire is a message +
  no-op, not an error.

## Testing notes

- Temp-dir fixture seeded with the motivating example's exact file set,
  including the malformed `figure_1a_2026_08-22.png` — assert it is left
  untouched (pin the safe-failure contract) — plus at least one
  `_HH-MM-SS` file now that the grammar includes the time segment.
- Pin: grouping by (stem, ext) — same stem different ext are separate
  groups; ordering rule including a date/version conflict case; idempotency
  (second run no-op); dry_run touches nothing (dir snapshot before/after);
  never-overwrite error, matched on message text.
- Grammar tests live with `parse_dated_filename()`, wherever it is built
  (see Shared parser above); keep retire() tests focused on grouping/moving.
