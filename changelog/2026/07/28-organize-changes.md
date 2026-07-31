# Plan: Organize nestable changes into iterative independent artifacts

| Field | Value |
|-------|--------|
| **Date** | 2026-07-28 |
| **Status** | plan / review (docs only — **not** an inbox reorg go-ahead) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — how to **further split** and **re-bucket** work already sketched as nestable change YAML under `data/changes/human/inbox/2026/07/27/`; alignment with root `README.md` § Current status and July 2026 plan changelogs |
| **Related** | Inbox specimen + first dump `data/changes/human/inbox/2026/07/27/` (`foobar.yml` format, plan-derived trees); `changelog/2026/07/23-f-e-naming-convention.md`; `24-filename-dsl.md`; `24-yml-structure.md`; `24-subject-asc-extensions.md`; `26-living-docs-readme-status.md`; living `docs/asc/entities.md` § change / workflow; `asc/extensions/change/`; root README § Current status (raw-notes SoT) |
| **Lifecycle** | Review this changelog; amend in conversation; only then rewrite / move inbox YAML (or keep 2026/07/27 as historical dump and land a new dated inbox). Do **not** treat this file as permission to mass-reorganize the inbox. |
| **Living docs (on accept)** | Thin note under `docs/asc/entities.md` § change / workflow and/or `data/changes/human/README.md` — wave + kind conventions; point here as dated SoT while status is review. |

---

## Context

On 2026-07-27 the open work from July changelogs + README raw TODO was broken into nestable **change** YAML under:

```text
data/changes/human/inbox/2026/07/27/
```

**Format (locked for MVP review):** each `*.yml` carries:

| Key | Synonym | Role |
|-----|---------|------|
| `goal` | `objective` | One coherent objective for this change entity |
| `paths` | — | Dirs / files in play (mid-grain — not whole-repo, not one-file-per-path noise) |
| `why` | — | Explanations — why this change exists |

**Nesting:** `<id>.yml` + optional sibling directory `<id>/` with numbered children `<n>-<slug>.yml` (children may nest the same way). Specimen: `foobar.yml` + `foobar/`.

**What landed as top-level trees (plan-shaped):**

| Tree | Source |
|------|--------|
| `foobar/` | Format specimen only |
| `f-e-naming-convention/` | Phases of `23-f-e-naming-convention.md` |
| `filename-dsl/` | Phases of `24-filename-dsl.md` (incl. multi-shell nest) |
| `yml-structure/` | Waves / follow-ups of `24-yml-structure.md` |
| `subject-asc-extensions/` | `24-subject-asc-extensions.md` |
| `readme-rewrite-todo/` | Root README numbered items 1–11 |
| `readme-cross-cutting/` | README notes outside 1–11 |

**Problem for iteration:** those trees are still **plan-chapter shaped**, not **artifact shaped**. Several parents **duplicate** each other (e.g. `readme-rewrite-todo/1–5` vs the plan trees; `readme-rewrite-todo/6-refactor-bootstrap` vs `filename-dsl/3-complete-multi-shell-groundwork`). Agents (and humans) cannot pick a leaf and know it is independently shippable without re-deriving a dependency DAG each time.

**This changelog** records a proposed organization: axes, waves, re-bucketing rules, concrete moves, and a minimal next cut — for review before any inbox rewrite.

---

## Goals

1. Define what an **independent implementable artifact** means for ASC change YAML.
2. Split work along **kind**, **wave**, and **surface** — not along changelog chapter titles alone.
3. Make **hard blockers** (decisions) explicit, tiny, and serial.
4. Separate **restore bootstrap** from **filename-DSL grammar / parser** work so “make `. asc/bootstrap.sh` work again” is not blocked on redesign accept/reject beyond what’s strictly required.
5. Collapse **wishlist / sequencing indexes** (`readme-rewrite-todo` as executable parent) so they stop looking like implementable changes.
6. Give a **queue order** agents can follow: decide → restore boot → doc contracts → renames → DSL → product.
7. Leave July-24/23 **plan SoTs** intact; this doc owns **change-inbox organization** only.

Non-goals (for now): implementing renames/DSL/loaders; inventing a second workflow engine; requiring new YAML keys in the MVP schema (`kind` / `wave` / `blocked_by` are optional later); mass-deleting the 2026/07/27 dump before accept.

---

## Definition — independent implementable artifact

An inbox change is **independently implementable** when **all** of the following hold:

