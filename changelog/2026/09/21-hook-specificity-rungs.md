# `hook_ms` specificity rungs

| Field | Value |
|-------|--------|
| **Date** | 2026-09-21 |
| **Status** | **done** |
| **Scope** | `hook_ms` in `asc/core/hook.manual-inc.sh`. Tests in `asc/test/core/hook.test.sh`. The harness paragraph in `.cursor/rules/asc-lightweight.mdc`. |
| **Not this change** | Make pivots (no entry-point score; agreed). Overrides. `hook()` sourcing every match. README wording (the human is rewriting that section). A new `.mdc`. Builder, workflow, and agent extensions. |

`$` in this file is the ASC docs placeholder (`$subject`, `$action`, `$extension`, `$vendor`), not a shell variable.

Do not commit unless asked.

Implemented: `f_hook_ms_measure` and the `hook_ms` pick in `asc/core/hook.manual-inc.sh`. `test_hook_ms_rung_order` and `test_hook_ms_extend_beats_contrib` in `asc/test/core/hook.test.sh`. Harness paragraph in `.cursor/rules/asc-lightweight.mdc`.

---

## Goal

`hook_ms` picks one file. The pick is a rung, then the existing dot-and-slash sum inside that rung.

Low to high:

1. `asc/` and `asc/extensions/` (one rung; the sum still separates them)
2. `scripts/asc/contrib/asc/` — contrib shipped with ASC
3. `scripts/asc/contrib/$vendor/` — any other vendor
4. `scripts/asc/extend/`
5. A project-root path (`-r`, no `/`)

An equal rung and an equal sum keep today's rule: the later candidate wins.

## Why the current sum cannot do this

`hook_ms` (`asc/core/hook.manual-inc.sh`) scores each existing match:

```text
score = (dot-separated parts) + (slash-separated parts)
        + 4 if the path starts with scripts/
        + 10 if there is no slash
```

Parts, not separators: `dump.hook.sh` is 3 dot-parts. `asc/db/dump.hook.sh` is 3 slash-parts. Score 6.

The `+4` is every `scripts/` path. It does not distinguish `contrib/asc`, another vendor, and `extend`. Those three differ by slash count, and `extend` is the shallow one:

| Path | Dot parts | Slash parts | Bonus | Score |
|------|-----------|-------------|-------|-------|
| `asc/db/dump.hook.sh` | 3 | 3 | 0 | 6 |
| `asc/extensions/db/db/dump.hook.sh` | 3 | 5 | 0 | 8 |
| `scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh` | 4 | 7 | +4 | 15 |
| `scripts/asc/contrib/acme/mysql/db/dump.hook.sh` | 3 | 7 | +4 | 14 |
| `scripts/asc/extend/db/dump.mysql.hook.sh` | 4 | 5 | +4 | 13 |
| `env.local.dev.yml` | 4 | 1 | +10 | 15 |

So today:

- The ASC-shipped `dump.mysql` hook implementation (15) beats another vendor's plain `dump` hook implementation (14). One extra dot-part is enough. Requirement 1 fails.
- `extend` (13) loses to both contrib files. Requirement 2 fails.
- The comment says an equal score keeps the first match. The comparison is `depth -ge highest_depth`, so the later match replaces it. The comment is wrong. Keep the code's direction.
- The comment says a root file beats `scripts/`. `+10` against `+4` is a gap of 6. A `scripts/` path whose dot+slash sum is more than 6 above the root file wins anyway. `env.local.dev.yml` (15) already ties the mysql contrib hook implementation (15).

The same formula and the same stale "first match" comment are in the older CWT `u_hook_most_specific`. This plan changes only this tree.

`scripts/asc/override/` is not a candidate. `f_hook_resolve_source_path` swaps the chosen file afterwards. Leave that.

## Rank

Replace the bonuses with a pair. Higher pair wins. Compare rung first. Compare the sum only inside one rung.

```text
sum = dot-parts + slash-parts
```

