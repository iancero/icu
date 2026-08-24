# dev/ideas/

Backlog of function ideas for icu, one markdown file per idea. This folder is
`.Rbuildignore`d and never ships with the package.

Repo chores — tooling, hygiene, configuration — go in
[../chores/](../chores/), not here.

**Workflow:**

- Ideas get drafted here (often from chat conversations) before any code.
- Each file carries: status, motivation, design notes, open questions,
  testing notes, and dependencies on other backlog items.
- When starting work on one in Claude Code: read the file first; **design
  discussion happens before code** (open questions get resolved and recorded
  in the file, then implementation starts).
- When a function ships: delete the file, or move it to `dev/ideas/done/`.

**Superseded ordering note** (kept for context; the live constraint is the
dated block below): new-main.md → project-scaffold.md.
dated-path is **shipped** (`dated_path()`); the two downstream items call it
for file-name assembly, but it carries no versioning logic, so each owns its
own version handling. round-cols-default is **shipped** (`round_cols()` now
defaults to `digits = 3, min = 0`); it was independent of the other three.
**Current ordering constraint (2026-08-23):**

Implementation wave, in order. Steps 1 and 2 are done:

1. ~~**new-main.md** (new_main())~~ — **shipped 2026-08-23** (see done/).
   Its version probe pinned the `{stem}[_vN]_{date}[_HH-MM-SS].{ext}`
   grammar, which now lives in an internal `parse_dated_filename()` in
   R/paths.R; everything downstream inherits it rather than re-deciding
   it. The template is installed at inst/templates/main.qmd — that file
   IS the function's output, so content changes are template edits, no R
   code involved.
2. ~~**meeting.md** (meeting() + internal meeting_block())~~ — **shipped
   2026-08-23** (see done/). Lives in R/document.R beside `new_main()`.
   Note the seam it introduced: the RStudio check is now an internal
   `rstudio_available()`, which both functions share and the tests mock —
   `rstudioapi::isAvailable()` is TRUE when the suite runs inside RStudio,
   so anything with an editor side effect must go through it.
3. ~~**conventions-md.md** (conventions_md())~~ — **shipped 2026-08-23**
   (see done/). Master at inst/templates/conventions.md, copied verbatim.
   `path` defaults to `'.'`, so callers pass `ai/` themselves. **What the
   master should actually say is an open chore** — what ships today is
   project mechanics, not statistical practice: see
   ../chores/conventions-content.md. Pure content edit when decided.
4. ~~**project-scaffold.md** (new_project())~~ — **shipped 2026-08-23**
   (see done/). Orchestrates `new_main(path = ..., open = FALSE)` and
   `conventions_md(file.path(project, 'ai'))`, owns no logic itself. Third
   template installed, at inst/templates/project.Rproj. Note for
   icu-setup.md: its unset-option warning points at
   `options(icu.projects_dir = ...)` in `.Rprofile`, **not** at
   `icu_setup()` as that spec had it — revisit the text when icu_setup()
   ships.

**The wave is complete.** Nothing in the backlog is ordered against
anything else any more; what remains is independent, and none of it is a
commitment.

Independent, any time: **retire.md** (grammar now shipped, and the parser
it planned to share already exists), **icu-setup.md** (now the only
consumer of `icu.projects_dir`'s story — see the note above).

Deliberately backlog, not in the wave: **codebook-md.md**, then
**synthetic-data.md** (downstream of codebook — consumes its schema, never
the data).

Shipped: dated-path (`dated_path()` + shorthands), round-cols-default
(`digits = 3`), new-main (`new_main()` + internal `parse_dated_filename()`),
meeting (`meeting()` + internal `meeting_block()`), conventions-md
(`conventions_md()`), project-scaffold (`new_project()` + internal
`projects_dir()`) — see done/. Superseded: qmd-creator.md was replaced wholesale by
new-main.md (2026-08-23) and is gone.
