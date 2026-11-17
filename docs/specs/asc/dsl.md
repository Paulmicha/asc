---
status: draft
updated: 2026-11-17
---

# ASC custom DSL

Draft. **Observed** means present in the mother tree on 2026-11-17.
**Proposed** means a semantic default written here for review.

**Acceptance vs go-ahead:** Setting the `make ds` row in
[`gates.core.yml`](../../../gates.core.yml) to `go: "yes"` **accepts every
proposed semantic default in this file as the implementation contract** for
that work. It does not rewrite README prose; escaped README proposals may
lag. Rejecting or changing a default later needs an explicit plan/spec edit.
Nothing here is authorized until that gate (or a direct human instruction)
says so.

The root [README](../../../README.md) § “ASC domain-specific language : *DSL*
syntax” remains the concept source. This spec restates that grammar as a
working contract, records entry-point facts, and proposes resolutions where
the README contradicts itself or cannot run as written.

Delivery plan: [22-make-ds.md](../../plans/2026/09/22-make-ds.md).

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a
shell variable, except inside explicit shell examples.

## Entry points (observed)

| Piece | Value |
|-------|--------|
| Script | `asc/dsl.sh` |
| Interpreter | `f_asc_dsl` in `asc/core/dsl.manual-inc.sh` (sourced from `asc/bootstrap.sh`) |
| Make pivot | hardcoded `ds` in `asc/make/default.mk` → `call_wrap` → `asc/dsl.sh` |
| Removed | `asc/instance/ds.sh` |

`make ds` and `asc/dsl.sh` are carriers into the interpreter. They are not a
compile-only or print-only tool. A later dry-run or debug print may exist as an
option; it is not the product.

**Gap (observed):** `f_make_list_hardcoded` in `asc/make/make.inc.sh` does not
yet list `ds`, while `default.mk` does. Those two lists must stay in sync for
Make discovery — that is separate from the DSL executable resolver below.

Stubs still print a TODO from `f_asc_dsl`. Behavior below is the target
contract, not claimed runtime.

## Run model (proposed)

`f_asc_dsl` interprets one DSL string: parse, resolve, **run**. It is a Bash
**function**: it **returns** a status. It must not call `exit` for DSL or
test failure (that would kill an in-process hook caller and skip its cleanup).

| Boundary | On failure |
|----------|------------|
| `f_asc_dsl` | `return` non-zero (parse/resolve errors or expression status) |
| `asc/dsl.sh` / `make ds` | process `exit` with that status |
| Generated / YAML embedding that wants a hard stop | caller writes `f_asc_dsl '…' -- "$@" \|\| exit 1` (or equivalent) |

**Expression status:** for a whole DSL string (including chains, pipes,
conditionals), the status is the status of the interpreted expression under
ordinary shell rules for those combinators. A leading `test-*` pivot does
**not** change return-vs-exit; it does not specially inspect only the first
call in a chain. The README’s `\|\| exit 1` sketch is an **embedding**
convention, not something `f_asc_dsl` itself performs.

## Caller binding (proposed)

A Bash function’s `$1` is its own. The DSL string therefore cannot also be the
hook caller’s `$1`. Calling-scope positionals and option forwarders need an
**explicit binding**.

### Interface

```text
f_asc_dsl <dsl-string> [-- <caller-arg>...]
```

| Piece | Role |
|-------|------|
| `<dsl-string>` | The only required argument; the DSL to interpret |
| `--` | Starts the caller argv binding (optional) |
| `<caller-arg>...` | Bound as the calling-scope positionals: `p1`→first, `a`→all, `sN`→all after shift N |

Without `--` (and thus with no bound argv): literal-only DSL may run;
any token that needs caller argv (`p1`, `a`, `sN`, `ba` / `bba` / `oa` /
`ooa`, …) is a hard error.

**Variables (`v-name`):** resolve as `"$name"` in the shell that runs
`f_asc_dsl`. In-process from a hook, Bash dynamic scope makes the caller’s
`local` variables visible to the function. Across a process boundary
(`asc/dsl.sh` / `make ds`), caller locals are **not** visible unless the
carrier exports or otherwise injects them — process carriers document
no `v-` unless a later binding is added.

**YAML `d0` / `d1` / `d2`:** the YAML caller sets shell variables `d0`, `d1`,
… (or a documented equivalent) in the same shell before `f_asc_dsl`, then
uses `dN` tokens in the DSL. Bare `make ds` does not define them.

**Option forwarders (`ba`, `bba`, `oa`, `ooa`):** scan the bound argv after
`--` for matching `-` / `--` forms. Without bound argv → error.

### Examples

Direct / process carrier (literals only):

```sh
asc/dsl.sh 'transcribe-file(path/to/file.mp4)'
# or: make ds 'transcribe-file(path/to/file.mp4)'
```

Direct with bound argv:

```sh
asc/dsl.sh 'slug(p1)' -- 'Foo Bar'
f_asc_dsl 'slug(p1)' -- 'Foo Bar'
```

Hook caller (in-process):

