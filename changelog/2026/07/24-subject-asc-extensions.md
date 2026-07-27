# Plan: `$subject/.asc_extensions` declares nested ASC extensions

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (not implemented; design lock for review) — **open conflict with root README** (see Amendment 2026-07-27) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — how nested extension points are **declared** under any `$subject` (and under extension / contrib / extend trees); specificity weight for hooks in those nests |
| **Related** | Idea `data/ideas/2026/07/18/extensions.md` (specificity note + extension-point scale); `data/ideas/2026/07/18/nested.md`; living `docs/asc/organization.md` § subjects; `docs/asc/wrappers.md` § nested; README extension-point lists; seed file `asc/asc/.asc_extensions` (`utils`); filename-DSL nest notes in `changelog/2026/07/24-filename-dsl.md` |
| **Lifecycle** | Local review stub: `data/plans/review/2026-07-24-subject-asc-extensions.md` (dir mostly gitignored — **this changelog is the tracked SoT**, same pattern as `24-filename-dsl.md` / `24-yml-structure.md`). Move stub across `review` → `iterate` → `accepted` / `rejected` per `data/ideas/2026/07/23/idea-changelog-workflow.md`. |
| **Living docs (on accept / implement)** | Update `docs/asc/organization.md`, `docs/asc/wrappers.md`, README extension-point bullets, `docs/asc/archive/extensions.md` if revived — replace “via `.asc_subjects_ignore`” nested-extension wording with `$subject/.asc_extensions`. |

---

## Context

ASC already has **nested extension points**: folders under an extension (or under `./asc`, contrib, extend) that are themselves mini extension trees — e.g. `asc/extensions/entity/field`, `asc/extensions/hardware/nested_hardware`, `asc/dir/nested_dir`.

**Today’s declaration (overloaded):** those nests are listed in **`.asc_subjects_ignore`**. That file is also used to blacklist folders that must **not** become subjects and are **not** nested extensions (e.g. `asc/.asc_subjects_ignore` → `env`, `extensions`, `vendor`). Living docs call `.asc_subjects_ignore` the “nested-extension submodule list”, which conflates ignore-as-subject with promote-to-nested-extension.

**Emerging seed:** `asc/asc/.asc_extensions` lists `utils` — a **positive** declaration of a nested extension dir under `$subject` = `asc`, without relying on subjects-ignore.

**Specificity (unchanged intent):** any nested extension’s hook implementations must have the **exact same specificity (weight)** as if they lived on the nearest non-nested extension point closer to project docroot. Example from the 2026-07-18 idea: implementing `u_hook_most_specific()` under `asc/extensions/entity/field` must weigh the same as under `asc/extensions/entity`.

---

## Locked decision

**Any `$subject/.asc_extensions` file turns its listed directory names into nested ASC extensions**, using the **same specificity mechanism** as today’s nested-extension points.

| Rule | Detail |
|------|--------|
| **Where** | Under **any** `$subject/` that participates in extension-point discovery — including core `asc/$subject/`, `asc/extensions/$extension/…`, `scripts/asc/contrib/…`, `scripts/asc/extend/…` (and nests of those). |
| **File** | `$subject/.asc_extensions` — one directory name per line (same line-oriented style as `.asc_subjects_ignore` / `.asc_extensions_ignore`). |
| **Effect** | Each listed name that resolves to a directory under that `$subject/` becomes a **nested ASC extension** (own subjects/actions/inc aggregation via the same `u_asc_extend`-style primitives as a top-level extension folder). |
| **Specificity** | Nested hook / most-specific weight = **same as the nearest non-nested extension point** toward project docroot (not deeper / not weaker). Do **not** invent a parallel weight scale for nests. |
| **Not** | `.asc_extensions_ignore` (global enable/disable of top-level `asc/extensions/$extension` names). Do not conflate the two filenames. |

Documentation `$` notation still applies: `$subject` = any make-entry-point subject (slug, or hook DSL on `*.hook.yml` / `*.hook.sh` only). On disk the path is the concrete subject folder + `/.asc_extensions`.

---

## Separation from `.asc_subjects_ignore`

| Dotfile | Role (locked intent) |
|---------|----------------------|
| **`$subject/.asc_extensions`** | **Positive** list → listed dirs are **nested ASC extensions**. |
| **`.asc_subjects_ignore`** (at extension root or subject level) | **Negative** list → listed names are **not** subjects. Does **not** by itself promote a folder to a nested extension. |
| **`.asc_extensions_ignore`** | Top-level extension **blacklist** under `asc/extensions/` (and override paths). Unrelated to per-subject nests. |

A folder may still need to appear in `.asc_subjects_ignore` so it is not also registered as a plain subject **and** in `.asc_extensions` so it is registered as a nested extension — or runtime may auto-exclude listed `.asc_extensions` dirs from the subject set (preferred convenience; confirm in implementation). Prefer **one clear rule** in code: listed in `.asc_extensions` ⇒ nested extension, **not** a sibling `$subject`.

---

## Extension-point scale (wording update)

Generic → specific (`u_hook_most_specific()`, bottom wins) — same order as README / idea, with declaration renamed:

1. `asc/$subject/$action`
1. `asc/extensions/$extension/$subject/$action`
1. `asc/extensions/$extension/**/$nested_extension` (**via `$subject/.asc_extensions`**)
1. `scripts/asc/contrib/$extension/$subject/$action`
1. `scripts/asc/contrib/$extension/**/$nested_extension` (**via `$subject/.asc_extensions`**)
1. `scripts/asc/extend/$subject/$action`
1. `scripts/asc/extend/**/$nested_extension` (**via `$subject/.asc_extensions`**)

