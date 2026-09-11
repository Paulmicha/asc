# Lazy `*.opt-inc.sh` sourcing and entry-point extraction (follow-up)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-11 |
| **Status** | proposed (docs only — no code yet). **Do not implement until** `changelog/2026/09/11-bootstrap-cache-layout-and-invalidation.md` stamp + `core/active.sh` + hook keys have landed (or that plan is explicitly abandoned). |
| **Scope** | ASC repo `/home/paul/Documents/asc` — what bootstrap **parses** every run: six kernel includes, `ASC_INC` (`*.inc.sh`), `*.opt-inc.sh`, plus the same “keep vs move vs drop” drill used 2026-09-11 on `arr` / `str` / `fs` / `core` / `global` / `hook` / `autoload` / `yml` across **remaining core subjects and extensions**. |
| **Prerequisite** | [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md) — stamp, `cache/core/active.sh`, `cache/hook/<canonical-key>.sh`, `make cc` = lookup only. That plan does **not** shrink what is sourced; this one does. |
| **Related** | `asc/bootstrap.sh` (caller opt-inc block); `f_hook_opt_inc_append_candidates()` in `asc/asc/hook.inc.sh`; README § Bootstrap / Active Dir; `asc/utils/core_utils.inc.sh` (TODO: avoid unused utils every bootstrap); `asc/instance/write_globals.sh`, `list_actions.sh`, `list_makefiles.sh`, `globals_debug.sh` (pattern already used this conversation); `asc/extensions/software/host/provision.opt-inc.sh` (hook-seeded lazy include). |
| **Lifecycle** | Come back after cache/stamp. Implement in waves (kernel last). Do **not** mix this into the stamp PR. |

---

## Why this is a separate plan

The cache/stamp work avoids **`f_asc_extend`** and stale hook **lookup**. A warm `make $subject-$action` still **parses ~9k lines** of function definitions before the action runs:

| Bucket | Approx. lines (this tree, 2026-09-11) | When it is sourced |
|---|---|---|
| Kernel (six files + utils they pull) | ~4.8k | Every `ASC_BS_FLAG` bootstrap |
| `ASC_INC` (`$subject/$subject.inc.sh` + extension `*.inc.sh`) | ~4.5k | Every bootstrap after primitives |
| Caller `*.opt-inc.sh` | varies | Only the **process** that sourced `bootstrap.sh` (see caveats) |
| Hook-seeded `*.opt-inc.sh` | varies | When `hook()` runs a matching `*.hook.sh` (cached with that hook) |

Stamp does not change those numbers. This plan does.

**Do not** fold “split all core functions into opt-incs” into stamp/`active.sh`. Alias / `pre_bootstrap` / `bootstrap` hooks still **run** on warm path; they must see `hook()` and whatever **they** call. Lazy-moving the wrong file breaks those hooks without a lookup miss.

---

## Vocabulary

| Term | Meaning |
|---|---|
| **Eager include** | `*.inc.sh`. Discovered into `ASC_INC` as `$path/$subject/${subject}.inc.sh` (and extension equivalents). Sourced **every** bootstrap. |
| **Lazy include** | `*.opt-inc.sh`. **Not** in `ASC_INC`. Sourced only via (1) bootstrap **caller** paths or (2) **hook** colocated seeding. |
| **Kernel** | Always sourced before primitives: `core_utils` → arr/fs/shell/str, `core.inc.sh`, `global.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`, `yml.inc.sh`. |
| **Entry point (pivot)** | `$subject/$action.sh` (Make target `$subject-$action`). May `source` an opt-inc or a sourcable helper script. |
| **Sourcable + executable helper** | A `*.sh` that **defines** a function; runs a main only if `[[ "${BASH_SOURCE[0]}" == "$0" ]]`. Used when a function is a **one-shot workflow**, not a shared primitive. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## How lazy sourcing works today (exact)

There are **two** independent loaders. They do **not** share a code path. A file can be loaded by one, both, or neither.

### 1. Bootstrap caller (`asc/bootstrap.sh`, after `ASC_BS_FLAG` block)

Runs **every time** `bootstrap.sh` is sourced, including when `ASC_BS_FLAG` is already 1 (second source in the **same** shell still runs this block).

```text
BASH_SOURCE[0] = asc/bootstrap.sh
BASH_SOURCE[1] = the script that sourced bootstrap
```

Derived paths (only if `[1]` is set):

```text
<dir>     = dirname(BASH_SOURCE[1])
<subject> = basename(<dir>)
<action>  = basename(BASH_SOURCE[1]) with trailing .sh removed

<source if they exist, override-aware>:
  <dir>/<subject>.opt-inc.sh
  <dir>/<action>.opt-inc.sh     # skipped if it is the same path as subject
```

