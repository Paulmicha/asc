# Eager vs lazy includes — complete case table

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | **pick A locked** (2026-09-20). Nested `$extension/$subject/$action.sh` uses **caller-dir** opt-inc (`db/db/db.opt-inc.sh`). Caller opt-inc does **not** load `$extension/$extension.opt-inc.sh`. Coverage: `asc/test/core/caller_opt_inc.test.sh` (`make test-core`). Two include kinds only (`*.inc.sh` / `*.opt-inc.sh`); `utils/fs.opt-inc.sh` stays that name ([20-two-include-kinds.md](./20-two-include-kinds.md)). Root README Recap applied ([20-readme-eager-lazy-rows.md](./20-readme-eager-lazy-rows.md)). Function move still later. |
| **Scope** | Document **every** auto-loader case. Examples from `asc/utils/fs.inc.sh`, `asc/extensions/db`, `scripts/asc/contrib/asc/mysql`, `pgsql`, `arcadedb`, plus the two **existing** db-related opt-incs. Do **not** use `asc/extensions/software` or `asc/host/provision.sh`. |
| **Parent** | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) |
| **Follows** | [19-fs-archive-lazy-include.md](./19-fs-archive-lazy-include.md), [19-db-thin-inc-and-opt-inc.md](./19-db-thin-inc-and-opt-inc.md), [19-mysql-pgsql-hook-opt-inc.md](./19-mysql-pgsql-hook-opt-inc.md) create the rows marked *planned*. |

`$` in this file is the ASC docs placeholder (`$subject` / `$object` / `$action` / `$extension`), not a shell variable.

---

## Loaders (two, not three)

There is **no** `ASC_OPT_INC` glob and **no** scan of `asc/utils/*.opt-inc.sh`.

| Loader | When | Derives |
|--------|------|---------|
| **Eager** | Heavy bootstrap (`ASC_BS_FLAG` was not 1): kernel, then every path in `ASC_INC` | `$subject/$subject.inc.sh` in an *active dir*; `$extension/$extension.inc.sh` in an *extension point* (core, `asc/extensions/…`, contrib). Kernel utils are sourced by `asc/utils/core_utils.inc.sh` even though `utils/` is not an active dir. |
| **Caller opt-inc** | **Every** `. asc/bootstrap.sh`, including when already bootstrapped | From `BASH_SOURCE[1]`: `<dir>/<subject>.opt-inc.sh` then `<dir>/<action>.opt-inc.sh`. If `<parent>/<dir>` is a discovered `$subject/$object` pair, `<subject>` is the **parent** folder (3-level). |
| **Lazy hook** | `hook()` / `hook_ms()` non-dry-run, for each existing `*.hook.sh` path (ms: the winning path only) | `<hook-dir>/<hook-dir-basename>.opt-inc.sh` and `<hook-dir>/<action>.opt-inc.sh` where `<action>` is the hook basename with `.hook.sh` stripped, then **everything before the first `.`**. |

Interactive `. asc/bootstrap.sh` has no `BASH_SOURCE[1]` → **no** caller opt-inc. `hook -t` never sources opt-incs.

---

## Nesting trap (db-related paths)

`$extension/$subject/$action.sh` is **two-level** from the subject’s point of view. `$subject/$object/$action.sh` is **three-level** only when `$subject/$object` is in `ASC_OBJECTS` / `*_OBJECTS`.

| Script | Looks like | Loader sees | Subject opt-inc tried |
|--------|------------|-------------|------------------------|
| `asc/extensions/db/db/dump.sh` | ext + subject + action | 2-level subject `db` | `asc/extensions/db/db/db.opt-inc.sh` (**not** `asc/extensions/db/db.opt-inc.sh` next to eager `db.inc.sh`) |
| `asc/extensions/remote_instance/db/sync_to.sh` | same shape | 2-level subject `db` | `asc/extensions/remote_instance/db/db.opt-inc.sh` (**on disk today**) |
| `asc/instance/registry/get.sh` | subject + object + action | 3-level (`instance/registry` is in `ASC_OBJECTS`) | `asc/instance/instance.opt-inc.sh` and `asc/instance/registry/get.opt-inc.sh` |

Putting dump helpers in `asc/extensions/db/db.opt-inc.sh` (beside the eager include) would **not** load for `make db-dump`. **Pick A (locked):** that is correct, not a spelling mistake. Tests: `asc/test/core/caller_opt_inc.test.sh`.

---

## Case table

Legend: **on disk** = file exists today. **planned** = filename the follow-up sub-plans will add. **absent** = illustrates a loader case; file must not be invented just for the table (ArcadeDB).

