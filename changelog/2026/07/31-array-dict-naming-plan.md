# Inventory: Bash array / associative-array / nameref naming (`*_arr` / `*_dict` / `*_nameref`)

| Field | Value |
|-------|--------|
| **Date** | 2026-07-31 |
| **Status** | implemented (2026-07-31) — code migration applied across ASC repo |
| **Scope** | ASC repo `/home/paul/Documents/asc` — **ordinary** shell script variables only: Bash indexed arrays, associative arrays, and nameref locals in `*.sh`, `*.inc.sh`, `*.opt-inc.sh` (excluding `asc/vendor/`). **Out of scope:** capitalized (`ALL_CAPS`) global names, especially `readonly` ones — leave untouched (see § Exclusions). |
| **Related** | `changelog/2026/07/31-subshell-printf-v-candidates.md`; `changelog/2026/07/23-f-e-naming-convention.md`; `asc/utils/arr/arr.opt-inc.sh` |
| **Lifecycle** | Review inventory; rename in focused PRs. Do **not** treat this file as permission for a repo-wide mechanical rewrite. |

---

## Context

ASC shell code uses Bash arrays throughout make generation, globals, git, thread orchestration, remote DB, software provisioning, and test infrastructure. Naming is inconsistent today: some utilities already use `*_arr` / `*_dict` (especially `asc/utils/arr/arr.opt-inc.sh` output vars and `dumps_dict` in remote_db), while most call-site arrays use bare names (`make_entries`, `db_ids`, `GLOBALS`). Nameref locals (`declare -n` / `local -n`) are rare (six sites, four files) and mostly lack a `_nameref` suffix — except `a_out_arr_nameref` in `hook.inc.sh`.

This plan inventories array variables so renames can be applied deliberately — file-by-file or subsystem-by-subsystem — without breaking wrap-script contracts or generated cache files.

---

## Naming convention

| Kind | Suffix | Example |
|------|--------|---------|
| Indexed (regular) array | `_arr` | `db_ids` → `db_ids_arr` |
| Associative array | `_dict` | `peer_count` → `peer_count_dict` |
| Nameref (any target) | `_nameref` | `__p` → `__p_nameref` |
| Nameref → indexed array | `_arr_nameref` | `__yaml_list` → `__yaml_list_arr_nameref` |
| Nameref → associative array | `_dict_nameref` | `__yaml_scalars` → `__yaml_scalars_dict_nameref` |

**Rules:**

- Suffix reflects **storage kind**, not role (`declaration_dict` not `declaration_arr` for `declare -A`).
- **Nameref locals** (`declare -n` / `local -n`) always take a `_nameref` suffix.
- **Double suffix is allowed only for namerefs** that alias an array or dict: `foobar_arr_nameref` (indexed target), `foobar_dict_nameref` (associative target). This is the sole exception to the “one suffix per variable” rule.
- When the nameref target type is known, prefer the double suffix (`*_arr_nameref` / `*_dict_nameref`) over plain `*_nameref`.
- When a nameref is **polymorphic** (may point at indexed or associative storage), plain `*_nameref` is acceptable — e.g. `f_array_print` accepts either kind via one nameref.
- **String parameters** that hold another variable’s *name* (`haystack_var_name`, `a_scalars_name`, `a_arr_name`, …) are scalars, not namerefs — no `_arr` / `_dict` / `_nameref` on the param itself (see Exclusions).
- **Bash built-in special arrays** are out of scope (see Exclusions).
- **Capitalized global names** (`ALL_CAPS` / SHOUTY globals, especially `readonly`) are out of scope — leave as-is; do not add `_arr` / `_dict` / `_nameref` (see Exclusions). This includes the `GLOBALS*` runtime family.
- Generated files (`data/asc/cache/*.sh`, `data/asc/generated.mk`) inherit names from generators — rename source + regenerate, not hand-edit cache.

---

## Methodology

Audited `*.sh`, `*.inc.sh`, `*.opt-inc.sh` under the repo, excluding `asc/vendor/` and other `vendor/` trees. **In scope:** ordinary script variables (locals, lowercase globals). **Out of scope:** capitalized (`ALL_CAPS`) global names — see § Exclusions.

Signals collected per distinct variable name:

1. Explicit declarations: `declare -a`, `declare -A`, `local -a`, `local -A`, `readonly -a/A`
2. Nameref declarations: `declare -n`, `local -n`, `readonly -n`
3. Assignments: `name=(…)`, `name+=("…")`
4. Array expansions: `${name[@]}`, `${name[*]}`, `${name[i]}`, `${#name[@]}`, `${!name[@]}` (associative keys)
5. Comment-only `@example` blocks (flagged separately)

Type inference: explicit `-a`/`-A` wins; `declare -n` / `local -n` → nameref (infer target type from usage: `[@]`/`+=`/numeric index → indexed; string keys / `${!name[@]}` on caller array → associative). Manual review flagged only for remaining ambiguous indirect uses (e.g. `eval` with dynamic names).

---

## Summary

| Category | Distinct vars | Already compliant / excluded | Renamed | Remaining |
|----------|---------------|------------------------------|---------|-----------|
| Indexed arrays | 117 | 21 | 96 | 0 |
| Associative arrays | 10 | 3 | 7 | 0 |
| Namerefs | 6 | 1 | 5 | 0 |
| Unknown / ambiguous | 0 | — | — | 0 |
| **Total** | **133** | **25** | **108** | **0** |

**Explicit `declare -a`/`-A` sites:** 24 (plus comment examples in docs)

**Explicit `declare -n` / `local -n` sites:** 6 (5 distinct nameref symbols + `__yaml_list` re-declared in loop)

**Wrong suffix (type ≠ suffix):** 1 — see § Tricky cases

### Hotspots (most sites, needs rename)

