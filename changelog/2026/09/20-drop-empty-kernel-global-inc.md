# Drop empty kernel `global.inc.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **done** (runtime). README still lists five kernel includes — [20-readme-four-kernel-includes.md](./20-readme-four-kernel-includes.md). |
| **Scope** | After Wave B, `asc/asc/global.inc.sh` was a comment-only stub still sourced every heavy bootstrap. Deleted it and the bootstrap `.` line. Helpers stay in `asc/asc/global.opt-inc.sh` (explicit `.`). |
| **Related** | [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md) Wave B; [20-readme-kernel-includes.md](./20-readme-kernel-includes.md) (applied: six → five, including this stub). |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

Wave B kept the file so the **five** kernel-include list would not change in the same slice. A comment-only `.` on every bootstrap is not a include. Callers already `. asc/asc/global.opt-inc.sh`. Warm `make` still sources `data/asc/global.vars.sh`.

Kernel block in `asc/bootstrap.sh` is now: `core_utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`. Tests: `test_f_global_aggregate_helpers_absent_from_kernel_bootstrap`, `test_asc_global_inc_not_in_kernel_includes`.
