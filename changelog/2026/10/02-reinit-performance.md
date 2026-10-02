# Reinit performance

| Field | Value |
|-------|--------|
| **Date** | 2026-10-02 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Four measured costs inside `make reinit`: warmup replaying a hook-cache hit, linear membership scans while building hook lookup paths, repeated walks of shared writable directories in Drupal contrib, and candidate-driven token scans while rendering Drupal settings. |
| **Out of this plan** | A gates row. A root README edit. A configuration-only reinit mode. Preserving hook or discovery caches across reinit. Parallel hook execution. Replacing `f_in_array` for every caller. Deduplicating direct lookup candidates. A persistent permission-completion cache. PHP escaping of settings values. Editing the instance settings override from this repo. |
| **Evidence** | One plain `make reinit` and one instrumented run on a working multi-site tree, plus one isolated dry-run lookup comparison. OS caches were not flushed. No production patch was applied. The core suite was not run for this note. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME` and the shell parameters named below.

Go-ahead is a new row in [`gates.core.yml`](../../../gates.core.yml). This note does not add that row. `discuss` stays `go: no` until a later approval. Tasks 1–3 are sequential on the measured tree: each later run still pays the cost the earlier task removes. Task 4 changes the generic renderer only. Its acceptance test is that renderer. The measured settings time becomes evidence of improvement only after the instance adaptation named under task 4.

The mother copies of the files named here were read on 2026-10-02. The measurement compared those copies with the tree it timed and reported a byte match.

---

## What was measured

The plain run finished in 117.780 s real (72.926 s user, 39.347 s system). The instrumented run finished in 109.239 s real (73.044 s user, 37.482 s system). The gap between those two runs is noise between ordinary runs. It is not an optimization result.

A sandboxed attempt stopped on a Git-hook write after 29.887 s. An instrumentation attempt with an invalid `DEBUG` trap was excluded. Phase rows below are elapsed time between successive markers. Separately, function-call instrumentation was smoke-tested for return-code preservation and produced matched begin/end records.

| Phase | Seconds |
|---|---:|
| Bootstrap | 0.77 |
| Initial YAML and global preparation | 1.50 |
| Make-target and test registry generation | 0.78 |
| Pre-init, including DB initialization | 10.37 |
| Clone dispatch | 0.18 |
| Init hooks, including cold discovery | 15.04 |
| Ensure directories | 0.22 |
| Permissions | 21.50 |
| Post-init | 58.87 |

Post-init includes 24.94 s of hook warmup and 29.50 s of per-site Drupal settings generation. Those two figures are parts of the 58.87 s, not extra time. Settings generation includes its own hook lookups and DB activation.

`asc/instance/post_init.hook.sh` warms the permission hooks that the permissions phase already ran. The instrumented run repeated them:

| Warmup call | Seconds |
|---|---:|
| `fs_perms_pre_set` | 3.03 |
| `fs_perms_set` | 14.21 |
| `fs_perms_post_set` | 0.63 |
| `fs_perms_get` | <0.01 |
| Total of these four | 17.87 |

The 17.87 s sits inside the 24.94 s warmup. The same warmup also calls `fs_ownership_get`, `fs_ownership_pre_set`, `fs_ownership_set`, and `fs_ownership_post_set`, plus the start, stop, and setup hooks earlier in `asc/instance/post_init.hook.sh`. Those calls have no rows of their own.

A disposable lookup fixture sourced the current discovery inventory, used an empty hook cache, and dry-ran one broad init lookup. No hook body ran. A prototype kept the ordered candidate array, left direct additions in place, and recorded those paths in a per-hook associative index for later membership checks.

| Trial | Linear membership | Indexed membership |
|---|---:|---:|
| 1 | 13.902 s | 0.653 s |
| 2 | 14.031 s | 0.615 s |

Both trials emitted the same ordered candidate list and the same matched implementations. That is a result for this one lookup. It is not a prediction of whole-reinit time. The prototype was not installed.

---

## Task 1: A warmup hit returns without sourcing the cache

**Files:**

- Modify: `asc/core/hook.manual-inc.sh` (`hook()`, the cache-hit branch around the existing `[[ -f "$hook_cache_file" ]]` test)
- Test: `asc/test/core/hook.test.sh` (beside `test_hook_cache_debug_and_warmup_share_file`)

`f_hook_cache_key` already omits `-d` and `-w`. A warmup call and a normal call with the same filters share one cache file. On a hit, `hook()` sources that file and returns before it reads `b_cache_warmup`. The cache body is a list of `.` lines for seeded optional includes and for matched hook implementations, so the hit executes both.

On a miss, the same function already skips those `.` lines when `b_cache_warmup` is 1, then writes the cache file. Cold warmup is the behavior the hit path should keep.

- [ ] **Step 1: Add a failing core test for warmup execution**

In `asc/test/core/hook.test.sh`, add one case with a temporary hook body that appends one line to a marker file:

1. Delete that action’s hook cache files.
2. Call `hook` without `-w`. The marker has one line, and one cache file exists.
3. Call `hook -w` with the same filters. The marker still has one line, and the cache file count is unchanged.
4. Delete the cache file, call `hook -w` first. The marker is empty, and the cache file exists.
5. Call `hook` without `-w`. The marker has one line.

Keep `test_hook_cache_debug_and_warmup_share_file` and `test_f_hook_cache_key_flags`. Dry-run (`-t`) stays a different cache key and still must not source bodies.

Run: `asc/test/core/hook.test.sh` (or the equivalent `make test-core` filter this tree already uses for that file).

Expected before the fix: step 3 fails because the warmup hit sources the cached body.

- [ ] **Step 2: Return on a warmup hit**

When the cache file exists and `b_cache_warmup` is 1, return 0 without sourcing it. When the cache file exists and warmup is off, source it as today. Leave the miss path as it is: build the cache, source optional includes and hook bodies only when warmup is off, then write the file.

`mkdir -p data/asc/cache/hook` on every hit is a separate, smaller process launch. Leave it in this task.

- [ ] **Step 3: Re-run the hook test file**

Expected: the new case and the existing cache-key cases pass.

---

## Task 2: Membership index for one hook lookup

**Files:**

- Modify: `asc/core/utils/arr.manual-inc.sh` (`f_array_add_once`)
- Modify: `asc/core/autoload.manual-inc.sh` (`f_autoload_add_lookup_level`)
- Modify: `asc/core/hook.manual-inc.sh` (`hook()`, `f_hook_build_lookup_by_subject`, `f_hook_build_project_root_dir_lookup`)
- Test: `asc/test/core/utilities.test.sh` (`test_f_in_array_and_add_once`)
- Test: `asc/test/core/autoload.test.sh` (`test_f_autoload_add_lookup_level`)
- Test: `asc/test/core/hook.test.sh` (ordered lookup already asserted by the dry-run cases)

`f_autoload_add_lookup_level` calls `f_array_add_once`. `f_in_array` scans the whole candidate array. The lookup builders also append with `lookup_paths_arr+=` in `f_hook_build_lookup_by_subject` and `f_hook_build_project_root_dir_lookup`. Those direct appends are not membership checks. A repeated `-a` or `-s` value therefore leaves repeated direct candidates, and a file that exists on a repeated path is matched again. `f_array_add_once` would drop the repeat. The lookup prototype did not do that: it kept every direct addition and recorded it in the index so a later membership check could see it.

This task keeps that split. Direct additions stay direct additions. The index answers later `f_array_add_once` checks inside the same `hook()` call. Deduplicating direct candidates is a behavior change and is outside this task.

`f_in_array` stays a linear scan. Entity keys, YAML keys, git paths, and DB ids keep today’s call. Do not give every mutable array a hidden global index.

- [ ] **Step 1: Lock ordered candidate lists and match lists**

In `asc/test/core/hook.test.sh`, clear the hook cache for a temporary action, then capture two lists from `hook -t -d`: the full ordered candidate list printed for `lookup_paths_arr`, and `hook_dry_run_matches`. Compare both lists, in order, for:

1. An ordinary `-s` / `-a` lookup.
2. The same lookup with that action repeated in `-a`.
3. The same lookup with that subject repeated in `-s`.
4. Each of those three with `-r` as well.

The repeated-filter lists contain the repeated direct candidates the current builders append. The test fails if those repeats disappear. Existing dry-run order assertions stay.

In `asc/test/core/utilities.test.sh`, keep the current `f_array_add_once` assertions. Add a case whose third argument is the name of a `local -A` index: a repeated string stays one array element and one index key, a new string appends, and a call without the third argument still uses `f_in_array`.

In `asc/test/core/autoload.test.sh`, pass that index through `f_autoload_add_lookup_level`, including a versioned name (`app-1.2`, as the existing test does) and a repeated plain name. The emitted paths match the existing unindexed test, in the same order.

Run the three test files. Expected before the index exists: the hook-list cases pass on today’s builders, and the new index assertions fail.

- [ ] **Step 2: Index direct additions without filtering them**

`f_array_add_once` gains an optional third parameter, the name of an associative array in the caller. When it is set, membership is that key; on a miss, set the key and append. When it is empty, keep the `f_in_array` body.

`hook()` declares `local -A lookup_seen_arr=()` once per call, so a nested `hook()` has its own index. After each existing `lookup_paths_arr+=` in the two builders, set the index key for the appended path. Leave the `+=` in place. Pass the index name into `f_autoload_add_lookup_level`. Recursive calls forward the same name.

A direct path that was just appended is then visible to a later `f_array_add_once` in that call. A second direct `+=` of the same path still appends.

The index lives only for that `hook()` call. It is not written under `data/asc/cache/`.

- [ ] **Step 3: Re-run utilities, autoload, and hook tests**

Expected: the four candidate/match comparisons are unchanged, including repeated direct candidates for repeated filters and for `-r`. Indexed autoload paths match the unindexed lists.

Two further cuts on this same path were inspected and not timed. Leave them until the index is in and a fresh lookup timing says they still matter:

- [ ] **Optional: Skip action aggregation when `-a` replaces the action list**

`hook()` currently merges discovered actions and then deduplicates them even when `-a` supplies the action filter. Build the filtered list from the raw `-a` values in that case, repeats included. Collapsing a repeated `-a` value is the behavior change this task does not take.

- [ ] **Optional: Compute variant combinations once per stable call**

The prefix/variant product is rebuilt for every namespace and action inside one `hook()` call. Compute it once for that call when the inputs are unchanged, then reuse it. Keep the current product for calls whose filters differ.

---

## Task 3: Walk each writable directory once per permission phase

**Files:**

- Modify: `scripts/asc/contrib/asc/drupalwt/app/fs_perms_set.hook.sh`
- Create: `scripts/asc/contrib/asc/drupalwt/test/core.hook.sh`
- Create: `scripts/asc/contrib/asc/drupalwt/test/core/fs_perms_set.test.sh` (case shape in `data/entities/anti-pattern/asc/tests.md` and `asc/extensions/builder/subject/core/test_case.test.tpl.sh`)

`fs_perms_set.hook.sh` loads sites, skips `default`, and for every remaining site calls `f_dwt_get_sites_writeable_paths`. On the measured tree the temporary directory and the private directory resolved to the same paths for every non-default site. Each pass runs `find` twice on each path (`-type f` with `FS_W_FILES`, `-type d` with `FS_W_DIRS`). Warmup then repeated the whole hook; task 1 removes that repeat. This task removes the per-site repeat inside one pass.

`fs_perms_pre_set.hook.sh` walks `APP_DOCROOT` once. It is not this deduplication.

The protected-file lines in the same hook replace `sites/default` with `sites/$site_dir`. The loop never sets `site_dir`. `f_dwt_write_drupal_settings` already resolves it from the original site id: `site_dir` defaults to `default`, the variable name is `dwt_sites_${site}_dir`, and `f_str_sanitize_var_name` rewrites that name before it is read. The permission loop currently sanitizes `site_id` itself on entry, so a hyphenated id is no longer the original id when the path is built. Capture the original id first.

`scripts/asc/contrib/asc/drupalwt/test/core.hook.sh` is what makes the directory run. Match `asc/extensions/builder/test/core.hook.sh`: source `asc/test/test.opt-inc.sh` when `f_test_batch_exec` is missing, then `f_test_batch_exec 'scripts/asc/contrib/asc/drupalwt/test/core' || exit $?`. Task 4 uses this same hook. This mother checkout lists `asc/drupalwt` in `.asc_extensions_ignore`, so `f_asc_extensions` never adds it to `ASC_EXTENSIONS`, `hook -s test -a core` never adds `scripts/asc/contrib/asc/drupalwt` to its base paths, and `make test-core` here does not run that file. This repo has no enabled fixture for that extension.

- [ ] **Step 1: Add a failing contrib test**

Fixture: three site ids. Two resolve to one temporary directory and one private directory. One of those ids is `news-fr`. Its directory variable is `dwt_sites_news_fr_dir` (the sanitized form of `dwt_sites_news-fr_dir`), and its settings file lives under `sites/` plus that variable’s value.

Assert:

1. That shared temporary directory is walked once for files and once for directories, not once per site.
2. The protected settings path for `news-fr` uses the sanitized directory variable’s value. An empty `site_dir` produces `sites//…`, and the raw id `news-fr` is the wrong variable name.
3. The protected `chmod` runs after the writable walks, so a path covered by both ends with `FS_P_FILES`.

