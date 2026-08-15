# round_cols(): default digits = 3

**Status:** small, but touches existing exported function — check tests first
**File:** R/rounding.R (existing), tests/testthat/test-rounding.R

## Change

Give `round_cols(df, digits, min = 0)` a default of `digits = 3`.

## Cautions

- This changes the contract of an already-exported function (currently
  `digits` is required). Scan existing tests for any that assert the
  no-default / error-on-missing-digits behavior; update alongside.
- While in there, decide whether `min` should get a reconsidered default too,
  or stay at `0` (identity / plain round).
- Update roxygen docs + examples to show the default in the consulting use
  case (manuscript tables at 3 digits).
