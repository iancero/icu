# conventions_md() writes a file, so every test works in its own temp
# directory. It also announces the path it wrote, in dated_path()'s posture,
# so most tests wrap the call in capture.output() to keep the suite's output
# readable -- the announcement itself is pinned in its own section below.

# --- Correctness ------------------------------------------------------------

test_that("the file is created, named conventions.md", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(conventions_md(dir))

  expect_identical(list.files(dir), "conventions.md")
})

test_that("the created path is returned, invisibly", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(returned <- withVisible(conventions_md(dir)))

  # Announced already, so a visible return would report the path twice
  expect_false(returned$visible)
  expect_identical(returned$value, file.path(dir, "conventions.md"))
})

test_that("the copy is verbatim", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(created <- conventions_md(dir))

  master <- system.file(
    "templates", "conventions.md",
    package = "icu",
    mustWork = TRUE
  )

  # The whole content contract: the master is what projects receive, so
  # editing it is the only way to change what this function writes
  expect_identical(readLines(created), readLines(master))
})

test_that("the default path is the working directory", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  capture.output(conventions_md())

  expect_true(file.exists(file.path(dir, "conventions.md")))
})

test_that("the default does not go looking for ai/", {
  dir <- tempfile()
  dir.create(dir)
  dir.create(file.path(dir, "ai"))
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # In a project the file belongs in ai/, but this function writes where it
  # is told and nowhere else: no project-root detection, no guessing at a
  # layout. Putting it in ai/ is the caller's job.
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  capture.output(conventions_md())

  expect_true(file.exists(file.path(dir, "conventions.md")))
  expect_false(file.exists(file.path(dir, "ai", "conventions.md")))
})

# --- The content contract ---------------------------------------------------

# Subsumed by the verbatim-copy test, but kept so that an edit to the master
# which breaks its structure fails with a readable message.

test_that("the file carries house conventions and a deviations section", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(created <- conventions_md(dir))

  lines <- readLines(created)

  expect_identical(lines[[1]], "# Code conventions (icu)")
  expect_identical(
    grep("^## ", lines, value = TRUE),
    c("## House conventions", "## Project-specific deviations")
  )
})

test_that("the deviations section ships empty", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(created <- conventions_md(dir))

  lines <- readLines(created)

  # Empty but present: the section is what makes a copy, rather than a
  # pointer, the right shape for this file
  deviations <- which(lines == "## Project-specific deviations")

  expect_true(deviations > 0)
  expect_identical(
    grep("\\S", lines[(deviations + 1):length(lines)], value = TRUE),
    "<!-- none yet -->"
  )
})

# --- Never overwrite --------------------------------------------------------

test_that("an existing conventions.md is an error, not an overwrite", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(conventions_md(dir))

  expect_error(conventions_md(dir), "already exists")
})

test_that("the error says what to do about it", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  capture.output(conventions_md(dir))

  expect_error(conventions_md(dir), "delete it by hand")
})

test_that("the existing file survives the error untouched", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  target <- file.path(dir, "conventions.md")

  # A project's copy holds its deviations, which nothing else records --
  # losing them to a re-run is the failure this function must never have
  writeLines(c("# Code conventions (icu)", "", "deviations live here"), target)

  expect_error(conventions_md(dir))
  expect_identical(readLines(target)[[3]], "deviations live here")
})

# --- Announcement -----------------------------------------------------------

test_that("the path is announced", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_output(conventions_md(dir), "conventions.md", fixed = TRUE)
})

test_that("the announced path is the returned path", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  announced <- capture.output(returned <- conventions_md(dir))

  # One clean line, no [1] or quotes: cat(), not print()
  expect_identical(announced, returned)
})

# --- Input validation -------------------------------------------------------

test_that("invalid path is rejected", {
  expect_error(conventions_md(c(".", ".")), "path must be length 1")
  expect_error(conventions_md(character(0)), "path must be length 1")
  expect_error(conventions_md(1), "path must be character")
  expect_error(conventions_md(NA_character_), "path must not be NA")
  expect_error(
    conventions_md(file.path(tempdir(), "no-such-directory")),
    "path must be an existing directory"
  )
})

test_that("a missing target directory is an error, not a silent creation", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # Seeding a project's ai/ means creating that directory first,
  # deliberately -- this function never makes one
  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  expect_error(conventions_md('ai'), "path must be an existing directory")
})

test_that("nothing is created when validation fails", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(conventions_md(1))

  expect_length(list.files(dir), 0)
})
