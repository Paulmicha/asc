# README table of contents on pre-commit

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | implemented |
| **Scope** | `asc/doc/md_toc.sh`, `asc/git/pre-commit.hook.sh`, `asc/git/global.vars.sh` |

## What

`pre-commit` regenerates the list inside the first `<nav>` block of the repository `README.md`, using `asc/doc/md_toc.sh`, then stages that file.

It runs only when `README.md` is already part of the commit and that file has a `<nav>` line. A README without that block is left alone. Other staged paths are not read.

`asc/doc/md_toc.sh` does the same for any `README.md`: no `<nav>` … `</nav>` pair means exit 0 and no write. Another markdown path still errors when that pair is missing.

`asc/core/global.vars.sh` still defaults `ASC_GIT_HOOKS_WIRED` to empty. `asc/git/global.vars.sh` appends `pre-commit`, so the next instance init writes that one hook. The checker listener is still absent.

This checkout's `.git/hooks/pre-commit` is written by `asc/git/write_hooks.sh pre-commit`. That file is not committed.
