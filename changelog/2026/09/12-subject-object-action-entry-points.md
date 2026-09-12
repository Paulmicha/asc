# `$subject` / `$object` / `$action` entry points (heuristic A)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-12 |
| **Status** | proposed (docs only — no code yet) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — discover a third nesting level for **entry points only**. Hooks stay `$subject`-scoped. Not entity YAML merge, not stamp v1.1 nested-file watch, not lazy-opt-inc extraction. |
| **Related** | README § Current status / Active Dir / Actions / Specificity; `f_asc_extend()` / `f_asc_primitive_values()` in `asc/asc/core.inc.sh`; `f_make_list_entry_points()` in `asc/make/make.inc.sh`; `hook()` in `asc/asc/hook.inc.sh`; caller opt-inc in `asc/bootstrap.sh`; builder template `asc/extensions/builder/template/core/[subject]/[object]/`. Prior: [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md). |
| **Lifecycle** | Review this file; implement the waves below. `autoload.inc.sh` is **out of scope** (`p_extra_level_name` is hook **filename** variants, not directories). |

`$` in this file is the ASC docs placeholder (`$subject` / `$object` / `$action`), not a shell variable.

---

## Context

README already specifies two entry-point nestings:

- `$subject` / `$action` → `foobar-baz` → `asc/foobar/baz.sh`
- `$subject` / `$object` / `$action` → `host-dependency-install` → `asc/host/dependency/install.sh`

`$object` dirs are **not** active dirs: they group `$action` scripts only. No hook implementations there (otherwise hook lookup explodes).

Core discovery still lists only `*.sh` files **directly** in each `$subject` folder. Trees that already match the extra level are invisible to primitives / `pivots.mk`:

- `asc/host/dependency/{install,list,status,uninstall,update}.sh`
- `asc/host/registry/{del,get,set}.sh`
- `asc/instance/logged/{batch,chain,loop,pipe,sequence,thread}.sh` (comments already document `make logged-batch` / synonym `lb`)
- `asc/instance/registry/{del,get,set}.sh`

---

## Decisions

### 1. Discovery = heuristic A (picked)

Scan **immediate** subdirs of each `$subject`. A subdir is an `$object` when it contains at least one **valid action** `*.sh` (same rules as today: no leading dot, no double extension).

| Rule | Meaning |
|------|---------|
| Depth cap | Only `$subject/$object/$action.sh`. Not `$object/$nested/$action`. |
| Coexistence | `foobar/baz.sh` **and** `foobar/baz/toto.sh` are both entry points (`foobar-baz`, `foobar-baz-toto`). Same-named `$action.sh` next to `$object/` does **not** exclude the folder. |
| Empty / non-action dirs | Skip. `*.hook.sh`, `*.inc.sh`, `*.opt-inc.sh`, `*.test.sh`, YAML-only dirs (`asc/dir/nested_dir/`) are not objects. |
| Opt-out | Reuse primitive dotfiles: `.asc_objects` / `.asc_objects_ignore` / `.asc_objects_append` in the **subject** folder (same machinery as subjects/actions). |

Rejected: “no sibling `$object.sh`” (would drop `foobar/baz/toto.sh` whenever `foobar/baz.sh` exists). Rejected: opt-in-only `.asc_objects` (fights README’s agnostic stance).

### 2. Canonical pivot name + deeper nesting wins (picked)

`f_make_task_name()` already maps every non-alphanumeric char to `-`. So these are the **same** make target:

| Script | Primitive path | Task |
|--------|----------------|------|
| `foobar/baz_toto.sh` | `foobar/baz_toto` | `foobar-baz-toto` |
| `foobar/baz-toto.sh` | `foobar/baz-toto` | `foobar-baz-toto` |
| `foobar/baz/toto.sh` | `foobar/baz/toto` | `foobar-baz-toto` |

**Pick:** the deeper primitive path wins (more `/` in `subject[/object]/action`). Only the winner is written to `data/asc/pivots.mk` / `data/asc/cache/pivots.sh`.

- Winner: `asc/foobar/baz/toto.sh`
- Loser: still on disk, still in `ASC_ACTIONS`, still callable as `asc/foobar/baz_toto.sh`. Not a make target.

Slash count is measured on the **primitive pair** (`host/registry/get` = 2, `host/registry_get` = 1), not on the full filesystem prefix (`scripts/asc/extend/...`). Genericity collisions at the **same** depth stay as today: prefix the newcomer with the extension name.