`f_autoload_override` runs first (`continue` operand): `scripts/overrides/...` counterpart wins.

**Example:** `asc/host/provision.sh` sources bootstrap → tries `asc/host/host.opt-inc.sh` and `asc/host/provision.opt-inc.sh`.

### 2. Hook-mapped seeding (`hook()`, non-dry-run)

For each **existing** lookup path that ends in `*.hook.sh`:

```text
<dir>     = dirname(hook path)
<subject> = basename(<dir>)          # last path component
<action>  = hook basename up to first '.' then strip .hook.sh
            e.g. pre_bootstrap.compose.hook.sh → action = pre_bootstrap
                 provision.hook.sh → action = provision

<source if they exist, once, before hook bodies>:
  <dir>/<subject>.opt-inc.sh
  <dir>/<action>.opt-inc.sh
```

Override resolution uses `f_hook_resolve_source_path` (prefer `scripts/overrides/` when the file exists). Those `. $src` lines are **written into the hook cache**, so a cache **hit** still sources the same opt-incs (no extra lookup).

Custom `-c` lookups that are **not** `*.hook.sh` are ignored by `f_hook_opt_inc_append_candidates`.

**Example:** `asc/extensions/software/host/provision.hook.sh` seeds `host.opt-inc.sh` (if any) and `provision.opt-inc.sh` in that **same** directory (`…/software/host/`). That is why provision helpers live in `provision.opt-inc.sh` next to the hook, not in a global `software.inc.sh`.

`hook_ms` uses `f_hook_source_opt_incs_for_path` for the single winning path (ad hoc), not the full `hook()` batch.

### 3. Eager `*.inc.sh` (`f_asc_extend` → `ASC_INC`)

For each subject in a namespace:

```text
if [[ -f "$p_path/$subject/${subject}.inc.sh" ]]; then
  ASC_INC+="$inc "
fi
```

Plus `scripts/asc/*.inc.sh` and extension `$ext/$ext.inc.sh`. Bootstrap then sources **every** `ASC_INC` path every run (override-aware).

`yml.inc.sh` is currently **both** in the six-file kernel **and** in `ASC_INC` (double source). Harmless, wasteful.

---

## Caveats (read before moving anything)

These are failure modes, not “cons in a table”.

1. **`BASH_SOURCE[1]` is the process that sourced bootstrap, not Make’s idea of the action.**  
   `asc/make/call_wrap.make.sh` sources bootstrap, then `eval "$p_real_script …"` which starts a **new** process. That wrap process loads kernel + `ASC_INC` + `asc/make/make.opt-inc.sh` and `call_wrap.make.opt-inc.sh` (if they exist). The **action** process sources bootstrap again and loads **its** `<dir>/<subject>.opt-inc.sh`.  
   **Implication:** opt-inc next to the action is what the action sees. Opt-inc next to `call_wrap` is **not** visible inside the action unless the action sources it.  
   **Implication:** every `make` currently pays **two** full bootstraps (wrap + action). Shrinking kernel/`ASC_INC` helps **both**. Do not “fix” that double start in the same wave as opt-inc moves unless measured.

2. **Hooks do not re-enter the caller opt-inc block.**  
   `hook()` `.`s hook files in the **current** shell. `BASH_SOURCE[1]` stays the original caller. A hook in `asc/git/` does **not** auto-load `git.opt-inc.sh` via bootstrap. It only gets opt-incs **colocated with that hook file** (mechanism 2).  
   **If you move `f_git_*` out of `git.inc.sh` into `git.opt-inc.sh`**, every `*.hook.sh` that calls those functions must live in a directory that has that opt-inc **or** the hook must `.` it explicitly. Alias / `pre_bootstrap` / `bootstrap` hooks are the first things that will break.

3. **Subject vs action basename mismatch.**  
   Hook action is the filename **before the first dot** (`pre_install.compose.hook.sh` → `pre_install.opt-inc.sh`, not `install.opt-inc.sh`). Bootstrap action is the **whole** stem minus `.sh` (`call_wrap.make.sh` → `call_wrap.make.opt-inc.sh`). Do not assume they match.

4. **Overrides are path-prefix swaps, not “search the whole tree”.**  
   `asc/host/host.opt-inc.sh` → `scripts/overrides/host/host.opt-inc.sh`. Contrib paths swap `scripts/asc/contrib/` the same way. A lazy file that only exists under contrib is not found from a core hook path.