| Rung | Path |
|------|------|
| 0 | anything else `hook` emits (`asc/…`, `asc/extensions/…`) |
| 1 | `scripts/asc/contrib/asc/…` |
| 2 | `scripts/asc/contrib/…` whose next segment is not `asc` |
| 3 | `scripts/asc/extend/…` |
| 4 | no `/` (project root, `-r`) |

Rung 4 makes the root comment true: a root file beats every `scripts/` file, including a deep one. That is stricter than `+10`. The lookups that use `-r` are `env.yml`-style names, not hook implementations. Call that out in the test.

Inside rung 0 the sum is unchanged, so `asc/extensions/…` (more slashes) still beats `asc/$subject/…` unless the core filename has enough extra dots to tie or pass. Do not split core and `asc/extensions` into two rungs. That was not requested.

On a full tie, the later candidate wins.

## Files

- Modify: `asc/core/hook.manual-inc.sh` — add `f_hook_ms_measure`, use it in `hook_ms`, fix the comment above `hook_ms`.
- Modify: `asc/test/core/hook.test.sh` — rank cases, then one dry-run that builds three real files.
- Do not add a loader, a new hook call, or a new include. Both functions are called by `hook_ms`.

## Task 1: measure, then pick

**Files:** `asc/core/hook.manual-inc.sh`

`f_hook_ms_measure` writes three integers in the calling scope: `hook_ms_rung`, `hook_ms_sum`.

```bash
##
# Rank one hook_ms candidate.
#
# Writes hook_ms_rung and hook_ms_sum in the calling scope.
# Rung: 0 asc and asc/extensions, 1 scripts/asc/contrib/asc,
# 2 other scripts/asc/contrib/$vendor, 3 scripts/asc/extend,
# 4 project-root path (no slash).
# Sum: dot-parts + slash-parts. Compared only inside one rung.
#
# @param 1 String : filepath relative to PROJECT_DOCROOT
#
f_hook_ms_measure() {
  local p_path="$1"
  local dot_arr=()
  local slash_arr=()
  local vendor

  f_str_split1 'dot_arr' "$p_path" '.'
  f_str_split1 'slash_arr' "$p_path" '/'

  hook_ms_sum=$(( ${#dot_arr[@]} + ${#slash_arr[@]} ))
  hook_ms_rung=0

  if [[ ${#slash_arr[@]} -eq 1 ]]; then
    hook_ms_rung=4
    return
  fi

  case "$p_path" in
    scripts/asc/extend/*)
      hook_ms_rung=3
      ;;
    scripts/asc/contrib/asc/*)
      hook_ms_rung=1
      ;;
    scripts/asc/contrib/*)
      hook_ms_rung=2
      ;;
  esac
}
```

In `hook_ms`, drop `depth`, `highest_depth`, the `+4`, and the `+10`. Track `best_rung=-1` and `best_sum=-1`. For each existing match:

```bash
f_hook_ms_measure "$f"

if [[ $hook_ms_rung -gt $best_rung ]] \
  || { [[ $hook_ms_rung -eq $best_rung ]] && [[ $hook_ms_sum -ge $best_sum ]]; }; then
  most_specific_match="$f"
  best_rung=$hook_ms_rung
  best_sum=$hook_ms_sum
fi
```

`-ge` on the sum keeps "later equal rank wins".

Replace the comment block above `hook_ms` (the "first match" sentence and the `+4` note) with the rung table. Keep the sentence that override is applied after the pick.

## Task 2: failing tests, then the function

**File:** `asc/test/core/hook.test.sh`

Add `test_hook_ms_rung_order` before implementing Task 1 if doing TDD. Run that test alone, see it fail, then add the function.

