# Remaining lazy / extraction waves (core `ASC_INC`)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | yaml dual-source **done** (2026-09-20). Str tail **done** (2026-09-20). Wave B **done** (2026-09-20): init-only globals → `asc/core/global.opt-inc.sh` (explicit `.`). Empty kernel `global.inc.sh` **deleted**. `f_make_generate` → `asc/make/generate.sh` **done** (2026-09-20). Wave C `test` **done** (2026-09-20). Wave C `git` **done** (2026-09-22): `asc/git/git.opt-inc.sh`; `git.inc.sh` **deleted** (off `ASC_INC`). Next leftover: `make.inc.sh`. |
| **Scope** | Everything still listed in [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) that is **not** fs-archive, db-thin, or mysql/pgsql hook DRY. **Not** host catalog of project instances — [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) (later, separate). |
| **SoT for caveats** | Parent plan caveats (1)–(14). Especially: hooks do not see caller opt-incs; alias hook runs **before** `ASC_INC`. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## Still in the parent plan (do not rewrite here)

Implement as **separate** small PRs, one row at a time. Inventory → classify (primitive / internal / one-shot entry point / unused) → tests.

| Wave | Work | First concrete leftover |
|------|------|-------------------------|
| A rest | Remove **duplicate** `yml.inc.sh` (kernel **and** `ASC_INC`). `str.inc.sh` tail (slug/snake/random/…) → `str.opt-inc.sh` with the same **explicit `.` vs auto-derive** rule as fs (`asc/core/utils/` is not a caller dir). | **Yaml done. Str tail done** (random/basic-auth stayed eager). Wave B done. Next: Wave C |
| B | `f_global_aggregate` / `global()` off kernel; init/reinit source them | **Wave B done** (2026-09-20). `hook -s asc -a bootstrap -t`: empty matches; no stub. |
| C | Shrink `ASC_INC`: `test.inc.sh`, then `git.inc.sh`, `make.inc.sh`, `thread.inc.sh`, `host.inc.sh`, `instance.inc.sh` | **test** and **git** off `ASC_INC`. Next: `make.inc.sh`. |
| D | Optional: hook lookup builders sourced only on cache miss | after A–C |
| Ext rest | Same drill: crontab, compose, remote, entity, … | software provision **already** lazy — leave it; do not use it as the README model |

---

## Explicit `.` for `asc/core/utils/*.opt-inc.sh`

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

- [x] Yaml dual-source PR (can be done anytime; no opt-inc). Kernel line removed; `yml.inc.sh` stays on `ASC_INC`. Tests: `test_asc_yml_inc_not_in_kernel_includes`, `test_asc_yml_inc_on_asc_inc_defines_parse`.
- [x] Str tail: slug/snake/transliterate → `asc/core/utils/str.opt-inc.sh` (explicit `.` from `host.inc.sh` slug path, `instance/slug.sh`, `instance/snake.sh`, `utilities.test.sh`). `f_str_random` / `f_str_basic_auth_credentials` stay eager (global.vars). Test: `test_f_str_slug_helpers_absent_from_kernel_bootstrap`.
- [x] Wave B: `f_global_list` / `f_global_lookup_paths` / `f_global_aggregate` / `f_global_assign_value` / `global()` → `asc/core/global.opt-inc.sh` (explicit `.`). Empty kernel `global.inc.sh` **deleted** (2026-09-20) — [20-drop-empty-kernel-global-inc.md](./20-drop-empty-kernel-global-inc.md). Test: `test_f_global_aggregate_helpers_absent_from_kernel_bootstrap`.
- [x] `f_make_generate` / `f_make_generate_test_cases` → `asc/make/generate.sh` (write_globals shape; list/unescape/hardcoded stay eager).
- [x] Wave C leftover: `f_test_*` → `asc/test/test.opt-inc.sh` (explicit `.` from generate + hooks outside `asc/test/`). Empty `test.inc.sh` **deleted** so `test` leaves `ASC_INC` (same as empty kernel `global.inc.sh`). Test: `test_f_test_batch_exec_helpers_absent_from_kernel_bootstrap`.
- [x] Then Wave C: `git` as next `ASC_INC` subject. `asc/git/git.opt-inc.sh`. `init.hook.sh`, `find_changed_files.sh`, and `samples/pre-commit.hook.sh` source it when caller/hook seeding does not. Test: `test_git_helpers_absent_from_bare_bootstrap`.
- [x] README: four kernel includes (empty `global.inc.sh` deleted; `global()` in `global.opt-inc.sh`).