1. **One mergeable outcome** — a reviewer can say accept / reject / ship against a single coherent `goal`.
2. **Explicit ship criteria** — docs diff, decision recorded in a changelog, `make test-core` green, `. asc/bootstrap.sh` works, grep gates clean, etc. — stated in `why` or a child leaf, not implied.
3. **Bounded `paths`** — touching the listed surfaces is enough; no silent need to churn unrelated trees.
4. **No hidden blockers** — if the work needs a prior human yes/no or another artifact, that dependency is either:
   - a **parent/ancestor** in the nest, or
   - a **named prior wave / decide leaf**, or
   - (later) an optional `blocked_by:` field — not buried in prose only.
5. **One risk class** — do not mix “decide punctuation” + “rewrite 1900 call sites” + “new hook loader” in the same leaf.
6. **Revertable** — preferably one PR / one short PR series with a clear revert story (especially for breaking renames).

**Mid-grain reminder (unchanged):** not a mega-plan for the whole rewrite; not one change per file or per directory. Nest when a chunk still shares one `why` but decomposes into shippable steps.

---

## Problem diagnosis — current 2026/07/27 dump

### Plan-shaped vs artifact-shaped

| Pattern today | Why it hurts iteration |
|---------------|------------------------|
| Parents mirror changelog phase lists (`Phase 0…5`) | Phases are narrative; artifacts are shippable outcomes |
| `readme-rewrite-todo` restates README 1–11 | Sequencing index disguised as work; duplicates plan trees |
| `filename-dsl` holds both redesign decide + multi-shell restore + parser phases | Bootstrap restore blocked socially/structurally on DSL accept |
| `f-e-naming-convention/2-rename-u-to-f-and-hookms` | Still a mega-PR; “Phase 1” ≠ one artifact |
| `readme-cross-cutting/*` peers with bootstrap | Many items need DSL runtime or `$object` discovery first — fake independence |
| Overlap children (`stabilize-*-doc` vs plan trees) | Two SoTs for the same gate; drift risk |

### Duplication map (do not implement twice)

| Index / duplicate | Real owner (keep as implementable home) |
|-------------------|----------------------------------------|
| `readme-rewrite-todo/1-stabilize-naming-doc` | Doc gate of `f-e-naming-convention` + living docs — or a W2 leaf, not both |
| `readme-rewrite-todo/4-stabilize-dsl-doc` | `filename-dsl` decide + living-docs pass |
| `readme-rewrite-todo/5-stabilize-yml-doc` | `yml-structure` |
| `readme-rewrite-todo/6-refactor-bootstrap` | `filename-dsl/3-complete-multi-shell-groundwork` → proposed **W1** |
| `readme-rewrite-todo/7-…` discovery / fields | Future **W5** product slices (after yml + discovery locks) |

---

## Proposed split — three axes

Organize (and eventually re-folder) along **all three**; filesystem can encode wave + slug; kind can be prefix or optional YAML key later.

### 1. Kind (review / risk class)

| Kind | Meaning | Typical ship criteria | May touch `asc/**/*.sh`? |
|------|---------|----------------------|-------------------------|
| **`decide`** | Human accept / reject / amend a lock | Changelog status line + living-doc one-liner updated | **No** (except the changelog / rules that record the lock) |
| **`doc`** | Living docs / README / Cursor rules traces only | Docs speak one vocabulary; no runtime change | Rules `.mdc` yes; shell no (unless comment-only and called out) |
| **`mech`** | Mechanical rename / migrate lists / amend draft YAML bodies to a frozen shape | Grep gates + tests; bisectable commits | Yes — bounded symbol/path set |
| **`runtime`** | New or rewired behavior (loaders, discovery, generators) | Smoke + `make test-core` (or scoped) | Yes |
| **`test`** | Fixtures / goldens / harness cases as the primary deliverable | `make test-core` green for new cases | Test tree + minimal harness helpers |

**Hard rule:** a `decide` leaf must not list implementation `paths` under `asc/**/*.sh` as if coding were in scope. Record the decision, then open a dependent `mech` / `runtime` child or sibling under a later wave.

### 2. Wave (hard dependency order)

| Wave | Name | Role |
|------|------|------|
| **W0** | Decisions | Serial, tiny; unblock everything else |
| **W1** | Bootstrap restore | Vertical slice: paths → `ASC_SHELL` → include-loader → bash smoke |
| **W2** | Contracts as docs | Parallel *after* W0 (and parallel with late W1 if careful) |
| **W3** | Symbol renames | Serial among rename classes; after W2 naming doc gate |
| **W4** | Filename-DSL | Only after W0 grammar choose; prefer after W1 green |
| **W5** | Product | `$object` discovery, fields examples, builder slices, baseline, agents; after needed contracts |

