# icu_setup() — guided .Rprofile configuration check

**Status:** design agreed in principle (2026-08-23) — guide approach, not
writer. Details to settle at implementation.
**Proposed file:** R/setup.R
**Depends on:** nothing structurally, but exists because create_project and
new_main() read `options()` values. Update the option list here whenever a
new `icu.*` option ships.

## Motivation

Effective use of icu depends on `.Rprofile` options that vanish from memory
between machine setups and R upgrades:

- `icu.projects_dir` — where new_project() puts new projects (unset →
  loud getwd() fallback, by design). **Shipped 2026-08-23** — and note
  what its warning says: the spec had it pointing at `icu_setup()`, but
  since this function does not exist yet, it points at
  `options(icu.projects_dir = ...)` in `.Rprofile` instead (Ian's call —
  a warning that tells you mid-meeting to call a missing function is
  worse than no pointer at all). **When icu_setup() ships, revisit that
  text**: it is a one-line edit in R/project.R plus the test in
  test-project.R that pins `.Rprofile`. That is also the concrete answer
  to open question 3 below, deferred rather than decided.
  Set-but-missing directories are created and used silently; a value that
  is not a usable path falls back the same way an unset one does. See
  done/project-scaffold.md, "As shipped" items 3–5.

(`icu.author` was retired 2026-08-23 — the template went fully static with
the author hardcoded, leaving the option no consumer. With one option
remaining, reconsider at implementation whether icu_setup() still earns
its keep now vs. waits until a second option exists.)

`icu_setup()` is run once per new machine / R upgrade to get these set.

## Design: guide, not writer

Rejected the interactive **writer** (function edits `.Rprofile` itself):
parsing and deduplicating a load-bearing user-owned file has worse failure
modes (stale duplicates, clobbered comments) than the ten seconds of pasting
it saves.

The **guide** instead:

1. Checks each known `icu.*` option; reports set/unset status and current
   values.
2. Prints a ready-to-paste `options()` block, prompting for values to fill
   in (or leaving `'...'` placeholders — decide at implementation).
3. Opens `.Rprofile` via `usethis::edit_r_profile()` (or thin equivalent —
   check whether it justifies a usethis dependency vs.
   `file.edit('~/.Rprofile')`; lean the latter, no new dependency).

## Open questions

1. Prompt interactively for values (readline) vs. print placeholders only.
2. usethis dependency question above.
3. Should other icu functions that hit an unset option point at
   `icu_setup()` in their warning/error text? (Lean yes — cheap
   discoverability.)

## Testing notes

- Status-checking logic fully testable with `withr::local_options()`.
- The prompt/open step is untestable — keep it thin and isolated, per house
  convention (same regime as new_main()'s editor-opening code).
