# Inventory: subshell capture candidates for `printf -v` migration

| Field | Value |
|-------|--------|
| **Date** | 2026-07-31 |
| **Status** | inventory / review (docs only — no code changes) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — subshell usages that capture function/command output, as candidates for the output-variable / `printf -v` pattern |
| **Related** | `asc/utils/str/str.opt-inc.sh` (`f_str_convert_tokens`, lines 143–144); `asc/utils/fs/fs.opt-inc.sh` (`f_fs_get_file_contents`, line 287); `changelog/2026/07/23-f-e-naming-convention.md` (`f_*` naming) |
| **Lifecycle** | Review this inventory; pick functions or hotspots to migrate in focused changes. Do **not** treat this file as permission for a repo-wide mechanical rewrite. |

---

## Context

ASC already uses an output-variable convention in several utilities: the callee takes a **variable name** as a parameter and writes the result with `printf -v "$a_output_var_name" '%s' "$value"` instead of `echo` + caller `$(…)`.

Reference implementation — `f_str_convert_tokens()` in `asc/utils/str/str.opt-inc.sh`:

```142:144:asc/utils/str/str.opt-inc.sh
  # Write result to var in calling scope.
  printf -v "$a_output_var_name" '%s' "$tokens_replaced"
```

**Convention observed in migrated functions:**

| Aspect | Pattern |
|--------|---------|
| Output param | Second (or last) positional arg: `a_output_var_name`, `a_var_name`, etc. |
| Default var name | Sometimes derived from input (e.g. lowercase of input var in `f_str_convert_tokens`) |
| Caller usage | `f_str_convert_tokens ASC_DB_DUMPS_LOCAL_PATTERN 'my_var'` then `"$my_var"` — no subshell |
| Docs | `@param` documents output var; `@example` shows direct read after call |
| Collision note | Some functions document a fixed `@var` when no param is passed (legacy; prefer explicit output arg) |

**Goal of this inventory:** list remaining `$(f_* …)` (and related echo-return patterns) so migrations can be planned function-by-function rather than discovered ad hoc.

---

## Methodology

Searched `*.sh` under the ASC repo (excluding `asc/vendor/`) for:

- `$(f_* …)` — primary signal ( **162 capture sites**, **39 distinct `f_*` functions** )
- `echo "$(f_* …)"` — nested subshell inside echo-return wrappers (3 sites)
- `` `f_* …` `` — none found outside vendor
- Functions whose bodies use `echo` to stdout (return value) vs existing `printf -v`
- Known internal nested subshells inside utility bodies

**Not exhaustively listed:** bare `$(date …)`, `$(id -u)`, `$(find …)`, `$(mktemp …)`, etc. — external commands where `printf -v` is usually not the right tool (noted briefly at end).

---

## Summary

| Category | Functions | Capture sites | Migration fit |
|----------|-----------|---------------|---------------|
| **A — High-volume echo `f_*`** | 4 | 75 | Excellent — single-value string return |
| **B — String / path utilities** | 12 | 35 | Good — straightforward output-var API |
| **C — YAML / multi-var eval** | 1 | 10 | Poor direct fit — needs different API |
| **D — Git / remote wrappers** | 4 | 10 | Mixed — may need exit status + stdout |
| **E — Test helpers** | 6 | 17 | Good — mostly path/string builders |
| **F — Internal nested subshells** | 5 | 5 | Fix at function body (no caller change) |
| **G — Generated / bootstrap literals** | — | 8 | Deferred — eval-time or codegen context |
| **Already migrated (`printf -v`)** | ~15 | 33 call sites | Reference only — callers may still use `$()` in a few places |

**Hotspots (files with most `$(f_*` captures):**

1. `asc/extensions/software/host/provision.opt-inc.sh` — **47** sites
2. `asc/extensions/crontab/crontab.inc.sh` — **27** sites
3. `asc/test/test.inc.sh` — **16** sites
4. `asc/extensions/db/db.inc.sh` — **6** sites

---

## Already migrated (reference)

These functions already write via `printf -v` (33 occurrences across 12 files). New echo-based utilities should follow the same pattern.

