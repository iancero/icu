# Confirm-then-move retire(), and a migration log in old/

**Status:** DONE 2026-08-30 — implemented as specified below, with no
deviations. Everything from "Motivation" down is the design as decided,
kept as written; "As done" records what actually landed.
**Caution (while it was open):** this changed an **exported function's
signature and its default**. `dry_run` was removed, and a bare `retire()`
went from "never touches the disk" to "may move files after asking" —
reversing the first non-negotiable recorded in
[../../ideas/done/retire.md](../../ideas/done/retire.md), which now carries
a dated note pointing back here.

## As done (2026-08-30)

Landed exactly as designed. Four notes for anyone reading this later:

- **Three internals, not two.** `interactive_session()` and `ask_yes_no()`
  are the seams the tests mock, as specified — but the answer *parsing*
  split out into a third, pure internal, `is_yes()`. That is what makes
  the Enter/`y`/garbage contract testable without mocking
  `base::readline()`, which testthat cannot do cleanly for a primitive's
  namespace.
- **`write_migration_log()` is a fourth internal**, holding the log's whole
  format so `retire()` reads as a sweep rather than as a report writer.
- **The suite is 454 passing, 0 failures** (`test-paths.R` alone: 194 of
  them, in 94 `test_that()` blocks). 13 call sites renamed to
  `action = "move"`, 3 tests renamed or replaced, 20 new ones across
  asking, the log, and `ignore`.
- **`ignore` is checked against the parsed stem**, one term added to the
  existing `participates` expression in `R/paths.R` — no new pass over the
  directory, and ignored-by-name rows blank their parsed fields like every
  other `ignored` row, exactly as decided.
**Scope:** `retire()` in [../../../R/paths.R](../../../R/paths.R) (signature,
body, roxygen), two new internal seams beside it, the `retire()` section of
`tests/testthat/test-paths.R` including its `local_swept_dir()` fixture,
and the retire paragraph in `CLAUDE.md`. `dry_run` appears 9 times in
`R/paths.R`, 18 times in `test-paths.R` (13 of them `dry_run = FALSE` call
sites), 5 times in the generated `man/retire.Rd`, and once in `CLAUDE.md`.
No DESCRIPTION change — `utils` is already in Imports, and nothing here
needs it.
**Raised:** 2026-08-30, by Ian. **Decided:** 2026-08-30.

## Motivation

Two asks, from using the shipped function.

**1. The two-call workflow is one call too many.** The designed path is
`retire()`, read the plan, then `retire(dry_run = FALSE)`. In practice the
plan is on screen and the answer is yes, and retyping the call with an
argument is friction at the moment you have already decided. Ian's ask:
default behavior shows the plan, then asks `(Y/n)` whether to proceed.

Worth noting this is not only faster, it is *safer* in one respect the
original design flagged and accepted: the directory can change between the
two calls, so what the second call moves is not guaranteed to be what the
first one showed. A prompt closes that window — the plan you approve is the
plan that executes.

**2. A real run should leave a record of what it moved**, so a sweep can be
undone by hand if it turns out to have been wrong. Today the only record is
the plan the function returns, and it is gone as soon as the console
scrolls.

## Design notes

### The signature

    retire(path = '.', action = 'ask', ignore = 'retire_migration')

`dry_run` is **removed**, not deprecated. There are three wanted states and
a boolean carries two:

| `action` | behavior |
| --- | --- |
| `'ask'` (default) | print the plan, then prompt `(Y/n)` |
| `'plan'` | print the plan, move nothing — today's `dry_run = TRUE` |
| `'move'` | move without asking — today's `dry_run = FALSE` |

Rejected: **keeping `dry_run` and adding `confirm`.** Two booleans give four
combinations for three states, one of them (`dry_run = TRUE, confirm =
TRUE`) meaningless, and the ask-by-default requirement forces `dry_run`'s
default to `FALSE` — a signature that advertises a function which moves
files. Also rejected: **`confirm = interactive()` alone**, with preview
being "answer n". Smallest signature, but it removes any way to see the
plan from a script or a knitted document, and makes the unattended default
*move silently*, which is the opposite of this function's posture.

**Validation follows the house pattern, not `match.arg()`.** The default is
the scalar `'ask'`, and the checks are named `stopifnot()` conditions like
every other argument in the package:

    'action must be length 1'                        = length(action) == 1,
    'action must be character'                       = is.character(action),
    'action must be one of ask, plan or move'        = action %in% c('ask', 'plan', 'move'),