```text
W0 decide (serial, tiny)
  ├─ DSL redesign accept/reject
  └─ .asc_extensions keep / drop / amend
        ↓
W1 restore bootstrap (one vertical slice — first code wave)
  rewire paths → ASC_SHELL → include-loader → bash smoke
        ↓
W2 contracts as docs (parallel after W0)
  naming doc · hooks doc · yml Wave A/B Qs · field/prop · change inbox schema · guidelines
        ↓
W3 mechanical renames (serial among themselves; after W2 naming doc)
  hookms → f_* (by surface) → o_* → e_* → gates
        ↓
W4 DSL (only if W0 accepted locked grammar or an explicit redesign SoT)
  fixtures → runtime → hook.yml → explicit actions → verify
        ↓
W5 product (after discovery + yml field locks as needed)
  $object discovery · remote field examples · .asc_extensions implement?
  · builder slices · nestable tests · baseline · agents
```

**Parked** (not a peer of W1): seed→cmd, incremental cache rebuild, parsable stdout templates, rules/sync pattern, make-understands-DSL — dependents of W4/W5. Keep under `W5-parked/` or leave as ideas until unblocked.

### 3. Surface (parallelism *within* a wave)

Examples: `bootstrap` · `symbols` · `yml-body` · `discovery` · `change-workflow` · `builder` · `agents`.

Within W2/W5, different surfaces can proceed in parallel if they don’t share a decide lock. Within W3, **surfaces split the mega `f_*` rename** (see below); rename **classes** (`hookms` / `f_*` / `o_*` / `e_*`) stay serial.

---

## Proposed inbox layout (after accept)

Illustrative — exact date folder may be `2026/07/28/` or a move of selected leaves out of `2026/07/27/`:

```text
data/changes/human/inbox/YYYY/MM/DD/
  W0-decisions/
    1-decide-dsl-redesign.yml
    2-decide-asc-extensions.yml
    3-decide-yml-wave-a.yml          # optional split
    4-decide-yml-wave-b.yml          # optional split
  W1-bootstrap-restore/
    W1-bootstrap-restore.yml         # parent goal
    1-rewire-bootstrap-paths.yml
    2-export-asc-shell.yml
    3-include-loader-hook.yml
    4-bash-bootstrap-smoke.yml
  W2-contracts-docs/
    …
  W3-symbol-renames/
    …
  W4-filename-dsl/
    …
  W5-product/
    …
  W5-parked/                         # or data/ideas — not fake-ready
    …
  _index-readme-rewrite-todo.md      # optional non-YAML sequencing sidecar
```

**Optional YAML extensions (later — not required for MVP):**

```yaml
goal: …
paths: […]
why: |
  …
kind: decide        # decide | doc | mech | runtime | test
wave: W0
blocked_by:
  - W0-decisions/1-decide-dsl-redesign
```

Filesystem wave prefixes already carry most of this; add keys only if agents ignore folder meaning.

---

## Concrete re-bucketing of 2026/07/27 trees

### Demote / non-executable

| Current | Action after accept |
|---------|---------------------|
| `readme-rewrite-todo.yml` (+ most children that only restate 1–11) | **Demote** to a non-executable index (markdown sidecar or changelog appendix). Not an implementable change parent. |
| Duplicate `stabilize-*-doc` / `6-refactor-bootstrap` children | **Delete or replace** with pointers to W1/W2/plan-owned leaves |
| `readme-cross-cutting.yml` children that need DSL/`$object` | Move to **`W5-parked/`** (or leave as ideas) until unblocked |
| `foobar/` | Keep as **format specimen** only (any date) |

### Promote to W0 — one decision = one file

| Leaf | From | Outcome |
|------|------|---------|
| `decide-dsl-redesign` | `filename-dsl/1-resolve-readme-redesign.yml` | Accept locked `24-filename-dsl` punctuation **or** supersede with README invert/`bo`/`a-1s` **or** hybrid amend |
| `decide-asc-extensions` | `subject-asc-extensions/1-resolve-readme-conflict.yml` | Keep positive-list lock **or** reject in favor of `$object`-depth only **or** amend both |
| `decide-yml-wave-a` (optional) | `yml-structure/1-wave-a-…` | Inventory / `new`∈states / spelling / enum asymmetry — Qs only |
| `decide-yml-wave-b` (optional) | `yml-structure/2-wave-b-…` | `include` shape / spine / contract rules home — Qs only |

