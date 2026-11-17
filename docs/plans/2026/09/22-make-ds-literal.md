# `make ds` literal print

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 (status updated 2026-11-17) |
| **Status** | **abandoned** |
| **Superseded by** | [22-make-ds.md](22-make-ds.md) + [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## Why abandoned

On 2026-11-17 the mother locked a different product shape:

- Entry is `asc/dsl.sh` + hardcoded `make ds` + `f_asc_dsl` (not `asc/core/dsl.sh` / synonym print pipeline).
- **`f_asc_dsl` is an interpreter from the start**, targeting the full README grammar (with proposed resolutions in the DSL spec).
- A print-only first slice is cancelled. Coverage waves under the parent plan may still start with literal calls, but they **run** them.

This file is kept as a historical record. It does not authorize work. The
`gates.core.yml` row that pointed here is not a second go-ahead.

---

## Historical scope (no longer active)

First slice of the old parent: print one literal DSL call. No execution. Path
assumptions (`asc/core/dsl.sh`, `gates.yml`, synonym `core-dsl/ds`, “no
`*.inc.sh`”) are obsolete.
