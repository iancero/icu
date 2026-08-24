# new_project() — one-call consulting project scaffolder

**Status:** shipped as `new_project()` in R/project.R (tests in
tests/testthat/test-project.R); the `.Rproj` template installed at
inst/templates/project.Rproj. Last of the implementation wave. The spec
below is the design and held up as written; what it left to implementation
is recorded under "As shipped" immediately after this block. **No open
questions remain** — the last one (an renv opt-in argument) was closed
2026-08-24 with a no; see Reproducibility.
**Shipped file:** R/project.R (the working name was kept — the area is
projects, and the file is named for the area, not the function)
**Depended on:** new_main() — **shipped 2026-08-23**, see done/new-main.md;
call it as `new_main(path = <project dir>, open = FALSE)` to seed main_v1,
and note that it returns the created path invisibly and creates nothing
else. conventions_md() — **shipped 2026-08-23**, see done/conventions-md.md
— seeds ai/conventions.md, but **its default path is `'.'`, so the scaffold
must pass the ai/ directory explicitly**: `conventions_md(file.path(project,
'ai'))`, called **after** creating that directory, since it never creates
one. Expect it to announce the path it wrote. Nothing is outstanding: both
dependencies now exist. meeting()/meeting_block() is **not** a dependency of
the
scaffold: the template ships an empty Project Background and the first
block is typed by hand at the kickoff, like every later one. Outermost of
the filesystem functions; orchestrates, owns no logic itself.

## As shipped (implementation decisions, 2026-08-23)

1. **Signature: `new_project(name)`.** One required argument and nothing
   else, as specced. No `path` argument — the destination is the option's
   job, and a second way to say it would undercut "the call works the same
   from wherever you happen to be." No `open` argument either, unlike
   new_main(): new_main() needed one because *this* function is a caller
   that must suppress the open, and nothing calls new_project(). Tests
   reach the no-editor path through the `rstudio_available()` seam, the
   way meeting()'s do.
2. **`.Rproj` content ships as a template**, inst/templates/project.Rproj,
   copied verbatim and renamed to the folder name — the same posture as
   main.qmd and conventions.md, so what a new project's editor settings
   are is a content edit plus a reinstall, with no R to touch. It is the
   package's own icu.Rproj minus the `BuildType: Package` block, which
   keeps `LineEndingConversion: Posix` in every new project (see
   ../chores/line-endings.md for why that matters). Note the near-miss:
   `.Rbuildignore` is scoped to `^icu\.Rproj$`, not a blanket
   `^.*\.Rproj$`, so the template does ship. A blanket pattern would have
   silently excluded it from the built package.
3. **`icu.projects_dir` set but pointing at a directory that does not
   exist → create it and proceed, silently** (decision: Ian, 2026-08-23;
   the spec covered only the unset case). The option is a statement of
   where projects go, and a Box folder that has not synced onto this
   machine yet is the ordinary reason it is missing. Not a fallback, so
   not a warning. Rejected: erroring (leaves you with no project
   mid-meeting, against the north star), and treating it as unset (throws
   away a destination you did configure).
4. **An option value that is not a usable path at all** — not a length-1,
   non-NA, non-empty character string — **is treated as an unset one**:
   loud getwd() fallback, with the warning saying "not a single directory
   path" rather than "not set". There is nothing to take at its word, and
   still no reason to end the meeting without a project. This is the one
   sub-case of (3) that could not follow it, since you cannot `dir.create()`
   a number.
5. **The unset-option warning points at the `.Rprofile` option, not at
   `icu_setup()`** (decision: Ian, 2026-08-23), because icu_setup() is
   still backlog — the specced text would have told you mid-meeting to
   call a function that does not exist. The warning names what went wrong,
   the path the project landed in, and `options(icu.projects_dir = ...)`.
   When icu_setup() ships, adding it is a one-line text edit plus a test
   update; icu-setup.md carries the note.
6. **Name validation** (parked item 2, now settled): character, length 1,
   non-NA, non-empty — plus **no path separator**. Permissive otherwise,
   as the parked item leaned. The separator is the one exception because
   it is not a strictness question: `smith/delirium` would put the project
   somewhere other than the projects directory, which makes it a path and
   not a name.
