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

# --- Filename grammar (parse_dated_filename) --------------------------------

# The grammar is {stem}[_vN]_{YYYY-MM-DD}[_HH-MM-SS].{ext}, shared by every icu
# function that reads or writes a dated file name. These tests are exhaustive
# on the grammar itself; the functions built on it (new_main() today, retire()
# later) test what they do with the parse, not the parse.

test_that("the full form parses into all five fields", {
  parsed <- parse_dated_filename("main_v3_2026-08-23_11-30-00.qmd")

  expect_identical(parsed$stem, "main")
  expect_identical(parsed$version, 3L)
  expect_identical(parsed$date, as.Date("2026-08-23"))
  expect_identical(parsed$time, "11-30-00")
  expect_identical(parsed$ext, "qmd")
  expect_true(parsed$parsed)
})

test_that("the version segment is optional", {
  parsed <- parse_dated_filename("figure_1a_2026-08-23.png")

  expect_identical(parsed$stem, "figure_1a")
  expect_identical(parsed$version, NA_integer_)
  expect_identical(parsed$date, as.Date("2026-08-23"))
  expect_identical(parsed$time, NA_character_)
  expect_true(parsed$parsed)
})

test_that("the time segment is optional", {
  parsed <- parse_dated_filename("main_v1_2026-08-23.qmd")

  expect_identical(parsed$version, 1L)
  expect_identical(parsed$time, NA_character_)
  expect_true(parsed$parsed)
})

test_that("a time with no version parses", {
  parsed <- parse_dated_filename("figure_1a_2026-08-23_11-30-00.png")

  expect_identical(parsed$stem, "figure_1a")
  expect_identical(parsed$version, NA_integer_)
  expect_identical(parsed$time, "11-30-00")
})

test_that("the version is read as a number, not a string", {
  parsed <- parse_dated_filename(
    c("main_v2_2026-08-23.qmd", "main_v10_2026-08-23.qmd")
  )

  # v10 must outrank v2, which it does numerically and does not alphabetically
  expect_identical(parsed$version, c(2L, 10L))
  expect_gt(max(parsed$version), 2L)
})

test_that("an underscore-heavy stem survives intact", {
  parsed <- parse_dated_filename("smith_delirium_table_2_2026-08-23.docx")

  expect_identical(parsed$stem, "smith_delirium_table_2")
  expect_identical(parsed$ext, "docx")
})

test_that("a lone v in the stem is not read as a version", {
  parsed <- parse_dated_filename("v3_2026-08-23.png")

  # No underscore before it, so it is part of the stem
  expect_identical(parsed$stem, "v3")
  expect_identical(parsed$version, NA_integer_)
})

test_that("the directory portion is ignored, and reported back as given", {
  parsed <- parse_dated_filename("output/old/figure_1a_2026-08-23.png")

  expect_identical(parsed$stem, "figure_1a")
  expect_identical(parsed$file_name, "output/old/figure_1a_2026-08-23.png")
})

test_that("parsing is vectorized and order-preserving", {
  parsed <- parse_dated_filename(
    c("main_v1_2026-08-21.qmd", "nonsense.txt", "figure_1a_2026-08-23.png")
  )

  expect_identical(nrow(parsed), 3L)
  expect_identical(parsed$parsed, c(TRUE, FALSE, TRUE))
  expect_identical(parsed$stem, c("main", NA, "figure_1a"))
})

test_that("an empty vector gives an empty result, not an error", {
  parsed <- parse_dated_filename(character(0))

  expect_identical(nrow(parsed), 0L)
  expect_identical(parsed$version, integer(0))
})

# --- Grammar: non-participation ---------------------------------------------

test_that("a near-miss date is left unparsed rather than reinterpreted", {
  # The motivating real-world case: an underscore where a hyphen belongs
  parsed <- parse_dated_filename("figure_1a_2026_08-22.png")

  expect_false(parsed$parsed)
  expect_identical(parsed$stem, NA_character_)
  expect_identical(parsed$date, as.Date(NA))
})

test_that("undated names do not participate", {
  parsed <- parse_dated_filename(c("main.qmd", "main_v1.qmd", "README"))

  expect_identical(parsed$parsed, c(FALSE, FALSE, FALSE))
})

test_that("a name with no extension does not participate", {
  # Just as likely to be a directory as a file
  parsed <- parse_dated_filename("main_v1_2026-08-23")

  expect_false(parsed$parsed)
})

