# Bootstrap cache layout, `make cc` semantics, and stamp invalidation

| Field | Value |
|-------|--------|
| **Date** | 2026-09-11 |
| **Status** | proposed (docs only — no code yet) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — bootstrap, lookup cache, `make cc` / `make reinit` / `make uninit`. Not entity YAML merge, not bash-yaml swap. |
| **Related** | `asc/bootstrap.sh`; `asc/asc/cache_clear.sh`; `asc/asc/hook.inc.sh` (`hook()` cache); `asc/instance/write_globals.sh`; `asc/make/make.inc.sh` (`f_make_generate`); README § Data dirs / instance init; `changelog/2026/09/10-begin-entity-system-with-remote-instances.md` (`data/asc/cache/entities/`); **follow-up (do not mix in):** [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) |
| **Constraint (decided)** | **`make cc` stays “wipe lookup only”.** `data/asc/global.vars.sh` and `data/asc/generated.mk` stay where they are and are **not** deleted by `cc`. |
| **Lifecycle** | Review this file; implement the **picked** slice only. Do not treat this as permission for a cache-tree rewrite plus concatenated bootstrap blob. Shrinking what bootstrap **parses** (`*.opt-inc.sh`, entry-point extraction) is the **follow-up plan**, not this one. |

---

## Context

Warm bootstrap already skips `f_asc_extend` when `data/asc/cache/asc.sh` exists, and skips hook **lookup** when `data/asc/cache/hook.*.sh` exists. It still always:

1. Sources the six core includes (`core_utils`, `core`, `global`, `hook`, `autoload`, `yml`).
2. Sources `data/asc/global.vars.sh` if present.
3. Sources primitives cache (`asc.sh`) or rebuilds via `f_asc_extend`.
4. Runs `hook` `pre_bootstrap` / `alias` / `bootstrap` (lookup cached; **bodies still run**).
5. Sources every path in `ASC_INC`.

`make cc` (`asc/asc/cache_clear.sh`) is `rm -rf data/asc/cache`. It does **not** touch globals or `generated.mk`. `make uninit` / setup purge those separately. Cache is **existence-only**: add an extension, action, or ignore line and nothing rebuilds until a human runs `cc`.

That stale-cache hole is the real performance/correctness gap. Renaming files without a stamp is cosmetics.

Hook cache files today look like `hook._s_asc_a_bootstrap_v_v1_asc.sh` — flattened `"$@"` after variant-value substitution and `f_str_sanitize_var_name`. Debug (`-d`) is part of the raw argv key, so debug vs normal duplicates entries.

---

## Confirmed: `make cc` = lookup only

**Decision:** `cc` deletes disposable **discovery / lookup** artifacts under `data/asc/cache/`. It must **not** delete:

- `data/asc/global.vars.sh` (instance env, sourced every bootstrap)
- `data/asc/generated.mk` (Make include, `-include` from root `Makefile`)
- `.env`

| | Pros | Cons |
|---|---|---|
| **Keep cc = lookup only (picked)** | Next `make $subject-$action` still has targets and env. Matches today’s `cache_clear.sh` vs `uninit.sh` split. Agents can `cc` after adding a hook without a full reinit. | Humans must still `reinit` when **entry points or globals** change. Two wipe commands to remember. |
| **cc wipes everything generated** (rejected) | One “reset generated state” button. | `make cc` then `make test-core` has no instance targets until reinit. Easy to strand a tree. Mixes lookup cache with instance state. |

**Implication:** `global.vars.sh` and `generated.mk` **do not** move under `data/asc/cache/core/`. If they lived there, today’s `rm -rf data/asc/cache` would violate this constraint unless `cache_clear.sh` grew a fragile allowlist.

---

## Target layout (after implementation)

```text
data/asc/
  global.vars.sh              ← unchanged (instance state; reinit/uninit)
  generated.mk                ← unchanged (Make include; reinit/uninit)
  cache/
    core/
      active.sh               ← today: cache/asc.sh (primitives + ASC_INC list)
      stamp                   ← NEW (see “Best performance win”)
    hook/                     ← today: cache/hook.*.sh (flat in cache/)
      <canonical-key>.sh
    make.sh                   ← unchanged role (cc wipes; regenerated at init)
    test-cases.sh             ← unchanged role
    entities/                 ← entity load cache (cc already wipes this)
    …                         ← other lookup caches (remote ids, etc.)
```

