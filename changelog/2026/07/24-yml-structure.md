# Plan: Structuring ASC YAML files

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (draft for iterative amendment; **not** implementation go-ahead) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — conventions for **inside** YAML (`*.able.yml`, `*.hook.yml`, entity / specimen / includes); anchor use case = **git `$state`** draft |
| **Related** | Filename DSL plan `changelog/2026/07/24-filename-dsl.md` (**separate**, complementary — owns filename stems / `$action.able.yml` *path* mapping, not YAML body schema); `docs/asc/entities.md` (`.able.yml` catalog); `docs/asc/organization.md` (globals / cache / state layers); entity blueprint stubs under `asc/extensions/entity/`; draft commit `af31aca` (*wip: draft state yml system.*) |
| **Lifecycle** | Local review stub: `data/plans/review/2026-07-24-yml-structure.md` (dir mostly gitignored — **this changelog is the tracked SoT**, same pattern as `24-filename-dsl.md`). Move stub across `review` → `iterate` → `accepted` / `rejected` per `data/ideas/2026/07/23/idea-changelog-workflow.md`. |
| **Living docs** | `docs/asc/yml-structure.md` (new — YAML body conventions; pointer added in `docs/asc/README.md`) |

---

## Context

ASC already uses many YAML surfaces: specimen env / remotes, `*.able.yml` capability markers beside subjects/actions, planned `*.hook.yml` smart defaults, entity `includes`, and generated caches. Most `*.able.yml` under `asc/folder/` (and peers) are still **empty stubs**. Living docs describe *what* ables mean (`docs/asc/entities.md`) more than *how* to shape keys inside the files.

The **filename DSL** plan locks how YAML shows up in **paths** (e.g. `$action.able.yml` → `$subject.$action`; `slot` on `*.hook.yml`; `.hook.yml` vs `.hook.sh`). It deliberately leaves **YAML body schema** open (see that plan’s open Qs on `$action.able.yml` keys, `asc.extendable` / `asc.overridable`, YAML `slot` field shape).

**This plan is the complementary SoT for structuring YAML contents.** It starts from a concrete draft already pushed: the **git state** able pair under `$subject` `git`.

**Plan-only for schema / loaders.** Do not invent a second YAML dialect, rewrite empty `*.able.yml` trees, or wire runtime state machines until this plan is accepted and implementation is explicitly requested. Amending the draft files below during review is OK when the user asks.

---

## Goals

1. Define a **small, amendable convention** for ASC YAML bodies — starting with `$action.able.yml` **state** declarations.
2. Keep YAML structure **aligned** with filename-DSL path mapping (`$action.able.yml` → `$subject.$action`) without merging the two plans.
3. Use the **git state** draft as the first worked example (entities → per-entity default state + enum of states).
4. Leave room for other YAML kinds (`*.hook.yml`, specimen, entity `includes`, `*.entity.yml`) as later sections — do not boil the ocean in v1.
5. Document the approach as **living docs** (`docs/asc/yml-structure.md`) and keep this changelog as dated SoT for decisions.

Non-goals (for now): shipping a YAML schema validator; renaming every empty `*.able.yml`; implementing git state transitions in shell; freezing `*.hook.yml` / extendable keys (owned jointly with filename-DSL Phase 3 — decide here only when needed).

---

## Anchor draft — git `$state` YAML

**Commit:** `af31aca` — *wip: draft state yml system.* (branch `naming-convention-changelog`)

| Path | Role (draft reading) |
|------|----------------------|
| `asc/git/git.able.yml` | Subject-adjacent able: declares **which entities** the `git` subject cares about (`folder`, `file`). |
| `asc/git/state.able.yml` | `$action.able.yml` for `$action` = `state`: per-entity **default** + **allowed states**. |

### Current draft bodies

```yaml
# asc/git/git.able.yml
entities:
  - folder
  - file
```

