# Plan stub: `$subject/.asc_extensions` nested extensions

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (not implementation go-ahead) |
| **Tracked SoT** | [`changelog/2026/07/24-subject-asc-extensions.md`](../../../changelog/2026/07/24-subject-asc-extensions.md) |
| **Note** | `data/plans/review/*` is gitignored except `README.md`. Full plan + decision record lives in the changelog (same convention as `24-filename-dsl.md`). Keep this stub here for lifecycle lane only; update status / move folder when review → iterate → accepted / rejected. |

## Scope (see changelog)

- Any `$subject/.asc_extensions` → listed dirs become **nested ASC extensions**.
- Same specificity weight as nearest non-nested extension point.
- Untangle from `.asc_subjects_ignore` (blacklist subjects only).
- Seed already on disk: `asc/asc/.asc_extensions` → `utils`.

## Quick card (see changelog for full plan)

```text
$subject/.asc_extensions   → positive nest list (nested ASC extensions)
.asc_subjects_ignore       → negative subject list (not nests by itself)
.asc_extensions_ignore     → top-level asc/extensions/* on/off (unrelated)

specificity: nest hooks weigh like parent non-nested extension point
migrate: entity/field, hardware/software nested_*, folder/nested_dir, docker/nested_docker
```
