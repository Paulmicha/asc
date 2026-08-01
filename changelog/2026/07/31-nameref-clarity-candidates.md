# Inventory: Bash nameref clarity candidates (`declare -n` / `local -n`)

| Field | Value |
|-------|--------|
| **Date** | 2026-07-31 |
| **Status** | inventory / plan (docs only — no code changes) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — shell scripts only: `*.sh`, `*.inc.sh`, `*.opt-inc.sh` (excluding `asc/vendor/` and other third-party trees). **Out of scope:** capitalized (`ALL_CAPS`) / `readonly` globals (e.g. `GLOBALS*` family stays as-is). |
| **Related** | `changelog/2026/07/31-array-dict-naming-plan.md`; `changelog/2026/07/31-subshell-printf-v-candidates.md`; `asc/asc/hook.inc.sh` (`a_out_arr_nameref` model) |
| **Lifecycle** | Review inventory; migrate in focused PRs. Do **not** treat this file as permission for a repo-wide mechanical rewrite. |

---

## Context

ASC already uses Bash 4.3+ namerefs in six places (four files) for array aliasing — most notably `a_out_arr_nameref` in `f_hook_opt_inc_append_candidates()`, which is the naming model for typed array namerefs. Elsewhere, the same problems are solved with **`${!var}` indirect expansion**, **`eval` into a dynamically named variable**, or **`printf -v "$var_name"`** output parameters.

This plan inventories where **namerefs would be clearer** than those patterns — not every `printf -v` (many are already fine; see the subshell/`printf -v` plan).

### When namerefs help

| Situation | Why nameref |
|-----------|-------------|
| Function takes **variable name as string**, then reads/writes that variable or array **multiple times** | `local -n target_nameref="$1"` replaces `${!name}`, `eval`, and repeated `printf -v` |
| Append / mutate caller's **indexed or associative array** in place | `haystack_arr_nameref+=("item")` vs `eval "$name+=(...)"` |
| Iterate keys/values of caller's array passed by name | `${!__p[@]}` on nameref vs `local arr=${1}[@]; ${!arr}` |
| Polymorphic array helper (indexed **or** associative) | One nameref param; `${!ref[@]}` works for both |

### When namerefs do **not** help (leave alone or use other tools)

| Situation | Prefer |
|-----------|--------|
| **Single scalar write** to caller scope | `printf -v "$a_output_var_name"` — already idiomatic; no clarity win from nameref |
| **Computed variable name at runtime** with no repeated access | One-shot `${!name}` or `printf -v` is fine |
| **`eval` of shell commands** (git, hook dispatch, make wrap) | Not variable indirection — keep `eval` or refactor command API separately |
| **`f_yaml_parse` / bash-yaml** — emits many `declare` lines | Needs associative-array or structured return API, not a single nameref |
| **`read -p … $dynamic_var`** / **`unset $dynamic_var`** | Bash requires `eval` for the target name in `read`/`unset` |
| **`ALL_CAPS` / `GLOBALS*` runtime globals** | Excluded from rename **and** from nameref suffix proposals |
| **Bash version floor** | Namerefs require Bash ≥ 4.3 (already assumed in `hook.inc.sh` comment) |

### `printf -v` vs nameref (coexist)

Both patterns avoid subshells. Use this rule of thumb:

| Pattern | Use when |
|---------|----------|
| `printf -v "$var_name" …` | One (or two) scalar writes; output param documented in `@param` |
| `local -n ref="$var_name"` | Multiple reads/writes; array append; in-place mutation; loop over keys |

A function may combine both: e.g. nameref for reading an input array, `printf -v` for a separate scalar status flag. See `f_thread_args_append()` — nameref for array slot, `printf -v enc` for a local temp (correct split).

Cross-reference: `changelog/2026/07/31-subshell-printf-v-candidates.md` for echo/`$(f_* …)` → `printf -v` work (orthogonal to namerefs).

---

## Naming convention (nameref locals)

From `changelog/2026/07/31-array-dict-naming-plan.md`:

| Kind | Suffix | Example |
|------|--------|---------|
| Nameref (any target) | `_nameref` | `__p` → `__p_nameref` |
| Nameref → indexed array | `_arr_nameref` | `_u_ta_ref` → `_u_ta_ref_arr_nameref` |
| Nameref → associative array | `_dict_nameref` | `__yaml_scalars` → `__yaml_scalars_dict_nameref` |