```bash
test_hook_ms_rung_order() {
  local -a paths=(
    'asc/db/dump.hook.sh'
    'asc/extensions/db/db/dump.hook.sh'
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh'
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh'
    'scripts/asc/extend/db/dump.hook.sh'
    'env.local.dev.yml'
  )
  local expect_rungs=(0 0 1 2 3 4)
  local i

  for i in "${!paths[@]}"; do
    f_hook_ms_measure "${paths[$i]}"
    assertEquals "rung ${paths[$i]}" "${expect_rungs[$i]}" "$hook_ms_rung"
  done

  # Inside rung 0 the sum is unchanged: more slashes still beat a shallower core file.
  f_hook_ms_measure 'asc/db/dump.hook.sh'
  local core_sum=$hook_ms_sum
  f_hook_ms_measure 'asc/extensions/db/db/dump.hook.sh'
  assertTrue 'extension sum beats core sum' "[[ $hook_ms_sum -gt $core_sum ]]"

  # The old sum picked the deep ASC-shipped hook implementation (15) over extend (12 or 13).
  # Rung 3 must beat rung 1 even when the extend filename has fewer dots.
  local best=''
  local best_rung=-1
  local best_sum=-1
  local f
  for f in \
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh' \
    'scripts/asc/extend/db/dump.hook.sh'
  do
    f_hook_ms_measure "$f"
    if [[ $hook_ms_rung -gt $best_rung ]] \
      || { [[ $hook_ms_rung -eq $best_rung ]] && [[ $hook_ms_sum -ge $best_sum ]]; }; then
      best="$f"
      best_rung=$hook_ms_rung
      best_sum=$hook_ms_sum
    fi
  done
  assertEquals 'extend beats asc-shipped contrib' \
    'scripts/asc/extend/db/dump.hook.sh' "$best"

  best=''
  best_rung=-1
  best_sum=-1
  for f in \
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.aaa.bbb.hook.sh' \
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh'
  do
    f_hook_ms_measure "$f"
    if [[ $hook_ms_rung -gt $best_rung ]] \
      || { [[ $hook_ms_rung -eq $best_rung ]] && [[ $hook_ms_sum -ge $best_sum ]]; }; then
      best="$f"
      best_rung=$hook_ms_rung
      best_sum=$hook_ms_sum
    fi
  done
  assertEquals 'other vendor beats asc-shipped contrib' \
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh' "$best"
}
```

Run:

```bash
asc/test/core/hook.test.sh
```

Expected before Task 1: `f_hook_ms_measure: command not found` (or the assertions fail if a stub exists).

Expected after Task 1: this test passes. Then:

```bash
make test-core
```

Expected: pass. Unrun stays unverified.

## Task 3: one dry-run through `hook_ms`

The unit test never checks that `hook_ms` calls the measure. Add one case that creates three files, registers them, and dry-runs.

Use a subject name that is not already an ASC subject. `zzscore` is free in this tree (checked 2026-09-21: no `zzscore` path).

Extension folder names must differ. `f_asc_extension_namespace` keeps only the last path segment, so `asc/zzscore` and `zzvendor/zzscore` would share one `ZZSCORE_*` variable. Use `asc/zzscorea` and `zzvendor/zzscorev`.

