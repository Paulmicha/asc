# Utils modules: `asc/utils/` → `asc/core/utils/`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-21 |
| **Status** | **done** |
| **Scope** | Nest `arr` / `fs` / `shell` / `str` (and their `*.opt-inc.sh`) under `asc/core/utils/`. Hub `asc/core/utils.inc.sh` `.`s those paths. Callers of `fs.opt-inc.sh` / `str.opt-inc.sh` follow. |
| **Not this change** | Making `utils/` an active dir or a `$object`. A third include kind. Filling `utils/test/*.sh`. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

`asc/core/utils.inc.sh` is the hub. `asc/core/utils/` is the module dir. Double-ext `*.inc.sh` / `*.opt-inc.sh` are not actions, so `core/utils` is not an object and not a caller/hook dir. Callers still `.` the opt-incs.