`make cc` remains `rm -rf data/asc/cache` (or equivalent: wipe `core/`, `hook/`, `entities/`, `make.sh`, …). Globals and pivots stay.

---

## Decisions

Each subsection: options, pros/cons, **pick**. Lightest option that still fixes the problem wins.

### 1. Two bootstrap paths (bare vs warm)

Already half-true (`global.vars.sh` optional; `asc.sh` miss → `f_asc_extend`). Make the split explicit in `bootstrap.sh`, **not** a second entry file.

| Option | Pros | Cons |
|---|---|---|
| **A — One `bootstrap.sh`, two branches (picked)** | No new include graph. Cold: core includes + `f_asc_extend`, skip alias/bootstrap hooks that need `INSTANCE_TYPE` if globals missing. Warm: source `active.sh` + globals + existing three hooks. | Must list which hooks run on bare (init still needs *some* bootstrap). Easy to get wrong if a hook is required for `make init`. |
| **B — `bootstrap.bare.sh` + `bootstrap.warm.sh`** | Clear files. | Two sources of truth; every caller still `. asc/bootstrap.sh`; more to keep in sync. |
| **C — Concatenate core `*.inc.sh` + primitives into one `active.sh` blob** | Fewer `source` parses on warm path. | Editing `hook.inc.sh` does nothing until `cc`. Hostile to ASC development. Blob size grows with every function. **Rejected** (not lightweight in *maintenance*). |

**Pick A.** Bare vs warm is an `if [[ -f cache/core/active.sh ]]` (plus stamp — §3). Do not skip sourcing the six core includes on warm: they are small; skipping them requires the blob.

Cold path must remain enough to run `make init` (core utils, `f_asc_extend`, hook lookup without instance variants if needed).

### 2. Where primitives live (`asc.sh` → `core/active.sh`)

| Option | Pros | Cons |
|---|---|---|
| **A — `data/asc/cache/core/active.sh` (picked)** | Groups “core lookup” next to planned `cache/entities/`. Name says “this instance’s active primitives”. | Path churn: bootstrap, tests, docs, `make cc` messages. |
| **B — Keep `data/asc/cache/asc.sh`** | Zero rename cost. | Opaque; `cache/` root stays a junk drawer. |
| **C — Also move `generated.mk` → `cache/core/pivots.mk` and globals → `cache/core/global.vars.sh`** | One “generated” tree. | **Conflicts with cc = lookup only** unless clear is rewritten with exceptions. Makefile `-include` path change. **Rejected.** |

**Pick A** only. Makefile keep `-include data/asc/generated.mk`. Bootstrap keep `. data/asc/global.vars.sh`.

### 3. Best performance win: discovery stamp (picked to implement first)

**This is the performance/correctness win.** Existence-only cache is why people run `cc` “just in case” and why new hooks/extensions are invisible.

**What the stamp is for:** decide whether `active.sh` and the **hook lookup** tree are still valid. Not whether hook *file contents* changed (a cache hit still `. "$src"`; edits apply). Not whether `env.yml` changed (that is reinit / globals).

**Stamp file:** `data/asc/cache/core/stamp` (one line or a few: checksum or `mtime` tuple).

**Inputs (discovery only, not file bodies):**

- ignore files: `.asc_subjects_ignore`, `.asc_extensions_ignore`, override copies under `scripts/asc/override/`
- directory mtimes of `asc/extensions`, `scripts/asc/contrib`, `scripts/asc/extend` (add/remove **children**)
- optional light `find` of `*.inc.sh` / `*.hook.sh` **path + mtime** (names appearing/disappearing), **not** hashing contents

On bootstrap, after core includes:

1. If no `core/active.sh` → cold: `f_asc_extend`, write `active.sh` + stamp, continue.
2. If `active.sh` exists and stamp **matches** → source it (warm).
3. If stamp **mismatches** → `f_asc_extend`, rewrite `active.sh`, **delete `cache/hook/` only** (not globals, not `generated.mk`), rewrite stamp.

