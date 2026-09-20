# Living agent write-watcher notes vs runtime stdout

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **decided** (working note, not README SoT). No runtime. No ables. No loaders. |
| **Scope** | Where living **agent** review notes land, and how scripts print. Not a sidecar/store fill. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`) except `$BASH_SOURCE` / `$LINENO` (shell).

---

Living **agent** write-watcher notes go to gitignored `data/changes/agent/review/watcher-*.md` (tree already ignores that dir except `README.md`). Changelog only when a durable **human** decision. Not `data/logs/` — that is `log.wrap` pivot capture.

Do **not** fill empty `asc/data/store.able.yml` / `asc/sidecar/sidecar.able.yml`. Do not mint `stdout.able` / `gap.able`. Those YAML copies are 0-byte stubs.

Runtime stdout stays `echo` / `echo >&2` plus the existing `Error in $BASH_SOURCE line $LINENO` / `Aborting (1).` idiom. `printf -v` stays return-by-var. No `u_log` helper unless a named multi-file caller appears and someone asks.

README still describes sidecar/store contracts that are empty on disk. A later `changelog/YYYY/MM/DD-readme-sidecar-store-stubs.md` is the human’s call, not this file.
