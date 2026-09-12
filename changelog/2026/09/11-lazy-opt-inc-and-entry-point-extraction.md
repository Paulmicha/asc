# Lazy `*.opt-inc.sh` sourcing and entry-point extraction (follow-up)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-11 |
| **Status** | proposed (docs only — no code yet). **Do not implement until** [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md) stamp + `core/active.sh` + hook keys have landed (or that plan is explicitly abandoned). |
| **Scope** | ASC repo `/home/paul/Documents/asc` — what bootstrap **parses** every run (kernel, `ASC_INC`, `*.opt-inc.sh`), plus the same “keep vs move vs drop” drill used 2026-09-11 on `arr` / `str` / `fs` / `core` / `global` / `hook` / `autoload` / `yml`, continued across **remaining core subjects and extensions**. |
| **Prerequisite** | Cache/stamp plan. That work avoids `f_asc_extend` and stale hook **lookup**. It does **not** shrink what is sourced. This plan does. |
| **Related** | `asc/bootstrap.sh` (caller opt-inc, lines 100–138); `f_hook_opt_inc_append_candidates()` / `f_hook_source_opt_incs_for_path()` in `asc/asc/hook.inc.sh`; `f_autoload_override()` in `asc/asc/autoload.inc.sh`; README § Bootstrap / Active Dir; `docs/asc/organization.md` § bootstrap; `docs/asc/archive/bootstrap.md` (planned numbered phases — **not** on disk); `asc/utils/core_utils.inc.sh`; already-extracted `asc/instance/write_globals.sh`, `list_actions.sh`, `list_makefiles.sh`, `globals_debug.sh`; model lazy files `asc/extensions/software/host/provision.opt-inc.sh` + `software/software/software.opt-inc.sh`. |
| **Lifecycle** | Come back after cache/stamp. Implement in waves (kernel last). Do **not** mix this into the stamp PR. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## Why this is a separate plan

Warm `make $subject-$action` still **parses ~9k lines** of function definitions before the action runs, even when primitives and hook lookups hit cache:

| Bucket | Approx. lines (this tree, 2026-09-11) | When sourced |
|---|---|---|
| Kernel (six files + utils they pull) | ~4.8k | Every `ASC_BS_FLAG` bootstrap |
| `ASC_INC` (`$subject/$subject.inc.sh` + extension `*.inc.sh` + `scripts/asc/*.inc.sh`) | ~4.5k | Every bootstrap after primitives |
| Caller `*.opt-inc.sh` | varies | Phase 90: the **process** that sourced `bootstrap.sh` |
| Hook-seeded `*.opt-inc.sh` | varies | When `hook()` matches a `*.hook.sh` (written into that hook cache) |

Stamp does not change those numbers.

**Do not** fold “split all core functions into opt-incs” into stamp/`active.sh`. Alias / `pre_bootstrap` / `bootstrap` hooks still **run** on the warm path; they must see `hook()` and whatever **they** call. Lazy-moving the wrong file breaks those hooks **without** a lookup miss.

---

## The double extension `*.opt-inc.sh`

ASC marks include **kind** with a **double** (sometimes triple) suffix, not with a folder:

| Pattern | Kind | Meaning |
|---|---|---|
| `$subject/$action.sh` | Entry point (pivot) | Make target `$subject-$action`. Usually starts with `. asc/bootstrap.sh`. |
| `$subject/$subject.inc.sh` | Eager include | Discovered into `ASC_INC`. Sourced **once per shell** (heavy bootstrap). |
| `$ext/$ext.inc.sh` | Eager include | Same, for an enabled extension. |
| `scripts/asc/*.inc.sh` | Eager include | Convenience glob in `f_asc_extend` (project-local helpers). |
| `$subject/$subject.opt-inc.sh` | Lazy include | **Not** in `ASC_INC`. Sourced when that subject is the bootstrap **caller**, and/or when a hook in that directory is matched. |
| `$subject/$action.opt-inc.sh` | Lazy include | Same, but only for that action stem (and colocated hook). |
| `$subject/$action.hook.sh` | Hook body | Event implementation. May rely on a colocated opt-inc **seeded before** it. |

**Why `opt-inc` and not `opt`:** the file is still an **include** (defines functions in the current shell). `opt` = optional / on-demand. README wording: eager = “auto” = `*.inc.sh`; lazy = `*.opt-inc.sh` “corresponding to the entry point used.”

