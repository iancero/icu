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


# --- The dated-file grammar -------------------------------------------------

# Every icu function that speaks file names speaks this one grammar:
#
#     {stem}[_vN]_{YYYY-MM-DD}[_HH-MM-SS].{ext}
#
# Both bracketed segments are optional, because both are optional in the files
# the convention actually produces: dated_path() emits a time only when
# hms = TRUE, and only documents carry a manual major version. The extension is
# not optional -- see the strictness note below.
#
# dated_path() writes names in this grammar; parse_dated_filename() reads them
# back, so the writer and the reader live in one file. Internal on purpose:
# it is a shared contract between icu functions, not a user-facing tool.
# new_main() is its first consumer (the version probe has to recognize
# `{stem}_vN` to increment past it); retire() will be its second, needing the
# date and time segments to order a group.
#
# Nothing here touches the filesystem. It parses names, not files on disk.

parse_dated_filename <- function(file_name) {

  stopifnot(
    'file_name must be character' = is.character(file_name)
  )

  # Anchored and strict about every segment, because non-participation is the
  # safe failure mode: a near-miss name (`figure_1a_2026_08-22.png`) is
  # reported as unparsed and left alone, never reinterpreted into something
  # close enough to act on. Requiring an extension is part of that -- an
  # extensionless `main_v1_2026-08-23` is as likely to be a directory.
  #
  # The stem is lazy so `main_v1_2026-08-23` parses as stem "main", version 1,
  # rather than stem "main_v1" with the version segment skipped.
  pattern <- paste0(
    '^(.+?)',                             # stem
    '(?:_v([0-9]+))?',                    # optional _vN
    '_([0-9]{4}-[0-9]{2}-[0-9]{2})',      # date
    '(?:_([0-9]{2}-[0-9]{2}-[0-9]{2}))?', # optional _HH-MM-SS
    '$'
  )

  # Grouping is per-directory, so a stem never carries a directory with it
  name <- basename(file_name)
  ext  <- tools::file_ext(name)
  base <- tools::file_path_sans_ext(name)

  parts <- regmatches(base, regexec(pattern, base))

  # regexec() gives back a zero-length vector for a name that does not match at
  # all, and "" for an optional group that was not used; both become NA here
  field <- function(i) {
    vapply(
      parts,
      function(p) if (length(p) == 0L) NA_character_ else p[[i + 1L]],
      character(1)
    )
  }

  stem    <- field(1)
  version <- field(2)
  date    <- field(3)
  time    <- field(4)

  version[!is.na(version) & !nzchar(version)] <- NA_character_
  time[!is.na(time) & !nzchar(time)]          <- NA_character_

  # A name can match the shape and still name no real day (2026-02-30) or no
  # real time (25-00-00). Strict means strict: those do not participate either.
  day <- as.Date(date, format = '%Y-%m-%d')

  parsed <-
    !is.na(stem) &
    nzchar(ext) &
    !is.na(day) &
    (is.na(time) | !is.na(strptime(time, format = '%H-%M-%S')))

  stem[!parsed]    <- NA_character_
  version[!parsed] <- NA_character_
  day[!parsed]     <- as.Date(NA)
  time[!parsed]    <- NA_character_
  ext[!parsed]     <- NA_character_

  data.frame(
    file_name = file_name,
    stem      = stem,
    version   = as.integer(version),
    date      = day,
    time      = time,
    ext       = ext,
    parsed    = parsed,
    stringsAsFactors = FALSE
  )
}


# --- Retiring superseded files ----------------------------------------------

