#' Scaffold a new main analysis document
#'
#' Creates the house analysis document -- a Quarto file carrying the standard
#' YAML, the standard section headers, and the session-info render hook -- in
#' `path`, named with the next major version and today's date, and opens it in
#' the editor.
#'
#' @param stem A single, non-empty, non-`NA` character string: the base name of
#'   the document. Defaults to `"main"`.
#' @param path A single, non-`NA` character string naming an existing
#'   directory: where the document is created. Defaults to the working
#'   directory.
#' @param open A single `TRUE`/`FALSE`: open the new file in the editor.
#'   Defaults to `TRUE`. Pass `FALSE` from code that is creating a document for
#'   a session other than this one.
#'
#' @details
#' The file is named `main_v1_2026-08-23.qmd`: stem, major version, creation
#' date, assembled by [dated_path()]. The version comes from a probe of `path`
#' for existing `{stem}_vN` Quarto files -- if any are found, the new document
#' takes the highest version plus one, **with a warning**, since silently
#' bumping a version is the kind of thing you want to hear about.
#'
#' This matters more than it looks: the projects this is built for live on
#' synced storage without git, so save-as-increment *is* the versioning system.
#'
#' The function is **write-only**. Creating `main_v3` leaves `main_v2` exactly
#' where it is; sweeping superseded versions aside is a separate job with a
#' separate blast radius.
#'
#' @section The template:
#' The document is copied verbatim from `inst/templates/main.qmd`. There are no
#' placeholders and no interpolation: the title is `"Untitled"` and is edited by
#' hand, `# Project Background` is left empty for the first meeting block, and
#' the remaining headers (Data Provenance, Data Wrangling, Analysis, Results
#' Summary) are the structure that has proven stable across projects.
#'
#' Because the copy is verbatim, **editing the template is editing this
#' function's output**: content changes are a template edit plus a reinstall,
#' with no R code to touch.
#'
#' The template assumes `tidyverse` and `sessioninfo` are available in whatever
#' project renders it. Neither is a dependency of icu -- they are assumptions of
#' the document, and installing icu does not install them.
#'
#' @section Session info:
#' The template's setup chunk registers a knitr `document` hook that appends a
#' collapsed session-info section to every render. It is declared at the top of
#' the document, where active work will not bury or delete it, but runs at the
#' end, where the record is complete. Rendering once at the end of a project
#' therefore leaves the package versions that produced the analysis on the face
#' of the output -- the lightweight stand-in for a full `renv` lockfile.
#'
#' @section Opening the file:
#' With `open = TRUE`, the file is opened through
#' [rstudioapi::navigateToFile()] when RStudio is running, and
#' [utils::file.edit()] otherwise. `open = FALSE` exists for callers that must
#' not touch the current editor: tests, and a project scaffolder creating a
#' document destined for a different session.
#'
#' @return The path to the created file, invisibly.
#'
#' @examples
#' # Scaffold into a temporary directory, without opening an editor
#' dir <- tempfile()
#' dir.create(dir)
#'
#' new_main(path = dir, open = FALSE)
#' list.files(dir)
#'
#' unlink(dir, recursive = TRUE)
#'
#' @export
new_main <- function(stem = 'main', path = '.', open = TRUE) {

  stopifnot(
    'stem must be length 1'              = length(stem) == 1,
    'stem must be character'             = is.character(stem),
    'stem must not be NA'                = !is.na(stem),
    'stem must not be empty'             = nzchar(stem),
    'path must be length 1'              = length(path) == 1,
    'path must be character'             = is.character(path),
    'path must not be NA'                = !is.na(path),
    'path must be an existing directory' = dir.exists(path),
    'open must be length 1'              = length(open) == 1,
    'open must be TRUE or FALSE'         = is.logical(open) && !is.na(open)
  )

  template <- system.file(
    'templates', 'main.qmd',
    package = 'icu',
    mustWork = TRUE
  )

  # Version probe. Grouping is by (stem, extension), as everywhere else in the
  # grammar, so a rendered main_v2_*.html is not mistaken for a document to
  # increment past. Names that do not parse are ignored rather than guessed at.
  existing <- parse_dated_filename(list.files(path))
  siblings <- existing[
    existing$parsed &
      existing$stem == stem &
      existing$ext == 'qmd' &
      !is.na(existing$version),
  ]

  version <- 1L

  if (nrow(siblings) > 0) {
    previous <- max(siblings$version)
    version  <- previous + 1L

    # Loud on purpose: without git, the version number is the whole record of
    # which document supersedes which, so a bump is news
    warning(
      stem, '_v', previous, ' already exists in ', path,
      '; creating ', stem, '_v', version, ' instead'
    )
  }

  target <- dated_path(
    file.path(path, paste0(stem, '_v', version, '.qmd')),
    ymd   = TRUE,
    hms   = FALSE,
    print = FALSE
  )

  # overwrite = FALSE: the probe makes a collision all but impossible, but the
  # one thing this function must never do is land on top of existing work
  copied <- file.copy(template, target, overwrite = FALSE)

  if (!copied) {
    stop('could not create ', target)
  }

  # Editor side effects, kept thin and isolated at the end: everything above is
  # testable, this is not
  if (open) {
    if (rstudio_available()) {
      rstudioapi::navigateToFile(target)
    } else {
      utils::file.edit(target)
    }
  }

  invisible(target)
}


