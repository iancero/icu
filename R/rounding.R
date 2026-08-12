#' Round to the nearest multiple of a unit
#'
#' Rounds values to the nearest multiple of `unit`, e.g. to the nearest
#' 0.5, 5, or 100. The rounding function can be swapped out to round
#' up or down instead.
#'
#' @param x A numeric vector to round.
#' @param unit A single positive, finite number: the multiple to round to.
#' @param round_func The rounding function to apply. Defaults to [round()];
#'   [floor()] or [ceiling()] give "always down" / "always up" behavior.
#'
#' @details
#' With the default `round_func`, halfway cases follow base [round()]'s
#' round-half-to-even ("banker's rounding") behavior, so
#' `round_to_nearest(0.25, 0.1)` returns 0.2, not 0.3.
#'
#' `NA`, `NaN`, and `Inf` are handled the same way as in [round()]:
#' they propagate through unchanged.
#'
#' @return A numeric vector the same length as `x`, rounded to multiples
#'   of `unit`.
#'
#' @examples
#' round_to_nearest(c(1.2, 3.7, 6.1), 0.5)
#' round_to_nearest(137, 5)
#' round_to_nearest(137, 5, round_func = floor)
#' round_to_nearest(c(2.3, NA, 8.9), 0.5)  # NA propagates
#'
#' @export
round_to_nearest <- function(x, unit, round_func = round) {

  stopifnot(
    'x must be numeric'           = is.numeric(x),
    'unit must be length 1'       = length(unit) == 1,
    'unit must be numeric'        = is.numeric(unit),
    'unit must be finite'         = is.finite(unit),
    'unit must be greater than 0' = unit > 0
  )

  round_func(x / unit) * unit
}


#' Round with a minimum magnitude
#'
#' Rounds like [round()], but values whose rounded magnitude would fall
#' below `min` are clamped to `min` instead (keeping their sign). The
#' motivating case is p-values: with `digits = 3` and `min = 0.001`, a
#' p-value of 0.00001 returns 0.001 rather than 0.
#'
#' @param x A numeric vector to round.
#' @param digits A single whole number: decimal places to round to,
#'   passed to [round()].
#' @param min A single non-negative, finite number: the smallest magnitude
#'   the result may have. Applies symmetrically to negative values,
#'   using the sign of the original (pre-rounding) value. `min = 0`
#'   disables the minimum entirely, making the function equivalent
#'   to [round()].
#'
#' @details
#' Exact zeros in `x` are set to `min`, with a warning (suppressable via
#' [suppressWarnings()]). If your data contains meaningful zeros, this
#' function is probably not what you want. (With `min = 0`, zeros are
#' left alone and no warning is issued.)
#'
#' The clamp applies to any value whose rounded magnitude is below `min`,
#' not only values that round to zero: `round_with_min(0.004, 3, 0.01)`
#' returns 0.01.
#'
#' `NA` and `NaN` propagate unchanged; `Inf` and `-Inf` pass through
#' untouched.
#'
#' Note that the numeric result 0.001 overstates a p-value of 0.00001;
#' for manuscript tables the string `"<0.001"` is usually the right
#' presentation. This function is for numeric pipelines, not display.
#'
#' @return A numeric vector the same length as `x`.
#'
#' @examples
#' round_with_min(c(0.032, 0.00001), digits = 3, min = 0.001)
#' round_with_min(-0.0004, digits = 3, min = 0.001)  # sign preserved
#'
#' @export
round_with_min <- function(x, digits, min) {

  stopifnot(
    'x must be numeric'             = is.numeric(x),
    'digits must be length 1'       = length(digits) == 1,
    'digits must be a whole number' = is.numeric(digits) && is.finite(digits) && digits == trunc(digits),
    'min must be length 1'          = length(min) == 1,
    'min must be numeric'           = is.numeric(min),
    'min must be finite'            = is.finite(min),
    'min must be non-negative'      = min >= 0
  )

  out <- round(x, digits)

  # Nonzero values whose rounded magnitude falls below min:
  # clamp to min, keeping the sign of the *original* value
  clamp <- !is.na(x) & is.finite(x) & x != 0 & abs(out) < min
  out[clamp] <- sign(x[clamp]) * min

  # Exact zeros become min, with a warning (unless min = 0: nothing to do)
  zeros <- !is.na(x) & x == 0
  if (min > 0 && any(zeros)) {
    warning('x contains exact zeros; these were set to min')
    out[zeros] <- min
  }

  out
}


#' Round the numeric columns of a data frame
#'
#' Applies [round_with_min()] to every numeric column of a data frame,
#' leaving all other columns untouched. A convenience for making model
#' output and summary tables readable at a glance.
#'
#' @param df A data frame (or tibble).
#' @param digits A single whole number: decimal places to round to.
#'   Defaults to 3.
#' @param min A single non-negative, finite number: the smallest magnitude
#'   any rounded value may have (see [round_with_min()]). The default
#'   `min = 0` means plain rounding.
#'
#' @details
#' With `min > 0`, the minimum applies to *every* numeric column, and any
#' column containing exact zeros will have them set to `min`, with one
#' warning per such column. If some columns have meaningful zeros (counts,
#' differences), round those separately rather than raising `min` here.
#'
#' Integer columns are numeric and so are processed; if `min` binds on
#' one, the affected column is converted to double.
#'
#' @return The data frame with numeric columns rounded, otherwise
#'   unchanged (same class, same column order).
#'
#' @examples
#' df <- data.frame(
#'   term = c("age", "sex"),
#'   estimate = c(1.23456, -0.98765),
#'   p_value = c(0.00001, 0.04321)
#' )
#' round_cols(df, digits = 3)
#' round_cols(df, digits = 3, min = 0.001)
#'
#' @export
round_cols <- function(df, digits = 3, min = 0) {

  stopifnot(
    'df must be a data frame'       = is.data.frame(df),
    'digits must be length 1'       = length(digits) == 1,
    'digits must be a whole number' = is.numeric(digits) && is.finite(digits) && digits == trunc(digits),
    'min must be length 1'          = length(min) == 1,
    'min must be numeric'           = is.numeric(min),
    'min must be finite'            = is.finite(min),
    'min must be non-negative'      = min >= 0
  )

  df |>
    dplyr::mutate(
      dplyr::across(
        tidyselect::where(is.numeric),
        .fns = ~ round_with_min(.x, digits = digits, min = min)
    )
  )
}
