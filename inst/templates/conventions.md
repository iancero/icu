# Code conventions (icu)

This is a copy, taken when the project was created. It is read by you and
by AI sessions working on this project. The house conventions below travel
with icu; anything this project does differently belongs in the last
section, which is yours to edit.

## House conventions

### Where things live

| Folder | Written by | Contents |
| --- | --- | --- |
| `data/` | nobody in this project | Data files exactly as received from outside. Never written to by project code. |
| `background/` | nobody in this project | Read by a person: codebooks, data dictionaries, surveys, prior manuscripts. |
| `transcripts/` | nobody in this project | Meeting transcripts as the recorder named them. Never renamed. |
| `output/` | code | Everything generated: figures, tables, deliverables. Dated file names. |
| `old/` | `retire()` | Superseded versions, swept aside rather than deleted. |
| `ai/` | you and AI sessions | This file, and the rest of the AI workbench. |
| `manuscript/` | you and co-authors | The paper's track-changes lifecycle. Papers are written natively in Word. |

The invariant worth stating twice: **`data/` is an inbox, not a working
directory.** Anything derived from it is written to `output/`.

### The analysis document

`main_vN_<date>.qmd` at the project root is the analysis, and it is also
the project's memory. It carries, in order: Project Background (the meeting
log), Data Provenance, Data Wrangling, Analysis, Results Summary.

- Start each meeting by putting the cursor at the end of the log and
  calling `meeting()`. Attendees, notes, and requests get typed as the
  colleague talks.
- Requests are checkboxes. Tick them as the work lands, so the top of the
  document always shows what is outstanding.
- Analysis sections cite the meeting that asked for them.
- Render once at the end of a work stretch. The setup chunk's hook appends
  a session-info record, so the rendered file states which package
  versions produced it.

### Versioning, without git

Projects live on synced storage, so version control is save-as-increment:

- `new_main()` creates the next `main_vN`, leaving the previous one in
  place. Bump the version for a major revision, not for every edit.
- Output file names carry the date: write them through `dpp()`, which
  stamps the name and announces it, so the rendered document records which
  files that run produced. `ggsave(p, dpp('output/figure_1a.png'), ...)`.
- Two runs on the same day overwrite by design. Use `dtpp()` when every
  run must be kept.
- `retire()` sweeps superseded versions into `old/`. Nothing is deleted.

### Style

- Base pipe, `|>`.
- `snake_case` for objects and files.
- `library()` calls belong in the setup chunk, not scattered through the
  document.
- Label chunks, and keep one purpose per chunk. Code stays visible: the
  rendered document is a record of the analysis, not a report that hides
  how it was made.

### Numbers

- `round_cols(df)` rounds every numeric column of a summary or model table
  to 3 digits.
- P-values: `round_with_min(p, digits = 3, min = 0.001)`, so a very small
  value clamps to 0.001 instead of rounding to a misleading 0. In prose and
  in manuscript tables, write `<0.001` rather than the clamped number.

### Working with AI on this project

The rule is **chat-first, and data never leaves the project**:

- An AI session sees code and reviewed aggregate output. Never data files,
  and never unreviewed console output — a pasted error message or a
  `head()` can carry raw rows with it.
- Paste the `.qmd` *source*, not the rendered document. A render can embed
  glimpses of the data.
- `main_vN` is the context document. Pasting it should be enough to orient
  a session; keeping it good enough for that is the discipline that makes
  the log worth writing.

## Project-specific deviations

<!-- none yet -->
