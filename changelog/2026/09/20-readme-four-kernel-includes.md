# README proposal: four kernel includes; `global()` is opt-inc

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **applied** (2026-09-20). Agent applied to root `README.md` (uncommitted) for human review. |
| **Target** | [`README.md`](../../../README.md) — **ASC cache : `data/asc/cache`** (kernel-include sentence) and **Environment variables (*env vars*)** (item 1). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## Why

Empty kernel `global.inc.sh` is gone. `global()` lives in `asc/asc/global.opt-inc.sh`. README still lists five kernel includes and points env-vars at the deleted file.

## Exact edit

**Replace** the kernel-include sentence with:

```markdown
Bootstrap always sources the four kernel includes (`core_utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`). `yml.inc.sh` is eager via `ASC_INC` (`asc/yml` is an *active dir*).
```

**Replace** env-vars item 1 (`see asc/asc/global.inc.sh`) with:

```markdown
1. **readonly globals** declared using the `global` bash function that ASC provides, see `asc/asc/global.opt-inc.sh` (generated readonly *constants*) ;
```

## Not this edit

Do not list `ASC_INC`. Do not restore `global.inc.sh`. Do not rewrite the rest of Environment variables.
