# Deprecate `$subject/.asc_extensions` (positive nest list)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **implemented** (docs/plan 2026-09-22) — July 24 positive-list rejected; no loader. Keep `.asc_subjects_ignore`. |
| **Scope** | ASC mother `/home/paul/Documents/asc` — whether README / plan wording should keep advertising `$subject/.asc_extensions` as the nested-extension declaration |
| **Related** | Plan [24-subject-asc-extensions.md](../07/24-subject-asc-extensions.md) (open conflict since 2026-07-27); object discovery [12-subject-object-action-entry-points.md](./12-subject-object-action-entry-points.md); builder skip [20-builder-kernel-subject.md](./20-builder-kernel-subject.md); gates note [22-gates-prune-approved-work.md](./22-gates-prune-approved-work.md) (“Not this change: implementing `$subject/.asc_extensions` discovery”) |
| **Not this change** | Removing code (there is none). Migrating nest folders. Implementing nested mini-extension recursion. Committing. |

`$` in this file is the ASC docs placeholder (`$subject` / `$object` / `$action` / `$extension`), not a shell variable. The path `$subject/.asc_extensions` is allowed as the declaration under discussion. Do not confuse it with `.asc_extensions_ignore` (top-level extension blacklist).

---

## Context

README proposals from earlier today (2026-09-22) say nested extension folders are a **separate declaration**: `$subject/.asc_extensions` (positive list), and that `.asc_subjects_ignore` must not be the nest list. That restates the July 24 plan.

The human now asks whether that positive-list wording can be **deprecated**.

July 24’s own amendment already flagged a README tension: once `$subject` / `$object` / `$action` discovery lands, submodule-style nest declarations may be unnecessary. Object discovery is **implemented** (see `f_asc_extend` / `ASC_OBJECTS` in `asc/core/core.manual-inc.sh`, changelog 12). The positive-list loader was **never** accepted or written.

---

## What was checked in the tree

| Check | Result |
|-------|--------|
| `find` for files named `.asc_extensions` | **Zero** under the mother tree (including `asc/core/`). The July plan’s seed `asc/core/.asc_extensions` → `utils` is **gone**; `asc/core/utils/` is loaded via `utils.manual-inc.sh`, not nest discovery. |
| Shell sources reading bare `.asc_extensions` (excluding `_ignore` / `f_asc_extensions*`) | **None** under `asc/` or `scripts/`. |
| Live ignore / discover APIs | `.asc_extensions_ignore` via `f_asc_extensions_ignore_filepath` / `_load` / `f_asc_extensions_discover` / `f_asc_extensions` in `asc/core/core.manual-inc.sh`. `.asc_subjects_ignore` via generic `f_asc_primitive_values` (`.$dn_$primitive_ignore`). |
| Nested recursion | `f_asc_extensions_discover` only walks `asc/extensions/*`, `scripts/asc/contrib/$vendor/*`, and `scripts/asc/extend`. It does **not** open `$subject/.asc_extensions` or re-enter ignored nest dirs as extension points. |
| Object model | `ASC_OBJECTS` in `data/asc/cache/core/active.sh` includes pairs such as `host/dependency`, `instance/registry`. Object dirs are not active dirs (no hook implementations there) — changelog 12. |
| On-disk “nest” leftovers | `.asc_subjects_ignore` still lists `nested_hardware`, `nested_software`, `nested_docker`, `gitflow`; `asc/.asc_subjects_ignore` lists `env` / `extensions` / `vendor`. `entity/field` has **no** subjects-ignore and appears in `ENTITY_SUBJECTS`. `asc/dir/nested_dir` is YAML-only (not an object). |
| Tests | `asc/test/core/extensions.test.sh` covers **top-level** contrib discovery + `.asc_extensions_ignore` prefixes — not `$subject/.asc_extensions` files. No test was run for this proposal (no behavior change). |
| Able stubs | `asc/dir/asc_extensions_ignore.able.yml` / `asc/file/…` name the **ignore** able, not a positive-list entity. |