#' Sweep superseded dated files into old/
#'
#' Groups the dated files in a directory by stem and extension, keeps the most
#' recent of each group where it is, and moves the rest into an `old/`
#' subdirectory. Prints the plan and asks before moving anything, then leaves a
#' record of what it moved.
#'
#' @param path A single, non-`NA` character string naming an existing
#'   directory: the directory to sweep. Defaults to the working directory.
#' @param action A single string, one of `"ask"`, `"plan"` or `"move"`.
#'   `"ask"`, the default, prints the plan and then asks whether to proceed;
#'   `"plan"` prints the plan and moves nothing; `"move"` moves without asking.
#'   See the Asking section for what happens when there is no one to ask.
#' @param ignore A character vector of stems that never participate in a
#'   sweep. Defaults to `"retire_migration"`, the stem of the log described
#'   below, so sweeping an `old/` directory leaves its own records alone. Pass
#'   `character()` to sweep everything.
#'
#' @details
#' This is the counterpart to [new_main()]'s write-only contract. Creating
#' `main_v3` leaves `main_v2` where it is; `retire()` is the only thing that
#' moves a file to `old/`, replicating by hand what git would otherwise do.
#'
#' Files are grouped by stem and extension, so `main.qmd` documents and
#' `main.html` renders are separate groups and never compete. Only names that
#' speak the dated-file grammar participate -- see [dated_path()] for the
#' grammar itself. A name that does not parse is left exactly where it is and
#' reported as `ignored`; so is a *directory*, even one whose name parses
#' cleanly, which is why `old/` never sweeps itself.
#'
#' @section Which file survives:
#' Within a group, the survivor is chosen on **version first, then date, then
#' time**, and a missing segment sorts as older. So a versioned file always
#' outranks an unversioned one, whatever the dates say:
#'
#' \preformatted{
#'   figure_1a_v2_2026-08-23.png   <- keeps
#'   figure_1a_2026-08-24.png      -> old/, despite being a day newer
#' }
#'
#' That is deliberate. A version number is an explicit statement that one file
#' supersedes another; a date only records when a file happened to be started.
#' The consequence is worth knowing before you answer the prompt, which is why
#' the plan reports the version, date and time it sorted on.
#'
#' @section Asking:
#' `action = "ask"` prints the plan and then asks `proceed? (Y/n)`. A bare
#' Enter, `y`, `Y` or `yes` proceeds; **everything else declines**, including
#' input that is neither. There is one read and no loop, so ambiguity always
#' resolves toward not moving, and a function that moves files can never sit
#' holding the console.
#'
#' When there is no one to ask -- under `Rscript`, `knitr`, or `R CMD check` --
#' `"ask"` prints the plan, moves nothing, and says so. This is deliberately
#' not an error: an unattended `retire()` should be inert rather than fatal,
#' and it is the same outcome as `action = "plan"`.
#'
#' @section The migration log:
#' A real run that moves at least one file writes
#' `retire_migration_{date}_{time}.txt` into `old/`, so a sweep can be undone
#' by hand. Nothing is written by `"plan"`, by a declined prompt, or by a run
#' that moved nothing -- a run that changes nothing leaves nothing behind, and
#' that is what keeps a second run a no-op.
#'
#' The file is a `#`-commented header followed by a two-column tab-separated
#' table, so it reads either way:
#'
#' \preformatted{
#'   # icu::retire() 2026-08-30 14:22:01
#'   # swept: output/
#'   # moved: 2  skipped: 1  failed: 0
#'   # skipped (already in old/): figure_1a_2026-08-24.png
#'   from	to
#'   main_v1_2026-08-21.qmd	old/main_v1_2026-08-21.qmd
#'   main_v2_2026-08-23.qmd	old/main_v2_2026-08-23.qmd
#' }
#'
#' Only files that actually moved appear in the table, so every row of it is
#' reversible with no filtering step:
#'
#' \preformatted{
#'   m <- read.delim(log, comment.char = '#')
#'   file.rename(file.path('output', m$to), file.path('output', m$from))
#' }
#'
#' Skipped and failed files are named on the header lines instead, since they
#' are the rows with nothing to undo but the most to explain. Paths are
#' recorded relative to the swept directory, so moving the project does not
#' invalidate the record.
#'
#' The log's own stem is in `ignore` by default, which is why sweeping an
#' `old/` directory does not sweep its logs. If writing it fails the failure is
#' a warning, never an error: the files have already moved, and erroring would
#' imply they had not.
#'
#' @section Never overwriting:
#' If a file's name is already taken in `old/` -- possible when something was
#' restored and then re-retired -- that file is **skipped with a warning** and
#' left in place. It is not clobbered, and it does not stop the rest of the
#' sweep: one stale name should not hold routine housekeeping hostage, and a
#' skipped file goes on warning about itself every run until it is dealt with.
#'
#' The check is made while the plan is built rather than during the move,
#' because it cannot be delegated to [file.rename()]: on POSIX, `rename(2)`
#' replaces an existing destination silently, so a successful rename is not
#' evidence that nothing was overwritten.
#'
#' Collisions aside, the sweep is best-effort: a locked or unwritable file can
#' still fail partway, and nothing is rolled back. That is what the count in
#' the closing line is for.
#'
#' @return The plan, invisibly: a data frame with one row per entry in `path`
#'   and the columns `path`, `stem`, `ext`, `version`, `date`, `time`,
#'   `action`, `destination`. `action` is one of `"keep"`, `"retire"`,
#'   `"skipped"` or `"ignored"`, and `destination` is `NA` except on `retire`
#'   rows. The parsed fields are carried so that a surprising decision can be
#'   read off the plan rather than reconstructed.
#'
#'   The same frame comes back whatever `action` was and whatever you answered:
#'   a `retire` row means the file lost its group, not that it moved. The log
#'   in `old/` is the on-disk record of what actually moved.
#'
#' @examples
#' dir <- tempfile()
#' dir.create(dir)
#'
#' file.create(file.path(dir, c(
#'   'main_v1_2026-08-21.qmd',
#'   'main_v2_2026-08-22.qmd',
#'   'notes.txt'
#' )))
#'
#' # Print the plan, move nothing
#' retire(dir, action = 'plan')
#'
#' # Do it for real, without being asked
#' plan <- retire(dir, action = 'move')
#' plan$action
#'
#' list.files(dir)
#' list.files(file.path(dir, 'old'))
#'
#' \dontrun{
#' # The default prints the plan and then asks
#' retire(dir)
#' }
#'
#' unlink(dir, recursive = TRUE)
#'
#' @export
retire <- function(path = '.', action = 'ask', ignore = 'retire_migration') {

  stopifnot(
    'path must be length 1'                   = length(path) == 1,
    'path must be character'                  = is.character(path),
    'path must not be NA'                     = !is.na(path),
    'path must be an existing directory'      = dir.exists(path),
    'action must be length 1'                 = length(action) == 1,
    'action must be character'                = is.character(action),
    'action must not be NA'                   = !is.na(action),
    'action must be one of ask, plan or move' =
      action %in% c('ask', 'plan', 'move'),
    'ignore must be character'                = is.character(ignore),
    'ignore must not be NA'                   = !anyNA(ignore)
  )

  old_dir <- file.path(path, 'old')
  full    <- file.path(path, list.files(path))
  parsed  <- parse_dated_filename(full)

  # Directories are excluded explicitly rather than left to the grammar. An
  # extension is required to parse, but `analysis_2026-08-23.old` is a
  # perfectly parseable *directory* name, and list.files() returns directories
  # alongside files -- so without this, retire() would rename a folder. It is
  # also what keeps old/ itself out of its own sweep.
  #
  # `ignore` is the third exclusion, and the only one by name: it is how the
  # migration log written below stays out of a sweep of the directory it lives
  # in, without needing a filename that deliberately breaks the grammar.
  participates <-
    parsed$parsed &
    !dir.exists(full) &
    !(parsed$stem %in% ignore)

  plan <- data.frame(
    path        = full,
    stem        = parsed$stem,
    ext         = parsed$ext,
    version     = parsed$version,
    date        = parsed$date,
    time        = parsed$time,
    action      = rep_len('ignored', length(full)),
    destination = rep_len(NA_character_, length(full)),
    stringsAsFactors = FALSE
  )

  # A file that does not participate carries no parsed fields, so an `ignored`
  # row cannot be mistaken for one that was weighed and lost
  plan$stem[!participates]    <- NA_character_
  plan$ext[!participates]     <- NA_character_
  plan$version[!participates] <- NA_integer_
  plan$date[!participates]    <- as.Date(NA)
  plan$time[!participates]    <- NA_character_

  idx <- which(participates)

  if (length(idx) > 0) {

    # NA sorts as oldest in both optional segments: an unversioned file loses
    # to any versioned one, and a timeless name loses to a stamped one. -1
    # rather than 0, since `_v0` is a name the grammar accepts.
    version_key <- ifelse(is.na(plan$version[idx]), -1L, plan$version[idx])
    date_key    <- as.integer(plan$date[idx])
    time_key    <- ifelse(is.na(plan$time[idx]), '', plan$time[idx])

    # Grouped, then newest first within each group. Mixed sort directions
    # alongside a character key need the radix method.
    o <- order(
      plan$stem[idx], plan$ext[idx], version_key, date_key, time_key,
      decreasing = c(FALSE, FALSE, TRUE, TRUE, TRUE),
      method     = 'radix'
    )

    ranked <- idx[o]
    stems  <- plan$stem[ranked]
    exts   <- plan$ext[ranked]

    # The first row of each group is the survivor. Detecting the boundary on
    # the sorted vectors avoids inventing a separator character to paste a
    # grouping key out of -- a stem can contain anything.
    n      <- length(ranked)
    newest <- c(
      TRUE,
      stems[-1] != stems[-n] | exts[-1] != exts[-n]
    )

    plan$action[ranked] <- ifelse(newest, 'keep', 'retire')

    # Participants in plan order, then the rest: the frame reads the way the
    # plan prints, group by group
    plan <- plan[c(ranked, setdiff(seq_len(nrow(plan)), ranked)), ]
    row.names(plan) <- NULL
  }

  retiring <- which(plan$action == 'retire')

  if (length(retiring) > 0) {
    plan$destination[retiring] <- file.path(
      old_dir, basename(plan$path[retiring])
    )

    # Never overwrite. This has to be an explicit check: on POSIX, rename(2)
    # replaces an existing destination silently, so file.rename() coming back
    # TRUE is not evidence that nothing was clobbered.
    collides <- file.exists(plan$destination[retiring])

    plan$action[retiring[collides]]      <- 'skipped'
    plan$destination[retiring[collides]] <- NA_character_
  }

  skipped <- which(plan$action == 'skipped')

  if (length(skipped) > 0) {
    # Loud, and loud again on every subsequent run: a skipped file is work
    # left undone, and the plan is not something anyone re-reads
    warning(
      'already in ', old_dir, ', skipped: ',
      paste(basename(plan$path[skipped]), collapse = ', ')
    )
  }

  moving <- which(plan$action == 'retire')

  if (length(moving) == 0) {
    cat('nothing to retire in ', path, '\n', sep = '')
    return(invisible(plan))
  }

  # 'move' is the only action that does not show the plan first: you asked for
  # the sweep, not for a report on it
  if (action != 'move') {
    shown <- plan[plan$action != 'ignored', ]

    cat('retire plan for ', path, '\n', sep = '')
    cat(sprintf('  %-7s %s\n', shown$action, basename(shown$path)), sep = '')

    ignored <- sum(plan$action == 'ignored')

    if (ignored > 0) {
      cat('  ', ignored, ' not recognized\n', sep = '')
    }
  }

  # Shared by both ways of stopping short of the move, so the two lines cannot
  # drift apart
  count <- paste0(
    length(moving), if (length(moving) == 1) ' file' else ' files',
    ' to ', old_dir
  )

  if (action == 'plan') {
    cat(
      'plan only: nothing moved; re-run with action = "move" to move ',
      count, '\n',
      sep = ''
    )

    return(invisible(plan))
  }

  if (action == 'ask') {

    # Through a wrapper, never interactive() inline: it reports on the session
    # rather than the call stack, so it is TRUE when devtools::test() runs from
    # a console and this branch would block the suite on a prompt nothing
    # answers. Same seam, same reason, as rstudio_available().
    if (!interactive_session()) {
      cat(
        'not an interactive session: nothing moved; ',
        're-run with action = "move" to move ', count, '\n',
        sep = ''
      )

      return(invisible(plan))
    }

    if (!ask_yes_no('proceed? (Y/n) ')) {
      cat('declined: nothing moved\n')

      return(invisible(plan))
    }
  }

  # Only now, and never before the answer: creating old/ is touching the
  # directory
  if (!dir.exists(old_dir)) {
    dir.create(old_dir)
  }

  moved <- file.rename(plan$path[moving], plan$destination[moving])

  if (!all(moved)) {
    warning(
      'could not move: ',
      paste(basename(plan$path[moving][!moved]), collapse = ', ')
    )
  }

  cat(
    'retired ', sum(moved), if (sum(moved) == 1) ' file' else ' files',
    ' to ', old_dir,
    if (length(skipped) > 0) paste0(' (', length(skipped), ' skipped)'),
    '\n',
    sep = ''
  )

  # A run that moved nothing writes nothing, which is what keeps a second run a
  # no-op. Moves that failed are already reported by the warning above.
  if (any(moved)) {
    log_file <- write_migration_log(
      path    = path,
      old_dir = old_dir,
      from    = basename(plan$path[moving][moved]),
      skipped = basename(plan$path[skipped]),
      failed  = basename(plan$path[moving][!moved])
    )

    # Named on its own line rather than appended: an undo record you have to
    # know about is one you will not use, and the path is there to be copied
    if (!is.na(log_file)) {
      cat('log: ', log_file, '\n', sep = '')
    }
  }

  invisible(plan)
}


