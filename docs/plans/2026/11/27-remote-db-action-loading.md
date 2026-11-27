# Remote DB actions: opt-inc loading and `remote-exec`

Status: completed

Repair `remote-db-sync-to`, `remote-db-sync-from`, and `remote-db-dl-from` so
bootstrap loads their helpers, callers use the existing `remote-exec` action,
arguments survive forwarding (including an empty second argument before an
explicit DB ID), and fixtures verify **completion and failure** at the actual
dump and restore operations — not merely that a stub was reached or that
`f_db_set` selected a DB in the calling shell. The outcome is recorded below.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions (what and why). This plan owns steps and acceptance for
the remote DB action work.

**Out of scope:** other ASC project instance compatibility; live SSH against
real remotes (fixtures may stub).

## Observed breaks (reviewed revision `5dc602b`)

With `remote` and `remote_asc` enabled:

| Pivot | Path shape | Problem |
| --- | --- | --- |
| `remote-db-sync-to` | `$ext/$subject/$object/$action.sh` → `…/remote/db/sync_to.sh` | Bootstrap loads subject opt-inc `…/remote/remote.opt-inc.sh`, not `…/remote/db/db.opt-inc.sh` → `f_remote_sync_db_to` undefined |
| `remote-db-sync-from` | same object dir | Same opt-inc miss; helpers call a missing `remote_asc` exec path |
| `remote-db-dl-from` | same object dir | Same |

Call sites under `remote_asc` still reference
`asc/extensions/remote_asc/remote/exec.sh`, which does not exist. The existing
action is **`remote-exec`** at `asc/extensions/remote/remote/exec.sh`
(`$ext/$subject/$action.sh` → `remote-exec`).

With only `remote` and `remote_asc` enabled, a repaired include can define
`f_remote_sync_db_to` while **`f_db_set` remains missing**. Enabling the **`db`**
extension supplies it. The action fixture must include that dependency.

Additional verified gaps:

1. **Success printed after failure.** A restore stub returning 7 still produced
   a `done` line and status zero (`f_remote_sync_db_to` does not check the
   restore / exec wrapper status before printing success).
2. **Unquoted `$@`.** Wrappers (`sync_to.sh`, `sync_from.sh`, `dl_from.sh`)
   call helpers with unquoted `$@`, which drops the documented empty second
   argument before an explicit DB ID (see helper examples such as
   `f_remote_sync_db_to my_remote_id '' my_db_id`).
3. **Make shortcut drops the empty slot.** Quoting `"$@"` inside the action is
   necessary but not sufficient for Make. Confirmed:
   `make debug example '' separate` delivered `separate` as argument **two**,
   while the direct action delivered it as argument **three**. The generated
   Make rule forwards `$(MAKECMDGOALS)` through `asc/make/call_wrap.make.sh`.
4. **DB ID not forwarded to dump/restore operations.** Sync-to runs remote
   `make db-restore` with no DB ID. Sync-from calls the local restore helper
   without one. Both download paths invoke `get_dump.sh` without one. In a
   stubbed fixture, selecting `separate` still produced a remote restore
   command with no DB argument, and the local clear/import selected
   `default`. Asserting only the shell’s selected DB after `f_db_set` can
   pass while the restore targets a different DB.
5. **Sync-to source dump ignores DB scope.** Empty-option sync-to uses
   `f_fs_get_most_recent` on the dumps root (not the per-DB dir); with only
   standard per-DB dump directories present it found no dump. The `new` option
   calls `f_db_routine_backup` without a DB ID, so a stub selected `default`
   after the caller selected `separate`. Existing DB-scoped helpers such as
   `f_db_get_dump` already take a DB ID.
6. **Restore-helper stub hides inner failures.** Stubbing only the outer
   restore result misses clear/import behavior inside `f_db_restore`. In a
   probe, clear returned 7, import still ran, the import hook returned 8, and
   `f_db_restore` returned zero.
7. **Stale action examples.** Wrapper `@example` blocks still point at old
   paths (e.g. `asc/extensions/remote_asc/db/…`) instead of the current
   `$ext/$subject/$object/$action.sh` locations beside the wiring.

## Work

1. Restore subject-level loading for the DB helpers, **scoped to the DB
   actions** (subject `remote.opt-inc.sh` that sources the db include when
   those pivots run, or relocate the include to the path bootstrap already
   resolves — without widening helper load to unrelated remote actions
   unnecessarily).
2. Point sync-from / dl-from (and other `remote_asc` callers that still use the
   missing path) at **`remote-exec`**.