Rejected: `action = c('ask', 'plan', 'move')` in the signature plus
`match.arg()`. It is the R idiom, it self-documents in the signature, and
it gives partial matching for free — but its failure message is
`'arg' should be one of ...`, which is not a user-facing sentence, and this
package's tests assert on validation strings as a contract. Consistency
with the stated rule wins over the idiom; `@param action` carries the
self-documentation instead.

`ignore` is validated the same way: character, no `NA`s, **length 0
allowed**. `ignore = character()` is how you deliberately sweep the logs
themselves.

### Non-interactive callers fall back to the plan

`action = 'ask'` with no one to ask prints the plan, moves nothing, and
says why:

    retire plan for output
      keep    main_v3_2026-08-22.qmd
      retire  main_v1_2026-08-21.qmd
    not an interactive session: nothing moved; re-run with
      action = 'move' to move 1 file to output/old/

This keeps the unattended default safe and keeps the roxygen `@examples`
working with no edits beyond the rename. Rejected: **erroring** (every
example and any habit-typed `retire()` in a script would have to name an
action), and **warning instead of printing** (it would fire on every
knitted render and every example during `R CMD check`).

This matters more than a fallback usually would, because `readline()`
returns `""` *immediately* when non-interactive and `utils::askYesNo()`
maps an empty answer onto its `default` — so `askYesNo(default = TRUE)` in
a check run is a silent yes that moves files. The fallback exists so that
code path is never reached. (`utils::menu()` is better behaved, returning
`0`, but is not used here.)

### Reading the answer

One read, no loop. `y`, `Y`, `yes` or a bare Enter proceeds; **everything
else declines**, including unrecognized input. Ambiguity resolves toward
not moving, and a function that moves files can never sit holding the
console. A slip costs one retyped call.

Rejected: **re-asking on unrecognized input** (a read loop needs its own
cap and its own test for the cap, inside a function that already
special-cases having no input at all) and **`(y/N)`, requiring an explicit
`y`** (the whole point is speed, and Enter is the fast key).

### The prompt needs two mockable seams — this one will hang the suite

Both go in `R/paths.R` beside `retire()`, its only consumer, and both are
internal bindings so the tests can mock them:

    interactive_session()   # wraps interactive()
    ask_yes_no(prompt)      # wraps readline(), returns TRUE/FALSE

`retire()` then reads: `action == 'ask'` and not
`interactive_session()` → the fallback above; otherwise `ask_yes_no()`
decides.

**`interactive()` is TRUE under `devtools::test()`.** It reports on the
session, not the call stack, so a suite run from the console — the normal
way this package is tested — takes the interactive branch for real and
**blocks on a prompt that nothing will ever answer**. This is precisely the
`rstudioapi::isAvailable()` trap that `rstudio_available()` exists to
close, and it is why `interactive()` must not be inlined: it is a
primitive, so it cannot be mocked directly, and the wrapper is the only
seam available. `R CMD check` is genuinely non-interactive, so the examples
are safe either way — the hazard is `devtools::test()` specifically.

Rejected: `rlang::is_interactive()`, which respects an option and would
solve this cleanly, but adds rlang to Imports for one call.
`rstudioapi::showQuestion()` was also considered and rejected: a modal
dialog is slower than typing `y`, and speed is the whole point.

### `ignore`, and why the log does not need a special name

Ian's answer to the self-sweeping problem, and a better one than renaming
the log: **`ignore` is a character vector of stems that never participate
in a sweep**, defaulting to the log's own stem. `parse_dated_filename()`
already returns a `stem` column, so the filter is one line beside the
existing directory exclusion:

    participates <- parsed$parsed & !dir.exists(full) & !(parsed$stem %in% ignore)

Exact matching, case-sensitive, stems only — not filenames, not extensions.
The problem is fixed in the sweeper rather than in the filename, so the log
keeps one date grammar with everything else in the package.

The default stem is **`retire_migration`**, not `migration`. A default
entry of `'migration'` would silently shadow a real `migration_2026-*.qmd`
— a data migration script, a migration analysis — and the failure mode is
invisible: the file just never gets swept, and the plan says `ignored`
without saying why. `retire_migration` cannot collide by accident and names
the function that wrote it. (Underscore-heavy stems already parse; there is
a test for it.)