| Variable | Type | Sites | Suggested | Primary file(s) |
|----------|------|-------|-----------|-----------------|
| `db_ids` | indexed | 38 | `db_ids_arr` | `asc/extensions/db/app/install.hook.sh`, `asc/extensions/db/db.inc.sh`… |
| `make_entries` | indexed | 32 | `make_entries_arr` | `asc/log/log.wrap.sh`, `asc/loop/loop.wrap.sh`… |
| `real_scripts` | indexed | 27 | `real_scripts_arr` | `asc/log/log.wrap.sh`, `asc/loop/loop.wrap.sh`… |
| `keys` | indexed | 24 | `keys_arr` | `asc/extensions/remote/remote.inc.sh`, `asc/extensions/remote_db/remote/remote.opt-inc.sh` |
| `git_hooks_whitelist` | indexed | 23 | `git_hooks_whitelist_arr` | `asc/git/git.inc.sh` |
| `cmds` | indexed | 14 | `cmds_arr` | `asc/extensions/remote_db/remote/db_download.sh`, `asc/extensions/remote_db/remote/db_dump.sh`… |
| `declaration_arr` | associative | 14 | `declaration_dict` | `asc/asc/global.inc.sh` |
| `instance_ids` | indexed | 12 | `instance_ids_arr` | `asc/extensions/db/db.inc.sh`, `asc/extensions/remote/remote.inc.sh`… |
| `cron_schedules` | indexed | 11 | `cron_schedules_arr` | `asc/extensions/crontab/crontab.inc.sh` |
| `dwt_sites_ids` | indexed | 9 | `dwt_sites_ids_arr` | `scripts/asc/contrib/asc/drupalwt/app/ensure_dirs_exist.hook.sh`, `scripts/asc/contrib/asc/drupalwt/app/fs_perms_set.hook.sh`… |
| `software_diff_ids` | indexed | 9 | `software_diff_ids_arr` | `asc/extensions/software/host/provision.opt-inc.sh` |
| `software_diff_status` | indexed | 9 | `software_diff_status_arr` | `asc/extensions/software/host/provision.opt-inc.sh` |
| `asc_globals_var_names` | indexed | 7 | `asc_globals_var_names_arr` | `asc/asc/global.inc.sh`, `asc/extensions/remote/remote.inc.sh`… |
| `default_files` | indexed | 7 | `default_files_arr` | `asc/instance/fs_perms_set.hook.sh` |

### Files with most array variables

| File | Vars |
|------|------|
| `asc/extensions/software/host/provision.opt-inc.sh` | 24 |
| `asc/make/make.inc.sh` | 14 |
| `asc/git/git.inc.sh` | 12 |
| `asc/test/test.inc.sh` | 11 |
| `asc/thread/thread.inc.sh` | 11 |
| `asc/asc/global.inc.sh` | 10 |
| `asc/utils/arr/arr.opt-inc.sh` | 10 |
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | 8 |
| `asc/asc/hook.inc.sh` | 7 |
| `asc/asc/core.inc.sh` | 6 |
| `asc/extensions/remote/remote.inc.sh` | 6 |
| `asc/extensions/crontab/crontab.inc.sh` | 5 |

---

## Exclusions (do not rename)

| Symbol | Reason |
|--------|--------|
| `BASH_ARGC` | Bash built-in special array |
| `BASH_ARGV` | Bash built-in special array |
| `BASH_REMATCH` | Bash built-in special array |
| `BASH_SOURCE` | Bash built-in special array |
| `DIRSTACK` | Bash built-in special array |
| `FUNCNAME` | Bash built-in special array |
| `LINENO` | Bash built-in special array |
| `MAPFILE` | Bash built-in special array |
| `PIPESTATUS` | Bash built-in special array |
| `REPLY` | Bash built-in special array |
| Nameref string params (`haystack_var_name`, `a_scalars_name`, `a_keys_name`, `a_arr_name`, `list_arr_name`, …) | Scalar holds **name** of another variable; not a nameref local — no suffix on param |
| `eval`-built dynamic names without fixed symbol | Case-by-case; not in inventory |
| `GLOBALS` | Core runtime associative store — capitalized global; **keep `GLOBALS` as-is** (not `GLOBALS_dict`) |
| `GLOBALS_DEFERRED` | Capitalized global indexed companion of `GLOBALS` — leave as-is |
| `GLOBALS_UNIQUE_KEYS` | Capitalized global indexed companion of `GLOBALS` — leave as-is |
| `GLOBALS_UNIQUE_NAMES` | Capitalized global indexed companion of `GLOBALS` — leave as-is |
| Capitalized (`ALL_CAPS`) global arrays / dicts / namerefs (incl. `readonly`) | **Class exclusion** — ordinary locals and lowercase script variables are in scope; SHOUTY globals are not |

**Scope rule (2026-07-31):** Renaming applies to **ordinary shell script variables** — typical locals and non-readonly lowercase script variables that should gain `_arr` / `_dict` / `_nameref`. **Do not rename** capitalized global names (the `GLOBALS*` family and any other `ALL_CAPS` globals). Verified in repo: the only ALL_CAPS array globals besides `GLOBALS` are `GLOBALS_DEFERRED`, `GLOBALS_UNIQUE_KEYS`, and `GLOBALS_UNIQUE_NAMES` (none are `readonly -a`; all are runtime globals in `asc/asc/global.inc.sh`, reset from `asc/instance/instance.inc.sh` and tests). Local ALL_CAPS scratch vars (e.g. `ADDR` from `read -ra` in `dump.mysql.hook.sh`) remain **in scope** — they are not globals.

---

## Tricky cases

### Wrong suffix today

| Variable | Declared type | Current suffix | Suggested | Notes |
|----------|---------------|----------------|-----------|-------|
| `declaration_arr` | associative | mismatched | `declaration_dict` | Associative but `_arr` suffix — rename to `declaration_dict` |

### High-impact renames (plan carefully)

| Variable | Suggested | Why tricky |
|----------|-----------|------------|
| `make_entries` | `make_entries_arr` | Paired with `real_scripts`; sourced by wrap scripts (`make.wrap.sh`, `log.wrap.sh`, `loop.wrap.sh`, `thread.wrap.sh`) |
| `real_scripts` | `real_scripts_arr` | Same wrap-script contract; codegen writes `real_scripts+=` into cache files |
| `test_case_registry_*` | `test_case_registry_*_arr` | Six parallel arrays written to `data/asc/cache/test-cases.sh` by `f_make_generate_test_cases()` |
| `asc_action_names` | `asc_action_names_arr` | Instance listing / core bootstrap action registry |
| `dumps_dict` | `—` | Already compliant; shared across six remote_db entry scripts |
| `sorted_arr / reversed_arr` | `—` | Already compliant; documented output collision vars in `f_array_qsort` / `f_array_reverse` |

### Software manifest column arrays

`provision.opt-inc.sh` loads YAML into parallel indexed columns (`sw_tarball__id`, `sw_apt`, …). These behave as indexed arrays (numeric/`$i` access) but were partially missed by naive `[@]`-only heuristics. All should gain `_arr` suffix together when that file is migrated.

---

## Already compliant / excluded (reference)

