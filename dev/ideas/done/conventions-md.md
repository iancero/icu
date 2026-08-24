# conventions_md() — copy the house code-conventions file into a project

**Status:** shipped as `conventions_md()` in R/conventions.R (tests in
tests/testthat/test-conventions.R); master installed at
inst/templates/conventions.md. One content question is still open — see
"Master content" below.
**Depended on:** nothing at runtime. new_project() calls this to seed new
projects (same orchestration pattern as seeding main_v1: scaffold composes
small functions, owns no logic itself).

## As shipped (implementation decisions, 2026-08-23)

1. **Signature: `conventions_md(path = '.')`.** ~~Default `'ai'`~~ —
   revised by Ian the same day: the default is the **working directory**,
   and remembering to pass `'ai'` (or having `new_project()` pass it) is
   the caller's job. Either way there is no project-root detection and no
   guessing at a layout: the function writes where it is told, so what a
   call does is legible from the call itself, and a wrong working
   directory fails immediately with "path must be an existing directory"
   rather than writing somewhere surprising. It never creates the
   directory. Two tests pin this — the default writes to the working
   directory, and it does **not** reach into an `ai/` that happens to
   exist beside it.

   Note this changes only the argument default. The destination *within a
   project* is still `ai/`, as the spec resolved — that decision now lives
   with the caller instead of the default.
2. **Announces the path** (open question 2, which leaned yes): `cat()`, in
   `dated_path()`'s posture, with the path returned invisibly so it is
   reported exactly once.
3. **No `force` argument**, as the spec leaned. An existing
   `conventions.md` is an error, and a test pins that the existing file
   survives the error with its content intact — deviations are the one
   part of that file nothing else records.
4. **Master installed beside the qmd template**, at
   `inst/templates/conventions.md`, and copied verbatim. Same property as
   `main.qmd`: editing the master is the only way to change what projects
   receive, and no R code is involved.

## Master content (drafted at implementation; one question open)

Written from what the repo already documents, so nothing in it was
invented: folder taxonomy and the `data/` invariant (project-scaffold.md
and the qmd template), the analysis document and meeting-log ritual
(new-main.md, meeting.md), save-as-increment versioning and `dpp()` output
naming (dated-path, retire.md), the numbers conventions (`round_cols()`
defaults, and `round_with_min(p, 3, 0.001)` with `<0.001` in prose, from
round_with_min's own documentation), and the chat-first AI posture quoted
from project-scaffold.md.

**The master's content is an open chore**, raised 2026-08-23: what ships
today is project *mechanics* (where files go, versioning, the meeting
ritual, the AI posture) with no statistical practice in it, which is not
generally enough for statistical consulting. See
[../../chores/conventions-content.md](../../chores/conventions-content.md)
— it is a content decision for Ian, and a pure master edit when made.

**Resolved: no table tooling section** (Ian, 2026-08-23). The spec listed
it as a section the master should carry, but no convention has actually
settled — nothing in the repo evidences gt, flextable, or kable — so the
master ships without one rather than inventing a house rule. The Numbers
section already covers the part that *is* settled (`round_cols()`
defaults, and p-values via `round_with_min()` with `<0.001` in prose).
Adding a Tables section later is a pure master edit: the content tests
assert the copy matches the master, so they follow such an edit rather
than blocking it.

**Resolved: the qmd template now loads icu** (Ian, 2026-08-23). The
template's setup chunk loaded `tidyverse` but not `icu`, while these
conventions tell you to call `dpp()` unqualified. `library(icu)` was added
to inst/templates/main.qmd, so the two artifacts now agree and the
conventions can stay unqualified at every call site. That is a change to
`new_main()`'s output; see done/new-main.md.

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
  **Settled differently (Ian, 2026-08-23): neither.** The default is `'.'`
  and the caller says where — see "As shipped" item 1 above. The file
  still belongs in `ai/` within a project; that is now something the
  caller remembers rather than something the default assumes.

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
