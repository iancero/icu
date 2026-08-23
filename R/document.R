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
    if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
      rstudioapi::navigateToFile(target)
    } else {
      utils::file.edit(target)
    }
  }

  invisible(target)
}
