# new_main() writes files and opens editors, so every test here works in its
# own temp directory and passes open = FALSE. The opening step is the one part
# that cannot be tested; it is deliberately the last, thinnest branch of the
# function.
#
# The date in a created name comes from the clock, so it is recomputed here
# rather than hard-coded.

today <- format(Sys.Date(), "%Y-%m-%d")

# --- Correctness ------------------------------------------------------------

test_that("an empty directory gets main_v1, stamped with today", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(path = dir, open = FALSE)

  expect_identical(list.files(dir), paste0("main_v1_", today, ".qmd"))
})

test_that("the created path is returned, invisibly", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  returned <- withVisible(new_main(path = dir, open = FALSE))

  expect_false(returned$visible)
  expect_identical(
    returned$value,
    file.path(dir, paste0("main_v1_", today, ".qmd"))
  )
  expect_true(file.exists(returned$value))
})

test_that("creating a document says nothing", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # dated_path() announces the path it built by default; new_main() must not
  # inherit that. Opening the file is the notification, and the callers that
  # pass open = FALSE -- tests, and a project scaffolder writing for a
  # different session -- want silence.
  expect_silent(new_main(path = dir, open = FALSE))
})

test_that("the created file is a verbatim copy of the installed template", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  created <- new_main(path = dir, open = FALSE)

  template <- system.file(
    "templates", "main.qmd",
    package = "icu",
    mustWork = TRUE
  )

  # The whole content contract. The template is static -- no placeholders, no
  # interpolation -- so "identical to the template" is the entire
  # specification of what this function writes.
  expect_identical(readLines(created), readLines(template))
})

test_that("stem names the document", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(stem = "sensitivity", path = dir, open = FALSE)

  expect_identical(list.files(dir), paste0("sensitivity_v1_", today, ".qmd"))
})

test_that("the document lands in path, not the working directory", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(path = dir, open = FALSE)

  expect_length(list.files(dir), 1)
  expect_length(list.files(getwd(), pattern = "^main_v"), 0)
})

# --- Versioning -------------------------------------------------------------

test_that("an existing version increments, with a warning", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(path = dir, open = FALSE)

  expect_warning(new_main(path = dir, open = FALSE), "main_v1 already exists")
})

test_that("the warning names the version it is creating", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(path = dir, open = FALSE)

  expect_warning(new_main(path = dir, open = FALSE), "creating main_v2 instead")
})

test_that("the document is still created despite the warning", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  new_main(path = dir, open = FALSE)
  suppressWarnings(new_main(path = dir, open = FALSE))

  expect_true(file.exists(file.path(dir, paste0("main_v2_", today, ".qmd"))))
})

test_that("the probe takes the highest version, not the count", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  file.create(
    file.path(dir, c("main_v1_2026-08-21.qmd", "main_v7_2026-08-22.qmd"))
  )

  suppressWarnings(new_main(path = dir, open = FALSE))

  expect_true(file.exists(file.path(dir, paste0("main_v8_", today, ".qmd"))))
})

test_that("versions are compared numerically, not alphabetically", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  file.create(
    file.path(dir, c("main_v9_2026-08-21.qmd", "main_v10_2026-08-22.qmd"))
  )

  suppressWarnings(new_main(path = dir, open = FALSE))

  expect_true(file.exists(file.path(dir, paste0("main_v11_", today, ".qmd"))))
})

test_that("creating a new version leaves the old ones in place", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # Write-only by design: relocating superseded versions is retire()'s job,
  # with its own blast radius and its own contract
  new_main(path = dir, open = FALSE)
  suppressWarnings(new_main(path = dir, open = FALSE))
  suppressWarnings(new_main(path = dir, open = FALSE))

  expect_length(list.files(dir), 3)
  expect_true(file.exists(file.path(dir, paste0("main_v1_", today, ".qmd"))))
})

test_that("a different stem has its own version sequence", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  file.create(file.path(dir, "main_v4_2026-08-21.qmd"))

  expect_silent(new_main(stem = "sensitivity", path = dir, open = FALSE))
  expect_true(
    file.exists(file.path(dir, paste0("sensitivity_v1_", today, ".qmd")))
  )
})

# --- Edge cases / special values --------------------------------------------

test_that("a rendered sibling does not push the version along", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # main_v9_*.html would be the render of a document, not a document; the
  # grammar groups by (stem, extension) everywhere it is spoken
  file.create(
    file.path(dir, c("main_v1_2026-08-21.qmd", "main_v9_2026-08-21.html"))
  )

  suppressWarnings(new_main(path = dir, open = FALSE))

  expect_true(file.exists(file.path(dir, paste0("main_v2_", today, ".qmd"))))
})

