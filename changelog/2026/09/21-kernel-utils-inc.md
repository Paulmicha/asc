# Kernel utils hub: `asc/core/utils.inc.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-21 |
| **Status** | **done** |
| **Scope** | `git mv asc/utils/core_utils.inc.sh asc/asc/utils.inc.sh` (hub is now `asc/core/utils.inc.sh` — [21-rename-asc-subject-to-core.md](./21-rename-asc-subject-to-core.md)). Bootstrap `.` line. Same hub contents (`arr` / `fs` / `shell` / `str`). |
| **Not this change** | Nesting the modules under `asc/core/utils/` — [21-utils-under-core.md](./21-utils-under-core.md). Making `utils/` an active dir. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

`core_utils` was a nickname. The hub now sits with the other kernel includes. The module dir is `asc/core/utils/` (not an active dir, not a caller/hook dir) — [21-utils-under-core.md](./21-utils-under-core.md).

Kernel block: `utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`. Root README hub / kernel-include sentences and the garage rule use the new path.
