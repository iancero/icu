# new_project() creates directories and opens RStudio windows, so every test
# here works inside a temp projects directory and mocks rstudio_available().
#
# The mock is not optional. devtools::test() run from inside RStudio would
# otherwise take the editor branch for real and open a new RStudio window per
# test -- the same hazard meeting() carries, and the reason the check lives in
# one internal binding.
#
# The function also lets conventions_md()'s announcement through, so calls are
# wrapped in capture.output() to keep the suite readable.
#
# The year in a folder name comes from the clock, so it is recomputed here
# rather than hard-coded.

year  <- format(Sys.Date(), "%Y")
today <- format(Sys.Date(), "%Y-%m-%d")

# A temp projects directory, the option pointed at it, and no editor. Returns
# the directory; the project it will hold is `smith_2026`.
local_projects_dir <- function(env = parent.frame()) {
  dir <- tempfile()
  dir.create(dir)

  withr::defer(unlink(dir, recursive = TRUE), envir = env)
  withr::local_options(icu.projects_dir = dir, .local_envir = env)

  testthat::local_mocked_bindings(
    rstudio_available = function() FALSE,
    .env = env
  )

  dir
}

# --- Correctness ------------------------------------------------------------

test_that("the folder is the name plus the current year", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(new_project("smith")))

  expect_identical(list.files(dir), paste0("smith_", year))
})

test_that("the year goes at the end, so projects group by colleague", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(new_project("smith_delirium_drug_r01")))

  # Browsed by who, not by when: an alphabetical listing keeps a colleague's
  # projects together across years
  expect_identical(list.files(dir), paste0("smith_delirium_drug_r01_", year))
})

test_that("the skeleton is the full house taxonomy", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  expect_identical(
    list.dirs(project, full.names = FALSE, recursive = FALSE),
    c(
      "ai",
      "background",
      "data",
      "manuscript",
      "old",
      "output",
      "transcripts"
    )
  )
})

test_that("the skeleton folders ship empty, apart from seeded ai/", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  empties <- c(
    "background", "data", "manuscript", "old", "output", "transcripts"
  )

  for (folder in file.path(project, empties)) {
    expect_length(list.files(folder), 0)
  }
})

test_that("an .Rproj named for the project is written", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  expect_true(
    file.exists(file.path(project, paste0("smith_", year, ".Rproj")))
  )
})

test_that("the .Rproj is a verbatim copy of the installed template", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  template <- system.file(
    "templates", "project.Rproj",
    package = "icu",
    mustWork = TRUE
  )

  # Same posture as the other two templates: what a project receives is a
  # content edit plus a reinstall, with no R code to touch
  expect_identical(
    readLines(file.path(project, paste0("smith_", year, ".Rproj"))),
    readLines(template)
  )
})

test_that("the whole tree is created, and nothing else", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  # The full contract, asserted as a tree rather than as return values
  expect_identical(
    sort(list.files(project, recursive = TRUE, include.dirs = TRUE)),
    sort(c(
      "ai",
      file.path("ai", "conventions.md"),
      "background",
      "data",
      "manuscript",
      "old",
      "output",
      "transcripts",
      paste0("main_v1_", today, ".qmd"),
      paste0("smith_", year, ".Rproj")
    ))
  )
})

test_that("the project path is returned, invisibly", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(returned <- withVisible(new_project("smith"))))

  expect_false(returned$visible)
  expect_identical(returned$value, file.path(dir, paste0("smith_", year)))
  expect_true(dir.exists(returned$value))
})

# --- Seeded contents --------------------------------------------------------

# Asserted as present only. What is *in* main_v1 is pinned by new_main()'s
# tests and what is in conventions.md by conventions_md()'s -- each at the
# layer that owns it.

test_that("main_v1 is seeded at the project root", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  expect_true(
    file.exists(file.path(project, paste0("main_v1_", today, ".qmd")))
  )
})

test_that("conventions.md is seeded into ai/, not the project root", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  expect_true(file.exists(file.path(project, "ai", "conventions.md")))
  expect_false(file.exists(file.path(project, "conventions.md")))
})

test_that("main_v1 is created without being opened", {
  dir <- local_projects_dir()

  # new_main(open = FALSE): the document belongs to the session that is about
  # to open, not this one. Its silence is what makes the scaffold's own
  # output legible.
  announced <- capture.output(suppressMessages(project <- new_project("smith")))

  expect_identical(announced, file.path(project, "ai", "conventions.md"))
})

# --- Location ---------------------------------------------------------------

test_that("the projects directory wins over the working directory", {
  dir <- local_projects_dir()

  elsewhere <- tempfile()
  dir.create(elsewhere)
  on.exit(unlink(elsewhere, recursive = TRUE), add = TRUE)

  old <- setwd(elsewhere)
  on.exit(setwd(old), add = TRUE)

  capture.output(suppressMessages(new_project("smith")))

  expect_identical(list.files(dir), paste0("smith_", year))
  expect_length(list.files(elsewhere), 0)
})

