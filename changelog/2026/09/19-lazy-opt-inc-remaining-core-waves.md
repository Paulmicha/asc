# Remaining lazy / extraction waves (core `ASC_INC`)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | proposed, **later**. Do not start until [19-fs-archive-lazy-include.md](./19-fs-archive-lazy-include.md) and [19-db-thin-inc-and-opt-inc.md](./19-db-thin-inc-and-opt-inc.md) have landed (or been dropped). |
| **Scope** | Everything still listed in [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) that is **not** fs-archive, db-thin, or mysql/pgsql hook DRY. |
| **SoT for caveats** | Parent plan caveats (1)–(14). Especially: hooks do not see caller opt-incs; alias hook runs **before** `ASC_INC`. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## Still in the parent plan (do not rewrite here)

Implement as **separate** small PRs, one row at a time. Inventory → classify (primitive / internal / one-shot entry point / unused) → tests.

| Wave | Work | First concrete leftover |
|------|------|-------------------------|
| A rest | Remove **duplicate** `yml.inc.sh` (kernel **and** `ASC_INC` — still true in `data/asc/cache/core/active.sh`). `str.inc.sh` tail (slug/snake/random/…) → `str.opt-inc.sh` with the same **explicit `.` vs auto-derive** rule as fs (`asc/utils/` is not a caller dir). | yaml dual-source is the cheapest independent PR |
| B | `f_global_aggregate` / `global()` off kernel; init/reinit source them | `hook -s asc -a bootstrap -t` before moving `global()` |
| C | Shrink `ASC_INC`: `test.inc.sh`, then `git.inc.sh`, `make.inc.sh`, `thread.inc.sh`, `host.inc.sh`, `instance.inc.sh` | Move `f_git_write_hooks` **into** `asc/git/write_hooks.sh` (write_globals shape). `test.opt-inc.sh` first if few production hooks |
| D | Optional: hook lookup builders sourced only on cache miss | after A–C |
| Ext rest | Same drill: crontab, compose, remote, entity, … | software provision **already** lazy — leave it; do not use it as the README model |

---

## Explicit `.` for `asc/utils/*.opt-inc.sh`

Any demotion from `str.inc.sh` / leftover `fs` has the same footgun as the fs sub-plan: **filename `*.opt-inc.sh` does not auto-load from `utils/`**. Either `.` from the few callers, or the helpers are not actually lazy.

---

## Entry-point extraction candidates (parent leftover list)

Confirm with grep before moving:

- `f_git_write_hooks` → `git/write_hooks.sh` (thin wrapper today)
- `f_make_generate` / `f_make_generate_test_cases` → init-only
- `f_instance_init` → do not keep ~850 lines eager for this
- `f_host_crontab_add` / `_remove` → workflow / opt-inc

---

## Open tasks

- [ ] Yaml dual-source PR (can be done anytime; no opt-inc).
- [ ] Then str tail, then Wave B, then `test`/`git` as first `ASC_INC` subjects.
- [ ] README: two loaders + caveats (1)–(2) if not already covered by [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md).
