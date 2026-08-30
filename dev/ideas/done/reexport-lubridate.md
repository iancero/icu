# Re-export lubridate::today and lubridate::now

**Status:** **SHIPPED 2026-08-30** as re-exports of `lubridate::today` and
`lubridate::now` in R/reexports.R, with `lubridate` added to DESCRIPTION
Imports. The dependency question below was settled at implementation, as
planned; the sections are kept for the reasoning.
~~backlog — quick win, one dependency question to settle at implementation~~
**Proposed file:** R/reexports.R (existing)
**Raised:** 2026-08-26. Reconciled against the shipped repo 2026-08-30.

## Motivation

Easy timestamping in consulting scripts — `today()` and `now()` read
better than `Sys.Date()` / `Sys.time()` in the dated-filename workflow the
package is built around. `now()` pairs with the grammar's optional
`[_HH-MM-SS]` segment the way `today()` pairs with the date segment; that
segment is no longer hypothetical, it is `dated_path(hms = TRUE)` and the
`time` field that `parse_dated_filename()` reads. Fits the
re-export-over-wrapper rule.

## Steps

1. `usethis::use_package("lubridate")` (not currently in Imports).
2. Add to R/reexports.R:

   ```r
   #' @importFrom lubridate today
   #' @export
   lubridate::today

   #' @importFrom lubridate now
   #' @export
   lubridate::now
   ```

3. `devtools::document()` — both join the shared man/reexports.Rd.

Touching DESCRIPTION means this is one of the changes worth saying so
about rather than calling done on `document()` + `test()` alone.

## Dependency-weight note — decided 2026-08-30: yes, lubridate goes in

Ian asked for the task by name on 2026-08-30, which settled it: the
re-exports are worth an Imports slot. The reasoning below is what the
decision was made against, kept as-is.

This was the whole of the decision — everything else was mechanical.

- `today()` is functionally `Sys.Date()` with a `tzone` argument; `now()`
  is `Sys.time()` likewise. The re-exports buy readability, not
  capability — but ONE lubridate Imports decision buys BOTH, which is a
  better cost/benefit than `today()` alone would be.
- Counterweight: Ian's scripts typically load tidyverse, which attaches
  lubridate anyway — the re-exports' marginal value is sessions where
  only icu is loaded (exactly the quick-console-work case where easy
  timestamping matters, so arguably the point).
- lubridate is a heavier Imports than the current set. `glue` and
  `janitor` are the precedent, and both are lighter.
- Internals are unaffected either way, and should stay that way: package
  code keeps base `Sys.Date()` / `Sys.time()` per the minimal-deps habit.
  The three call sites are R/paths.R:140 (`dated_path()`), R/document.R:254
  (`meeting()`), and R/project.R:111 (`new_project()`). The re-exports are
  user-facing sugar only.

## Testing notes

- Re-exports get no behavior tests of their own — house precedent is
  `clean_names` and `glue`, neither of which has one, and there is no
  test-reexports.R file to add to.
- If one is ever wanted: `expect_identical(today, lubridate::today)` and
  the same for `now`. Identity only; the behavior is lubridate's problem.

## Related

- **reexport-glue.md shipped** (see done/). `glue::glue` is in
  R/reexports.R and `glue` is in Imports, so the old "land all the
  re-exports in one PR" plan is moot — this one lands alone, and it is
  the only re-export left in the backlog.
- The house pattern it follows is documented in CLAUDE.md under
  "Re-export pattern".
