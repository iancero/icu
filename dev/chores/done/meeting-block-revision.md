# Fill out meeting()'s block

**Status:** DONE 2026-08-31 — implemented as specified, with all three
open questions resolved on their recorded leans (Ian, 2026-08-31):
checkbox lines **keep** the trailing space, the third label **gains** the
colon (`**TODOs / Deliverables:**`), and the gap under Notes is **two**
blank lines. `document()` + `test()` clean: 454 passing, 0 failures.
Step 5 was done as the narrow rename fix only — the two stale sentences in
`inst/templates/conventions.md` now read TODOs rather than requests. That
edit is independent of [conventions-content.md](conventions-content.md),
which decides what belongs in that file at all; it goes stale either way.
**Caution:** this changes an **exported function's output**, reverses a
decision that is documented and test-pinned, and breaks five named tests
by design. Read the Testing notes before editing anything.
**Scope:** `meeting_block()`'s `lines` vector in
[../../R/document.R](../../R/document.R), its roxygen block, five tests in
`tests/testthat/test-document.R`, and two stale sentences in
`inst/templates/conventions.md`. No template file involved — the meeting
block is assembled in R, not copied, because it carries the current date.
**Raised:** 2026-08-25, by Ian.

## Motivation

The block as shipped is almost empty: three bold labels, one blank
attendee line, two checkboxes. It was deliberately minimal, on the theory
that a mid-meeting tool should not make you delete things. In practice the
opposite bites — the entry has no shape until you type one, at the exact
moment you are listening to someone rather than formatting a document. A
fuller skeleton is faster to fill and, more to the point, *reminds you
what to capture*.

## The target block

Exactly as specified:

```
## Meeting - 2026-08-25

**Attendees:**
- Ian Cero
- 
- 


**Notes:**


**TODOs / Deliverables**
- [ ]
- [ ]
- [ ]
- [ ]
```

Trailing whitespace as pasted: the two blank attendee bullets carry a
trailing space; the checkbox lines do not; the Attendees label no longer
carries one, since bullets follow it now rather than the cursor. See open
question 1 — the house rationale argues the checkboxes should keep theirs.

Changes against what ships today:

| | Now | Target |
|---|---|---|
| Attendees | one inline label line, cursor after it | label, then `- Ian Cero` plus 2 blank bullets |
| Gap under Notes | 3 blank lines | 2 blank lines |
| Third label | `**Requests:**` | `**TODOs / Deliverables**` (no colon) |
| Blank line under third label | yes | no — checkboxes follow immediately |
| Checkboxes | 2 | 4 |

Unchanged: the `## Meeting - <date>` header and its `%Y-%m-%d` format, the
optional `label` argument appended after the date, three sections in that
order, the trailing newline, and the whole insert-or-print wrapper.

## Design notes

- **Ian is prefilled as an attendee.** He is at every meeting this
  function will ever be called for. Consistent with `author: "Ian Cero"`
  hard-coded in `inst/templates/main.qmd` and with DESCRIPTION's sole
  author — icu is Ian's utils, not a general-purpose package, and this is
  not the first place that shows.
- **Attendees becomes a list**, because it is one. The inline form only
  ever held one name comfortably.
- **Requests becomes TODOs / Deliverables. This reverses a shipped
  decision.** The current design says, in the roxygen at
  [../../R/document.R](../../R/document.R) (~line 187) and in
  [../ideas/done/meeting.md](../ideas/done/meeting.md) (line 83):
  *"Deliverables folded into Requests, because they are the same
  checklist seen from two sides."* The new label unfolds them and names
  both. That rationale paragraph is now wrong and gets rewritten, not
  patched — and the test that pins the folding (an `expect_no_match` on
  the word Deliverables) fails **by design**. Do not work around it; it
  is the tripwire doing its job.
- **Four checkboxes rather than two** — the count is a hint about how much
  usually comes out of a meeting, and unused ones are cheap to delete.
