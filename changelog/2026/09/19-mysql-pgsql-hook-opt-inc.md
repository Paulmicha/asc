# Mysql / pgsql hook-seeded `db.opt-inc.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | proposed (no code yet). After [19-db-thin-inc-and-opt-inc.md](./19-db-thin-inc-and-opt-inc.md) if you want abstract dump to be lazy first; can also land independently (DRY only). |
| **Scope** | `scripts/asc/contrib/asc/mysql/db/*.mysql.hook.sh` and `…/pgsql/db/*.pgsql.hook.sh`. Give hook seeding a **real** contrib example in the case table. ArcadeDB is **out** (no dump/exec hooks). |
| **Parent** | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md); cases in [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md). |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## What exists today

No `mysql.inc.sh` / `pgsql.inc.sh`. Drivers are **hook-only**. That is correct and should stay the eager story (“contrib need not have `$extension.inc.sh`”).

Mysql dump/exec/query/clear/create/destroy/exists/ensure_creds are **self-contained hook files**. `dump.mysql.hook.sh` already talks to `mysqldump` and calls `f_fs_relative_path` (eager fs). There is no `mysql/db/db.opt-inc.sh`.

`f_db_dump` in core db uses `hook_ms`, which seeds opt-incs for the **winning** hook path only (`f_hook_source_opt_incs_for_path`).

Derivation for `scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh`:

```text
dir     = scripts/asc/contrib/asc/mysql/db
subject = db
base    = dump.mysql
action  = dump          # before first '.'
tries   = mysql/db/db.opt-inc.sh
          mysql/db/dump.opt-inc.sh
```

**Not** `dump.mysql.opt-inc.sh`. Same for `dump.pgsql.hook.sh`.

Caller opt-inc for `make db-dump` does **not** load these files (caller is `asc/extensions/db/db/dump.sh`).

---

## What to extract (YAGNI)

Do **not** move the entire hook body into an opt-inc just to have a file (that is the software-provision pattern: hook is a one-liner). Mysql dump **is** the implementation; a one-liner hook plus a 100-line opt-inc is extra indirection.

Extract only **shared** pieces used by more than one hook in the same dir:

| Helper (illustrative) | Used by |
|------------------------|---------|
| skip-data / `--ignore-table` (or pgsql equivalent) | dump (maybe exec) |
| “`$db_dump_file` must be set” guard | dump + exec |
| default `mysqldump_last_arg` / `pg_dump` all-db vs named | dump |

If grep shows **no** real sharing beyond comments, **skip this plan** and keep case-table rows as “if this file existed, hook seeding would load it” — do not create empty opt-incs.

**Pick if sharing exists:** `scripts/asc/contrib/asc/mysql/db/db.opt-inc.sh` (subject-wide for that hook dir). Same for pgsql. No per-action `dump.opt-inc.sh` unless a helper is dump-only and large.

---

## ArcadeDB

`scripts/asc/contrib/asc/arcadedb/asc/alias.compose.hook.sh` + compose globals only. Alias hook runs at bootstrap from dir `arcadedb/asc/` → would seed `asc.opt-inc.sh` / `alias.opt-inc.sh`, not a db dump opt-inc. **Do not** add ArcadeDB opt-incs for the README.

---

## Tests

- `test_f_hook_opt_inc_append_candidates`: fixture `dump.mysql.hook.sh` → candidates include `db.opt-inc.sh` and `dump.opt-inc.sh` when those files exist.
- `hook_ms` without `-t`: after a dummy mysql-style hook, a function defined only in colocated `db.opt-inc.sh` exists; `-t` does not define it.
- `make db-dump` still produces a dump (mysql or pgsql, whatever this instance uses).

---

## Open tasks

- [ ] Grep mysql/pgsql hooks for duplicated blocks; extract only if duplicated.
- [ ] If extracted, case-table *planned* contrib rows become **on disk**.
- [ ] If not extracted, leave the table rows as mechanism examples (file optional).
