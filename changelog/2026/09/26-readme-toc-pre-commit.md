# README table of contents on pre-commit

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | implemented |
| **Scope** | `asc/doc/md_toc.sh`, `asc/git/write_hooks.sh`, `asc/git/pre-commit.hook.sh`, `asc/git/global.vars.sh` |

## What

`pre-commit` regenerates the list inside the first `<nav>` block of the repository `README.md`, using `asc/doc/md_toc.sh`, then stages that file.

It runs when `README.md` has a `<nav>` line and no unstaged edits, then stages that file even if it was not already part of the commit. A README without that block is left alone. An untracked README is left alone. Other paths are not read.

`pre-commit` passes no arguments. `asc/git/write_hooks.sh` stores `git_hook_args_nb` (a scalar, `0` in that case) and then `git_hook_args`. An empty array has no element 0, so `${git_hook_args+x}` is empty. Listeners read the count.

`asc/doc/md_toc.sh` does the same for any `README.md`: no `<nav>` … `</nav>` pair means exit 0 and no write. Another markdown path still errors when that pair is missing.

`asc/core/global.vars.sh` still defaults `ASC_GIT_HOOKS_WIRED` to empty. `asc/git/global.vars.sh` appends `pre-commit`, so the next instance init writes that one hook. The checker listener is still absent.

This checkout's `.git/hooks/pre-commit` is written by `asc/git/write_hooks.sh pre-commit`. That file is not committed.
