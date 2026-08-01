# Inventory: Bash nameref clarity candidates (`declare -n` / `local -n`)

| Field | Value |
|-------|--------|
| **Date** | 2026-07-31 |
| **Status** | inventory / plan (docs only — no code changes). Reviewed 2026-07-31: suffix renames already landed via array-dict plan; counts/caveats refreshed. |
| **Scope** | ASC repo `/home/paul/Documents/asc` — shell scripts only: `*.sh`, `*.inc.sh`, `*.opt-inc.sh` (excluding `asc/vendor/` and other third-party trees). **Out of scope:** capitalized (`ALL_CAPS`) / `readonly` globals (e.g. `GLOBALS*` family stays as-is). |
| **Related** | `changelog/2026/07/31-array-dict-naming-plan.md` (**implemented** — nameref `_nameref` / `_arr_nameref` / `_dict_nameref` suffixes already applied); `changelog/2026/07/31-subshell-printf-v-candidates.md`; `asc/asc/hook.inc.sh` (`a_out_arr_nameref` model) |
| **Lifecycle** | Review inventory; migrate in focused PRs. Do **not** treat this file as permission for a repo-wide mechanical rewrite. |

---

## Context

ASC already uses Bash 4.3+ namerefs in six places (four files) for array aliasing — all six symbols already use compliant `_nameref` / `_arr_nameref` / `_dict_nameref` suffixes (array-dict plan, implemented 2026-07-31). The reference model remains `a_out_arr_nameref` in `f_hook_opt_inc_append_candidates()`. Elsewhere, the same problems are solved with **`${!var}` indirect expansion**, **`eval` into a dynamically named variable**, or **`printf -v "$var_name"`** output parameters.

This plan inventories where **namerefs would be clearer** than those patterns — not every `printf -v` (many are already fine; see the subshell/`printf -v` plan). Suffix renames are **done**; remaining work is logic migrations (Categories A–D).

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
| **Dynamic `read` / `unset` (today often via `eval`)** | Not nameref-impossible: `unset "$name"` works without `eval`; `read` can target a nameref. Current code uses `eval` — leave alone unless touching that path for other reasons |
| **`ALL_CAPS` / `GLOBALS*` runtime globals** | Excluded from rename **and** from nameref suffix proposals |
| **Bash version floor** | Namerefs require Bash ≥ 4.3 (already assumed in `hook.inc.sh` comment) |
| **Nameref name equals target name** | Circular nameref — always use a distinct local (`*_nameref`), never short names that can collide with tokens/globals |

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

| Kind | Suffix | Example (current code) |
|------|--------|------------------------|
| Nameref (any target) | `_nameref` | `__p_nameref` |
| Nameref → indexed array | `_arr_nameref` | `_u_ta_ref_arr_nameref`, `__yaml_keys_arr_nameref` |
| Nameref → associative array | `_dict_nameref` | `__yaml_scalars_dict_nameref` |

**Rules:**

- **String parameters** that hold another variable's *name* (`haystack_var_name`, `a_scalars_name`, `a_input_arr_name`, …) stay scalars — no `_nameref` on the **param**. Callers still pass the name string; the callee binds `local -n …_nameref="$param"`.
- **Nameref locals** inside the callee always get `_nameref` (or double suffix when target type is known).
- Double suffix only for typed namerefs: `*_arr_nameref`, `*_dict_nameref`.
- Do **not** name public API parameters `*_arr_nameref` / `*_dict_nameref` — that suffix is for nameref locals only.

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
| **Already using nameref** | 6 declaration sites / 6 symbols (incl. `__yaml_list_*` loop rebind) | **Done** — all compliant suffixes (array-dict plan) |
| **A — eval / array-by-name utilities** | 5 functions / 8 `eval` write lines / ~14 `f_array_add_once` + ~11 `f_in_array` + ~17 `f_str_split1` call sites | **Excellent** — drop `eval`, typed nameref API |
| **B — array helper API evolution** | 3 functions (`f_array_qsort`, `f_array_reverse`, `f_array_ksort`) | **Good** — optional name-string params + internal nameref (defer) |
| **C — mixed `${!}` read + `printf -v` write** | 6 functions | **Mixed** — nameref helps read side or in-place update |
| **D — loop `${!var}` → `local -n` in body** | **~89** live scalar indirect sites / **24** files | **Good** in multi-access loops; skip one-shot reads; see rebind caveats |
| **E — poor fit / leave alone** | command/`yaml`/`include` `eval`; dynamic `read`/`unset` (eval today, not required by Bash) | **Do not** prioritize for nameref sweep |
| **`printf -v` indirect writes** | 27 sites / 12 files | **Reference** — mostly fine as-is |