| Function | File | Notes |
|----------|------|-------|
| `f_str_convert_tokens` | `asc/utils/str/str.opt-inc.sh:143` | Canonical reference |
| `f_str_escape_single_quotes` | `asc/utils/str/str.opt-inc.sh:182` | |
| `f_str_sanitize_var_name` | `asc/utils/str/str.opt-inc.sh:269` | |
| `f_str_sanitize` | `asc/utils/str/str.opt-inc.sh:320` | |
| `f_str_lowercase` / `f_str_uppercase` | `asc/utils/str/str.opt-inc.sh:405,432` | |
| `f_fs_get_file_contents` | `asc/utils/fs/fs.opt-inc.sh:287` | Doc explicitly says "without subshell" |
| `f_fs_change_line` (partial) | `asc/utils/fs/fs.opt-inc.sh:774` | |
| `f_yaml_escape_double` | `asc/yml/yml.inc.sh:229` | |
| `f_global_assign_value` | `asc/asc/global.inc.sh:490–541` | |
| `f_asc_extension_namespace` | `asc/asc/core.inc.sh:434` | |
| `f_hook_variant_values_add` | `asc/asc/hook.inc.sh:796` | |
| `f_make_unescape` / `f_make_task_name` | `asc/make/make.inc.sh:98,393` | |
| `f_thread_output_mtime_ms` | `asc/thread/thread.inc.sh:359–363` | |
| `f_thread_yml_strip_quotes` | `asc/thread/thread.inc.sh:201–202` | |
| Remote token replace | `asc/extensions/remote/remote.inc.sh:868–880` | |

**Remaining subshell at already-migrated call sites:**

| File | Line | Issue |
|------|------|-------|
| `asc/utils/fs/fs.opt-inc.sh` | 629 | `local new_str="$(f_str_append_once …)"` — callee still echoes |
| `asc/utils/fs/fs.opt-inc.sh` | 649 | `local new=$(f_str_sed_escape …)` — callee still echoes |
| `asc/make/make.inc.sh` | 435 | `case_target="$(f_test_case_make_target …)"` — nested `$()` inside echo-based helper |

---

## Category A — High-volume echo `f_*` (best candidates)

### `f_software_scalar` — 32 capture sites

| | |
|---|---|
| **Definition** | `asc/extensions/software/host/provision.opt-inc.sh:19–28` — strips yaml quote artifacts, `echo "$out"` |
| **Hotspot** | Same file: lines 38, 249, 254, 260, 265, 270, 275, 466, 474, 483–496, 504–515, 595, 752, 808, 826, 835–838, 847, 856–858, 867, 876–877, 886, 895–896, … |
| **Fit** | **Excellent** — always single scalar string |
| **Caveats** | High churn file; migrate definition first, then bulk-update callers in one pass |

### `f_cron_scalar` — 19 capture sites (+ 3 in generated cron entry scripts)

| | |
|---|---|
| **Definition** | `asc/extensions/crontab/crontab.inc.sh:171–179` — uses `printf '%s'` to stdout (not yet `printf -v`) |
| **Call sites** | `crontab.inc.sh:233–238,246,352–360`; generated exports at `415–417` (literal `$(f_cron_scalar …)` embedded in heredoc output — subshell runs when entry script is sourced) |
| **Fit** | **Excellent** — identical to `f_software_scalar` |
| **Caveats** | Lines 415–417 are **codegen**, not live shell; migration must update the heredoc template |

### `f_test_results_root` — 12 capture sites

| | |
|---|---|
| **Definition** | `asc/test/test.inc.sh:96–97` — already `printf '%s'` (no subshell in callee, but callers still fork) |
| **Call sites** | `test.inc.sh:124,126,139,140,242,301,320,363,385,388,454,455` |
| **Fit** | **Excellent** — trivial constant path |
| **Caveats** | Often embedded in path concatenation; `printf -v root …` then `"${root}/frozen/…"` is clean |

### `f_fs_get_most_recent` — 12 capture sites

| | |
|---|---|
| **Definition** | `asc/utils/fs/fs.opt-inc.sh:228–252` — `find … \| head` to stdout; may return multiple lines |
| **Call sites** | `db.inc.sh:1126,1268,1280,1433,1442,1472`; `db.opt-inc.sh:76`; `db_upload.sh:111`; `remote.opt-inc.sh:204`; `fs.opt-inc.sh` examples in comments |
| **Fit** | **Good** — single-file callers expect one path; multi-line callers use `while read` in docs |
| **Caveats** | Preserve multi-line behaviour; document whether output var holds newline-separated list |

---

## Category B — String / path utilities

### `f_str_*` (echo-return, not yet output-var)