| Variable | Type | File(s) | Notes |
|----------|------|---------|-------|
| `a_parts_arr` | indexed | `asc/asc/hook.inc.sh` | — |
| `commit_arr` | indexed | `asc/git/git.inc.sh` | — |
| `contents_list_arr` | indexed | `asc/utils/fs/fs.opt-inc.sh` | — |
| `deduo_arr` | indexed | `asc/asc/hook.inc.sh` | — |
| `depending_var_split_arr` | indexed | `asc/asc/global.inc.sh` | — |
| `GLOBALS` | associative | `asc/asc/global.inc.sh`, `asc/instance/instance.inc.sh`, `asc/test/core/global.test.sh` | Capitalized global — excluded; keep `GLOBALS` as-is (see § Exclusions) |
| `GLOBALS_DEFERRED` | indexed | `asc/asc/global.inc.sh` | Capitalized global — excluded (see § Exclusions) |
| `GLOBALS_UNIQUE_KEYS` | indexed | `asc/asc/global.inc.sh` | Capitalized global — excluded (see § Exclusions) |
| `GLOBALS_UNIQUE_NAMES` | indexed | `asc/asc/global.inc.sh`, `asc/instance/instance.inc.sh`, `asc/test/core/global.test.sh` | Capitalized global — excluded (see § Exclusions) |
| `dumps_dict` | associative | `asc/extensions/remote_db/remote/db_download.sh`, `asc/extensions/remote_db/remote/db_dump.sh`, `asc/extensions/remote_db/remote/db_list_dumps.sh` | Already compliant; remote_db scripts |
| `ei_override_lookup_arr` | indexed | `asc/asc/core.inc.sh` | — |
| `exclusions_arr` | indexed | `asc/asc/core.inc.sh` | — |
| `file_list_arr` | indexed | `asc/extensions/db/db/list_dumps.sh`, `asc/utils/fs/fs.opt-inc.sh`, `scripts/asc/contrib/asc/mysql/db/exec.mysql.hook.sh` | — |
| `globals_arr` | indexed | `asc/asc/global.inc.sh` | — |
| `gn_arr` | indexed | `asc/asc/global.inc.sh` | — |
| `k_split_arr` | indexed | `asc/git/git.inc.sh` | — |
| `name_version_arr` | indexed | `asc/asc/autoload.inc.sh` | — |
| `purge_list_arr` | indexed | `asc/extensions/compose/instance/uninit.hook.sh`, `asc/instance/setup.sh`, `asc/instance/uninit.sh` | — |
| `reversed_arr` | indexed | `asc/git/git.inc.sh`, `asc/utils/arr/arr.opt-inc.sh` | Output var documented in `f_array_*` @var blocks |
| `setup_dict` | associative | `asc/extensions/remote/remote.inc.sh` | — |
| `sorted_arr` | indexed | `asc/git/git.inc.sh`, `asc/instance/list_actions.sh`, `asc/make/list_entry_points.sh` | Output var documented in `f_array_*` @var blocks |
| `split_arr` | indexed | `asc/utils/str/str.opt-inc.sh` | — |
| `tmp_arr` | indexed | `asc/utils/arr/arr.opt-inc.sh` | — |
| `version_arr` | indexed | `asc/asc/autoload.inc.sh` | — |

---

## Nameref inventory

All `declare -n` / `local -n` sites under ASC (excluding vendor). **OK:** ✓ compliant, ✗ needs rename.

| Variable | File | Function | Line | Target type | Points at (param / usage) | OK | Suggested rename | Notes |
|----------|------|----------|------|-------------|---------------------------|----|------------------|-------|
| `a_out_arr_nameref` | `asc/asc/hook.inc.sh` | `f_hook_opt_inc_append_candidates` | L816 | indexed array | `$2` — caller output array (e.g. `opt_incs`) | ✓ | — | Already `*_arr_nameref`; model for array-output namerefs |
| `__p` | `asc/utils/arr/arr.opt-inc.sh` | `f_array_print` | L202 | indexed or associative | `$1` — caller array name; polymorphic via `${!__p[@]}` | ✗ | `__p_nameref` | Plain `_nameref` — target type varies |
| `__yaml_scalars` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L263 | associative array | `$a_scalars_name` (e.g. `y_sc`) | ✗ | `__yaml_scalars_dict_nameref` | — |
| `__yaml_keys` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L264 | indexed array | `$a_keys_name` (e.g. `y_keys` / `__yaml_keys` caller var) | ✗ | `__yaml_keys_arr_nameref` | Was misclassified as indexed array var |
| `__yaml_list` | `asc/yml/yml.inc.sh` | `f_yaml_write` | L281 | indexed array | `$list_arr_name` (varargs pair per YAML list section) | ✗ | `__yaml_list_arr_nameref` | Re-declared inside `while` loop per list key |
| `_u_ta_ref` | `asc/thread/thread.inc.sh` | `f_thread_args_append` | L453 | indexed array | `$a_arr_name` (e.g. `thread_entry_args`, `thread_stage_args`) | ✗ | `_u_ta_ref_arr_nameref` | — |

**Reclassified from § Manual review (2026-07-31):** `__p`, `__yaml_scalars`, `_u_ta_ref` → nameref rows above. `array` (`f_array_ksort` caller-scope `@var`) → associative, see `asc/utils/arr/arr.opt-inc.sh` inventory. `sites` (`drupalwt.inc.sh` L780) → removed (false positive: PHP fragment in `echo`, not a Bash array).

---

## Inventory by file

Grouped by path. **OK:** ✓ compliant, ✗ needs rename, ⚠ wrong suffix, — excluded (string param / not an array).

### `asc/asc/autoload.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `name_version_arr` | indexed | ✓ | — | L141 | `f_autoload_add_lookup_level` | 6 | — |
| `version_arr` | indexed | ✓ | — | L153 | `f_autoload_add_lookup_level` | 2 | — |

### `asc/asc/core.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_action_names` | indexed | ✗ | `asc_action_names_arr` | L18 | `(top-level)`, `f_asc_get_actions` | 2 | — |
| `asc_action_scripts` | indexed | ✗ | `asc_action_scripts_arr` | L84 | `(top-level)`, `f_asc_get_actions` | 2 | — |
| `base_paths` | indexed | ✗ | `base_paths_arr` | L204 | `f_asc_get_actions`, `f_hook_build_lookup_by_subject` | 6 | — |
| `ei_override_lookup_arr` | indexed | ✓ | — | L183 | `f_asc_extensions` | 5 | — |
| `exclusions_arr` | indexed | ✓ | — | L201 | `f_asc_extensions` | 1 | — |
| `ignored_values` | indexed | ✗ | `ignored_values_arr` | L315 | `f_asc_primitive_values` | 2 | — |

