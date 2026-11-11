# Living docs: absorb root README § Current status

| Field | Value |
|-------|--------|
| **Date** | 2026-07-26 |
| **Status** | done (docs) |
| **Scope** | `docs/asc/**` living suite |

## Context

Root `README.md` gained a large **Current status** / raw TODO dump (rewrite notes: path shapes, field vs prop, DSL redesign, sidecars, workflow, atomic blueprints, cache, hooks aliases, …). Living docs are the compiled SoT; the README dump stays as raw notes until the product README is rewritten.

## What changed

Compiled those notes into:

| Page | Topics absorbed |
|------|-----------------|
| `docs/asc/README.md` | Rewrite status TODO order; TOC links for new sections |
| `organization.md` | Agnostic `$subject`/`$object`/`$action`; seed→cmd; `hook-ms`/`hook-dr`; incremental cache / freeze.able |
| `entities.md` | Genericity scale; files/dirs; field vs prop; sidecar; `--` relation notation; change / workflow |
| `yml-structure.md` | Props vs fields; proposed `a`/`o` validation YAML |
| `builder.md` | Blueprint = DSL\|tpl kinds; atomic blueprint objects; `tpl()` rename; rules/sync sketch |
| `shell-usage.md` | Competing DSL redesign (punctuation invert + `bo`; positionals already `a`/`a_*`); `<asc-dsl>` / `<asc-yml>` stdout |
| `wrappers.md` | Rules pattern presets / sudoers / change recap |
| `documentation.md` | Root README § Current status as raw-notes role |

## Safety / locks

- Filename-DSL punctuation in `changelog/2026/07/24-filename-dsl.md` remains SoT until explicitly superseded.
- Positional / function-arg prefix is **`a` / `a_*`** (not `p_*`).
- README punctuation invert + `bo` tokens documented as **proposed only** under `shell-usage.md` § proposed DSL redesign.

## Open (aligned to root README § Current status — SoT)

Stabilization order still open (docs first, then code):

1. Naming convention in doc (`23-f-e-naming-convention.md` + Cursor `naming.mdc` — positional SoT is **`a` / `a_*`**, not tip `p_*`)
2. Workflow + git flow in doc (change-centered; `change.entity.yml` nestable; changelogs as sidecars; `data/changes/**` inbox started 2026-07-27)
3. Hooks in doc (`hook` / `hook-ms` / `hook-dr`; subject-only hooks vs `$object` dirs)
4. DSL in doc — **accept or reject** README punctuation invert + `bo` / `a-1s` redesign vs locked `24-filename-dsl.md` before any parser work
5. YAML in doc (`24-yml-structure.md` Waves A/B still review)
6–11. Refactor bootstrap → core+extensions → nestable tests → builder → baseline → agents (Cursor MVP first)

Also open from README (not yet decided in a dedicated accept/reject pass):

- Discovery for both `$subject`/`$action` and `$subject`/`$object`/`$action` (agnostic)
- **Tension:** README TODO “drop submodule declarations via `.asc_extensions` because of objects” vs plan lock in `24-subject-asc-extensions.md` (positive nest list) — living org.md already flags this
- Stabilize fields via `remote_host` / `remote_instance` entity examples (field vs prop)
- Seed → command (`cmd`); freeze.able / incremental cache; builder code entity; template `tpl` / `<asc-if>` syntax; make understands DSL; namespaced entry-point notation optional

**Amendment (2026-07-27):** root README remains raw-notes SoT; this changelog’s “done (docs)” pass still holds for the July-26 absorption, but Open above replaces the shorter prior list. Atomic nestable change YAML inbox: `data/changes/human/inbox/2026/07/27/`.