**Rules:**

- **String parameters** that hold another variable's *name* (`haystack_var_name`, `a_scalars_name`, …) stay scalars — no `_nameref` on the param.
- **Nameref locals** inside the callee always get `_nameref` (or double suffix when target type is known).
- Double suffix only for typed namerefs: `*_arr_nameref`, `*_dict_nameref`.

---

## Methodology

Audited `*.sh`, `*.inc.sh`, `*.opt-inc.sh` under the repo, excluding `asc/vendor/`. Signals:

1. Existing `declare -n` / `local -n`
2. `${!var}` scalar indirect expansion (excluding `${!arr[@]}` key iteration on known locals)
3. `eval "${var_name}=…"` / `eval "$var_name+=…"` array/scalar writes
4. `local arr=${n}[@]` + `${!arr}` array-by-name iteration
5. Functions documented with `@param … variable name` + `printf -v` / `${!}` / `eval`
6. Cross-checked against array-dict plan nameref inventory and subshell plan output-var list

---

## Summary

| Category | Count | Migration fit |
|----------|-------|-----------------|
| **Already using nameref** | 6 sites / 5 symbols (+ loop re-declare) | 1 compliant suffix; 5 need rename per array-dict plan |
| **A — eval / array-by-name utilities** | 5 functions / 8 `eval` write lines / ~40 call sites | **Excellent** — drop `eval`, typed nameref API |
| **B — array helper API evolution** | 3 functions (`f_array_qsort`, `f_array_reverse`, `f_array_ksort`) | **Good** — optional nameref params vs value expansion |
| **C — mixed `${!}` read + `printf -v` write** | 6 functions | **Mixed** — nameref helps read side or in-place update |
| **D — loop `${!var}` → `local -n` in body** | ~76 live scalar indirect sites / 23 files | **Good** in hot loops; skip one-shot reads |
| **E — poor fit / leave alone** | ~35 `eval` sites (commands, yaml, read/unset) | **Do not migrate** to nameref |
| **`printf -v` indirect writes** | 27 sites / 12 files | **Reference** — mostly fine as-is |

---

## Already using nameref (reference)

All `declare -n` / `local -n` sites (excluding vendor). **OK:** ✓ compliant suffix, ✗ needs rename.

| Variable | File | Function | Line | Target | Suggested rename | Notes |
|----------|------|----------|------|--------|------------------|-------|
| `a_out_arr_nameref` | `asc/asc/hook.inc.sh` | `f_hook_opt_inc_append_candidates` | L816 | indexed array (`$2`) | — | ✓ Model for `*_arr_nameref` output |
| `__p` | `asc/utils/arr/arr.opt-inc.sh` | `f_array_print` | L202 | polymorphic array (`$1`) | `__p_nameref` | ✗ `${!__p[@]}` debug printer |
| `__yaml_scalars` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L263 | associative (`$a_scalars_name`) | `__yaml_scalars_dict_nameref` | ✗ |
| `__yaml_keys` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L264 | indexed (`$a_keys_name`) | `__yaml_keys_arr_nameref` | ✗ |
| `__yaml_list` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L281 | indexed (varargs list name) | `__yaml_list_arr_nameref` | ✗ Re-declared per list section in loop |
| `_u_ta_ref` | `asc/thread/thread.inc.sh` | `f_thread_args_append` | L453 | indexed (`$a_arr_name`) | `_u_ta_ref_arr_nameref` | ✗ Append encoded arg to array slot |

**Convention takeaways from existing code:**

- Pass **caller array name as string** (`"$2"`, `"$a_arr_name"`), bind with `local -n foo_arr_nameref="$param"`.
- Polymorphic target (`f_array_print`): plain `_nameref` suffix is acceptable.
- Loop-local rebind (`__yaml_list` in `f_yaml_write`): re-declare nameref each iteration when the target name changes.

---

## Category A — eval / array-by-name utilities (best candidates)

These functions take a **variable name string** and use `eval` or `${!…[@]}` indirection. Nameref replaces the whole pattern.

### `f_array_add_once` + `f_in_array` — `asc/utils/arr/arr.opt-inc.sh`