# --- Asking, and the record left behind --------------------------------------

# Whether there is a human at the console to answer a prompt. A wrapper rather
# than the call written inline, for the same reason rstudio_available() is one:
# interactive() reports on the *session*, not the call stack, so it is TRUE
# when devtools::test() is run from a console. A bare retire() in the suite
# would take the asking branch for real and block forever. interactive() is
# also a primitive and cannot be mocked directly, so this binding is the only
# seam the tests have.
interactive_session <- function() {
  interactive()
}

# One read, no loop. The parsing is split out so it can be tested without
# mocking base::readline(); this half is the seam retire()'s tests mock.
ask_yes_no <- function(prompt) {
  is_yes(readline(prompt))
}

# Enter, y, Y or yes proceeds; everything else declines, including input that
# is neither. Ambiguity resolves toward not moving: a slip costs one retyped
# call, and the alternative costs a sweep you did not agree to.
is_yes <- function(answer) {
  answer <- trimws(answer)

  !nzchar(answer) || tolower(answer) %in% c('y', 'yes')
}

# The record retire() leaves behind, so a sweep can be undone by hand.
#
# The name is built with dtp() rather than assembled here, because the
# {stem}_{date}_{time}.{ext} grammar lives in one place -- and the header's
# timestamp is then read back out of that name with parse_dated_filename(),
# rather than formatted from a second clock reading that could disagree with it
# across a second boundary.
#
# Paths are recorded relative to the swept directory: absolute ones would break
# the moment the project moved, and the sweep is per-directory anyway, so the
# basename is the whole story.
write_migration_log <- function(path, old_dir, from, skipped, failed) {

  name <- dtp('retire_migration.txt')
  file <- file.path(old_dir, name)

  stamp <- parse_dated_filename(name)
  when  <- paste(stamp$date, gsub('-', ':', stamp$time))

  header <- c(
    paste0('# icu::retire() ', when),
    paste0('# swept: ', path),
    paste0(
      '# moved: ', length(from),
      '  skipped: ', length(skipped),
      '  failed: ', length(failed)
    )
  )

  # Named, not merely counted: "skipped: 1" names no file six months later,
  # and these are the rows with nothing to undo but the most to explain. The
  # lines are omitted entirely when empty, so the usual log is a three-line
  # header and a table.
  if (length(skipped) > 0) {
    header <- c(
      header,
      paste0('# skipped (already in old/): ', paste(skipped, collapse = ', '))
    )
  }

  if (length(failed) > 0) {
    header <- c(
      header,
      paste0('# failed: ', paste(failed, collapse = ', '))
    )
  }

  # Only moves go in the table, so every row of it is reversible without a
  # filtering step -- and a filter that gets forgotten is a rename attempted
  # against a file that never moved
  lines <- c(
    header,
    paste('from', 'to', sep = '\t'),
    paste(from, file.path('old', from), sep = '\t')
  )

  written <- tryCatch(
    {
      writeLines(lines, file)
      TRUE
    },
    error   = function(e) FALSE,
    warning = function(w) FALSE
  )

  # The files have already moved by the time this runs, so a failure here is a
  # warning: erroring would imply they had not
  if (!written) {
    warning('could not write the migration log to ', file)

    return(NA_character_)
  }

  file
}