```bash
test_hook_ms_extend_beats_contrib() {
  local saved_ext="$ASC_EXTENSIONS"
  local dir
  local cache_glob='data/asc/cache/hook/*zzscore*'

  for dir in \
    scripts/asc/contrib/asc/zzscorea/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore \
    scripts/asc/extend/zzscore
  do
    mkdir -p "$dir"
  done

  # More dots on the ASC-shipped file, on purpose.
  touch scripts/asc/contrib/asc/zzscorea/zzscore/zzscore.aaa.bbb.hook.sh
  touch scripts/asc/contrib/zzvendor/zzscorev/zzscore/zzscore.hook.sh
  touch scripts/asc/extend/zzscore/zzscore.hook.sh

  f_asc_extend 'scripts/asc/contrib/asc/zzscorea'
  f_asc_extend 'scripts/asc/contrib/zzvendor/zzscorev'
  f_asc_extend 'scripts/asc/extend'

  ASC_EXTENSIONS="$saved_ext asc/zzscorea zzvendor/zzscorev extend"
  rm -f $cache_glob

  most_specific_match=''
  hook_ms 'dry-run' -s 'zzscore' -a 'zzscore' -t

  assertEquals 'dry-run winner is extend' \
    'scripts/asc/extend/zzscore/zzscore.hook.sh' \
    "$most_specific_match"

  rm -f \
    scripts/asc/contrib/asc/zzscorea/zzscore/zzscore.aaa.bbb.hook.sh \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore/zzscore.hook.sh \
    scripts/asc/extend/zzscore/zzscore.hook.sh
  rmdir \
    scripts/asc/extend/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev \
    scripts/asc/contrib/asc/zzscorea/zzscore \
    scripts/asc/contrib/asc/zzscorea \
    2>/dev/null || true
  rm -f $cache_glob
  ASC_EXTENSIONS="$saved_ext"
}
```

`f_asc_extension_path` maps `asc/zzscorea` and `zzvendor/zzscorev` to `scripts/asc/contrib`, and `extend` to `scripts/asc`. `hook` then looks in those base paths. `f_asc_extend` fills `ZZSCOREA_SUBJECTS` / `ZZSCOREV_SUBJECTS` / `EXTEND_SUBJECTS` from the directories just created.

If `EXTEND_SUBJECTS` already lists real extend subjects, `f_asc_extend 'scripts/asc/extend'` replaces that variable for the rest of the process. Save and restore it the same way as `ASC_EXTENSIONS`:

```bash
local saved_extend_subjects="${EXTEND_SUBJECTS-}"
# ... test ...
EXTEND_SUBJECTS="$saved_extend_subjects"
```

Run `asc/test/core/hook.test.sh` again. Expected: both new tests pass, and the existing hook dry-run tests still pass. Those tests `rm` their own cache keys; this one must not leave `zzscore` files or a cache behind.

Cleanup belongs in the test even on assertion failure. If shunit2 stops the function at the first `assertEquals`, a failed run leaves directories. Put the `rm` in a `tearDown` for this file, or delete at the start of the test as well as the end.

## Task 4: write the placement law into the existing rule

Do this in the same change as Tasks 1–3. The rule must describe the rung the code implements. Landing it earlier would tell agents a score that still uses `+4`.

**File:** `.cursor/rules/asc-lightweight.mdc` only.

Do not add a `.mdc`. The rule already forbids a new one as the memory vehicle. `.cursor/rules/asc-dollar-prefix.mdc` is about the `$` placeholder, not placement. The harness paragraph under "Labels (human ↔ token)" is already the law for "one `$subject-$action`, the tool's hook implementation is the `hook_ms` winner". Extend that paragraph. Do not open a new section.

In that prose, write **hook call** or **hook implementation**. "Hook" alone does not say which. `hook_ms` is the hook call. The `*.hook.sh` file is the hook implementation.

Replace the harness paragraph (the one that starts "A **harness** is generic ASC-level") with:

```markdown
A **harness** is one generic `$subject-$action` that makes a hook call (`hook_ms`). The tool extension supplies the hook implementation. Entry-point name clashes stay prefixed, so both commands remain callable. Do not score them. Same `*.entity.yml` / `*.able.yml`. Do not mint a second pivot or a second entity spec per tool. On disk: `make agent-start` → `hook_ms -s agent -a start`; `make db-dump` vs `dump.mysql.hook.sh` / `dump.pgsql.hook.sh`. `agent-swarm-start` vs `cursor-swarm-start` / `codex-swarm-start` are names, not files here.

In prose, write **hook call** or **hook implementation**. Do not use "hook" alone for either.

Put the hook implementation in the tool's extension: `scripts/asc/contrib/asc/$extension/` unless that tool is ordinary in almost every instance, in which case `asc/extensions/$extension/` (compose). Another vendor: `scripts/asc/contrib/$vendor/`. One project: `scripts/asc/extend/`. `hook_ms` ranks hook implementations low to high: `asc/` and `asc/extensions/`, then `scripts/asc/contrib/asc/`, then other `scripts/asc/contrib/$vendor/`, then `scripts/asc/extend/`, then a project-root path from `-r`. Inside one rung, dot-parts + slash-parts. An equal rank keeps the later file.
```

