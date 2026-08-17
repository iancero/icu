# round_cols(): default digits = 3

**Status:** shipped — both defaults live in R/rounding.R
**File:** R/rounding.R (existing), tests/testthat/test-rounding.R

## Change

Give `round_cols(df, digits, min = 0)` a default of `digits = 3`.

Shipped in commit 377fb51 ("Default round_cols digits to 3"). The signature
is now `round_cols(df, digits = 3, min = 0)`.

## Design notes

- **`digits = 3`** — the consulting default. Manuscript tables are reported
  at 3 decimal places, so the common call is the bare `round_cols(df)`.
- **`min` stays at `0`** (decided; previously listed as an open question).
  `min = 0` is plain rounding, which is the right *default* because the
  minimum applies to **every** numeric column at once — a nonzero default
  would silently clamp counts, differences, and other columns with
  meaningful zeros, and emit a warning per such column. `min` is a
  p-value-shaped concern, not a whole-table one, so it should be opted into
  per call (`round_cols(df, min = 0.001)`), not inherited. Rejected
  alternative: defaulting to `min = 0.001` to match the p-value motivating
  case — it makes the safe call the verbose one and turns a table-wide
  clamp into the path of least resistance.
- Note the asymmetry with `round_with_min()`, which takes `min` as a
  **required** argument with no default. That is deliberate: calling
  `round_with_min()` at all means you want a minimum, so there is no
  sensible default to fall back to; `round_cols()` is the table-wide
  convenience wrapper, where plain rounding is the common case.

## Cautions (resolved)

- Changing the contract of an already-exported function: no test asserted
  error-on-missing-`digits`, so nothing broke. `round_cols(df)` is now
  pinned at tests/testthat/test-rounding.R:155.
- Roxygen docs and examples show both defaults; `man/round_cols.Rd` is
  regenerated.
