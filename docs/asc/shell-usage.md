# ASC core concept : Shell usage

Table of contents :

1. [stdin / stdout / stderr](#stdin--stdout--stderr)
1. [sourcing](#sourcing)
1. [argument forwarding](#argument-forwarding)
1. [shell options](#shell-options)
1. [scope](#scope)
1. [walk arrays](#walk-arrays)
1. [step by step](#step-by-step)
    1. [`$subject/$action.sh` entry point](#subjectactionsh-entry-point)
    1. [hooks](#hooks)
    1. [`call_wrap.make.sh`](#call_wrapmakesh)
    1. [logged-\* entry points](#logged--entry-points)
1. [filename-DSL examples](#filename-dsl-examples)
1. [proposed DSL redesign (README)](#proposed-dsl-redesign-readme)
1. [parsable stdout (asc-dsl / asc-yml)](#parsable-stdout-asc-dsl--asc-yml)

How ASC leans on **bash** primitives — streams, source, `"$@"`, `shopt`/`set`, relative scope, and array walks — so entry points, hooks, wraps, and make stay thin and composable.

Related living pages: [organization.md](organization.md), [wrappers.md](wrappers.md), [documentation.md](documentation.md) § `$` notation. Plan SoT for filename grammar: `changelog/2026/07/24-filename-dsl.md`.

Docs `$` notation: `$name` = any make entry point. **Exception — `$subject` (only):** plain slugified string, **or** (for `*.hook.yml` / `*.hook.sh`) custom DSL notation.

---

## stdin / stdout / stderr

ASC treats the three standard streams as first-class composition surfaces.

| Stream | Typical ASC use |
|--------|-----------------|
| **stdin** | Closed under wraps (`</dev/null`) so noninteractive jobs fail fast on prompts; real pipes feed stage *N* from stage *N−1* |
| **stdout** | Operator-facing progress (`echo "Thread started…"`); under log wrap, redirected into `data/logs/<entry>.txt` |
| **stderr** | Errors (`echo >&2`); merged with stdout under log capture (`2>&1`) |

### Redirection (canonical patterns in tip)

```bash
# Errors only (never pollute captured job output with diagnostics)
echo "Error in $BASH_SOURCE line $LINENO …" >&2

# Silence helper noise
kill -0 "$pid" 2>/dev/null
pushd "$p_path" >/dev/null

# Log wrap storage: no stdin; stdout+stderr → log file
nohup "$p_script" "$@" </dev/null > "$log_file" 2>&1 &

# Thread wrap (no log wrap): background + append both streams
( u_thread_supervised_run "$@" ) >> "$p_output" 2>&1 </dev/null &

# Thread wrap inner run: close stdin, leave streams to parent/log
"$p_script_real" "$@" </dev/null
```

SoT: `asc/log/storage.hook.sh`, `asc/thread/thread.wrap.sh`.

### Piping

`asc/thread/pipe.sh` builds a real shell `|` chain under **`set -o pipefail`** (≥2 stages). Stages are either:

| Token | Runs as |
|-------|---------|
| bare string | `bash -c -- "$stage"` |
| `e:<entry>` | `make <entry>` (+ optional `a:<arg>` for that stage) |

```bash
make pipe 'ls -lah' 'grep foobar'
make lp e:blueprint-generate e:transcribe-all   # logged-pipe
```

Join of ordered make steps that are **not** I/O pipes uses `&&` / `;` in sequence/chain wrappers — see [wrappers.md](wrappers.md) § pipe / sequence / chain.

---

## sourcing

ASC is mostly **sourced**, not forked, for bootstrap and hooks. Execution vs source changes what `$0` / `BASH_SOURCE` mean and whether options/locals leak into the caller.

### Without params (include bodies)

```bash
. asc/bootstrap.sh
. asc/bootstrap/10-shell.bootstrap-inc.sh
. data/asc/cache/make.sh
. "$hook_most_specific_dry_run_match"   # after dry-run resolve
```

Eager `*.inc.sh` and lazy `*.opt-inc.sh` are include bodies (not hook implementations). Planned: one include-loader hook selects by `ASC_SHELL` — see filename-DSL plan.

### With params (decorated / wrapped source)

Bash lets you pass positional parameters to a sourced file:

```bash
# Outer wrap sources/runs an inner wrap with remaining args
. asc/log/wrap.sh asc/thread/wrap.sh $@

# Log wrap resolves storage hook, then sources the match with forwarded args
. "$hook_most_specific_dry_run_match" "$@"
```

That is how **nested wraps** stack: the sourced script sees `$1` = next script/entry, `$@` = payload. Same idea as filename-DSL `foo(bar)` (outer wraps inner) — plan SoT, not fully parsed yet.

### Bootstrap caller detection

```bash
# bootstrap.sh: BASH_SOURCE[0] = bootstrap; [1] = real caller → phase 90 opt-inc
_asc_bs_caller="${BASH_SOURCE[1]}"
. asc/bootstrap/90-caller-opt-inc.bootstrap-inc.sh
```

Every `$subject/$action.sh` starts with `. asc/bootstrap.sh` from `$PROJECT_DOCROOT`. Phases 10–70 once per shell (`ASC_BS_FLAG`); phase 90 every source.

---

## argument forwarding

| Layer | Mechanism | Notes |
|-------|-----------|-------|
| Script → script | `"$@"` / `$@` after `shift` | Prefer `"$@"`; tip still has some unquoted `$@` on wrap stacks |
| Make → script | `call_wrap.make.sh` | Escapes, rejects reserved make entry names, `eval` real script |
| Awkward make args | `asc/escape.sh` | Swaps `$` / `=` etc. so make does not eat them; unwrap in `u_make_unescape` |
| Named make → hook | `a:` / `s:` / `v:` … | `hook.make.sh` rewrites to `-a '…' -s '…'` |
| Logged runners | `e:<entry>`, `a:<arg>`, `e:1:…` | Repeatable notation — see [organization.md](organization.md) § make shortcuts |

### Forwarding pattern (wraps)

```bash
p_script="$1"
shift
# … validate / rewrite …
"$p_script_real" "$@" </dev/null
# or:
. asc/log/wrap.sh asc/thread/wrap.sh $@
```

### Make named args → hook flags

```text
make hook s:instance a:start
  → call_wrap → hook.make.sh
  → hook -s 'instance' -a 'start'
```

Spaces in named values: enter **without** shell quotes on the make line; `hook.make.sh` adds quotes.

### Space-safe make args

```bash
# Wrong: make splits on spaces
make debug arg1 'arg2 with space'

# Right: nested quotes survive make → call_wrap
make debug arg1 "'arg2 with space'"

# Or escape helper for $ / = / quotes
make drush ev $(asc/escape.sh '$test = "hi"; print $test;')
```

---

## shell options

ASC turns options **on for a span**, then **off**, so callers are not permanently mutated.

| Option | Where | Pattern |
|--------|-------|---------|
| `expand_aliases` | bootstrap phase 10 | `shopt -s expand_aliases` (once; non-interactive shells need it) |
| `nullglob` | thread list/monitor, loop status, cron | `shopt -s nullglob` … work … `shopt -u nullglob` |
| `dotglob` | `u_fs_*` dir walks | `shopt -s dotglob` … `shopt -u dotglob` |
| `globstar` | crontab peer scan | `shopt -s nullglob globstar` … unset both |
| `pipefail` | `u_thread_run_pipe` | `set -o pipefail` for the `|` eval |
| `-e` (errexit) | `wait_for` | `set -e` … retries … `set +e` |

### Wrapped on/off skeleton (canonical)

```bash
shopt -s nullglob
# … only this block sees empty globs as nothing …
shopt -u nullglob

set -e
# … fail-fast span …
set +e
```

Do **not** leave `set -e` or `nullglob` on across bootstrap/hook boundaries unless the contract is intentional (bootstrap keeps `expand_aliases`).

---

## scope

### Relative paths = `$PROJECT_DOCROOT`

All ASC scripts and make targets assume **cwd = project docroot**. Relative paths (`asc/…`, `data/logs/…`, `data/asc/cache/…`) are resolved from there — not from the script’s directory.

```bash
. asc/bootstrap.sh          # must be run from PROJECT_DOCROOT
data/logs/${entry}.txt      # relative durable path
```

Overrides mirror under `scripts/asc/override/` (autoload). Nested ASC (`nested-asc-exec`) starts a **new** bootstrap in the child docroot (`env -i` allowlist).

### Entry point “position”

| Position | Meaning |
|----------|---------|
| **Subject / action file** | `$subject/$action.sh` — operable unit; becomes a make entry after `reinit` |
| **Nested** | Child subject/extension via path segments or (planned) DSL `.` nest: `foo.bar` |
| **Wrapped / decorated** | Outer script receives inner path or entry as `$1`, forwards `"$@"` — runtime stack (`log.wrap` → `thread.wrap` → entry). Planned DSL: `foo(bar)` |
| **Named vs positional** | Make `e:` / `a:` / `s:` named tokens; scripts still see positionals after rewrite |

Generic → specific discovery (bottom wins for most-specific hooks):

```text
asc/$subject/$action
asc/extensions/…/$subject/$action
scripts/asc/contrib/…
scripts/asc/extend/$subject/$action
```

Hook stems (including future DSL) sit **directly under `$subject/`**, not under `$subject/$action/`.

---

## walk arrays

Bash 4+ patterns ASC uses everywhere (utils, make lists, hooks, dumps).

### Indexed array — walk values

```bash
declare -a items=("a" "b" "c")

for val in "${items[@]}"; do
  echo "$val"
done
```

### Indexed array — walk keys (indices), then values

```bash
for i in "${!items[@]}"; do
  echo "$i=${items[$i]}"
done

# Parallel arrays (make entry ↔ real script)
for index in "${!real_scripts[@]}"; do
  task="${make_entries[index]}"
  script="${real_scripts[index]}"
done
```

### Associative array (dictionary) — walk keys (props)

```bash
declare -A dumps_dict=([prod]="a.sql" [dev]="b.sql")

for key in "${!dumps_dict[@]}"; do
  echo "prop=$key"
done
```

### Associative array — walk values

```bash
for key in "${!dumps_dict[@]}"; do
  echo "${dumps_dict[$key]}"
done

# Or values only (order not defined)
for val in "${dumps_dict[@]}"; do
  echo "$val"
done
```

### Debug both shapes

```bash
u_array_print dumps_dict   # key=value lines; works for -a and -A
# @see asc/asc/utils/arr/arr.opt-inc.sh
```

Synonyms in ASC prose: **associative array** = **dictionary**; **keys** = **props**.

---

## step by step

### `$subject/$action.sh` entry point

Example: `make start` → generated target → `asc/instance/start.sh` (names illustrative).

1. **Make** expands the short/synonym name to a recipe that calls `asc/make/call_wrap.make.sh <real_script> <goals…>` (see [call_wrap](#call_wrapmakesh)).
2. **call_wrap** bootstraps, checks the script exists, rejects args that collide with other make entry names, unescapes/requotes, then `eval`s the real script with safe args.
3. **Action script** runs `. asc/bootstrap.sh` from `$PROJECT_DOCROOT`.
4. Bootstrap: phases 10–70 once; phase **90** loads `$subject/$subject.opt-inc.sh` and `$subject/$action.opt-inc.sh` for this caller.
5. Body runs (often `hook …` and/or a wrap). Relative I/O lands under `data/…`.
6. Exit status propagates back through `eval` → make.

Direct (skip make): `asc/instance/logged_thread.sh transcribe-all` still bootstraps the same way.

---

### hooks

`hook` / `u_hook_most_specific` build lookup paths from `-s` / `-a` / `-p` / `-v` / … and **source** matching `*.hook.sh` (or `-c yml`, etc.).

#### Simple example

```bash
make hook s:instance a:start
# → hook -s 'instance' -a 'start'
# → sources matching …/instance/start.hook.sh (and variants if -v)
```

Steps:

1. `call_wrap` → `hook.make.sh` rewrites `s:`/`a:` → `-s`/`-a`.
2. `hook()` builds/caches lookup list under `data/asc/cache/hook.*.sh`.
3. For each match: resolve override (`scripts/asc/override/…`), seed colocated `*.opt-inc.sh`, **source** the body in current shell (shares globals/locals with caller).
4. Default `-v` when omitted: often `INSTANCE_TYPE`. Dry-run: `make hook-debug …` (`-t`).

#### Contrived example

```bash
make hook-debug s:instance a:start v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
```

Steps:

1. Same rewrite as above, plus `-d -t` (debug + dry-run).
2. Variant globals expand via `u_str_subsequences` into dotted filenames, e.g. `start.local.dev.hook.sh`.
3. `PROVISION_USING=compose` dual-expands to `compose` **and** `docker-compose` tokens.
4. Dry-run **lists** matches (does not source). Drop `-t` / use plain `make hook …` to execute.
5. Most-specific only: `make hook-debug ms s:instance a:stop v:PROVISION_USING HOST_TYPE` → `u_hook_most_specific dry-run …`.

SoT: [organization.md](organization.md) § hooks, `docs/asc/archive/hooks.md`, `asc/asc/hook.inc.sh`.

---

### `call_wrap.make.sh`

Hardcoded and generated make recipes funnel through this gate so make’s “everything is a target” model does not steal args.

#### Simple example

```bash
make debug hello
# default.mk →
#   asc/make/call_wrap.make.sh asc/make/echo.make.sh debug hello
```

Steps:

1. `$1` = real script (`asc/make/echo.make.sh`); must exist.
2. `$2` = invoked make target (`debug`); shifted away from script args.
3. Load `data/asc/cache/make.sh` (or hardcoded list) of all entry names.
4. Remaining args checked: if any equals a make entry name → abort with “use `$p_real_script …` instead”.
5. Each arg: `u_make_unescape` + single-quote escape → `escaped_args`.
6. `eval "$p_real_script $escaped_args"` → echo script prints `hello`.

#### Contrived example

```bash
make debug arg1 "'arg2 with space'" arg3
# Real call:
#   asc/make/echo.make.sh arg1 'arg2 with space' arg3
```

Steps:

1. Same gate; `arg2 with space` survives as **one** positional thanks to nested quotes.
2. If you passed a value equal to e.g. `init`, call_wrap would refuse and tell you to invoke the script path directly.
3. Test runner special-case: `*/test/case.run.sh` also forwards the invoked make target via `printf '%q'`.

Escape helper for `$` / `=` / quotes: `asc/escape.sh` (intentionally **outside** bootstrap includes).

---

### logged-\* entry points

Logged shortcuts stack **pre hooks → log wrap → inner wrap → post hooks**. Synonyms: `lt` / `ll` / `lc` / `ls` / `lb` / `lp` (`ASC_SYNONYMS`).

| Make | Script | Inner stack |
|------|--------|-------------|
| `lt` / `logged-thread` | `asc/instance/logged_thread.sh` | `log.wrap` → `thread.wrap` → entry |
| `ll` / `logged-loop` | `logged_loop.sh` | `log.wrap` → `loop.wrap` → entry |
| `lc` / `logged-chain` | `logged_chain.sh` | `log.wrap` → `instance/chain` → sequence |
| `ls` / `logged-sequence` | `logged_sequence.sh` | `log.wrap` → `thread/sequence` |
| `lb` / `logged-batch` | `logged_batch.sh` | `log.wrap` → `thread/batch` |
| `lp` / `logged-pipe` | `logged_pipe.sh` | `log.wrap` → `thread/pipe` |

#### Simple example — logged thread

```bash
make lt e:transcribe-all
```

Steps:

1. Make → `call_wrap` → `logged_thread.sh`.
2. Bootstrap; strip `e:` from first arg; export `LOGGED_THREAD_ENTRY`.
3. **Pre:** `hook -s log -p pre -a logged_thread` then same for `thread`.
4. **Process:** `. asc/log/wrap.sh asc/thread/wrap.sh $@`
   - log wrap validates make entry, resolves `log`/`storage` hook, sources it;
   - storage sets `ASC_LOG_WRAP_ACTIVE`, runs job with `</dev/null > data/logs/….txt 2>&1`;
   - when composed with thread wrap, thread supervises PID/YAML under `data/threads/`, stdin `/dev/null`, retries optional.
5. **Post:** `log` then `thread` `post` hooks.
6. Artifacts: `data/logs/<entry>.txt` + `.sidecar.txt`; `data/threads/<entry>.yml`.

#### Contrived example — logged pipe of mixed stages

```bash
make lp e:site-composer a:install 'grep -i done'
```

Steps:

1. Same pre/post hook sandwich for `logged_pipe` (`log` + `pipe` subjects).
2. `log.wrap` → `thread/pipe.sh` with remaining args.
3. Parser builds stages: make `site-composer` with arg `install`, then `bash -c -- 'grep -i done'`.
4. `u_thread_run_pipe`: `set -o pipefail`; `eval` `{ make … ; } | { bash -c -- … ; }`.
5. Log wrap still owns the durable stdout/stderr file when used via `lp`; plain `make pipe` skips log wrap.

See [wrappers.md](wrappers.md) for chooser guidance (`lt` vs `ll` vs `lc` / `ls` / `lb` / `lp`).

---

## filename-DSL examples

**Plan-only** grammar (not implemented until accepted). Punctuation SoT: `()` = **wrap**, `.` = **nest**, `[]` = **args**. Full SoT: `changelog/2026/07/24-filename-dsl.md`.

Realistic stems under any `$subject/` (DSL hooks sit **directly under `$subject/`**):

### 1. Simple wrapped source hook

```text
$subject/entity_yml[state](p-1).is_default.hook.yml
```

| Fragment | Reading |
|----------|---------|
| `source(code)` | **wrap** — `source` wraps `code` |
| `.available.hook.sh` | hook event / variant suffix |

### 2. Logged-thread style stack (custom shell)

```text
$subject/lt(agent[role-prompt-analyst].start[loop.heartbeat](data[inbox].unread).start.hook.sh
```

| Fragment | Reading |
|----------|---------|
| `lt(…)` | **wrap** — logged-thread stack |
| `agent[role-prompt-analyst]` | **arg** positional freeform |
| `.start` | **nest** under agent |
| `start[loop.heartbeat]` | **arg** + nested token |
| `(data[inbox].unread)` | **wrap** of nested data path |
| `.start.hook.sh` | hook suffix |

Same stem with `.hook.yml` → smart YAML defaults; **`slot` lives in the YAML body**, not as `…[slot]` in the filename.

### 3. Nest / wrap test steps + short synonyms

```text
log.level_get.hook.sh
log.level_set[debug].hook.sh
ll(log.level_get).hook.sh
lt(log.level_set[info]).hook.sh
llv-get.hook.sh                 # synonym atom ≡ log.level_get
llv-set[warn].hook.sh
test(log.level_get).hook.sh
test.assert(log.level_set[debug]).hook.sh
```

| Construct | Shape | Matching action |
|-----------|--------|-----------------|
| Wrap | `foo(bar)` | `wrap` |
| Nest | `foo.bar` | `nest` |
| Args | `foo[bar]`, `foo[b-oneline]`, `foo[bar,o-x]` | positional / `b-*` / `o-*` → `p_` / `b_` / `o_` |
| Field | `($field.able.subject)--($field.able.object)` | via `$action.able.yml` |
| Triple | `($triple.able.subject)--($triple.able.predicate)--($triple.able.object)` | via `$action.able.yml` |

### 4. Shell-qualified includes (multi-shell groundwork)

```text
asc/asc/utils/shell.opt-inc.sh           # bash default + fallback
asc/asc/utils/shell.zsh.opt-inc.sh       # alternate if ASC_SHELL=zsh and file exists
```

Loader policy (planned): try `*.$ASC_SHELL.(opt-)inc.sh` if present; else unqualified bash set. Includes are **not** hook implementations; one dedicated include-loader hook selects them.

### Quick card

```text
foo(bar)              → wrap
foo.bar               → nest
foo[bar]              → positional arg  → p_
foo[b-oneline]        → boolean         → b_
foo[bar,o-option]     → option | arg    → o_ / p_
retention-5m          → first '-' head|tail (intra-token)
db_dump.sh            → optional '_' prefix reading (docs/convention; not enforced)
```

When the plan is accepted and wired, living pages ([organization.md](organization.md), [wrappers.md](wrappers.md)) stay the runtime SoT; this section only mirrors the changelog examples for shell-minded readers.

---

## proposed DSL redesign (README)

**Status:** competing proposal from root README § Current status — **not** accepted. Until a changelog supersedes `changelog/2026/07/24-filename-dsl.md`, the locked punctuation above (`()` wrap, `[]` args, `p_`/`o_`/`b_`) remains SoT.

Proposed changes:

| Locked (plan) | Proposed (README) |
|---------------|-------------------|
| `()` = wrap, `[]` = args | **Invert** `(` and `[` |
| positional → `p_` / `p-1` | positional → `a` / `a-1` |
| boolean → `b-*` / `b_` | boolean → `bo-*` / `bo_` |
| option → `o-*` / `o_` | option → `o-*` / `o_` (same letter) |

Filename-safe example:

```text
# locked plan shape
test-is[either](slot.slug[-],slot.slug[_])

# proposed shape
test(a-1).is-either(slug(a-1,-),slug(a-1,_))
```

Auto-convert sketch (shrink all `--` to `-` in prefixed syntax):

| Token | Meaning |
|-------|---------|
| `a` | `$@` |
| `a-1` | `$1` (`a-$n`) |
| `a-1s` | rest after 1 shift (`a-2s` = after 2, …) |
| `bo-oneline` | `--oneline` |
| `bo-y` | `-y` (any boolean option) |
| `o-max-4` | `--max=4` or `--max 4` or `-m 4` |

`dsl()` (like `hook()`) would prepare calling-scope vars before evaluating:

```sh
a="$@"
a_1="$1"
# … a_2 … a_9
# TODO a_1s, a_2s (shifted rest)

o_s=''; o_h=''; bo_y=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--hook) export o_h="$2" ; shift 2 ;;
    -s|--scope) export o_s="$2" ; shift 2 ;;
    -y|-yes) export bo_y=1 ; shift 1 ;;
  esac
done
```

Frozen DSL entry points (open): empty path markers like `blueprint-var.field(type,a-1).dsl.hook` (gitkeep-style) and/or `.dsl.hook.yml` with `a` / `o` validation. Finally: make should understand DSL. Do **not** implement until this proposal is accepted or rejected in a dated changelog.

---

## parsable stdout (asc-dsl / asc-yml)

Design: emit machine-catchable blocks at the end of human-readable stdout for prompts / agents:

```html
Error message, any stdout output... With at the end :

<asc-dsl>
Dsl ?
</asc-dsl>
```

and / or:

```html
<asc-yml>
required:
  foobar: <slot/> ?
optional:
  foobar: <slot/> ?
</asc-yml>
```

Those blocks can be templates (string `tpl()` / `u_str_convert_tokens`, file `*.tpl.html`, or dir templates) — see [builder.md](builder.md) § templates. Not implemented; keep stderr diagnostics separate from captured job stdout (see § stdin / stdout / stderr).