In the checklist under that section, add these three lines and keep the rest:

```text
❌ A second make pivot per tool
❌ Scoring entry points so one namespace drops the other's task
✅ Generic `$subject-$action` makes the hook call; the tool extension supplies the hook implementation
```

Replace the existing "✅ One abstract `$subject-$action`; contrib is hook_ms specificity" with:

```text
✅ One abstract `$subject-$action`; the contrib hook implementation is the hook_ms winner
```

Do not mention builder, workflow, or agent templates in the rule. Those extensions are not in this tree.

## Out of scope for the implementation

- Do not change `f_make_register_entry_point` or `f_make_list_entry_points`.
- Do not retune rung 0 (core versus `asc/extensions`). Compose stays in `asc/extensions` and therefore on rung 0, below contrib and extend. That is the rank, not a reason to move compose.
- Do not score `scripts/asc/override`.
- Do not edit `README.md` in this work. The human is rewriting "Lookup and collisions". The mechanism they can describe is: rung, then dot-parts + slash-parts, later equal rank wins, override swaps after the pick.
- Do not add a Cursor rule file.

---

## Follow-up review: scoring make entry points

Not a task. Decision recorded here so it is not redone from memory.

**Question.** Should the same rung pick a single `make` `$subject-$action` when two namespaces provide that script, the way `hook_ms` picks one hook implementation?

**Agreed 2026-09-21.** No entry-point score. A generic entry point makes the hook call (`hook_ms`). The less generic, tool-specific extension supplies the hook implementation. Keep the prefix for the rare case where two namespaces still share a task name: both commands stay callable. Core, registered first, keeps the short name. The project copy is `extend-…` when core already owns that name. When core does not, `extend` is walked before the other extensions, so the project copy keeps the short name and the generic extension is prefixed.

### What the code does now

`f_make_list_entry_points` in `asc/make/make.inc.sh`:

1. Register every core `ASC_ACTIONS` pair under the short task name.
2. Walk extensions with `extend` moved to the front.
3. Same namespace and a deeper primitive pair (`$subject/$object/$action` has more slashes than `$subject/$action`) replaces the script. Same namespace and a shallower or equal pair keeps the first script. `f_make_sp_pair_slash_count`.
4. A task already owned by another namespace is not replaced. The caller prefixes `${extension}-$task`. `test_asc_make_cross_namespace_prefixes` in `asc/test/core/primitives.test.sh` locks that: core keeps `foobar-baz-toto` at `asc/foobar/baz/toto.sh`, and extend becomes `extend-foobar-baz-toto`.

`projet-complexe` still has the older function (its `asc/make/make.inc.sh` is dated 2026-08-30). It has steps 1, 2, and 4. It does not have the same-namespace depth replacement. The comment is the same one this tree still carries: walk `extend` first so the prefixed name lands on the generic extension, not on the project script.

The older CWT `u_make_list_entry_points` is that same prefix rule. No depth replacement. Same comment about walking `extend` first.

### What the instances actually registered

Counted from generated makefiles and from action scripts on 2026-09-21. Hooks, includes, tests, `*.make.sh`, and `*.wrap.sh` were not treated as pivots. The two CWT instances are not named here.

**Long-running CWT instance, larger extend tree.** `scripts/cwt/local/generated.mk`: 262 parsed targets, 127 of them under `scripts/cwt/extend/`. No target whose short name was also implemented by an extension script. The extend scripts are extra commands (`api-console`, and the rest of that `api-` set), not overlays of core. `composer.sh` appears twice, under `api/` and under `site/`, so the task names differ (`api-composer`, `site-composer`).

