# meeting() — insert meeting-log boilerplate at cursor

**Status:** shipped as `meeting()` in R/document.R, alongside `new_main()`,
with internal `meeting_block()` beside it (tests in
tests/testthat/test-document.R).
**Depended on:** nothing. Sole producer of meeting blocks (decision
2026-08-23): new_main()'s template ships with an EMPTY Project Background,
and the kickoff ritual is open main_v1 → cursor → meeting(). The former
shared-block-builder coupling with the template is dissolved.

## As shipped (implementation decisions, 2026-08-23)

The spec held up as written; the block is byte-for-byte what this file
specified, pinned by one exact-string test. Four things the spec did not
foresee:

1. **`rstudio_available()` is now an internal seam, not an inline check.**
   The spec said the cat() fallback is testable via `capture.output()` —
   but `rstudioapi::isAvailable()` is **TRUE** when `devtools::test()` runs
   inside RStudio, so a test calling `meeting()` would have taken the
   editor branch for real and inserted a meeting block into whatever file
   Ian had open. The RStudio check is therefore one internal function
   (shared with `new_main()`, which previously inlined it), and the tests
   mock that binding. Every test that calls `meeting()` mocks it first, on
   purpose; the comment above them says why so nobody removes it.
2. **`testthat` minimum bumped to >= 3.2.0** in Suggests, for
   `local_mocked_bindings()`. That also made the *insert* path testable
   after all — mocking `rstudioapi::insertText` pins that the block goes to
   the editor and nothing is printed — so the branch the spec wrote off as
   untestable is covered from both sides.
3. **Validation lives in `meeting_block()` only.** `meeting()` delegates
   rather than repeating the `stopifnot()`, following the precedent set by
   `dated_path()`'s shorthands, with a test that the messages still reach
   the caller through the exported function.
4. **Both paths return the block invisibly.** Same reasoning as
   `dated_path(print = TRUE)`: it has already been delivered, to the editor
   or to stdout, so a visible return would report it twice.

A documentation gotcha worth knowing, since the next markdown-emitting
function will hit it: a literal `[ ]` in a roxygen block — even inside a
fenced code block — is parsed as a markdown reference link and leaves junk
link definitions (`[ ]: R:%20`) in the generated .Rd. Show the block with
`\preformatted{}` rather than a fence, and keep bracket pairs out of the
prose.

## Motivation

Consulting projects run on a meeting → work TODOs → meeting cadence. The
analysis document (see the v7 exemplar discussed 2026-08-23) accumulates a
meeting log at the top under `# Project Background`: per-meeting narrative,
requests, and rationale, cross-referenced from analysis sections. `meeting()`
makes adding an entry a one-call act at meeting start, and gives requests
explicit checkbox state — the thing the hand-rolled log lacked. The log
doubles as machine-readable project memory for AI collaboration (what's
outstanding, what's settled).

## Resolved spec

### Boilerplate

```markdown
## Meeting - 2026-08-23

**Attendees:** 

**Notes:**



**Requests:**

- [ ] 
- [ ] 
```

- No meeting number — date identifies the entry. Date format `%Y-%m-%d`,
  same grammar as `dated_path()`, so the log stays greppable/sortable.
- "Meeting" is hardcoded in the header; an optional label argument appends:
  `meeting('manuscript feedback')` →
  `## Meeting - 2026-08-23 - manuscript feedback`.
- Sections are Attendees / Notes / Requests only. Decisions was considered
  and folded into Notes (per Ian: "Decisions is really just Notes to me").
  Deliverables folded into Requests — in practice they're the same checklist.
- Requests are `- [ ]` checkboxes: ticked as work completes between
  meetings, so file-top always shows outstanding work.

### Mechanics

- Insert at cursor via `rstudioapi::insertText()`, guarded by
  `rstudioapi::isAvailable()`. Cursor placement is the user's job (end of
  the log); this avoids parsing/rewriting the qmd to find an insertion
  point, which is fragile.
- **No RStudio session → `cat()` the block** for copy-paste. Never leaves
  you empty-handed mid-meeting; costs three lines.
- rstudioapi in Suggests (same dependency posture as `new_main()`'s
  file-opening, now shipped: guarded by `requireNamespace()` as well as
  `isAvailable()`, with `utils::file.edit()` as the fallback).

### Internal block builder (testability, not sharing)

An internal `meeting_block(label = NULL)` returning the block text is still
the right factoring — but for testability only, not sharing: string
assembly gets plain-string tests; `meeting()` stays a thin
insert-or-cat wrapper. (An earlier design had the template as a second
consumer; dissolved 2026-08-23 when the template went fully static — the
block's creation-day date is exactly what a static file cannot carry.)

## Validation (per package conventions)

- `label`: if supplied, character, length 1, non-NA, non-empty. Absent →
  no suffix.

## Testing notes

- `meeting_block()` carries the real tests: exact block text with and
  without label, date format, header assembly. Plain string assertions, no
  temp dir. (Same midnight-flake note as dated_path tests: regex or inline
  Sys.Date() comparison.)
- `meeting()` itself is thin: the insertText path is untestable
  (rstudioapi), the cat() fallback testable via `capture.output()`. Keep the
  untestable part isolated, per house convention.
- (A former note about template tests asserting the block's presence is
  obsolete — the template no longer contains a meeting block.)