#' Insert a meeting-log entry at the cursor
#'
#' Writes the house meeting-log block -- date-stamped header, Attendees,
#' Notes, and a Requests checklist -- into the current document at the
#' cursor, ready to type into while the meeting is happening.
#'
#' @param label An optional single, non-empty, non-`NA` character string:
#'   a short name for the meeting, appended to the header after the date.
#'   Omitted by default.
#'
#' @details
#' The block is:
#'
#' \preformatted{## Meeting - 2026-08-23
#'
#' **Attendees:**
#'
#' **Notes:**
#'
#'
#'
#' **Requests:**
#'
#' - [ ]
#' - [ ]
#' }
#'
#' with `meeting('manuscript feedback')` giving
#' `## Meeting - 2026-08-23 - manuscript feedback`.
#'
#' Entries are identified by date, not by a meeting number, in the same
#' `%Y-%m-%d` format [dated_path()] stamps files with -- so a log entry and
#' the output that came out of that meeting sort and grep together. The
#' fill-in lines carry a trailing space, which is where the cursor wants to
#' be.
#'
#' Only three sections, deliberately. Decisions folded into Notes, because
#' in practice a decision is just a note worth writing down. Deliverables
#' folded into Requests, because they are the same checklist seen from two
#' sides. The requests are checkboxes rather than bullets, so they carry
#' state: tick them as the work lands, and the top of the document always
#' shows what is still outstanding -- which is also what makes the log
#' usable as project memory, by you or by an AI session reading the source.
#'
#' @section Where it lands:
#' At the cursor, via [rstudioapi::insertText()]. Putting the cursor at the
#' end of the log is your job. That is deliberate: the alternative is
#' parsing the document to find the end of the meeting log, which is
#' fragile in exactly the way a mid-meeting tool must not be, and you are
#' already clicking where the entry goes.
#'
#' Outside RStudio there is nothing to insert into, so the block is
#' printed instead, ready to paste. A meeting should never start with an
#' error message.
#'
#' @return The block text, invisibly. Invisible because the function has
#'   already delivered it -- into the document, or to `stdout` -- so a
#'   visible return would print it a second time.
#'
#' @examples
#' # Outside RStudio the block is printed, ready to paste. Inside RStudio it
#' # is inserted into the current document at the cursor instead.
#' meeting()
#'
#' # An optional label lands after the date
#' meeting('manuscript feedback')
#'
#' @export
meeting <- function(label = NULL) {

  # Validation lives in meeting_block(), the one place that reads `label`;
  # the message reaches the caller from here unchanged
  block <- meeting_block(label)

  # Editor side effects, kept thin and isolated, as in new_main()
  if (rstudio_available()) {
    rstudioapi::insertText(text = block)

    return(invisible(block))
  }

  # Nothing to insert into: print it, so the block is always available to
  # paste rather than lost to an error
  cat(block)

  invisible(block)
}


# --- Internals --------------------------------------------------------------

# The one producer of the meeting block. Split out from meeting() for
# testability, not for sharing: the string assembly deserves exact tests and
# the insert-or-print step around it cannot have any. There is no second
# consumer by design -- the document template is fully static, and the
# creation day's date is precisely what a static file cannot carry.
meeting_block <- function(label = NULL) {

  stopifnot(
    'label must be length 1'  = is.null(label) || length(label) == 1,
    'label must be character' = is.null(label) || is.character(label),
    'label must not be NA'    = is.null(label) || !is.na(label),
    'label must not be empty' = is.null(label) || nzchar(label)
  )

  header <- paste0('## Meeting - ', format(Sys.Date(), '%Y-%m-%d'))

  if (!is.null(label)) {
    header <- paste0(header, ' - ', label)
  }

  # The trailing spaces are deliberate: they leave the cursor one space past
  # the label, so clicking into the line puts you where you type. The three
  # blank lines under Notes are room to write in, not an accident.
  lines <- c(
    header,
    '',
    '**Attendees:** ',
    '',
    '**Notes:**',
    '',
    '',
    '',
    '**Requests:**',
    '',
    '- [ ] ',
    '- [ ] '
  )

  paste0(paste(lines, collapse = '\n'), '\n')
}


# Whether there is an RStudio session to talk to. One function rather than the
# check written twice, and -- since it is a binding in this namespace -- the
# seam the tests mock to exercise the no-RStudio path. That matters more than
# it sounds: devtools::test() run inside RStudio would otherwise take the
# editor branch and insert a meeting block into whatever file happens to be
# open.
rstudio_available <- function() {
  requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()
}
