# meeting() — insert meeting-log boilerplate at cursor

**Status:** design resolved (2026-08-23) — ready to implement.
**Proposed file:** R/meeting.R (or alongside qmd-creator; decide at
implementation)
**Depends on:** nothing. Sole producer of meeting blocks (decision
2026-08-23): new_main()'s template ships with an EMPTY Project Background,
and the kickoff ritual is open main_v1 → cursor → meeting(). The former
shared-block-builder coupling with the template is dissolved.

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
- rstudioapi in Suggests (same dependency posture as qmd-creator's
  file-opening).

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