**Not a third loader.** There is no `ASC_OPT_INC` list. A `*.opt-inc.sh` that is neither next to the process that sourced bootstrap **nor** next to a matched `*.hook.sh` is never read. Putting helpers in `asc/utils/foo.opt-inc.sh` does nothing unless some caller/hook path derives that exact filename.

**Filename derivation is mechanical** (see the two loaders below). There is no glob of “all `*.opt-inc.sh` under the subject.”

**Docs vs disk (do not implement as part of this plan):**

- `docs/asc/archive/bootstrap.md` describes numbered files `asc/bootstrap/*.bootstrap-inc.sh` and `90-caller-opt-inc`. **Those files do not exist.** Today everything is inlined in `asc/bootstrap.sh`. `software.opt-inc.sh` comments that cite `90-caller-opt-inc.bootstrap-inc.sh` are aspirational.
- Filename-DSL notes wanted primordial **lazy** `asc/asc/utils/{array,fs,shell,string}.opt-inc.sh`. Today those are **eager** `asc/utils/{arr,fs,shell,str}.inc.sh` pulled by `core_utils.inc.sh`. Wave A of this plan is the practical move toward that intent, without waiting for `ASC_SHELL` or a phase-file split.
- Archive docs still say `u_asc_extend` / `u_autoload_override` and override root `scripts/asc/override/`. Code is `f_*` and `scripts/asc/override` (first `asc` path segment replaced). Follow **code** when placing override opt-incs.

---

## How lazy sourcing works today (exact)

Two independent loaders. A file can be loaded by one, both, or neither.

### 1. Bootstrap caller (phase 90) — `asc/bootstrap.sh`

Runs **every time** `bootstrap.sh` is sourced, **including** when `ASC_BS_FLAG` is already 1 (second `.` in the same shell still runs this block). Heavy bootstrap (kernel, globals, primitives, three hooks, `ASC_INC`) is the `if [[ $ASC_BS_FLAG -ne 1 ]]` block above it.

```text
BASH_SOURCE[0] = asc/bootstrap.sh
BASH_SOURCE[1] = the script that sourced bootstrap  (absent → no-op)
```

Derived paths (only if `[1]` is set):

```text
<dir>     = dirname(BASH_SOURCE[1])     # ${bootstrap_caller%/*}
<subject> = basename(<dir>)             # last path component
<action>  = basename(BASH_SOURCE[1]) with a single trailing .sh removed
            call_wrap.make.sh → call_wrap.make
            provision.sh      → provision

<source if they exist, override-aware, subject first>:
  <dir>/<subject>.opt-inc.sh
  <dir>/<action>.opt-inc.sh     # skipped if the two paths are identical
```

`f_autoload_override "$file" 'continue'` then `eval "$inc_override_evaled_code"` then `. "$file"` if it still exists.

**Examples:**

| Process that sourced bootstrap | Tries |
|---|---|
| `asc/host/provision.sh` | `asc/host/host.opt-inc.sh`, `asc/host/provision.opt-inc.sh` |
| `asc/extensions/software/software/status.sh` | `…/software/software.opt-inc.sh`, `…/software/status.opt-inc.sh` |
| `asc/make/call_wrap.make.sh` | `asc/make/make.opt-inc.sh`, `asc/make/call_wrap.make.opt-inc.sh` |
| interactive `. asc/bootstrap.sh` | nothing (`BASH_SOURCE[1]` empty) |

`software/software/software.opt-inc.sh` exists today and **sources** `host/provision.opt-inc.sh` so `make software-*` gets provision helpers without duplicating them. That is the composition pattern for subject-wide lazy APIs.

### 2. Hook-mapped seeding — `hook()` (non-dry-run)

For each **existing** lookup path that is a `*.hook.sh`:

```text
<dir>     = dirname(hook path)
<subject> = basename(<dir>)
<action>  = hook basename with .hook.sh stripped, then everything before the first '.'
            provision.hook.sh                    → action = provision
            pre_bootstrap.compose.hook.sh        → action = pre_bootstrap
            undo_nftaschhnc_dry_run.local.dev…   → action = undo_nftaschhnc_dry_run

append if they exist (deduped via f_array_add_once):
  <dir>/<subject>.opt-inc.sh
  <dir>/<action>.opt-inc.sh
```

Implemented in `f_hook_opt_inc_append_candidates()`. Custom `-c` lookups that are **not** `*.hook.sh` return immediately.

