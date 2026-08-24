#' Copy the house code conventions into a project
#'
#' Writes `conventions.md` -- the code conventions that travel with icu,
#' plus an empty section for this project's departures from them -- into
#' `path`. One call at project creation, or any time to retrofit a project
#' that predates the file.
#'
#' @param path A single, non-`NA` character string naming an existing
#'   directory: where `conventions.md` is written. Defaults to the working
#'   directory. In a project the file belongs in `ai/`, so pass that --
#'   `conventions_md('ai')` from a project root.
#'
#' @details
#' The conventions are Ian-level rather than project-level, so the master
#' lives in the package and is versioned alongside the functions that embody
#' it. Each project gets a **copy**, not a pointer, for one reason: a copy
#' can hold deviations, and a pointer cannot. The file ends with a
#' `## Project-specific deviations` section, empty by default, which is the
#' project's to edit.
#'
#' That makes every copy part boilerplate and part project-owned, and it
#' reframes staleness as a feature. A project's file is a snapshot of house
#' style *as it stood while that project ran*, plus its local exceptions.
#' Coming back to the project years later for a revise-and-resubmit, that is
#' a more faithful record than the then-current master would be.
#'
#' There is no `force` argument and no overwriting: if `conventions.md`
#' already exists at the target, this errors. The existing file may hold
#' deviations, which are content nobody else wrote and nothing else records.
#' Delete it by hand if you genuinely mean to replace it.
#'
#' Within a project the file belongs in `ai/`, with the rest of the AI
#' workbench, since that is who mostly reads it. The **default is still the
#' working directory**: this function writes where it is told and nothing
#' else, with no project-root detection and no guessing at a layout, so what
#' a call does is legible from the call itself. Placing it in `ai/` is the
#' caller's job -- `conventions_md('ai')` by hand, and [new_main()]'s
#' companion project scaffolder passes the path explicitly. The directory
#' must already exist either way.
#'
#' Editing `inst/templates/conventions.md` in this package is what changes
#' what new projects receive -- the copy is verbatim, so there is no R code
#' to touch.
#'
#' @return The path to the created file, invisibly. The path is also
#'   announced on `stdout`, in the same posture as [dated_path()]: the run
#'   states what it wrote.
#'
#' @examples
#' # Scaffold into a temporary directory
#' dir <- tempfile()
#' dir.create(dir)
#'
#' conventions_md(dir)
#'
#' unlink(dir, recursive = TRUE)
#'
#' @export
conventions_md <- function(path = '.') {

  stopifnot(
    'path must be length 1'              = length(path) == 1,
    'path must be character'             = is.character(path),
    'path must not be NA'                = !is.na(path),
    'path must be an existing directory' = dir.exists(path)
  )

  master <- system.file(
    'templates', 'conventions.md',
    package = 'icu',
    mustWork = TRUE
  )

  target <- file.path(path, 'conventions.md')

  # Never clobber: the existing copy may carry project-specific deviations,
  # which are the one part of this file nothing else in the world records
  if (file.exists(target)) {
    stop(
      target, ' already exists; delete it by hand if you mean to replace it'
    )
  }

  copied <- file.copy(master, target, overwrite = FALSE)

  if (!copied) {
    stop('could not create ', target)
  }

  # cat() rather than message(), for the same reason dated_path() does it:
  # stdout survives the `message: false` a .qmd commonly sets, so a rendered
  # document carries a record of what the run wrote
  cat(target, '\n', sep = '')

  invisible(target)
}