Discover **two-level first, then three-level**, so a later deeper path can replace the script for an existing task.

### 3. Hooks stay two-level (already in README)

`hook()` / `hook_ms()` must ignore primitive paths with more than one `/`. Do not look for `asc/host/dependency/install.hook.sh`.

`f_autoload_add_lookup_level` is unchanged.

### 4. Eager includes stay on `$subject`

`ASC_INC` still only adds `$subject/$subject.inc.sh`. Object dirs are not active dirs.

Caller opt-inc in `asc/bootstrap.sh` currently takes `basename(dirname(caller))` as the subject. For `asc/host/dependency/install.sh` that wrongly yields `dependency`. Fix: if the parent folder name is a known subject (any namespace `*_SUBJECTS`), treat that as `$subject` and the current folder as `$object`; seed `$subject/$subject.opt-inc.sh` and colocated `$action.opt-inc.sh` only.

### 5. Optional `ASC_OBJECTS`

Export `${NS}_OBJECTS` as `subject/object` pairs (only objects that actually yielded ≥1 action). Cache it next to `*_SUBJECTS` / `*_ACTIONS` in `data/asc/cache/core/active.sh`. Introspection + tests. Not used by `hook()`.

---

## Files

| File | Change |
|------|--------|
| `asc/asc/core.inc.sh` | `f_asc_extend`: after 2-level actions, `objects` then nested `actions`. Cache `*_OBJECTS`. Docblock. |
| `asc/asc/core.inc.sh` | `f_asc_primitive_values`: `objects` case = `f_fs_dir_list` (same ignore/append/override as subjects). |
| `asc/make/make.inc.sh` | Intra-namespace task collision: deeper `sp_pair` replaces `real_scripts_arr` entry; shallower is skipped. Core loop must check collisions (today it does not). |
| `asc/asc/hook.inc.sh` | `f_hook_build_lookup_by_subject`: `case "$p_path" in */*/*) continue ;; esac` before using `[1]` as `$action`. |
| `asc/bootstrap.sh` | Caller opt-inc: resolve `$subject` vs `$object` from known subjects. |
| `asc/instance/list_actions.sh` | No path-join change (`asc/${a}.sh` already works for three segments). Docs: prints primitive paths, including losers. |
| `asc/test/core/*.test.sh` | Discovery, coexistence, collision, hooks-not-in-object-dirs, bootstrap opt-inc. |
| `asc/extensions/builder/template/core/[subject]/[object]/` | Drop `{subject}.inc.sh` / `{subject}.opt-inc.sh` (contradict README). Keep `[action].sh` (+ optional yml). |
| Per-subject `.asc_objects_ignore` | Opt-out helper trees (see below). |
| README | Status checkbox; Actions / bootstrap opt-inc notes if they drift. |

`asc/asc/autoload.inc.sh`: **no change**.

Stamp v1.1 (nested-file mtimes) stays a follow-up. Adding `$object/$action.sh` inside an **existing** folder still needs `make cc` and `make reinit` for the new Make target — same as today’s `$subject/$action.sh`.

---

## Collision algorithm (`f_make_list_entry_points`)

For each `sp_pair` in `$ASC_ACTIONS` then each extension `*_ACTIONS`:

1. `task=` `f_make_task_name "$sp_pair"`; strip leading `instance-` except `instance-init` / `instance-setup` (unchanged).
2. If `task` is **new** → append `task` + `base/$sp_pair.sh`.
3. If `task` already exists, compare `/` count of the new `sp_pair` vs the existing script’s primitive pair:
   - **new deeper** → replace `real_scripts_arr[i]` (keep `task`).
   - **new shallower or equal** → if this is an extension newcomer, prefix `task` with `$extension-` as today; if this is core vs core, skip the newcomer.

Worked example:

```text
ASC_ACTIONS contains: foobar/baz_toto  foobar/baz/toto

1. foobar/baz_toto  → task foobar-baz-toto  → asc/foobar/baz_toto.sh
2. foobar/baz/toto  → same task, more slashes → replace with asc/foobar/baz/toto.sh

make foobar-baz-toto  →  asc/foobar/baz/toto.sh
asc/foobar/baz_toto.sh remains callable by path
```

