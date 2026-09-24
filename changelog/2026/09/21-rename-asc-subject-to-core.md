# Kernel subject dir: `asc/asc/` → `asc/core/`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-21 |
| **Status** | **done** |
| **Scope** | `git mv asc/asc asc/core`. Make pivots follow the folder: `make core-upgrade`, `make core-remote-extensions-download`. `make cc` stays (`core-cache-clear/cc` in `asc/core/global.vars.sh`). |
| **Not this change** | Renaming `hook -s 'asc'` bootstrap / alias / pre_bootstrap (those files live in `asc/extensions/*/asc/` and contrib). Nesting `arr` / `fs` / `shell` / `str` under `asc/core/utils/` — [21-utils-under-core.md](./21-utils-under-core.md). |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

`asc/asc/` was the kernel subject folder named after the project. `asc/core/` says what that folder is.

Entry points in that dir are now `$subject` = `core`. `upgrade.sh` calls `hook -s 'core' -a 'post_upgrade'` so it still finds `asc/core/post_upgrade.hook.sh`.

`hook -s 'asc' -a 'pre_bootstrap'` / `alias` / `bootstrap` in `asc/bootstrap.sh` stay. Their implementations are `$extension/asc/*.hook.sh`, not this folder.

`asc/core/core.inc.sh` is still a kernel include (needed before discovery). It now also matches `$subject/$subject.inc.sh`, so it appears on `ASC_INC` and is sourced a second time. Function-only; no extra loader.

Kernel block: `asc/core/utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`.