3. Preserve arguments inside the action: forward with `"$@"` (or equivalent) so
   an empty second argument before an explicit DB ID remains when the action
   is invoked **directly**.
4. Forward the selected DB ID into every dump and restore operation that must
   target that DB:
   - **sync-to source selection** for empty option and `new` — use existing
     DB-scoped dump helpers (e.g. `f_db_get_dump` / per-DB most-recent and
     `f_db_routine_backup` with DB ID), not dumps-root lookup or backup
     without a DB ID;
   - remote restore (`db-restore` / equivalent) on sync-to;
   - remote `get_dump.sh` (and `new`) on sync-from and dl-from;
   - local restore / clear / import on sync-from.
5. Propagate nonzero status from restore / exec / download steps **and** from
   failures inside the real restore path (clear, then import). Do not print
   success/`done` after a failed step. A clear failure must prevent import; an
   import failure must reach the public action.
6. Fixture extensions: enable **`remote`**, **`remote_asc`**, and **`db`**.
   Provide **two distinguishable DBs** (e.g. `default` and `separate`) with
   per-DB dump directories when testing empty-option sync-to.
7. Exercise **all three pivots** (`remote-db-sync-to`, `remote-db-sync-from`,
   `remote-db-dl-from`):
   - assert the **DB at each actual dump/restore operation** (command args or
     stub capture), not only `DB_ID` / `f_db_set` in the calling shell;
   - for sync-to **empty** and **`new`**: assert the **uploaded file** comes
     from the selected DB’s dump path / backup helper, and assert the restore
     target DB;
   - include empty-second-arg + explicit DB ID via the **direct action path**;
   - assert the **final status**;
   - exercise the **real** `f_db_restore` (or sync-from’s call into it) with
     stubbed **clear** and **import** operations — not only an outer restore
     stub returning nonzero;
   - assert a **failed prerequisite** (e.g. missing `f_db_set` / `db` disabled,
     or a failed earlier step) **prevents restore**;
   - stubbed sync-from / dl-from check the exec path is the real `remote-exec`
     action.
8. Document how the Make shortcut is tested for these pivots: either a
   separate case that records Make’s empty-arg limitation, or an explicit
   non-empty-arg Make path — empty-slot acceptance must not rely on
   `make … '' <db_id>`.
9. Update the action `@example` / `@see` blocks alongside the wiring so they
   name the current pivots and paths.

## Acceptance

- With `remote`, `remote_asc`, and `db` enabled, each of the three pivots loads
  its helper and reaches the stubbed expected operations with the **expected
  arguments**, including the empty second argument before an explicit DB ID on
  the **direct action** path.
- Fixture uses two distinguishable DBs. Selecting the non-default DB must
  appear on **sync-to source dump** (empty and `new`), **download dump
  lookup**, **remote restore**, and **local restore/clear/import** stubs as
  applicable — not only in the calling shell after `f_db_set`. A gate that
  only checks selected DB in one shell while restore targets `default` (or
  omits the DB argument) fails.
- Sync-to empty and `new`: assert both the **uploaded file** (DB-scoped path /
  backup with DB ID) and the **restore target**.
- Reaching an outer stub is not enough: assert **DB at each operation**,
  **final status**, and that failures **below** the restore helper propagate —
  clear returning nonzero must **not** run import; import returning nonzero
  must yield **nonzero** on the public action with **no** success/`done` for
  that step. An outer restore stub alone is insufficient acceptance.
- A failed prerequisite prevents restore (or the corresponding remote
  mutation) and fails the public action.
- Stubbed sync-from and dl-from resolve `remote-exec` rather than
  `remote_asc/remote/exec.sh`.
- Empty-slot coverage uses direct action paths; Make shortcut coverage is
  documented separately and does not pretend Make preserves `''`.
- A check that only asserts the first helper is defined is insufficient and
  must not be the sole gate.
- No new duplicate exec action under `remote_asc`.
- Documented examples match the wired paths.

## Order

After
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md) if the
fixture needs a working remote lifecycle; otherwise can proceed once opt-inc
and `remote-exec` wiring are the only blockers under test.

## Implementation and verification (27 November)

All three actions load their dependencies and forward the selected DB to the relevant dump and restore operations. Explicit remote source paths are downloaded by basename into the selected remote/DB directory; explicit local uploads use the selected remote DB directory. Isolated action fixtures cover both DBs and injected failures; no real SSH or database operation was run.

The integrated `make test-core` passed in an initialized disposable checkout with the remote extension enabled. This was local fixture acceptance; no live remote, database, or host crontab operation was performed.
