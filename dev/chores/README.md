# dev/chores/

Backlog of **repo chores** — tooling, hygiene, and configuration work that
isn't a function idea. One markdown file per chore, same shape and same
`Status:` gate as [../ideas/](../ideas/): read the status before doing
anything, and resolve the decisions with Ian before acting when it says so.

Function ideas go in `dev/ideas/`, not here. The split is what the work
touches: `ideas/` proposes things the package will *export*, `chores/`
proposes changes to how the repo is *built, configured, or kept tidy*.

Like `ideas/`, this folder is `.Rbuildignore`d and never ships. Chores are
not commitments either — don't start one because it's here; surface it when
it's relevant and let Ian decide.

When a chore is done: delete the file, or move it to `dev/chores/done/`.
