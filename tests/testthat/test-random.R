# --- Correctness ------------------------------------------------------------

test_that("returns n integer draws of 0 or 1", {
  x <- rbernoulli(100, 0.5)
  expect_length(x, 100)
  expect_type(x, "integer")
  expect_true(all(x %in% c(0L, 1L)))
})

test_that("degenerate probabilities are deterministic", {
  expect_equal(rbernoulli(10, 0), rep(0L, 10))
  expect_equal(rbernoulli(10, 1), rep(1L, 10))
})

test_that("per-draw probabilities are applied element-wise", {
  x <- rbernoulli(4, prob = c(0, 1, 0, 1))
  expect_equal(x, c(0L, 1L, 0L, 1L))
})

test_that("results are reproducible under set.seed", {
  set.seed(42)
  a <- rbernoulli(20, 0.3)
  set.seed(42)
  b <- rbernoulli(20, 0.3)
  expect_identical(a, b)
})

# --- Edge cases -------------------------------------------------------------

test_that("n = 0 returns a zero-length integer vector", {
  expect_identical(rbernoulli(0, 0.5), integer(0))
})

test_that("integer-typed n works", {
  expect_length(rbernoulli(5L, 0.5), 5)
})

# --- Input validation -------------------------------------------------------

test_that("invalid n is rejected", {
  expect_error(rbernoulli(c(5, 10), 0.5), "n must be length 1")
  expect_error(rbernoulli("5", 0.5),      "n must be a non-negative number")
  expect_error(rbernoulli(-1, 0.5),       "n must be a non-negative number")
  expect_error(rbernoulli(Inf, 0.5),      "n must be a non-negative number")
  expect_error(rbernoulli(5.7, 0.5),      "n must be a whole number")
})

test_that("invalid prob is rejected", {
  expect_error(rbernoulli(5, "0.5"),        "prob must be numeric")
  expect_error(rbernoulli(5, c(0.2, 0.8)),  "prob must be length 1 or length n")
  expect_error(rbernoulli(5, 1.5),          "prob must be between 0 and 1")
  expect_error(rbernoulli(5, -0.1),         "prob must be between 0 and 1")
})

test_that("NA in prob is rejected", {
  expect_error(rbernoulli(3, prob = c(0.5, NA, 0.5)), "prob must not contain NA")
  expect_error(rbernoulli(5, NA_real_), "prob must not contain NA")
})

test_that("prob is not partially recycled", {
  # length 2 into n = 6 would recycle cleanly in base rbinom; here it errors
  expect_error(rbernoulli(6, c(0.1, 0.9)), "prob must be length 1 or length n")
})
