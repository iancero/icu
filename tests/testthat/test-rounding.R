# --- Correctness ------------------------------------------------------------

test_that("rounds to the nearest multiple of unit", {
  expect_equal(round_to_nearest(c(1.2, 3.7, 6.1), 0.5), c(1.0, 3.5, 6.0))
  expect_equal(round_to_nearest(137, 5), 135)
  expect_equal(round_to_nearest(c(-1.2, -3.8), 0.5), c(-1.0, -4.0))
  expect_equal(round_to_nearest(c(12, 15, 18), 10), c(10, 20, 20))
})

test_that("values already at a multiple are unchanged", {
  expect_equal(round_to_nearest(c(0, 2.5, -5), 0.5), c(0, 2.5, -5))
})

test_that("round_func swaps rounding direction", {
  expect_equal(round_to_nearest(137, 5, round_func = floor), 135)
  expect_equal(round_to_nearest(137, 5, round_func = ceiling), 140)
  expect_equal(round_to_nearest(-1.2, 1, round_func = floor), -2)
  expect_equal(round_to_nearest(-1.2, 1, round_func = ceiling), -1)
})

# --- Follows base round() contract ------------------------------------------

test_that("x is handled like base round()", {
  x <- c(1.26, -3.74, NA, NaN, Inf, -Inf)
  expect_equal(round_to_nearest(x, 1), round(x))
})

test_that("NA and NaN in x propagate", {
  expect_equal(round_to_nearest(c(1, NA, 3), 2), c(0, NA, 4))
  expect_equal(round_to_nearest(c(1, NaN), 0.5), c(1, NaN))
})

test_that("zero-length input returns zero-length output", {
  expect_equal(round_to_nearest(numeric(0), 5), numeric(0))
})

# --- Input validation -------------------------------------------------------

test_that("non-numeric x is rejected", {
  expect_error(round_to_nearest("5", 1), "x must be numeric")
  expect_error(round_to_nearest(TRUE, 1), "x must be numeric")
})

test_that("invalid unit is rejected", {
  expect_error(round_to_nearest(1, c(1, 5)), "unit must be length 1")
  expect_error(round_to_nearest(1, "a"),     "unit must be numeric")
  expect_error(round_to_nearest(1, NA),      "unit must be numeric")
  expect_error(round_to_nearest(1, NA_real_), "unit must be finite")
  expect_error(round_to_nearest(1, Inf),     "unit must be finite")
  expect_error(round_to_nearest(1, 0),       "unit must be greater than 0")
  expect_error(round_to_nearest(1, -2),      "unit must be greater than 0")
})
