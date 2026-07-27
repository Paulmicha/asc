# Plan: Structuring ASC YAML files

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (draft for iterative amendment; **not** implementation go-ahead) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — conventions for **inside** YAML (`*.able.yml`, `*.entity.yml`, `*.yml.yml`, `*.hook.yml`, specimen / includes); anchors = **git `$state`** draft + emerging **primordial** inheritance / contract / wrap sketches |
| **Related** | Filename DSL plan `changelog/2026/07/24-filename-dsl.md` (**separate**, complementary — owns filename stems / `$action.able.yml` *path* mapping, not YAML body schema); `docs/asc/entities.md` (`.able.yml` catalog); `docs/asc/organization.md` (globals / cache / state layers); entity blueprint under `asc/extensions/entity/`; draft commits below |
| **Lifecycle** | Local review stub: `data/plans/review/2026-07-24-yml-structure.md` (dir mostly gitignored — **this changelog is the tracked SoT**, same pattern as `24-filename-dsl.md`). Move stub across `review` → `iterate` → `accepted` / `rejected` per `data/ideas/2026/07/23/idea-changelog-workflow.md`. |
| **Living docs** | `docs/asc/yml-structure.md` (YAML body conventions; pointer in `docs/asc/README.md`) — still thin; re-sync when this plan’s second wave locks |

### Draft commit chain (SoT @ HEAD)

| Wave | Commits | What landed |
|------|---------|-------------|
| **A — git `$state`** | `af31aca` → `58b89a5` / `3f61912` → `71b4f71` | `git.able.yml`, `state.able.yml` enums, `repo.entity.yml` + `str.url` field stub |
| **B — primordial meta** | `d4533f6` → `559d2d7` / `9e7fcd8` → `ca23b12` → `bb827b5` / `8701a79` → `5871043` (HEAD tip `f392e55` has no further YAML body edits) | `able.able.yml` → `include: contract.entity`; `contract.able.yml` migrated then deleted → stub `contract.entity.yml`; synonyms → `asc.yml.yml`; ability whitelist → `entity.entity.yml`; `wrap.able.yml` + `git/acp/wrap.able.yml` |

**Amendment (2026-07-24, evening):** re-synced beyond `71b4f71` to HEAD `f392e55` — Wave B primordial inheritance / contract / wrap drafts. Git state bodies unchanged since `71b4f71`.

---

## Context

ASC already uses many YAML surfaces: specimen env / remotes, `*.able.yml` capability markers beside subjects/actions, planned `*.hook.yml` smart defaults, entity `includes`, and generated caches. Most `*.able.yml` under `asc/folder/` (and peers) are still **empty stubs**. Living docs describe *what* ables mean (`docs/asc/entities.md`) more than *how* to shape keys inside the files.

The **filename DSL** plan locks how YAML shows up in **paths** (e.g. `$action.able.yml` → `$subject.$action`; `slot` on `*.hook.yml`; `.hook.yml` vs `.hook.sh`). It deliberately leaves **YAML body schema** open (see that plan’s open Qs on `$action.able.yml` keys, `asc.extendable` / `asc.overridable`, YAML `slot` field shape).

**This plan is the complementary SoT for structuring YAML contents.** Two concrete draft waves are already on the branch:

1. **Git state** able pair under `$subject` `git`, plus sibling **`repo.entity.yml`** (Wave A — still the clearest *domain* example).
2. **Primordial meta** under `asc/asc/` + `asc/extensions/entity/entity/` — inheritance root, synonyms, contract stub, wrap able shapes (Wave B — schema-of-schemas sketch; still fluid).

**Plan-only for schema / loaders.** Do not invent a second YAML dialect, rewrite empty `*.able.yml` trees, or wire runtime state machines / YAML validators until this plan is accepted and implementation is explicitly requested. Amending the draft files below during review is OK when the user asks.

---

## Goals

