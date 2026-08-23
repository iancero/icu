# new_main() — scaffold the house analysis document

**Status:** design resolved (2026-08-23) — ready to implement. Supersedes
qmd-creator.md (delete that file; this one carries all its resolutions plus
the naming, `open` argument, and meeting-block decisions made after it was
drafted).
**Proposed file:** R/main.R (working; or alongside paths.R family — decide
at implementation)
**Depends on:** `dated_path()` (shipped) for name assembly. `new_project()`
(see project-scaffold.md) calls this to seed new projects. No longer depends
on meeting()/meeting_block(): the template ships with an EMPTY Project
Background, and `meeting()` is the sole producer of meeting blocks (decision
2026-08-23, "maximize modularity" — see Template below).

## Motivation

One call scaffolds a new analysis document with house conventions baked in.
Named `new_main()` — not qmd_create() — because in practice it creates
`main` documents: the paired vocabulary is `new_project()` / `new_main()`.
Context: projects run **without git** (Box); versioning is
save-as-increment with retire() sweeping old versions, so the version probe
here is the versioning system, not a courtesy.

## Resolved spec

### Filename and versioning

- `main_v1_2026-08-23.qmd`; stem defaults to `main`.
- Probe the target directory for existing `{stem}_v*` files; if any exist,
  use max version + 1 and **warn** (message text pinned by test).
- **Write-only.** Creating `main_v3` leaves `main_v2` in place; archival is
  retire()'s job (separate blast radii, separate contracts).
- Name assembly via `dated_path()`.

### Grammar ownership (coordinates with retire.md)

The version probe makes this the **first consumer** of the
`{stem}[_vN]_{date}[_HH-MM-SS].{ext}` grammar. Pinned here at
implementation time: version segment optional, time segment optional.
Whether the internal `parse_dated_filename()` is factored out now or at
retire() time is an implementation choice; grammar tests live with the
parser wherever it is built.

### YAML front matter (STATIC — see Template mechanics)

- `title: "Untitled"` hardcoded; edited by hand per project. There is no
  title argument.
