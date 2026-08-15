# The stamp comes from the clock, so exact-string assertions are only safe for
# the date (recomputed here) and never for the time; time is pinned by regex.
#
# dated_path() cat()s the path to stdout by default. Everything outside the
# Printing section is about string assembly, so it passes print = FALSE to keep
# the suite's output readable. Printing cannot change the returned value -- that
# is pinned by "the announced path is the returned path" below -- so nothing is
# lost by silencing it here.

# --- Correctness ------------------------------------------------------------

test_that("the date is inserted before the extension", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  expect_identical(
    dated_path("output/figure_1a.png", print = FALSE),
    paste0("output/figure_1a_", today, ".png")
  )
})

test_that("hms appends a time after the date", {
  expect_match(
    dated_path("output/figure_1a.png", hms = TRUE, print = FALSE),
    "^output/figure_1a_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}\\.png$"
  )
})

test_that("ymd = FALSE gives a time-only stamp", {
  expect_match(
    dated_path("output/figure_1a.png", ymd = FALSE, hms = TRUE, print = FALSE),
    "^output/figure_1a_\\d{2}-\\d{2}-\\d{2}\\.png$"
  )
})

test_that("a manual version in the name is kept ahead of the date", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  expect_identical(
    dated_path("output/figure_1a_v3.png", print = FALSE),
    paste0("output/figure_1a_v3_", today, ".png")
  )
})

test_that("the directory portion of the path is untouched", {
  expect_match(dated_path("a/b/c/fig.png", print = FALSE), "^a/b/c/fig_")
  expect_match(dated_path("fig.png", print = FALSE),       "^fig_")
})

test_that("nothing is written to disk", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  dated_path(file.path(dir, "figure_1a.png"), hms = TRUE, print = FALSE)

  expect_length(list.files(dir), 0)
})

# --- Edge cases / special values --------------------------------------------

test_that("only the final component of a double extension is the extension", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  # Follows tools::file_ext(): the stamp lands before .gz, not before .tar
  expect_identical(
    dated_path("data.tar.gz", print = FALSE),
    paste0("data.tar_", today, ".gz")
  )
})

test_that("a name with no extension gets the stamp appended", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  expect_identical(
    dated_path("output/README", print = FALSE),
    paste0("output/README_", today)
  )
})

test_that("a leading-dot name is treated as having no extension", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  # tools::file_ext() returns "" here, so the name survives intact and the
  # stamp appends, rather than the whole name being read as an extension
  expect_identical(
    dated_path(".gitignore", print = FALSE),
    paste0(".gitignore_", today)
  )
})

test_that("extension case and spaces in the name are preserved", {
  expect_match(dated_path("FIG.PNG", print = FALSE),         "\\.PNG$")
  expect_match(dated_path("my figure 1.png", print = FALSE), "^my figure 1_")
})

test_that("the returned path contains no characters illegal in file names", {
  expect_no_match(
    dated_path("output/fig.png", hms = TRUE, print = FALSE),
    "[:*?\"<>|]"
  )
})

# --- Printing ---------------------------------------------------------------

test_that("the path is announced by default", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  expect_output(
    dated_path("output/figure_1a.png"),
    paste0("output/figure_1a_", today, ".png"),
    fixed = TRUE
  )
})

test_that("print = FALSE is silent", {
  expect_silent(dated_path("output/figure_1a.png", print = FALSE))
})

test_that("the announced path is the returned path", {
  announced <- capture.output(
    returned <- dated_path("output/figure_1a.png", hms = TRUE)
  )

  # One clean line, no [1] or quotes: cat(), not print()
  expect_identical(announced, returned)
})

test_that("the announcement goes to stdout, so knitr renders it", {
  # The whole point is that it lands in the rendered document. A message()
  # would too, but a .qmd that sets `message: false` to hide library() chatter
  # would silence this along with it, so it must not be a message.
  capture.output(expect_no_message(dated_path("a.png")))
})

test_that("the path is reported exactly once", {
  # Announced to stdout, so the return is invisible: a visible one would make a
  # bare call in a chunk render the same path twice
  capture.output(printed <- withVisible(dated_path("a.png")))
  expect_false(printed$visible)

  # Not announced, so the return is the report and must be visible
  quiet <- withVisible(dated_path("a.png", print = FALSE))
  expect_true(quiet$visible)

  # Either way the value itself is the same, and assignment is unaffected
  expect_identical(printed$value, quiet$value)
})