1. Define a **small, amendable convention** for ASC YAML bodies — starting with `$action.able.yml` **state** declarations, then primordial `include` / contract / wrap.
2. Keep YAML structure **aligned** with filename-DSL path mapping (`$action.able.yml` → `$subject.$action`) without merging the two plans.
3. Use the **git state** draft as the first worked *domain* example (entities → per-entity default state + enum of states).
4. Capture Wave B as the first worked *meta* example (`asc.yml` → entity → contract → able; wrap required/add; synonym table) without freezing it prematurely.
5. Leave room for other YAML kinds (`*.hook.yml`, specimen, entity `includes`) as later sections — do not boil the ocean in v1.
6. Document the approach as **living docs** (`docs/asc/yml-structure.md`) and keep this changelog as dated SoT for decisions.

Non-goals (for now): shipping a YAML schema validator; renaming every empty `*.able.yml`; implementing git state transitions in shell; freezing `*.hook.yml` / extendable keys (owned jointly with filename-DSL Phase 3 — decide here only when needed).

---

## Anchor draft A — git `$state` YAML (+ `repo` entity)

**Branch:** `naming-convention-changelog`. **Bodies unchanged since:** `71b4f71`. **Repo HEAD:** `f392e55`.

| Path | Role (draft reading) |
|------|----------------------|
| `asc/git/git.able.yml` | Subject-adjacent able: declares **which entities** the `git` subject cares about (`folder`, `file`). |
| `asc/git/state.able.yml` | `$action.able.yml` for `$action` = `state`: per-entity **default** + **allowed states**. |
| `asc/git/repo.entity.yml` | Named **entity** body for `repo`: `depends_on.entity` list + `url.field` pointer (`str.url`). |

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

```yaml
# asc/git/repo.entity.yml
repo:
  depends_on:
    entity:
      - file
      - folder
      - relation
  url:
    field: str.url
```

Related field stub (outside `git/`, referenced by `url.field`): `asc/asc/utils/str/url.field.yml` → `url: { validate: limit[2048](str.length) }`.

### What problem this sketch solves

- Names **state** as an explicit `$action` under `$subject` `git` (filesystem-visible; matches “files = actions”).
- Separates **entity inventory** (`git.able.yml`) from **state machine / enum** (`state.able.yml`).
- Gives humans and agents a readable enum of git-ish folder/file conditions without hard-coding them only in shell.
- Starts a concrete **`*.entity.yml`** shape (`depends_on` + field ref) beside the able pair — inventory (`entities:`) and entity definition are no longer the same file.

### Draft gaps (expected — plan will fill)

- No runtime loader / transition graph yet.
- Spelling `versionned` vs `versioned` undecided.
- Unclear whether `new` is only a default or also a member of `states`.
- Folder vs file enums still diverge (`unclean` on folder only).
- How `git.able.yml` `entities:` relates to `repo.entity.yml` `depends_on.entity` (and to `relation`) is open.
- No link yet to `is.*.yml` “state markers” noted in `docs/asc/entities.md`.
- No `include` story yet tying Wave A files into Wave B’s inheritance chain.
- `url.field: str.url` → `*.field.yml` resolution path / nesting convention still open.

---

## Anchor draft B — primordial meta / inheritance / wrap

**Branch:** `naming-convention-changelog`. **Example SoT at:** HEAD `f392e55` (Wave B landed `d4533f6`…`5871043`).

Wave B iterated hard in one afternoon: started as rich `contract.able.yml` + `yml.able.yml` + fat `able.able.yml`, then **split roles** — synonyms / ability whitelist / contract rules / able inheritance are now separate files. Intermediate shapes (esp. `freeform` / `operation` / `sk` synonyms) are **historical**; cite HEAD bodies below unless reviewing the migration.