### `asc/asc/global.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `GLOBALS` | associative | ✓ | — | L104 | `f_global_aggregate`, `f_global_list` | 38 | Capitalized global — excluded; keep `GLOBALS` as-is (see § Exclusions) |
| `GLOBALS_DEFERRED` | indexed | ✓ | — | L810 | `global` | 1 | Capitalized global — excluded (see § Exclusions) |
| `GLOBALS_UNIQUE_KEYS` | indexed | ✓ | — | L863 | `f_global_debug` | 1 | Capitalized global — excluded (see § Exclusions) |
| `GLOBALS_UNIQUE_NAMES` | indexed | ✓ | — | L63 | `f_global_list`, `global` | 2 | Capitalized global — excluded (see § Exclusions) |
| `asc_globals_values` | indexed | ✗ | `asc_globals_values_arr` | L65 | `f_global_list` | 1 | — |
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |
| `declaration_arr` | associative | ⚠ wrong suffix | `declaration_dict` | L660 | `global` | 14 | Associative but `_arr` suffix — rename to `declaration_dict` |
| `depending_var_split_arr` | indexed | ✓ | — | L681 | `global` | 1 | — |
| `globals_arr` | indexed | ✓ | — | L383 | `f_global_debug`, `f_global_foreach` | 2 | — |
| `gn_arr` | indexed | ✓ | — | L79 | `f_global_write` | 2 | — |

### `asc/asc/hook.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `a_out_arr_nameref` | nameref | ✓ | — | L816 | `f_hook_opt_inc_append_candidates` | 2 | Nameref to indexed array (`local -n`); already compliant |
| `a_parts_arr` | indexed | ✓ | — | L519 | `f_hook_build_lookup_by_subject` | 1 | — |
| `base_paths` | indexed | ✗ | `base_paths_arr` | L204 | `f_asc_get_actions`, `f_hook_build_lookup_by_subject` | 6 | — |
| `deduo_arr` | indexed | ✓ | — | L280 | `hook` | 1 | — |
| `lookup_paths` | indexed | ✗ | `lookup_paths_arr` | L320 | `f_hook_build_lookup_by_subject`, `f_hook_build_project_root_dir_lookup` | 6 | — |
| `matched_hooks` | indexed | ✗ | `matched_hooks_arr` | L367 | `hook` | 3 | — |
| `opt_incs` | indexed | ✗ | `opt_incs_arr` | L368 | `f_hook_source_opt_incs_for_path`, `hook` | 5 | — |

### `asc/bootstrap/90-caller-opt-inc.bootstrap-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `bootstrap_opt_candidates` | indexed | ✗ | `bootstrap_opt_candidates_arr` | L36 | `(top-level)` | 2 | — |

### `asc/extensions/builder/template/core/stack/app/list_mandatory_globals.compose.hook.tpl.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `mandatory_globals` | indexed | ✗ | `mandatory_globals_arr` | L22 | `(top-level)` | 5 | — |

### `asc/extensions/builder/template/core/stack/app/list_mandatory_globals.hook.tpl.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `mandatory_globals` | indexed | ✗ | `mandatory_globals_arr` | L22 | `(top-level)` | 5 | — |

### `asc/extensions/builder/template/core/stack/db/list_mandatory_globals.hook.tpl.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `mandatory_globals` | indexed | ✗ | `mandatory_globals_arr` | L22 | `(top-level)` | 5 | — |

### `asc/extensions/builder/template/core/stack/vcs/list_mandatory_globals.hook.tpl.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `mandatory_globals` | indexed | ✗ | `mandatory_globals_arr` | L22 | `(top-level)` | 5 | — |

### `asc/extensions/compose/instance/uninit.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `purge_list_arr` | indexed | ✓ | — | L92 | `(top-level)` | 15 | — |

### `asc/extensions/crontab/crontab.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `cron_schedules` | indexed | ✗ | `cron_schedules_arr` | L84 | `f_cron_preset_compile` | 11 | — |
| `files` | indexed | ✗ | `files_arr` | L284 | `f_cron_settings_setup` | 4 | — |
| `lines` | indexed | ✗ | `lines_arr` | L530 | `f_cron_entry_crontab_lines` | 3 | — |
| `peer_count` | associative | ✗ | `peer_count_dict` | L286 | `f_cron_settings_setup` | 2 | — |
| `peer_seen` | associative | ✗ | `peer_seen_dict` | L287 | `f_cron_settings_setup` | 2 | — |

### `asc/extensions/db/app/install.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `asc/extensions/db/db.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `instance_ids` | indexed | ✗ | `instance_ids_arr` | L64 | `(top-level)`, `f_db_restore_any` | 12 | — |
| `lookup_subdirs` | indexed | ✗ | `lookup_subdirs_arr` | L1409 | `f_db_restore_any` | 4 | — |

### `asc/extensions/db/db/get_credentials.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `asc/extensions/db/db/list_dumps.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `file_list_arr` | indexed | ✓ | — | L470 | `(top-level)`, `f_fs_file_list` | 4 | — |

### `asc/extensions/db/db/list_ids.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `asc/extensions/db/instance/stage2_setup.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `asc/extensions/nested_instance/nested_instance/exec.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `nested_asc_cmd` | indexed | ✗ | `nested_asc_cmd_arr` | L169 | `f_nested_asc_expand_entry` | 2 | — |

### `asc/extensions/remote/remote.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `instance_ids` | indexed | ✗ | `instance_ids_arr` | L64 | `(top-level)`, `f_db_restore_any` | 12 | — |
| `keys` | indexed | ✗ | `keys_arr` | L322 | `f_remote_db_read_definition`, `f_remote_definition_tokens_replace` | 24 | — |
| `setup_dict` | associative | ✓ | — | L605 | `f_remote_instances_setup` | 14 | — |
| `yaml_keys` | indexed | ✗ | `yaml_keys_arr` | L593 | `f_dwt_sites`, `f_remote_instances_setup` | 3 | — |

### `asc/extensions/remote_db/remote/db_download.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `cmds` | indexed | ✗ | `cmds_arr` | L54 | `(top-level)`, `f_remote_db_prepare_dumps` | 14 | — |
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |

### `asc/extensions/remote_db/remote/db_dump.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `cmds` | indexed | ✗ | `cmds_arr` | L54 | `(top-level)`, `f_remote_db_prepare_dumps` | 14 | — |
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |

### `asc/extensions/remote_db/remote/db_list_dumps.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |

### `asc/extensions/remote_db/remote/db_restore.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |
| `instance_ids` | indexed | ✗ | `instance_ids_arr` | L64 | `(top-level)`, `f_db_restore_any` | 12 | — |

### `asc/extensions/remote_db/remote/db_upload.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |
| `instance_ids` | indexed | ✗ | `instance_ids_arr` | L64 | `(top-level)`, `f_db_restore_any` | 12 | — |