This reverses the "no `keep` argument" posture recorded in
`ideas/done/retire.md`, and deliberately: that argument protected *a file
the sweep had judged*, on a need that had not yet appeared. This one
excludes *a class of names the sweep should never judge*, on a need the
package itself creates.

**An ignored-by-name row carries no parsed fields**, like every other
`ignored` row — the existing rule is that a row which did not participate
cannot be mistaken for one that was weighed and lost, and that reasoning
applies unchanged. The cost is that the plan does not distinguish "did not
parse" from "deliberately ignored". Accepted, consistent with the
no-new-surface decision below; one line to reverse if it ever bites.

### The log file

**Name:** `retire_migration_<date>_<time>.txt`, built with
`dtp('retire_migration.txt')` so the grammar is reused rather than
re-derived. Written into `old/`.

**When:** on a real run, **only if at least one file actually moved**. Not
on `action = 'plan'`, not on a decline, not when there was nothing to
retire. This is what keeps "a second run is a no-op" true, which makes that
test load-bearing for this rule rather than incidental — say so in a
comment there.

*Accepted limit:* if every move fails, nothing moved, so no log is written
and the failures are recorded only by the existing `warning()`. A run that
changes nothing should write nothing; the warning is already loud.

**Format:** `#`-commented header, then a two-column tab-separated table.
`read.delim(comment.char = '#')` returns a usable data frame, so undo is
one line, while the header still tells a person what run this was.

    # icu::retire() 2026-08-30 14:22:01
    # swept: output/
    # moved: 2  skipped: 1  failed: 0
    # skipped (already in old/): figure_1a_2026-08-24.png
    from	to
    main_v1_2026-08-21.qmd	old/main_v1_2026-08-21.qmd
    main_v2_2026-08-23.qmd	old/main_v2_2026-08-23.qmd

Undo, by hand:

    m <- read.delim(log, comment.char = '#')
    file.rename(file.path('output', m$to), file.path('output', m$from))

**Paths are relative to the swept directory** — `from` is the basename,
`to` is `old/<basename>`. Absolute paths would break the moment the project
moved, and retire() is per-directory anyway, so the basename is the whole
story.

**Only moves go in the table; the awkward cases go in the header.** Every
row is therefore reversible and undo needs no filtering step — a filter
that is forgotten is a rename attempted against a file that never moved.
Skipped and failed files are *named* on comment lines, not merely counted,
since "skipped: 1" six months later names nothing. Emit those two comment
lines only when they are non-empty. Rejected: a third `status` column
holding everything (undo grows a required filter), and counts alone (the
one case where the plan has long since scrolled away is exactly the case it
fails to record).

**The header timestamp comes from the file name**, read back with
`parse_dated_filename()` and its `-` swapped for `:` in the time. `dtp()`
takes its own clock reading internally, so a separately formatted
`Sys.time()` could disagree with the name across a second boundary. Reading
it back out of the name makes that impossible, and exercises both halves of
the grammar. (If that reads as precious at implementation time, the simpler
fix is to drop the timestamp line — the file name already carries it. What
is *not* acceptable is hand-assembling the name from a local `Sys.time()`:
that re-derives the grammar, which this package keeps in one place.)

**If writing the log fails, `warning()` — never an error.** The files have
already moved; erroring would imply they had not.

### What the plan says, and what the console says

**A declined sweep returns the plan exactly as a `'plan'` run does** — rows
still read `retire`, meaning "would move". No new `action` value, no
attribute. Rejected: `attr(plan, 'moved')` and a fifth action value
`declined`; both add documented surface, and `declined` would put a
call-level outcome in a per-file column.

The accepted cost: a script capturing `plan <- retire()` cannot tell a
declined sweep from a completed one. In practice the log closes that gap on
disk — it exists if and only if files moved — and at the console you just
answered the prompt.

**A real run prints a second line naming the log**, so the undo record is
something you can see and copy rather than something you have to know
about:

    retired 4 files to output/old/ (1 skipped)
    log: output/old/retire_migration_2026-08-30_14-22-01.txt

Both existing output tests match on a substring of the first line, so
neither breaks.

## Open questions

**None.** Everything above was decided on 2026-08-30. The status gate is
open.

## Testing notes