| Path | Role (draft reading @ HEAD) |
|------|------------------------------|
| `asc/asc/asc.yml.yml` | Meta YAML registry: **`synonym:`** table (`op`, `skill`, `val`, `prop`, `sh`, `fs`, `str`, `int`, `arr`). Comment: any ASC-core YAML inherits this. |
| `asc/extensions/entity/entity/entity.entity.yml` | **Primordial entity** root: `include: asc.yml`; under `entity:` — ability whitelist (`is`/`access`/`include`/`field`/…/`contract: '*'`) + `required` / `optional` field/prop defaults. |
| `asc/asc/contract.entity.yml` | Contract entity stub: `rules: { todo: TODO }` (body emptied after migrate-out). |
| `asc/asc/able.able.yml` | Primordial **able** definition: `include: [contract.entity]` — common inheritance for all `*.able.yml`. |
| `asc/asc/wrap.able.yml` | Core wrap able: `wrap.required.prop.wrapper.validate: test-file-exists(a-1)`. |
| `asc/git/acp/wrap.able.yml` | Subject/nested wrap able: `wrap.add` with `synonym: a` + `default.value: .`. |

### Current draft bodies (HEAD)

```yaml
# asc/asc/asc.yml.yml
synonym:
  op:
    - operation
  skill:
    - ability
    - capability
  val:
    - value
  prop:
    - key
    - property
  sh:
    - shell
  fs:
    - file_system
    - filesystem
  str:
    - string
  int:
    - integer
  arr:
    - array
```

```yaml
# asc/extensions/entity/entity/entity.entity.yml
include: asc.yml
entity:
  is: '*'
  access: '*'
  include: '*'
  field: '*'
  triple: '*'
  link: '*'
  synonym: '*'
  override: '*'
  hook: '*'
  wrap: '*'
  nest: '*'
  sidecar: '*'
  entity: '*'
  taxonomy: '*'
  cognition: '*'
  contract: '*'
  required:
    field:
      type:
        validate: test-entity[type](a-1)
  optional:
    prop:
      - include
    field:
      name:
        default:
          val: ''
      bundle:
        default: '$entity.type'
```

```yaml
# asc/asc/contract.entity.yml
rules:
  todo: TODO
```

```yaml
# asc/asc/able.able.yml
include:
  - contract.entity
```

```yaml
# asc/asc/wrap.able.yml
wrap:
  required:
    prop:
      wrapper:
        validate: test-file-exists(a-1)
```

```yaml
# asc/git/acp/wrap.able.yml
wrap:
  add:
    synonym: a
    default:
      value: .
```

### Migration notes (Wave B — do not treat as locked)

| Step | Commit(s) | Shift |
|------|-----------|--------|
| Start | `d4533f6` | `able.able.yml` (freeform/required), `contract.able.yml`, `yml.able.yml`, `git/acp/wrap.able.yml` |
| Contract thicken | `559d2d7` → `9e7fcd8` | Synonyms + `operation: '*'` whitelist lived **inside** `contract.able.yml` |
| Split | `ca23b12` | Contract body → `contract.entity.yml`; able slimmed toward `include` |
| Re-home | `bb827b5` → `8701a79` | Synonyms → `asc.yml.yml`; whitelist → `entity.entity.yml`; delete `contract.able.yml` + `yml.able.yml`; add core `wrap.able.yml` |
| Tweak | `5871043` | Entity `required`/`optional` defaults (`test-entity[type]`, `default.val`, `$entity.type`) |

### What problem this sketch solves

- Names an **inheritance spine**: meta synonyms → primordial entity → contract → able (every able can share one include).
- Separates **vocabulary** (`synonym`), **capability surface** (`entity:` whitelist), **contract rules** (stub), and **able inheritance** (`able.able.yml`).
- Starts concrete **wrap** body keys: `required` / `add`, `prop`, `validate`, `default`, local `synonym`.
- Introduces **`*.yml.yml`** as a file kind (meta YAML beside able/entity), not only `*.able.yml` / `*.entity.yml`.

### Draft gaps (expected — plan will fill)

