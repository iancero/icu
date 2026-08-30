# retire() — sweep superseded dated/versioned files to old/

**Status:** **SHIPPED 2026-08-30** as `retire()` in R/paths.R, with tests
in tests/testthat/test-paths.R. Designed and implemented the same day; the
sections below are the decisions as taken, kept for the reasoning.
~~READY — design settled 2026-08-30~~
~~design discussion needed (ordering rule + scope)~~ ~~grammar must be
settled jointly with dated-path~~ ~~Grammar now pinned by qmd-creator~~
**Grammar shipped with `new_main()` (2026-08-23)** — see "Shared parser"
below.
**Shipped in:** R/paths.R, beside dated_path() and the parser (shares the
filename grammar)
**Depends on:** nothing outstanding. The parser this file planned to share
already exists: internal `parse_dated_filename()` in R/paths.R, with the
exhaustive grammar tests in tests/testthat/test-paths.R.

## As shipped (2026-08-30)

Implemented as designed; every decision below held up. Four things the
design did not cover, settled at implementation and recorded here rather
than left to be read out of the code:

1. **The plan comes back in plan order**, not directory order:
   participants first, grouped and sorted newest-first within each group,
   then the `ignored` rows. The frame reads the way the plan prints.
2. **Output pluralizes** — `retired 1 file`, `retired 4 files`. Pinned by
   a test, because it is exactly the kind of thing that regresses
   unnoticed.
3. **A rename that fails for a reason other than a collision warns**, over
   and above the count in the closing line that the design named as the
   signal for it. Silence on a failed move was not worth the terseness.
4. **A sweep with nothing movable prints `nothing to retire in <path>` and
   returns early**, so a dry run in which every candidate collides shows
   that line plus the skip warning rather than a plan made entirely of
   skips. The warning carries the information; a plan of things that will
   not happen does not.

One implementation note worth keeping: group boundaries are detected on
the sorted stem and extension vectors rather than by pasting a grouping
key, so no separator character has to be assumed absent from a stem.

## Motivation

The dated_path() / new_main() conventions deliberately accumulate files:

    main_v3_2026-08-23.qmd     <- keep (latest of main/.qmd group)
    main_v3_2026-08-22.qmd     -> old/
    main_v2_2026-08-22.qmd     -> old/
    main_v1_2026-08-21.qmd     -> old/
    figure_1a_2026-08-23.png   <- keep (latest of figure_1a/.png group)
    figure_1a_2026-08-22.png   -> old/

`retire()` periodically sweeps: group files by (stem, extension), keep the
most recent in place, move the rest to an `old/` directory.

**Standing decision (2026-08-23, shipped):** new_main() is write-only — creating
`main_v3` leaves `main_v2` in place. retire() is the *only* mechanism that
moves files to `old/`, replicating the manual move step of the pre-package
workflow. This separation is deliberate: one function writes one file, one
function relocates files; different blast radii, separate contracts.

## Shared parser (SHIPPED — do not re-decide the grammar)

The grammar is:

    {stem}[_vN]_{YYYY-MM-DD}[_HH-MM-SS].{ext}

It was pinned by `new_main()`'s version probe (the first consumer: it must
recognize `{stem}_vN` to increment past it) and shipped 2026-08-23 as
non-exported `parse_dated_filename()` in R/paths.R, beside `dated_path()`.
retire() inherits it and should build no grammar of its own.

What it gives you, vectorized, one row per input name:

    file_name  stem  version  date  time  ext  parsed

`version` is an integer (`NA` when absent — so `v10` outranks `v9`, which
it does not alphabetically), `date` is a `Date`, `time` is `"HH-MM-SS"` or
`NA`, and every field is `NA` when `parsed` is `FALSE`. A directory portion
in the input is ignored for parsing and echoed back in `file_name`.

Strictness, already decided and tested — retire() gets non-participation
for free:

- **Version segment optional** (figure_1a files have none); **time segment
  optional** (`dated_path(hms = TRUE)` emits it, and those files exist).
- **Extension required.** An extensionless `main_v1_2026-08-23` is as
  likely to be a directory as a file, so it does not parse. This is what
  keeps retire() from walking into a subdirectory named like a document.
- A name that matches the shape but names no real day (`2026-02-30`) or no
  real time (`25-00-00`) does not participate either.

The exhaustive grammar tests live with the parser, in
tests/testthat/test-paths.R. Keep retire()'s own tests focused on grouping,
ordering, and moving.