- [ ] **Step 2: Apply unique targets, then protected files**

Inside this hook invocation, remember each writable path together with its type (`f` or `d`) and mode. Run `find` only for a pair not already seen. Then apply each site’s protected settings file and local settings file.

Before the `sites/default` substitution, resolve `site_dir` from the original site id the way `f_dwt_write_drupal_settings` does. For `news-fr`, that read is `dwt_sites_news_fr_dir`.

Do not record that a directory was finished in a file under `data/`. A later process or dependency install can change modes between runs. Overlapping paths stay ordered: writable walks first, protected files after.

- [ ] **Step 3: Run the contrib batch where `asc/drupalwt` is enabled**

Expected: the three assertions pass. Run `make test-core` on the instance that produced the reinit timings, which enables `asc/drupalwt`. Keep that instance’s name and docroot out of this file. Confirm the batch actually executed `fs_perms_set.test.sh`. A copy of this repo with the `asc/drupalwt` ignore line removed is the other place the same command dispatches the hook. Do not remove that line in this checkout, and do not add a new top-level test entry point.

---

## Task 4: Render the tokens a template actually contains

**Files:**

- Modify: `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` (`f_dwt_write_settings`, `f_dwt_write_drupal_settings`)
- Create: `scripts/asc/contrib/asc/drupalwt/test/core.hook.sh` (the same file as task 3; create it here when task 3 has not)
- Create: `scripts/asc/contrib/asc/drupalwt/test/core/drupal_settings_tokens.test.sh`