```sh
# Inside a hook implementation that already has its own "$@":
f_asc_dsl 'test-in(p1,slug(p1),snake(p1))' -- "$@"
# On failure: return status to the hook; hook decides whether to exit.
```

YAML / validate-style caller:

```sh
# Field value under test is $1; depth names already set if needed:
d1='bar'
f_asc_dsl 'service-run(d1,a)' -- "$@" || return 1
```

## Pivot resolution (proposed)

**Do not** treat `f_make_list_hardcoded`’s `real_scripts_arr` strings as
always-executable “path plus DSL args.” That list is a Make recipe map: some
paths are wrong relative to `default.mk`, and some entries embed fixed flags
in the same string (for example `hook-debug` → `asc/make/hook.make.sh -d -t`).

### Rules

1. **Discovered pivots** from `f_make_list_entry_points`: the mapped value is
   a script path. Run that path with the resolved DSL arguments. Apply
   `instance-` strip and `ASC_SYNONYMS` as make does.
2. **Hardcoded pivots** used from DSL: only names that map to **exactly one
   script path and no embedded flags**. Maintain that mapping explicitly for
   DSL (a dedicated table or a filtered view kept aligned with
   `default.mk`). Today’s Make list is not that table until cleaned up.
3. **Compound Make recipes** (`init-debug`, `hook-debug`, and any other
   path-plus-fixed-flags entry) are **not** DSL pivot names. Express debug
   behavior with DSL option tokens on the base pivot, or call the script
   outside DSL.
4. **Hygiene (plan task):** align `f_make_list_hardcoded` with what
   `default.mk` actually runs (for example `init` → `asc/instance/init.sh`,
   not a nonexistent `init.make.sh`), and add `ds` → `asc/dsl.sh`. DSL tests
   must cover at least one discovered pivot and one hardcoded-but-clean
   pivot, and must assert that a compound recipe name is rejected.

**Run form:** always the resolved script path plus arguments (never
`make $pivot` as the executed form). Nested ASC pivots use command
substitution:

```sh
asc/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')"
```

Unknown pivot: return non-zero, message on stderr, no partial run.

## Grammar inventory

Labels match the README section order. **R** = restated from README.
**P** = proposed default where README is incomplete or contradictory.

### Pivots (R)

Same names as make entry points that the resolver accepts under the rules
above. Examples: `start`, `service-rebuild`, `transcribe-file`, `test-in`,
`slug`.

Bare name with no `()` runs the resolved script with no arguments.

### Literal arguments (R + P)

`name(arg1,arg2,…)` — commas separate arguments. Special characters are
usually forbidden. Substitutions:

| DSL | Meaning |
|-----|---------|
| `%` | `*` |
| `%%` | `**` |

**P — characters inside one unquoted literal value:** allow letters, digits,
and `.`, `/`, `_`, `-`, plus `*` after `%` expansion. Reject space, comma, or
parentheses inside an unquoted value until a later spelling exists. Reject
empty DSL string.

**P — reserved spellings vs literals:** unquoted `a`, `pN`, `sN`, `v-…`,
`dN`, option tokens (`b-…`, `bb-…`, `o-…`, …), and forwarders (`ba`, `bba`,
`oa`, `ooa`) are **tokens**, never bare literals. To pass such a string as
data, write a **single-quoted literal**:

| DSL fragment | Meaning |
|--------------|---------|
| `slug(p1)` | positional token (needs caller binding) |
| `slug('p1')` | literal argument whose value is `p1` |
| `echo('a')` | literal `a` (still needs `[echo(…)]` if `echo` is a function) |

Unquoted reserved forms without a required binding → error (same as missing
calling scope). Quoted forms never consult calling scope.

### Positional and forwarding tokens (R)

| Token | Meaning |
|-------|---------|
| `p1`, `p2`, … | first, second, … bound caller arg |
| `a` | all bound caller args |
| `s1`, `s2`, … | all bound caller args after shifting N |

### Boolean options (R)

| Token | Meaning |
|-------|---------|
| `b-y` | `-y` |
| `bb-oneline` | `--oneline` |
| `ba` | all single-dash boolean options from bound argv |
| `bba` | all double-dash boolean options from bound argv |

### Named options (R)

| Token | Meaning |
|-------|---------|
| `o-m-4` | `-m 4` |
| `oo-max-4` | `--max 4` |
| `oe-max-4` | `-max=4` |
| `ooe-max-4` | `--max=4` |
| `oa` / `ooa` | forward matching named options from bound argv |

### Variables (R)

`v-name` → `"$name"` in the interpreter’s shell (see Caller binding).

### Functions (R + P)

`[name(…)]` calls a **whitelisted** bash function (or allowlisted builtin).

**P — whitelist:** deny by default. Unknown name inside `[]` is an error.
Ship an explicit list (start small; `echo` only if listed). ASC pivots are
**not** required to use `[]`; they use bare `name(…)`.

**P — nesting:**

- ASC pivot nested as an argument: `outer(…,inner(…),…)` → outer args include
  `"$(resolved/inner.sh …)"`.