test_that("a date that matches the shape but names no real day is rejected", {
  parsed <- parse_dated_filename(
    c("main_2026-02-30.qmd", "main_2026-13-01.qmd")
  )

  expect_identical(parsed$parsed, c(FALSE, FALSE))
})

test_that("a time that matches the shape but names no real time is rejected", {
  parsed <- parse_dated_filename("main_2026-08-23_25-00-00.qmd")

  expect_false(parsed$parsed)
})

test_that("a truncated or overlong stamp does not participate", {
  parsed <- parse_dated_filename(
    c("main_26-08-23.qmd", "main_2026-08-23_11-30.qmd", "_2026-08-23.qmd")
  )

  expect_identical(parsed$parsed, c(FALSE, FALSE, FALSE))
})

test_that("dated_path() output parses back under the grammar", {
  # The writer and the reader must agree, in both stamp modes
  round_trip <- parse_dated_filename(
    c(
      dated_path("output/figure_1a.png", print = FALSE),
      dated_path("output/main_v2.qmd", hms = TRUE, print = FALSE)
    )
  )

  expect_identical(round_trip$parsed, c(TRUE, TRUE))
  expect_identical(round_trip$stem, c("figure_1a", "main"))
  expect_identical(round_trip$version, c(NA_integer_, 2L))
  expect_identical(round_trip$date, rep(Sys.Date(), 2))
  expect_identical(is.na(round_trip$time), c(TRUE, FALSE))
})

# --- Grammar: input validation ----------------------------------------------

test_that("a non-character file_name is rejected", {
  expect_error(parse_dated_filename(1), "file_name must be character")
})


# --- retire(): how these tests are set up -----------------------------------

# retire() moves files, so every test below works in its own temp directory.
#
# It also cat()s its plan. Tests that are not about the printing wrap the call
# in quietly() to keep the suite readable; the two that are about it use
# expect_output() instead.
#
# Dates here are fixed rather than taken from the clock: retire() reads them
# out of file names and never asks what today is.

local_swept_dir <- function(files = character(), dirs = character(),
                            env = parent.frame()) {
  dir <- tempfile()
  dir.create(dir)

  withr::defer(unlink(dir, recursive = TRUE), envir = env)

  if (length(files) > 0) {
    file.create(file.path(dir, files))
  }

  for (d in dirs) {
    dir.create(file.path(dir, d))
  }

  dir
}

quietly <- function(expr) {
  capture.output(value <- expr)
  value
}

# The motivating example from the design file, plus the three cases the
# ordering rule turns on: a version that disagrees with its date, a versioned
# file beside an unversioned one, and a timed name beside a timeless one.
swept_files <- c(
  "main_v1_2026-08-21.qmd",
  "main_v2_2026-08-23.qmd",
  "main_v3_2026-08-22.qmd",
  "figure_1a_v2_2026-08-23.png",
  "figure_1a_2026-08-24.png",
  "figure_1b_2026-08-23.png",
  "figure_1b_2026-08-23_14-30-00.png",
  "figure_1a_2026_08-22.png",
  "notes.txt"
)

survivors <- function(plan) {
  sort(basename(plan$path[plan$action == "keep"]))
}

# --- retire(): grouping and ordering ----------------------------------------

test_that("one file of each group survives, and it is the newest", {
  dir  <- local_swept_dir(swept_files)
  plan <- quietly(retire(dir))

  expect_identical(
    survivors(plan),
    sort(c(
      "main_v3_2026-08-22.qmd",
      "figure_1a_v2_2026-08-23.png",
      "figure_1b_2026-08-23_14-30-00.png"
    ))
  )
})

test_that("version outranks date", {
  dir  <- local_swept_dir(c("main_v3_2026-08-22.qmd", "main_v2_2026-08-23.qmd"))
  plan <- quietly(retire(dir))

  # Date-first was the rejected rule, and would keep v2 here
  expect_identical(survivors(plan), "main_v3_2026-08-22.qmd")
})

test_that("a versioned file outranks an unversioned one, whatever the dates", {
  dir <- local_swept_dir(c(
    "figure_1a_v2_2026-08-23.png",
    "figure_1a_2026-08-24.png"
  ))
  plan <- quietly(retire(dir))

  # Grouping is (stem, ext) and nothing else, so these compete -- and the
  # unversioned file loses despite being a day newer
  expect_identical(survivors(plan), "figure_1a_v2_2026-08-23.png")
})

