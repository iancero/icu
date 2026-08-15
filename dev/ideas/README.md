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
own version handling. round-cols-default.md is independent and can go anytime.