test_that("a configured directory that does not exist yet is created", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  parent <- tempfile()
  on.exit(unlink(parent, recursive = TRUE), add = TRUE)

  # A Box folder that has not synced onto this machine yet is the ordinary
  # reason the configured directory is missing; the option is taken at its
  # word rather than refused
  missing <- file.path(parent, "Projects", "consulting")
  withr::local_options(icu.projects_dir = missing)

  capture.output(suppressMessages(new_project("smith")))

  expect_true(dir.exists(file.path(missing, paste0("smith_", year))))
})

test_that("creating the configured directory is silent", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  parent <- tempfile()
  on.exit(unlink(parent, recursive = TRUE), add = TRUE)

  withr::local_options(icu.projects_dir = file.path(parent, "Projects"))

  # Not a fallback and not a surprise -- the option said where projects go
  expect_no_warning(capture.output(suppressMessages(new_project("smith"))))
})

test_that("an unset option falls back to the working directory, loudly", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  withr::local_options(icu.projects_dir = NULL)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  expect_warning(
    capture.output(suppressMessages(new_project("smith"))),
    "icu.projects_dir is not set"
  )
})

test_that("the fallback still creates the project", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  withr::local_options(icu.projects_dir = NULL)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  # The whole point of warning rather than erroring: mid-meeting, a project in
  # the wrong place is a ten-second fix, and no project at all is not
  suppressWarnings(capture.output(suppressMessages(new_project("smith"))))

  expect_identical(list.files(dir), paste0("smith_", year))
  expect_true(
    file.exists(file.path(dir, paste0("smith_", year), paste0("main_v1_", today, ".qmd")))
  )
})

test_that("the warning names the path the project landed in", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  withr::local_options(icu.projects_dir = NULL)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  # Loud means findable: the ten-second fix needs somewhere to go and get it
  expect_warning(
    capture.output(suppressMessages(new_project("smith"))),
    paste0("smith_", year),
    fixed = TRUE
  )
})

test_that("the warning says how to stop it happening again", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  withr::local_options(icu.projects_dir = NULL)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  expect_warning(
    capture.output(suppressMessages(new_project("smith"))),
    ".Rprofile",
    fixed = TRUE
  )
})

test_that("an unusable option value is treated as an unset one", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # Not a path at all, so there is nothing to take at its word -- and still no
  # reason to leave the meeting without a project
  withr::local_options(icu.projects_dir = 1)

  old <- setwd(dir)
  on.exit(setwd(old), add = TRUE)

  expect_warning(
    capture.output(suppressMessages(new_project("smith"))),
    "icu.projects_dir is not a single directory path"
  )
  expect_identical(list.files(dir), paste0("smith_", year))
})

# --- Collision --------------------------------------------------------------

test_that("an existing project is an error, not an increment", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(new_project("smith")))

  # Projects are not versioned artifacts. A second smith_2026 is a
  # double-call, or a name that should have been distinct.
  expect_error(new_project("smith"), "already exists")
})

test_that("the collision error says why there is no v2", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(new_project("smith")))

  expect_error(new_project("smith"), "projects are not versioned")
})

test_that("the existing project survives the collision untouched", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  writeLines("real work", file.path(project, "data", "cohort.csv"))

  expect_error(new_project("smith"))

  expect_identical(readLines(file.path(project, "data", "cohort.csv")), "real work")
  expect_length(list.files(dir), 1)
})

test_that("a distinct name is not a collision", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(new_project("smith")))
  capture.output(suppressMessages(new_project("smith_aim2")))

  expect_identical(
    sort(list.files(dir)),
    sort(c(paste0("smith_", year), paste0("smith_aim2_", year)))
  )
})

# --- Outside RStudio --------------------------------------------------------

test_that("with no RStudio session the path is reported instead", {
  dir <- local_projects_dir()

  # Nothing to open a window with, so the message is the only sign the call
  # did anything
  expect_message(capture.output(new_project("smith")), "smith", fixed = TRUE)
  expect_message(
    capture.output(new_project("jones")),
    "not opened",
    fixed = TRUE
  )
})

test_that("everything is still created when there is nothing to open", {
  dir <- local_projects_dir()

  capture.output(suppressMessages(project <- new_project("smith")))

  expect_true(dir.exists(project))
  expect_true(file.exists(file.path(project, "ai", "conventions.md")))
})

# --- Input validation -------------------------------------------------------

test_that("invalid name is rejected", {
  expect_error(new_project(c("a", "b")), "name must be length 1")
  expect_error(new_project(character(0)), "name must be length 1")
  expect_error(new_project(1), "name must be character")
  expect_error(new_project(NA_character_), "name must not be NA")
  expect_error(new_project(""), "name must not be empty")
})

test_that("a path separator in the name is rejected", {
  # Permissive about names otherwise, but a separator would put the project
  # somewhere other than the projects directory
  expect_error(new_project("smith/delirium"), "name must not contain a path separator")
  expect_error(new_project("smith\\delirium"), "name must not contain a path separator")
})

test_that("nothing is created when validation fails", {
  dir <- local_projects_dir()

  expect_error(new_project(""))

  expect_length(list.files(dir), 0)
})