| | |
|---|---|
| **Current** | `f_in_array`: `local haystack=${2}[@]; for i in ${!haystack}` · `f_array_add_once`: `eval "$haystack_var_name+=($needle)"` (L59) |
| **Suggested** | `local -n haystack_arr_nameref="$2"` in both; append with `haystack_arr_nameref+=("$needle")` |
| **Call sites** | `f_array_add_once` **19** · `f_in_array` **14** (incl. `make.inc.sh`, autoload, git) |
| **Benefit** | Eliminates only `eval` array write in core utils; clarifies haystack is an array |
| **Caveats** | API stays string param for caller array name (per array-dict exclusions); only callee locals become namerefs |

### `f_str_split1` — `asc/utils/str/str.opt-inc.sh`

| | |
|---|---|
| **Current** | L550–554: `eval "${a_str_split1_var_name}=()"` and `eval "${a_str_split1_var_name}+=(\"$REPLY\")"` |
| **Suggested** | `local -n out_arr_nameref="$1"` then `out_arr_nameref=()` / `out_arr_nameref+=("$REPLY")` |
| **Call sites** | **17** (autoload version paths, git, str utils) |
| **Benefit** | Removes `eval` + documents output is always an indexed array → prefer `out_arr_nameref` or keep param name + bind |
| **Caveats** | Still sanitize param with `f_str_sanitize_var_name` before bind |

### `f_autoload_item_split_version` — `asc/asc/autoload.inc.sh`

| | |
|---|---|
| **Current** | L194–211: four `eval "${a_var_name}…"` lines building output array |
| **Suggested** | `local -n out_arr_nameref="$1"` |
| **Call sites** | **3** (via `f_autoload_add_lookup_level`) |
| **Benefit** | Same pattern as `f_str_split1`; pairs with `f_array_add_once` migration |

### `f_autoload_print_lookup_paths` — `asc/asc/autoload.inc.sh`

| | |
|---|---|
| **Current** | L93–101: `local a_arr=${1}[@]; for path in ${!a_arr}` |
| **Suggested** | `local -n paths_arr_nameref="$1"; for path in "${paths_arr_nameref[@]}"` |
| **Call sites** | Low (debug/diagnostic) |
| **Benefit** | Removes obscure `${1}[@]` indirection idiom |

### `f_hook` filter dedup write-back — `asc/asc/hook.inc.sh`

| | |
|---|---|
| **Current** | L275–280: `dedup="${!f}"` … build `deduo_arr` … `eval "$f=\"${deduo_arr[@]}\""` |
| **Suggested** | `local -n filter_nameref="$f"` for read/write of filter variable in loop |
| **Call sites** | 1 loop over `$filters` |
| **Benefit** | Eliminates `eval` reassignment; pairs with `f_array_add_once` for `deduo_arr` |
| **Caveats** | Loop variable `$f` is the dynamic name — `local -n filter_nameref="$f"` is valid Bash 4.3+ |

---

## Category B — array helper API (optional nameref params)

Today these pass **array values** (`"$@"`) or assume a caller-scope name (`array`). Nameref params would clarify contracts (coordinate with `_arr` renames in array-dict plan).

| Function | File | Current pattern | Suggested API | Benefit | Caveat |
|----------|------|-----------------|---------------|---------|--------|
| `f_array_qsort` | `arr.opt-inc.sh:81` | Values in `"$@"` → writes `sorted_arr` | `f_array_qsort input_arr_nameref [output_arr_nameref]` | Caller keeps source array; explicit output | Breaking API; 10+ call sites |
| `f_array_reverse` | `arr.opt-inc.sh:163` | Same | Same | Same | Same |
| `f_array_ksort` | `arr.opt-inc.sh:134` | Implicit caller `array` associative | `local -n array_dict_nameref="$1"` | Removes magic `@var array` doc contract | Associative target → `_dict_nameref` |

**Recommendation:** defer until `_arr`/`_dict` renames land; pilot on `f_array_ksort` first (single caller-scope assumption).

---

## Category C — mixed `${!}` read + `printf -v` write

