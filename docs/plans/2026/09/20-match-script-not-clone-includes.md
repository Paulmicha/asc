# Sibling `. include` is not a caller

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | done (rule). No runtime change. |
| **Scope** | [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc) — “match an existing script” vs cloning unused sources. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

Human catch: `caller_opt_inc.test.sh` had `. asc/test/test.inc.sh` only because `primitives.test.sh` does. This file never calls `f_test_*`. `test.inc.sh` is already eager.

**Discipline:** a sibling’s `.` is not a caller in this file. Match the shape that still runs; drop unused sources. A “why is this `.` here?” with no caller upgrades **this rule** (and/or changelog). Skip if one-off.
