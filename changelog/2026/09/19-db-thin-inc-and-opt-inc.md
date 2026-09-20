# Thin eager `db.inc.sh` + subject-wide `db.opt-inc.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | pick A locked (caller-dir `db/db/db.opt-inc.sh`). Loader coverage in `asc/test/core/caller_opt_inc.test.sh`. Function move still later. After [19-fs-archive-lazy-include.md](./19-fs-archive-lazy-include.md) if dump/exec should `.` `fs.opt-inc.sh`. |
| **Scope** | `asc/extensions/db/db.inc.sh` (~1501 lines) is `$extension/$extension.inc.sh` → **every** bootstrap when db is enabled. Most of it is dump/exec/restore orchestration only needed for `db-*` actions (and two setup hooks). |
| **Parent** | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) function drill + Wave C (this extension only). |
| **Examples SoT** | [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md) |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## What is already the right shape (do not undo)

These entry points already **contain the work**; they are not thin wrappers around `db.inc.sh`:

| Script | Uses from eager db |
|--------|---------------------|
| `db/dump_reduce.sh` (~154) | `f_fs_extract_in_place` only |
| `db/list_dumps.sh` (~81) | `f_db_get_ids` + fs list/relative |
| `db/get_credentials.sh` (~64) | `f_db_get_ids` / `f_db_set` / `f_db_vars_list` |
| `db/list_ids.sh` (~23) | `f_db_get_ids` |

Leave them as entry points (same idea as `instance/write_globals.sh`).

**Anti-pattern still on disk:** `dump.sh`, `exec.sh`, `query.sh`, `restore.sh`, `restore_last.sh`, `restore_any.sh`, `setup.sh`, `create.sh`, `destroy.sh`, `clear.sh`, `routine_backup.sh`, `get_dump.sh`, `ensure_creds.sh` — bootstrap then `f_db_* "$@"`. The **body** lives in eager `db.inc.sh`.

Those functions **call each other** (`restore` → `clear` + `exec`; `setup` → `exists` + `create` + `restore_any`; `routine_backup` → `dump`). Moving each body into its `*.sh` would create a source web. **Pick: one subject-wide opt-inc**, keep the wrappers thin.

---

## Path (the README trap)

| File | Role |
|------|------|
| `asc/extensions/db/db.inc.sh` | Eager extension-root include (`ASC_INC`) |
| `asc/extensions/db/db/db.opt-inc.sh` | Lazy, loaded by caller opt-inc from `db/dump.sh` etc. |
| `asc/extensions/db/db.opt-inc.sh` | **Not auto-loaded** (pick A) — caller dir is `db/db/`, not `db/` |

Caller opt-inc for `asc/extensions/db/db/dump.sh`:

```text
<dir>     = asc/extensions/db/db
<subject> = db
<action>  = dump
tries     = db/db/db.opt-inc.sh , db/db/dump.opt-inc.sh
```

Do **not** add `dump.opt-inc.sh` unless dump-only helpers appear. One `db.opt-inc.sh` is enough.

---

## Keep eager vs move lazy

**Eager `db.inc.sh` (shared primitive — other subjects’ hooks):**

| Function | Callers outside `db/db/*.sh` |
|----------|------------------------------|
| `f_db_set` / `f_db_unset` / `f_db_set_all` / `f_db_get_ids` / `f_db_vars_list` | `db/asc/bootstrap.compose.hook.sh`, `instance/pre_{init,start,stop,build,destroy,rebuild}.hook.sh`, mysql/pgsql `wait_for.compose.hook.sh`, drupalwt/moodle `*.inc.sh`, remote_instance opt-inc |
| `f_db_exists` | setup; driver `exists.*.hook.sh` is the implementation, wrapper stays with creds |
| `f_db_is_flagged` / `f_db_flag*` / `f_db_unflag*` / `f_db_get_flag_key` | `instance/stage2_setup.hook.sh`, `post_destroy.hook.sh`, `app/install.hook.sh` |

Alias hooks (`mysql/asc/alias.compose.hook.sh`, `arcadedb/asc/alias.compose.hook.sh`) run **before** `ASC_INC`. They use `DB_HOST` / `dc_db_service_name` / globals, not `f_db_*` at first pass. `f_db_set_all` runs from **bootstrap** hook (after `ASC_INC`). That is why creds stay eager, not why they would work in an opt-inc next to `dump.sh`.

**Move to `asc/extensions/db/db/db.opt-inc.sh`:**

`f_db_exec`, `f_db_query`, `f_db_dump`, `f_db_clear`, `f_db_restore`, `f_db_restore_last`, `f_db_routine_backup`, `f_db_get_dump`, `f_db_ensure_creds`, `f_db_create`, `f_db_destroy`, `f_db_setup`, `f_db_restore_any`.

At the top of that opt-inc, `. asc/utils/fs.opt-inc.sh` once dump/exec need extract/compress (fs sub-plan).

---

## Hook dirs that are **not** `db/db/`

`f_db_setup` is called from:

- `asc/extensions/db/instance/stage2_setup.hook.sh`
- `asc/extensions/db/app/install.hook.sh`

Hook seeding there would look for `instance/instance.opt-inc.sh` / `stage2_setup.opt-inc.sh` and `app/app.opt-inc.sh` / `install.opt-inc.sh` — **not** `db/db.opt-inc.sh`.

**Pick:** those two hooks `. asc/extensions/db/db/db.opt-inc.sh` at the top (override-aware if you already have a helper; otherwise a plain `.` is enough for v1). Do **not** duplicate setup into `instance.opt-inc.sh`.

`remote_instance/db/db.opt-inc.sh` already calls `f_db_set` (eager), `f_db_routine_backup`, `f_db_restore`. After the move it must `.` `asc/extensions/db/db/db.opt-inc.sh` (composition, db-to-db, not software-to-host).

`remote_db/remote/remote.opt-inc.sh` — grep on implementation: uses `f_fs_get_most_recent` / dump paths; keep working without pulling the whole dump orchestrator unless a call site needs `f_db_dump`.

---

## Entry-point extraction vs opt-inc (this slice)

| Kind | Pick |
|------|------|
| Mutual dump/exec/restore/setup cluster | **opt-inc** (`db/db.opt-inc.sh`) |
| One-shot listing / credentials / reduce | **already in `*.sh`** |
| `f_git_write_hooks`-style leftover | not db; remaining-core plan |

Do **not** fold `dump_reduce.sh` back into an include.

---

## Tests

- `make db-list-ids` / `db-get-credentials` still work with only eager `db.inc.sh` (no opt-inc required).
- After move: `type -t f_db_dump` empty in a shell that bootstrapped via e.g. `asc/git/…` (or interactive); defined after `. asc/extensions/db/db/dump.sh` **without** executing the dump (source the wrapper? wrappers currently always run `f_db_dump`. Better: source `db.opt-inc.sh` in the test, or add the write_globals `BASH_SOURCE` guard later).
- `hook -s instance -a setup` / stage2 path still sees `f_db_setup` (explicit `.` in the hook).
- `make db-dump` still runs mysql/pgsql `hook_ms` (contrib unchanged until mysql sub-plan).

---

## Open tasks

- [ ] Move the workflow cluster; keep creds/flags eager.
- [ ] Explicit `.` in `stage2_setup.hook.sh`, `app/install.hook.sh`, `remote_instance/db/db.opt-inc.sh`.
- [ ] Point wrapper comments at `db/db.opt-inc.sh`.
- [ ] Mark case-table *planned* row on disk.