`f_dwt_write_drupal_settings` copies the selected template, then runs `grep -F` for every name from `f_global_list`, every `DB_*` name, every site- and `ASC_DB_IDS`-prefixed `DB_*` name, and every `SITE_*` key. A hit then runs `sed -i`. Token text is `{{ ` + name + ` }}`.

`f_dwt_write_settings` already calls `f_db_set` for every DB id and every site before the per-site render loop. The per-site function still rebuilds the candidate name list and scans the file for each name. Parsed sites YAML is already memoized in `f_dwt_sites` when the declaration path is unchanged. That memo is not the cost this task removes.

The 29.50 s settings figure was measured on an instance whose writer overrides this include. This task does not change that override, so it does not reduce that figure. Acceptance is the generic renderer test below. A separate adaptation, owned by that instance, has to apply this same token contract to the override before a new timing on that tree can count as an improvement. Keep the instance name, docroot, and override path out of this file.

Shipped templates quote tokens as PHP, for example `$settings['hash_salt'] = '{{ DRUPAL_HASH_SALT }}';` in `scripts/asc/contrib/asc/drupalwt/app/drupal_settings.9.tpl.php`. `{{ INSTANCE_DOMAIN }}` there sits inside a single-quoted string next to `'\.'`.

Token contract for the generic renderer:

- A `{{ NAME }}` token whose name is not resolved stays in the file byte for byte. An absent candidate that never appears in the template does not prove this.
- A replacement value is literal, including when the value itself contains `{{ DB_USER }}`. One pass does not scan the inserted text. Successive `sed -i` passes can replace that token in a later loop. This task chooses the one-pass result.
- Quotes and backslashes are asserted as PHP source in that single-quoted shape. This task does not add PHP escaping. The current `sed` path does not escape either. A value that contains a single quote is recorded as raw bytes and is not claimed to be valid PHP.

- [ ] **Step 1: Add a failing render test**

Use a temporary PHP template in the shipped quoting style:

```php
<?php
$settings['hash_salt'] = '{{ DRUPAL_HASH_SALT }}';
$settings['file_public_path'] = '{{ DRUPAL_FILES_DIR }}';
$databases['default']['default']['password'] = '{{ DB_PASS }}';
$settings['kept'] = '{{ NOT_A_KNOWN_VAR }}';
```

Set `DRUPAL_HASH_SALT` to `say "hi" \path {{ DB_USER }}`. Load `DB_USER` as `dbuser`. The DB loop runs after the global loop, so today’s `sed` sees that inserted token. Set `DB_PASS` to a value with a comma. Leave `NOT_A_KNOWN_VAR` unset. Do not put `{{ DB_USER }}` in the template itself.

Assert the written PHP source, not a free-text blob:

1. The hash-salt line is `$settings['hash_salt'] = 'say "hi" \path {{ DB_USER }}';`. The inserted token stays even though `DB_USER` is resolvable.
2. The kept line is still `$settings['kept'] = '{{ NOT_A_KNOWN_VAR }}';`.
3. `php -l` exits 0 on that file.
4. A second fixture whose password value contains a single quote matches the raw inserted bytes. Do not require `php -l` on that fixture.
5. Path conversion still runs for `DRUPAL_FILES_DIR` and `DRUPAL_CONFIG_SYNC_DIR`, and for their `_C` names when `PROVISION_USING` is `compose` or `docker-compose`.

Run it the way task 3 runs contrib tests: `make test-core` only where `asc/drupalwt` is enabled. On the current successive `sed` path, the hash-salt assertion fails: the later DB pass replaces the inserted `{{ DB_USER }}` with `dbuser`. The unknown-token line already survives today, because that name is never a candidate. That assertion fails if a new renderer clears unresolved tokens. It is the regression lock for tokens that are present and unknown.

- [ ] **Step 2: Substitute from the template’s token set**

After the template is copied, read it once. Collect distinct `{{ NAME }}` tokens. Resolve only those names with the current rules:

- global value, then `f_fs_relative_path` for the files and config-sync names
- `NAME_C` when provisioning uses compose and that variable is non-empty
- unprefixed `DB_*` for the current site, and prefixed names for other sites and `ASC_DB_IDS`
- `SITE_*` keys, including the writable-path names and the `config_sync_dir` exception

Write the result in one pass. Insert each resolved value as literal bytes. Leave a token whose name does not resolve untouched. Do not scan inserted bytes for further tokens. Do not PHP-escape.

Per site, keep the `hook_ms` template selection, the `sites.php` / default-settings copy, and the final `chmod` to `FS_P_FILES`.

Inside one `f_dwt_write_settings` call, build the DB field-name list once and reuse it. Read a template’s token list once per distinct template path in that call. Site values stay per site.

- [ ] **Step 3: Re-run the generic renderer test**

Expected: the PHP file matches the five assertions, including the surviving unknown token and the literal inner token. That result accepts the generic renderer. It does not accept a shorter settings phase on the measured instance.

- [ ] **Instance adaptation, tracked in that instance**

Apply this token contract to the instance override of `f_dwt_write_drupal_settings`. Re-time settings generation there. Until that adaptation lands, 29.50 s stays a measurement of the override.

---

## Later, outside the four tasks

These showed up in the same run. They are not tasks above.

| Item | Why it waits |
|---|---|
| `mkdir -p` on every hook-cache hit | Smaller than the four tasks. Safe to fold into task 1 only if the warmup test still passes. |
| `echo \| awk` in `f_instance_yaml_config_parse` (`asc/instance/instance.inc.sh`) | YAML and global preparation measured 1.50 s. Builtin extraction can wait. |
| Retaining site ids and per-site YAML slices | `f_dwt_sites` already reuses a parsed declaration when the path matches. Whole-file parsing was not the measured cost. |
| Configuration-only reinit | Would change the reinit contract. Full permission repair stays the available behavior. |
| Keeping discovery caches across reinit | The stamp from [11-bootstrap-cache-layout-and-invalidation.md](../09/11-bootstrap-cache-layout-and-invalidation.md) watches selected identity fields and top-level directory mtimes. Additions inside an existing nested directory still need an invalidation contract before a persistent incremental discovery. |
| Parallel hook execution | Hooks share mutable shell state and order. Removing the repeated work comes first. |
| Instance settings-writer override | Task 4’s generic test does not change it. The instance adaptation under task 4 is the timing follow-up. |

Instance hooks that are not the generic files above stay in their instance.

---

## Checks before editing

Read the matching template under `asc/extensions/builder/subject/` and the anti-pattern records whose `globs` match each file. The records that apply here include `asc/shell_conditions.md`, `asc/shell_errors.md`, `asc/shell_function_existence.md`, `asc/docblock_function.md`, `asc/docblock_file_sh.md`, `asc/hook_call_existence.md`, `asc/inc_vs_opt-inc.md`, `asc/tests.md`, and `general/editorconfig.md`. A record whose examples are still `TODO` still binds through its description.

Task 1 and task 2 belong in the core suite and run under `make test-core` on this checkout. Tasks 3 and 4 add `scripts/asc/contrib/asc/drupalwt/test/core.hook.sh` and run with `make test-core` only where `asc/drupalwt` is enabled. No new always-sourced include, and no new top-level test entry point.