### `asc/extensions/remote_db/remote/remote.opt-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `cmds` | indexed | ✗ | `cmds_arr` | L54 | `(top-level)`, `f_remote_db_prepare_dumps` | 14 | — |
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |
| `dumps_dict` | associative | ✓ | — | L36 | `(top-level)` | 49 | Already compliant; remote_db scripts |
| `keys` | indexed | ✗ | `keys_arr` | L322 | `f_remote_db_read_definition`, `f_remote_definition_tokens_replace` | 24 | — |

### `asc/extensions/remote_instance/remote/init.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `hosts` | indexed | ✗ | `hosts_arr` | L47 | `(top-level)` | 6 | — |
| `hosts_with_user` | indexed | ✗ | `hosts_with_user_arr` | L49 | `(top-level)` | 4 | — |

### `asc/extensions/software/host/provision.opt-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `kept` | indexed | ✗ | `kept_arr` | L221 | `f_software_managed_remove` | 3 | — |
| `software_desired_ids` | indexed | ✗ | `software_desired_ids_arr` | L250 | `f_software_desired_ids` | 7 | — |
| `software_diff_extra` | indexed | ✗ | `software_diff_extra_arr` | L522 | `f_software_apply_prune`, `f_software_build_diff` | 3 | — |
| `software_diff_ids` | indexed | ✗ | `software_diff_ids_arr` | L469 | `f_software_build_diff` | 9 | — |
| `software_diff_status` | indexed | ✗ | `software_diff_status_arr` | L470 | `f_software_build_diff` | 9 | — |
| `software_managed_ids` | indexed | ✗ | `software_managed_ids_arr` | L195 | `f_software_build_diff`, `f_software_managed_load` | 4 | — |
| `software_manifest_files` | indexed | ✗ | `software_manifest_files_arr` | L75 | `f_software_load_manifests`, `f_software_manifest_paths` | 4 | — |
| `sw_appimage__id` | indexed | ✗ | `sw_appimage__id_arr` | L265 | `f_software_apply_installs`, `f_software_build_diff` | 3 | YAML manifest column array (parallel arrays by index) |
| `sw_appimage__path` | indexed | ✗ | `sw_appimage__path_arr` | L495 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_appimage__sha256` | indexed | ✗ | `sw_appimage__sha256_arr` | L496 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_appimage__url` | indexed | ✗ | `sw_appimage__url_arr` | L856 | `f_software_apply_installs` | 1 | YAML manifest column array (parallel arrays by index) |
| `sw_apt` | indexed | ✗ | `sw_apt_arr` | L248 | `f_software_build_diff`, `f_software_desired_ids` | 2 | — |
| `sw_ensure__command` | indexed | ✗ | `sw_ensure__command_arr` | L505 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_ensure__id` | indexed | ✗ | `sw_ensure__id_arr` | L270 | `f_software_apply_installs`, `f_software_build_diff` | 3 | YAML manifest column array (parallel arrays by index) |
| `sw_ensure__method` | indexed | ✗ | `sw_ensure__method_arr` | L877 | `f_software_apply_installs` | 1 | YAML manifest column array (parallel arrays by index) |
| `sw_pipx` | indexed | ✗ | `sw_pipx_arr` | L253 | `f_software_apply_installs`, `f_software_build_diff` | 3 | — |
| `sw_tarball__binary` | indexed | ✗ | `sw_tarball__binary_arr` | L486 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_tarball__id` | indexed | ✗ | `sw_tarball__id_arr` | L260 | `f_software_apply_installs`, `f_software_build_diff` | 3 | YAML manifest column array (parallel arrays by index) |
| `sw_tarball__install_dir` | indexed | ✗ | `sw_tarball__install_dir_arr` | L485 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_tarball__url` | indexed | ✗ | `sw_tarball__url_arr` | L836 | `f_software_apply_installs` | 1 | YAML manifest column array (parallel arrays by index) |
| `sw_tarball__version` | indexed | ✗ | `sw_tarball__version_arr` | L484 | `f_software_apply_installs`, `f_software_build_diff` | 2 | YAML manifest column array (parallel arrays by index) |
| `sw_units__enable` | indexed | ✗ | `sw_units__enable_arr` | L896 | `f_software_apply_installs` | 1 | YAML manifest column array (parallel arrays by index) |
| `sw_units__id` | indexed | ✗ | `sw_units__id_arr` | L275 | `f_software_apply_installs`, `f_software_build_diff` | 3 | YAML manifest column array (parallel arrays by index) |
| `sw_units__template` | indexed | ✗ | `sw_units__template_arr` | L895 | `f_software_apply_installs` | 1 | YAML manifest column array (parallel arrays by index) |

### `asc/git/find_changed_files.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `git_changed_files` | indexed | ✗ | `git_changed_files_arr` | L27 | `(top-level)` | 1 | — |

### `asc/git/git.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `args` | indexed | ✗ | `args_arr` | L472 | `f_git_get_unmerged_paths`, `f_thread_run_make_step` | 3 | — |
| `commit_arr` | indexed | ✓ | — | L302 | `f_git_find_commits` | 4 | — |
| `commits_to_sort` | associative | ✗ | `commits_to_sort_dict` | L506 | `f_git_mfind_commits` | 6 | — |
| `git_commits_dates` | indexed | ✗ | `git_commits_dates_arr` | L80 | `f_git_find_commits`, `f_git_log` | 6 | — |
| `git_commits_emails` | indexed | ✗ | `git_commits_emails_arr` | L79 | `f_git_find_commits`, `f_git_log` | 6 | — |
| `git_commits_hashes` | indexed | ✗ | `git_commits_hashes_arr` | L77 | `f_git_find_commits`, `f_git_log` | 6 | — |
| `git_commits_timestamps` | indexed | ✗ | `git_commits_timestamps_arr` | L81 | `f_git_find_commits`, `f_git_log` | 6 | — |
| `git_commits_titles` | indexed | ✗ | `git_commits_titles_arr` | L78 | `f_git_find_commits`, `f_git_log` | 6 | — |
| `git_hooks_whitelist` | indexed | ✗ | `git_hooks_whitelist_arr` | L639 | `f_git_write_hooks` | 23 | — |
| `k_split_arr` | indexed | ✓ | — | L539 | `f_git_mfind_commits` | 1 | — |
| `reversed_arr` | indexed | ✓ | — | L420 | `f_git_find_commits` | 11 | Output var documented in `f_array_*` @var blocks |
| `sorted_arr` | indexed | ✓ | — | L20 | `(top-level)`, `f_array_qsort` | 10 | Output var documented in `f_array_*` @var blocks |