| Option | Pros | Cons |
|---|---|---|
| **A — Stamp vs ignore files + top-level extension dir mtimes only (picked v1)** | A handful of `stat`s. Catches enable/disable extension, ignore-list edits, new contrib folder. No `find` on every `make`. | Misses a **new `*.hook.sh` / `*.sh` action inside an existing subject** (parent dir mtime may not change on all FS when a nested file is added). Those still need `cc` or v1.1. |
| **B — A + cheap `find` of hook/inc/action names+mtimes, checksum** | Catches new action/hook files. Still no content hash. | One `find` per bootstrap (~tens of ms on this tree). Heavier than A. **v1.1 if A is too deaf.** |
| **C — Compare every hook cache file mtime to every matching `*.hook.sh`** | Precise. | Can cost as much as a lookup miss. Defeats the cache. **Rejected.** |
| **D — Keep existence-only + document `make cc`** | Zero code. | Status quo; stale cache is the bug we are fixing. **Rejected as the end state.** |

**Pick A for v1** (lightest that fixes the usual “I toggled an extension / ignore file” case). If nested new hooks stay invisible in practice, add **B** (still no content hashing).

Do **not** rebuild `global.vars.sh` or `generated.mk` on stamp mismatch.

### 4. Hook cache path scheme

Today: `data/asc/cache/hook.${sanitized_argv}.sh` with variant **values** substituted into the key (correct: `local` vs `prod` must differ).

| Option | Pros | Cons |
|---|---|---|
| **A — `cache/hook/<canonical-key>.sh` from **parsed** flags, not `"$@"` (picked)** | One builder. Readable enough (`s.asc.a.bootstrap.v.v1.asc.sh`). Drop `-d` from key (debug ≠ different matches). Multi-value join with **`,`** (comma): `-s 'site instance'` → `s.site,instance`. Missing filters omitted. `-t` / `-r` / `-c` stay in the key. No extra `mkdir` per miss beyond `cache/hook/`. Tests glob `cache/hook/*nftaschhnc*`. | Not a directory tree per subject. Long filenames if many variants (same risk as today). Comma is legal on Linux; **always quote** the cache path (`"$hook_cache_file"`) so IFS never splits. |
| **B — Nested `s.$subject/a.$action/v.$variants.sh` plus six layout rules** (original sketch) | Nice to browse by subject. Can `rm -rf hook/s.foo` if that were a single subject. | `-s` is often **several** subjects. Six layouts to keep in sync. `mkdir -p` on every miss. Tests and `cc` partial wipes get messier. **Heavier than A for little lookup gain.** |
| **C — Leave flat `cache/hook.*` names as today** | No path migration. | Opaque; `-d` duplicates; `"$@"` order-sensitive. Stamp (§3) still works. |

**Pick A.** Values stay in the key. Canonical order: `s`, `a`, `p`, `v`, `e`, `c`, then flags `t`/`r`/`w`. Never six different directory shapes. Multi-subject / multi-action / multi-variant lists use **comma** (not `+`).

Example:

```text
data/asc/cache/hook/s.asc.a.bootstrap.v.v1.asc.sh
data/asc/cache/hook/s.site,instance.a.fs_perms_set.p.pre.v.v1.asc.local.dev.sh
data/asc/cache/hook/a.global.c.vars.sh.t.sh
```

### 5. What `cc` deletes vs what init writes

Unchanged policy, restated so layout changes do not silently expand `cc`:

| Artifact | `make cc` | `make reinit` / init | `make uninit` |
|---|---|---|---|
| `cache/core/active.sh`, `cache/core/stamp` | wipe | rewrite | wipe (via cache dir) |
| `cache/hook/` | wipe | refill on next hook miss / warmup | wipe |
| `cache/make.sh`, `cache/test-cases.sh`, `cache/entities/` | wipe | rewrite at init | wipe |
| `data/asc/global.vars.sh` | **keep** | rewrite | wipe |
| `data/asc/generated.mk` | **keep** | rewrite | wipe |
| `.env` | **keep** | rewrite | wipe |

After `cc`, next bootstrap is a **stamp miss** (no `active.sh`): `f_asc_extend` once, then hook lookups refill. Make targets and env remain.

### 6. What not to do (on purpose)

