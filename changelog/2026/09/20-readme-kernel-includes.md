# README proposal: kernel includes are five files; yaml is ASC_INC

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **applied** (2026-09-20). Five kernel includes + `yml.inc.sh` on `ASC_INC` in root [`README.md`](../../../README.md) **ASC cache**. |
| **Target** | [`README.md`](../../../README.md) — **ASC cache : `data/asc/cache`** (paragraph after the tree). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## Why

Yaml dual-source is gone: `yml.inc.sh` is only an `ASC_INC` active-dir include. README still says bootstrap always sources **six** kernel includes.

## Exact edit

**Replace:**

```text
Bootstrap always sources the six kernel includes.
```

**with:**

```text
Bootstrap always sources the five kernel includes (`core_utils.inc.sh`, `core.inc.sh`, `global.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`). `yml.inc.sh` is eager via `ASC_INC` (`asc/yml` is an *active dir*).
```

## Not this edit

Do not list all `ASC_INC` paths. Do not add a Recap row for `yml.inc.sh` (same idea as `git.inc.sh`). Do not start the str-tail wave.
