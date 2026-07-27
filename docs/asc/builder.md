# ASC core concept : Builder (synonym : codegen, code generator ?)

Table of contents :

1. documenting (~ minimal OKF ? dedicated core extension ?)
1. blueprints
1. atomic blueprint objects
1. slots
1. templates
1. self-building (chain.able, nest.able, rule.able codegen for humans and agents)

Builder is the opt-in extension for **templates / blueprints / prototypes** — scaffolding helpers for humans and (later) agents. It replaced the retired **`preset`** workflow.

Working motto from notes: **Builder · Extender** — generate scaffolds, then extend them under `scripts/asc/extend/` (not a second competing codegen path). Composition ability: **`combine.able`** (see [entities.md](entities.md)).

A **blueprint** can be any of: DSL fragment, string template, file template, or dir template (see § templates).

| Fact | Detail |
|------|--------|
| Path | `asc/extensions/builder/` |
| Default | Listed in core `.asc_extensions_ignore` (off until override omits it) |
| After enable | `make reinit` registers stub make targets; **bodies are still `# TODO`** |

**Do not use (retired):** `preset-discover` / `preset-list` / `preset-write` / `preset-improve`, `u_preset_*`, rematerializing live loop/crontab files from old preset packs.

**Prototype tip (rewrite notes):** builder can use temporary ASC overrides in tests to try ideas as prototypes before promoting them.

---

## documenting (~ minimal OKF ? dedicated core extension ?)

Open design slot: should “documenting” be a builder concern (generate minimal OKF-style docs beside scaffolds), a dedicated core extension, or only [documentation.md](documentation.md) living/ideas/changelogs?

Until specified:

- Living docs and changelogs remain the SoT for *explaining* ASC.
- Builder should emit **code scaffolds**, not replace the three documentation kinds.
- Any generated doc fragments must stay clearly marked as generated and must not invent runtime behavior.

---

## blueprints

Subject folders under the builder extension: **`blueprint`** / **`blueprints`**.

| Intent | Make (registered when enabled; bodies TODO) |
|--------|-----------------------------------------------|
| Generate / status / … | `blueprint-generate`, `blueprint-status`, … |
| List | `blueprints-list` |

Blueprints are meant to capture a **pattern** (structure + tokens) that can be applied to a target docroot. Nested application may use [nested-asc](wrappers.md#nested) (`nested-asc-exec`) so child instances do not inherit the parent bootstrap env.

**Preflight (open):** before/after apply — capture `git diff` / manual fixes as lessons-learned SoT so the next blueprint run improves. Not implemented; keep diffs in changelog or extend until a `blueprint-preflight` action exists.

Open: **`nested-blueprint?`** as a fourth nested kind (builder + `.asc_subjects_ignore` sub-modules).

---

## atomic blueprint objects

Instead of distinct entity kinds for every atomic code piece, prefer a single **`atomic.able` blueprint** entity (builder). Inspired by Brad Frost’s Atomic Design stages (atoms → molecules → organisms → templates → pages), but ASC collapses that into one nestable / useable blueprint object family:

| Object | Notes |
|--------|-------|
| vars | global, scoped, positional_arg, named_arg, local, readonly, exported — nestable (string templates / other vars / functions / maybe DSL) |
| functions (synonym **f**) | |
| files | |
| dirs | |
| asc instance | |

`data_dir.store.able` sidecar of each shell variable/function can mirror relative location from `$PROJECT_DOCROOT` as a nestable tree — same expressiveness as blueprint entities.

Potential DSL usage in entry points (proposed `a-*` arg tokens — see [shell-usage.md](shell-usage.md) § proposed DSL redesign):

- `dsl blueprint-var.field(type,a-1)` → `asc/extensions/builder/blueprint/var/is.sh`
- `dsl blueprint-var.sidecar(a)` → `…/blueprint/var/sidecar.sh`
- `dsl blueprint-f.sidecar(used-by,a-1)` → `…/blueprint/function/used_by.sh`

`dsl()` would resemble `hook()` but prepare calling-scope vars (`a`, `a_1`…, `o_*`, `bo_*`). Not implemented.

Guideline sketch: encourage **max ~1000 lines per file** so complex pieces split into smaller atomic blueprints.

---

## slots

**Undefined in sources.** Working meaning for the rewrite:

| Term | Proposed meaning |
|------|------------------|
| Slot | Named hole in a blueprint/template to be filled (path, token, or partial) |
| Fill | Hydration step that binds slot → value (env, YAML, CLI) |
| `slotable` | Entity/capability flag: this blueprint/template exposes slots |

Do not invent make targets named `slot-*` until the builder stubs define them. Prefer documenting slots here when `blueprint-*` / `template-*` bodies land.

---

## templates

Subject folders: **`template`** / **`templates`**.

A blueprint may hydrate via:

| Kind | Mechanism |
|------|-----------|
| **string** templates | `u_str_convert_tokens()` today — TODO rename to `tpl()` |
| **file** templates | `*.tpl.html` (hook) |
| **dir** templates | entire directory trees |

Pack tree (extension):

```text
asc/extensions/builder/templates/
  boilerplate/…
  asc/                 # action.tpl.sh, subject.inc.tpl.sh, action.test.sh, …
  services/            # app, cache, db, index, vcs, …
  list.sh
```

| Intent | Make (stubs) |
|--------|----------------|
| Hydrate / diff / … | `template-hydrate`, `template-diff`, … |
| List | `templates-list` |

Typical flow when implemented: `blueprints-list` → `blueprint-*` → `templates-list` → `template-*`. Token style historically used `{{ TOKEN }}` expansion in the retired preset path — confirm before relying on it in new bodies.

Also related: subject **`prototype`** / **`prototypes`** (same stub pattern as blueprint/template).

---

## self-building (chain.able, nest.able, rule.able codegen for humans and agents)

Self-building means ASC (and agents) can **emit** further ASC entry points from contracts — not an autonomous orchestrator.

| Building block | Role |
|----------------|------|
| `build.able` / builder subjects | Produce scaffolds from packs |
| `chain.able` | Generate ordered multi-step runners |
| `nest.able` | Generate nested-asc / nested-git / nested-extension wiring |
| `rule.able` | Generate conditional gates ([wrappers.md](wrappers.md) § rule) |

Scope guardrails (product non-goals):

- No self-organizing all-orchestrating platform in core.
- Complex NL / agent cognition stays in nested apps; builder only provides **exemplar blueprints**.
- Codegen must remain reviewable (diffable files under extend/contrib), not hidden binary state.

**Current reality:** ~19 stub actions register when builder is enabled; no real codegen yet. Nested virgin-env exec (`nested_asc`) is real and is the supported way to operate on child instances while scaffolding.

Rules extension sketch (core-in-progress, Drupal-contrib-module analogy): pattern presets as typeable entities — e.g. “make a hook for that, sidecar for this, prototype, test, recap as a new change entry” — all expressable in DSL. Infra actions must be configured as sudoers (or equivalent) first; a sync pattern could land in ASC core. See [wrappers.md](wrappers.md) § rule.

See [entities.md](entities.md) for the `*.able` catalog and [usage.md](usage.md) for how to enable extensions and extend a project.
