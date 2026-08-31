# Revise new_main()'s template: render targets, not just html

**Status:** design discussion needed — the output set and the render ritual
are Ian's call. The sketch below is his, from the raising conversation; the
open questions under it are not answered.
**Scope:** `inst/templates/main.qmd` YAML (and possibly its setup chunk).
No R code — `new_main()` copies the master verbatim — but three
hand-written tests in `tests/testthat/test-document.R` pin the current
output and do not follow automatically. Likely a matching content edit in
`inst/templates/conventions.md`.
**Raised:** 2026-08-25, by Ian.

## Motivation

The template ships `format: html` with `embed-resources: true` — one
self-contained file, chosen because the render is *a record of the
analysis*, kept on synced storage (see
[../ideas/done/new-main.md](../ideas/done/new-main.md), the format
decision). That was one consumer. There are now two, and neither is html:

- **AI collaboration** wants GitHub-flavored markdown. A `.md` render
  pastes into a session cleanly, diffs, and greps — an html file with
  embedded resources is the worst possible thing to hand a model.
- **Documentation / receipts** wants PDF, via **Typst**. A PDF is the
  artifact that survives outside the project and gets attached to an
  email: fixed pagination, no browser, nothing to un-embed. Typst rather
  than LaTeX because quarto ships it — no TinyTeX install to maintain on
  a collaborator's machine.

Ian's opening sketch: **drop html, render gfm + Typst PDF.** Everything
below is what that runs into.

## What the sketch runs into

Five things, roughly in order of how much they change the answer.

1. **The session-info hook emits raw HTML.** The setup chunk's `document`
   hook appends `<details><summary>...</summary>` around a fenced
   `sessioninfo::session_info()` dump. That collapses in html, renders on
   GitHub in gfm, and in Typst is a raw HTML block with **no PDF
   equivalent — it is dropped**. So the format that most wants to be a
   receipt is the one that would silently lose the package-version
   record, which is the hook's entire reason for existing. A fix is
   needed *inside the hook*, not around it: emit plain markdown (`###`
   plus a fenced block) and accept that it is not collapsible, or branch
   on `knitr::pandoc_to()` / wrap in `::: {.content-visible
   when-format="html"}` blocks and write the PDF variant separately.
   Whatever is chosen, the one slow render test exists precisely to catch
   a silently-missing section — extend it per format rather than trusting
   it.
2. **`embed-resources: true` is html-only** and becomes meaningless.
   Under gfm, figures land in a sibling `main_vN_<date>_files/` directory
   next to the document — in the project root, beside `data/` and
   `output/`. Typst embeds. So "self-contained" survives in the PDF and
   is *lost* in the markdown, and the project root gains a directory per
   render.
3. **Multiple keys under `format:` means `quarto render` produces all of
   them, every time.** Two files (plus a `_files/` dir) per render,
   accumulating on synced storage under save-as-increment versioning,
   where nothing is ever swept. A PDF that is a *receipt* arguably wants
   producing once at wrap, not on every exploratory render — which points
   at `format: gfm` as the default and `quarto render --to typst` as a
   wrap-time step, rather than both in the YAML. That is a real fork in
   the design, not a detail.
4. **It touches the AI rule in `conventions.md`.** That file says: *"Paste
   the `.qmd` source, not the rendered document. A render can embed
   glimpses of the data"* (line ~79). Rendering gfm **for AI
   collaboration** is that rule pointed the other way. It may well be
   right — a reviewed gfm render is a different thing from an html
   render, and it carries executed output the source doesn't — but the
   rule and this change cannot both stand unedited. Decide which one
   moves. The analysis-document section (~line 25) also says "render once
   at the end of a work stretch", which is the same question as (3).
5. **The version probe is fine, and one test under-covers it.**
   `new_main()` filters siblings to `ext == 'qmd'`, so a `.md` or `.pdf`
   render can never push the version along — no code change needed. But
   the test that pins this (test-document.R:181, "a rendered sibling does
   not push the version along") uses an `.html` sibling only. If html
   goes away, that test is pinning a file type nothing produces any more.
   Extend it to `.md` / `.pdf`.

## Open questions

1. **Both formats in the YAML, or gfm in the YAML and PDF on demand?**
   See (3). Bears on whether the PDF is a receipt or an output.
2. **Does html stay?** Keeping it is three outputs; dropping it loses the
   only format that is both self-contained *and* readable without a PDF
   viewer. `toc: true` / `toc-depth: 2` was doing real work there — the
   depth-2 toc doubles as a meeting index, per the original decision.
   Typst has its own toc; gfm has none.
3. **What does the PDF carry for session info?** See (1). Plain
   non-collapsible section, or format-conditional content, or omitted
   from the PDF entirely (which makes the PDF a worse receipt than the
   markdown).
4. **Where does the gfm render sit against the paste-the-source rule?**
   See (4). If gfm is the AI-facing artifact, the rule becomes something
   like "paste the source, or a render you have read".
5. **Is a `_files/` directory in the project root acceptable?** If not,
   the alternative is an output subdirectory (`_quarto.yml`'s
   `output-dir`), which changes where the rendered document lands and
   therefore what the file-naming convention means.
6. **Anything else worth revising while the template is open?** The ask
   was scoped to formats, but the template has not been touched since it
   shipped 2026-08-23 and this is the natural moment.

## Testing notes

The verbatim-copy test is the master contract and follows a template edit
automatically. These three do **not**, and are the whole cost of this
chore on the test side:

- **test-document.R:240** "the YAML carries the house render settings" —
  asserts `embed-resources: true`, `toc: true`, `toc-depth: 2` literally.
  Rewrite to whatever the new YAML says.
- **test-document.R:324** "a render appends the session-info section" —
  the one slow test. Derives the output path as
  `sub("\.qmd$", ".html", created)` and greps it for `Session info`.
  Needs a path per format, and an assertion per format, and it is the
  only thing that will catch (1). Keep its existing skips (quarto on
  PATH, icu installed); a Typst render adds no new external dependency,
  since quarto ships Typst — but it does add wall-clock to the one test
  that already costs ~10s.

  **This test under-asserts today, before any format change.** It greps
  the rendered html for `Session info` and stops there — it never checks
  that the hook's `<details>` / `<summary>` wrapper came through as
  *markup* rather than as literal escaped text. A hook that emitted the
  tags as a character string, or a pandoc setting that escaped them,
  would produce a document with the heading present, the collapse broken,
  and a passing test. Worth adding an assertion on the rendered
  `<details>` element whether or not the format set changes; it is the
  cheap half of what (1) needs anyway, and it establishes the per-format
  assertion shape before there are three formats to write it for.
- **test-document.R:181** "a rendered sibling does not push the version
  along" — see (5) above.

Nothing else in the suite reads the YAML.

## Related

- [../ideas/done/new-main.md](../ideas/done/new-main.md) — the original
  format decision and the session-info hook's design, with the reasoning
  this chore is revisiting.
- [conventions-content.md](conventions-content.md) — the open chore on
  what `conventions.md` should say. Item (4) edits the same paragraphs;
  if both are worked, do them together rather than twice.
- [done/meeting-block-revision.md](done/meeting-block-revision.md) — was
  the other open revision to a shipped document artifact; **landed
  2026-08-31**. Independent of this one; they touched different files.
  Note it already made the narrow rename fix to `conventions.md`'s two
  meeting sentences, so item (4) here has that much less to do.