| Idea | Why not (v1) |
|---|---|
| Concatenate six core includes into `active.sh` | Maintenance cost &gt; parse savings. |
| `find` + content hash of every hook on each bootstrap | Cache becomes a slower miss. |
| Move globals / `generated.mk` into `cache/core/` | Breaks cc = lookup only. |
| Second bootstrap script | Duplicate graph. |
| Per-hook nested dirs for every flag combination | Complexity without faster hits. |
| Rebuild pivots.mk when stamp mismatches | Wrong artifact; needs `f_make_generate` + full instance. That is reinit. |
| Split kernel / `ASC_INC` into `*.opt-inc.sh`, or move one-shot `f_*` into `$subject/$action.sh` | Parse-cost work. **Follow-up:** [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md). Alias / `pre_bootstrap` / `bootstrap` still run on warm path; mixing that into stamp is how those hooks break without a lookup miss. |

---

## Out of scope here (follow-up plan)

This plan does **not** change which functions exist after `. asc/bootstrap.sh`. Warm path still sources the six kernel files and every `ASC_INC` path (~9k lines).

Lazy `*.opt-inc.sh` (caller phase 90 + hook-seeded colocated files), demoting fat utils / `ASC_INC` subjects, and continuing the 2026-09-11 “keep vs dedicated entry point vs drop” drill across leftover core + extensions: **[11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md)**. Implement that **after** stamp + `core/active.sh` + hook keys.

---

## Recommended implementation order (minimal)

Do **not** ship layout + stamp + hook-key rewrite as one ball of mud if a smaller slice lands the win.

1. **Stamp + rebuild primitives + wipe `cache/hook*` on mismatch** (paths can stay `asc.sh` / `hook.*` for this step). This is the **best performance/correctness win**.
2. Rename `asc.sh` → `cache/core/active.sh`; send hook files to `cache/hook/`. Update bootstrap, tests, docs.
3. Canonical hook key from parsed flags; drop `-d` from the key.
4. Document bare vs warm in `bootstrap.sh` comments (same file, two branches). Skip alias/bootstrap hooks on bare only if init still works — verify with `make uninit` then `make init`.

v1.1 only if needed: stamp input **B** (`find` names+mtimes of `*.hook.sh` / `*.inc.sh` / action `*.sh`).

---

## Tests (when implementing)

- Stamp match: do not call `f_asc_extend` (spy: `active.sh` mtime unchanged; or a counter).
- Ignore-file touch: next bootstrap rewrites `active.sh`, hook lookup dir empty or regenerated.
- `make cc`: `global.vars.sh` and `generated.mk` still present; `cache/` gone; next bootstrap recreates `core/active.sh`.
- Hook cache: same `-s/-a/-v` with and without `-d` share one file (after step 3).
- Existing `asc/test/core/hook.test.sh` / `global.test.sh`: update globs (`cache/hook/*nftaschhnc*` vs `cache/hook.*nftaschhnc*`).

---

## Open tasks

- [ ] Implement stamp v1 (decision 3A) against current paths or against `core/active.sh` if rename is done in the same change.
- [ ] Rename primitives cache + hook dir (decisions 2A, 4A).
- [ ] Canonical hook key; exclude `-d`.
- [ ] Bare-path hook skip: confirm `make init` from uninit does not need `alias` / `bootstrap` with empty variants.
- [ ] README `#### ASC cache` (currently TODO): document cc vs reinit vs this layout.
- [ ] v1.1 find-based stamp if nested new hooks stay stale.
- [ ] After this lands: [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) (opt-inc / `ASC_INC` shrink / entry-point sweep). Do not start it in the stamp change.

---

## Summary pick

| Topic | Pick |
|---|---|
| `make cc` | Lookup only (`data/asc/cache/`). Globals + `generated.mk` stay. |
| Best performance win | **Discovery stamp** (ignore files + extension dir mtimes). Mismatch → `f_asc_extend` + wipe hook lookup only. |
| Layout | `cache/core/active.sh` + `cache/hook/<canonical-key>.sh`. No nested six-layout tree. No globals/mk under `cache/`. |
| Bootstrap | One file, bare vs warm branches. No concatenated lib blob. |
| Weight | Stamp first; rename second; fancy hook directories never (v1). |
| Not this PR | Lazy `*.opt-inc.sh` / moving leftover `f_*` into entry points — see follow-up plan. |
