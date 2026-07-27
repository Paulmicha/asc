# ASC core concept : YAML structure

How ASC shapes **YAML bodies** (keys, nesting, enums) — distinct from **filename** grammar.

Table of contents :

1. [scope vs filename-DSL](#scope-vs-filename-dsl)
1. [file kinds](#file-kinds)
1. [props vs fields in bodies](#props-vs-fields-in-bodies)
1. [state able (git draft)](#state-able-git-draft)
1. [subject inventory](#subject-inventory)
1. [repo entity (git draft)](#repo-entity-git-draft)
1. [open / living](#open--living)

Status: **living draft**. Decision SoT while in review: `changelog/2026/07/24-yml-structure.md`. Amend with the plan; do not invent runtime behavior here. Field/prop vocabulary also tracked from root README § Current status — see [entities.md](entities.md) § field vs prop.

Example SoT: branch `naming-convention-changelog` @ `71b4f71` (`asc/git/{git.able,state.able,repo.entity}.yml`).

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
| Entity | `$subject/<name>.entity.yml` | Named entity — deps / fields (draft: `repo.entity.yml`) |
| Hook YAML | `….hook.yml` | Smart defaults + `slot` (field names TBD) |
| Includes | YAML `includes:` | Inheritance — see [entities.md](entities.md) § yml includes |

Most historical `*.able.yml` under `asc/folder/` (and peers) are still empty stubs — prefer one worked example over mass-filling.

---

## props vs fields in bodies

| Kind | Role in YAML |
|------|----------------|
| **prop** | Inherit.able constants shared by all entities of the kind (e.g. root `required:` / `optional:` on `*.entity.yml`) |
| **field** | Edit.able / store.able per-instance values (sidecars, globals, cache, scripts) |

The YAML file format defines something **represented and named** (= filename + path). Stabilize fields before relying on shared names across parent/child entities (e.g. `hostname` on remote host + remote instance).

### Arg / option validation (proposed DSL YAML)

When frozen DSL hooks use `.dsl.hook.yml`, bodies may declare validations (proposed `a` / `o` tokens — see [shell-usage.md](shell-usage.md) § proposed DSL redesign):

```yml
a:
  validation: test(a).is-slug
```

```yml
a1:
  validation: test(a-1).is-either(slug(a-1,-),slug(a-1,_))
```

Not implemented. Keep distinct from filename-DSL `slot` (slot stays in `*.hook.yml` bodies per locked plan).

---

## state able (git draft)

**Path:** `asc/git/state.able.yml` → `$action` = `state` under `$subject` = `git` (doc: `$git.$state`).

```yaml
folder:
  default:
    state: new
  states:
    - gitignored
    - versionned
    - modified
    - deleted
    - conflicted
    - unclean

file:
  default:
    state: new
  states:
    - gitignored
    - versionned
    - modified
    - deleted
    - conflicted
```

| Key | Intent |
|-----|--------|
| Top-level | Entity id |
| `default.state` | Initial / unset state |
| `states` | Allowed state ids (enum) |

Notes from current draft: folder and file share most ids; **`unclean` is folder-only**. No transition graph or loader yet — enum + default only.

---

## subject inventory

Paired draft: `asc/git/git.able.yml`

```yaml
entities:
  - folder
  - file
```

Keeps a flat “which entities this `$subject` names” list separate from per-entity state enums. How this relates to `*.entity.yml` `depends_on` is still open (see plan changelog).

---

## repo entity (git draft)

Sibling sketch: `asc/git/repo.entity.yml`

```yaml
repo:
  depends_on:
    entity:
      - file
      - folder
      - relation
  url:
    field: str.url
```

`url.field: str.url` points at a field stub (`asc/asc/utils/str/url.field.yml` today). Resolution / nesting rules for `*.field.yml` are not frozen yet.

---

## open / living

Track decisions in `changelog/2026/07/24-yml-structure.md` § Open questions. High-priority while amending:

1. `entities:` (subject able) vs `depends_on.entity` / `*.entity.yml`.
2. Must `default.state` appear in `states`?
3. Spelling: `versionned` vs `versioned`.
4. Keep `unclean` folder-only, or align folder/file enums?
5. Freeze `depends_on` + `*.field` refs as the entity-body pattern?

Update this page when those lock; keep thin until then.

Also absorb from rewrite notes when stabilizing YAML docs: required/optional prop shapes on all `*.entity.yml`; field stabilization using remote_host / remote_instance examples; optional (facultative) namespaced entry-point notation in YAML.
