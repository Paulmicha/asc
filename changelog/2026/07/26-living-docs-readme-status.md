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

## Open

- Accept or reject the DSL redesign in a dedicated changelog before implementation.
- Stabilize fields using remote_host / remote_instance examples.
- Drop `.asc_extensions` submodule declarations once `$object` discovery lands.