---

## Already using nameref (reference)

All `declare -n` / `local -n` sites (excluding vendor). Suffix renames from the array-dict plan are **already applied** — this table is the live reference, not a todo list.

| Variable (current) | File | Function | Line | Target | Notes |
|--------------------|------|----------|------|--------|-------|
| `a_out_arr_nameref` | `asc/asc/hook.inc.sh` | `f_hook_opt_inc_append_candidates` | L816 | indexed array (`$2`) | ✓ Model for `*_arr_nameref` output |
| `__p_nameref` | `asc/utils/arr/arr.opt-inc.sh` | `f_array_print` | L202 | polymorphic array (`$1`) | ✓ Plain `_nameref` (indexed or associative) |
| `__yaml_scalars_dict_nameref` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L263 | associative (`$a_scalars_name`) | ✓ |
| `__yaml_keys_arr_nameref` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L264 | indexed (`$a_keys_name`) | ✓ |
| `__yaml_list_arr_nameref` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L281 | indexed (varargs list name) | ✓ Re-bound with `declare -n` per list section in loop |
| `_u_ta_ref_arr_nameref` | `asc/thread/thread.inc.sh` | `f_thread_args_append` | L453 | indexed (`$a_arr_name`) | ✓ Append encoded arg to array slot |

**Convention takeaways from existing code:**

- Pass **caller array name as string** (`"$2"`, `"$a_arr_name"`), bind with `local -n` / `declare -n foo_arr_nameref="$param"`.
- Polymorphic target (`f_array_print`): plain `_nameref` suffix is acceptable.
- Loop-local rebind (`__yaml_list_arr_nameref` in `f_yaml_write`): re-declare with `declare -n` each iteration when the target name changes — do **not** assign `ref=$new_name` (that writes *through* the nameref).

---

## Category A — eval / array-by-name utilities (best candidates)

These functions take a **variable name string** and use `eval` or `${!…[@]}` indirection. Nameref replaces the whole pattern.

### `f_array_add_once` + `f_in_array` — `asc/utils/arr/arr.opt-inc.sh`

| | |
|---|---|
| **Current** | `f_in_array`: `local haystack=${2}[@]; for i in ${!haystack}` · `f_array_add_once`: `eval "$haystack_var_name+=($needle)"` (L59) |
| **Suggested** | `local -n haystack_arr_nameref="$2"` in both; append with `haystack_arr_nameref+=("$needle")`; iterate `"${haystack_arr_nameref[@]}"` |
| **Call sites** | `f_array_add_once` **~14** · `f_in_array` **~11** (excl. defs/docs; includes `make.inc.sh`, autoload, git, global, contrib) |
| **Benefit** | Eliminates only `eval` array write in core utils; clarifies haystack is an array |
| **Caveats** | API stays string param for caller array name (per array-dict exclusions); only callee locals become namerefs. **Intentional behavior fixes:** quoted `[@]` / `"$needle"` stop IFS-splitting that unquoted `${!haystack}` and `+=($needle)` allow today — treat as fix, not pure rename; cover in shunit2 |

### `f_str_split1` — `asc/utils/str/str.opt-inc.sh`

