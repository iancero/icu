# Decide what belongs in conventions_md()'s master

**Status:** decision needed — content scope. Ian's call; not derivable from
the repo, which is exactly how it ended up in its current state.
**Scope:** `inst/templates/conventions.md` only. No code change —
`conventions_md()` copies the master verbatim, so this is a pure content
edit (see the test note at the bottom for the one exception).
**Raised:** 2026-08-23, on shipping `conventions_md()`.

## The problem

The master as shipped is **house rules** — how Ian's projects are
organized. It was written from what the repo documents, because that was
the only evidence available, and it shows:

- where files live (`data/` inbox, `output/` dated, `old/`, `ai/`,
  `background/`, `manuscript/`, `transcripts/`)
- the analysis document and the meeting-log ritual
- save-as-increment versioning and `dpp()` output naming
- style (base pipe, snake_case, `library()` in setup)
- two numeric conventions (`round_cols()` defaults; p-values via
  `round_with_min()`, `<0.001` in prose)
- the chat-first AI posture

Every one of those is *project mechanics*. **None of it is statistical
practice**, which is the substance of what a statistical consultant
actually needs to have agreed and written down. A collaborator or an AI
session reading this file learns where the figures go, and nothing about
how the analysis should be conducted or reported.

## The decision

**What is this file for?** Two candidate answers, and they pull apart:

- **A. Project mechanics only** — keep it as it is, and accept that
  statistical conventions live elsewhere (or nowhere, deliberately).
  Cheapest, and defensible if statistical practice varies too much by
  engagement to have a house default worth shipping.
- **B. Mechanics plus statistical conventions** — the file grows a section
  that states the analytic defaults: what gets reported with a model, what
  is checked before anything is delivered, how missing data and seeds are
  handled, how results are phrased for a non-statistical collaborator.
  More useful, but every line of it is a claim about how Ian works that
  only Ian can make.
- **C. Two files** — `ai/conventions.md` stays mechanics, and a second
  master carries analytic conventions, possibly per-engagement-type.
  `conventions_md()` would then grow an argument or a sibling function.
  Only worth it if the two really are different audiences.

If B or C, the content itself is the work, and it is a writing task for
Ian, not a design task. The questions worth answering on paper first:
which decisions recur across engagements, which ones a collaborator gets
wrong when they are not stated, and which ones an AI session should be
told before it touches an analysis.

## Folded in from the shipping decision

**Table tooling** was left out of the master deliberately (Ian,
2026-08-23) because no convention had settled — no evidence of gt,
flextable, or kable anywhere in the repo. That question belongs to this
one: if the file grows statistical conventions, how tables are built and
formatted is part of the same conversation.

## Notes for whoever does it

- Pure content edit. The copy is verbatim, so nothing in R changes.
- **One test to watch:** test-conventions.R asserts the exact set of `##`
  headings (`## House conventions`, `## Project-specific deviations`).
  Adding a third top-level section is a deliberate structure change and
  means updating that assertion — everything else follows the master
  automatically, since the content contract is "the copy matches the
  master".
- The per-project `## Project-specific deviations` section stays whatever
  else changes: it is what makes the copy project-owned rather than a
  stale duplicate.

## Related

- Shipped function and its decisions:
  [../ideas/done/conventions-md.md](../ideas/done/conventions-md.md).
- `new_project()` seeds this file into every new project
  ([../ideas/done/project-scaffold.md](../ideas/done/project-scaffold.md)
  — shipped 2026-08-23), so whatever this file says is what every future
  project starts from.
