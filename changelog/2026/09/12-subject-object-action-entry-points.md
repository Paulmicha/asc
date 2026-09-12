# `$subject` / `$object` / `$action` entry points (heuristic A)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-12 |
| **Status** | proposed (docs only — no code yet). Review pass folded in (opt-inc, hook probe, deeper-wins scope, pivot arrays, ignores, tests). |
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
- `asc/instance/logged/{batch,chain,loop,pipe,sequence,thread}.sh` (script comments: `make lb`)
- `asc/instance/registry/{del,get,set}.sh` (script comments: `make reg-get`)

---

## Decisions

### 1. Discovery = heuristic A (picked)

Scan **immediate** subdirs of each `$subject`. A subdir is an `$object` when it contains at least one **valid action** `*.sh` (same rules as today: no leading dot, no double extension).

| Rule | Meaning |
|------|---------|
| Depth cap | Only `$subject/$object/$action.sh`. Not `$object/$nested/$action`. |
| Coexistence | `foobar/baz.sh` **and** `foobar/baz/toto.sh` are both entry points (`foobar-baz`, `foobar-baz-toto`). Same-named `$action.sh` next to `$object/` does **not** exclude the folder. |
| Empty / non-action dirs | Skip. `*.hook.sh`, `*.inc.sh`, `*.opt-inc.sh`, `*.test.sh`, YAML-only dirs (`asc/dir/nested_dir/`) are not objects. Do not export empty objects even if `.asc_objects` lists them. |
| Opt-out | Reuse primitive dotfiles: `.asc_objects` / `.asc_objects_ignore` / `.asc_objects_append` in the **subject** folder (same machinery as subjects/actions). Object-dir `.asc_actions*` applies when listing actions **inside** that object (same as today per path). |

Rejected: “no sibling `$object.sh`” (would drop `foobar/baz/toto.sh` whenever `foobar/baz.sh` exists). Rejected: opt-in-only `.asc_objects` (fights README’s agnostic stance).

### 2. Canonical pivot name + deeper nesting wins **inside one namespace** (picked)

`f_make_task_name()` already maps every non-alphanumeric char to `-`. So these are the **same** make target:

| Script | Primitive path | Task |
|--------|----------------|------|
| `foobar/baz_toto.sh` | `foobar/baz_toto` | `foobar-baz-toto` |
| `foobar/baz-toto.sh` | `foobar/baz-toto` | `foobar-baz-toto` |
| `foobar/baz/toto.sh` | `foobar/baz/toto` | `foobar-baz-toto` |

**Pick:** the deeper primitive path wins (more `/` in `subject[/object]/action`). Only the winner is written to `data/asc/pivots.mk` / `data/asc/cache/pivots.sh`.

- Winner: `asc/foobar/baz/toto.sh`
- Loser: still on disk, still in `ASC_ACTIONS`, still callable as `asc/foobar/baz_toto.sh`. Not a make target. Wrap helpers (`log.wrap.sh`, `thread.wrap.sh`) whitelist **make** targets / winner paths only — wrapping a loser by filesystem path is out of scope.

Slash count is measured on the **primitive pair** (`host/registry/get` = 2, `host/registry_get` = 1), not on the full filesystem prefix (`scripts/asc/extend/...`). Counting slashes on the real path would make every contrib/extend file look “deeper”.

**Namespace scope:** deeper-wins runs **only among pairs from the same namespace** (core vs core, or the same extension). Across namespaces, keep today’s rule: if the canonical `task` already exists, prefix the newcomer with `$extension-`. Do **not** let `scripts/asc/extend/host/registry/get.sh` steal core’s `host-reg-get`.

Do **not** implement README “bottom of the genericity list wins the same make name” in this change. That would replace at equal depth too. Code today prefixes. This plan stays prefix-across-namespaces.

Discover **two-level first, then three-level** *inside that namespace*, so a later deeper path can replace the script for an existing task.

Equal-depth twins in the same namespace (`baz_toto` vs `baz-toto`): first listing order keeps the target; skip the newcomer. Untested today; add a test.

### 3. Hooks stay two-level (already in README)

`hook()` / `hook_ms()` must ignore primitive paths with more than one `/`. Do not look for `asc/host/dependency/install.hook.sh`. Without that skip, unfiltered `ASC_ACTIONS` (`hook -e …`, `hook -v …`, `asc/instance/hook.make.sh`) would split `host/dependency/install` as `$action=dependency` and emit bogus `asc/host/dependency.hook.sh`.