## Ordering rule (DECIDED 2026-08-30)

Within a group, newest wins and everything else goes to `old/`. Four
decisions, taken with Ian on 2026-08-30.

1. **Version outranks date. Date breaks ties within a version; time breaks
   ties within a date. Unversioned files sort as oldest.**

   Rejected: date-first, which is what this file originally proposed. Its
   motivating case was a revival — restoring `main_v2` from `old/` on a
   later day, where version-first retires the file you just went back to.
   Ian's call: uncommon, because development on these projects is linear,
   and easier to handle by hand when it happens than to bend the ordering
   rule around. A version number is an explicit statement of supersession;
   a date is incidental to when a file happened to get started.

   Also rejected: a hybrid where version decides when every file in the
   group carries one and date decides otherwise. Too conditional to hold in
   your head while reading a dry-run plan.

2. **Grouping is (stem, extension) and nothing else.** A dated-but-
   unversioned file therefore competes with versioned files of the same
   stem and extension: `figure_1a_2026-08-24.png` is retired in favor of
   `figure_1a_v2_2026-08-23.png`, despite being a day newer.

   That sharp edge is accepted deliberately. The alternative — sweeping
   versioned and unversioned as two independent groups — can never retire a
   legacy `main_2026-08-21.qmd` once `main_v1` exists, because it is the
   sole member of its own group forever. Accumulating exactly the clutter
   this function exists to clear is the worse failure mode. **The dry run
   is the safety net here, not the grouping rule**: `dry_run = TRUE` is the
   default, so a surprising plan gets read before anything moves.