Then, for each candidate, `f_hook_resolve_source_path` (prefer `scripts/asc/override/…` when that file exists) and:

- append `. $src` to `hook_cache_contents` under `# --- opt-inc (seeded) ---` **before** `# --- hooks ---`
- `. "$src"` now unless `-w` cache warmup (`b_cache_warmup=1`)

A later **cache hit** re-sources those same lines. Adding a **new** colocated opt-inc does nothing until that hook cache file is gone (`make cc` or stamp wipe of `cache/hook/`).

`hook -t` (dry-run) never seeds or sources opt-incs. `hook -d` prints seeded paths after the lookup debug.

`hook_ms` uses `f_hook_source_opt_incs_for_path` for the single winning path (ad hoc), not the full `hook()` batch.

**Canonical example:** `asc/extensions/software/host/provision.hook.sh` is a one-liner (`f_software_provision apply`). Helpers live in `provision.opt-inc.sh` in the **same** directory. `hook -s host -a provision` seeds that file before the hook body. `make host-provision` also loads it via phase 90 if the action is `asc/host/provision.sh` — **only if** an opt-inc exists under `asc/host/`. The extension file is **not** the same path; software provision relies on **hook seeding**, not on the core `host/` caller opt-inc.

### 3. Eager `*.inc.sh` (`f_asc_extend` → `ASC_INC`) — not lazy

```text
if [[ -f "$p_path/$subject/${subject}.inc.sh" ]]; then
  ASC_INC+="$inc "
fi
```

Plus, when namespace is `ASC`: `scripts/asc/*.inc.sh` if that dir exists, and for each enabled extension `$ext_path/$extension/${inc_stem}.inc.sh` (`inc_stem=${extension##*/}`).

Bootstrap sources **every** `ASC_INC` path every heavy bootstrap (override-aware). `yml.inc.sh` is currently **both** in the six-file kernel **and** in `ASC_INC` (double source). Harmless, wasteful.

---

## Caveats (read before moving anything)

These are failure modes, not a short pros/cons row.

1. **`BASH_SOURCE[1]` is the process that sourced bootstrap, not Make’s idea of the action.**  
   `asc/make/call_wrap.make.sh` sources bootstrap, then `eval "$p_real_script …"` which starts a **new** process. The wrap process loads kernel + `ASC_INC` + `make.opt-inc.sh` / `call_wrap.make.opt-inc.sh` (if any). The **action** process sources bootstrap again and loads **its** `<dir>/<subject>.opt-inc.sh`.  
   Opt-inc next to the action is what the action sees. Opt-inc next to `call_wrap` is **not** visible inside the action unless the action sources it.  
   Every `make` currently pays **two** full bootstraps (wrap + action). Shrinking kernel/`ASC_INC` helps **both**. Do not “fix” that double start in the same wave as opt-inc moves unless measured.

2. **Hooks do not re-enter the caller opt-inc block.**  
   `hook()` `.`s hook files in the **current** shell. `BASH_SOURCE[1]` stays the original caller. A hook in `asc/git/` does **not** auto-load `git.opt-inc.sh` via phase 90. It only gets opt-incs **colocated with that hook file** (loader 2).  
   **If you move `f_git_*` out of `git.inc.sh` into `git.opt-inc.sh`**, every `*.hook.sh` that calls those functions must live in a directory that has that opt-inc **or** the hook must `.` it explicitly. Alias / `pre_bootstrap` / `bootstrap` hooks are the first things that will break.

3. **Subject vs action basename mismatch.**  
   Hook action = filename **before the first dot** after stripping `.hook.sh`. Bootstrap action = **whole** stem minus one `.sh`. `call_wrap.make.sh` → `call_wrap.make.opt-inc.sh`. `pre_install.compose.hook.sh` → `pre_install.opt-inc.sh`, not `install.opt-inc.sh`. Do not assume they match.

4. **Overrides are a single-segment path swap, not “search the tree”.**  
   `f_autoload_override` / `f_hook_resolve_source_path`: first `asc` → `scripts/asc/override`.  
   `asc/host/host.opt-inc.sh` → `scripts/asc/override/host/host.opt-inc.sh`.  
   `asc/extensions/software/host/provision.opt-inc.sh` → `scripts/asc/override/extensions/software/host/provision.opt-inc.sh`.  
   README/`scripts/asc/override/` is **not** what the functions look for. A lazy file that only exists under contrib is not found from a core hook path.

