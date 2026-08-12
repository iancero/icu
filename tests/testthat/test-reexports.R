test_that("clean_names is re-exported from janitor", {
  df <- data.frame("A Column" = 1, check.names = FALSE)
  expect_equal(names(clean_names(df)), "a_column")
})