### `asc/instance/fs_perms_set.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_action_scripts` | indexed | ✗ | `asc_action_scripts_arr` | L84 | `(top-level)`, `f_asc_get_actions` | 2 | — |
| `default_files` | indexed | ✗ | `default_files_arr` | L21 | `(top-level)` | 7 | — |

### `asc/instance/instance.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `GLOBALS` | associative | ✓ | — | L104 | `f_global_aggregate`, `f_global_list` | 38 | Capitalized global — excluded; keep `GLOBALS` as-is (see § Exclusions) |

### `asc/instance/list_actions.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_action_names` | indexed | ✗ | `asc_action_names_arr` | L18 | `(top-level)`, `f_asc_get_actions` | 2 | — |
| `sorted_arr` | indexed | ✓ | — | L20 | `(top-level)`, `f_array_qsort` | 10 | Output var documented in `f_array_*` @var blocks |

### `asc/instance/setup.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `purge_list_arr` | indexed | ✓ | — | L92 | `(top-level)` | 15 | — |

### `asc/instance/uninit.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `purge_list_arr` | indexed | ✓ | — | L92 | `(top-level)` | 15 | — |

### `asc/log/log.wrap.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |

### `asc/log/rotate.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `log_files` | indexed | ✗ | `log_files_arr` | L64 | `f_log_rotate_file` | 2 | — |

### `asc/loop/loop.wrap.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |

### `asc/make/call_wrap.make.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |

### `asc/make/list_entry_points.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `output` | indexed | ✗ | `output_arr` | L19 | `(top-level)` | 3 | — |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `sorted_arr` | indexed | ✓ | — | L20 | `(top-level)`, `f_array_qsort` | 10 | Output var documented in `f_array_*` @var blocks |

### `asc/make/make.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `tc_batch_dirs` | indexed | ✗ | `tc_batch_dirs_arr` | L414 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `tc_batch_scripts` | indexed | ✗ | `tc_batch_scripts_arr` | L415 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `tc_batch_tasks` | indexed | ✗ | `tc_batch_tasks_arr` | L411 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `tc_modes` | indexed | ✗ | `tc_modes_arr` | L413 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `tc_stems` | indexed | ✗ | `tc_stems_arr` | L412 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `tc_targets` | indexed | ✗ | `tc_targets_arr` | L410 | `f_make_generate_test_cases` | 3 | Local scratch in `f_make_generate_test_cases`; maps to `test_case_registry_*` cache |
| `test_case_registry_batch_dirs` | indexed | ✗ | `test_case_registry_batch_dirs_arr` | L475 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_batch_scripts` | indexed | ✗ | `test_case_registry_batch_scripts_arr` | L476 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_batch_tasks` | indexed | ✗ | `test_case_registry_batch_tasks_arr` | L472 | `f_make_generate_test_cases`, `f_test_run_case` | 4 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_modes` | indexed | ✗ | `test_case_registry_modes_arr` | L474 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_stems` | indexed | ✗ | `test_case_registry_stems_arr` | L473 | `f_make_generate_test_cases`, `f_test_run_case` | 4 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_targets` | indexed | ✗ | `test_case_registry_targets_arr` | L471 | `f_make_generate`, `f_make_generate_test_cases` | 5 | Emitted into generated cache `data/asc/cache/test-cases.sh` |

### `asc/test/core/global.test.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `GLOBALS` | associative | ✓ | — | L104 | `f_global_aggregate`, `f_global_list` | 38 | Capitalized global — excluded; keep `GLOBALS` as-is (see § Exclusions) |

### `asc/test/test.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `all_lines` | indexed | ✗ | `all_lines_arr` | L314 | `f_test_results_batch_end` | 5 | — |
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `test_case_registry_batch_dirs` | indexed | ✗ | `test_case_registry_batch_dirs_arr` | L475 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_batch_scripts` | indexed | ✗ | `test_case_registry_batch_scripts_arr` | L476 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_batch_tasks` | indexed | ✗ | `test_case_registry_batch_tasks_arr` | L472 | `f_make_generate_test_cases`, `f_test_run_case` | 4 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_modes` | indexed | ✗ | `test_case_registry_modes_arr` | L474 | `f_make_generate_test_cases`, `f_test_run_case` | 3 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_stems` | indexed | ✗ | `test_case_registry_stems_arr` | L473 | `f_make_generate_test_cases`, `f_test_run_case` | 4 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_case_registry_targets` | indexed | ✗ | `test_case_registry_targets_arr` | L471 | `f_make_generate`, `f_make_generate_test_cases` | 5 | Emitted into generated cache `data/asc/cache/test-cases.sh` |
| `test_results_tree_loaded` | indexed | ✗ | `test_results_tree_loaded_arr` | L188 | `f_test_results_batch_end`, `f_test_results_tree_load` | 3 | — |
| `test_results_tree_new` | indexed | ✗ | `test_results_tree_new_arr` | L214 | `f_test_results_batch_end`, `f_test_results_tree_put` | 3 | — |

### `asc/thread/list.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `yml_files` | indexed | ✗ | `yml_files_arr` | L21 | `(top-level)` | 2 | — |

### `asc/thread/status.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `thread_tree` | indexed | ✗ | `thread_tree_arr` | L53 | `(top-level)`, `f_thread_proc_tree` | 7 | — |

### `asc/thread/thread.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `_u_ta_ref` | nameref | ✗ | `_u_ta_ref_arr_nameref` | L456 | `f_thread_args_append` | 1 | `local -n` → indexed array via `$a_arr_name` |
| `args` | indexed | ✗ | `args_arr` | L472 | `f_git_get_unmerged_paths`, `f_thread_run_make_step` | 3 | — |
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `pids` | indexed | ✗ | `pids_arr` | L697 | `f_thread_run_batch` | 3 | — |
| `thread_entries` | indexed | ✗ | `thread_entries_arr` | L551 | `f_thread_parse_e_args`, `f_thread_run_batch` | 4 | — |
| `thread_entry_args` | indexed | ✗ | `thread_entry_args_arr` | L552 | `f_thread_parse_e_args`, `f_thread_run_batch` | 4 | — |
| `thread_stage_args` | indexed | ✗ | `thread_stage_args_arr` | L634 | `f_thread_parse_pipe_stages`, `f_thread_run_pipe` | 4 | — |
| `thread_stage_kind` | indexed | ✗ | `thread_stage_kind_arr` | L616 | `f_thread_parse_pipe_stages`, `f_thread_run_pipe` | 4 | — |
| `thread_stage_value` | indexed | ✗ | `thread_stage_value_arr` | L633 | `f_thread_parse_pipe_stages`, `f_thread_run_pipe` | 4 | — |
| `thread_tree` | indexed | ✗ | `thread_tree_arr` | L53 | `(top-level)`, `f_thread_proc_tree` | 7 | — |
| `y_sc` | associative | ✗ | `y_sc_dict` | L75 | `f_thread_host_publish`, `f_thread_yml_write` | 2 | YAML scalar cache dict; used in thread + yml |