Amend-draft-bodies (`yml-structure/5-…`) becomes a **W2/W3 `mech`** *after* the matching decide — not part of the decide leaf.

### W1 — lift multi-shell restore out of `filename-dsl`

| Current | Target |
|---------|--------|
| `filename-dsl/3-complete-multi-shell-groundwork.yml` + nested `1–4` | Top-level **`W1-bootstrap-restore/`** (same four children) |

**Why:** commits `648a4d7` / `8f3faa8` / `f971316` already moved utils to `asc/asc/`; phase 20 still references gone `asc/utilities/` — bootstrap is broken. Restoring bash bootstrap is valuable **even if** DSL redesign is still open (loader hook identity is already locked in the filename-dsl plan; redesign is punctuation/token, not “whether includes load via one hook”).

Detach W1 from W4 so grammar/parser work cannot sit on the critical path of “ASC runs again.”

### W2 — docs-only contracts (parallel leaves)

Each leaf ends in a **living-doc (and/or Cursor rule) diff**, not code:

| Theme | Notes |
|-------|--------|
| Naming doc gate | `a`/`a_*`, `f_*`/`e_`/`o_*`, `hookms`; not the rename itself |
| Hooks doc | `hook` / `hook-ms` / `hook-dr` **names & semantics**; subject-only hooks; `$object` dir capabilities |
| Yml living doc | *After* Wave A/B decides — two steps: decide → doc |
| Field vs prop + validation notes | Align README SoT into `yml-structure.md` / `entities.md` once validate-token family known |
| Change inbox schema MVP | `goal`/`paths`/`why` + nest rules + human/agent lanes — already started |
| General guidelines | Max ~1000 lines; meta non-redundancy; facultative namespaced entry notation |
| Cursor rules refresh | Thin bullets; not a second SoT — from `filename-dsl/4-…` |
| Living-docs DSL sweep | From `filename-dsl/5-…` — `$` notation, nest/wrap SoT, optional `_` note |

### W3 — symbol renames (tighten independence)

Keep separate artifacts for **rename classes** (already partly true):

1. `hookms` only (`u_hook_most_specific` → `hookms`)
2. `f_*` utilities (split further by **surface** — below)
3. `o_*` option storage (allowlist)
4. `e_*` exports + consumers
5. Final verify / gates (or per-surface gates)

**Split today’s mega `2-rename-u-to-f-and-hookms` by surface:**

| Proposed leaf | Bounded paths (illustrative) |
|---------------|------------------------------|
| `hookms-only` | Def + all call sites + docs traces for that symbol alone |
| `f-utilities-core` | `asc/utilities/` + bootstrap phase callers |
| `f-core-subjects` | `asc/{git,host,instance,make,test,thread,log,loop,…}/` |
| `f-extensions` | `asc/extensions/**` |
| `f-contrib` | `scripts/asc/contrib/**` |
| `f-docs-traces` | **Prefer riding with each surface** rather than one global late “Phase 4” |

**Rule:** convention-header / README mechanical traces for symbols touched in a surface land **in the same artifact / PR** as that surface — do not leave stale `u_*` docs after a merged core rename.

`o_*` and `e_*` remain their own artifacts (high precision / different risk). Boolean storage stays `b_*` unless W0 accepted README `bo_*` redesign first (`23-f-e` amendment 2026-07-27).

### W4 — filename-DSL implementation (after W0 grammar)

Retain phase spirit as **artifacts**, gated on redesign decide:

| Artifact | Kind |
|----------|------|
| Formal grammar + shunit2 goldens (tests first) | `test` (+ doc) |
| Runtime wrap/nest/arg binding | `runtime` |
| Hook discovery + `.hook.yml` slot defaults | `runtime` |
| Explicit `$action` materialization | `runtime` / builder touch |
| Full verification gate | `test` |

Do **not** bury W2 doc sweeps under W4 parents after reorg.

### W5 — product vertical slices (one each)

| Slice | Depends on |
|-------|------------|
| `$subject`/`$object`/`$action` discovery + tests | W1; hooks doc clarity (W2) |
| `remote_host` / `remote_instance` field examples | Yml field/prop lock (W0/W2) |
| `.asc_extensions` implement → migrate → test | **Only if** W0 kept positive-list; else **cancel** tree |
| Builder — **split**, do not one-shot “complete builder” | Templates syntax · `tpl()` · code entity · self-build chain (separate leaves) |
| Nestable tests refactor | Discovery + DSL test-step policy as needed |
| Baseline exemplar fill | After contracts stable — thin opt-in only |
| Agents — Cursor MVP vs ollama/Hermes/kimi | **Two** artifacts minimum |