7. **Failure is loud, and there is no rollback.** Each `dir.create()` and
   the `.Rproj` copy is checked and errors by name if it fails, leaving a
   partial project behind. Deliberate: cleanup code that deletes
   directories is exactly the code you do not want running unattended near
   real work, and the collision check has already established that nothing
   here existed a moment ago.
8. **Ordering is load-bearing**: skeleton directories first, then the
   `.Rproj`, then `new_main(path, open = FALSE)`, then
   `conventions_md(file.path(project, 'ai'))` — which needs `ai/` to
   already exist, since it never creates one. The fallback warning is
   raised *after* creation succeeds, so it can name a project that really
   exists and cannot fire on a run that errored out.
9. **Output**: conventions_md()'s announcement is let through, as the spec
   anticipated, and it is the only thing on stdout — new_main() is silent
   by design, which is what makes that one line legible. Outside RStudio
   the no-open notice goes out through `message()` rather than the `cat()`
   dated_path() and conventions_md() use: their reason is surviving a
   document's `message: false`, and nobody scaffolds a project from inside
   a render.
10. **Return value:** the project directory, invisibly, per house
    convention. The tests assert the tree, not the return value, as the
    spec required.

## Motivation and design north star

The call happens **mid-meeting**: a colleague's request is turning into a
project in real time, and the project must exist before the meeting ends.

```r
icu::new_project('smith_delirium_drug_r01')
```

One required argument, good defaults for everything, nothing interactive.
Every design choice below bends toward "fast, safe, and recoverable when
called by someone who is half-listening to a meeting."

Context that shaped everything: projects live on HIPAA-compliant Box, so
**no git** (versioning is save-as + retire()-to-old/), and the AI
collaboration posture is **chat-first** (Claude sees code and reviewed
aggregate output only, never data — see "AI workflow" below).

## Resolved spec

### Naming

- Folder name = argument + `_` + current year:
  `smith_delirium_drug_r01_2026`.
- Year marks *initiation* vintage — when Smith returns in 2028 with the
  R&R, the folder still says 2026.
- Year at the END (not front): the projects folder sorts alphabetically by
  colleague/topic, grouping a colleague's projects across years. You find
  projects by *who*, not *when*. (Deliberate; chronological sort was
  considered and rejected.)
- The folder name deliberately does NOT speak the icu filename grammar —
  year only, never parsed by retire(). Confirmed intended.
- **Collision → error, never increment.** Projects aren't versioned
  artifacts; an existing `smith_..._2026` means a double-call or a name
  that should differ semantically (`_aim2`, `_rr`).

### Location

- Created under `getOption('icu.projects_dir')` regardless of current
  working directory.
