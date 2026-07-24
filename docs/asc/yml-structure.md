# ASC core concept : YAML structure

How ASC shapes **YAML bodies** (keys, nesting, enums) — distinct from **filename** grammar.

Table of contents :

1. [scope vs filename-DSL](#scope-vs-filename-dsl)
1. [file kinds](#file-kinds)
1. [state able (git draft)](#state-able-git-draft)
1. [subject inventory](#subject-inventory)
1. [open / living](#open--living)

Status: **living draft**. Decision SoT while in review: `changelog/2026/07/24-yml-structure.md`. Amend with the plan; do not invent runtime behavior here.

---

## scope vs filename-DSL

| Concern | Where |
|---------|--------|
| Filename stems: wrap `()`, nest `.`, args `[]`; path mapping `$action.able.yml` → `$subject.$action`; `slot` on `*.hook.yml` | `changelog/2026/07/24-filename-dsl.md`, `.cursor/rules/naming.mdc` |
| **Keys and nesting inside YAML files** | **This page** + `changelog/2026/07/24-yml-structure.md` |

Docs `$` notation (make entry points; `$subject` exception) still applies in prose — see [documentation.md](documentation.md) § `$` notation.

Related: [entities.md](entities.md) (what `*.able.yml` *means*), [organization.md](organization.md) (globals / cache / state *layers*).

---

## file kinds

| Kind | Typical path | Body role (draft) |
|------|--------------|-------------------|
| Action able | `$subject/$action.able.yml` | Capability / relation / **state** for that `$action` |
| Subject able | `$subject/$subject.able.yml` | Subject-wide inventory (e.g. entity list) |
| Hook YAML | `….hook.yml` | Smart defaults + `slot` (field names TBD) |
| Entity / includes | `*.entity.yml`, `includes:` | Inheritance — see [entities.md](entities.md) § yml includes |

Most historical `*.able.yml` under `asc/folder/` (and peers) are still empty stubs — prefer one worked example over mass-filling.

---

## state able (git draft)

First concrete sketch (commit `af31aca`, subject `git`):

**Path:** `asc/git/state.able.yml` → `$action` = `state` under `$subject` = `git` (doc: `$git.$state`).

```yaml
folder:
  default:
    state: new
  states:
    - gitignored
    - versionned
    - unclean

file:
  default:
    state: new
  states:
    - gitignored
    - versionned
    - modified
    - conflicted
```

| Key | Intent |
|-----|--------|
| Top-level | Entity id |
| `default.state` | Initial / unset state |
| `states` | Allowed state ids (enum) |

No transition graph or loader yet — enum + default only.

---

## subject inventory

Paired draft: `asc/git/git.able.yml`

```yaml
entities:
  - folder
  - file
```

Keeps “which entities this `$subject` names” separate from per-entity state enums. Whether `$subject/$subject.able.yml` is the locked home for `entities:` is still open (see plan changelog).

---

## open / living

Track decisions in `changelog/2026/07/24-yml-structure.md` § Open questions. High-priority while amending:

1. Must `default.state` appear in `states`?
2. Spelling: `versionned` vs `versioned`.
3. Share folder/file state enums core-wide vs keep git-local.
4. When to stub `*.hook.yml` body conventions (vs filename-DSL Phase 3).

Update this page when those lock; keep thin until then.
