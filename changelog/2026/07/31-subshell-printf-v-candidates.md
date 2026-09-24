# Inventory: subshell capture candidates for `printf -v` migration

| Field | Value |
|-------|--------|
| **Date** | 2026-07-31 |
| **Status** | partial implementation — waves 1–8 done (2026-09-22). **`eval` / `f_yaml_parse` design written** (2026-09-22; implementation still needs a later gates row). Bootstrap `global.vars.sh` captures deferred (category G). |
| **Scope** | ASC repo `/home/paul/Documents/asc` — subshell usages that capture function/command output, as candidates for the output-variable / `printf -v` pattern |
| **Related** | `asc/core/utils/str/str.opt-inc.sh` (`f_str_convert_tokens`, lines 143–144); `asc/core/utils/fs/fs.opt-inc.sh` (`f_fs_get_file_contents`, line 287); `changelog/2026/07/23-f-e-naming-convention.md` (`f_*` naming) |
| **Lifecycle** | Waves 1–8 migrated by 2026-09-22. Category C **design** accepted 2026-09-22 (keep `eval` until a later implementation go-ahead). Bootstrap `global … "$(f_*)"` literals stay deferred (category G). Do **not** treat this file as permission for a repo-wide mechanical rewrite. |

---

## Context

ASC already uses an output-variable convention in several utilities: the callee takes a **variable name** as a parameter and writes the result with `printf -v "$a_output_var_name" '%s' "$value"` instead of `echo` + caller `$(…)`.

Reference implementation — `f_str_convert_tokens()` in `asc/core/utils/str/str.opt-inc.sh`:

```142:144:asc/core/utils/str/str.opt-inc.sh
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
| `f_str_convert_tokens` | `asc/core/utils/str/str.opt-inc.sh:143` | Canonical reference |
| `f_str_escape_single_quotes` | `asc/core/utils/str/str.opt-inc.sh:182` | |
| `f_str_sanitize_var_name` | `asc/core/utils/str/str.opt-inc.sh:269` | |
| `f_str_sanitize` | `asc/core/utils/str/str.opt-inc.sh:320` | |
| `f_str_lowercase` / `f_str_uppercase` | `asc/core/utils/str/str.opt-inc.sh:405,432` | |
| `f_fs_get_file_contents` | `asc/core/utils/fs/fs.opt-inc.sh:287` | Doc explicitly says "without subshell" |
| `f_fs_change_line` (partial) | `asc/core/utils/fs/fs.opt-inc.sh:774` | |
| `f_yaml_escape_double` | `asc/yml/yml.inc.sh:229` | |
| `f_global_assign_value` | `asc/core/global.inc.sh:490–541` | |
| `f_asc_extension_namespace` | `asc/core/core.inc.sh:434` | |
| `f_hook_variant_values_add` | `asc/core/hook.inc.sh:796` | |
| `f_make_unescape` / `f_make_task_name` | `asc/make/make.inc.sh:98,393` | |
| `f_thread_output_mtime_ms` | `asc/thread/thread.inc.sh:359–363` | |
| `f_thread_yml_strip_quotes` | `asc/thread/thread.inc.sh:201–202` | |
| Remote token replace | `asc/extensions/remote/remote.inc.sh:868–880` | |

**Remaining subshell at already-migrated call sites:**

| File | Line | Issue |
|------|------|-------|
| `asc/core/utils/fs/fs.opt-inc.sh` | ~~629~~ | ~~`f_str_append_once`~~ — **fixed** (wave 2) |
| `asc/core/utils/fs/fs.opt-inc.sh` | ~~649~~ | ~~`f_str_sed_escape`~~ — **fixed** (wave 2) |
| `asc/make/make.inc.sh` | 435 | `case_target="$(f_test_case_make_target …)"` — nested `$()` inside echo-based helper (wave 8) |

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
| **Definition** | `asc/core/utils/fs/fs.opt-inc.sh:228–252` — `find … \| head` to stdout; may return multiple lines |
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

### `f_yaml_parse` — callers (capture subshell already gone)

As of 2026-09-22, callers use the output-var form (`f_yaml_parse path prefix 'parsed'`) then `eval "$parsed"`. The old `eval "$(f_yaml_parse …)"` capture pattern is gone (see `test_f_yaml_parse_no_caller_capture_subshell`). Remaining problem is **`eval` of multi-var assignment text**, not another `printf -v` pass.

| File | Pattern |
|------|---------|
| `asc/thread/thread.inc.sh` | full-blob `eval "$parsed"` after `thread_` prefix |
| `asc/thread/monitor.hook.sh` | full-blob `eval` (errors swallowed) |
| `asc/instance/reinit.sh` | full-blob `eval` of `env.yml` → `yaml_*` |
| `asc/extensions/crontab/crontab.inc.sh` | full-blob `eval` (base + cron job files) |
| `asc/extensions/software/host/provision.opt-inc.sh` | full-blob `eval` of software manifests |
| `asc/instance/instance.inc.sh` | transform lines → uppercase globals, then `eval` of built strings |
| `asc/extensions/entity/entity.inc.sh` | **selective** line `eval` (only `einc_include*=`) |
| `asc/extensions/remote/remote.inc.sh` | write assignment text to a file (later consume) |
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | full-blob + per-line `eval` (contrib) |
| `asc/test/core/yml.test.sh` | exercises the current contract |

**Definition:** `asc/yml/yml.inc.sh` — delegates to vendor `parse_yaml`, emits shell assign / `+=` statements. Optional 3rd arg writes that text via `printf -v` (no caller capture subshell). Vendor pipeline still forks internally.

**Fit:** **Not a `printf -v` candidate** — many variables, including arrays. This is a separate design track.

### Design (2026-09-22) — replace `eval` without pretending it is `printf -v`

**Constraints**

- bash-yaml’s contract is “emit shell declarations”; ASC already depends on `+=` list shape and prefixed scalars.
- Callers need **many** names in the current scope (or a filtered subset), not one string.
- Trust model today: YAML paths are instance / extension files under ASC control, not arbitrary user paste.
- Lightweight: no new loader, no second YAML dialect, no repo-wide rewrite from this design alone.

**Options (do not implement yet)**

| Option | Idea | Pros | Cons |
|--------|------|------|------|
| **A — document + thin helper** | Keep `eval "$parsed"`; optional `f_yaml_eval_assignments "$parsed"` that only documents “bash-yaml grammar only” | Zero behavior change; one name for reviews | Still `eval` |
| **B — `source` a tempfile** | Write `$parsed` to a temp file, `source` it, remove | Same semantics; easier to inspect on failure | Temp I/O; cleanup; still runs the same text |
| **C — selective line eval** | Entity pattern: walk lines, `eval` only matching keys | Smaller blast radius when only a few keys matter | Most callers need the full prefix set |
| **D — nameref / assoc API** | New `f_yaml_load_map` fills `declare -n` assoc for simple maps | No `eval` for flat key→string cases | Does not cover `+=` lists or keyed parallel arrays without a second shape; large caller churn |
| **E — process substitution** | `source <(printf '%s\n' "$parsed")` | No tempfile | Still executes assignment text; bash/`set -e` quirks; not safer than `eval` |

**Recommendation**

1. **Near term (this design’s accept):** keep **A**. Capture-subshell work is done; `eval "$parsed"` stays the multi-var load contract. Do not migrate Category C under the printf -v waves.
2. **When a caller only needs a filter:** prefer **C** (copy entity’s include walk) before inventing D.
3. **Only if a concrete consumer needs map-without-eval:** add **D** for flat maps as a *new* optional API beside `f_yaml_parse`, leave list-heavy callers on A. Do not delete `eval` paths in the same change.
4. Reject **E** as a “safety” fix — same trust, more ceremony. **B** only if debugging assignment text on disk helps a real failure mode.

**Out of scope for the next implementation go-ahead (when granted)**

- Replacing vendor `parse_yaml`.
- Bootstrap `global … "$(f_*)"` (category G).
- `f_remote_exec_wrapper` exit-status story.

**Implementation go-ahead later must name** whether it ships A-only (docs/helper), C for one call site, or a D pilot — not “rewrite every `eval "$parsed"`”.

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
| `asc/core/utils/str/str.opt-inc.sh` | 639 | `f_str_trim` | `echo "$(echo -e "$1" \| sed …)"` | Parameter expansion / `printf -v` |
| `asc/core/utils/str/str.opt-inc.sh` | 89 | `f_str_convert_tokens` | `val="$(date +"$match")"` | Acceptable? or inline date into var without subshell |
| `asc/core/utils/str/str.opt-inc.sh` | 231 | `f_str_basic_auth_credentials` | `` a_pass=`< /dev/urandom …` `` | Backtick subshell for password gen |
| `asc/git/git.inc.sh` | 741, 777 | `f_git_get_staged_files`, `f_git_get_unmerged_paths` | `echo "$(f_git_wrapper …)"` | Call wrapper with output var |
| `asc/core/utils/fs/fs.opt-inc.sh` | 629, 649 | `f_fs_append_line_once`, `f_fs_change_line` | `$(f_str_append_once …)`, `$(f_str_sed_escape …)` | Migrate str helpers first |

---

## Category G — Bootstrap / codegen literals (defer or special-case)

| File | Line | Pattern | Notes |
|------|------|---------|-------|
| `asc/core/global.vars.sh` | 37, 44 | `global HOST_OS "$(f_host_os)"` | Evaluated when globals aggregate — subshell at init |
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

1. ~~**Leaf scalars with highest fan-out:** `f_software_scalar`, `f_cron_scalar`, `f_test_results_root`~~ **done**
2. ~~**Str utilities with existing TODO:** `f_str_append_once`, `f_str_sed_escape`, `f_str_trim`, then fix `fs.opt-inc.sh` callers~~ **done**
3. ~~**Path constants:** `f_cron_project_marker`, `f_software_managed_path`, `f_hook_resolve_source_path`~~ **done** (also `f_software_expand_path`)
4. **Status enums:** `f_software_*_status` → **done** (2026-09-22). Optional last arg + defaults `software_apt_status` / `software_pipx_status` / … Callers in `provision.opt-inc.sh` use output vars (no `$(f_software_*_status …)`).
5. **Filesystem:** `f_fs_get_most_recent` → **done** (2026-09-22). 5th arg output var (default `fs_most_recent`). Unblocks `f_db_get_dump` / restore / remote upload callers.
6. **Host/shell:** `f_print_current_user`, `f_host_os`, `f_host_ip` → **done** (2026-09-22). `f_str_slug` was already output-var. Bootstrap `global HOST_OS "$(f_host_os)"` / traefik `TRAEFIK_SYSTEMD_USER` stay category G.
7. **Git wrappers:** `f_git_get_staged_files` / `f_git_get_unmerged_paths` → **done** (2026-09-22). Collapse `echo "$(f_git_wrapper …)"`; 3rd arg output var.
8. **Test helpers:** batch helpers in `test.opt-inc.sh` → **done** (2026-09-22). `f_test_case_*` / `f_test_batch_dir_from_script` / `f_test_read_manifest_cases`; `make/generate.sh` updated.
9. **Defer:** `f_yaml_parse` / eval **implementation** (design done 2026-09-22), `f_remote_exec_wrapper`, bootstrap `global.vars.sh` literals

### Waves 1–3 implementation notes (2026-07-31)

- Convention: optional last arg `a_output_var_name` with function-specific default (`software_scalar`, `cron_scalar`, `test_results_root`, `sed_escaped`, `str_append_once`, `str_trimmed`, …).
- Cron codegen: monitor exports precomputed then embedded as `${monitor_*}` (no live `$(f_cron_scalar …)` in generated `data/asc/cron/*.sh`).
- Post-wave audit: migrated symbols have **zero** `$(f_*` capture sites; remaining high-count captures are mostly `f_fs_get_most_recent` (12) and `f_yaml_parse` (10).

### Wave 4 implementation notes (2026-09-22)

- `f_software_apt_status` / `pipx` / `tarball` / `appimage` / `ensure` / `unit` write via `printf -v`.
- Tests: `test_f_software_status_output_vars` in `asc/test/core/utilities.test.sh`.

### Waves 5–8 implementation notes (2026-09-22)

- Wave 5: `f_fs_get_most_recent`; test `test_f_fs_dir_file_list_and_most_recent`.
- Wave 6: `f_print_current_user` / `f_host_os` / `f_host_ip`; test `test_f_host_os_and_ip_output_vars`. Bootstrap globals deferred.
- Wave 7: git staged/unmerged; wave 8: test case helpers — `test_f_git_and_test_helper_output_vars`.

---

## Open tasks

- [x] Agree output-param naming convention extension-wide (optional last arg + fixed default name; match `f_str_lowercase`)
- [x] Pilot: migrate `f_cron_scalar` + `f_software_scalar` (largest payoff)
- [x] Add shunit2 cases asserting output-var paths for migrated scalars
- [x] Design replacement for `eval "$(f_yaml_parse …)"` (separate from `printf -v` work) — see Category C design 2026-09-22; keep `eval` until a later implementation gates row
- [x] Update `f_str_append_once` / `f_str_sed_escape` docblocks — remove TODO once migrated
- [x] Re-run ripgrep audit after waves 1–3: `rg '\$\(f_' --glob '*.sh' | rg -v vendor`
- [x] Wave 4: status enums (`f_software_*_status`)
- [x] Waves 5–8: `f_fs_get_most_recent`, host/shell, git get_*, test case helpers
- [ ] Optional later: implement Category C option A helper and/or C/D pilot — **needs a new gates row** (this design approval is not that go-ahead)
- [ ] Category G: bootstrap `global … "$(f_*)"` literals
---

## Audit command (repeatable)

```bash
cd /home/paul/Documents/asc
rg -o '\$\(f_[a-zA-Z0-9_]+' --glob '*.sh' | rg -v vendor | sed 's/^.*://' | sort | uniq -c | sort -rn
rg -n '\$\(f_' --glob '*.sh' | rg -v vendor | rg -v '^\S+:\d+:#' | cut -d: -f1 | sort | uniq -c | sort -rn
rg -n 'printf -v' --glob '*.sh' asc
```