| Function | Def | Captures | Fit | Notes |
|----------|-----|----------|-----|-------|
| `f_str_basic_auth_credentials` | `str.opt-inc.sh:215–242` | 6 | Good | Side effects (registry read/write); output-var still fine |
| | | `global.vars.sh` (moodle, traefik, d4d contrib) | | Used in `global … "[default]=$(…)"` bootstrap literals |
| `f_str_random` | `str.opt-inc.sh:568–575` | 3 | Good | urandom pipeline; also backtick subshell inside `f_str_basic_auth_credentials:231` |
| `f_str_slug` | `str.opt-inc.sh:596–610` | 4 | Good | Pipeline via `echo \| iconv \| sed`; used in `host.inc.sh:147–148` internally |
| `f_str_append_once` | `str.opt-inc.sh:513–526` | 4 | **Already marked TODO [opti]** | `echo -n`; docs show `$()` pattern |
| `f_str_sed_escape` | `str.opt-inc.sh:488–496` | 2 | **Already marked TODO [opti]** | Used inside `fs.opt-inc.sh:649` |
| `f_str_trim` | `str.opt-inc.sh:638–639` | 1 (docs) | Good | **Nested subshell in body** — see Category F |

### `f_host_*` / `f_print_current_user`

| Function | Def | Captures | Fit | Notes |
|----------|-----|----------|-----|-------|
| `f_host_os` | `host.inc.sh:114–153` | 1 | Good | `env/global.vars.sh:37`; internally calls `$(f_str_slug …)` twice |
| `f_host_ip` | `host.inc.sh:94–104` | 1 | Good | Pipeline to stdout; `instance.inc.sh:694` |
| `f_print_current_user` | `shell.opt-inc.sh:15–16` | 4 | Good | `logname \|\| echo`; thread/log/traefik call sites |

### `f_cron_*` (other)

| Function | Def | Captures | Fit | Notes |
|----------|-----|----------|-----|-------|
| `f_cron_project_marker` | `crontab.inc.sh:463–464` | 5 | Excellent | Constant path; also embedded in generated crontab line `538` |
| `f_cron_crontab_list` | `crontab.inc.sh:480–481` | 2 | Mixed | Wraps external `crontab -l`; output-var avoids subshell but not external cmd |
| `f_cron_entry_crontab_lines` | `crontab.inc.sh:527–541` | 2 | Mixed | Multi-line; uses `printf '%s\n'` — nameref array or output var with newlines |

### `f_software_*` (other)

| Function | Def | Captures | Fit | Notes |
|----------|-----|----------|-----|-------|
| `f_software_expand_path` | `provision.opt-inc.sh:34–46` | 4 | Good | Internally `$(f_software_scalar …)` — fix both |
| `f_software_managed_path` | `provision.opt-inc.sh:144–145` | 3 | Excellent | Returns fixed string |
| `f_software_*_status` | `provision.opt-inc.sh:299–433` | 6 | Good | Returns `'ok'` / `'missing'` / version strings |
| `f_software_apt_status` | :299 | 1 | Good | |
| `f_software_pipx_status` | :314 | 2 | Good | |
| `f_software_tarball_status` | :353 | 1 | Good | |
| `f_software_appimage_status` | :388 | 1 | Good | |
| `f_software_ensure_status` | :413 | 1 | Good | |
| `f_software_unit_status` | :426 | 1 | Good | |

### `f_asc_*` / `f_hook_*`

| Function | Def | Captures | Fit | Notes |
|----------|-----|----------|-----|-------|
| `f_asc_extensions_get_makefiles` | `core.inc.sh:561–577` | 2 | Good | Space-separated list; `env/global.vars.sh:44` bootstrap |
| `f_hook_resolve_source_path` | `hook.inc.sh:881–889` | 3 | Excellent | Single path |
| `f_provision_using_lookup_values` | `hook.inc.sh:759–771` | 3 | Mixed | Uses `printf '%s'`; captured in `for x in $(…)` — word-splitting; prefer nameref array or read loop |

### `f_thread_delay_seconds`

| | |
|---|---|
| **Definition** | `thread.inc.sh:320–332` — `echo` integer seconds |
| **Capture** | `thread.wrap.sh:171` |
| **Fit** | Excellent |

### `f_instance_domain`