test_that("a missing time segment sorts older than a present one", {
  dir <- local_swept_dir(c(
    "figure_1b_2026-08-23.png",
    "figure_1b_2026-08-23_14-30-00.png"
  ))
  plan <- quietly(retire(dir))

  expect_identical(survivors(plan), "figure_1b_2026-08-23_14-30-00.png")
})

test_that("the same stem with different extensions makes separate groups", {
  dir <- local_swept_dir(c(
    "main_v1_2026-08-21.qmd",
    "main_v2_2026-08-22.qmd",
    "main_v1_2026-08-21.html"
  ))
  plan <- quietly(retire(dir))

  expect_identical(
    survivors(plan),
    sort(c("main_v2_2026-08-22.qmd", "main_v1_2026-08-21.html"))
  )
})

test_that("a group of one is kept, not retired", {
  dir  <- local_swept_dir("main_v1_2026-08-21.qmd")
  plan <- quietly(retire(dir))

  expect_identical(plan$action, "keep")
})

# --- retire(): moving -------------------------------------------------------

test_that("a real run moves the retired files and leaves the rest", {
  dir <- local_swept_dir(swept_files)

  quietly(retire(dir, dry_run = FALSE))

  expect_identical(
    sort(list.files(file.path(dir, "old"))),
    sort(c(
      "main_v1_2026-08-21.qmd",
      "main_v2_2026-08-23.qmd",
      "figure_1a_2026-08-24.png",
      "figure_1b_2026-08-23.png"
    ))
  )
  expect_true(file.exists(file.path(dir, "main_v3_2026-08-22.qmd")))
})

test_that("a dry run touches nothing, and creates no old/", {
  dir    <- local_swept_dir(swept_files)
  before <- sort(list.files(dir))

  quietly(retire(dir))

  expect_identical(sort(list.files(dir)), before)
  expect_false(dir.exists(file.path(dir, "old")))
})

test_that("a second run is a no-op", {
  dir <- local_swept_dir(swept_files)

  quietly(retire(dir, dry_run = FALSE))
  after_first <- sort(list.files(dir, recursive = TRUE))

  quietly(retire(dir, dry_run = FALSE))

  expect_identical(sort(list.files(dir, recursive = TRUE)), after_first)
})

test_that("a real run reports what it moved", {
  dir <- local_swept_dir(swept_files)

  expect_output(retire(dir, dry_run = FALSE), "retired 4 files to")
})

test_that("the count in the closing line is singular when it should be", {
  dir <- local_swept_dir(c("main_v1_2026-08-21.qmd", "main_v2_2026-08-22.qmd"))

  # Reads as prose or it does not get read at all
  expect_output(retire(dir, dry_run = FALSE), "retired 1 file to")
})

test_that("nothing to retire says so, and creates no old/", {
  dir <- local_swept_dir("main_v1_2026-08-21.qmd")

  expect_output(retire(dir, dry_run = FALSE), "nothing to retire in")
  expect_false(dir.exists(file.path(dir, "old")))
})

# --- retire(): never overwriting --------------------------------------------

test_that("a name already taken in old/ is skipped, not clobbered", {
  dir <- local_swept_dir(swept_files, dirs = "old")
  file.create(file.path(dir, "old", "main_v1_2026-08-21.qmd"))

  expect_warning(
    quietly(retire(dir, dry_run = FALSE)),
    "skipped: main_v1_2026-08-21[.]qmd"
  )

  expect_true(file.exists(file.path(dir, "main_v1_2026-08-21.qmd")))
})

test_that("a collision does not stop the rest of the sweep", {
  dir <- local_swept_dir(swept_files, dirs = "old")
  file.create(file.path(dir, "old", "main_v1_2026-08-21.qmd"))

  suppressWarnings(quietly(retire(dir, dry_run = FALSE)))

  # Everything except the collided file still moved
  expect_true(file.exists(file.path(dir, "old", "main_v2_2026-08-23.qmd")))
  expect_true(file.exists(file.path(dir, "old", "figure_1a_2026-08-24.png")))
})

test_that("a collision shows on the dry run, before anything moves", {
  dir <- local_swept_dir(swept_files, dirs = "old")
  file.create(file.path(dir, "old", "main_v1_2026-08-21.qmd"))

  plan <- suppressWarnings(quietly(retire(dir)))

  expect_identical(
    basename(plan$path[plan$action == "skipped"]),
    "main_v1_2026-08-21.qmd"
  )
})

# --- retire(): non-participation --------------------------------------------