5. **Hook cache pins the opt-inc list.**  
   After a miss, the cache contains `. path/to/foo.opt-inc.sh`. New colocated opt-inc → stale until `cc` or stamp wipe of `cache/hook/`. Same class of bug as a new `*.hook.sh` (stamp v1 may not see nested file adds — see prerequisite plan).

6. **`source` is not `type -t`.**  
   Functions in an unsourced opt-inc are **undefined**. Tests that call `f_yaml_parse` after only kernel bootstrap will fail if yaml left the kernel. Every test file that uses a helper must source the new home (or keep a tiny kernel stub). Existing `test_f_hook_opt_inc_append_candidates` only checks **candidate discovery**, not that bootstrap phase 90 loaded a dummy file.

7. **Circular / order deps.**  
   `f_global_aggregate` calls `f_instance_yaml_config_load`. If aggregate stays in `global.inc.sh` and yaml parse moves to opt-inc, **init** must source yaml before aggregate. Today kernel/`ASC_INC` order hides this.

8. **Aliases expand at function-definition time.**  
   `hook -s asc -a alias` runs **before** `ASC_INC` is sourced (today’s order). Lazy-moving alias **definitions** into an opt-inc sourced **after** that hook is too late. Keep alias **hooks** eager; they may stay small. `shopt -s expand_aliases` is already on in bootstrap.

9. **Nameref / `printf -v` callers assume the callee exists.**  
   Same drill as 2026-09-11: moving a function without updating every call site (including CWT twins in other trees, if still in scope) leaves `command not found` in a **new** process — easy to miss if you only test `make init`.

10. **Do not lazy-load the kernel of the kernel.**  
    `hook()`, `f_asc_extend`, `f_autoload_override`, `f_array_add_once`, `f_str_sanitize_var_name` must stay eager or bootstrap cannot load anything else.

11. **`ASC_BS_SKIP_GLOBALS=1`** (`asc/instance/init.sh`) still runs kernel + primitives + hooks + `ASC_INC` + phase 90. Demoting yaml/instance helpers still breaks init unless init sources them.

12. **Nested / virgin exec** starts a new bash; parent `ASC_BS_FLAG` does not apply. Child pays full parse cost again. Another reason to shrink kernel/`ASC_INC`, not to invent a third loader.

13. **Warmup vs run.** `hook -w` writes `. opt-inc` lines into the cache **without** sourcing them in that process. A later real `hook` hit will source them. Tests that warmup then expect functions in the **same** shell will fail.

14. **Do not invent `ASC_SHELL` / numbered phase files here.** Multi-shell `*.$ASC_SHELL.opt-inc.sh` and `asc/bootstrap/90-…bootstrap-inc.sh` are other plans. This one only uses the two loaders that already run.

---

## What must stay eager (kernel)

Warm path still **executes** three hooks (`pre_bootstrap`, `alias`, `bootstrap`).

| File / symbols | Why eager |
|---|---|
| `arr.inc.sh`: `f_in_array`, `f_array_add_once` | Hook lookup, extend, opt-inc dedupe |
| `str.inc.sh` **subset**: sanitize, split1, subsequences, upper/lower | Cache keys, core, yaml prefix |
| `autoload.inc.sh` | `ASC_INC` loop + hook miss lookup levels |
| `hook.inc.sh` (whole file for v1 of **this** plan) | Dispatch + miss builders. Splitting builders to a miss-only file is Wave D. |
| `core.inc.sh`: extend, extension path/namespace, `f_asc_namespace_has_subject` | Stamp miss + hook miss |
| Stamp helpers (when implemented) | Bootstrap itself |

**Cold path** (no `active.sh`): kernel + `f_asc_extend`. Still no `f_global_aggregate` unless `make init` sources it on purpose.

---

## What to demote (parse win per line)

Order is **impact / risk**, not file name. Lightest first.

### Wave A — fat utils never used at bootstrap