| Function | File | Read | Write | Nameref fit | Notes |
|----------|------|------|-------|-------------|-------|
| `f_str_convert_tokens` | `str.opt-inc.sh:69–143` | `${!a_input_var_name}`, `${!match}` | `printf -v "$a_output_var_name"` | **Partial** | Input side: `local -n input_nameref="$a_input_var_name"`. Token `eval "val=\"\$($match)\""` stays (command sub) |
| `f_hook_variant_values_add` | `hook.inc.sh:779–796` | `${!a_v_values_var_name}` | `printf -v "$a_v_values_var_name"` | **Good** | Single var read-modify-write → one nameref replaces both |
| `f_global_assign_value` | `global.inc.sh:428–541` | `${!arg_var_name}`, `${!depending_var}` | multiple `printf -v "$a_var"` | **Partial** | `arg_var_name` is computed (`a_ascii_$a_var`); `local -n arg_nameref="$arg_var_name"` works. `read -p` / `unset` still need `eval` |
| `f_thread_yml_strip_quotes` | `thread.inc.sh:192–203` | `_v="thread_${_k}"; ${!_v}` | `printf -v "$_v"` | **Low** | Fixed key list; nameref per key is marginal clarity |
| `f_thread_output_mtime_ms` | `thread.inc.sh:359–363` | — | `printf -v "$a_var_name"` | **Leave** | Scalar output only |
| `f_yaml_escape_double` | `yml.inc.sh:221–229` | — | `printf -v "$a_var_name"` | **Leave** | Scalar output only |

---

## Category D — loop `${!var}` → `local -n` in body

**~76 live** `${!var}` scalar sites (excluding comment-only lines) across **23 files**. Pattern:

```bash
# Current
for var_name in "${names[@]}"; do
  val="${!var_name}"
done

# Suggested (when body has multiple accesses or assignment)
for var_name in "${names[@]}"; do
  local -n val_nameref="$var_name"
  # use "$val_nameref" instead of "${!var_name}"
done
```

**Migrate when:** loop body reads or writes the indirect variable more than once, or assigns back.

**Skip when:** single one-shot read (e.g. `case "${!uppercase}"` in wait-for hooks) — nameref adds line noise.

### Hotspots (files with most indirect scalar reads)

| File | Live `${!…}` sites | Pattern | Priority |
|------|-------------------|---------|----------|
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | ~22 | Site/global token loops, `dwt_site_data` fill | High (contrib template) |
| `asc/asc/global.inc.sh` | ~12 | `f_global_list`, `f_global_assign_value`, conditions | High |
| `asc/asc/hook.inc.sh` | ~11 | Cache keys, primitive lookups, filters | High |
| `asc/extensions/remote/remote.inc.sh` | ~8 | Definition + global token replace | High |
| `scripts/asc/contrib/asc/apache/apache.inc.sh` | 4 | Vhost token replace | Medium |
| `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh` | 4 | Config token replace | Medium |
| `asc/asc/core.inc.sh` | ~6 | Extension subjects/actions dynamic vars | Medium |
| `asc/make/make.inc.sh` | 1 | `extension_actions="${!extension_var}"` | Medium (single site, high visibility) |
| `asc/extensions/nested_instance/nested_instance/list.sh` | 2 | `doc_rel="${!doc_var:-…}"` computed names | Medium |
| `asc/extensions/remote/remote/files_dir_sync_from.sh` | 2 | `REMOTE_INSTANCE_FILES_*` pair | Medium |
| `asc/utils/str/str.opt-inc.sh` | 2 | Inside `f_str_convert_tokens` | Covered in Cat C |
| `asc/extensions/db/db.inc.sh` | 4 | Prefixed DB preset/export | Low–medium |
| `asc/test/core/global.test.sh` | 1 | Test assertion `${!s_varname}` | Leave (test idiom) |

### Token-replace family (shared refactor opportunity)

These files share the same loop shape (`for var_name in …; val="${!var_name}"; sed …`):

- `scripts/asc/contrib/asc/apache/apache.inc.sh`
- `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh`
- `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh`
- `asc/extensions/remote/remote.inc.sh` (`f_remote_definition_tokens_replace`)

Extracting a small helper (e.g. `f_str_replace_file_tokens` with nameref read) is optional — out of scope for this inventory except as a follow-up.

---

## Category E — poor fit / leave alone