| | |
|---|---|
| **Current** | L550–554: `eval "${a_str_split1_var_name}=()"` and `eval "${a_str_split1_var_name}+=(\"$REPLY\")"` |
| **Suggested** | `local -n out_arr_nameref="$1"` then `out_arr_nameref=()` / `out_arr_nameref+=("$REPLY")` |
| **Call sites** | **~17** (autoload version paths, git, str utils) |
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
| **Suggested** | `local -n filter_nameref="$f"` for read/write of filter variable in loop; write-back is a **space-joined scalar** (`filter_nameref="${deduo_arr[*]}"`), not an array assign |
| **Call sites** | 1 loop over `$filters` |
| **Benefit** | Eliminates `eval` reassignment; pairs with `f_array_add_once` for `deduo_arr` |
| **Caveats** | Loop variable `$f` is the dynamic name — `local -n filter_nameref="$f"` is valid Bash 4.3+. Same loop still mutates via `declare "$f"=…` / `declare "$f"+="…"` — decide whether the **whole filter block** is in scope or only the `eval` line; partial migrate leaves mixed style |

---

## Category B — array helper API (optional name params + internal nameref)

Today these pass **array values** (`"$@"`) or assume a caller-scope name (`array`). A clearer contract uses **string params** for array names and binds nameref **locals** inside (same rule as Category A — do not put `_nameref` on the public param).

| Function | File | Current pattern | Suggested API | Benefit | Caveat |
|----------|------|-----------------|---------------|---------|--------|
| `f_array_qsort` | `arr.opt-inc.sh:81` | Values in `"$@"` → writes `sorted_arr` | `f_array_qsort a_input_arr_name [a_output_arr_name]` + `local -n` inside | Caller keeps source array; explicit output | Breaking API; 10+ call sites |
| `f_array_reverse` | `arr.opt-inc.sh:163` | Same | Same | Same | Same |
| `f_array_ksort` | `arr.opt-inc.sh:134` | Implicit caller `array` associative | `f_array_ksort a_dict_name` → `local -n array_dict_nameref="$1"` | Removes magic `@var array` doc contract | Associative target → `_dict_nameref` local |

**Recommendation:** defer until after Category A pilots; pilot on `f_array_ksort` first (single caller-scope assumption). `_arr` / `_dict` renames from the array-dict plan are already landed — no need to wait on those.

---

## Category C — mixed `${!}` read + `printf -v` write

| Function | File | Read | Write | Nameref fit | Notes |
|----------|------|------|-------|-------------|-------|
| `f_str_convert_tokens` | `str.opt-inc.sh:69–143` | `${!a_input_var_name}`, `${!match}` | `printf -v "$a_output_var_name"` | **Partial** | Input side: `local -n input_nameref="$a_input_var_name"`. Token `eval "val=\"\$($match)\""` stays (command sub) |
| `f_hook_variant_values_add` | `hook.inc.sh:779–796` | `${!a_v_values_var_name}` | `printf -v "$a_v_values_var_name"` | **Good** | Single var read-modify-write → one nameref replaces both |
| `f_global_assign_value` | `global.inc.sh:428–541` | `${!arg_var_name}`, `${!depending_var}` | multiple `printf -v "$a_var"` | **Partial** | `arg_var_name` is computed (`a_ascii_$a_var`); `local -n arg_nameref="$arg_var_name"` works. `read`/`unset` use `eval` today but can use nameref / `unset "$a_var"` instead if that path is touched |
| `f_thread_yml_strip_quotes` | `thread.inc.sh:192–203` | `_v="thread_${_k}"; ${!_v}` | `printf -v "$_v"` | **Low** | Fixed key list; nameref per key is marginal clarity |
| `f_thread_output_mtime_ms` | `thread.inc.sh:359–363` | — | `printf -v "$a_var_name"` | **Leave** | Scalar output only |
| `f_yaml_escape_double` | `yml.inc.sh:221–229` | — | `printf -v "$a_var_name"` | **Leave** | Scalar output only |

---