5. **Hook cache pins the opt-inc list.**  
   After a hook miss, the cache contains `. path/to/foo.opt-inc.sh`. Adding a **new** colocated opt-inc does not apply until that hook cache is gone (`make cc` or stamp wipe of `cache/hook/`). Same as adding a new `*.hook.sh` for lookup (stamp v1 may not see nested file adds — see prerequisite plan).

6. **`source` is not `type -t`.**  
   Functions in an unsourced opt-inc are **undefined**. Tests that call `f_yaml_parse` after only kernel bootstrap will fail if yaml left the kernel. Every test file that uses a helper must source the new home (or keep a tiny kernel stub).

7. **Circular / order deps.**  
   `f_global_aggregate` calls `f_instance_yaml_config_load`. If aggregate stays in `global.inc.sh` and yaml parse moves to opt-inc, **init** must source yaml before aggregate. Today kernel order hides this.

8. **Aliases expand at function-definition time.**  
   `hook -s asc -a alias` must run **before** `ASC_INC` is sourced (today’s order). Lazy-moving alias **definitions** into an opt-inc sourced **after** that hook is too late. Keep alias **hooks** eager; they may stay small.

9. **Nameref / `printf -v` callers assume the callee exists.**  
   Same drill as 2026-09-11: moving a function without updating every call site (including CWT twins in other trees, if still in scope) leaves `command not found` in a **new** process, which is easy to miss if you only test `make init`.

10. **Do not lazy-load the kernel of the kernel.**  
    `hook()`, `f_asc_extend`, `f_autoload_override`, `f_array_add_once`, `f_str_sanitize_var_name` must stay eager or bootstrap cannot load anything else.

---

## What must stay eager (kernel)

Same list as the cache-plan discussion. Warm path still **executes** three hooks.

| File / symbols | Why eager |
|---|---|
| `arr.inc.sh`: `f_in_array`, `f_array_add_once` | Hook lookup, extend, opt-inc dedupe |
| `str.inc.sh` **subset**: sanitize, split1, subsequences, upper/lower | Cache keys, core, yaml prefix |
| `autoload.inc.sh` | `ASC_INC` loop + hook miss lookup levels |
| `hook.inc.sh` (whole file for v1) | Dispatch + miss builders. Splitting builders to a miss-only file is a micro-parse save; skip until fat files move. |
| `core.inc.sh`: extend, extension path/namespace, `f_asc_namespace_has_subject` | Stamp miss + hook miss |
| Stamp helpers (when implemented) | Bootstrap itself |

**Cold path** (no `active.sh`): kernel + `f_asc_extend`. Still no `f_global_aggregate` unless `make init` sources it on purpose.

---

## What to demote (parse win per line)

Order is **impact / risk**, not file name. Lightest first.

### Wave A — fat utils never used at bootstrap

| Move | From | To | Caveat |
|---|---|---|---|
| compress/extract/merge/watch | `fs.inc.sh` (~1088 lines, most of the file) | `fs.opt-inc.sh` sourced by the few actions/hooks that call them; **or** keep a 50-line `fs-min.inc.sh` (dir list / relative path / get_file_contents) in kernel if those are used during extend | Grep every `f_fs_*` in hooks **and** `ASC_INC` before cutting. |
| slug/snake/random/basic-auth/transliterate | `str.inc.sh` tail | `str.opt-inc.sh` | Kernel must keep sanitize/split/subseq/case. |
| `f_array_qsort` / reverse | `arr.inc.sh` | opt-inc or keep (tiny) | qsort was unused-volume in core; confirm again. |
| `yml.inc.sh` | kernel **and** `ASC_INC` | **one** home: either stay on `ASC_INC` only, or opt-inc for yaml callers | `f_instance_yaml_config_parse`, thread, remote, cron, software all need it **before** they parse. Init path must `.` yaml explicitly if it leaves `ASC_INC`. Remove the duplicate kernel line first (zero-behavior win). |

### Wave B — init-only globals

| Move | Caveat |
|---|---|
| `f_global_aggregate`, `f_global_lookup_paths`, `f_global_list` | Only init/reinit/tests. Warm `make` only sources **generated** `data/asc/global.vars.sh`. |
| `global()` | Only while **declaration** files (`asc/*/global.vars.sh`) are sourced. That is aggregate, not every bootstrap. If a `bootstrap` hook still calls `global`, it must keep a stub or source `global.opt-inc.sh` from `asc/asc/` (hook dir `asc/` → `asc.opt-inc.sh` / `bootstrap.opt-inc.sh`). **Verify with `hook -s asc -a bootstrap -t`. |

`write_globals.sh` / `globals_debug.sh` already left `global.inc.sh` (this conversation). Do not put them back.