| Pattern | Example locations | Why not nameref |
|---------|-------------------|-----------------|
| Command `eval` | `git.inc.sh:834`, `call_wrap.make.sh:154`, `hook.make.sh:67`, `thread.inc.sh:757` | Executing commands, not aliasing variables |
| YAML multi-var `eval` | `f_yaml_parse` callers (`thread.inc.sh:141`, `crontab.inc.sh:231`, `drupalwt.inc.sh:582`) | Emits many assignments — needs dict API |
| Include override eval | `global.inc.sh:338`, `hook.inc.sh:748`, bootstrap | Dynamic sourced code |
| `read -p` / `unset` dynamic target | `global.inc.sh:424,520–522` | Bash syntax requires `eval` |
| `eval` + command substitution in tokens | `str.opt-inc.sh:114` `eval "val=\"\$($match)\""` | Invoking function/command as token |
| Instance reinit line eval | `instance/reinit.sh`, `switch_*.sh` | Whole-line config replay |
| `GLOBALS` / `ALL_CAPS` indirection | `global.inc.sh:63–65` over `GLOBALS_UNIQUE_NAMES` | Excluded globals; indirect read is intentional |
| Scalar-only `printf -v` | 27 sites — str, fs, make, global, remote | Already clear; see subshell plan |

---

## Inventory by file (nameref-relevant)

Grouped by path. Focus on **functions and loops**, not every `${!}` one-liner.

### `asc/utils/arr/arr.opt-inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_in_array` | 26–37 | `${!haystack}` via `local haystack=${2}[@]` | `local -n haystack_arr_nameref="$2"` | A |
| `f_array_add_once` | 54–60 | `eval "$haystack_var_name+=($needle)"` | nameref append | A |
| `f_array_print` | 201–205 | `declare -n __p` | rename → `__p_nameref` | Done (rename only) |
| `f_array_qsort` / `f_array_reverse` / `f_array_ksort` | 81–143 | value args / implicit `array` | optional nameref API | B |

### `asc/utils/str/str.opt-inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_str_split1` | 542–555 | `eval` array build | `local -n out_arr_nameref="$1"` | A |
| `f_str_convert_tokens` | 69–143 | `${!…}` + `printf -v` + token `eval` | nameref on input var | C |

### `asc/asc/autoload.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_autoload_print_lookup_paths` | 92–106 | `${!a_arr}` indirection | nameref | A |
| `f_autoload_item_split_version` | 190–212 | `eval` array build | nameref | A |
| `f_autoload_add_lookup_level` | 128–170 | calls split/add_once | benefits from A | — |

### `asc/asc/hook.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_hook_opt_inc_append_candidates` | 814–816 | `local -n a_out_arr_nameref` | — | ✓ Reference |
| Filter dedup loop | 272–280 | `${!f}` + `eval "$f=…"` | nameref | A |
| Primitive / cache lookups | 140,222–243,528,614 | `${!prim_var}`, `${!var}` | nameref in multi-use loops | D |
| `f_hook_variant_values_add` | 779–796 | `${!}` + `printf -v` | single nameref RMW | C |

### `asc/yml/yml.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_yaml_write` | 249–287 | three namerefs | rename per array-dict plan | ✓ Reference |
| `f_yaml_escape_double` | 221–229 | `printf -v` only | leave | — |
| `f_yaml_parse` | 85–95 | eval multi-assign | separate project | E |

### `asc/thread/thread.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_thread_args_append` | 448–460 | `local -n _u_ta_ref` | rename → `_u_ta_ref_arr_nameref` | ✓ Reference |
| `f_thread_yml_strip_quotes` | 192–203 | `${!_v}` + `printf -v` | optional | C |
| `eval "$(f_yaml_parse …)"` | 141 | yaml codegen | E | — |

### `asc/asc/global.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_global_list` | 63–65 | `${!global_var_name}` | nameref in loop | D |
| `f_global_assign_value` | 428–541 | `${!arg_var_name}`, `printf -v`, `eval read/unset` | partial nameref | C |
| `global()` declaration parse | 660–684 | `eval declare -A`, `${!depending_var}` | depending_var → nameref | C/D |

### `asc/extensions/remote/remote.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_remote_definition_tokens_replace` | 327–356,611–647 | `${!var}` in loops | nameref | D |
| `f_remote_definition_globals_replace` | 864 | `${!var}` | single read — optional | D |

### Contrib token-replace modules

| File | Fit | Notes |
|------|-----|-------|
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | D | Largest `${!}` cluster; site data loops |
| `scripts/asc/contrib/asc/apache/apache.inc.sh` | D | Same pattern as remote tokens |
| `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh` | D | Same |
| `scripts/asc/contrib/asc/remote_traefik/*.sh` | D | Small loops |

---

## Recommended migration order