test_that("an unversioned dated document does not trigger the probe", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  file.create(file.path(dir, "main_2026-08-21.qmd"))

  expect_silent(new_main(path = dir, open = FALSE))
  expect_true(file.exists(file.path(dir, paste0("main_v1_", today, ".qmd"))))
})

test_that("names that do not speak the grammar are ignored", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # Undated, unstamped, and a near-miss date: none of them participate, so
  # none of them can drag the version number up
  file.create(
    file.path(dir, c("main_v3.qmd", "notes.qmd", "main_v4_2026_08-21.qmd"))
  )

  expect_silent(new_main(path = dir, open = FALSE))
  expect_true(file.exists(file.path(dir, paste0("main_v1_", today, ".qmd"))))
})

test_that("a subdirectory named like a document is ignored", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  dir.create(file.path(dir, "main_v6_2026-08-21"))

  expect_silent(new_main(path = dir, open = FALSE))
  expect_true(file.exists(file.path(dir, paste0("main_v1_", today, ".qmd"))))
})

# --- The template's content contract ----------------------------------------

# All subsumed by the verbatim-copy test above. Kept as belt and braces so
# that a template edit which breaks the document's structure fails with a
# readable message rather than "these sixty lines differ".

test_that("the YAML carries the house render settings", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  lines <- readLines(new_main(path = dir, open = FALSE))

  expect_identical(lines[[1]], "---")
  expect_true(any(grepl('^title: "Untitled"', lines)))
  expect_true(any(grepl('^author: "Ian Cero"', lines)))
  expect_true(any(grepl("^date: today", lines)))
  expect_true(any(grepl("embed-resources: true", lines)))
  expect_true(any(grepl("toc: true", lines)))
  expect_true(any(grepl("toc-depth: 2", lines)))
  expect_true(any(grepl("^editor: source", lines)))
  expect_true(any(grepl("message: false", lines)))
})

test_that("the skeleton headers are present, and in order", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  lines <- readLines(new_main(path = dir, open = FALSE))

  # Prose only: an R comment inside the setup chunk also opens with "# "
  fences   <- grepl("^```", lines)
  in_chunk <- fences | (cumsum(fences) %% 2 == 1)

  expect_identical(
    grep("^# ", lines[!in_chunk], value = TRUE),
    c(
      "# Project Background",
      "# Data Provenance",
      "# Data Wrangling",
      "# Analysis",
      "# Results Summary"
    )
  )
})

test_that("Project Background ships empty, for meeting() to fill", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  lines <- readLines(new_main(path = dir, open = FALSE))

  background <- which(lines == "# Project Background")
  provenance <- which(lines == "# Data Provenance")

  expect_true(all(!nzchar(lines[(background + 1):(provenance - 1)])))
})

test_that("Data Provenance states the data/ invariant", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  # The invariant's one visible home -- the project skeleton ships no README
  text <- paste(readLines(new_main(path = dir, open = FALSE)), collapse = " ")

  expect_match(text, "data/")
  expect_match(text, "never written")
  expect_match(text, "output/")
})

test_that("the setup chunk registers the session-info hook", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  lines <- readLines(new_main(path = dir, open = FALSE))

  expect_true(any(grepl("include: false", lines)))
  expect_true(any(grepl("knitr::knit_hooks\\$set\\(document", lines)))
  expect_true(any(grepl("sessioninfo::session_info\\(\\)", lines)))

  # Deletion-resistant only if it says why it must not be deleted
  expect_true(any(grepl("Do not remove", lines)))
})

# --- Render (the one slow test) ---------------------------------------------

test_that("a render appends the session-info section", {
  skip_on_cran()
  skip_if_not(nzchar(Sys.which("quarto")), "quarto is not on PATH")
  skip_if_not_installed("knitr")
  skip_if_not_installed("tidyverse")
  skip_if_not_installed("sessioninfo")

  # The template loads icu itself, and quarto renders in a separate R process
  # that cannot see a load_all()'d package -- so this test can only run
  # against an installed icu. lib.loc is passed explicitly because
  # find.package() would otherwise answer from the loaded dev namespace and
  # this would never skip when it should.
  skip_if(
    length(find.package("icu", lib.loc = .libPaths(), quiet = TRUE)) == 0,
    "icu is not installed, so the template's library(icu) cannot resolve"
  )

  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  created <- new_main(path = dir, open = FALSE)

  # The hook is knitr internals, and its failure mode is a silently missing
  # section rather than an error. Only a real render catches that, so the
  # suite pays for exactly one.
  status <- system2(
    "quarto",
    c("render", shQuote(normalizePath(created, winslash = "/"))),
    stdout = FALSE,
    stderr = FALSE
  )

  expect_identical(status, 0L)

  rendered <- sub("\\.qmd$", ".html", created)

  expect_true(file.exists(rendered))
  expect_match(
    paste(readLines(rendered, warn = FALSE), collapse = "\n"),
    "Session info"
  )
})

