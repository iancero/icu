#' Add a date and/or time stamp to a file name
#'
#' Inserts the current date, the current time, or both immediately before a
#' file's extension, so re-runs write to a new file instead of clobbering
#' historic output.
#'
#' @param file_name A single, non-empty, non-`NA` character string: the file
#'   name or path to stamp. Not vectorized.
#' @param ymd A single `TRUE`/`FALSE`: include the current date, formatted
#'   `%Y-%m-%d`. Defaults to `TRUE`.
#' @param hms A single `TRUE`/`FALSE`: include the current time, formatted
#'   `%H-%M-%S`. Defaults to `FALSE`. Use this when re-running within a single
#'   day and each run's output must be kept.
#' @param print A single `TRUE`/`FALSE`: write the assembled path to `stdout`.
#'   Defaults to `TRUE`, so a script or a rendered document carries a record of
#'   which file it named.
#'
#' @details
#' Apart from the optional announcement, this function only builds a string. It
#' does not read the filesystem, check for existing files, or write anything,
#' so the path it returns is not guaranteed to be free by the time you write
#' to it.
#'
#' There is no version argument. Major versions are manual and belong in the
#' name you pass: `dated_path('figure_1a_v3.png')` returns
#' `"figure_1a_v3_2026-08-10.png"`, keeping the version ahead of the date so
#' an output directory groups by version and then sorts chronologically
#' within it.
#'
#' With `hms = FALSE`, two runs on the same day produce the same path, and the
#' second will overwrite the first. This is deliberate: re-running an analysis
#' usually means replacing this morning's figure, not accumulating a dozen
#' copies of it. Set `hms = TRUE` when you want every run kept.
#'
#' Both stamps come from a single [Sys.time()] call, so a run that straddles
#' midnight cannot emit a date and a time from opposite sides of it.
#'
#' The extension is whatever [tools::file_ext()] considers it, which is only
#' the final component: `data.tar.gz` becomes `data.tar_2026-08-10.gz`. A file
#' name with no extension gets the stamp appended at the end.
#'
#' Setting both `ymd` and `hms` to `FALSE` is an error rather than a silent
#' passthrough.
#'
#' @section Printing:
#' The path goes out through [cat()], so it lands on `stdout` and knitr renders
#' it into the document as ordinary chunk output — the point being that a
#' rendered PDF states on its face which files that render produced.
#'
#' [message()] was the alternative and is rejected. Its output does reach a
#' knitted document by default, but it is fragile in exactly the place this is
#' meant to be useful: `message: false` in a document's YAML is the customary
#' way to hide `library()` startup chatter, and it would silence this record
#' along with it. Nothing is conventionally set that would suppress `stdout`.
#' [print()] is rejected too, on cosmetics — it would put `[1]` and quotes
#' around the path in the rendered output.
#'
#' The cost of `stdout` is that the announcement is part of the value stream:
#' [capture.output()] will pick it up, as will a shell redirect of an `Rscript`
#' run. Turn it off for a call with `print = FALSE`, or use the quiet
#' shorthands below.
#'
#' The path is reported exactly once: through `stdout` when `print = TRUE`, and
#' otherwise by the ordinary visible return value. That is why `print = TRUE`
#' returns **invisibly** — a visible return would print the path a second time
#' anywhere that auto-prints, so a bare `dpp('fig.png')` in a chunk would
#' render two identical lines. Invisibility affects auto-printing only:
#' `p <- dpp('fig.png')` and `ggsave(plot, dpp('fig.png'))` behave the same
#' either way.
#'
#' The announcement reports the path that was **built**, not one that was
#' written. Nothing here touches the disk, so if the surrounding
#' [ggplot2::ggsave()] or render call then fails, the path was still announced.
#' Read it as "this is the name the run intended", which is what makes it
#' useful in a log.
#'
#' @section Shorthands:
#' Four one-word wrappers exist for inline use in calls where the full name
#' crowds the line. The second `p` means "print":
#'
#' | Shorthand | Equivalent to |
#' | --- | --- |
#' | `dp(x)`   | `dated_path(x, ymd = TRUE, hms = FALSE, print = FALSE)` |
#' | `dtp(x)`  | `dated_path(x, ymd = TRUE, hms = TRUE,  print = FALSE)` |
#' | `dpp(x)`  | `dated_path(x, ymd = TRUE, hms = FALSE, print = TRUE)`  |
#' | `dtpp(x)` | `dated_path(x, ymd = TRUE, hms = TRUE,  print = TRUE)`  |
#'
#' None of them takes any further arguments — a shorthand you have to pass
#' toggles to is not shorter. For the time-only case, call `dated_path()`
#' directly.
#'
#' Note that `dp()` is deliberately *not* `dated_path()` with its defaults:
#' the full name defaults to printing, the two-letter forms do not. Inline in
#' a busy call the quiet version is usually what you want, and the `p` is
#' there to ask for the record when you do.
#'
#' @return A single character string: `file_name` with the stamp inserted
#'   before its extension. Returned invisibly when `print` is `TRUE`, since the
#'   path has already been written to `stdout`; visibly otherwise.
#'
#' @examples
#' dated_path('output/figure_1a.png')
#' dated_path('output/figure_1a.png', hms = TRUE)
#'
#' # Manual major versions are just part of the name
#' dated_path('output/figure_1a_v3.png')
#'
#' # Time only, e.g. for output already filed in a dated folder
#' dated_path('output/figure_1a.png', ymd = FALSE, hms = TRUE)
#'
#' # Shorthands: dp/dtp are quiet, dpp/dtpp announce the path
#' dp('output/figure_1a.png')
#' dtp('output/figure_1a.png')
#' dpp('output/figure_1a.png')
#' dtpp('output/figure_1a.png')
#'
#' \dontrun{
#' ggsave(plot, dpp('output/figure_1a.png'), width = 3, height = 4, dpi = 300)
#' }
#'
#' @export
dated_path <- function(file_name, ymd = TRUE, hms = FALSE, print = TRUE) {

  stopifnot(
    'file_name must be length 1'               = length(file_name) == 1,
    'file_name must be character'              = is.character(file_name),
    'file_name must not be NA'                 = !is.na(file_name),
    'file_name must not be empty'              = nzchar(file_name),
    'ymd must be length 1'                     = length(ymd) == 1,
    'ymd must be TRUE or FALSE'                = is.logical(ymd) && !is.na(ymd),
    'hms must be length 1'                     = length(hms) == 1,
    'hms must be TRUE or FALSE'                = is.logical(hms) && !is.na(hms),
    'print must be length 1'                   = length(print) == 1,
    'print must be TRUE or FALSE'              = is.logical(print) && !is.na(print),
    'at least one of ymd and hms must be TRUE' = ymd || hms
  )

  # One clock reading for both stamps, so a run at 23:59:59 cannot report
  # today's date alongside tomorrow's time
  now <- Sys.time()

  stamp <- paste(
    c(
      if (ymd) format(now, '%Y-%m-%d'),
      if (hms) format(now, '%H-%M-%S')
    ),
    collapse = '_'
  )

  ext  <- tools::file_ext(file_name)
  stem <- tools::file_path_sans_ext(file_name)

  out <- if (nzchar(ext)) {
    paste0(stem, '_', stamp, '.', ext)
  } else {
    paste0(stem, '_', stamp)
  }

  # cat() rather than message(): stdout is rendered into a knitted document as
  # chunk output, and unlike a message it survives the `message: false` that a
  # .qmd commonly sets to hide library() startup chatter
  if (print) {
    cat(out, '\n', sep = '')

    # Announced already, so returning visibly would print the path a second
    # time in any context that auto-prints -- console, or a bare call in a
    # chunk. Assignment and nesting are unaffected by invisibility.
    return(invisible(out))
  }

  out
}

# The shorthands name their arguments even where they match dated_path()'s
# defaults, so each stays pinned to its documented behavior if those defaults
# ever move, and the one-line body reads as its own documentation.

#' @rdname dated_path
#' @export
dp <- function(file_name) {
  dated_path(file_name, ymd = TRUE, hms = FALSE, print = FALSE)
}

#' @rdname dated_path
#' @export
dtp <- function(file_name) {
  dated_path(file_name, ymd = TRUE, hms = TRUE, print = FALSE)
}

#' @rdname dated_path
#' @export
dpp <- function(file_name) {
  dated_path(file_name, ymd = TRUE, hms = FALSE, print = TRUE)
}

#' @rdname dated_path
#' @export
dtpp <- function(file_name) {
  dated_path(file_name, ymd = TRUE, hms = TRUE, print = TRUE)
}
