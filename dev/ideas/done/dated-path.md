# Dated/versioned path helper

**Status:** shipped as `dated_path()` in R/paths.R (tests in
tests/testthat/test-paths.R). Kept for the rejected alternatives below, which
qmd-creator and project-scaffold will want.

One thing came out differently than the design assumed: `tools::file_ext()`
returns `""` for a leading-dot name, so `.gitignore` is treated as
extensionless and the stamp appends (`.gitignore_2026-08-15`) rather than the
whole name being read as an extension. Better behavior than expected; pinned
by a test.

**Two things below are now out of date, deliberately — read them as the
original design, not the current contract:**

1. *"Pure string function"* — no longer strictly true. A `print` argument
   (default `TRUE`) `cat()`s the assembled path to stdout, so there is one
   side effect. Everything the purity argument was actually load-bearing for
   still holds: no filesystem reads, no TOCTOU window, no collision logic, no
   temp-dir test regime.

   `cat()` was chosen over `message()` deliberately, and the reason matters
   for qmd-creator: the point of printing is that a **rendered document states
   which files the render produced**. A `message()` does reach a knitted
   document by default, but `message: false` in the YAML — the customary way
   to hide `library(tidyverse)` startup chatter, which qmd-creator's template
   will want — would silence the file record along with it. Nothing
   conventionally suppresses stdout. Verified by knitting a scratch .Rmd:
   the path appears in the output under both default and `message = FALSE`
   chunk options. `print()` was rejected on cosmetics (`[1]` and quotes).

   Corollary, found the same way: when `print = TRUE` the value is returned
   **invisibly**. A visible return made a bare call in a chunk render the path
   twice, once from `cat()` and once from auto-printing. The contract is now
   "reported exactly once" — via stdout when printing, via the visible return
   otherwise.
2. *"Keeps the signature to three obvious arguments"* — it is four now, and
   there are four shorthands rather than the original two:
   `dp`/`dtp` (quiet) and `dpp`/`dtpp` (printing), where the second `p` means
   print. `dt` was ruled out at naming time: it is `stats::dt()`, attached in
   every session. Checked `dp`/`dtp`/`dpp`/`dtpp` against every installed
   package's exports — no collisions.

The printing default is the one asymmetry worth remembering: `dated_path()`
prints, but `dp()` does not, so `dp()` is *not* `dated_path()` with its
defaults. The reasoning is that the two-letter forms exist for inline use
inside a busy call, where quiet is the common want, and the `p` is how you ask
for the record.

## Motivation

Output files are date-stamped so re-runs never clobber historic outputs:

```r
ggsave(plot, glue::glue('output/figure_1a_{Sys.Date()}.png'))
```

This is verbose and the *intent* (timestamping) isn't visible. Target usage:

```r
ggsave(plot, dated_path('output/figure_1a.png'))
# -> "output/figure_1a_2026-08-10.png"
```

## Design notes

**Name:** `dated_path()`. The path is the noun returned; the date is the
mechanism. Avoids `stamp` (collides conceptually with `lubridate::stamp()`,
which builds date-*formatting* functions).

**Signature:** `dated_path(file_name, ymd = TRUE, hms = FALSE)`.

**Output grammar:**

```
<stem>[_<YYYY-MM-DD>][_<HH-MM-SS>].<ext>

dated_path('output/figure_1a.png')                   #> output/figure_1a_2026-08-10.png
dated_path('output/figure_1a.png', hms = TRUE)       #> output/figure_1a_2026-08-10_12-23-01.png
dated_path('output/figure_1a_v3.png', hms = TRUE)    #> output/figure_1a_v3_2026-08-10_12-23-01.png
dated_path('output/fig.png', ymd = FALSE, hms = TRUE)  #> output/fig_12-23-01.png
```

**No version argument, and no collision detection.** The original draft had
`_vN` as an auto-incremented collision counter, which required reading the
target directory. Rejected in favor of two separate mechanisms:

- *Major versions are manual and semantic.* `v3` means "the third iteration of
  this figure", set by the user. It is simply part of the stem the caller
  types (`'output/figure_1a_v3.png'`), so the function needs no knowledge of
  it. This is also why version-before-date is the right order: an automatic
  counter has no semantic tie to the file, so sorting by it is noise, but a
  manual major version is a real grouping — sort by which version of the
  thing it is, then chronologically within that.