3. **A missing time segment sorts as older**, so of
   `figure_1a_2026-08-23.png` and `figure_1a_2026-08-23_14-30-00.png` the
   timed file is kept.

   This is a convention, not a fact — the timeless file's real time is
   unknown, not zero. It is justified by `dated_path()`'s own semantics: a
   timeless name is a slot to be overwritten ("re-running an analysis
   usually means replacing this morning's figure"), while `hms = TRUE` is
   how you say "keep every run". Retiring the replaceable one preserves
   what was explicitly marked worth keeping.

   Rejected: timeless-sorts-newer, which has no supporting rationale; and
   breaking the tie on filesystem mtime, the only option grounded in fact
   rather than convention, but it costs the property that retire() reasons
   about names rather than files, and Box sync rewrites mtime on files it
   did not semantically change.

4. **No "tie on everything" error.** The branch this file originally
   proposed is unreachable: after decision 3, a total tie means two files
   with an identical name in one directory. Untestable defensive code is
   worse than none — it cannot be exercised, so it rots, and it tells the
   next reader the tie is something that happens.

   It becomes reachable only if `recursive = TRUE` ever lands *and* groups
   are keyed across directories. Note `parse_dated_filename()` takes
   `basename()`, so per-directory grouping is what the parser already
   assumes; a recursive version would most naturally keep it and never
   reach the tie either.

## Non-participation is the safe failure mode

Files that don't parse under the grammar are ignored (left in place) and
appear in the plan as `action = "ignored"`, summarized in the printed
output as a count (decided 2026-08-30). Real folders will contain
near-misses — e.g. `figure_1a_2026_08-22.png` (underscore in the date)
from the motivating example itself. Strict matching means a malformed
name is left alone, never "helpfully" retired. Undated files
(`main.qmd`) likewise never participate.

## Scope, reporting, and mechanics (DECIDED 2026-08-30)

Taken with Ian on 2026-08-30, in the same pass as the ordering rule.

**Scope: one directory, non-recursive.** `retire(path = '.')` sweeps that
directory only, and each retired file moves to `old/` *inside it*
(`output/figure_1a_... -> output/old/...`). A project takes two calls, one
at the root for documents and one in `output/` for figures. That friction
is nothing against the blast radius of a recursive maintenance function
reaching directories you were not thinking about when you typed it.
Per-directory is also what the parser already assumes: it takes
`basename()`, so a stem never carries its directory.

Rejected: designing `recursive = TRUE` in from the start (it reopens the
tie case that ordering decision 4 closes, and unbounds the blast radius),
and a vectorized `path` (breaks the length-1 validation pattern every
other exported function follows).

The `path = '.'` default is safe *because* `dry_run = TRUE` is also a
default: a bare `retire()` prints a plan and touches nothing, which makes
it a good "what has accumulated in here?" gesture.

**`old/` is a fixed name, not an argument.** It is a documented house
convention — `conventions.md` names it beside `data/` and `output/`, and
`new_project()` scaffolds against that layout — so making it configurable
would turn retire() from a statement of the convention into a generic file
mover that happens to default to it. Same reasoning as dropping `keep`
below: an argument that "costs nothing" still costs a permanent line in
the signature, the docs, and the validation block.

`old/` is created **only on a real run**. A dry run that created an empty
`old/` would violate the contract the directory-snapshot test exists to
pin. `old/` is never scanned, and directories are excluded from the sweep
generally: `analysis_2026-08-23.old` is a *directory* that parses cleanly
under the grammar, and `list.files()` returns directories alongside files,
so without a `dir.exists()` filter retire() would rename a folder.

**Return value: always the plan, invisibly, as a data frame.** Same shape
whether or not anything moved, one row per file in the directory, every
file accounted for in exactly one row:

    path  stem  ext  version  date  time  action  destination

`action` is one of `keep`, `retire`, `skipped`, `ignored`; `destination`
is `NA` except on `retire` rows. Carrying `version`, `date` and `time`
costs nothing — they are already parsed in order to sort — and it turns
"why did today's figure lose?" into something readable straight off the
plan. That question is guaranteed to come up, because ordering decision 2
makes a newer unversioned file losing to an older versioned one the
designed behavior, and the plan should show its work.

Invisible for the same reason `dated_path()` returns invisibly: on a dry
run the plan has already gone to stdout, and a visible return would print
it a second time in the console.

Rejected: returning the plan only on a dry run (two return shapes, so a
caller that logs both has to branch); returning a character vector of the
files moved (throws away why a file lost); and returning nothing (which
forces the tests to assert on printed text, the thing this file already
flagged as worth avoiding).

**Unrecognized files appear as `ignored` rows but print only as a count.**
Two indistinguishable kinds of file land there: near-misses like
`figure_1a_2026_08-22.png` that were meant to be dated, and files that
were never dated and never will be (`README.md`, `icu.Rproj`). Listing
them individually is a real signal in `output/`, where everything is
supposed to be dated, and pure noise in a project root, where a dozen
undated files would bury the two lines you wanted to read. The count is
the hook: if `output/` reports anything not recognized, go look.

Rejected: flagging *likely* near-misses separately. That needs a second,
fuzzier grammar sitting beside the strict one, and two grammars is exactly
what the parser work exists to avoid.

**Printing goes through `cat()`**, matching `dated_path()`. Note the
precedent is weaker than it looks: `dated_path()` chose stdout to survive
`message: false` in a document's YAML, and retire() will never be called
from a knitted document. The real reason is that a dry-run plan is the
*point* of the call rather than a diagnostic about it — you typed
`retire()` in order to see it. `message()` was the alternative, and its
one concrete advantage is that `capture.output()` would not swallow the
plan.

**A real run prints one confirmation line**, e.g.
`retired 4 files to output/old/ (1 skipped)`. Silence was defensible on
Unix grounds, since the usual path is dry-run, read, re-run, and you have
already seen the plan. Two things argued against it: the directory can
change between the two calls, so what moved is not guaranteed to be what
you approved; and a count reading `2` when the plan had `5` is the
cheapest possible signal that the sweep stopped early.

**No `keep` argument.** Dropped, against this file's original lean.
(**2026-08-30:** still no `keep`, but the sibling argument this reasoning
also ruled out now exists. `ignore` takes a vector of stems that never
participate in a sweep, defaulting to the migration log's own stem. The
distinction that justifies it: `keep` would protect *a file the sweep had
judged*, on a need that had not appeared; `ignore` excludes *a class of
names the sweep should never judge*, on a need the package created for
itself when `retire()` started writing a log into `old/`. Same file as
above.) If
retire() sweeps a version you turn out to want, it is sitting in `old/` —
this is a move, not a delete, and the dry run showed you first. The cost
of not having it is one trip to `old/`; the cost of having it is permanent
surface for a need that has not yet come up. This matches the posture
`new_main()` shipped with (no template argument: "add a second only if a
real recurring need appears"), and it stays additive if the need appears.

**Moves use `file.rename()`.** Per-directory scope settles this for free:
`old/` is inside the directory being swept, so it is always the same
filesystem, and a copy-and-unlink fallback is never needed.

## Non-negotiables (same as transcript organizer)

- **`dry_run = TRUE` default:** print the keep/move plan; touch nothing
  unless `dry_run = FALSE`. Creating `old/` counts as touching.

  **Revised 2026-08-30**, after using the shipped function — see
  `../../chores/done/retire-confirm-and-log.md` for the full reasoning.
  `dry_run` is gone, replaced by `action`, one of `'ask'` (the default:
  print the plan, then prompt), `'plan'` (the old `dry_run = TRUE`) and
  `'move'` (the old `dry_run = FALSE`). The *safe by default* half of this
  non-negotiable stands unchanged — nothing is touched, `old/` included,
  until someone says so, and with no one to ask, `'ask'` degrades to
  `'plan'`. What changed is that saying so no longer means retyping the
  call, which also closes a hole this file accepted: the directory could
  change between the two calls, so what the second one moved was not
  guaranteed to be what the first one showed.
- **Idempotent:** running again immediately after a sweep is a no-op.
- **Never overwrite:** if a target name already exists in `old/` (possible
  if a file was restored and re-retired), that file is **skipped, with a
  warning** — never clobbered. Decided 2026-08-30, revising this file's
  original "error loudly".

  The collision is detected while the **plan is built**, not discovered
  mid-move, so a colliding file shows up on the dry run as
  `action = "skipped"` before anything is committed to. What changes
  against the rejected all-or-nothing version is only the consequence: one
  collision skips one file instead of aborting the sweep. Erroring would
  let a single stale name in `old/` hold routine housekeeping hostage on
  every run until it was cleared by hand; skipping completes the sweep and
  lets the problem file keep nagging, since it is skipped and warned about
  again on the next run. Idempotency survives either way.

  The check **cannot be delegated to the move**: on POSIX, `rename(2)`
  replaces an existing destination silently and atomically, so
  `file.rename()` returning `TRUE` is not evidence that nothing was
  overwritten.

  Skips are reported with `warning()` rather than folded into the `cat()`
  output, matching how `new_main()` warns on a version bump — something
  that happened, that you need to know about, and that no one should have
  to re-read the plan to notice.

  **Accepted limit:** this eliminates the collision class, not every
  failure. A Box file lock or a permissions error can still fail on the
  third of five moves, and rolling back the first two is more machinery
  than this deserves. That is the other reason a real run prints a count.

## Name (CHECKED 2026-08-30)

No clash. All 295 packages installed under R 4.6.1 were scanned for an
exported `retire`: none has one, and nothing named `retire` sits on the
default search path. Old open question 5 is closed.

## Open questions

**None.** Everything in this file was decided on 2026-08-30 — ordering,
grouping, scope, reporting, mechanics, and the name check — so the status
gate is open and implementation can start.

## Validation (per package conventions)

- Strict on parameters: `path` character length-1 non-NA existing
  directory; `dry_run` logical length-1 non-NA. There is no `keep`
  argument and no `old` argument — see the decisions above.
- Permissive on data: empty directory or nothing-to-retire is a message +
  no-op, not an error.

## Testing notes

- Temp-dir fixture seeded with the motivating example's exact file set,
  including the malformed `figure_1a_2026_08-22.png` — assert it is left
  untouched and appears as an `ignored` row, pinning the safe-failure
  contract — plus at least one `_HH-MM-SS` file, now that the grammar
  includes the time segment.
- **Assert against the returned plan as data**, not against printed text.
  That is what the return-value decision buys. Keep printed-output
  assertions down to the one confirmation line, and match the skip
  warnings on message text.
- Pin each ordering decision with a case that would come out differently
  under the rejected rule:
  - version outranks date: `main_v3_2026-08-22` beats
    `main_v2_2026-08-23`;
  - grouping is (stem, ext), so a versioned and an unversioned file with
    the same stem compete — `figure_1a_2026-08-24.png` is retired in
    favor of `figure_1a_v2_2026-08-23.png` despite being a day newer;
  - same stem with different extensions are separate groups;
  - a missing time segment sorts older than a present one.
- Pin the mechanics: idempotency (second run is a no-op); `dry_run`
  touches nothing, *including* creating no `old/` (directory snapshot
  before and after); a directory named like a dated file
  (`analysis_2026-08-23.old/`) is never moved; and a collision leaves that
  file in place, raises a warning, and still completes the rest of the
  sweep.
- No test for a total ordering tie: ordering decision 4 makes it
  unreachable per-directory.
- Grammar tests live with `parse_dated_filename()` in test-paths.R (see
  Shared parser above); keep retire()'s own tests focused on grouping,
  ordering, and moving.