`hook -a toto -s foobar` **never walks 3-level paths**: `-a` rewrites the actions list to `$s/$arg_val` only. A dry-run with `-a` does **not** prove the skip. Test unfiltered (`-e` and/or `-v`, no `-a`) with a 3-level pair in that namespace.

`f_autoload_add_lookup_level` is unchanged.

### 4. Eager includes stay on `$subject`; opt-inc must not use “parent ∈ `*_SUBJECTS`”

`ASC_INC` still only adds `$subject/$subject.inc.sh`. Object dirs are not active dirs.

Caller opt-inc in `asc/bootstrap.sh` currently takes `basename(dirname(caller))` as the subject. For `asc/host/dependency/install.sh` that wrongly yields `dependency`.

**Rejected fix:** “if the parent folder name is in `*_SUBJECTS`, treat it as `$subject`.” `asc` **is** a subject (`asc/asc/`). That rule would fire for every core 2-level script (`asc/host/provision.sh` → parent `asc`) and seed `asc/asc/asc.opt-inc.sh` instead of `asc/host/host.opt-inc.sh`. Same trap for `asc/test/core/*.test.sh` (parent `test` is a subject; `core/` is **not** an object — only `*.test.sh`).

**Picked fix:** classify the caller from discovered primitives:

1. If `dirname(caller)` matches a known `$subject/$object` in that namespace’s `*_OBJECTS` (or a 3-segment path in `*_ACTIONS`), it is a 3-level caller: seed `$subject_dir/$subject.opt-inc.sh` and colocated `$action.opt-inc.sh`.
2. Else keep today’s basename rule (2-level).

`call_wrap.make.sh` is fine: it bootstraps as `make`, then the action script bootstraps again (`ASC_BS_FLAG` skips the heavy path; caller opt-inc still runs for the action). Contrib / `scripts/asc/extend` 2-level parents are the extension name, not `asc`.

Do not treat “current folder name ∈ `*_SUBJECTS`” as object-ness (`…/host/instance/foo.sh` would mis-classify).

### 5. Optional `ASC_OBJECTS`

Export `${NS}_OBJECTS` as `subject/object` pairs (only objects that actually yielded ≥1 action). Cache it next to `*_SUBJECTS` / `*_ACTIONS` in `data/asc/cache/core/active.sh`. Introspection + tests. Not used by `hook()`.

### 6. Synonyms run **inside** `f_make_task_name`, **then** `instance-` is stripped

Do not invent `host-dependency → dep` — that comment in `f_make_task_name` is **not** in `ASC_SYNONYMS`.

Day-one names after this change:

| Primitive | After sanitize | After synonyms | After `instance-` strip | Make target |
|-----------|----------------|----------------|-------------------------|-------------|
| `instance/logged/batch` | `instance-logged-batch` | `instance-lb` | `lb` | `lb` |
| `instance/registry/get` | `instance-registry-get` | `instance-reg-get` | `reg-get` | `reg-get` |
| `host/registry/get` | `host-registry-get` | `host-reg-get` | (n/a) | `host-reg-get` |
| `host/dependency/install` | `host-dependency-install` | unchanged | (n/a) | `host-dependency-install` |

---

## Files