| | |
|---|---|
| **Definition** | `instance.inc.sh:690–709` — composes domain; internally `$(f_host_ip)` |
| **Capture** | Comment example only in inventory grep; live nested subshell at :694 |
| **Fit** | Good once `f_host_ip` migrated |

---

## Category C — YAML parse / multi-variable eval (poor `printf -v` fit)

### `f_yaml_parse` — 10 capture sites

| File | Line(s) | Pattern |
|------|---------|---------|
| `asc/thread/thread.inc.sh` | 141 | `eval "$(f_yaml_parse "$a_yml" 'thread_')"` |
| `asc/thread/monitor.hook.sh` | 60 | `eval "$(f_yaml_parse …)"` |
| `asc/instance/reinit.sh` | 71 | `eval "$(f_yaml_parse 'env.yml' 'yaml_')"` |
| `asc/extensions/crontab/crontab.inc.sh` | 231, 347 | `eval "$(f_yaml_parse …)"` |
| `asc/extensions/software/host/provision.opt-inc.sh` | 134 | `parsed="$(f_yaml_parse …)"` then eval? |
| `asc/extensions/remote/remote.inc.sh` | 574 | `local parsed_yaml_remotes="$(f_yaml_parse …)"` |
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | 566 | assignment (contrib) |

**Definition:** `asc/yml/yml.inc.sh:85–95` — delegates to `parse_yaml`, emits shell `declare`/`assign` statements for `eval`.

**Fit:** **Not a `printf -v` candidate** — produces many variables, not one string. Alternatives: nameref / associative array API, or keep `eval` but stream into caller without subshell (process substitution + source).

---

## Category D — Git / remote wrappers

### `f_git_get_staged_files` / `f_git_get_unmerged_paths`

| | |
|---|---|
| **Definition** | `git.inc.sh:741,777` — `echo "$(f_git_wrapper diff …)"` (**double subshell**) |
| **Captures** | `pre-commit.hook.sh:22`; comment examples in `git.inc.sh` |
| **Fit** | Good after inlining git call or output-var on wrapper |
| **Caveats** | Multi-line file list; may need newline preservation |

### `f_git_wrapper` (inside echo wrappers)

| | |
|---|---|
| **Captures** | 3 subshells inside `f_git_get_*` bodies |
| **Fit** | Fix at `f_git_get_*` level |

### `f_remote_exec_wrapper`

| | |
|---|---|
| **Captures** | `remote_db/remote/db_restore.sh:93`, `remote.opt-inc.sh:204` |
| **Fit** | Mixed — remote command execution; may need **exit status** and stderr, not just stdout string |

### `f_db_get_dump`

| | |
|---|---|
| **Definition** | `db.inc.sh:1246–1286` — internally `$(f_fs_get_most_recent …)` then `echo` |
| **Fit** | Good — chain migration with `f_fs_get_most_recent` |

---

## Category E — Test helpers (`asc/test/test.inc.sh`)

| Function | Line | Captures | Returns | Fit |
|----------|------|----------|---------|-----|
| `f_test_results_root` | 96 | 12 | path | Excellent (see A) |
| `f_test_case_stem_to_suffix` | 495 | 1 (via `f_test_case_make_target`) | string | Excellent |
| `f_test_case_make_target` | 506 | 1 (`make.inc.sh:435`) | string | Excellent — nested `$()` |
| `f_test_case_runner_path` | 520 | 1 | path | Excellent |
| `f_test_batch_dir_from_script` | 476 | 1 | path | Excellent |
| `f_test_read_manifest_cases` | 530 | 1 | space-sep stems | Good — `echo -n` |

---

## Category F — Internal nested subshells (fix in function body)

These are not caller `$()` sites but subshells **inside** utilities that echo results.

| File | Line | Function | Pattern | Fix |
|------|------|----------|---------|-----|
| `asc/utils/str/str.opt-inc.sh` | 639 | `f_str_trim` | `echo "$(echo -e "$1" \| sed …)"` | Parameter expansion / `printf -v` |
| `asc/utils/str/str.opt-inc.sh` | 89 | `f_str_convert_tokens` | `val="$(date +"$match")"` | Acceptable? or inline date into var without subshell |
| `asc/utils/str/str.opt-inc.sh` | 231 | `f_str_basic_auth_credentials` | `` a_pass=`< /dev/urandom …` `` | Backtick subshell for password gen |
| `asc/git/git.inc.sh` | 741, 777 | `f_git_get_staged_files`, `f_git_get_unmerged_paths` | `echo "$(f_git_wrapper …)"` | Call wrapper with output var |
| `asc/utils/fs/fs.opt-inc.sh` | 629, 649 | `f_fs_append_line_once`, `f_fs_change_line` | `$(f_str_append_once …)`, `$(f_str_sed_escape …)` | Migrate str helpers first |

