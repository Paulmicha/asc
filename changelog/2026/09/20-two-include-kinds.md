# Two include kinds; `utils/` opt-inc is explicit `.`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | done (rule + this note). No runtime code. No README edit. |
| **Scope** | [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc) — two filename kinds only. Filename for the fs split stays `asc/utils/fs.opt-inc.sh`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

Locked: `*.inc.sh` (eager) and `*.opt-inc.sh` (lazy). No third suffix (`private-inc` rejected — it reads as “don’t call me”; dump/exec must `.` the archive helpers).

`asc/utils/` is not a caller dir and has no `*.hook.sh`. Loaders never derive `fs.opt-inc.sh`. Callers `.` it. Same token as `db/db/db.opt-inc.sh`; the difference is the folder, not a new spelling.

Does not create `fs.opt-inc.sh`. Does not fill README rows (human).