`instance/logged/batch` → `instance-logged-batch` → `logged-batch` → synonym `lb` (already in `ASC_SYNONYMS`). `host/registry/get` → `host-registry-get` → `host-reg-get`.

---

## `.asc_objects_ignore` to ship with this change

Heuristic A will otherwise promote helper folders that happen to contain valid `*.sh`:

| Subject | Ignore | Why |
|---------|--------|-----|
| `asc/test` | `test` | `asc/test/test/{in,and,…}.sh` would become `test-test-in`, etc. `core/` has only `*.test.sh` and is skipped anyway. |
| `asc/git` | `gitflow` `samples` | Nested flow / sample hooks. Confirm `acp` (`wrap.sh` is a raw snippet, not a bootstrapped entry point) — ignore `acp` unless we intend `git-acp-wrap`. |
| `asc/doc` | `asc` `fixtures` `fonts` | Assets / fixtures. |
| `asc/extensions/builder` subjects (`template`, `code`, …) | generator subtrees that contain `[action].sh` placeholders | Must not become live pivots. |

Review this table while implementing; the mechanism is the point, the exact lines can be adjusted.

---

## Tests (before / with the core change)

Put cases in `asc/test/core/` (bootstrap or a new `primitives.test.sh` sourced by `test-core`). Use a throwaway subject dir under `asc/` or a dummy extension, then `f_asc_extend` + `f_make_list_entry_points`. Tear down in `oneTimeTearDown` / `tearDown`.

| Case | Setup | Expect |
|------|--------|--------|
| 3-level discover | `$ns/foobar/baz/toto.sh` | `ASC_ACTIONS` contains `foobar/baz/toto`; `ASC_OBJECTS` contains `foobar/baz` |
| Coexistence | `foobar/baz.sh` + `foobar/baz/toto.sh` | Both in `ASC_ACTIONS`; pivots `foobar-baz` **and** `foobar-baz-toto` |
| Deeper wins | `foobar/baz_toto.sh` + `foobar/baz/toto.sh` | One pivot `foobar-baz-toto` → `…/foobar/baz/toto.sh` |
| Double ext | `foobar/baz/x.test.sh` only | Not an object / not an action |
| Depth cap | `foobar/baz/qux/toto.sh` | Not discovered |
| Hooks | 3-level action exists; `hook -a toto -s foobar -t` | No `…/foobar/baz/toto.hook.sh` in matches |
| Ignore | `.asc_objects_ignore` lists `baz` | `foobar/baz/toto.sh` not in `ASC_ACTIONS` |

After implementation, `make reinit` then `make make-list-entry-points` should show `host-dependency-install`, `logged-batch` / `lb`, `host-reg-get`, etc.

---

## Implementation waves

1. **Tests first** for the table above (they fail on current `f_asc_extend`).
2. **`f_asc_primitive_values 'objects'` + `f_asc_extend` loop + cache `*_OBJECTS`.**
3. **`f_make_list_entry_points` deeper-wins** (core + extensions).
4. **`hook()` skip three-segment paths.**
5. **Bootstrap caller opt-inc** subject/object resolution.
6. **Ship `.asc_objects_ignore`** for known helper trees; trim builder `[object]` template.
7. **`make reinit`**, `make test-core`, spot-check `make list-actions` / `make make-list-entry-points`. README status: “only subject/object/action level remains” → done for **core discovery**; leftover is adopting the extra level in more core/extension trees, not the mechanism.

Do not mix this into stamp v1.1 or the lazy-opt-inc extraction plan.

---

## Safety

- Makefile: two recipes with the same target name are invalid; collapsing on task name is required, not optional.
- `make reinit` required after pull so `pivots.mk` gains three-level targets.
- Direct script paths of “losers” keep working; only the make alias moves to the deeper file.
- Hook lookup cache keys unchanged; wipe `data/asc/cache/hook/` via stamp miss or `make cc` after the skip lands so old lookups cannot source a mistaken object-dir hook if one was ever written.

---

## Open tasks

- [ ] Confirm `git/acp` ignore vs `git-acp-wrap` as a real pivot
- [ ] Builder template / generator: emit `$subject/$object/$action.sh` without subject includes in the object dir
- [ ] Stamp v1.1 nested-file invalidation (separate changelog)
- [ ] Remaining core/extension trees that should **move** 2-level `foo_bar.sh` into `foo/bar.sh` (optional cleanup; not required for the mechanism)