test_that("a near-miss name is left alone and reported as ignored", {
  dir <- local_swept_dir(swept_files)

  plan <- quietly(retire(dir, dry_run = FALSE))

  # An underscore in the date: strict matching means it is never reinterpreted
  expect_true(file.exists(file.path(dir, "figure_1a_2026_08-22.png")))
  expect_identical(
    plan$action[basename(plan$path) == "figure_1a_2026_08-22.png"],
    "ignored"
  )
})

test_that("an undated file never participates", {
  dir  <- local_swept_dir(swept_files)
  plan <- quietly(retire(dir, dry_run = FALSE))

  expect_true(file.exists(file.path(dir, "notes.txt")))
  expect_identical(
    plan$action[basename(plan$path) == "notes.txt"],
    "ignored"
  )
})

test_that("a directory named like a dated file is never moved", {
  dir <- local_swept_dir(
    c("analysis_v1_2026-08-21.qmd", "analysis_v2_2026-08-22.qmd"),
    dirs = "analysis_2026-08-23.old"
  )

  plan <- quietly(retire(dir, dry_run = FALSE))

  expect_true(dir.exists(file.path(dir, "analysis_2026-08-23.old")))
  expect_identical(
    plan$action[basename(plan$path) == "analysis_2026-08-23.old"],
    "ignored"
  )
})

test_that("old/ does not sweep itself", {
  dir <- local_swept_dir(swept_files)

  quietly(retire(dir, dry_run = FALSE))
  quietly(retire(dir, dry_run = FALSE))

  expect_false(dir.exists(file.path(dir, "old", "old")))
})

# --- retire(): the plan -----------------------------------------------------

test_that("the plan accounts for every entry in the directory, exactly once", {
  dir  <- local_swept_dir(swept_files, dirs = "analysis_2026-08-23.old")
  plan <- quietly(retire(dir))

  expect_identical(sort(basename(plan$path)), sort(list.files(dir)))
})

test_that("the plan is returned invisibly", {
  dir <- local_swept_dir(swept_files)

  capture.output(returned <- withVisible(retire(dir)))

  expect_false(returned$visible)
  expect_s3_class(returned$value, "data.frame")
})

test_that("the plan carries the fields it sorted on", {
  dir  <- local_swept_dir(swept_files)
  plan <- quietly(retire(dir))

  row <- plan[basename(plan$path) == "figure_1b_2026-08-23_14-30-00.png", ]

  expect_identical(row$stem, "figure_1b")
  expect_identical(row$ext, "png")
  expect_identical(row$date, as.Date("2026-08-23"))
  expect_identical(row$time, "14-30-00")
  expect_true(is.na(row$version))
})

test_that("an ignored row carries no parsed fields", {
  dir  <- local_swept_dir(swept_files)
  plan <- quietly(retire(dir))

  row <- plan[basename(plan$path) == "notes.txt", ]

  # Nothing was weighed, so nothing is reported as having been weighed
  expect_true(is.na(row$stem))
  expect_true(is.na(row$ext))
  expect_true(is.na(row$date))
})

test_that("destination is filled on retire rows and nowhere else", {
  dir  <- local_swept_dir(swept_files)
  plan <- quietly(retire(dir))

  expect_false(any(is.na(plan$destination[plan$action == "retire"])))
  expect_true(all(is.na(plan$destination[plan$action != "retire"])))
})

test_that("an empty directory gives an empty plan, not an error", {
  dir <- local_swept_dir()

  plan <- quietly(retire(dir))

  expect_identical(nrow(plan), 0L)
})

# --- retire(): input validation ---------------------------------------------

test_that("invalid path is rejected", {
  expect_error(retire(c(".", ".")), "path must be length 1")
  expect_error(retire(1), "path must be character")
  expect_error(retire(NA_character_), "path must not be NA")
  expect_error(
    retire(file.path(tempdir(), "no-such-directory")),
    "path must be an existing directory"
  )
})

test_that("invalid dry_run is rejected", {
  dir <- local_swept_dir(swept_files)

  expect_error(retire(dir, dry_run = c(TRUE, TRUE)), "dry_run must be length 1")
  expect_error(retire(dir, dry_run = "yes"), "dry_run must be TRUE or FALSE")
  expect_error(retire(dir, dry_run = NA), "dry_run must be TRUE or FALSE")
})

test_that("nothing is moved when validation fails", {
  dir <- local_swept_dir(swept_files)

  expect_error(retire(dir, dry_run = "yes"))

  expect_identical(sort(list.files(dir)), sort(swept_files))
  expect_false(dir.exists(file.path(dir, "old")))
})