**Verdict:** the positive-list declaration is **documented / planned only**. Runtime does **not** read `$subject/.asc_extensions`. Removing the *wording* (and rejecting the plan) does not change bootstrap, pivots, or hook lookup.

---

## Is it still read by code, only documented, or both?

**Only documented (plus an unimplemented plan).** Code reads `.asc_extensions_ignore` and `.asc_subjects_ignore`. It does not read `$subject/.asc_extensions`.

---

## What would break if the declaration were “removed”

| Surface | Impact |
|---------|--------|
| Mother runtime | **Nothing** — no reader, no seed file. |
| Contrib / home `scripts/asc` | **Nothing** at load time unless some instance invented a custom reader (none found here). |
| Existing nest folders | Unchanged. They already rely on subjects-ignore (negative) or sit as ordinary subjects / YAML trees / unreachable action nests (`nested_docker/…`). |
| Agents / docs | Risk if proposals keep advertising a loader that will never ship — agents may invent files or wait on a false dependency (builder already refused to wait: changelog 20). |

---

## Pros of deprecating it now

1. Matches the tree: objects are live; the positive-list loader is not.
2. Ends the July 24 ↔ README conflict without implementing either migration.
3. Avoids filename clash confusion with `.asc_extensions_ignore`.
4. Keeps `.asc_subjects_ignore` as one clear job: **not a subject**.
5. Lightweight: changelog + README proposal edit only.

## Cons / what might still want a positive list

1. **True nested mini-extension points** (own subjects, includes, hook implementations under a nest, same specificity as the parent extension point) are still **not** implemented. Objects explicitly refuse to be active dirs. Subjects-ignore only subtracts; it does not promote.
2. Shapes like `scripts/asc/contrib/asc/docker/nested_docker/…` with real `*.sh` under a double nest remain awkward until someone restructures them as `$subject/$object/$action` or a real subject tree.
3. Stub forests (`nested_hardware`, `nested_software`, `nested_dir`) still need a human rule for “folder that must not become a subject” — that stays **subjects-ignore**, not a new positive list.
4. Rejecting the plan leaves the human README tree line that still labels `.asc_subjects_ignore` as `[nested $ext] submodule(s)` — that human line stays until the human edits it; proposals can only sit beside it.

---

## Recommendation

**Deprecate the positive-list declaration now** (docs/plan): do **not** implement `$subject/.asc_extensions`; treat [24-subject-asc-extensions.md](../07/24-subject-asc-extensions.md) as **superseded / reject** in favor of:

- `.asc_subjects_ignore` = names that must **not** become subjects (only);
- `$subject/$object/$action` for three-level **entry points**;
- no new nest-extension loader until a concrete active-dir nest appears that objects cannot express.

**Do not** keep advertising the positive list in README proposals. Update today’s proposal blocks to retract it (lighter wording next to the human lines). Leave human-written README lines untouched.

This is choice **(b)** from the July 27 amendment (reject the positive-list lock in favor of object-depth discovery), with subjects-ignore kept for true blacklists.

---

## Safety notes

- Deprecation here means **stop planning to load the file**, not delete unrelated `.asc_extensions_ignore` machinery.
- Do not mass-migrate nest folders in this pass.
- Do not invent recursive `f_asc_extend` “for completeness.”
- Hook implementations stay `$subject`-scoped; `$object` dirs stay entry-point only.

## Open tasks

- [x] Human accept: mark July 24 plan rejected/superseded (status line there).
- [x] Keep README proposals aligned with this recommendation (updated 2026-09-22 in the same proposal tags).
- [ ] Optional later: human rewrite of any remaining file-structure wording that still reads nests as submodules on `.asc_subjects_ignore` (tree lines already say blacklisted).
- [ ] Optional later: reshape `nested_docker` (or similar) to `$subject/$object/$action` if those scripts should become pivots.
- [x] No new test (docs/plan only; runtime unchanged).