Containing folders of `$subject`/`$action` scripts:

- `./asc`
- `./asc/extensions/$extension`
- `./asc/extensions/$extension/**/$nested_extension` (via `$subject/.asc_extensions`)
- `./scripts/asc/contrib/$extension`
- `./scripts/asc/contrib/$extension/**/$nested_extension` (via `$subject/.asc_extensions`)
- `./scripts/asc/extend`
- `./scripts/asc/extend/**/$nested_extension` (via `$subject/.asc_extensions`)

---

## Worked examples (current tree → target declaration)

| Today (via `.asc_subjects_ignore`) | Target |
|------------------------------------|--------|
| `asc/extensions/entity/.asc_subjects_ignore` → `field` | `asc/extensions/entity/.asc_extensions` → `field` (and drop `field` from subjects-ignore **or** keep ignore only if still needed for non-nest reasons) |
| `asc/extensions/hardware/.asc_subjects_ignore` → `nested_hardware` | `…/hardware/.asc_extensions` → `nested_hardware` |
| `asc/extensions/software/.asc_subjects_ignore` → `nested_software` | `…/software/.asc_extensions` → `nested_software` |
| `asc/dir/.asc_subjects_ignore` → `nested_dir` | `asc/dir/.asc_extensions` → `nested_dir` |
| `scripts/asc/contrib/asc/docker/.asc_subjects_ignore` → `nested_docker` | `…/docker/.asc_extensions` → `nested_docker` |
| `asc/asc/.asc_extensions` → `utils` | **Already** the target form (seed). |

`asc/.asc_subjects_ignore` (`env`, `extensions`, `vendor`) stays **subjects-ignore only** — those are not nested extensions.

---

## Goals

1. Lock **`$subject/.asc_extensions`** as the declaration SoT for nested ASC extensions.
2. Keep **specificity weight** identical to the nearest non-nested extension point (existing contract).
3. Untangle **`.asc_subjects_ignore`** so it is only “not a subject”, not “is a nested extension”.
4. Migrate existing nest lists (entity/field, hardware/software nested_*, folder/nested_dir, docker/nested_docker) once implementation is accepted.
5. Align living docs + README with the new wording; leave filename-DSL `foo.bar` nest mapping to point at this mechanism.

Non-goals (for now): implementing the loader change; recursive multi-level `.asc_extensions` depth policy beyond “same as today”; changing `.asc_extensions_ignore` override lookup; renaming top-level extension folders.

---

## Open tasks

- [ ] Accept or amend this plan (review → iterate).
- [ ] Confirm runtime rule: dirs listed in `.asc_extensions` are **automatically** excluded from `ASC_*_SUBJECTS` (no mandatory duplicate line in `.asc_subjects_ignore`).
- [ ] Confirm whether `.asc_extensions` is read only at **subject** folders that are themselves extension roots / subject roots, or also at arbitrary depth (recursive nests of nests).
- [ ] Implement discovery in `u_asc_extend` / `u_asc_extensions` (or dedicated helper) — plan-only until go-ahead.
- [ ] Migrate existing `.asc_subjects_ignore` nest entries → `.asc_extensions`; leave true blacklists in subjects-ignore.
- [ ] Tests: nest declared via `.asc_extensions` aggregates primitives; most-specific weight matches parent extension point (shunit2 under `asc/test/`).
- [ ] Living-docs + README wording pass; thin Cursor rule pointer if agents keep writing nests into `.asc_subjects_ignore`.
- [ ] Cross-link from filename-DSL open item “Nested subjects / `.asc_subjects_ignore`” → this changelog once accepted.

---

## Safety / notes

- Do **not** treat this changelog as implementation go-ahead.
- Name collision risk: `.asc_extensions` (per-subject nest list) vs `.asc_extensions_ignore` (global extension off-list) — docs and code comments must keep them distinct.
- Empty able stubs `asc_extensions_ignore.able.yml` / `asc_subjects_ignore.able.yml` under `folder` / `file` remain placeholders; do not invent YAML body schema here (owned by `24-yml-structure.md` if needed later).

---

## Amendment (2026-07-27) — README SoT tension

Root `README.md` § Current status now also says:

> Also TODO : drop submodules declarations via `.asc_extensions` because of objects.

That line **conflicts** with this plan’s locked positive-list role for `$subject/.asc_extensions`. Living docs (`docs/asc/organization.md`, `docs/asc/README.md`) already flag the tension and keep **this changelog** as living SoT until an explicit accept / reject / amend pass.

**Reading until decided:**

| Stance | Meaning |
|--------|---------|
| **This plan (current lock)** | `.asc_extensions` = positive nested-extension declaration; untangle from `.asc_subjects_ignore` |
| **README raw TODO** | Once `$subject`/`$object`/`$action` discovery lands, submodule-style nest declarations may become unnecessary or wrong — possibly **drop** reliance on `.asc_extensions` for that job |

**Do not implement migration either way** until that conflict is resolved in conversation (and this status line updated). Prefer a dedicated decision that either (a) keeps the positive-list lock, (b) rejects this plan in favor of object-depth discovery only, or (c) amends both (e.g. keep `.asc_extensions` for non-object nests only).
