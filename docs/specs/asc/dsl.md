---
status: draft
updated: 2026-11-17
---

# ASC custom DSL

Draft. **Observed** means present in the mother tree on 2026-11-17. **Proposed**
means the default an implementer should follow until a human accepts it into
the README or rejects it. Nothing proposed here is a gates go-ahead.

The root [README](../../../README.md) § “ASC domain-specific language : *DSL*
syntax” remains the concept source. This spec restates that grammar as a
working contract, records entry-point facts, and proposes resolutions where
the README contradicts itself or cannot run as written.

Delivery plan: [22-make-ds.md](../../plans/2026/09/22-make-ds.md). Authorization:
[`gates.core.yml`](../../../gates.core.yml) when `INSTANCE_TYPE` is `core`.

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
yet list `ds`, while `default.mk` does. Those two lists must stay in sync.

Stubs still print a TODO from `f_asc_dsl`. Behavior below is the target
contract, not claimed runtime.

## Run model (proposed)

`f_asc_dsl` interprets one DSL string: parse, resolve, **run**. Exit status is
the status of the interpreted command (or non-zero on parse/resolve errors).

Resolution of an ASC pivot name reuses the same make pivot lists as other
entry points (`f_make_list_hardcoded`, `f_make_list_entry_points`), including
`instance-` strip and `ASC_SYNONYMS`. Unknown pivot: non-zero, message on
stderr, no partial run.

**Compile / run form:** always the resolved script path plus arguments (never
`make $pivot` as the executed form). Nested ASC pivots run via command
substitution:

```sh
asc/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')"
```

## Grammar inventory

Labels match the README section order. **R** = restated from README.
**P** = proposed default where README is incomplete or contradictory.

### Pivots (R)

Same names as make entry points. Examples: `start`, `service-rebuild`,
`transcribe-file`, `test-in`, `slug`.

Bare name with no `()` runs the resolved script with no arguments.

### Literal arguments (R)

`name(arg1,arg2,…)` — commas separate arguments. Special characters are
usually forbidden. Substitutions:

| DSL | Meaning |
|-----|---------|
| `%` | `*` |
| `%%` | `**` |

**P — characters inside one literal value:** allow letters, digits, and
`.`, `/`, `_`, `-`, plus `*` after `%` expansion. Reject space, comma, or
parentheses inside a value until a later spelling exists. Reject empty DSL
string.

### Positional and forwarding tokens (R)

| Token | Meaning |
|-------|---------|
| `p1`, `p2`, … | `$1`, `$2`, … |
| `a` | `"$@"` |
| `s1`, `s2`, … | `"$@"` after shifting N |

### Boolean options (R)

| Token | Meaning |
|-------|---------|
| `b-y` | `-y` |
| `bb-oneline` | `--oneline` |
| `ba` | all single-dash boolean options from calling scope |
| `bba` | all double-dash boolean options from calling scope |

### Named options (R)

| Token | Meaning |
|-------|---------|
| `o-m-4` | `-m 4` |
| `oo-max-4` | `--max 4` |
| `oe-max-4` | `-max=4` |
| `ooe-max-4` | `--max=4` |
| `oa` / `ooa` | forward matching named options from calling scope |

### Variables (R)

`v-name` → `"$name"` from the (hook) calling scope.

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

**P — brackets on chained calls:** `[]` only when that call is a function.
Bare pivots need no brackets. `[echo(v-baz)];echo(foobar)` keeps `[]` on
`echo` only if `echo` is whitelisted; the second `echo(foobar)` is the same
rule applied to the next call.

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

**P:** resolve and run the test script normally. After a top-level DSL whose
leading pivot matches `test-*`, if the command status is non-zero, `f_asc_dsl`
exits `1`. Do not emit or eval bash `[[ … ]]`. Equivalent shell sketch for
docs and embeddings:

```sh
asc/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')" || exit 1
```

### YAML `d0` / `d1` / `d2` (R context)

README and older plans mention YAML depth tokens as calling-scope values.
**P:** same rule as other calling-scope tokens (below). Not available from a
bare `make ds` with no caller binding them.

### Calling scope (P)

When `f_asc_dsl` runs **with** a hook (or other) calling scope, positional,
`v-`, option forwarders, and YAML `dN` resolve from that scope.

When invoked as `make ds '…'` / `asc/dsl.sh '…'` **without** those bindings:

- Literal-only calls run.
- Any calling-scope token (`p1`, `a`, `sN`, `v-`, `ba` / `bba` / `oa` /
  `ooa`, `d0` / `d1` / `d2`, and redirects that need `v-`) → hard error,
  non-zero, no partial run.

## Proposed resolutions (summary)

| Topic | Proposed default |
|-------|------------------|
| Nesting brackets | `[]` = whitelisted function only; ASC pivots nest as `name(…)` → `"$(script …)"` |
| Chained brackets | Same rule per call; do not require `[]` on pivots |
| Run form | Always resolved script path (or function call), never `make …` |
| `test-*` | Run script; on failure exit `1`; no bash `[[ command ]]` |
| Function whitelist | Deny by default; explicit list |
| No calling scope | Calling-scope tokens error; literals still run |
| Literal charset | Alphanumeric + `.` `/` `_` `-` and post-`%` `*`; reject space/comma/`()` inside a value |

## Gaps and improvements

| Item | Notes |
|------|-------|
| Make carrier | GNU make treats `%`, `=`, `#`, `$` specially. Prefer tests via `asc/dsl.sh`. `%` through `make ds` needs an explicit carrier test. |
| `escape.sh` kinship | Top-level script + hardcoded make entry (like `asc/escape.sh`), but DSL **does** bootstrap because it needs ASC helpers. |
| Filename-safe hooks | README allows hook filenames containing DSL; consumers are separate from `f_asc_dsl`. |
| Whitelist contents | Not listed in README; must be named in code and tests. |
| Stale design notes | `data/ideas/2026/08/A simple, minimal DSL for ASC.md` and `data/ideas/2026/07/23/dsl.md` disagree with the README. Implement from README + this spec. |
| Coverage waves | Interpreter framing is fixed; grammar *coverage* may land in waves under [22-make-ds.md](../../plans/2026/09/22-make-ds.md). Print-only is abandoned. |

## Observed vs proposed vs not decided

| Kind | Content |
|------|---------|
| Observed | `asc/dsl.sh`, `dsl.manual-inc.sh`, bootstrap source, hardcoded `make ds`, removal of `asc/instance/ds.sh`, README grammar text, stub TODO body |
| Proposed | Run model, resolutions table, calling-scope errors, `test-*` fix, whitelist deny-by-default |
| Not decided | Exact whitelist membership; whether dry-run print becomes a flag; filename-hook compiler as a separate entry |