1. **`asc/utils/arr/arr.opt-inc.sh`** — `f_array_add_once` + `f_in_array` (unblocks 19+ call sites; removes core `eval` write).
2. **`asc/utils/str/str.opt-inc.sh`** — `f_str_split1` (17 call sites; same eval pattern).
3. **`asc/asc/autoload.inc.sh`** — `f_autoload_item_split_version` + `f_autoload_print_lookup_paths` (depends on 1–2).
4. **Nameref renames (no logic change)** — align with array-dict plan: `__p_nameref`, `__yaml_*_nameref`, `_u_ta_ref_arr_nameref`.
5. **`asc/asc/hook.inc.sh`** — filter dedup `eval` (L280); then `f_hook_variant_values_add` (Cat C).
6. **`asc/asc/global.inc.sh`** — `f_global_list` loop; partial `f_global_assign_value` (keep `eval read`/`unset`).
7. **`asc/extensions/remote/remote.inc.sh`** — token replace loops (template for contrib).
8. **Contrib** — drupalwt / apache / moodle token loops after core pattern settled.
9. **Defer** — `f_array_qsort`/`reverse`/`ksort` API change; `f_yaml_parse`; all command `eval`.

Coordinate with:

- `changelog/2026/07/31-array-dict-naming-plan.md` — `_arr` / `_dict` renames before changing `@var sorted_arr` docs.
- `changelog/2026/07/31-subshell-printf-v-candidates.md` — scalar returns stay on `printf -v`; do not replace those with namerefs unless doing in-place RMW.

### Open tasks

- [ ] Pilot: `f_array_add_once` / `f_in_array` nameref rewrite + shunit2 coverage in `asc/test/core/utilities.test.sh`
- [ ] Pilot: `f_str_split1` nameref rewrite (same test file pattern as split)
- [ ] Apply `_nameref` renames from array-dict plan § Nameref inventory (5 symbols)
- [ ] Document when to choose nameref vs `printf -v` in `.cursor/rules/naming.mdc` (after convention locked)
- [ ] Design `f_yaml_parse` replacement (associative dict) — separate from nameref sweep
- [ ] Re-run audit commands below after each wave

---

## Repeatable audit commands

Run from repo root `/home/paul/Documents/asc`.

```bash
# Existing namerefs
rg -n '\b(declare|local|readonly)\s+-n\b' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' --glob '!**/vendor/**' .

# Compliant nameref suffix
rg -n '\b(declare|local|readonly)\s+-n [a-zA-Z_][a-zA-Z0-9_]*(_arr_nameref|_dict_nameref|_nameref)\b' \
  --glob '!asc/vendor/**' .

# Non-compliant nameref locals (missing suffix)
rg -n '\b(declare|local|readonly)\s+-n [a-zA-Z_][a-zA-Z0-9_]*\b' \
  --glob '!asc/vendor/**' . | rg -v '_arr_nameref|_dict_nameref|_nameref'

# Indirect scalar expansion (nameref candidates)
rg -n '\$\{![a-zA-Z_][a-zA-Z0-9_]*\}' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# eval array/scalar writes by variable name
rg -n 'eval "\$\{[a-zA-Z_][a-zA-Z0-9_]*\}|eval "\$[a-zA-Z_][a-zA-Z0-9_]*\+=' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# Array-by-name indirection idiom
rg -n 'local [a-zA-Z_][a-zA-Z0-9_]*=\$\{[0-9]+\}\[@\]' \
  --glob '!asc/vendor/**' .

# Output-var pattern (coexists with namerefs — do not blindly migrate)
rg -n 'printf -v "\$' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# String param holding another var's name (excluded from _nameref suffix on param)
rg -n '_var_name|haystack_var_name|a_arr_name|a_scalars_name|a_keys_name|list_arr_name|a_output_var' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# Files ranked by indirect scalar count
rg -c '\$\{![a-zA-Z_][a-zA-Z0-9_]*\}' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' . | sort -t: -k2 -rn | head -20
```

---

## Cross-links

| Doc | Relationship |
|-----|--------------|
| `changelog/2026/07/31-array-dict-naming-plan.md` | `_nameref` / `_arr_nameref` / `_dict_nameref` suffix rules; § Nameref inventory (same six sites) |
| `changelog/2026/07/31-subshell-printf-v-candidates.md` | Scalar output via `printf -v` — complementary, not competing |
| `asc/asc/hook.inc.sh` L816 | Reference implementation `a_out_arr_nameref` |
| `asc/yml/yml.inc.sh` `f_yaml_write` | Reference for typed dict + array namerefs in one function |
