# Remote DB actions: opt-inc loading and `remote-exec`

Status: draft

Repair `remote-db-sync-to`, `remote-db-sync-from`, and `remote-db-dl-from` so
bootstrap loads their helpers and callers use the existing `remote-exec`
action. This plan describes proposed work; it does not claim implementation or
authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) is the
source of truth.

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

## Work

1. Restore subject-level loading for the DB helpers (subject
   `remote.opt-inc.sh` that sources the db include, or relocate the include to
   the path bootstrap already resolves).
2. Point sync-from / dl-from (and other `remote_asc` callers that still use the
   missing path) at **`remote-exec`**.
3. Fixture extensions: enable **`remote`**, **`remote_asc`**, and **`db`**.
4. Add fixtures:
   - `remote-db-sync-to` checks helper loading and reaches a **stubbed**
     expected DB operation with the **expected arguments** (not merely “first
     missing helper is gone”).
   - Stubbed `remote-db-sync-from` or `remote-db-dl-from` checks the exec path
     is the real `remote-exec` action (fails clearly if still missing).

## Acceptance

- With `remote`, `remote_asc`, and `db` enabled, `remote-db-sync-to` loads
  `f_remote_sync_db_to` and proceeds far enough that the stubbed expected
  operation is invoked with the expected arguments (fixture may stop before
  real transfer).
- A check that only asserts the first helper is defined is insufficient and
  must not be the sole gate.
- Stubbed sync-from or dl-from resolves `remote-exec` rather than
  `remote_asc/remote/exec.sh`.
- No new duplicate exec action under `remote_asc`.

## Order

After
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md) if the
fixture needs a working remote lifecycle; otherwise can proceed once opt-inc
and `remote-exec` wiring are the only blockers under test.