| Move | From | To | Caveat |
|---|---|---|---|
| compress/extract/merge/watch | `fs.inc.sh` (~1088 lines, most of the file) | `fs.opt-inc.sh` sourced by the few actions/hooks that call them; **or** keep a ~50-line `fs-min.inc.sh` (dir list / relative path / get_file_contents) in kernel if those are used during extend | Grep every `f_fs_*` in hooks **and** `ASC_INC` before cutting. |
| slug/snake/random/basic-auth/transliterate | `str.inc.sh` tail (~722) | `str.opt-inc.sh` | Kernel must keep sanitize/split/subseq/case. |
| `f_array_qsort` / reverse | `arr.inc.sh` (~143, already small) | opt-inc or keep | Confirm unused-at-bootstrap again; `list_actions.sh` still calls qsort when executed as `$0`. |
| `yml.inc.sh` (~298) | kernel **and** `ASC_INC` | **one** home | `f_instance_yaml_config_parse`, thread, remote, cron, software all need it **before** they parse. Init path must `.` yaml explicitly if it leaves `ASC_INC`. Remove the duplicate kernel line first (zero-behavior win). |

This is the filename-DSL “utils should be lazy” intent, without moving files to `asc/asc/utils/` in the same change unless that rename is requested.

### Wave B — init-only globals

| Move | Caveat |
|---|---|
| `f_global_aggregate`, `f_global_lookup_paths`, `f_global_list`, `f_global_assign_value` | Only init/reinit/tests. Warm `make` only sources **generated** `data/asc/global.vars.sh`. |
| `global()` | Only while **declaration** files (`asc/*/global.vars.sh`) are sourced. That is aggregate, not every bootstrap. If a `bootstrap` hook still calls `global`, it must keep a stub or source `global.opt-inc.sh` from `asc/asc/` (hook dir `asc/` → `asc.opt-inc.sh` / `bootstrap.opt-inc.sh`). **Verify with `hook -s asc -a bootstrap -t`. |

`write_globals.sh` / `globals_debug.sh` already left `global.inc.sh` (this conversation). Do not put them back.

### Wave C — shrink `ASC_INC`

Typical eager includes today: `git`, `host`, `instance`, `make`, `test`, `thread`, `yml`, plus extension `entity` / `file_registry` / … and `scripts/asc/*.inc.sh`.

| Candidate | Why it is eager today | Demote when |
|---|---|---|
| `test.inc.sh` (~960) | Any test helper might be called from a hook | Only `test/*.sh` and `hook -s test` need it → `test.opt-inc.sh` + hook seeding on `asc/test/*.hook.sh` |
| `git.inc.sh` (~878) | Git hooks / `f_git_write_hooks` | `git.opt-inc.sh` colocated with git hooks; `git/write_hooks.sh` already exists as an entry point — **move the function into that script** (same pattern as `write_globals.sh`) |
| `make.inc.sh` (~494) | `f_make_generate` at init; wrap uses `f_make_list_hardcoded` | Wrap process still needs a **small** make helper or `cache/make.sh` only. Do not pull `f_make_generate` into every action process. Candidates for entry points: generate, generate_test_cases. |
| `thread.inc.sh` (~760) | Cross-subject (`log`/`cron` comments) | Those callers must source `thread.opt-inc.sh` or keep a thin `thread.inc.sh` with **only** the cross-subject API |
| `host.inc.sh` (~278) | crontab / ip / os / registry / once | `host.opt-inc.sh` + seeding from `host/*.hook.sh`; crontab add/remove are workflow-ish |
| `instance.inc.sh` (~850) | `f_instance_init`, perms, yaml config parse, registry, once, domain | Init/reinit/setup source `instance.opt-inc.sh`. Perms **hooks** under `instance/` seed `instance.opt-inc.sh` if named that. **fs_perms hooks in other subjects must not call `f_instance_*` without sourcing.** `f_instance_init` is a workflow: keep callable from `init.sh` / `reinit.sh`, do not leave the whole file eager “just in case.” |

**Rule:** if function F is called from subject B’s hook, F’s include must be either still eager, or seeded by B’s hook directory, or explicitly `.`'d at the top of that hook. No “it was in ASC_INC so it worked.”

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
   - **One-shot / workflow** — **move to a dedicated entry point** (sourcable + executable). Pattern already used this conversation:
     - `f_global_write` → `asc/instance/write_globals.sh`
     - `f_global_debug` → `asc/instance/globals_debug.sh`
     - `f_asc_get_actions` → `asc/instance/list_actions.sh`
     - `f_asc_extensions_get_makefiles` → `asc/instance/list_makefiles.sh`
   - **Unused** — comment out or delete (same as `f_str_trim`, `f_global_foreach`, `f_array_ksort` / `print`). Keep `f_yaml_get_keys` (entity YAML later) even if currently unused.