## Category D — loop `${!var}` → `local -n` in body

**~89 live** `${!var}` scalar sites (excluding comment-only lines) across **24 files**. Pattern:

```bash
# Current
for var_name in "${names[@]}"; do
  val="${!var_name}"
done

# Suggested (when body has multiple accesses or assignment)
for var_name in "${names[@]}"; do
  local -n val_nameref="$var_name"   # or declare -n to rebind on later iters
  # use "$val_nameref" instead of "${!var_name}"
done
```

**Migrate when:** loop body reads or writes the indirect variable more than once, or assigns back.

**Skip when:** single one-shot read (e.g. `case "${!uppercase}"` in wait-for hooks) — nameref adds line noise; risk/noise tradeoff is often not worth it for token-replace one-liners.

### Rebind / circular-nameref caveats (do not skip)

| Hazard | Wrong | Right |
|--------|-------|-------|
| **Rebind target** | `val_nameref=$other_name` — writes the string *into* the current target | `declare -n val_nameref="$other_name"` (or `local -n` on first declare) |
| **Circular nameref** | Local name equals target name (e.g. `local -n foo="$1"` when `$1` is `foo`) | Always use a distinct long local (`*_nameref`); never short names that can collide with tokens/globals |
| **One-shot loops** | Blindly wrap every `${!var}` | Prefer leave one-shot `${!}` alone |

`f_yaml_write`'s `__yaml_list_arr_nameref` loop is the in-repo model for safe per-iteration rebind.

### Hotspots (files with most indirect scalar reads)

Counts from `rg -c '\$\{![a-zA-Z_][a-zA-Z0-9_]*\}'` (refreshed 2026-07-31; approximate — do not treat as a checklist gate):

| File | Live `${!…}` sites | Pattern | Priority |
|------|-------------------|---------|----------|
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | ~22 | Site/global token loops, `dwt_site_data` fill | High (contrib template) |
| `asc/asc/hook.inc.sh` | ~10 | Cache keys, primitive lookups, filters | High |
| `asc/asc/global.inc.sh` | ~9 | `f_global_list`, `f_global_assign_value`, conditions | High |
| `asc/asc/core.inc.sh` | ~7 | Extension subjects/actions dynamic vars | Medium |
| `asc/extensions/remote/remote.inc.sh` | ~6 | Definition + global token replace | High |
| `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh` | ~5 | Config token replace | Medium |
| `scripts/asc/contrib/asc/apache/apache.inc.sh` | ~5 | Vhost token replace | Medium |
| `asc/extensions/db/db.inc.sh` | 4 | Prefixed DB preset/export | Low–medium |
| `asc/utils/str/str.opt-inc.sh` | ~3 | Inside `f_str_convert_tokens` | Covered in Cat C |
| `asc/make/make.inc.sh` | 1 | `extension_actions="${!extension_var}"` | Medium (single site, high visibility) |
| `asc/extensions/nested_instance/nested_instance/list.sh` | 2 | `doc_rel="${!doc_var:-…}"` computed names | Medium |
| `asc/extensions/remote/remote/files_dir_sync_from.sh` | 2 | `REMOTE_INSTANCE_FILES_*` pair | Medium |
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

| Pattern | Example locations | Why not prioritize nameref |
|---------|-------------------|----------------------------|
| Command `eval` | `git.inc.sh:834`, `call_wrap.make.sh:154`, `hook.make.sh:67`, `thread.inc.sh:757` | Executing commands, not aliasing variables |
| YAML multi-var `eval` | `f_yaml_parse` callers (`thread.inc.sh:141`, `crontab.inc.sh:231`, `drupalwt.inc.sh:582`) | Emits many assignments — needs dict API |
| Include override eval | `global.inc.sh:338`, `hook.inc.sh:748`, bootstrap | Dynamic sourced code |
| `read -p` / `unset` via `eval` today | `global.inc.sh:424,520–522` | **Not** a Bash requirement: `unset "$a_var"` works; `read` can target a nameref (`local -n t="$a_var"; read -r … t`). Current `eval` is legacy — leave unless touching the path; do not treat as “nameref-impossible” |
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
| `f_array_print` | 201–205 | `declare -n __p_nameref` | — (suffix done) | ✓ Reference |
| `f_array_qsort` / `f_array_reverse` / `f_array_ksort` | 81–143 | value args / implicit `array` | optional name-string API + internal nameref | B |

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
| `f_yaml_write` | 249–287 | three namerefs (compliant suffixes) | — | ✓ Reference |
| `f_yaml_escape_double` | 221–229 | `printf -v` only | leave | — |
| `f_yaml_parse` | 85–95 | eval multi-assign | separate project | E |