- **Unset option → create in `getwd()`, LOUDLY** (warning + printed path).
  Rationale (Ian's, and better than the error alternative): mid-meeting, a
  project in the wrong place is a ten-second fix afterward; an error means
  no project at all. Wrong-but-loud beats right-but-absent.
- icu_setup() (see icu-setup.md) is the guided way to get the option set;
  the warning text should point at it. **Superseded at implementation**:
  icu_setup() is still backlog, so the shipped warning points at the
  `.Rprofile` option directly rather than at a function that does not
  exist. See "As shipped" item 5.
- The set-but-missing and set-but-unusable cases were not covered here;
  see "As shipped" items 3 and 4.

### Opening

- Writes a `.Rproj`; opens the project via
  `rstudioapi::openProject(path, newSession = TRUE)` — **new window**,
  old session untouched (you may need something from it mid-meeting).
- **main_v1 does NOT auto-open in the new session; accept one click**
  (decision 2026-08-23, reversing a brief auto-open decision the same
  day). The auto-open mechanism would be a self-removing project-local
  `.Rprofile` hook, which carries a sharp edge: a project `.Rprofile`
  replaces the user-level one, where `icu.projects_dir` / `icu.author`
  live, so an unguarded hook silently breaks the options in exactly the
  first session. Solvable but magic; one click in the new window isn't
  worth it. Recorded here so the trade is visible if auto-open tempts
  again.
- new_main() is still called with `open = FALSE` — opening in the
  *current* session would hit the wrong (meeting-time) window. The
  `open` argument survives the reversal: tests need it regardless.
- rstudioapi in Suggests; no-RStudio fallback = create everything, don't
  open the project, say so.

### Skeleton

```
smith_delirium_drug_r01_2026/
├── ai/                 <- workbench of the AI loop (see below)
│   └── conventions.md  <- seeded via conventions_md()
├── background/         <- read by YOU: codebooks, data dictionaries,
│                          surveys, their manuscripts. Arrives from
│                          outside; never written by the project.
├── data/               <- read by CODE: data files only, flat (no raw/
│                          derived split — Ian almost never caches).
│                          Arrives from outside; never written by the
│                          project. Derived outputs go to output/.
├── manuscript/         <- the co-authored paper's track-changes
│                          lifecycle (papers are written natively in
│                          Word; see done/new-main.md)
├── old/                <- flat dropzone for superseded versions;
│                          retire()'s destination
├── output/             <- generated by code; everything dated via
│                          dpp(); figures + tables; deliverables leave
│                          from here
├── transcripts/        <- save-and-drop Zoom transcripts, no renaming
│                          (see "Transcripts" below)
├── main_v1_2026-08-23.qmd   <- via new_main(open = FALSE); Project
│                               Background EMPTY — meeting() fills it
└── smith_delirium_drug_r01_2026.Rproj
```

Taxonomy that assigns every folder its meaning — worth preserving because
it answers "where does X go" questions by rule rather than memory:

- **Inboxes** (arrive from outside, never written by the project):
  `data/` (read by code), `background/` (read by you), `transcripts/`
  (raw material for AI processing).
- **Outputs** (written by the project): `output/` (by code, dated),
  `old/` (by retire()).
- **Workbenches** (read and written by both you and collaborators/AI):
  `manuscript/` (you + co-authors), `ai/` (you + AI loop) — the two
  folders that break the inbox/output split, deliberately.

Decisions logged with the skeleton:

- **`deliverables/` rejected**: duplicates output/; "what was sent when"
  is tracked by ticking Requests checkboxes in the meeting log, not by
  copying files (copies drift).
- **`manuscript/` included despite papers being the less-common case**:
  common enough, an empty folder is free, and nothing else in the
  taxonomy can house a track-changes round-trip (it's neither inbox nor
  code output).
- **`background/` over `reference/`/`docs/`**: it's the word Ian reaches
  for; covers the manuscript-context case that "reference" doesn't;
  alphabetizes first. Data dictionary lives HERE (who-reads-it rule: it's
  read by you/AI, not by code), narrowing data/ to data files only.
- **Flat `data/`**: raw/derived split rejected because caching is rare;
  the raw/ protection is replaced by the invariant (never written by the
  project), which must be *stated* somewhere visible — README vs. the
  template's Data Provenance section, parked, decide at implementation.
- **`ai/` is an experiment**: created by default, holding conventions.md
  at birth; further contents (codebook, synthetic data, drafts awaiting
  promotion into main_vX) to be earned over months of real use.
  codebook_md() and synthetic-data are separate backlog items, NOT part
  of project creation.

### Transcripts

Zoom names arrive as e.g.
`Tracking System Updates transcript_2026-08-19_11.31.25` — garbage prefix,
but the date/time are embedded and machine-readable. **No renaming, no
processing**: matching a transcript to its `## Meeting - 2026-08-19` log
entry is a join on date, done by eye or by an AI tool when needed.
Same-day double meetings disambiguate by timestamp, by hand, rarely.
Zoom's format happens not to parse under the icu grammar (dots in time),
so retire()'s non-participation protects this folder by accident; noted,
no coordination needed.

### The lifecycle this serves (paradigm walkthrough)

1. **Day 0, mid-meeting:** one call creates everything, opens a new
   window; click main_v1, cursor under # Project Background, `meeting()`
   — then Attendees/Notes/Requests typed as the colleague talks. (Same
   gesture as every later meeting; the template pre-seeds no block, per
   the static-template decision in new-main.md.)
2. **Between meetings:** data lands in data/, context in background/.
   Work in main_v1 under the skeleton headers; analysis sections cite the
   requesting meeting. Deliverables leave as dated files via dpp() into
   output/. Checkboxes ticked.
3. **Meeting 2:** cursor at end of log, `meeting()`, new block, new
   requests. Major revision → save-as main_v2; retire() eventually sweeps
   v1 to old/.
4. **Wrap:** render once — the session-info hook stamps the package-
   version record.
5. **2028 R&R:** folder says 2026; log says what was decided and why;
   output/ says what was delivered when; the render says which versions
   did it.

## AI workflow (posture, recorded here because it shaped the skeleton)

- **Chat-first**: data cannot be verified de-identified, so Claude works
  over chat and sees **code and reviewed aggregate output only** — never
  data files, never unreviewed console output (a pasted error or head()
  can carry raw rows), and qmd *source* not rendered output (renders can
  embed data glimpses).
- **main_vX is the context document.** A separate context.md was
  considered and rejected: the meeting log + provenance + analysis
  narrative should already BE good enough to orient an AI session, and
  the discipline of keeping it so is healthy. Session ritual: paste
  main_vX source.
- Claude Code layers (CLAUDE.md; .claude/settings.json deny rules on
  data/) were discussed: deny rules are defense-in-depth with known
  enforcement caveats, never load-bearing. Whether the scaffold ships
  them by default is PARKED (see below) given the chat-first posture.

## Reproducibility (recorded here; mechanism shipped with new_main())

- renv rejected as default: slow/unpleasant, and its many-small-files
  library is pathological inside a Box-synced folder. pak fixes install
  speed but isn't a snapshot system.
- Default insurance instead: the session-info document hook in the qmd
  template (shipped; see done/new-main.md) — render once at wrap, versions on
  record.
- Full renv (library outside Box) as an opt-in argument: **NO — closed
  2026-08-24 (Ian).** Not parked, not deferred: decided against, and
  `new_project()` will not grow an renv argument. The session-info hook is
  the reproducibility story for this paradigm, full stop.

  The reasoning that closed it: an opt-in nobody opts into is worse than
  no option at all — it costs an argument, a branch, a test, and a
  paragraph of documentation, permanently, in exchange for a capability
  that the two bullets above have already argued against using. Every
  reason renv was rejected as the default (slow, unpleasant, pathological
  library layout inside Box) still applies on the day you would reach for
  it, so the argument would sit there as a trap rather than an escape
  hatch. Nothing about it got easier by waiting.

  Reversible, and cheap if it ever comes back: an additive argument with
  a default, no restructuring. That was true while it was parked and is
  still true now — so closing it costs nothing that reopening it would
  not restore.

## Resolved 2026-08-23, second pass (formerly parked)

1. **Composition/opening**: one click accepted — main_v1 does not
   auto-open in the new session (auto-open briefly chosen, then reversed
   over the `.Rprofile`-hook sharp edge; see Opening above for the full
   trade). new_main() grows `open = TRUE` argument (specced in
   new-main.md); scaffold passes `open = FALSE`.
2. **CLAUDE.md / .claude/settings.json: SKIP.** Not shipped in the
   skeleton, consistent with the chat-first posture. Revisit only if the
   Claude Code workflow becomes real; the discussion of deny-rule layers
   above stands as the record for that day.
3. **data/ invariant lives in the template's Data Provenance section**
   (see new-main.md); the skeleton ships no README.
4. **Name: `new_project()`.** Avoids masking usethis::create_project;
   pairs with new_main(). (No known new_project export in common
   packages; confirm with the standard conflict check at implementation.)

## Parked / open questions — none left (closed 2026-08-24)

Both parked items are now decided, so this file carries no open questions
and nothing is waiting on a conversation:

1. renv opt-in argument — **closed 2026-08-24: no.** See Reproducibility
   above for the decision and the reasoning.
2. Validation specifics — settled at implementation; see "As shipped"
   item 6.

## Testing notes

- Temp dir per test with `withr::local_options(icu.projects_dir = ...)`;
  assert the full file tree, not return values.
- Collision error matched on message text; unset-option path asserts BOTH
  the warning and that creation still happened in getwd().
- Seeded contents asserted only as present (main_v1 exists, ai/
  conventions.md exists) — content is pinned in new-main.md's and
  conventions_md()'s own tests, at the layer that owns it.
- Opening RStudio windows is untestable — keep that code path thin and
  isolated (established house convention for editor/session side
  effects).