### `asc/thread/thread.wrap.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `make_entries` | indexed | ✗ | `make_entries_arr` | L751 | `(top-level)`, `f_make_check_args` | 32 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `real_scripts` | indexed | ✗ | `real_scripts_arr` | L50 | `(top-level)`, `f_make_check_args` | 27 | Wrap-script contract; sourced across make/log/loop/thread wraps |
| `thread_tree` | indexed | ✗ | `thread_tree_arr` | L53 | `(top-level)`, `f_thread_proc_tree` | 7 | — |

### `asc/utils/arr/arr.opt-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `__p` | nameref | ✗ | `__p_nameref` | L204 | `f_array_print` | 1 | `declare -n`; polymorphic array target |
| `array` | associative | ✗ | `array_dict` | L141 | `f_array_ksort` | 1 | Caller-scope `@var` in docs/examples — associative keys |
| `array_keys` | indexed | ✗ | `array_keys_arr` | L137 | `f_array_ksort` | 1 | — |
| `haystack_var_name` | — | — | — | L59 | `f_array_add_once` | 1 | String param (scalar); excluded — holds name of caller array |
| `larger` | indexed | ✗ | `larger_arr` | L97 | `f_array_qsort` | 2 | — |
| `reversed_arr` | indexed | ✓ | — | L420 | `f_git_find_commits` | 11 | Output var documented in `f_array_*` @var blocks |
| `smaller` | indexed | ✗ | `smaller_arr` | L95 | `f_array_qsort` | 2 | — |
| `sorted_arr` | indexed | ✓ | — | L20 | `(top-level)`, `f_array_qsort` | 10 | Output var documented in `f_array_*` @var blocks |
| `stack` | indexed | ✗ | `stack_arr` | L83 | `f_array_qsort` | 6 | — |
| `tmp_arr` | indexed | ✓ | — | L175 | `f_array_reverse` | 1 | — |

### `asc/utils/fs/fs.opt-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `contents_list_arr` | indexed | ✓ | — | L877 | `f_fs_extract` | 2 | — |
| `file_list_arr` | indexed | ✓ | — | L470 | `(top-level)`, `f_fs_file_list` | 4 | — |

### `asc/utils/str/str.opt-inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `split_arr` | indexed | ✓ | — | L235 | `f_str_basic_auth_credentials` | 2 | — |

### `asc/yml/yml.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `__yaml_keys` | nameref | ✗ | `__yaml_keys_arr_nameref` | L272 | `f_yaml_write` | 1 | `declare -n`; was misclassified as indexed array |
| `__yaml_list` | nameref | ✗ | `__yaml_list_arr_nameref` | L284 | `f_yaml_write` | 1 | `declare -n` in loop over list sections |
| `__yaml_scalars` | nameref | ✗ | `__yaml_scalars_dict_nameref` | L273 | `f_yaml_write` | 1 | `declare -n` → associative `$a_scalars_name` |
| `y_sc` | associative | ✗ | `y_sc_dict` | L75 | `f_thread_host_publish`, `f_thread_yml_write` | 2 | YAML scalar cache dict; used in thread + yml |

### `scripts/asc/contrib/asc/apache/apache.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |

### `scripts/asc/contrib/asc/drupalwt/app/ensure_dirs_exist.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dwt_sites_ids` | indexed | ✗ | `dwt_sites_ids_arr` | L51 | `f_dwt_write_drupal_settings`, `f_dwt_write_multisite_settings` | 9 | Contrib drupalwt extension |
| `dwt_sites_writeable_paths` | indexed | ✗ | `dwt_sites_writeable_paths_arr` | L404 | `(top-level)`, `f_dwt_get_sites_writeable_paths` | 5 | Contrib drupalwt extension |

### `scripts/asc/contrib/asc/drupalwt/app/fs_perms_set.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dwt_sites_ids` | indexed | ✗ | `dwt_sites_ids_arr` | L51 | `f_dwt_write_drupal_settings`, `f_dwt_write_multisite_settings` | 9 | Contrib drupalwt extension |
| `dwt_sites_writeable_paths` | indexed | ✗ | `dwt_sites_writeable_paths_arr` | L404 | `(top-level)`, `f_dwt_get_sites_writeable_paths` | 5 | Contrib drupalwt extension |

### `scripts/asc/contrib/asc/drupalwt/app/twig_debug.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dwt_sites_ids` | indexed | ✗ | `dwt_sites_ids_arr` | L51 | `f_dwt_write_drupal_settings`, `f_dwt_write_multisite_settings` | 9 | Contrib drupalwt extension |

### `scripts/asc/contrib/asc/drupalwt/db/set_multi_db_ids.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `dwt_sites_ids` | indexed | ✗ | `dwt_sites_ids_arr` | L51 | `f_dwt_write_drupal_settings`, `f_dwt_write_multisite_settings` | 9 | Contrib drupalwt extension |

### `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |
| `dwt_site_data` | associative | ✗ | `dwt_site_data_dict` | L680 | `f_dwt_site_data` | 2 | Contrib drupalwt extension |
| `dwt_sites_ids` | indexed | ✗ | `dwt_sites_ids_arr` | L51 | `f_dwt_write_drupal_settings`, `f_dwt_write_multisite_settings` | 9 | Contrib drupalwt extension |
| `dwt_sites_writeable_paths` | indexed | ✗ | `dwt_sites_writeable_paths_arr` | L404 | `(top-level)`, `f_dwt_get_sites_writeable_paths` | 5 | Contrib drupalwt extension |
| `multisite_writeable_paths_varnames` | indexed | ✗ | `multisite_writeable_paths_varnames_arr` | L385 | `f_dwt_write_drupal_settings` | 6 | — |
| `unique_db_ids` | indexed | ✗ | `unique_db_ids_arr` | L115 | `f_dwt_write_drupal_settings`, `f_moodle_write_settings` | 5 | — |
| `yaml_keys` | indexed | ✗ | `yaml_keys_arr` | L593 | `f_dwt_sites`, `f_remote_instances_setup` | 3 | — |

### `scripts/asc/contrib/asc/drush/instance/wait_for.compose.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |
| `unique_db_ids` | indexed | ✗ | `unique_db_ids_arr` | L115 | `f_dwt_write_drupal_settings`, `f_moodle_write_settings` | 5 | — |