| File | Change |
|------|--------|
| `asc/asc/core.inc.sh` | `f_asc_extend`: after 2-level actions, `objects` then nested `actions`. Cache `*_OBJECTS`. Docblock. |
| `asc/asc/core.inc.sh` | `f_asc_primitive_values`: `objects` case = `f_fs_dir_list` (same ignore/append/override as subjects). |
| `asc/make/make.inc.sh` | Same-namespace deeper-wins: find index `i` of `task` in `pivots_arr`, **overwrite** `real_scripts_arr[i]`. Do **not** `+=` and do **not** `f_array_add_once` on replace (that cannot drop the shallower path; `pivots_arr` / `real_scripts_arr` must stay same length and order). Core loop must collide-check (today it does not). Across namespaces: prefix as today. |
| `asc/asc/hook.inc.sh` | `f_hook_build_lookup_by_subject`: `case "$p_path" in */*/*) continue ;; esac` before using `[1]` as `$action`. Required for unfiltered hook calls. |
| `asc/bootstrap.sh` | Caller opt-inc: 3-level only when caller dir matches discovered `$subject/$object`; else today’s basename rule. |
| `asc/instance/list_actions.sh` | No path-join change (`asc/${a}.sh` already works for three segments). Docs: prints primitive paths, including losers. |
| `asc/test/core/primitives.test.sh` (or equivalent) | Dummy **extension** + explicit namespace (`f_asc_extend "$ext_path" 'NFT…'`), not a throwaway `asc/foobar/` (that becomes a real core subject and appends `asc_primitives_cache_str`). `rm -rf` in `oneTimeTearDown`. File in `asc/test/core/` is enough — `core.hook.sh` already runs `*.test.sh` there. |
| `asc/extensions/builder/template/core/[subject]/[object]/` | Drop `{subject}.inc.sh` / `{subject}.opt-inc.sh` (contradict README). Keep `[action].sh` (+ optional yml). |
| `asc/extensions/builder/code/.asc_objects_ignore` | Ignore `var` and `function` (live `*.sh`, would become `code-var-is` / `code-function-is`). |
| README | Mechanism-only: do not tick “only subject/object/action level remains” (that is the whole core/extension refactor). |

`asc/asc/autoload.inc.sh`: **no change**.

Stamp v1.1 stays a follow-up. `reinit.sh` already runs `cache_clear.sh` first, so **`make reinit` is enough** for new Make targets. Do not add a redundant `make cc` ritual.

`f_test_batch_dir_from_script`: `asc/host/dependency/install.sh` would look for `asc/host/dependency/install/` as a per-case dir. Harmless if those dirs do not exist; no extra work in this change.

---

## Collision algorithm (`f_make_list_entry_points`)

Process **one namespace at a time** (core `ASC_ACTIONS`, then each extension’s `*_ACTIONS`). Inside a namespace, 2-level pairs then 3-level pairs.

For each `sp_pair`:

1. `task=` `f_make_task_name "$sp_pair"` (sanitize **then** `ASC_SYNONYMS`). Then strip leading `instance-` except `instance-init` / `instance-setup` (unchanged).
2. If `task` is **new** in `pivots_arr` → `pivots_arr+=` and `real_scripts_arr+=` the same index (`base/$sp_pair.sh`).
3. If `task` already exists:
   - **Same namespace** and new `sp_pair` has more `/` than the stored primitive pair → set `real_scripts_arr[i]=` the deeper script. Keep `task`. Do not append.
   - **Same namespace** and new is shallower or equal `/` → skip newcomer.
   - **Different namespace** → prefix `task` with `$extension-` as today (`f_make_task_name` again after prefix). Never replace by slash count across namespaces.

Find `i` by looping `"${!pivots_arr[@]}"`. `f_in_array` does not return an index.

Worked example (core only):

```text
ASC_ACTIONS contains: foobar/baz_toto  foobar/baz/toto

1. foobar/baz_toto  → task foobar-baz-toto  → asc/foobar/baz_toto.sh
2. foobar/baz/toto  → same task, more slashes → real_scripts_arr[i]=asc/foobar/baz/toto.sh

make foobar-baz-toto  →  asc/foobar/baz/toto.sh
asc/foobar/baz_toto.sh remains callable by path
```

Existing extension TODO (`pivots_arr+=` vs `f_array_add_once` on scripts) already desyncs the arrays. Deeper-wins must not reuse `f_array_add_once` for the replace path. Prefer fixing that zip (always `+=` both, or replace both at `i`) in the same function while touching it.

---

## `.asc_objects_ignore` to ship with this change

Heuristic A promotes **immediate** subdirs that contain valid `*.sh`. On this tree, the only enabled-extension surprise is builder `code`:

| Path | Ignore | Why |
|------|--------|-----|
| `asc/extensions/builder/code` | `var` `function` | `var/{is,used_by,sidecar}.sh` and `function/{is,used_by,sidecar}.sh` would become live `code-var-is` / `code-function-is` (builder is **not** in `.asc_extensions_ignore`). |

Do **not** ship no-op ignores for trees that heuristic A already skips:

- `asc/test/core/` — only `*.test.sh`
- `asc/test/test/` — **does not exist**; helpers are 2-level `asc/test/in.sh`, etc.
- `asc/git/samples/` — only `pre-commit.hook.sh`
- `asc/extensions/builder/template/core/` — no immediate valid `*.sh` in `core/` (placeholders are deeper)

