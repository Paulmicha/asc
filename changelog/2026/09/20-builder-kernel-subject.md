# Builder as one kernel subject

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | proposed, **later**. No code. Not in the 2026-09-19 lazy-include order. Not in the [meadows review loop](./20-meadows-plan-review-feedback-loop.md). Prefer after fs/db so a tree move does not fight stamp / `pivots.mk` churn. |
| **Scope** | Promote `asc/extensions/builder` to **one kernel subject** `asc/builder/`. Placement lock + `template.able` / `literal.able` contract **sketches** (YAML bodies in this file). |
| **Not this plan** | Flatten `prototype` / `template` / `code` as sibling subjects under `asc/`. Kernel **include** (the six always-sourced bootstrap files). `builder.inc.sh` on `ASC_INC`. Implementing `TODO` in hydrate/build. Entity “builder code entity”. YAML loader / merge for this sketch. [24-subject-asc-extensions.md](../07/24-subject-asc-extensions.md) nest declaration. README matrix. Third loader. New `.mdc`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$object` / `$action` / `$extension`), not a shell variable.

---

## Kernel subject ≠ kernel include

**Kernel include** = the six files every bootstrap sources (`asc/utils/core_utils.inc.sh`, `asc/asc/core.inc.sh`, `global.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`, `yml.inc.sh`). Builder must **not** join that list.

**Kernel subject** = a folder under `asc/` that discovery always treats as a `$subject` (like `host`, `instance`). Promotion is filesystem + primitives / `pivots.mk`. Functions stay in the entry point or a colocated `*.opt-inc.sh` until a real always-needed caller exists.

This mother instance already **enables** the extension: root [`.asc_extensions_ignore`](../../../.asc_extensions_ignore) does not list `builder`. After the move, disable is **not** `.asc_extensions_ignore` (that file does not see kernel subjects). That is the point of the promotion.

README already puts generating ASC code in **scope** and lists builder under Core. This file locks **where** that generator lives. It does not start the generator.

---

## Pick

**One subject:** `asc/extensions/builder/` → `asc/builder/`.

Today the extension’s **subjects** (`prototype`, `template`, `code`, `test`) become:

| Today | After | Why |
|-------|--------|-----|
| `…/builder/prototype/$action.sh` | `asc/builder/prototype/$action.sh` | `$object` = `prototype`. Pivot `builder-prototype-build` (heuristic A). |
| `…/builder/template/$action.sh` | `asc/builder/template/$action.sh` | `$object` = `template`. Pivot `builder-template-hydrate`. |
| `…/builder/template/core/` | `asc/builder/template/core/` | Scaffold payload. Deeper than `$subject/$object/$action` → not discovered. |
| `…/builder/code/` | `asc/builder/code/` | **Data**, not objects. Do not ship `code-var-is` / `code-function-is`. `.asc_objects_ignore` only if an immediate valid `*.sh` appears. |
| `…/builder/test/core.hook.sh` + `test/core/template.test.sh` | `asc/test/core/builder_template.test.sh` | Object dirs cannot hold hooks. [`asc/test/core.hook.sh`](../../../asc/test/core.hook.sh) already batches `asc/test/core`. Delete the extra `hook -s test -a core` implementation. |

**Rejected:** `asc/prototype`, `asc/template`, `asc/code` as peer kernel subjects. `test/` already exists at [`asc/test/`](../../../asc/test). `template` / `code` as peers of `host` do not say *ASC self-build*. Client stacks would inherit un-namespaced pivots they cannot turn off with `.asc_extensions_ignore`.

**Rejected:** stay at `asc/extensions/builder` and call it always-on. Smallest, but README still teaches extensions as opt-in except `file_registry`; the next agent will treat builder as disable-able. The tree move is the durable token.

**Rejected:** wait for `$subject/.asc_extensions` ([24-subject-asc-extensions.md](../07/24-subject-asc-extensions.md) — open README conflict). This is a plain subject, not a nested extension.

**Synonyms:** `prototype-build` → `builder-prototype-build` only if grep finds a real caller. Stubs likely have none. Skip otherwise.

**Eager include:** no `asc/builder/builder.inc.sh` until a real always-needed function exists.

---

## Split: `literal.able` then `template.able`

**`literal.able`** substitutes tokens in a string. **`template.able`** is only a filesystem wrapper around that: existing fs readers walk/read `source`, each path and each file body go through `literal.able`, writes land under `dest`. One substitution engine. Do not reimplement `{{ slot }}` in template tools. Do not invent a new file reader (kernel `fs` / explicit `.` of `fs.opt-inc.sh` if that cluster moved — not the archive helpers).

README “folder or string templates”: string → `literal.able` directly; folder → `template.able` which `include`s `literal.able`.

---

## `literal.able` (contract sketch)

Token engine. `source` is inline text, not a path. This file does **not** start the entity system or `tpl()`.

**Path:** `asc/builder/literal.able.yml` (subject-level: README discovers `$ext/$subject/*.able.yml`, not under `$object`). There is **no** `literal/` object in this tree today. Do **not** invent one in the `git mv` PR. Tools name the intended pivots; entry points wait for a real caller.

**Tokens observed in this tree** (SoT — do not invent a third syntax):

- Filename-shaped (may appear *inside* a string; they are not path segments until `template.able` walks a tree): `[subject]`, `[object]`, `[action]`, `[hook]`, `[test_group]`, `[test_suite]`, `[test_case]`, `{subject}`, `{file_ext}`, `{variants}`
- Body: `{{ slot }}`, `{{ docblock }}`, `{{ examples }}`, `{{ COMPONENT }}`, `{{ TEMPLATE }}`

Kinds (living-docs label): a blueprint is **DSL or tpl**. Scaffolds on disk today are tpl. `<asc-if>` stays open (not in this body).

```yaml
# Sketch only. After the move: asc/builder/literal.able.yml
include:
  - able.able

synonym:
  literal:
    - inline
    - string

literal:
  required:
    prop:
      source:
        is: str
  optional:
    prop:
      dest:
        is: str
      kind:
        allowed:
          - dsl
          - tpl
        default: tpl
  tools:
    list: builder-literal-list(a)
    diff: builder-literal-diff(a)
    represent: builder-literal-represent(a)
    hydrate: builder-literal-hydrate(a)
```

No `validate: test-file-exists`. `dest` omitted → yield the substituted string (stdout / caller). `dest` set → write that path (may not exist yet). `list` enumerates tokens in `source`; `diff` compares two literals.

**Not this sketch:** a `literal/` `$object`, implementing `builder-literal-*`, YAML loader, `tpl()`.

---

## `template.able` (contract sketch)

Filesystem wrapper. `include: literal.able` (inherits tokens, kinds, substitution). This contract adds a path `source` that must exist, a dest tree, and tools that read then call literal tools. Types that include `template.able` get both.

**Path:** `asc/builder/template.able.yml`. Not `asc/builder/template/template.able.yml` (object dir — invisible).

Same shelf as the git / wrap drafts in [24-yml-structure.md](../07/24-yml-structure.md): **sketch only**. No loader. Stub file on the `git mv` PR; still no hydrate/build implementation.

```yaml
# Sketch only. After the move: asc/builder/template.able.yml
include:
  - literal.able

synonym:
  tpl:
    - template
    - blueprint

template:
  required:
    prop:
      source:
        validate: test-file-exists(a-1)
      dest:
        is: str
  tools:
    list: builder-template-list(a)
    diff: builder-template-diff(a)
    represent: builder-template-represent(a)
    hydrate: builder-template-hydrate(a)
```

After the move those pivots are `$subject/$object/$action` → `builder-template-*`. `source` is a path (must exist). Walk relative names; run `builder-literal-hydrate` (or the same substitution) on each relative path string and each file body; write under `dest`. `kind` lives on `literal.able` — do not duplicate it here. `validate:` / `a-1` spelling matches the wrap draft, still exploratory per yml-structure Wave B gaps.

**Not this sketch:** a second token syntax, archive/compress helpers, `freeze.able`, builder **code** entity, `prototype.able`, putting `*.able.yml` under `template/core/`. README `[able].able.yml` / `[entity].entity.yml` under `template/core/` are **payload** the builder may emit, not this contract file.

---

## Among the September plans

Same shelf as [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) and [10-begin-entity-system-with-remote-instances.md](./10-begin-entity-system-with-remote-instances.md): **later / out of the lazy-include loop**.

- [12-subject-object-action-entry-points.md](./12-subject-object-action-entry-points.md) (shipped) already trimmed `[object]` templates and wanted `builder/code/.asc_objects_ignore`. After the move, that ignore is this plan’s problem (or drops, if `code/` is data).
- [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) — builder templates still scaffold `{subject}.opt-inc.sh`; keep that aligned with [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md). Do not use `software` as the model.
- [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md) **Ext rest** (crontab, compose, remote, entity, …) must **not** swallow this move.
- Entity “builder code entity” stays on the entity plan. This file does not start entities.

Stamp watches `asc/` and `asc/extensions/` mtimes. A `git mv` rewrites primitives / `pivots.mk`. Independent of lazy-include logically; concurrent with fs+db is noise. Implement later.

---

## Tests (when a later session implements)

Unrun stays unverified. After `git mv`:

- `make reinit` then `make test-core`.
- `make make-list-entry-points` (or `make list-actions`) prints `builder-prototype-build` and `builder-template-hydrate`. Does **not** print `code-var-is` / `code-function-is`. Does **not** discover `template/core/[subject]/…`.
- `make test-core` still runs the relocated `builder_template.test.sh` via [`asc/test/core.hook.sh`](../../../asc/test/core.hook.sh) only. No second `*/test/core.hook.sh` under `asc/builder/`.
- `data/asc/cache/core/active.sh` / `ASC_INC` does **not** gain `builder.inc.sh`.
- `asc/builder/template.able.yml` and `asc/builder/literal.able.yml` exist (stubs from the sketches). `asc/builder/template/template.able.yml` does **not**. No `asc/builder/literal/` object dir.
- Existing kernel subjects (`host`, `instance`, `test`, …) unchanged.

---

## Open tasks

- [ ] Later: `git mv` `asc/extensions/builder` → `asc/builder`; keep `prototype/` and `template/` as `$object` dirs; leave `template/core/` in place.
- [ ] Move `asc/builder/test/core/template.test.sh` → `asc/test/core/builder_template.test.sh`. Delete `asc/builder/test/core.hook.sh` (and the emptied `asc/builder/test/` tree). Same PR as the `git mv`.
- [ ] `asc/builder/code/` as data; `.asc_objects_ignore` only if immediate valid `*.sh` appears.
- [ ] Grep for `prototype-build` / `template-hydrate` / `builder-` callers before adding `ASC_SYNONYMS`. Skip if none.
- [ ] Add `asc/builder/template.able.yml` and `asc/builder/literal.able.yml` from the sketches above (stubs). Do **not** put `*.able.yml` under the `template/` object dir. Do **not** invent `literal/`. Do **not** wire a YAML loader. Do **not** fill hydrate/build `TODO` in the same PR.
- [ ] `make reinit` then `make test-core`.