| Bootstrapping context | Type | File | Sourced | Why |
|-----------------------|------|------|---------|-----|
| (any heavy bootstrap) | eager | `asc/utils/fs.inc.sh` | ✅ yes | Kernel: `core_utils.inc.sh` always `.`s it. Not an active-dir name match. |
| (any) | eager | `asc/git/git.inc.sh` | ✅ yes | `asc/git` is an *active dir* and `git.inc.sh` matches its name |
| (any, **compose enabled**) | eager | `asc/extensions/compose/compose.inc.sh` | ✅ yes | Same rule as db: *extension point* + matching `$extension.inc.sh` |
| (any, **db enabled**) | eager | `asc/extensions/db/db.inc.sh` | ✅ yes | `asc/extensions/db` is an *extension point* and `db.inc.sh` matches its name |
| (any, mysql enabled) | eager | `scripts/asc/contrib/asc/mysql/mysql.inc.sh` | ❌ no file | Contrib **may** ship `$extension.inc.sh`. Mysql/pgsql/arcadedb currently do **not** — they are hook-only drivers. |
| `…/remote/db_upload.sh` (e.g. remote db upload) | lazy caller | `asc/extensions/remote_db/remote/remote.opt-inc.sh` | ✅ yes (**on disk**) | 2-level: caller dir `remote`, `$subject` = `remote` → `remote.opt-inc.sh` |
| `…/db/sync_to.sh` | lazy caller | `asc/extensions/remote_instance/db/db.opt-inc.sh` | ✅ yes (**on disk**) | 2-level inner subject `db` (not 3-level `remote_instance/db`) |
| `make db-dump` → `db/dump.sh` | lazy caller | `asc/extensions/db/db/db.opt-inc.sh` | planned | Subject-wide lazy API for dump/exec/restore. See db sub-plan. |
| `make db-dump` only | lazy caller | `asc/extensions/db/db/dump.opt-inc.sh` | optional / usually skip | Action-only opt-inc. Prefer **one** `db.opt-inc.sh` unless dump-only helpers appear. |
| `make instance-registry-get` | lazy caller (3-level) | `asc/instance/registry/get.opt-inc.sh` | if file exists | `$action` opt-inc stays in the **object** dir. Pair `instance/registry`. |
| same | lazy caller (3-level) | `asc/instance/instance.opt-inc.sh` | if file exists | `$subject` opt-inc is the **parent** `instance/`, not `registry/registry.opt-inc.sh` |
| `hook_ms -s db -a dump` when `dump.mysql.hook.sh` wins | lazy **hook** | `scripts/asc/contrib/asc/mysql/db/db.opt-inc.sh` | planned | Hook dir basename `db` → `db.opt-inc.sh`, seeded **before** the hook body |
| same | lazy **hook** | `scripts/asc/contrib/asc/mysql/db/dump.opt-inc.sh` | optional | `dump.mysql.hook.sh` → action = `dump` (stem **before first `.`**), **not** `dump.mysql.opt-inc.sh` |
| `dump.pgsql.hook.sh` wins | lazy **hook** | `scripts/asc/contrib/asc/pgsql/db/db.opt-inc.sh` | planned | Same derivation as mysql |
| any **auto** loader | include (manual) | `asc/utils/fs.opt-inc.sh` | ❌ never | `utils/` is not a caller dir and has no `*.hook.sh`. Bootstrap will not derive this path. Callers must `.` it. See fs sub-plan. |
| `make git-status` | caller opt-inc | `asc/extensions/db/db/db.opt-inc.sh` | ❌ no | Wrong caller. Caller opt-inc only looks next to `BASH_SOURCE[1]`. |
| `make db-dump` **before** `hook_ms dump` | lazy hook | `scripts/asc/contrib/asc/mysql/db/db.opt-inc.sh` | ❌ not yet | Caller is `asc/extensions/db/db/dump.sh`, not contrib. Mysql helpers arrive when the **hook** runs (`hook_ms`), not at caller opt-inc. |
| interactive `. asc/bootstrap.sh` | lazy caller | *(none)* | ❌ no | No `BASH_SOURCE[1]` |
| wrap process `call_wrap.make.sh` | lazy caller | `asc/make/make.opt-inc.sh` | if file exists | Wrap and action are **two** processes. Wrap does **not** see `db/db.opt-inc.sh`. |
| — | — | `scripts/asc/contrib/asc/arcadedb/*.opt-inc.sh` | ❌ not needed | ArcadeDB is aliases + compose globals only. Do not invent an opt-inc for the table. |

---

## Short “why two loaders” paragraph

`make db-dump` sources `asc/extensions/db/db/dump.sh` → caller opt-inc can load `db/db.opt-inc.sh` (abstract dump/exec/compress). The mysql (or pgsql) implementation lives in `scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh`. That path is **not** the bootstrap caller, so its colocated opt-inc is loaded only when `hook_ms -s db -a dump` seeds it. Same action, two directories, two loaders.

`f_db_set` / `f_db_set_all` stay **eager** (`db.inc.sh`): `asc/extensions/db/asc/bootstrap.compose.hook.sh` and `instance/pre_start.hook.sh` (etc.) call them from **other** subjects. Those hook dirs would seed `asc.opt-inc.sh` / `instance.opt-inc.sh`, not `db/db.opt-inc.sh`.

---

## What not to put in a short README table

- `asc/extensions/software/**` and `asc/host/provision.sh` — composition model is real, but the teaching surface should be dump/extract/creds.
- A row that says `asc/utils/fs.opt-inc.sh` is auto-sourced — that would teach the wrong derivation.
- Treating `asc/extensions/db/db.opt-inc.sh` (extension root) as the lazy file for `db/dump.sh`.

---

## Open tasks

- [x] Agree the table (especially: skip per-action `dump.opt-inc.sh` in favor of subject-wide `db.opt-inc.sh`; 3-level example = `instance/registry` not `host/provision`). **Pick A:** caller-dir only; no extension-root auto-load. Tests: `asc/test/core/caller_opt_inc.test.sh`.
- [x] README Recap: 3–5 rows ([20-readme-eager-lazy-rows.md](./20-readme-eager-lazy-rows.md) applied). Do not paste this matrix.
- [ ] After fs/db/mysql sub-plans land, change *planned* rows to **on disk**.