The `retire()` block of `tests/testthat/test-paths.R` is where nearly all
the cost lands. There are 45 `retire(` calls in that file and 13 of them
pass `dry_run = FALSE`; all of those become `action = 'move'`.

**Do the fixture first.** `local_swept_dir()` (line ~423) must gain
`local_mocked_bindings()` for both new seams, exactly as `test-project.R`
folds the `rstudio_available()` mock into `local_projects_dir()` so it
cannot be forgotten. Without it, every bare `retire(dir)` in the suite
takes the interactive branch when the suite is run from the console and
waits forever for an answer. Default the fixture to
`interactive_session = function() FALSE`; tests about the prompt override
it.

Named tests that break or need review, in file order:

- **"a real run moves the retired files and leaves the rest" (534)** —
  asserts `list.files(dir/old)` is exactly four names. The log makes it
  five. Breaks by design.
- **"a dry run touches nothing, and creates no old/" (551)** — becomes
  `action = 'plan'`, and gains a sibling: **declining at the prompt touches
  nothing**, creating neither `old/` nor a log.
- **"a second run is a no-op" (561)** — survives *only if* the log is
  written solely when at least one file moved. Comment it as the test that
  pins that rule.
- **"a real run reports what it moved" (572)** and **"the count in the
  closing line is singular when it should be" (578)** — the substring
  matches still pass; add an assertion for the new `log:` line.
- **"nothing to retire says so, and creates no old/" (585)** — extends to
  "and writes no log".
- **the three collision tests (594, 606, 617)** — real runs whose `old/` is
  now one file larger, and where the `# skipped (already in old/):` header
  line gets pinned.
- **"invalid dry_run is rejected" (749)** — the argument is gone; replace
  with `invalid action is rejected` and `invalid ignore is rejected`,
  asserting on the new message strings.
- **"nothing is moved when validation fails" (758)** — extend to assert no
  log was written either.

New tests beyond those:

- the prompt is never reached when there is nothing to move (nothing to
  retire must not ask);
- three mocked outcomes: yes moves, no declines, non-interactive prints the
  plan and moves nothing;
- unrecognized input declines, and does so without a second read;
- `ignore` works: a file whose stem is in the list is never swept, appears
  as `ignored`, and carries no parsed fields; `ignore = character()` sweeps
  the logs like anything else;
- the log's content — the `from`/`to` pair round-trips through
  `read.delim(comment.char = '#')`, one row per file that actually moved
  and none for a file that did not, paths relative to the swept directory;
- the header names skipped files rather than only counting them, and omits
  the skipped/failed lines when there are none;
- the header's timestamp agrees with the file name it was read from.

One platform note: the log is written at runtime on Windows, where
`writeLines()` to a text-mode connection emits CRLF. The repo's LF rule is
a `.gitattributes` rule about tracked files and does not reach a file
written into a user's project. Assert with `readLines()`, which normalizes,
rather than on the file's bytes — `read.delim()` is untroubled either way.

Verification is the usual `devtools::document()` plus `devtools::test()`.
Nothing here touches DESCRIPTION, `inst/`, or the build.

## Related

- [../../ideas/done/retire.md](../../ideas/done/retire.md) — the shipped design.
  Two of its recorded decisions are reversed here and both need a dated
  note written back into that file when this lands, or the next reader
  takes them at face value: the **`dry_run = TRUE` non-negotiable** (the
  *touch nothing unless told* half survives; the argument and the default
  do not) and **"no `keep` argument"** (`ignore` is a narrower thing, but
  it is the same kind of surface, added for a need that has now appeared).
  Its ordering, collision, and return-value reasoning all still hold.
- [../../ideas/inc-version.md](../../ideas/inc-version.md) — would be the
  grammar's third consumer. The log makes retire() write grammar-conformant
  names as well as read them, and is the first name in that shape produced
  by a function rather than typed by a person.
- `CLAUDE.md`, the retire paragraph: *"`dry_run = TRUE` is the default and
  creates nothing, not even `old/`"* is exactly what changes, and the
  sentence naming `retire()` as the only thing that moves a file into
  `old/` gains an asterisk — it also writes one there.
- A possible `unretire()`. Not proposed, and not something this chore
  should build — but the log format above is deliberately readable back in,
  so it would be an afternoon rather than a rewrite. It would not need to
  filter the logs out of `old/`: `ignore` already does that.
