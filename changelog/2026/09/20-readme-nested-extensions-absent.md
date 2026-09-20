# README proposal: nested_* extensions are not on disk

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **applied** (2026-09-20). Agent applied to root `README.md` (uncommitted) for human review. |
| **Target** | [`README.md`](../../../README.md) — **Genericity (scale)** → **Core** (opt-in extensions bullet list). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

## Why

README lists `nested_git` / `nested_host` / `nested_instance` as Core extensions, and those directories are not in this tree.

## Exact edit

**Drop this bullet:**

```markdown
    - `asc/extensions/nested_git`, `nested_host`, `nested_instance` : default implementations related to sub-git work trees (nested git clones), virtual machines (nested hosts), or even nested ASC project instances
```

## Not this edit

Do not create those three extension dirs. Do not rewrite the rest of the Core opt-in list. Do not invent `nested_instance` as host-scan.