- `author: "Ian Cero"` hardcoded. The `icu.author` option is retired — no
  consumer remains (update icu-setup.md's inventory).
- `date: today` — render date, not creation date. The filename permanently
  carries the creation date; the YAML date stamps *this render*, which is
  what a record-of-the-analysis wants (matches the v7 exemplar's dynamic
  date).
- `format: html`, `embed-resources: true`, `toc: true`, `toc-depth: 2`.
  Deliverables leave as dated files via dpp(); the render is a *record of
  the analysis*, self-contained for Box. Depth-2 toc doubles as a meeting
  index (## Meeting headers appear in the sidebar).
- `editor: source` (resolves source-mode at the YAML level; one manual
  verification at first implementation).
- Execution options: `message: false` (the setting dated_path's cat()
  printing was designed to survive — deliberate consistency).

### Body (in order)

1. `# Project Background` — **EMPTY**. The kickoff ritual is: new project
   → open main_v1 → cursor under the header → `meeting()`. This reverses
   the earlier "opens with the first meeting block in place" decision, in
   exchange for: one habit instead of a template special case (creation-
   time and meeting-time use the identical gesture), and a block with
   exactly one producer, ever.
2. Remaining skeleton headers: `# Data Provenance`, `# Data Wrangling`,
   `# Analysis`, `# Results Summary`. (Pre-seeding sections was originally
   rejected, then reversed on evidence: the v7 exemplar shows this exact
   structure is stable across projects.)
3. **Data Provenance carries the data/ invariant** as template text
   (decision 2026-08-23): prose stating that `data/` holds only files as
   received from outside and is never written by the project — derived
   outputs go to `output/` — plus a received-files list stub (v7-style
   inventory). This is the invariant's one visible home; the skeleton
   ships no README.
4. Setup chunk (`include: false`): `library(tidyverse)` + the session-info
   document hook (below), with a do-not-remove comment carrying the
   why in the template itself. Chunk echo elsewhere stays at Quarto's
   default (true) — visible code is the point of a record. `library()` in
   generated documents is fine; the no-library rule governs icu's own
   source.

### Session info via knitr document hook

renv rejected as default (slow; many-small-files library pathological in
Box-synced folders); the insurance is a complete session record in every
render. Hook registered in the setup chunk: lives at the top
(deletion-resistant), executes and renders at the end (complete). Tested
manually 2026-08-23 by Ian; works.

```r
knitr::knit_hooks$set(document = function(x) {
  c(x, '## Session info', '```',
    capture.output(sessioninfo::session_info()), '```')
})
```

- Wrap in a collapsed `<details>` block in the template version.
- Accepted trade-off: magic (knitr internals) whose failure mode is a
  silently missing section — mitigated by a render test asserting the
  section appears. Magic confined to the template, pinned by a test.
- YAML-only alternatives ruled out (include-after-body is static; Lua
  filters run post-knitr).
- `sessioninfo` (like tidyverse) is a **template assumption**, not an icu
  dependency; say so in @details.

### Rejected: manuscript/docx template

Papers are written natively in Word (track-changes round-trip makes the
Word file the document of record). **One** template, no template argument;
add a second only if a real recurring need appears.

### Opening the file: `open` argument

- `open = TRUE` default: open via `rstudioapi::navigateToFile()` guarded by
  `rstudioapi::isAvailable()`, `utils::file.edit()` fallback. rstudioapi in
  Suggests (use_package first, per convention).
- `open = FALSE` exists for two callers: **tests** (no editor side
  effects) and **new_project()**, which suppresses this open because the
  new project lives in a NEW session, not the current one — main_v1 is
  opened there by hand (one accepted click; see project-scaffold.md).
  This function knows nothing about that; it just honors `open = FALSE`.

### Template mechanics

- Real file under `inst/templates/main.qmd`, **copied verbatim — the
  template is fully static, zero placeholders, no interpolation**
  (decision 2026-08-23, "maximize modularity"). The glue-delimiters
  question is thereby deleted, and new_main() collapses to version-probe +
  copy + open.
- A working draft of the template exists (produced in design discussion
  2026-08-23) and should be adopted as the starting inst/ file.
- Editing the template IS editing the function's output: content changes
  are template edits + reinstall (the function reads the installed copy
  via system.file()), guarded by the content/render tests. No R changes
  for content.
- Reversibility, recorded in case minds change: re-adding a placeholder
  later (title, author, anything) is additive and non-breaking — new
  argument with a default plus one line of interpolation. Deferring costs
  only the re-decision. The one placeholder that WOULD have been
  load-bearing was the first-meeting block (its header needs
  creation-day's date, which a static file cannot carry and render-time
  inline R would drift) — that is precisely why the block moved out of
  the template and into the meeting() ritual, rather than surviving as a
  lone interpolation site.

## Open question (small, non-blocking)

- Should `# Analysis` carry a commented `dpp()` example
  (`# ggsave(p, dpp('output/figure_1a.png'), ...)`) teaching the output
  convention at the moment of use, or is that clutter deleted every
  project? Raised 2026-08-23, unanswered; a pure template edit either
  way, so it does not block implementation.

## Validation (per package conventions)

- `stem`: character, length 1, non-NA, non-empty; `open`: logical,
  length 1, non-NA; path argument (if any): existing directory.
  stopifnot() with named conditions; length-1 checks before
  scalar-assuming checks. (No title argument — see YAML.)

## Testing notes

- Temp dir per test; assert filename pattern, version increment + warning
  (message text), and created-file content identical to the inst/ template
  (expect_identical on lines — verbatim copy is the whole content
  contract; individual YAML/header/hook assertions are subsumed by it, but
  keep a few as belt-and-braces so a template edit that breaks structure
  fails with a readable message).
- **Render test** for the session-info hook: render and assert the Session
  info section in output. Requires quarto — skip_if guard; the one slow
  test, keep it singular.
- All content tests run with `open = FALSE`. The open path is untestable —
  thin and isolated, per house convention.
