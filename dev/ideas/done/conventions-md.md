# conventions_md() — copy the house code-conventions file into a project

**Status:** design resolved (2026-08-23) — ready to implement, pending one
content task (writing the master conventions file itself).
**Proposed file:** R/conventions.R
**Depends on:** nothing at runtime. create_project() calls this to seed new
projects (same orchestration pattern as seeding main_v1: scaffold composes
small functions, owns no logic itself).

## Motivation

Code conventions (base pipe, `dpp()` for all outputs, table tooling, style)
are Ian-level, not project-level — but AI chat workflows need a *pasteable
file*, and projects need a local copy that can record deviations. So: one
master ships with icu; each project gets a copy at creation.

## Resolved spec

- **Master lives in the package**, `inst/` alongside the qmd template —
  versioned with the functions that embody the conventions.
- **Copies to `ai/`** (revised 2026-08-23, superseding an earlier root
  decision): the file is *mostly consumed by AIs*, so it lives with the
  other AI-loop artifacts (codebook, synthetic data, drafts). CLAUDE.md's
  template points at `ai/conventions.md`.
- **Deviations section**, empty by default:

  ```markdown
  # Code conventions (icu)

  ## House conventions
  [master content]

  ## Project-specific deviations
  <!-- none yet -->
  ```

  This makes each copy deliberately divergent — part boilerplate, part
  project-owned. Two consequences, both logged as features:
  - Copy-vs-pointer is settled: must be a copy; a pointer can't hold
    deviations.
  - Staleness is reframed: a project's file is a snapshot of house style
    *as of when the project ran*, plus local exceptions — for an R&R years
    later, more correct than the then-current master would be.
- **Exported standalone** (not scaffold-internal), so it can retrofit
  existing projects and re-copy a refreshed master on demand.
- **Never overwrite silently.** If `conventions.md` exists at the target,
  error — the existing copy may hold deviations, which are project-owned
  content. (Same never-clobber posture as retire().) A `force = TRUE`
  override is plausible but destructive to deviations; lean *no* force
  argument v1 — delete by hand if you truly mean it.
- **Name:** `conventions_md()`. Chosen over `use_conventions()` /
  `add_conventions()` (usethis-flavored prefixes considered and passed on).
- File name at destination: `conventions.md`. Target directory argument —
  default should land it in `ai/` when called from a project root; exact
  default (`'ai'` vs. path detection) decided at implementation.

## Open questions

1. Master content itself — a writing task, not a design one: base pipe,
   dpp()/output conventions, table tooling, validation style, and the
   AI-workflow rules worth encoding (e.g. paste qmd *source* not rendered
   output; code and reviewed aggregate output only). Draft at
   implementation.
2. Does the function print/announce the created path (house `cat()`
   posture, cf. dated_path) — lean yes, announce.

## Validation (per package conventions)

- `path`: character, length 1, non-NA, existing directory.

## Testing notes

- Temp dir per test: file created; content identical to `inst/` master
  (`expect_identical` on lines); deviations section present; error when
  file already exists, matched on message text; announcement via
  `capture.output()` if adopted.
- create_project()'s own tests only assert the file appears — content is
  pinned here, at the layer that owns it.