test_that("invisibility does not interfere with nesting or assignment", {
  capture.output({
    assigned <- dpp("output/figure_1a.png")
    nested   <- nchar(dpp("output/figure_1a.png"))
  })

  expect_identical(assigned, dp("output/figure_1a.png"))
  expect_identical(nested, nchar(dp("output/figure_1a.png")))
})

# --- Shorthands -------------------------------------------------------------

test_that("dp() is date only", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  expect_identical(
    dp("output/figure_1a.png"),
    paste0("output/figure_1a_", today, ".png")
  )
})

test_that("dtp() is date plus time", {
  expect_match(
    dtp("output/figure_1a.png"),
    "^output/figure_1a_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}\\.png$"
  )
})

test_that("dpp() and dtpp() agree with dp() and dtp() on the path itself", {
  today <- format(Sys.Date(), "%Y-%m-%d")

  capture.output({
    from_dpp  <- dpp("output/figure_1a.png")
    from_dtpp <- dtpp("output/figure_1a.png")
  })

  expect_identical(from_dpp, paste0("output/figure_1a_", today, ".png"))
  expect_match(
    from_dtpp,
    "^output/figure_1a_\\d{4}-\\d{2}-\\d{2}_\\d{2}-\\d{2}-\\d{2}\\.png$"
  )
})

test_that("the second p is the only thing that prints", {
  expect_silent(dp("output/figure_1a.png"))
  expect_silent(dtp("output/figure_1a.png"))
  expect_output(dpp("output/figure_1a.png"),  "output/figure_1a_")
  expect_output(dtpp("output/figure_1a.png"), "output/figure_1a_")
})

test_that("the shorthands take no further arguments", {
  # A shorthand you have to pass toggles to is not shorter; the contract is a
  # fixed one-argument signature, so these must not silently pass through
  expect_error(dp("a.png", hms = TRUE),      "unused argument")
  expect_error(dtp("a.png", hms = FALSE),    "unused argument")
  expect_error(dpp("a.png", print = FALSE),  "unused argument")
  expect_error(dtpp("a.png", print = FALSE), "unused argument")
})

test_that("validation still reaches the caller through the shorthands", {
  expect_error(dp(1),                    "file_name must be character")
  expect_error(dtp(c("a.png", "b.png")), "file_name must be length 1")
  expect_error(dpp(NA_character_),       "file_name must not be NA")
  expect_error(dtpp(""),                 "file_name must not be empty")
})

# --- Input validation -------------------------------------------------------

test_that("invalid file_name is rejected", {
  expect_error(dated_path(c("a.png", "b.png")), "file_name must be length 1")
  expect_error(dated_path(1),                   "file_name must be character")
  expect_error(dated_path(NA_character_),       "file_name must not be NA")
  expect_error(dated_path(""),                  "file_name must not be empty")
  expect_error(dated_path(character(0)),        "file_name must be length 1")
})

test_that("invalid ymd is rejected", {
  expect_error(dated_path("a.png", ymd = c(TRUE, TRUE)), "ymd must be length 1")
  expect_error(dated_path("a.png", ymd = "yes"),         "ymd must be TRUE or FALSE")
  expect_error(dated_path("a.png", ymd = NA),            "ymd must be TRUE or FALSE")
})

test_that("invalid hms is rejected", {
  expect_error(dated_path("a.png", hms = c(TRUE, TRUE)), "hms must be length 1")
  expect_error(dated_path("a.png", hms = "yes"),         "hms must be TRUE or FALSE")
  expect_error(dated_path("a.png", hms = NA),            "hms must be TRUE or FALSE")
})

test_that("invalid print is rejected", {
  expect_error(dated_path("a.png", print = c(TRUE, TRUE)), "print must be length 1")
  expect_error(dated_path("a.png", print = "yes"),         "print must be TRUE or FALSE")
  expect_error(dated_path("a.png", print = NA),            "print must be TRUE or FALSE")
})

test_that("stamping nothing is an error, not a passthrough", {
  expect_error(
    dated_path("a.png", ymd = FALSE, hms = FALSE),
    "at least one of ymd and hms must be TRUE"
  )
})
