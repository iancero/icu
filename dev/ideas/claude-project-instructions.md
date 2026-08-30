# Claude project-instructions generator

**Status:** **design discussion needed** — reframed once already (see the
reality check below), and every substantive choice is still open. Do not
write code against this file; resolve the open questions with Ian first.
**Proposed file:** R/ai.R or R/claude.R (name follows the function's)
**Depends on:** `codebook_md()` — the redacted codebook is a key input, and
that function is itself still at design-discussion stage
(codebook-md.md). This is downstream of it, so it cannot go first.
**Raised:** 2026-08-18, reframed the same day. Reconciled against the
shipped repo 2026-08-30.

## Original idea vs. reality check (verified 2026-08-18)

Original idea: a function that spins up a Claude.ai Project via API,
aligned with (but not equivalent to) the local R project.

Reality as checked on 2026-08-18: Anthropic's Messages API
(api.anthropic.com) exists and is callable from R, but **there is no API
endpoint for creating Claude.ai Projects** — those are created by hand in
the web UI. A Project's custom instructions are functionally equivalent to
an API system prompt, so the idea survives in two variants.

> **Re-verify before building.** That finding is the load-bearing premise
> of this entire file — variant A exists *because* creation cannot be
> automated. It was checked once, on a third-party product surface that
> changes without notice. Confirm it still holds at implementation rather
> than inheriting it.

## Variant A (recommended): instructions generator

A function that *generates the instructions text* from the local repo, for
one-time manual paste into a hand-created Claude.ai Project.

- **Whitelisted sources only.** This is how "aligned but not equivalent"
  gets enforced by construction: CLAUDE.md conventions, backlog specs,
  exported function signatures/docs, and the redacted codebook
  (`ai/codebook.md`, per codebook-md.md). Never data files, never
  `output/`.
- Target length: under ~2,000 tokens — longer project instructions dilute
  focus.
- Output: write to a file (`dev/claude-project-instructions.md`?) and/or
  `cat()` to console; return invisibly. Same output ergonomics as
  `codebook_md()`'s console variant.
- Could also print a checklist reminder: "upload/refresh the backlog specs
  as Project knowledge files."

## Variant B: API chat from R (probably out of scope for icu)

Chat via the Messages API directly from R using the same generated system
prompt. Prior art: Posit's `ellmer` package supports Anthropic. Per the
re-export-over-wrapper rule, icu should NOT wrap API calls itself — at
most generate the prompt and let ellmer consume it. Decide whether this is
in scope at all, or just documented as a usage pattern.

## What has shipped since this was drafted

Three things bear on it, none of which existed on 2026-08-18.

1. **`ai/` is a real, seeded directory.** `new_project()` creates it and
   calls `conventions_md(file.path(project, 'ai'))` (R/project.R:168), so
   every new project starts with `ai/conventions.md` on disk.
   codebook-md.md targets `ai/codebook.md` in the same folder. That makes
   this function the **third** AI-facing context artifact, and raises a
   question the original framing did not have to answer: *is
   `ai/conventions.md` itself a whitelist source?* It is the closest
   thing the system already has to project instructions, and generating a
   second document that restates it would be duplication with two places
   to drift. Consider instead whether this function's job is partly to
   *point at* `ai/` rather than absorb it.

   Related: what `conventions.md` should even say is an open chore
   (../chores/conventions-content.md). Deciding this function's
   relationship to it while that is unsettled risks building against
   content that is about to change.

2. **The template pattern is real, and it is static.** Question 4 below
   originally cited "the qmd-creator's inst/templates approach";
   qmd-creator.md was superseded by new-main.md and is gone. What
   actually shipped is three templates in `inst/templates/`, all **copied
   verbatim with no placeholders and no interpolation** — that is the
   documented house pattern, and each is pinned by a line-for-line
   identity test.

   This function cannot work that way: assembling from live repo state is
   the entire point. So it would be the first thing in the package to
   need a template *with* interpolation, or the first to skip templates
   and build its text programmatically. Question 4 is therefore a real
   fork away from house precedent, not a style preference — worth calling
   that out when it gets decided.

3. **The backlog split into `dev/ideas/` and `dev/chores/`.** The
   whitelist said "dev/ideas/ specs". Decide whether chores are in scope
   too — they are repo-hygiene items, arguably noise in project
   instructions, but the line is not obvious and the whitelist is
   supposed to be exhaustive by construction.

## Privacy note (institutional, not technical)

Whichever variant: check institutional policy on what may be sent to
claude.ai vs. the API — consumer-product terms and API data-handling terms
differ, and a medical center may treat them differently. The function's
job is to make the *content* safe; the *channel* is a policy question.

## Open questions

1. Variant A only, or A + B?
2. Name — `claude_instructions()`, `project_brief()`, `ai_project_setup()`?
   Run the standard conflict check. Note that `codebook_md()` and
   `conventions_md()` established a `*_md()` convention for functions that
   write a markdown file, which may pull toward something like
   `instructions_md()` if the output is a file rather than console text.
3. Which repo sources are in the whitelist, and in what priority order
   when trimming to the token budget? See "What has shipped" (1) and (3) —
   `ai/conventions.md` and the chores folder are both new candidates.
4. Static template + interpolation, or assembled programmatically from
   live repo state? See "What has shipped" (2): either answer diverges
   from the verbatim-copy pattern, so this is a deliberate first.
5. Should it embed `ai/codebook.md` content (or `codebook_md()`'s schema
   for a named dataset via `data = df`) directly, or stay data-free and
   let the user append/upload the codebook separately? Note
   `ai/codebook.md` is also a natural Project *knowledge file* upload,
   which may be the better channel than embedding in instructions, on
   token budget alone.
6. Does this run against the *icu repo itself*, or against a consulting
   project scaffolded by `new_project()`? The whitelist as written
   (CLAUDE.md, backlog specs, exported function docs) describes icu; the
   `ai/codebook.md` input describes a consulting project. Those are two
   different functions with two different audiences, and the file has
   been quietly assuming both.

## Testing notes

- Variant A is pure-ish (reads repo files, writes/returns text): temp-dir
  fixture with a fake mini-repo (CLAUDE.md + one idea file), assert the
  generated text includes whitelisted content and — pin this hard, same
  as `codebook_md()` — **excludes sentinel content** planted in
  non-whitelisted locations (a fake data file, a fake `output/`
  artifact). The exclusion test is the one that matters; inclusion
  failures are visible, leaks are not.
- Token-budget behavior: assert trimming and priority order once decided.
- Input validation per house convention: `stopifnot()` block of named
  conditions that read as user-facing messages, checked separately.

## Related

- [codebook-md.md](codebook-md.md) — upstream dependency, itself at
  design-discussion stage. Resolve that one first; question 5 here is
  partly a restatement of its output-path question.
- [done/conventions-md.md](done/conventions-md.md) and
  [../chores/conventions-content.md](../chores/conventions-content.md) —
  the existing AI-facing document, and the open question of what it says.
- [done/project-scaffold.md](done/project-scaffold.md) — what seeds `ai/`,
  and the source of the layout this function would read.