### Parked (from `readme-cross-cutting`)

| Item | Unblock when |
|------|----------------|
| Seed → command (`cmd`) + freeze.able naming | W2/W5 docs + cache design |
| Incremental cache rebuild | W1 cache paths stable; preferably builder relation fields |
| Parsable stdout `<asc-dsl>` / `<asc-yml>` + `tpl()` | W4 token SoT; builder template work |
| Rules / sync pattern presets | Rules extension + change inbox stable |
| Make understands DSL | W4 phases 2–4 |
| General guidelines | Can be W2 `doc` if kept tiny — else parked with meta |

---

## Rules of thumb (ongoing)

1. **If it needs a human yes/no, it is a `decide` leaf** — no implementation `paths` into runtime shell as if coding were in scope.
2. **If `make test-core` or `. asc/bootstrap.sh` can prove it, it is implementable** — prefer that over “Phase N of plan.”
3. **One breaking rename class per artifact** — `hookms` ≠ all `f_*` ≠ `o_*` ≠ `e_*`; further split `f_*` by surface.
4. **No parent that only restates README 1–11** — parents group **dependency**, not wishlist.
5. **Park anything that needs DSL runtime or `$object` discovery** until those land — independence is fake if `blocked_by` is only implicit.
6. **Prefer deeper nests under a wave** over more top-level mega-plans — **waves are the isolation boundary**.
7. **July plan changelogs remain decision SoTs** for their domains; this changelog owns **inbox organization** and points at them.
8. **Mid-grain** — if a leaf’s `paths` is “all of `asc/`” without a symbol allowlist or subdirectory bound, split again.

---

## Minimal next cut (highest leverage — proposed first apply)

When this plan is accepted, do **only** the following before more essay-scale YAML writing:

1. **Lift two decides + W1 bootstrap restore** to top-level wave folders (new dated inbox or explicit move notes).
2. **Collapse `readme-rewrite-todo`** to a non-executable index (or delete executable parent).
3. **Split `f_*` rename** into surface slices (+ `hookms-only` first).
4. **Mark cross-cutting** as `W5-parked` (or ideas) until W4/W5.

That yields a queue agents can pick from without re-deriving the DAG: **decide → restore boot → doc contracts → renames → DSL → product**.

---

## Relationship to existing plan SoTs

| Concern | Owner |
|---------|--------|
| `f_*` / `e_*` / `o_*` / `a_*` / `hookms` migration content | `23-f-e-naming-convention.md` |
| Filename grammar, `ASC_SHELL`, include-loader, `$` notation | `24-filename-dsl.md` (+ README redesign amendment) |
| YAML **body** keys, Waves A/B | `24-yml-structure.md` |
| `$subject/.asc_extensions` positive list vs README drop tension | `24-subject-asc-extensions.md` |
| README raw TODO absorption into living docs | `26-living-docs-readme-status.md` |
| **How change YAML is bucketed for iteration** | **This changelog** |
| MVP change YAML keys (`goal` / `paths` / `why`) + nest shape | Inbox README + `foobar` specimen; workflow prose in `entities.md` |

Do **not** fork naming/DSL/yml locks into this file — link and organize only.

---

## Open questions (for review)

1. **Reuse `2026/07/27/` vs new date folder?** Amend in place, or freeze 07/27 as historical dump and land `2026/07/28/` (or later) as the wave-shaped inbox?
2. **Encode `kind` / `wave` / `blocked_by` in YAML now**, or filesystem-only until agents prove they need keys?
3. **W1 vs W0 DSL decide:** confirm bootstrap restore may proceed while redesign is still open (recommended: **yes** — punctuation redesign ≠ include-loader lock).
4. **Yml Wave A/B:** keep as two `decide` leaves, or one `decide-yml-structure` parent with nested Q files?
5. **Agent lanes:** when a human inbox change is accepted, copy/move to `data/changes/agent/…` or reference by path only?
6. **Index format:** markdown `_index-….md` vs a YAML change with `kind: index` that tools must ignore for execution?
7. **Builder split granularity:** agree the four slices (templates · `tpl()` · code entity · self-build) before writing W5 leaves?
8. **Cursor / Hermes:** should “implement agents” W5 MVP be explicitly “consume wave-shaped inbox + produce nested changes” as the first Cursor milestone?