- **Still no new arguments.** Attendee and TODO counts stay fixed; adding
  a row is one keystroke and an argument for it would cost more than it
  saves.

## Open questions

Small, and none of them blocks starting.

1. **Trailing spaces on the checkbox lines?** The documented reason for
   trailing spaces is cursor placement: click the line, land where you
   type. That argues for keeping one. The spec as pasted has none.
   **Lean: keep the trailing space**, matching the blank attendee
   bullets — but this is Ian's to confirm, and whichever way it goes, the
   exact-block test pins it forever.
2. **The third label has no colon** while Attendees and Notes do.
   Probably an artifact of typing it out. **Lean: add the colon** for
   consistency. Recorded above as-specified (without) so the divergence
   is a decision, not a transcription slip.
3. **Two blank lines under Notes, down from three?** Taken as written
   above. Worth a beat only because the current three were deliberate
   ("room to write in, not an accident") and a test measures the gap
   exactly.

## The work

1. `meeting_block()`'s `lines` vector in
   [../../R/document.R](../../R/document.R) — the whole change on the
   code side. One vector.
2. Its roxygen: the `@description` one-liner still says *"Attendees,
   Notes, and a Requests checklist"*; the `@details` `\preformatted{}`
   block reproduces the old block verbatim; the *"Only three sections,
   deliberately"* paragraph carries the folding rationale reversed by
   this chore.
   **Keep the block inside `\preformatted{}`.** Roxygen markdown parses a
   literal bracket pair as a reference link and leaves junk in the
   generated `.Rd` — a fenced code block does not protect it, and the
   checkbox lines are nothing but bracket pairs. Keep bracket pairs out
   of the surrounding prose too.
3. `devtools::document()` — regenerates `man/meeting.Rd`.
4. The five tests below.
5. `inst/templates/conventions.md` (~lines 32-35): *"Attendees, notes, and
   requests get typed as the colleague talks"* and *"Requests are
   checkboxes. Tick them as the work lands"*. Both go stale on the
   rename. Pure content edit — but note that file's content is itself an
   open chore ([conventions-content.md](conventions-content.md)), so
   check it before editing twice.
6. `devtools::test()`. Not `check()`.

## Testing notes

All in `tests/testthat/test-document.R`. Four of the five fail on purpose;
that is the contract working.

- **:429 "the block is exactly the house boilerplate"** — the whole
  content contract in one `expect_identical()`. Rewrite it to the new
  block, character for character including trailing spaces. This is the
  test that matters; the rest are belt and braces.
- **:476 "the block carries three sections, in order"** — expects the
  three bold labels, collected by grep. All three expected strings change
  (the first loses its trailing space, the third is renamed); the count
  and the order do not.
- **:485 "decisions and deliverables are folded in"** — the
  `expect_no_match` on Deliverables **fails by design**. Decisions are
  still folded into Notes, so keep that half and drop the deliverables
  half, with a comment saying it was deliberately unfolded on 2026-08-25.
- **:494 "requests are two empty, unticked checkboxes"** — rename it, and
  expect four. The half asserting nothing ships pre-ticked still holds.
- **:503 "there is room to type under Notes"** — locates the gap by
  searching for the old `**Requests:**` line. Both the terminator string
  and the expected run of blank lines change.

Nothing on the `meeting()` side moves: insert-or-print is untouched, and
the `rstudio_available()` mock stays mandatory in every test that calls
`meeting()` itself.

## Related

- [../ideas/done/meeting.md](../ideas/done/meeting.md) — the shipped
  design, including the fold-Deliverables-into-Requests reasoning this
  chore reverses. Worth updating the note there once this lands, so the
  file does not read as current.
- [conventions-content.md](conventions-content.md) — same file touched in
  step 5.
- [main-template-formats.md](main-template-formats.md) — the other open
  revision to a shipped document artifact. Independent; either order.
