# dev/ideas/

Backlog of function ideas for icu, one markdown file per idea. This folder is
`.Rbuildignore`d and never ships with the package.

**Workflow:**

- Ideas get drafted here (often from chat conversations) before any code.
- Each file carries: status, motivation, design notes, open questions,
  testing notes, and dependencies on other backlog items.
- When starting work on one in Claude Code: read the file first; **design
  discussion happens before code** (open questions get resolved and recorded
  in the file, then implementation starts).
- When a function ships: delete the file, or move it to `dev/ideas/done/`.

**Current ordering constraint:** qmd-creator.md → project-scaffold.md.
dated-path is **shipped** (`dated_path()`); the two downstream items call it
for file-name assembly, but it carries no versioning logic, so each owns its
own version handling. round-cols-default is **shipped** (`round_cols()` now
defaults to `digits = 3, min = 0`); it was independent of the other three.
**Current ordering constraint (2026-08-23):**

Implementation wave, in order:

1. **new-main.md** (new_main()) — first: its version probe pins the
   `{stem}[_vN]_{date}[_HH-MM-SS].{ext}` filename grammar that retire()
   later inherits. Template is fully static (a working draft exists);
   new_main() no longer depends on meeting() — that coupling was
   dissolved 2026-08-23.
2. **meeting.md** (meeting() + internal meeting_block()) — independent of
   new_main now; any time, but early, since the kickoff ritual needs it.
3. **conventions-md.md** (conventions_md()) — independent; any time before
   new_project().
4. **project-scaffold.md** (new_project()) — last of the wave; orchestrates
   new_main(open = FALSE) and conventions_md(), owns no logic itself.

Independent of the wave, any time: **retire.md** (grammar now inherited
from new_main, not settled jointly), **icu-setup.md**.

Deliberately backlog, not in the wave: **codebook-md.md**, then
**synthetic-data.md** (downstream of codebook — consumes its schema, never
the data).

Shipped: dated-path (`dated_path()` + shorthands), round-cols-default
(`digits = 3`) — see done/. Superseded: qmd-creator.md was replaced
wholesale by new-main.md (2026-08-23); if a qmd-creator.md file is still
present, it is stale — delete it.