### `scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `ADDR` | indexed | ✗ | `ADDR_arr` | L45 | `(top-level)` | 1 | — |
| `skip_data` | indexed | ✗ | `skip_data_arr` | L42 | `(top-level)` | 4 | — |
| `tables` | indexed | ✗ | `tables_arr` | L50 | `(top-level)` | 1 | — |

### `scripts/asc/contrib/asc/mysql/db/exec.mysql.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `file_list_arr` | indexed | ✓ | — | L470 | `(top-level)`, `f_fs_file_list` | 4 | — |

### `scripts/asc/contrib/asc/mysql/instance/wait_for.compose.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `scripts/asc/contrib/asc/ollama/gpt/stop_all.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `a_running` | indexed | ✗ | `a_running_arr` | L20 | `(top-level)` | 3 | — |

### `scripts/asc/contrib/asc/pgsql/instance/wait_for.compose.hook.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `db_ids` | indexed | ✗ | `db_ids_arr` | L53 | `(top-level)`, `f_remote_db_prepare_downloads` | 38 | — |

### `scripts/asc/contrib/asc/remote_traefik/host/systemd_service_setup.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |

### `scripts/asc/contrib/asc/remote_traefik/remote_traefik.inc.sh`

| Variable | Type | OK | Suggested | First line | Function | Sites | Notes |
|----------|------|----|-----------|------------|----------|-------|-------|
| `asc_globals_var_names` | indexed | ✗ | `asc_globals_var_names_arr` | L64 | `f_apache_write_vhost_conf`, `f_global_list` | 7 | — |

---

## Recommended migration order

All clusters below were migrated in this session (2026-07-31).

1. **`asc/utils/arr/arr.opt-inc.sh`** — ✓ canonical array helpers; doc examples updated (`my_array_arr`, `array_dict`, `__p_nameref`); `stack_arr` declaration fixed.
2. **Nameref cluster** — ✓ `asc/yml/yml.inc.sh` (`__yaml_*_*_nameref`), `asc/thread/thread.inc.sh` (`_u_ta_ref_arr_nameref`); `asc/asc/hook.inc.sh` already had `a_out_arr_nameref`.
3. **Wrong-suffix fix** — ✓ `declaration_arr` → `declaration_dict` in `asc/asc/global.inc.sh`.
4. **Remote DB scripts** — ✓ `dumps_dict` unchanged (already compliant); `cmds_arr`, `db_ids_arr`, `keys_arr` migrated.
5. **Self-contained modules** — ✓ `asc/git/git.inc.sh`, `asc/extensions/crontab/crontab.inc.sh`, `asc/log/`.
6. **Make / test codegen** — ✓ `make_entries_arr`, `real_scripts_arr`, `test_case_registry_*_arr`, `tc_*_arr` in generators; **regenerate** `data/asc/cache/test-cases.sh` and `data/asc/cache/make.sh` on next `make` reinit (cache absent in workspace at migration time).
7. **Contrib** — ✓ `scripts/asc/contrib/**`.

**Out of migration scope:** `GLOBALS`, `GLOBALS_DEFERRED`, `GLOBALS_UNIQUE_KEYS`, `GLOBALS_UNIQUE_NAMES` — left unchanged (verified).

### Implementation notes (2026-07-31)

- ~84 files touched (981 insertions / 981 deletions per `git diff --stat`).
- Short-name false positives corrected manually: crontab scalar `args` (not `args_arr`), test scalar `output`, YAML dict keys `args`/`output` in `y_sc_dict[…]`, comment/doc prose.
- `local X=()` declarations that the bulk pass missed (multi-token `local` lines, e.g. `stack`, `files`, `keys`) were fixed by follow-up scan.
- String params holding variable **names** (`haystack_var_name`, `a_arr_name`, …) left without suffix per § Exclusions.

### Open tasks

- [x] Rename all inventoried variables (108 symbols)
- [x] Update `@var` / `@example` blocks in `arr.opt-inc.sh`
- [ ] Regenerate `data/asc/cache/test-cases.sh` (and `make.sh`) after next instance reinit / `f_make_generate`
- [ ] Add array/dict/nameref naming rules to `.cursor/rules/naming.mdc` once convention is locked
- [x] Re-run audit commands below (post-migration spot-check)

---

## Repeatable audit commands

Run from repo root `/home/paul/Documents/asc`. Adjust excludes as needed.

```bash
# Nameref declarations
rg -n '\b(declare|local|readonly)\s+-n\b' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' --glob '!**/vendor/**' .

# Compliant nameref suffix check
rg -n '\b(declare|local|readonly)\s+-n [a-zA-Z_][a-zA-Z0-9_]*(_arr_nameref|_dict_nameref|_nameref)\b' \
  --glob '!asc/vendor/**' .

# Likely non-compliant namerefs (no _nameref suffix)
rg -n '\b(declare|local|readonly)\s+-n [a-zA-Z_][a-zA-Z0-9_]*\b' \
  --glob '!asc/vendor/**' . | rg -v '_arr_nameref|_dict_nameref|_nameref'

# Explicit declarations
rg -n 'declare -[aA]|local -[aA]|readonly -[aA]' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' --glob '!**/vendor/**' .

# Array assignments and appends
rg -n '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\+?=\(|\+?=\(' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# Array expansions
rg -n '\$\{[a-zA-Z_][a-zA-Z0-9_]*\[@\]|\$\{[a-zA-Z_][a-zA-Z0-9_]*\[\*|\$\{#[a-zA-Z_][a-zA-Z0-9_]*\[@\]|\$\{![a-zA-Z_][a-zA-Z0-9_]*\[@\]' \
  --glob '*.sh' --glob '*.inc.sh' --glob '*.opt-inc.sh' \
  --glob '!asc/vendor/**' .

# Compliant suffix check (indexed)
rg -n 'declare -a [a-zA-Z_][a-zA-Z0-9_]*_arr|local -a [a-zA-Z_][a-zA-Z0-9_]*_arr' \
  --glob '!asc/vendor/**' .

# Compliant suffix check (associative)
rg -n 'declare -A [a-zA-Z_][a-zA-Z0-9_]*_dict|local -A [a-zA-Z_][a-zA-Z0-9_]*_dict' \
  --glob '!asc/vendor/**' .

# Likely non-compliant (no _arr/_dict suffix on declare)
rg -n 'declare -[aA] [a-zA-Z_][a-zA-Z0-9_]*[^t]\b' \
  --glob '!asc/vendor/**' . | rg -v '_arr|_dict|GLOBALS|GLOBALS_'
```

Optional: re-run the Python inventory script used for this doc (stored in audit session); compare distinct var counts against § Summary.