- *Intraday uniqueness is `hms = TRUE`.* This is what the collision counter
  actually existed to solve, and a timestamp solves it without touching disk.

Consequences, all of them good:

- `dated_path()` is a **pure string function**. No filesystem reads, no
  TOCTOU race between the returned path and the eventual write, no collision
  warning to design, no temp-dir testing regime. The earlier note that this
  would be "the first function in icu to touch the filesystem" no longer
  applies — it still gets its own R/paths.R, but only as a topic file.

**Accepted trade-off:** with `hms = FALSE`, same-day re-runs still clobber.
This is deliberate — within a single day you usually *want* to overwrite this
morning's `figure_1a` rather than accumulate a dozen copies across one
afternoon. `hms = TRUE` is the opt-in for deliberately kept intraday
snapshots.

**No injectable stamp function.** Rejected the `stamp_fn` argument that would
have mirrored `round_to_nearest(round_func =)`. Base R inside the function:
`Sys.time()`, formatted with `format()`. Keeps the signature to three obvious
arguments, and fixing the formats means the output is filesystem-legal by
construction (no colons from `%H:%M:%S`, which are illegal in Windows
filenames). Cost: tests can't pin an exact string — see Testing notes.

**Formats are fixed**, not user-supplied: `%Y-%m-%d` and `%H-%M-%S`, joined to
the stem and to each other with `_`. So `..._2026-08-10_12-23-01.png`.

**Call `Sys.time()` exactly once** and feed both `format()` calls from it. Two
separate calls could straddle midnight and emit a date and a time from
opposite sides of it.

**Extensions:** date/time insert **before** the extension, not appended after.
`tools::file_ext()` is base R (no new dependency). Follow it exactly for
double extensions — only the final component counts, so `data.tar.gz` becomes
`data.tar_2026-08-10.gz`. Ugly but predictable, one rule, pinned by a test. A
path with no extension gets the stamp appended at the end.

**`ymd = FALSE, hms = FALSE` is an error**, not a silent passthrough. A
function named `dated_path()` that stamps nothing is a contradiction; a caller
who wants no stamp can decline to call it. Rejected the alternative of
returning `file_name` unchanged for programmatic toggling.

**Not vectorized** — every argument is length 1, enforced. There is no longer
a correctness reason to forbid length-n (the collision logic that couldn't
vectorize is gone), so this is a deliberate contract-narrowing for safety:
`ggsave()` and friends take one path, and a silently recycled vector of paths
is a worse failure than an error.

## Validation (per package conventions)

- `file_name`: character, length 1, not NA.
- `ymd`, `hms`: logical, length 1, not NA.
- `'at least one of ymd and hms must be TRUE' = ymd || hms`.

## Testing notes

- **No temp directory needed** — the function is pure. Plain string
  assertions.
- Without an injectable stamp, tests can't assert an exact string. Assert
  against a regex (`_\\d{4}-\\d{2}-\\d{2}\\.png$`), or compute the expected
  date inline with `Sys.Date()` in the test. The inline-comparison form has a
  vanishingly rare midnight-boundary flake; the regex form doesn't.
- Pin: insertion point before the extension, double-extension behavior,
  no-extension behavior, three of the four `ymd`/`hms` combinations plus the
  error on the fourth, and the separator characters.
- Input validation section per house convention: each `stopifnot()` message
  asserted with `expect_error()`.

## Related

- `glue` re-export — **shipped** (see dev/ideas/done/reexport-glue.md). `glue`
  is already in Imports, so this can use `glue::glue()` internally with no
  DESCRIPTION change.
- **qmd-creator's dependency has changed shape.** It still wants "if `main_v2`
  exists, increment and warn" — a manual version bump (draft 2 of the
  document), where you want one file per version, not one per second. Since
  `dated_path()` now has no versioning at all, qmd-creator owns its own
  probe-and-increment logic and calls `dated_path()` only to assemble the
  name. The shared piece is name assembly, not collision handling. Update
  qmd-creator.md and the ordering note in dev/ideas/README.md when this ships.
- project-scaffold sits downstream of both; unaffected by this change.