- `include:` shape inconsistent: scalar (`include: asc.yml`) vs list (`include: [contract.entity]`) vs older `includes:`.
- Include **target resolution** open (`asc.yml` ↔ `asc.yml.yml`? `contract.entity` ↔ `contract.entity.yml`?).
- `contract.entity.yml` is a TODO stub — where do real `rules` live after the migrate-out?
- Ability whitelist key naming: early drafts used `freeform` / `operation` / `rule`; HEAD uses flat `entity:` children + `contract: '*'`.
- Synonym key spelling: HEAD `skill` vs earlier `sk`; `capacity` deliberately commented out.
- `validate:` / `test-…` DSL is exploratory (several spellings in history: `one.of[…]`, `test.has(…)`, `test-not-empty`, `test-entity[type](a-1)`, `test-file-exists(a-1)`).
- `default.val` vs `default.value` inconsistency (entity optional vs wrap add).
- How Wave A files (`git.able.yml`, `state.able.yml`, `repo.entity.yml`) should `include` into this chain is unset.
- No loader / merge / override runtime wired to these files yet (empty `asc/yml/{parse,merge,extend}.sh` stubs exist nearby — out of scope until accepted).

---

## Proposed structure / conventions (starting draft)

Amend freely in conversation. Locked only when explicitly marked later.

### 1. File kinds (path vs body)

| Kind | Path pattern (filename-DSL / org) | Body owned by **this** plan |
|------|-----------------------------------|-----------------------------|
| Action able | `$subject/$action.able.yml` | Capability / relation / **state** / **wrap** payloads for that `$action` |
| Subject able | `$subject/$subject.able.yml` (draft: `git.able.yml`) | Subject-wide inventory / defaults (e.g. `entities:`) |
| Primordial able | `asc/asc/able.able.yml` | Shared inheritance for all ables (`include: contract.entity`) |
| Hook YAML | `$subject/….hook.yml` | Smart defaults + `slot` (field names TBD; path rules stay in filename-DSL) |
| Entity | `*.entity.yml` (drafts: `repo.entity.yml`, `contract.entity.yml`, `entity.entity.yml`) | Named entity body — deps / fields / whitelist / required·optional |
| Meta YAML | `*.yml.yml` (draft: `asc.yml.yml`) | Cross-cutting vocabulary (e.g. `synonym:`) for ASC YAML |
| Includes | YAML `include:` / `includes:` | Inheritance — shape TBD; see Wave B gaps |

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

Keeps “what entities exist for this `$subject`” out of the per-action state file. Draft also shows a richer **entity** body (`repo.entity.yml`) with `depends_on.entity` + field refs — see open Q1 / Q8.

### 4. Inheritance / contract / wrap (proposed — from Wave B; still soft)

Emerging spine (reading only — **not locked**):

```text
asc.yml.yml          → synonym vocabulary
entity.entity.yml    → include asc.yml; entity ability surface + required/optional
contract.entity.yml  → rules (stub)
able.able.yml        → include contract.entity  (all *.able inherit)
*.able.yml           → domain / wrap / state bodies
```

| Key family | Intent (draft) |
|------------|----------------|
| `include:` | Inheritance edge(s) to other YAML stems |
| `synonym:` | Alias table for DSL vocabulary |
| `entity:` children = `'*'` | Ability whitelist / blacklist surface for the primordial entity |
| `required` / `optional` | Mandatory vs optional `field` / `prop` with `validate` / `default` |
| `wrap.required` / `wrap.add` | Wrap able constraints and additive defaults |
| `validate:` | Declarative check expression (DSL TBD) |
| `rules:` | Contract rule payload (currently TODO) |

### 5. Relationship to filename-DSL (do not conflate)

| Concern | Owner |
|---------|--------|
| Stem punctuation `()` / `.` / `[]`; `$action.able.yml` **path** mapping; `slot` ∈ `*.hook.yml` not filename | `24-filename-dsl.md` |
| Keys, nesting, enums, defaults, includes **inside** YAML | **This plan** |
| Field/triple able **forms in docs** | filename-DSL + `.cursor/rules/doc-notation.mdc` — YAML keys that store those relations TBD here when needed |

---

## Open questions

### Wave A (git state) — still first