### Wave C — shrink `ASC_INC`

Today this instance’s `ASC_INC` includes (among others) `git`, `host`, `instance`, `make`, `test`, `thread`, `yml`, `entity`, `file_registry`.

| Candidate | Why it is eager today | Demote when |
|---|---|---|
| `test.inc.sh` (~960) | Any test helper might be called from a hook | Only `test/*.sh` and `hook -s test` need it → `test.opt-inc.sh` + hook seeding on `asc/test/*.hook.sh` |
| `git.inc.sh` (~878) | Git hooks / write_hooks | `git.opt-inc.sh` colocated with git hooks; `git/write_hooks.sh` sources it |
| `make.inc.sh` (~494) | `f_make_generate` at init; `call_wrap` uses `f_make_list_hardcoded` | Wrap process still needs a **small** make helper or `cache/make.sh` only. Do not pull `f_make_generate` into every action process. |
| `thread.inc.sh` (~760) | Cross-subject (`log`/`cron` comments) | Those callers must source `thread.opt-inc.sh` or keep a thin `thread.inc.sh` with **only** the cross-subject API |
| `instance.inc.sh` (~850) | `f_instance_init`, perms, yaml config parse | Init/reinit/setup source `instance.opt-inc.sh`. Perms **hooks** under `instance/` already seed `instance.opt-inc.sh` if you name it that. **fs_perms hooks in other subjects must not call `f_instance_*` without sourcing.** |

**Rule:** if function F is called from subject B’s hook, F’s include must be either still eager, or seeded by B’s hook directory, or explicitly `.`'d at the top of that hook. No “it was in ASC_INC so it worked”.

### Wave D — hook.inc.sh split (optional, last)

If cache hits are the common case, `f_hook_build_lookup_by_subject` / root lookup / variant add are dead code on the hit path but still **parsed**. A `hook.lookup.opt-inc.sh` sourced only on miss is valid **after** A–C. Not v1 of this plan.

---

## Broader drill: functions that should not stay in `*.inc.sh`

This is the same method as 2026-09-11 on utilities, **applied to every remaining core subject and enabled extension**.

For each `*.inc.sh` / `*.opt-inc.sh`:

1. **Inventory** functions (name, role, internal graph).
2. **Map call sites** in this repo (and projet-complexe / `~/asc` / ATB `u_*` twins if still in scope).
3. **Classify:**
   - **Shared primitive** — keep as a function; prefer nameref / `printf -v`; no extra subshell. Example: `hook()`, `f_yaml_parse`, `f_array_add_once`.
   - **Internal-only helper** — keep next to its only caller; do not export a second API.
   - **One-shot / workflow** — **move to a dedicated entry point** (sourcable + executable). Pattern already used:
     - `f_global_write` → `asc/instance/write_globals.sh`
     - `f_global_debug` → `asc/instance/globals_debug.sh`
     - `f_asc_get_actions` → `asc/instance/list_actions.sh`
     - `f_asc_extensions_get_makefiles` → `asc/instance/list_makefiles.sh`
   - **Unused** — comment out or delete (same as `f_str_trim`, `f_global_foreach`, `f_array_ksort` / `print`). Keep `f_yaml_get_keys` (entity YAML later) even if currently unused.
4. **Do not** create git branches/worktrees unless asked. Stay on current branch.
5. **Tests** before claiming done (TDD for behavior changes).

### Entry-point script shape (mandatory)

```bash
#!/usr/bin/env bash
# Defines f_foo(). Sourced: definition only. Executed: bootstrap (if needed) + run.

f_foo() {
  ...
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh   # omit if the function needs a caller-prepared scope only
  f_foo "$@"
fi
```

Callers that already bootstrapped: `. path/to/script.sh` then `f_foo`. Make: `make $subject-$action` → that script as `$0`.

### When *not* to extract

- Multi-caller library used from hooks **and** actions (`hook_ms`, `f_yaml_parse`).
- Must exist before `ASC_INC` (kernel).
- Extracting would force every hook to copy a `.` line (then prefer opt-inc seeding instead).

### Suggested sweep order (core + extensions)

Reuse the conversation order; continue where it stopped:

| Area | Status (2026-09-11) | Follow-up |
|---|---|---|
| `utils/arr`, `str`, `fs`, `shell` | In-place opts; some dead removed | Wave A: fs/str tails → opt-inc |
| `core.inc.sh` | list_actions / list_makefiles extracted | Stamp helpers live here or in bootstrap; do not grow core with workflows |
| `global.inc.sh` | write/debug extracted; `foreach` commented | Wave B: aggregate/list off the kernel |
| `hook.inc.sh` / `autoload.inc.sh` / `yml.inc.sh` | in-place opts; yaml `printf -v` | Wave A duplicate yaml; Wave D lookup split |
| `instance.inc.sh` | still huge eager | Wave C + extract remaining init-only functions the same way as write_globals |
| `make.inc.sh`, `git.inc.sh`, `host.inc.sh`, `test.inc.sh`, `thread.inc.sh` | eager `ASC_INC` | Same drill: unused drop; one-shot → `$subject/$action.sh`; cross-subject keep opt-inc seeded by hooks |
| Extensions (`entity`, `file_registry`, `compose`, `crontab`, `software`, `remote`, `db`, …) | mixed `*.inc.sh` / `*.opt-inc.sh` | software provision is the **model** (opt-inc next to hook). Repeat: crontab, remote, db, compose aliases |

Each extension gets the same write-up style as the utility drill: inventory, unused, perf, keep vs move vs drop — **then** implement only what was agreed.

---

## Pros / cons (high level)

| Approach | Pros | Cons |
|---|---|---|
| **Keep everything in `*.inc.sh`** | Hooks never miss a function. | ~9k lines parsed per `make`; double bootstrap (wrap + action). |
| **Demote unused-at-bootstrap code to `*.opt-inc.sh` (picked)** | Uses existing loaders; hook cache already seeds colocated files; matches README. | Caveats 1–10; easy to break alias/bootstrap; tests must source the new home. |
| **Move one-shot workflows to entry-point `*.sh` (picked, already started)** | Init helpers not in every shell; Make targets stay obvious. | Callers must `.` or exec; two ways to invoke (source vs `$0`). |
| **Concatenate kernel into `active.sh`** | Fewer files to parse. | Editing `hook.inc.sh` needs `cc`; rejected in the cache plan. |

---

## Implementation waves (when coming back)

0. Prerequisite plan done (stamp + paths + hook keys).  
1. Remove duplicate `yml.inc.sh` from kernel **or** `ASC_INC` (measure nothing else).  
2. Wave A: `fs.inc.sh` / `str.inc.sh` tails; grep + tests.  
3. Wave B: global aggregate off kernel; `make init` / `reinit` still work.  
4. Wave C: one `ASC_INC` subject at a time (`test` first — few production hooks).  
5. Continue the **function drill** on `instance`, `make`, `git`, `host`, `thread`, then each enabled extension (inventory → classify → extract/drop).  
6. Optional Wave D: hook lookup builders miss-only.

After each wave: `bash asc/test/core/*.test.sh` that touch the moved symbols; at least one real `make` action that uses a **hook** in that subject (`hook -s asc -a alias -t` after alias-related moves).

---

## Tests (this plan)

- Caller opt-inc: a dummy `asc/test/nftascoptinc.opt-inc.sh` is sourced when `asc/test/core.sh` bootstraps (and **not** when `asc/make/call_wrap.make.sh` is the only caller — assert wrap does not define dummy symbols).
- Hook seeding: existing software provision / hook tests; add a dummy hook + colocated opt-inc, `hook -a …` without `-t`, assert function exists; dry-run `-t` does **not** source it.
- After moving `f_fs_compress`: a caller that did not source `fs.opt-inc.sh` fails `type -t`; the compress action succeeds.
- `make cc` still does not delete `global.vars.sh` / `generated.mk` (owned by prerequisite plan).
- No leftover `$(f_*` captures when a moved function already has `printf -v` (same as yaml tests).

---

## Open tasks

- [ ] Wait for [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md).
- [ ] Wave 1: yaml dual-source.
- [ ] Wave A–C as above.
- [ ] Drill remaining `*.inc.sh` (instance → make → git → host → test → thread → extensions).
- [ ] README: expand Bootstrap / Active Dir with the two loaders and caveat (1)–(2).
- [ ] Optional: measure wrap vs action bootstrap cost; only then consider a thinner `call_wrap` bootstrap.

---

## Summary pick

| Topic | Pick |
|---|---|
| When | **After** cache/stamp/hook-key plan |
| Lazy mechanism | Existing `*.opt-inc.sh` only (caller + hook seed). No third loader. |
| One-shot functions | Sourcable + executable `$subject/$action.sh` (write_globals / list_actions pattern) |
| Kernel | Stay eager (hook, extend, autoload, arr/str minimum) |
| Biggest parse win | `fs.inc.sh` + drop yaml duplicate + shrink `ASC_INC` (`test`/`git` first) |
| Biggest footgun | Hooks do not get caller opt-incs; alias/bootstrap hooks must keep their callees |