- Function nested as an argument: only inside `[]`, and only if whitelisted:
  `[f_db_clear(slug(p1))]` → `f_db_clear "$(asc/instance/slug.sh …)"` when
  `slug` is an ASC pivot; or `f_db_clear "$(slug …)"` only when `slug` is on
  the function whitelist and written as `[slug(…)]`.

README example `[f_db_clear([slug(p1)])]` is treated as the function-nesting
form; prefer `[f_db_clear(slug(p1))]` when `slug` is an ASC pivot.

### Combinators (R + P)

| DSL | Shell |
|-----|--------|
| `;` | `;` (sequence) |
| `;;` | `&&` |
| `-;-` | `& … ; wait` (parallel) |
| `+` | `\|` (pipe) |
| `++` | `\|\|` |
| `--` | `>` redirect |
| `---` | `>>` redirect |

**P — brackets on chained calls:** `[]` only when that call is a whitelisted
function or builtin. Bare names are ASC pivots only. There is **no**
bare-builtin rule. Corrected chaining example (both calls are functions):

```text
[echo(v-baz)];[echo(foobar)]
```

→ `echo "$baz" ; echo 'foobar'` when `echo` is on the whitelist. Bare
`echo(foobar)` would look up an ASC pivot named `echo` and fail if none
exists.

### Loops (R)

Array items:

```text
[[echo(v-item)]v-foobar_arr]
```

→ `for item in "${foobar_arr[@]}"; do …; done`

Output lines (iterator in `[]` or a resolvable producer):

```text
[[echo(v-item)]myfunc]
```

→ `while read -r item; do …; done < <(myfunc)`

Loop `[[…]]` is DSL syntax, not bash `[[`.

### `test-*` (R + P)

README says any DSL starting with `test-*` becomes
`[[ */test/*.sh ]] || exit 1`. That `[[ … ]]` form is invalid bash for running
a command.

**P:** resolve and run under the normal run model. `f_asc_dsl` **returns**
the expression status (non-zero on failure). It does not `exit`. Do not emit
or eval bash `[[ … ]]`.

Valid Bash for docs and embeddings (caller-owned `exit`):

```sh
asc/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')" || exit 1
```

In-process:

```sh
f_asc_dsl 'test-in(p1,slug(p1),snake(p1))' -- "$@" || return 1
```

## Proposed resolutions (summary)

| Topic | Proposed default |
|-------|------------------|
| Caller binding | `f_asc_dsl <dsl> [-- <caller-arg>…]`; `v-` / `dN` from shell scope |
| Status | Function **returns**; process carrier may **exit**; embeddings use `\|\| exit 1` |
| Expression status | Whole DSL string, shell-like combinator rules |
| Nesting brackets | `[]` = whitelist only; pivots nest as `name(…)` → `"$(script …)"` |
| Chained brackets | Same rule; example uses `[echo(…)];[echo(…)]` |
| Run form | Resolved script path (or function call), never `make …` |
| Pivot lists | Entry-points = paths; hardcoded DSL map = path only, no embedded flags; compound Make names rejected |
| `test-*` | No bash `[[ command ]]`; return status; no `exit` inside `f_asc_dsl` |
| Function whitelist | Deny by default; explicit list |
| Reserved literals | Unquoted = tokens; single-quoted = literal data |
| Gate acceptance | `go: yes` on make-ds accepts these proposed semantics for implementation |

## Gaps and improvements

| Item | Notes |
|------|-------|
| Make carrier | GNU make treats `%`, `=`, `#`, `$` specially. Prefer tests via `asc/dsl.sh`. `%` through `make ds` needs an explicit carrier test. |
| `escape.sh` kinship | Top-level script + hardcoded make entry (like `asc/escape.sh`), but DSL **does** bootstrap because it needs ASC helpers. |
| Filename-safe hooks | README allows hook filenames containing DSL; single-quoted literals are for interpreter strings, not a claim that quotes appear in hook filenames. |
| Whitelist contents | Not listed in README; must be named in code and tests. |
| Hardcoded list hygiene | `init.make.sh` vs `init.sh`, embedded flags — fix Make list and keep a DSL-safe path map. |
| Stale design notes | `data/ideas/2026/08/A simple, minimal DSL for ASC.md` and `data/ideas/2026/07/23/dsl.md` disagree with the README. Implement from README + this spec. |
| Coverage waves | Interpreter framing is fixed; grammar *coverage* may land in waves under [22-make-ds.md](../../plans/2026/09/22-make-ds.md). Print-only is abandoned. |

## Observed vs proposed vs not decided

| Kind | Content |
|------|---------|
| Observed | `asc/dsl.sh`, `dsl.manual-inc.sh`, bootstrap source, hardcoded `make ds`, removal of `asc/instance/ds.sh`, README grammar text, stub TODO body, mismatched hardcoded Make paths/flags |
| Proposed | Run model, caller binding, return-vs-exit, pivot resolution rules, resolutions table, reserved literal quoting, chaining example fix |
| Locked by commits only | Entry-point **shape** (paths, hardcoded `ds`, `f_asc_dsl` stub) — not the full semantic table |
| Not decided | Exact whitelist membership; whether dry-run print becomes a flag; filename-hook compiler as a separate entry; optional process-carrier binding for `v-` |
