# codebook_md() — write a shareable, PHI-safe codebook to ai/

**Status:** backlog — design discussion needed. Deliberately NOT part of
create_project(); standalone function, run when data arrives.
**Proposed file:** R/codebook.R
**Depends on:** nothing upstream. synthetic-data (see synthetic-data.md) is
downstream and should consume this function's output.

## Motivation

The chat-based AI workflow (Claude never sees data; only code and reviewed
aggregate output are shared) needs one bridging artifact: a schema that lets
chat-Claude write correct wrangling and modeling code against data it never
sees. Variable names, types, labels, factor levels — a
glimpse()-with-values-redacted, written to `ai/codebook.md` as a standalone
pasteable file.

Why this cannot just be a chunk in main_vX: a codebook chunk *executes on
the real data*, and its rendered output is exactly what cannot be pasted.
The function runs locally on real data, but its **output file is designed
from the start to be shareable** — that design is the whole point.

## The substance is the exclusions

What the file includes is easy (names, classes, haven labels — the .sav
files carry variable/value label attributes — declared factor levels). What
it must exclude is the real design work, because each exclusion is a
disclosure channel:

- **No numeric summaries.** Min/max/range are real patient values.
- **Factor levels are conditional.** A well-defined categorical's levels
  (gender, condition arm) are schema; but rare levels can identify, and
  high-cardinality factors are values masquerading as levels. Needs a rule —
  e.g. list levels only below a cardinality threshold, else report the
  count of levels only. Threshold choice is a design decision.
- **Free text: type only, never uniques.** Character columns that aren't
  low-cardinality factors get "character" and nothing else.
- **Dates: type only.** A date range can identify (admission dates).
- **Counts:** overall n is probably fine; per-level counts reintroduce the
  small-cell problem. Lean: no per-level counts in v1.

Default posture: conservative. Anything ambiguous is excluded; the user can
hand-edit the .md to add safe detail, which is cheaper than un-leaking.

## Open questions

1. Input: data frame argument, or file path it reads itself? Lean data
   frame (`codebook_md(df)`) — reading is the analysis script's job, and it
   keeps the function format-agnostic.
2. Cardinality threshold for listing factor levels (and is it an argument).
3. Haven-labelled columns: report value labels? They're schema-like (coded
   response options from the survey) — lean yes, they're exactly what
   chat-Claude needs — but confirm no free-text label edge cases.
4. Output path default (`ai/codebook.md`?) and the announce-the-path
   posture (house cat(), cf. dated_path).
5. Overwrite behavior: unlike conventions.md, the codebook is *generated*,
   not hand-owned, so overwriting on re-run is arguably correct (data
   arrives in waves; regenerate). But hand-edits per the conservative
   posture above would be lost. Tension to resolve at design time.
6. Name confirmed `codebook_md()`? Consistent with conventions_md().

## Validation (per package conventions)

- Strict on parameters; data argument follows permissive-data norms
  (zero-column df is a message + minimal file, not an error?  — decide).

## Testing notes

- Fixture data frames covering: numeric, character, low- and
  high-cardinality factors, haven_labelled columns (tibble/haven in
  Suggests as needed — usethis::use_package first), dates.
- Pin the exclusions hardest: assert min/max do NOT appear, uniques of a
  free-text column do NOT appear, levels above threshold do NOT appear.
  Negative assertions are the contract here.
- Temp-dir write + content assertions; overwrite behavior per resolution of
  open question 5.
