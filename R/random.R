#' Draw from a Bernoulli distribution
#'
#' Generates random 0/1 draws, i.e. a single Bernoulli trial per draw.
#' A convenience wrapper around [rbinom()] with `size = 1`.
#'
#' @param n A single non-negative whole number: the number of draws.
#' @param prob Probability of success (a 1). Either a single value applied
#'   to all draws, or a vector of length `n` giving a per-draw probability.
#'   Other lengths are an error: unlike base R's `r*` functions, no partial
#'   recycling is done. `NA` values are an error.
#'
#' @details
#' Returns integer `0`/`1`, not logical `TRUE`/`FALSE` (as the now-deprecated
#' `purrr::rbernoulli()` did). Use `as.logical()` on the result if needed.
#'
#' Unlike [rbinom()], which produces `NA` draws with a warning when `prob`
#' contains `NA`, this function errors: an `NA` probability in a simulation
#' usually indicates an upstream problem.
#'
#' @return An integer vector of length `n` containing `0`s and `1`s.
#'
#' @examples
#' rbernoulli(10, 0.5)
#'
#' # Per-draw probabilities, e.g. subject-specific from a logistic model
#' rbernoulli(3, prob = c(0.1, 0.5, 0.9))
#'
#' # Simulating a binary outcome for a dataset
#' n <- 20
#' age <- rnorm(n, mean = 60, sd = 10)
#' p <- plogis(-4 + 0.06 * age)
#' outcome <- rbernoulli(n, p)
#'
#' @export
rbernoulli <- function(n, prob) {

  stopifnot(
    'n must be length 1'                = length(n) == 1,
    'n must be a non-negative number'   = is.numeric(n) && is.finite(n) && n >= 0,
    'n must be a whole number'          = is.numeric(n) && n == trunc(n),
    'prob must be numeric'              = is.numeric(prob),
    'prob must be length 1 or length n' = length(prob) == 1 || length(prob) == n,
    'prob must not contain NA'          = !anyNA(prob),
    'prob must be between 0 and 1'      = all(prob >= 0 & prob <= 1)
  )

  rbinom(n = n, size = 1, prob = prob)
}