**Long-running CWT instance, smaller extend tree.** 157 parsed targets, 86 under extend. Two real clashes, both kept as two targets:

| Short name | Script that owns it | Prefixed name | Other script |
|------------|---------------------|---------------|--------------|
| `composer` | `scripts/cwt/extend/instance/composer.sh` | `dwt-composer` | `cwt/extensions/drupalwt/instance/composer.sh` |
| `drupal` | `scripts/cwt/extend/instance/drupal.sh` | `dwt-drupal` | `cwt/extensions/drupalwt/instance/drupal.sh` |

A score that let extend win would drop `dwt-composer` and `dwt-drupal`. Those targets are in the makefile the instance actually generates.

That same instance has `remote/db_download.sh`, `db_dump.sh`, `db_restore.sh`, and `db_upload.sh` both under `cwt/extensions/remote_db/remote/` and under `scripts/cwt/extend/remote/`. Only the extend paths are make targets. The extension is listed in `cwt/extensions/.cwt_extensions_ignore` (`remote_db`, among others). The project disabled the extension and added its own scripts. It did not need a score, and a score would not have been what turned the extension off.

**projet-complexe.** 79 action-like scripts under `scripts/asc/extend/`. No `$subject/$action` filename shared between that tree and `scripts/asc/contrib/` (or between extend and `asc/extensions/`). Its make generator is still the prefix rule. Nothing there is waiting for a winner.

**This ASC tree.** The only same `subject/file` across core, extensions, contrib, and extend was `agent/wrap.sh` (the agent extension, plus contrib `cursor` and `codex`). Those are wraps, not pivots. `data/asc/pivots.mk` has no second script for one task name.

### Pros of a score anyway

- One rule to remember, shared with `hook_ms`.
- The README section under rewrite already has to explain two collision rules. A single winner would delete that split.
- A project that always wants its script and never the generic one would not need `extend-…` or an ignore file.

### Cons, from the runs above

- The clashes that exist are pairs of commands. The generated makefile keeps both. A winner deletes one command that an operator can run today.
- Core owning the short name is tested and is the CWT order (core, then extend, then the other extensions). A rung that let `scripts/asc/extend/` take `make host-registry-get` from `asc/host/registry/get.sh` breaks `test_asc_make_cross_namespace_prefixes` and the 2026-09-20 README note that make names stay unique by prefix.
- The harness split is already the specific thing: `make db-dump` is one pivot and one hook call; `dump.mysql.hook.sh` and `dump.pgsql.hook.sh` are the hook implementations that compete inside `hook_ms`. Scoring the pivot would merge two mechanisms that the mysql/pgsql split exists to keep apart.
- Swap of one file already has a place: `scripts/asc/override/`. Turning an extension off already has a place: the ignore file, used for real on `remote_db` in the smaller CWT instance.
- projet-complexe and both CWT generators have shipped the prefix for years. The larger extend tree (127 targets) does not collide. The feature would change behavior only for the rare overlap, and that overlap is the case where the second command is useful.

**Do not implement an entry-point score.** If a later instance wants the generic command gone, ignore the extension or delete the script. If it wants the body swapped, use override. If it wants both, the prefix is the current behavior and the one the makefiles show.

## Later, not this plan

Three pillars for the agent extension, in the order they can be built. This plan is only the first: where a hook implementation lives, and which file the hook call runs.

1. **Specificity.** The rungs above. The generic extension makes the hook call (`hook_ms`). The tool extension supplies the hook implementation. Project extend beats contrib. ASC-shipped contrib loses to another vendor.
2. **Builder.** Next body of work. An extension of templates that generate the starting code, so an agent begins from that instead of a blank file. Not designed here.
3. **Workflow.** A later extension, and possibly rule text, that runs those generated shapes. Not designed here.

Builder and workflow come back in their own plans. Until those extensions exist, they stay out of `.cursor/rules/`.