```yaml
# asc/git/state.able.yml
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

### What problem this sketch solves

- Names **state** as an explicit `$action` under `$subject` `git` (filesystem-visible; matches “files = actions”).
- Separates **entity inventory** (`git.able.yml`) from **state machine / enum** (`state.able.yml`).
- Gives humans and agents a readable enum of git-ish folder/file conditions without hard-coding them only in shell.

### Draft gaps (expected — plan will fill)

- No runtime loader / transition graph yet.
- Spelling `versionned` vs `versioned` undecided.
- Unclear whether `new` is only a default or also a member of `states`.
- No link yet to `is.*.yml` “state markers” noted in `docs/asc/entities.md`.
- No `includes` / extend / override story for these files.

---

## Proposed structure / conventions (starting draft)

Amend freely in conversation. Locked only when explicitly marked later.

### 1. File kinds (path vs body)

| Kind | Path pattern (filename-DSL / org) | Body owned by **this** plan |
|------|-----------------------------------|-----------------------------|
| Action able | `$subject/$action.able.yml` | Capability / relation / **state** payloads for that `$action` |
| Subject able | `$subject/$subject.able.yml` (draft: `git.able.yml`) | Subject-wide inventory / defaults (e.g. `entities:`) |
| Hook YAML | `$subject/….hook.yml` | Smart defaults + `slot` (field names TBD; path rules stay in filename-DSL) |
| Entity / includes | `*.entity.yml`, YAML `includes:` | Inheritance — see `docs/asc/entities.md` § yml includes; detail later |

### 2. State able shape (proposed — from git draft)

For `$action` = `state` (and possibly other state-like ables):

```text
<$entity>:
  default:
    state: <state_id>
  states:
    - <state_id>
    - …
```

| Key | Intent |
|-----|--------|
| Top-level key | Entity id (`folder`, `file`, …) — should match subject inventory when one exists |
| `default.state` | Initial / unset state id |
| `states` | Allowed state ids (enum; unordered list for now) |

**Doc notation:** `$subject.$action` for the operable pair (e.g. `$git.$state`); path still `$subject/$action.able.yml` without `$` on disk.

### 3. Subject inventory shape (proposed)

```text
entities:
  - <entity_id>
  - …
```

Keeps “what entities exist for this `$subject`” out of the per-action state file.

### 4. Relationship to filename-DSL (do not conflate)

| Concern | Owner |
|---------|--------|
| Stem punctuation `()` / `.` / `[]`; `$action.able.yml` **path** mapping; `slot` ∈ `*.hook.yml` not filename | `24-filename-dsl.md` |
| Keys, nesting, enums, defaults, includes **inside** YAML | **This plan** |
| Field/triple able **forms in docs** | filename-DSL + `.cursor/rules/doc-notation.mdc` — YAML keys that store those relations TBD here when needed |

---

## Open questions

1. **Subject able vs action able:** is `$subject/$subject.able.yml` (`git.able.yml`) the locked home for `entities:`, or should inventory live elsewhere (`$subject.entity.yml`, globals, …)?
2. **`new` vs `states`:** must `default.state` always be listed under `states`, or is default allowed outside the enum?
3. **Spelling:** `versionned` (draft) vs `versioned` (EN)? Any other enum renames (`unclean` vs `dirty`)?
4. **Transitions:** enum-only for v1, or declare edges (`from` / `to`) in the same YAML later?
5. **`is.*.yml` markers:** same SoT as `state.able.yml`, generated views, or orthogonal?
6. **Reuse beyond git:** should `folder` / `file` state enums be core-shared (`asc/folder/state.able.yml`) and merely referenced by git, or stay git-local?
7. **YAML `includes`:** adopt remote-instance-style includes for ables in v1, or keep files self-contained until entity work lands?
8. **`*.hook.yml` body:** land a minimal stub section in this plan soon, or wait for filename-DSL Phase 3?
9. **Validation:** docs-only convention first, or early shunit2 fixture checks under `make test-asc`?
10. **Typo / schema versioning:** add a top-level `asc.yml.schema` / `version:` key, or avoid until multiple consumers exist?

---

## Next iterative steps

- [ ] Review / amend this plan in conversation (status stays `plan / review`).
- [ ] Decide open Qs 1–3 first (inventory home, `new`∈`states`, spelling) — enough to refine the git draft.
- [ ] Expand living doc `docs/asc/yml-structure.md` when decisions lock (keep thin until then).
- [ ] Optionally amend `asc/git/*.able.yml` to match agreed shape (only when asked).
- [ ] Cross-link filename-DSL open Qs that this plan answers (`$action.able.yml` schema, YAML `slot` shape) once frozen.
- [ ] Do **not** implement loaders / transition runtime until accept + explicit go-ahead.

---

## Risks / safety notes

| Risk | Notes |
|------|--------|
| Merging with filename-DSL | Keep path grammar and YAML body as two SoTs; link, don’t duplicate. |
| Empty able sprawl | Do not mass-fill `asc/folder/*.able.yml` from this plan’s git example alone. |
| Premature schema | Prefer one worked example (git state) before a universal YAML meta-model. |
| Docs drift | Living page starts thin; changelog remains decision SoT while status is review. |

**Safety:** do not hand-edit gitignored generated caches as SoT. Do not implement until accepted + requested.
