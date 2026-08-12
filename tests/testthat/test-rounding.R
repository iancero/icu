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


# --- round_with_min: correctness --------------------------------------------

test_that("rounds normally when min does not bind", {
  expect_equal(round_with_min(0.032, 3, 0.001), 0.032)
  expect_equal(round_with_min(c(0.25, 1.5, 10), 1, 0.1), c(0.2, 1.5, 10))
})

test_that("values below min are clamped to min", {
  expect_equal(round_with_min(0.00001, 3, 0.001), 0.001)
  expect_equal(round_with_min(0.0004, 3, 0.001), 0.001)  # rounds to 0, rescued
  expect_equal(round_with_min(0.004, 3, 0.01), 0.01)     # rounds nonzero, still below min
})

test_that("values that round to exactly min are untouched", {
  expect_equal(round_with_min(0.0012, 3, 0.001), 0.001)
})

test_that("negative values are clamped symmetrically", {
  expect_equal(round_with_min(-0.00001, 3, 0.001), -0.001)
  expect_equal(round_with_min(-0.032, 3, 0.001), -0.032)
})

test_that("sign comes from the original value, not the rounded one", {
  # -0.0004 rounds to 0 (sign lost); original sign must be rescued
  expect_equal(round_with_min(-0.0004, 3, 0.001), -0.001)
})

test_that("mixed vectors clamp element-wise", {
  x <- c(0.5, 0.00002, -0.00002, 0.032)
  expect_equal(round_with_min(x, 3, 0.001), c(0.5, 0.001, -0.001, 0.032))
})

test_that("min = 0 is equivalent to plain round()", {
  x <- c(0.0004, -0.0004, 0, 0.032, NA, Inf)
  expect_no_warning(out <- round_with_min(x, 3, min = 0))
  expect_equal(out, round(x, 3))
})

# --- round_with_min: zeros and special values -------------------------------

test_that("exact zeros become min with a warning", {
  expect_warning(out <- round_with_min(0, 3, 0.001), "exact zeros")
  expect_equal(out, 0.001)
})

test_that("zero warning fires once for multiple zeros", {
  expect_warning(out <- round_with_min(c(0, 1, 0), 2, 0.01), "exact zeros")
  expect_equal(out, c(0.01, 1, 0.01))
})

test_that("zero warning is suppressable", {
  expect_no_warning(out <- suppressWarnings(round_with_min(0, 3, 0.001)))
  expect_equal(out, 0.001)
})

test_that("NA, NaN, and Inf pass through", {
  expect_equal(round_with_min(c(NA, NaN, Inf, -Inf), 3, 0.001),
               c(NA, NaN, Inf, -Inf))
})

test_that("zero-length input returns zero-length output", {
  expect_equal(round_with_min(numeric(0), 3, 0.001), numeric(0))
})

# --- round_with_min: input validation ---------------------------------------

test_that("invalid x is rejected", {
  expect_error(round_with_min("5", 3, 0.001), "x must be numeric")
})

test_that("invalid digits is rejected", {
  expect_error(round_with_min(1, c(2, 3), 0.001), "digits must be length 1")
  expect_error(round_with_min(1, 2.5, 0.001),     "digits must be a whole number")
  expect_error(round_with_min(1, "3", 0.001),     "digits must be a whole number")
})

test_that("invalid min is rejected", {
  expect_error(round_with_min(1, 3, c(0.001, 0.01)), "min must be length 1")
  expect_error(round_with_min(1, 3, "0.001"),        "min must be numeric")
  expect_error(round_with_min(1, 3, NA_real_),       "min must be finite")
  expect_error(round_with_min(1, 3, Inf),            "min must be finite")
  expect_error(round_with_min(1, 3, -0.001),         "min must be non-negative")
})



test_that("rounds numeric columns, leaves others untouched", {
  df <- data.frame(
    term = c("a", "b"),
    est  = c(1.23456, 2.34567),
    flag = c(TRUE, FALSE)
  )
  out <- round_cols(df, digits = 2)
  expect_equal(out$est, c(1.23, 2.35))
  expect_identical(out$term, df$term)
  expect_identical(out$flag, df$flag)  # logical is not numeric; untouched
})

test_that("min is applied to numeric columns", {
  df <- data.frame(p = c(0.00001, 0.04321), est = c(5.5555, -0.0002))
  out <- round_cols(df, digits = 3, min = 0.001)
  expect_equal(out$p, c(0.001, 0.043))
  expect_equal(out$est, c(5.556, -0.001))  # symmetric min, sign preserved
})

test_that("default min = 0 is plain rounding", {
  df <- data.frame(x = c(0.0004, 0))
  expect_no_warning(out <- round_cols(df, digits = 3))
  expect_equal(out$x, c(0, 0))
})

test_that("zeros with min > 0 warn", {
  df <- data.frame(a = c(0, 1), b = c(2, 0))
  expect_warning(out <- round_cols(df, 2, min = 0.01), "exact zeros")
  expect_equal(out$a, c(0.01, 1))
  expect_equal(out$b, c(2, 0.01))
})

test_that("data frame with no numeric columns passes through", {
  df <- data.frame(a = c("x", "y"), b = factor(c("u", "v")))
  expect_identical(round_cols(df, 3), df)
})

test_that("tibbles stay tibbles and grouping is preserved", {
  skip_if_not_installed("tibble")
  tb <- dplyr::group_by(tibble::tibble(g = c("a", "b"), x = c(1.234, 5.678)), g)
  out <- round_cols(tb, 1)
  expect_s3_class(out, "tbl_df")
  expect_identical(dplyr::group_vars(out), "g")
  expect_equal(out$x, c(1.2, 5.7))
})

test_that("NA in data propagates", {
  df <- data.frame(x = c(1.234, NA))
  expect_equal(round_cols(df, 1)$x, c(1.2, NA))
})

test_that("invalid inputs are rejected", {
  df <- data.frame(x = 1.5)
  expect_error(round_cols("not a df", 3),  "df must be a data frame")
  expect_error(round_cols(df, c(1, 2)),    "digits must be length 1")
  expect_error(round_cols(df, 2.5),        "digits must be a whole number")
  expect_error(round_cols(df, 3, min = -1),        "min must be non-negative")
  expect_error(round_cols(df, 3, min = c(.1, .2)), "min must be length 1")
})