---

## Open tasks

- [ ] Review / amend this plan in conversation (status stays `plan / review`).
- [ ] Answer open Qs 1–3 at least (inbox date strategy; optional YAML keys; W1 unblocked from DSL redesign).
- [ ] On accept: apply **minimal next cut** only; avoid rewriting every leaf in one pass.
- [ ] On accept: thin living-doc / `data/changes/human/README.md` pointer to wave + kind conventions; keep this changelog as dated SoT while iterating.
- [ ] Do **not** implement ASC runtime, renames, or DSL parsers from this document alone.
- [ ] Do **not** mass-delete `2026/07/27/` without an explicit accept of the reorg strategy.

---

## Risks / safety notes

| Risk | Notes |
|------|--------|
| Reorg churn without accept | Inbox YAML is already a large dump; rewriting twice wastes review — hence minimal next cut. |
| Fake independence | Parked items listed as ready peers recreate the current problem. |
| Plan SoT drift | Organizing changes must not silently amend `24-filename-dsl` locks or `.asc_extensions` — use W0 decide leaves. |
| Mega `f_*` PR | Surface split is load-bearing for bisect / revert; do not “save time” by one-shotting all utilities. |
| Bootstrap vs DSL coupling | Keeping multi-shell under `filename-dsl/` parent psychologically blocks W1 — lift W1 even if files temporarily duplicate paths lists. |
| Generated caches | Renames and bootstrap work must `make cc` / reinit; never hand-edit `data/asc/*` as SoT. |

**Safety:** plan-only for inbox organization until accepted + reorg explicitly requested. July domain plans remain plan-only for their implementations until those plans are accepted and go-ahead is given.

---

## Appendix A — Current top-level inventory (2026/07/27)

For reviewers mapping old → new (excluding `foobar` specimen internals):

```text
f-e-naming-convention.yml
  1-phase-0-decisions.yml
  2-rename-u-to-f-and-hookms.yml      → split (W3 surfaces + hookms-only)
  3-option-storage-p-to-o.yml
  4-export-e-prefix.yml
  5-convention-traces-docs.yml        → ride with surfaces
  6-verify-and-gates.yml

filename-dsl.yml
  1-resolve-readme-redesign.yml       → W0 decide
  2-phase-0-accept-freeze.yml         → W0 / residual decide
  3-complete-multi-shell-groundwork/  → W1 (lift)
  4-cursor-rules-refresh.yml          → W2
  5-living-docs-pass/                 → W2
  6…10 phase implementation           → W4 (after W0 grammar)

yml-structure.yml
  1-wave-a-git-state-decisions.yml    → W0 decide (optional)
  2-wave-b-include-spine-decisions.yml → W0 decide (optional)
  3-field-prop-and-validation.yml     → W2 doc (after decides)
  4-expand-living-doc.yml             → W2
  5-amend-draft-bodies.yml            → mech after decide

subject-asc-extensions.yml
  1-resolve-readme-conflict.yml       → W0 decide
  2…5                                 → W5 or cancel after decide

readme-rewrite-todo.yml               → demote to index
readme-cross-cutting.yml              → mostly W5-parked
```

---

## Appendix B — Artifact quality checklist (per leaf)

Before marking a change ready to implement:

- [ ] `goal` is one sentence a reviewer can accept/reject.
- [ ] `kind` is obvious from folder or explicit key (decide/doc/mech/runtime/test).
- [ ] `wave` matches true blockers (no W5 work labeled W1).
- [ ] `paths` are mid-grain and sufficient.
- [ ] `why` states ship criteria and names blockers.
- [ ] No duplicate leaf elsewhere in the inbox for the same outcome.
- [ ] Breaking renames: allowlist or surface bound; grep gates described.
- [ ] Docs-only leaves do not invite drive-by refactors in `asc/**/*.sh`.

---

## Appendix C — Queue cheat-sheet (after minimal next cut)

```text
1. W0  decide-dsl-redesign
2. W0  decide-asc-extensions
3. W1  rewire-bootstrap-paths → ASC_SHELL → include-loader → bash smoke
4. W2  doc contracts (parallel)
5. W3  hookms → f_* surfaces → o_* → e_* → gates
6. W4  DSL tests → runtime → hook.yml → explicit actions → verify
7. W5  discovery / fields / builder slices / tests / baseline / agents
   (parked cross-cutting stays parked until unblocked)
```
