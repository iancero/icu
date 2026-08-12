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