---

## Tests (before / with the core change)

Use a dummy **extension** directory + namespaced `f_asc_extend`, not `asc/foobar/`. Default `f_asc_extend` zeros core primitives, walks every extension, and appends cache strings (`hook.test.sh` / `global.test.sh` already do this for other reasons — do not add another core subject).

| Case | Setup | Expect |
|------|--------|--------|
| 3-level discover | `$ext/foobar/baz/toto.sh` | `*_ACTIONS` contains `foobar/baz/toto`; `*_OBJECTS` contains `foobar/baz` |
| Coexistence | `foobar/baz.sh` + `foobar/baz/toto.sh` | Both in `*_ACTIONS`; pivots `foobar-baz` **and** `foobar-baz-toto` |
| Deeper wins | `foobar/baz_toto.sh` + `foobar/baz/toto.sh` | One pivot `foobar-baz-toto` → `…/foobar/baz/toto.sh`; `pivots_arr` length equals `real_scripts_arr` |
| Equal-depth twins | `foobar/baz_toto.sh` + `foobar/baz-toto.sh` | One pivot; first listing order wins |
| Cross-namespace | core `foobar/baz/toto.sh` and extend `foobar/baz/toto.sh` | Unprefixed task keeps core script; extend is prefixed |
| Double ext | `foobar/baz/x.test.sh` only | Not an object / not an action |
| Depth cap | `foobar/baz/qux/toto.sh` | Not discovered |
| Hooks (unfiltered) | 3-level action in dummy ext; `hook -e '$ext' -v INSTANCE_TYPE -t` (no `-a`) | No `$object` / 3-segment hook path in matches |
| 2-level opt-inc | dummy `$subject/$action.sh` | Still seeds `$subject/$subject.opt-inc.sh` (not parent `asc`) |
| 3-level opt-inc | dummy `$subject/$object/$action.sh` | Seeds `$subject/$subject.opt-inc.sh` from the **subject** dir + colocated `$action.opt-inc.sh` |
| Ignore | `.asc_objects_ignore` lists `baz` | `foobar/baz/toto.sh` not in `*_ACTIONS` |

After implementation, `make reinit` then `make make-list-entry-points` must print **`lb`**, **`reg-get`**, **`host-reg-get`**, **`host-dependency-install`** (not `logged-batch` as the primary name).

---

## Implementation waves

1. **Tests first** for the table above (they fail on current `f_asc_extend` / bootstrap / hook).
2. **`f_asc_primitive_values 'objects'` + `f_asc_extend` loop + cache `*_OBJECTS`.**
3. **`f_make_list_entry_points` same-namespace deeper-wins** + keep arrays zipped.
4. **`hook()` skip three-segment paths** (unfiltered path).
5. **Bootstrap caller opt-inc** via discovered `*_OBJECTS` / 3-segment `*_ACTIONS`.
6. **Ship `builder/code/.asc_objects_ignore`**; trim builder `[object]` template.
7. **`make reinit`**, `make test-core`, spot-check `make list-actions` / `make make-list-entry-points`. README: document the extra level as implemented in **discovery**; do not close the “refactor core + core extensions” checkbox.

Do not mix this into stamp v1.1 or the lazy-opt-inc extraction plan.

---

## Safety

- Makefile: two recipes with the same target name are invalid; collapsing on task name is required, not optional.
- `make reinit` required after pull so `pivots.mk` gains three-level targets (`reinit` already clears lookup cache).
- Direct script paths of “losers” keep working; only the make alias moves to the deeper file.
- Hook lookup cache keys unchanged; stamp miss / `reinit` wipes `data/asc/cache/hook/` so old lookups cannot source a mistaken object-dir hook if one was ever written.

---

## Open tasks

- [ ] Builder template / generator: emit `$subject/$object/$action.sh` without subject includes in the object dir
- [ ] Stamp v1.1 nested-file invalidation (separate changelog)
- [ ] Remaining core/extension trees that should **move** 2-level `foo_bar.sh` into `foo/bar.sh` (optional cleanup; not required for the mechanism)
- [ ] README “most-specific namespace wins the same make name” vs today’s prefix behavior (separate decision; do not hybridize here)