### `asc/thread/thread.inc.sh`

| Item | Lines | Current | Suggested | Fit |
|------|-------|---------|-----------|-----|
| `f_thread_args_append` | 448–460 | `local -n _u_ta_ref_arr_nameref` | — (suffix done) | ✓ Reference |
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

1. **`asc/utils/arr/arr.opt-inc.sh`** — `f_array_add_once` + `f_in_array` (unblocks ~14 / ~11 call sites; removes core `eval` write; document quoted-iteration behavior fix in tests).
2. **`asc/utils/str/str.opt-inc.sh`** — `f_str_split1` (~17 call sites; same eval pattern).
3. **`asc/asc/autoload.inc.sh`** — `f_autoload_item_split_version` + `f_autoload_print_lookup_paths` (depends on 1–2).
4. ~~**Nameref renames (no logic change)**~~ — **done** via array-dict plan (`__p_nameref`, `__yaml_*_*_nameref`, `_u_ta_ref_arr_nameref`).
5. **`asc/asc/hook.inc.sh`** — filter dedup `eval` (L280) as scalar write-back; consider whole filter `declare "$f"` block vs single line; then `f_hook_variant_values_add` (Cat C).
6. **`asc/asc/global.inc.sh`** — `f_global_list` loop; partial `f_global_assign_value` (keep or later replace `eval` `read`/`unset` — neither strictly requires `eval`).
7. **`asc/extensions/remote/remote.inc.sh`** — token replace loops (template for contrib); only where body has multi-access.
8. **Contrib** — drupalwt / apache / moodle token loops after core pattern settled.
9. **Defer** — `f_array_qsort`/`reverse`/`ksort` API change; `f_yaml_parse`; all command `eval`.

Coordinate with:

- `changelog/2026/07/31-array-dict-naming-plan.md` — **implemented**; `_arr` / `_dict` / `_nameref` suffixes already applied. No rename dependency left for this plan.
- `changelog/2026/07/31-subshell-printf-v-candidates.md` — scalar returns stay on `printf -v`; do not replace those with namerefs unless doing in-place RMW.

### Open tasks

- [ ] Pilot: `f_array_add_once` / `f_in_array` nameref rewrite + shunit2 coverage in `asc/test/core/utilities.test.sh` (include space-in-element / quoted-needle cases)
- [ ] Pilot: `f_str_split1` nameref rewrite (same test file pattern as split)
- [x] Apply `_nameref` renames from array-dict plan § Nameref inventory (5 symbols) — **done** 2026-07-31
- [ ] Document when to choose nameref vs `printf -v` in `.cursor/rules/naming.mdc` (after convention locked); include rebind / circular-nameref warnings
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
| `changelog/2026/07/31-array-dict-naming-plan.md` | **Implemented** — `_nameref` / `_arr_nameref` / `_dict_nameref` suffix rules; same six sites now compliant |
| `changelog/2026/07/31-subshell-printf-v-candidates.md` | Scalar output via `printf -v` — complementary, not competing |
| `asc/asc/hook.inc.sh` L816 | Reference implementation `a_out_arr_nameref` |
| `asc/yml/yml.inc.sh` `f_yaml_write` | Reference for typed dict + array namerefs + safe loop rebind |
