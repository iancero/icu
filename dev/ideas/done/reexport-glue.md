# Re-export glue::glue

**Status:** ready — no design discussion needed
**Proposed file:** R/reexports.R (existing)

## Motivation

`glue()` is used constantly in consulting scripts; re-export fits the
package's "prefer re-exports over thin wrappers" rule (same as
`janitor::clean_names`).

## Steps

1. `usethis::use_package("glue")` (not currently in Imports).
2. Add to R/reexports.R:

   ```r
   #' @importFrom glue glue
   #' @export
   glue::glue
   ```

3. `devtools::document()` — lands in shared man/reexports.Rd.

## Related

- The dated-path helper may use `glue::glue()` internally; if so, do both in
  one PR so the Imports change lands once.