# --- Input validation -------------------------------------------------------

test_that("invalid stem is rejected", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(new_main(c("a", "b"), dir, open = FALSE), "stem must be length 1")
  expect_error(new_main(character(0), dir, open = FALSE), "stem must be length 1")
  expect_error(new_main(1, dir, open = FALSE), "stem must be character")
  expect_error(new_main(NA_character_, dir, open = FALSE), "stem must not be NA")
  expect_error(new_main("", dir, open = FALSE), "stem must not be empty")
})

test_that("invalid path is rejected", {
  expect_error(new_main(path = c(".", "."), open = FALSE), "path must be length 1")
  expect_error(new_main(path = 1, open = FALSE), "path must be character")
  expect_error(new_main(path = NA_character_, open = FALSE), "path must not be NA")
  expect_error(
    new_main(path = file.path(tempdir(), "no-such-directory"), open = FALSE),
    "path must be an existing directory"
  )
})

test_that("invalid open is rejected", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(new_main(path = dir, open = c(TRUE, TRUE)), "open must be length 1")
  expect_error(new_main(path = dir, open = "yes"), "open must be TRUE or FALSE")
  expect_error(new_main(path = dir, open = NA), "open must be TRUE or FALSE")
})

test_that("nothing is created when validation fails", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  expect_error(new_main(stem = "", path = dir, open = FALSE))

  expect_length(list.files(dir), 0)
})


# --- meeting(): how these tests are set up ---------------------------------

# meeting_block() carries the real tests -- it is a pure string function, so
# it needs no temp dir and no editor. meeting() is a thin insert-or-print
# wrapper around it.
#
# Every test that calls meeting() itself mocks rstudio_available() first, and
# must: devtools::test() run from inside RStudio would otherwise take the
# editor branch for real and insert a meeting block into whatever file
# happens to be open.
#
# `today` is defined at the top of this file, recomputed rather than
# hard-coded, since the header comes from the clock.

# --- meeting_block(): the block text ----------------------------------------

test_that("the block is exactly the house boilerplate", {
  # The whole content contract, in one assertion. The trailing spaces on the
  # fill-in lines are deliberate -- they leave the cursor where you type.
  expect_identical(
    meeting_block(),
    paste0(
      "## Meeting - ", today, "\n",
      "\n",
      "**Attendees:**\n",
      "- Ian Cero\n",
      "- \n",
      "- \n",
      "\n",
      "\n",
      "**Notes:**\n",
      "\n",
      "\n",
      "**TODOs / Deliverables:**\n",
      "- [ ] \n",
      "- [ ] \n",
      "- [ ] \n",
      "- [ ] \n"
    )
  )
})

test_that("the header is dated, not numbered", {
  lines <- strsplit(meeting_block(), "\n")[[1]]

  # Date identifies the entry; the format matches dated_path()'s, so a log
  # entry and the files that meeting produced sort and grep together
  expect_identical(lines[[1]], paste0("## Meeting - ", today))
  expect_match(lines[[1]], "^## Meeting - \\d{4}-\\d{2}-\\d{2}$")
})

test_that("a label is appended after the date", {
  lines <- strsplit(meeting_block("manuscript feedback"), "\n")[[1]]

  expect_identical(
    lines[[1]],
    paste0("## Meeting - ", today, " - manuscript feedback")
  )
})

test_that("a label changes the header and nothing else", {
  plain     <- strsplit(meeting_block(), "\n")[[1]]
  labelled  <- strsplit(meeting_block("kickoff"), "\n")[[1]]

  expect_identical(labelled[-1], plain[-1])
})

test_that("the block carries three sections, in order", {
  lines <- strsplit(meeting_block(), "\n")[[1]]

  expect_identical(
    grep("^\\*\\*", lines, value = TRUE),
    c("**Attendees:**", "**Notes:**", "**TODOs / Deliverables:**")
  )
})