4. **Do not** create git branches/worktrees unless asked. Stay on current branch.
5. **Tests** before claiming done (TDD for behavior changes).

### Entry-point script shape (mandatory)

Already on disk in `write_globals.sh` / `list_actions.sh` / `list_makefiles.sh` / `globals_debug.sh`:

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

**Anti-pattern still on disk:** `asc/git/write_hooks.sh` only does `. asc/bootstrap.sh` then `f_git_write_hooks "$@"`, while the function **body** lives in eager `git.inc.sh`. Next extraction should move the body into `write_hooks.sh` exactly like `write_globals.sh`. Same smell wherever an action is a thin wrapper around a function that is only used from that action (and maybe init).

### When *not* to extract

- Multi-caller library used from hooks **and** actions (`hook_ms`, `f_yaml_parse`).
- Must exist before `ASC_INC` (kernel).
- Extracting would force every hook to copy a `.` line (then prefer opt-inc seeding instead — software provision model).

### Suggested sweep order (core + extensions)

Reuse the conversation order; continue where it stopped:

| Area | Status (2026-09-11) | Follow-up |
|---|---|---|
| `utils/arr`, `str`, `fs`, `shell` | In-place opts; some dead removed | Wave A: fs/str tails → opt-inc |
| `core.inc.sh` | list_actions / list_makefiles extracted | Stamp helpers live here or in bootstrap; do not grow core with workflows |
| `global.inc.sh` | write/debug extracted; `foreach` commented | Wave B: aggregate/list/assign/`global()` off the kernel |
| `hook.inc.sh` / `autoload.inc.sh` / `yml.inc.sh` | in-place opts; yaml `printf -v` | Wave A duplicate yaml; Wave D lookup split |
| `instance.inc.sh` | still huge eager | Wave C + extract remaining init-only functions the same way as write_globals |
| `make.inc.sh`, `git.inc.sh`, `host.inc.sh`, `test.inc.sh`, `thread.inc.sh` | eager `ASC_INC` | Same drill: unused drop; one-shot → `$subject/$action.sh`; cross-subject keep opt-inc seeded by hooks |
| Extensions (`entity`, `file_registry`, `compose`, `crontab`, `software`, `remote`, `remote_db`, `remote_instance`, `db`, …) | mixed `*.inc.sh` / `*.opt-inc.sh` | software provision is the **model** (opt-inc next to hook). Repeat: crontab, remote, db, compose aliases. Already lazy: `remote_db/remote/remote.opt-inc.sh`, `remote_instance/db/db.opt-inc.sh`. Builder templates under `asc/extensions/builder/template/` already scaffold `{subject}.opt-inc.sh`. |

Each extension gets the same write-up style as the utility drill: inventory, unused, perf, keep vs move vs drop — **then** implement only what was agreed.

### Concrete “this conversation” leftovers (starting list, not exhaustive)

Confirm with grep before moving.

| Function | Today | Likely class |
|---|---|---|
| `f_git_write_hooks` | `git.inc.sh`; thin `git/write_hooks.sh` | Entry point (move body) |
| `f_make_generate` / `f_make_generate_test_cases` | `make.inc.sh`; init | Entry point or init-only opt-inc |
| `f_make_list_hardcoded` | wrap when `cache/make.sh` missing | Keep small; needed in wrap process |
| `f_instance_init` | `instance.inc.sh`; `init.sh` / `reinit.sh` | Entry-point-adjacent; do not keep 850 lines eager for this |
| `f_instance_yaml_config_load` / `_parse` | instance + aggregate | Shared with init; source from init/opt-inc, not every `make` |
| `f_instance_set_permissions` / ownership | perms hooks | `instance.opt-inc.sh` seeded by those hooks |
| `f_host_crontab_add` / `_remove` | host inc | Workflow / opt-inc |
| `f_host_ip` / `f_host_os` | maybe hooks + software | Grep; may stay in a thin host opt-inc |
| `f_thread_run_*` / parse e-args | thread runners | Entry points already under `thread/`; helpers → `thread.opt-inc.sh` |
| `f_software_*` | already in `provision.opt-inc.sh` | Model — do not “fix” by moving back to `software.inc.sh` |

---

## Pros / cons (high level)

