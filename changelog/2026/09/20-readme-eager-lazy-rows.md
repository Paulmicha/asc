# README proposal: eager / lazy example rows

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | proposed README delta. Not applied. |
| **Target** | [`README.md`](../../../README.md) — **Always (= eager) VS conditionally (= lazy) sourced includes** → **Recap** table (and the stray lines under it). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

## Why

The Recap table only shows two eager name-matches, then `TODO [wip] complete the examples to match all cases`, then leftover chat pointing. That TODO is not a row; the chat text is not README.

## Exact edit

**Delete** (do not keep in README):

```text
TODO [wip] complete the examples to match all cases.

asc/utils/fs.inc.sh — eager, but not an active-dir name match.
Kernel via core_utils.inc.sh.
Your bullets currently imply eager = parent-dir filename match only.
That is incomplete.
```

**Replace** the Recap table with:

| File | Type | Bootstrapping context | Sourced | Why |
|------|------|-----------------------|---------|-----|
| `asc/git/git.inc.sh` | eager | (any) | ✅ yes | `asc/git` is an *active dir* and `git.inc.sh` matches its name |
| `asc/extensions/compose/compose.inc.sh` | eager | (any) | ✅ yes | `asc/extensions/compose` is an *extension point* and `compose.inc.sh` matches its name |
| `asc/utils/fs.inc.sh` | eager | (any heavy bootstrap) | ✅ yes | Kernel: `core_utils.inc.sh` always `.`s it. Not an active-dir name match. |
| `asc/extensions/remote_instance/db/db.opt-inc.sh` | lazy caller | `…/db/sync_to.sh` | ✅ yes | On disk. Caller dir `db/` → 2-level `$subject` `db`. |
| `asc/extensions/remote_instance/db/db.opt-inc.sh` | lazy caller | `make git-status` | ❌ no | Wrong caller. Caller opt-inc only looks next to `BASH_SOURCE[1]`. |

**Add** one sentence at the end of **Exceptions** (file `fs.opt-inc.sh` is not on disk yet — do not put it in the table):

`asc/utils/` is not a caller dir and has no `*.hook.sh`, so a `*.opt-inc.sh` there is never auto-derived; callers must `.` it.

## Not this edit

Do not paste the working case table. Do not add `fs.opt-inc.sh` / `db/db/db.opt-inc.sh` rows until those files exist. Do not rewrite the two lazy bullets here (second proposal if you want caller-dir vs hook named in prose).