---

## Category G — Bootstrap / codegen literals (defer or special-case)

| File | Line | Pattern | Notes |
|------|------|---------|-------|
| `asc/env/global.vars.sh` | 37, 44 | `global HOST_OS "$(f_host_os)"` | Evaluated when globals aggregate — subshell at init |
| `scripts/asc/contrib/asc/*/global.vars.sh` | various | `$(f_str_basic_auth_credentials …)`, `$(f_str_random …)` | Same bootstrap pattern |
| `asc/extensions/crontab/crontab.inc.sh` | 415–417 | `'$(f_cron_scalar …)'` in heredoc | Becomes live subshell in generated `data/asc/cron/*.sh` |
| `asc/extensions/crontab/crontab.inc.sh` | 538 | `` `$(f_cron_project_marker)` `` in crontab line string | String built for host crontab |

**Fit:** Migrate underlying `f_*` first; bootstrap files may still need subshell unless `global` macro gains non-subshell expansion.

---

## Other subshell patterns (lower priority)

Not `f_*` captures, but common in ASC — usually **not** `printf -v` candidates:

| Pattern | Example locations | Notes |
|---------|-------------------|-------|
| `$(date …)` | `thread.wrap.sh`, `log/storage.hook.sh`, `loop.wrap.sh` | External cmd; keep or cache in var inline |
| `$(id -u)` / `$(id -un)` | `thread.inc.sh`, `compose/global.vars.sh` | Cheap; low benefit |
| `$(find …)` / `$(realpath …)` | `fs.opt-inc.sh:345+`, `thread.wrap.sh:71` | External; process substitution alternative |
| `$(mktemp -d)` | tests, software provision | Needs cmd substitution |
| `for i in $(seq …)` | tests, shell utils | Iterator; different problem |
| `eval "$(parse_yaml …)"` | `asc/vendor/bash-yaml` | Vendor |

---

## Recommended migration order

1. **Leaf scalars with highest fan-out:** `f_software_scalar`, `f_cron_scalar`, `f_test_results_root`
2. **Str utilities with existing TODO:** `f_str_append_once`, `f_str_sed_escape`, then fix `fs.opt-inc.sh` callers
3. **Path constants:** `f_cron_project_marker`, `f_software_managed_path`, `f_hook_resolve_source_path`
4. **Status enums:** `f_software_*_status`
5. **Filesystem:** `f_fs_get_most_recent` → unblock `f_db_get_dump` chain
6. **Host/shell:** `f_print_current_user`, `f_host_os`, `f_host_ip`, `f_str_slug`
7. **Git wrappers:** collapse double subshell in `f_git_get_*`
8. **Test helpers:** batch in `test.inc.sh`
9. **Defer:** `f_yaml_parse` / eval family, `f_remote_exec_wrapper`, bootstrap `global.vars.sh` literals

---

## Open tasks

- [ ] Agree output-param naming convention extension-wide (always explicit 2nd arg vs optional default `@var`)
- [ ] Pilot: migrate `f_cron_scalar` + `f_software_scalar` (largest payoff)
- [ ] Add shunit2 cases asserting output-var and `$()` paths produce identical results during transition
- [ ] Design replacement for `eval "$(f_yaml_parse …)"` (separate from `printf -v` work)
- [ ] Update `f_str_append_once` / `f_str_sed_escape` docblocks — remove TODO once migrated
- [ ] Re-run ripgrep audit after each wave: `rg '\$\(f_' --glob '*.sh' asc scripts | rg -v vendor`

---

## Audit command (repeatable)

```bash
cd /home/paul/Documents/asc
rg -o '\$\(f_[a-zA-Z0-9_]+' --glob '*.sh' | rg -v vendor | sed 's/^.*://' | sort | uniq -c | sort -rn
rg -n '\$\(f_' --glob '*.sh' | rg -v vendor | rg -v '^\S+:\d+:#' | cut -d: -f1 | sort | uniq -c | sort -rn
rg -n 'printf -v' --glob '*.sh' asc
```