test_that("Decisions are deliberately absent", {
  # Decisions folded into Notes -- pinned so the folding is not quietly
  # undone. Deliverables used to be folded into Requests the same way and
  # pinned here beside it; that half was deliberately unfolded on
  # 2026-08-25, when the section became TODOs / Deliverables.
  block <- meeting_block()

  expect_no_match(block, "Decisions")
})

test_that("TODOs are four empty, unticked checkboxes", {
  lines <- strsplit(meeting_block(), "\n")[[1]]

  # Checkboxes rather than bullets: they carry state, so the top of the
  # document always shows what is still outstanding. Four of them is a hint
  # about how much usually comes out of a meeting.
  expect_identical(
    grep("^- \\[", lines, value = TRUE),
    c("- [ ] ", "- [ ] ", "- [ ] ", "- [ ] ")
  )
  expect_no_match(meeting_block(), "[x]", fixed = TRUE)
})

test_that("attendees are Ian plus two empty bullets", {
  lines <- strsplit(meeting_block(), "\n")[[1]]

  # Ian is at every meeting this function will ever be called for, so he is
  # prefilled; the empty bullets carry the cursor-placing trailing space
  attendees <- which(lines == "**Attendees:**")
  expect_identical(lines[(attendees + 1):(attendees + 3)],
                   c("- Ian Cero", "- ", "- "))
})

test_that("there is room to type under Notes", {
  lines <- strsplit(meeting_block(), "\n")[[1]]

  notes <- which(lines == "**Notes:**")
  todos <- which(lines == "**TODOs / Deliverables:**")

  expect_identical(lines[(notes + 1):(todos - 1)], c("", ""))
})

test_that("the block ends with a newline", {
  # So the cursor lands on a fresh line after an insert, and a cat() of it
  # returns the console prompt cleanly
  expect_match(meeting_block(), "\n$")
})

# --- meeting(): insert or print ---------------------------------------------

test_that("with no RStudio session the block is printed", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  # Never empty-handed mid-meeting: with nothing to insert into, the block
  # goes to stdout to be pasted
  expect_output(meeting(), "## Meeting - ", fixed = TRUE)
})

test_that("what is printed is exactly the block", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  printed <- capture.output(meeting())

  expect_identical(paste0(paste(printed, collapse = "\n"), "\n"), meeting_block())
})

test_that("the block is returned invisibly, and reported exactly once", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  capture.output(returned <- withVisible(meeting()))

  # Already delivered, so a visible return would print it a second time in
  # any context that auto-prints
  expect_false(returned$visible)
  expect_identical(returned$value, meeting_block())
})

test_that("a label reaches the block through meeting()", {
  local_mocked_bindings(rstudio_available = function() FALSE)

  capture.output(returned <- meeting("kickoff"))

  expect_identical(returned, meeting_block("kickoff"))
})

test_that("with an RStudio session the block is inserted, not printed", {
  skip_if_not_installed("rstudioapi")

  inserted <- NULL

  local_mocked_bindings(rstudio_available = function() TRUE)
  local_mocked_bindings(
    insertText = function(...) {
      args <- list(...)
      inserted <<- args$text
      invisible(NULL)
    },
    .package = "rstudioapi"
  )

  expect_silent(returned <- meeting())

  expect_identical(inserted, meeting_block())
  expect_identical(returned, meeting_block())
})

# --- meeting(): input validation --------------------------------------------

test_that("invalid label is rejected", {
  expect_error(meeting_block(c("a", "b")), "label must be length 1")
  expect_error(meeting_block(character(0)), "label must be length 1")
  expect_error(meeting_block(1), "label must be character")
  expect_error(meeting_block(NA_character_), "label must not be NA")
  expect_error(meeting_block(""), "label must not be empty")
})

test_that("validation reaches the caller through meeting()", {
  # meeting() delegates to meeting_block() rather than repeating the checks,
  # so the messages must still surface from the exported function
  local_mocked_bindings(rstudio_available = function() FALSE)

  expect_error(meeting(c("a", "b")), "label must be length 1")
  expect_error(meeting(1), "label must be character")
  expect_error(meeting(NA_character_), "label must not be NA")
  expect_error(meeting(""), "label must not be empty")
})

test_that("no label is the default, and is not an error", {
  expect_no_error(meeting_block())
  expect_no_error(meeting_block(NULL))
  expect_identical(meeting_block(NULL), meeting_block())
})