1. **Subject able vs entity YAML:** is `$subject/$subject.able.yml` (`git.able.yml`) still the locked home for `entities:`, or does `*.entity.yml` (`repo.entity.yml`) take over inventory / deps? How do `entities:` and `depends_on.entity` relate?
2. **`new` vs `states`:** must `default.state` always be listed under `states`, or is default allowed outside the enum?
3. **Spelling:** `versionned` (draft) vs `versioned` (EN)? Any other enum renames (`unclean` vs `dirty`)?
4. **Folder vs file enum asymmetry:** keep `unclean` folder-only (current draft), align both lists, or treat `unclean` as a rollup of other states?
5. **Transitions:** enum-only for v1, or declare edges (`from` / `to`) in the same YAML later?
6. **`is.*.yml` markers:** same SoT as `state.able.yml`, generated views, or orthogonal?
7. **Reuse beyond git:** should `folder` / `file` state enums be core-shared (`asc/folder/state.able.yml`) and merely referenced by git, or stay git-local?
8. **`depends_on` / field refs:** freeze `depends_on.entity` + `url.field: str.url` as the entity-body pattern? How does `str.url` resolve to `…/str/url.field.yml`?

### Wave B (primordial) — new since `d4533f6`

9. **`include` shape:** scalar vs list? Key name `include` vs `includes`? How do targets resolve (`asc.yml` → `asc.yml.yml`, `contract.entity` → `contract.entity.yml`)?
10. **Inheritance spine:** freeze `asc.yml` → `entity.entity` → `contract.entity` → `able.able` as the locked chain, or keep experimenting?
11. **Where do contract `rules` live** now that `contract.entity.yml` is a TODO stub? Back into entity? Separate `*.contract.yml` kind?
12. **Ability whitelist home:** keep under primordial `entity:` (HEAD), or return nearer to contract / able meta?
13. **`validate:` DSL:** pick one spelling family before more drafts (`test-entity[type](a-1)` vs older `one.of[…]` / `at_least[…]` forms).
14. **`default.val` vs `default.value`:** unify under synonym table (`val` ↔ `value`), or pick one?
15. **`*.yml.yml` file kind:** keep as meta registry only, or allow other double-suffix kinds?
16. **Wrap body:** is `wrap.required` / `wrap.add` the locked wrap-able shape? How does nested `git/acp/wrap.able.yml` merge with core `asc/wrap.able.yml`?

### Cross-cutting

17. **YAML `include` for Wave A:** should `git.able.yml` / `state.able.yml` / `repo.entity.yml` opt into Wave B includes in v1, or stay self-contained until meta freezes?
18. **`*.hook.yml` body:** land a minimal stub section in this plan soon, or wait for filename-DSL Phase 3?
19. **Validation:** docs-only convention first, or early shunit2 fixture checks under `make test-core`?
20. **Schema versioning:** add a top-level `asc.yml.schema` / `version:` key, or avoid until multiple consumers exist?

---

## Next iterative steps

- [ ] Review / amend this plan in conversation (status stays `plan / review`).
- [ ] Decide Wave A open Qs 1–4 first (inventory vs `*.entity.yml`, `new`∈`states`, spelling, folder/file enum asymmetry) — enough to refine the git draft.
- [ ] Decide Wave B open Qs 9–11 next (`include` shape, inheritance spine, contract `rules` home) — enough to stop the meta churn.
- [ ] Expand living doc `docs/asc/yml-structure.md` when decisions lock (add Wave B section; keep thin until then).
- [ ] Optionally amend draft YAML files to match agreed shapes (only when asked).
- [ ] Cross-link filename-DSL open Qs that this plan answers (`$action.able.yml` schema, YAML `slot` shape) once frozen.
- [ ] Do **not** implement loaders / transition / validate runtime until accept + explicit go-ahead.

---

## Risks / safety notes

| Risk | Notes |
|------|--------|
| Merging with filename-DSL | Keep path grammar and YAML body as two SoTs; link, don’t duplicate. |
| Empty able sprawl | Do not mass-fill `asc/folder/*.able.yml` from this plan’s git example alone. |
| Premature schema | Prefer worked examples (git state + primordial meta) before a universal YAML meta-model. |
| Meta churn | Wave B moved keys across files several times in hours — treat HEAD as provisional until Qs 9–11 lock. |
| Docs drift | Living page still documents Wave A only @ `71b4f71`; changelog is decision SoT while status is review. |

**Safety:** do not hand-edit gitignored generated caches as SoT. Do not implement until accepted + requested.
