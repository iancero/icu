#' Scaffold a whole consulting project
#'
#' Creates a dated project folder -- the standard subdirectories, the house
#' analysis document, the AI conventions file, and an `.Rproj` -- and opens it
#' in a new RStudio window. One call, mid-meeting, while the request that
#' prompted it is still being described.
#'
#' @param name A single, non-empty, non-`NA` character string: the project's
#'   name, without a year. Typically colleague and topic, as in
#'   `'smith_delirium_drug_r01'`. Must not contain a path separator; anything
#'   else your filesystem accepts is allowed.
#'
#' @details
#' The folder is `name` plus the current year -- `smith_delirium_drug_r01_2026`
#' -- and the year marks *initiation* vintage, so a folder created today still
#' says 2026 when the revise-and-resubmit arrives in 2028. The year goes at the
#' end rather than the front because the projects directory is browsed by
#' *who*, not by *when*: alphabetical order groups a colleague's projects
#' across years.
#'
#' That name deliberately does not speak the `{stem}_vN_{date}` grammar the
#' documents inside it use. Projects are not versioned artifacts, and nothing
#' in icu parses a project folder's name.
#'
#' An existing folder of the same name is an **error**, never an increment. It
#' means either a double-call or a project that should have been named
#' differently in the first place -- `_aim2`, `_rr`.
#'
#' This function orchestrates and owns no logic of its own: [new_main()] writes
#' the document and [conventions_md()] writes the conventions file, each on its
#' own terms, and each pinning its own contents with its own tests.
#'
#' @section Where projects go:
#' Under `getOption('icu.projects_dir')`, regardless of the working directory
#' -- the point being that the call works the same from wherever you happen to
#' be when the meeting starts. Set it in your `.Rprofile`:
#'
#' \preformatted{options(icu.projects_dir = '~/Box/Projects')}
#'
#' A configured directory that does not exist yet is created. With the option
#' **unset**, the project is created in the working directory instead, with a
#' warning naming the path it landed in. That is deliberate, and the trade is
#' worth stating: mid-meeting, a project in the wrong place is a ten-second fix
#' afterward, while an error means no project at all. Wrong-but-loud beats
#' right-but-absent.
#'
#' @section The skeleton:
#' \preformatted{smith_delirium_drug_r01_2026/
#'   ai/            the AI workbench; conventions.md is seeded here
#'   background/    read by YOU: codebooks, dictionaries, surveys, papers
#'   data/          read by CODE: data files only, flat
#'   manuscript/    the co-authored paper's track-changes lifecycle
#'   old/           superseded versions land here
#'   output/        written by code, everything dated via dpp()
#'   transcripts/   meeting transcripts, dropped in unrenamed
#'   main_v1_2026-08-23.qmd
#'   smith_delirium_drug_r01_2026.Rproj
#' }
#'
#' Every folder has a rule, so "where does this go" is answered by the taxonomy
#' rather than by memory. **Inboxes** arrive from outside and are never written
#' by the project: `data/` (read by code), `background/` (read by you),
#' `transcripts/` (raw material). **Outputs** are written by the project:
#' `output/` by code, `old/` by hand. **Workbenches** are read and written by
#' both you and your collaborators: `manuscript/` with co-authors, `ai/` with
#' the AI loop.
#'
#' The one that most often needs saying out loud is `data/`: it holds files as
#' *received*, and the project never writes to it. Derived output goes to
#' `output/`. The skeleton ships no README, so that invariant lives in the
#' analysis document's Data Provenance section, where the work happens.
#'
#' @section Opening the project:
#' In a new RStudio window, via [rstudioapi::openProject()], leaving the
#' current session untouched -- mid-meeting you may still need whatever is open
#' in it.
#'
#' The document is **not** opened for you. [new_main()] is called with
#' `open = FALSE`, since opening it here would open it in the wrong (current)
#' session, and reaching into the new one would take a project-local
#' `.Rprofile` hook -- which replaces the user-level `.Rprofile`, where
#' `icu.projects_dir` lives, and would quietly break the option in exactly the
#' session that just used it. One click in the new window is cheaper than that.
#'
#' Outside RStudio there is nothing to open a window with, so everything is
#' created and the path is reported instead.
#'
#' @return The path to the created project directory, invisibly.
#'
#' @examples
#' \dontrun{
#' # Mid-meeting, wherever you happen to be
#' new_project('smith_delirium_drug_r01')
#' }
#'
#' @export
new_project <- function(name) {

  stopifnot(
    'name must be length 1'  = length(name) == 1,
    'name must be character' = is.character(name),
    'name must not be NA'    = !is.na(name),
    'name must not be empty' = nzchar(name),
    # Permissive otherwise -- but a separator would silently put the project
    # somewhere other than the projects directory, which is not a name
    'name must not contain a path separator' = !grepl('[/\\\\]', name)
  )

  # Initiation vintage, not last-touched: a folder created today still says
  # 2026 when the R&R arrives in 2028
  folder <- paste0(name, '_', format(Sys.Date(), '%Y'))

  destination <- projects_dir()
  project     <- file.path(destination$path, folder)

  # Never an increment. An existing project of this name is a double-call, or
  # a name that should have been distinct (_aim2, _rr) -- both are things to
  # be told about, and neither is fixed by creating a second folder.
  if (file.exists(project)) {
    stop(
      project, ' already exists; projects are not versioned, so give this ',
      'one a distinct name'
    )
  }

  if (!dir.create(project)) {
    stop('could not create ', project)
  }

  # The taxonomy, in one place. Inboxes (arrive from outside, never written by
  # the project): data/, background/, transcripts/. Outputs (written by the
  # project): output/, old/. Workbenches (read and written by both sides):
  # manuscript/, ai/.
  skeleton <- c(
    'ai',
    'background',
    'data',
    'manuscript',
    'old',
    'output',
    'transcripts'
  )

  for (subdirectory in file.path(project, skeleton)) {
    if (!dir.create(subdirectory)) {
      stop('could not create ', subdirectory)
    }
  }

  rproj <- file.path(project, paste0(folder, '.Rproj'))

  template <- system.file(
    'templates', 'project.Rproj',
    package = 'icu',
    mustWork = TRUE
  )

  if (!file.copy(template, rproj, overwrite = FALSE)) {
    stop('could not create ', rproj)
  }

  # Seeding, delegated entirely. open = FALSE because the document belongs to
  # the session about to open, not this one; conventions_md() is handed the
  # ai/ path explicitly, since it writes where it is told and never guesses at
  # a layout. It announces the file it wrote, and that announcement is left to
  # reach the caller.
  new_main(path = project, open = FALSE)
  conventions_md(file.path(project, 'ai'))

  if (!destination$configured) {
    warning(
      'icu.projects_dir is ', destination$why, ', so this project was ',
      'created in the working directory: ', project,
      '. Set options(icu.projects_dir = ...) in your .Rprofile to choose ',
      'where new projects go.'
    )
  }

  # Editor side effects, kept thin and isolated at the end, as in new_main()
  if (rstudio_available()) {
    rstudioapi::openProject(rproj, newSession = TRUE)
  } else {
    # message() rather than the cat() dated_path() and conventions_md() use:
    # their reason is surviving a document's `message: false`, and nobody
    # scaffolds a project from inside a render. Without a new window to be the
    # notification, this is the only sign the call did anything.
    message('Created ', project, ' (no RStudio session, so it was not opened)')
  }

  invisible(project)
}


# --- Internals --------------------------------------------------------------

# Where new projects go. Returns the directory, whether it came from the
# option, and -- when it did not -- what was wrong with the option, which the
# caller turns into a warning.
#
# A configured directory that does not exist yet is created rather than
# refused: the option states where projects go, and a Box folder that has not
# synced onto this machine yet is the ordinary reason it is missing. A value
# that is not a usable path at all cannot be taken at its word, so it falls
# back to the working directory the same way an unset option does -- loudly,
# but with a project.
projects_dir <- function() {

  configured <- getOption('icu.projects_dir')

  if (is.null(configured)) {
    return(list(path = getwd(), configured = FALSE, why = 'not set'))
  }

  usable <-
    is.character(configured) &&
    length(configured) == 1 &&
    !is.na(configured) &&
    nzchar(configured)

  if (!usable) {
    return(
      list(
        path       = getwd(),
        configured = FALSE,
        why        = 'not a single directory path'
      )
    )
  }

  if (!dir.exists(configured)) {
    if (!dir.create(configured, recursive = TRUE, showWarnings = FALSE)) {
      stop(
        'could not create the projects directory ', configured,
        ', which icu.projects_dir names'
      )
    }
  }

  list(path = configured, configured = TRUE, why = NA_character_)
}