| Approach | Pros | Cons |
|---|---|---|
| **Keep everything in `*.inc.sh`** | Hooks never miss a function. | ~9k lines parsed per `make`; double bootstrap (wrap + action). |
| **Demote unused-at-bootstrap code to `*.opt-inc.sh` (picked)** | Uses existing loaders; hook cache already seeds colocated files; matches README double-extension. | Caveats 1–14; easy to break alias/bootstrap; tests must source the new home. |
| **Move one-shot workflows to entry-point `*.sh` (picked, already started)** | Init helpers not in every shell; Make targets stay obvious. | Callers must `.` or exec; two ways to invoke (source vs `$0`). |
| **Concatenate kernel into `active.sh`** | Fewer files to parse. | Editing `hook.inc.sh` needs `cc`; rejected in the cache plan. |
| **Numbered `asc/bootstrap/*.bootstrap-inc.sh`** | Matches archive docs. | New include graph; not needed to get the parse win. **Out of scope.** |

---

## Implementation waves (when coming back)

0. Prerequisite plan done (stamp + paths + hook keys).  
1. Remove duplicate `yml.inc.sh` from kernel **or** `ASC_INC` (measure nothing else).  
2. Wave A: `fs.inc.sh` / `str.inc.sh` tails; grep + tests.  
3. Wave B: global aggregate off kernel; `make init` / `reinit` still work.  
4. Wave C: one `ASC_INC` subject at a time (`test` first — few production hooks). Move `f_git_write_hooks` into `write_hooks.sh` as the first “this conversation” extraction in that wave.  
5. Continue the **function drill** on `instance`, `make`, `git`, `host`, `thread`, then each enabled extension (inventory → classify → extract/drop).  
6. Optional Wave D: hook lookup builders miss-only.

After each wave: `bash asc/test/core/*.test.sh` that touch the moved symbols; at least one real `make` action that uses a **hook** in that subject (`hook -s asc -a alias -t` after alias-related moves).

---

## Tests (this plan)

- Caller opt-inc: a dummy `asc/test/nftascoptinc.opt-inc.sh` is sourced when `asc/test/core.sh` bootstraps (and **not** when `asc/make/call_wrap.make.sh` is the only caller — assert wrap does not define dummy symbols).
- Hook seeding: existing `test_f_hook_opt_inc_append_candidates`; add a dummy hook + colocated opt-inc, `hook -a …` without `-t`, assert function exists; dry-run `-t` does **not** source it; `-w` writes cache lines without defining the function in that shell.
- After moving `f_fs_compress`: a caller that did not source `fs.opt-inc.sh` fails `type -t`; the compress action succeeds.
- After moving `f_git_write_hooks`: `git.inc.sh` no longer defines it; `write_hooks.sh` sourced after bootstrap defines it; `make git-write-hooks` (or current target name) still works.
- `make cc` still does not delete `global.vars.sh` / `generated.mk` (owned by prerequisite plan).
- No leftover `$(f_*` captures when a moved function already has `printf -v` (same as yaml tests).

---

## Open tasks

- [ ] Wait for [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md).
- [ ] Wave 1: yaml dual-source.
- [ ] Wave A–C as above.
- [ ] Drill remaining `*.inc.sh` (instance → make → git → host → test → thread → extensions).
- [ ] README § Bootstrap / Active Dir: document the **two** loaders, derivation rules, and caveats (1)–(2) (currently one sentence).
- [ ] Align comments that cite missing `90-caller-opt-inc.bootstrap-inc.sh` / `scripts/asc/override/` with code (`bootstrap.sh` / `scripts/asc/override`).
- [ ] Optional: measure wrap vs action bootstrap cost; only then consider a thinner `call_wrap` bootstrap.

---

## Summary pick

| Topic | Pick |
|---|---|
| When | **After** cache/stamp/hook-key plan |
| Lazy mechanism | Existing `*.opt-inc.sh` only (caller phase 90 + hook seed). No third loader. No phase-file rewrite. |
| One-shot functions | Sourcable + executable `$subject/$action.sh` (write_globals / list_actions pattern) |
| Kernel | Stay eager (hook, extend, autoload, arr/str minimum) |
| Biggest parse win | `fs.inc.sh` + drop yaml duplicate + shrink `ASC_INC` (`test`/`git` first) |
| Biggest footgun | Hooks do not get caller opt-incs; alias/bootstrap hooks must keep their callees |
| Broader work | Same 2026-09-11 drill across leftover core + extensions; start with thin wrappers like `git/write_hooks.sh` |
