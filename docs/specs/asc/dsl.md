---
status: draft
updated: 2026-11-18
---

# ASC custom DSL

The [README DSL section](../../../README.md#asc-domain-specific-language--dsl-syntax)
describes the language's purpose and sketches its syntax. This draft records
the proposed interpreter contract and the decisions still open. The
[delivery plan](../../plans/2026/09/22-make-ds.md) owns sequencing and acceptance
checks. The [make ds gate](../../../gates.core.yml) remains in discussion with
`approved: "no"` and `go: "no"`.

## Current implementation

Status: **implemented in-tree, not gate-accepted** (`approved: "no"`, `go: "no"`).

| Entry | Behavior in this checkout |
|---|---|
| [`f_asc_dsl`](../../../asc/core/dsl.manual-inc.sh) | First slice: one pivot call, literals, exact `pN` / `a` / `sN` bindings, status return (never `exit` from the function). Requires a closing `)` before dispatch. |
| [`asc/dsl.sh`](../../../asc/dsl.sh) | Bootstraps ASC and passes its argv to `f_asc_dsl`; process exit status is the function status. |
| [`make ds`](../../../asc/make/default.mk) | Hardcoded target runs [`asc/make/ds.make.sh`](../../../asc/make/ds.make.sh). Expression comes from **`ASC_DS_EXPR`** (not Make goals). Stray goals with `ds` are refused at makefile parse time. |
| Former `asc/instance/ds.sh` | Removed in `65de058`. `f_make_generate` skips hardcoded reserved names and drops cached paths to the removed script. |
| Probe fixture | [`asc/test/dsl_probe.sh`](../../../asc/test/dsl_probe.sh) (`test-dsl-probe`) for argv / marker / status tests. |

### Observed Make carrier (first slice)

Supported:

```text
ASC_DS_EXPR='slug(foobar)' make ds
ASC_DS_EXPR="test-dsl-probe('a b')" make ds
```

The expression is **not** a Make goal, so colliding recipes such as `debug` cannot
interpolate it as unquoted shell (`make -k ds 'true;touch …' debug` is refused).
`ds.make.sh` calls `asc/dsl.sh` directly and does not run `f_make_unescape`, so
literal `∓`, `=`, and `$` in the expression stay unchanged. Combinators in
`ASC_DS_EXPR` are still **rejected by the interpreter** as unsupported grammar.

Bound argv and general strings use the direct interfaces:

```text
asc/dsl.sh 'slug(p1)' -- 'Foo Bar'
f_asc_dsl 'slug(a)' -- one 'two three'
```

Make notes:

- Passing the expression as a Make goal is unsupported and refused when `ds` is
  among the goals.
- GNU Make’s process status on recipe failure is typically `2`, even when the
  script exited with another nonzero code.
- Host `ds` shell alias migration is still open.

### Observed pivot resolution (first slice)

- Discovered names come from `f_make_list_entry_points` (exact final-name match).
- Hardcoded reserved names are checked first. DSL-eligible path-only set:
  `init`, `setup`, `hook`, `globals-lp`. Rejected as ineligible: `ds`, `debug`,
  `init-debug`, `hook-debug`.
- `f_make_list_hardcoded` matches `default.mk` (`init` → `asc/instance/init.sh`,
  debug variants keep recipe-specific arguments, `ds` → `asc/dsl.sh`).
- `f_make_generate` omits discovered names that collide with hardcoded reserved
  names so `default.mk` keeps the single `ds` recipe.

## Invocation and status (proposed)

Call from the ASC project root. The function requires a bootstrapped shell.

```text
f_asc_dsl <expression> [-- <caller-arg>...]
asc/dsl.sh <expression> [-- <caller-arg>...]
```

`f_asc_dsl` parses the complete expression and resolves its static call names
before running any branch. Invalid syntax, unsupported syntax, or unknown
calls return nonzero with a diagnostic on stderr before execution begins.
Values needed only by a branch are resolved when that branch runs.

The function returns the expression status to the caller. The direct script
uses that status as its process exit status. Make reports a failing recipe and
uses GNU Make's own exit status. In-process callers decide how to handle
failure, including whether to return from a hook after cleanup. A `test-*`
call follows the same rules as any other pivot, including within a chain.

The interpreter is for trusted ASC callers. It dispatches parsed calls to
script paths or explicitly listed functions or builtins and passes arguments
as argv. Literal and bound values are data. The interpreter does not
reparse them as DSL or evaluate them as shell source. A resolved action runs
with the caller's privileges.

## Pivot and function resolution (proposed)

- A bare name or `name(...)` resolves an ASC pivot. `name` and `name()` pass
  zero arguments. A missing or non-executable script is a resolution error.
- Use the **final names** from
  [`f_make_list_entry_points`](../../../asc/make/make.inc.sh) for discovered
  actions. That function already applies Make sanitization, synonyms, the
  `instance-` prefix rule, and discovery collision handling. Look up the
  supplied name exactly in those results.
- Reserve hardcoded Make names before considering discovered names, so a
  discovered collision cannot run a different script under a reserved name.
  A hardcoded name is eligible only if its recipe is a direct dispatch to
  one known script with the supplied argv. Use a path-only view aligned with
  `default.mk`. Exclude `ds` itself and recipes with extra steps or injected
  arguments such as `debug`, `init-debug` and `hook-debug`.
- `f_make_list_hardcoded` also serves the Make wrapper's reserved-name
  check. It omits `ds`, lists the wrong path for `init` and `init-debug`, and
  includes command strings with flags. Use the plan to reconcile the Make
  list. DSL dispatch uses a resolved script path and argv.
- `[name(...)]` selects a function or builtin from an explicit list. Each
  function or builtin call in a chain or argument needs its own brackets.
  The list is open. `echo` in examples is a candidate. `exit` is excluded
  because the interpreter returns control to its caller.

## Arguments (proposed)

Parentheses enclose arguments and unquoted commas separate them. Unquoted
literal values use ASCII letters and digits or `.`, `/`, `_`, `-`, and `%`.
`%` supplies a literal `*`, and `%%` supplies `**`. Any pattern evaluation
belongs to the receiving action. The interpreter preserves each value as one
argument, including paths containing wildcard characters.

Single quotes enclose one literal argument, including spaces, commas,
parentheses, operator characters, and reserved spellings. `''` supplies an
empty argument. Quoted values bypass substitutions, including `%`. Escaping
a literal apostrophe inside that form is open. Use a bound argument to pass
a value containing one.

| Token | Argument value |
|---|---|
| `p1`, `p2`, … | One bound positional argument. An out-of-range index is an error. |
| `a` | All bound arguments, as separate argv entries. |
| `s1`, `s2`, … | Bound arguments after dropping N. Dropping exactly the number bound yields zero entries. Dropping more is an error. |
| `v-name` | One scalar Bash variable from the interpreter's shell. |
| `d0`, `d1`, … | One YAML property name at depth N, supplied by the embedding caller. |
| `b-y`, `bb-oneline` | `-y`, `--oneline`. |
| `o-m-4`, `oo-max-4` | `-m 4`, `--max 4`, as two argv entries each. |
| `oe-max-4`, `ooe-max-4` | `-max=4`, `--max=4`, as one argv entry each. |
| `ba`, `bba` | Single-dash or double-dash boolean options from bound argv. Classification is open. |
| `oa`, `ooa` | Single-dash or double-dash options with values from bound argv. Classification is open. |

An unquoted reserved spelling is a token. For example, `slug(p1)` reads a
positional value and `slug('p1')` uses the literal string `p1`. Omitting
`--` leaves argv unbound and makes argv tokens errors. Supplying `--` with
zero arguments binds an empty vector, so `a` expands to zero arguments.
Preserve bound values exactly, including empty strings and whitespace.

An in-process caller's visible variables can supply `v-name` through Bash
dynamic scope. A separate process sees only variables established in that
process, including inherited exports and its own bootstrap state. A valid
scalar name with an empty value supplies one empty argument. An unset
binding is an error. Interpreter locals must preserve access to the
caller's bindings. A YAML embedding can set local variables named `d0`,
`d1` and so on before calling the function. The interpreter has no YAML
file or current branch of its own.

```sh
asc/dsl.sh 'slug(p1)' -- 'Foo Bar'
```

In a hook, pass the hook's own `"$@"` after `--` when the expression needs it.

## Nested calls (proposed)

In `outer(inner(...))` the inner pivot's stdout supplies one argument to
the outer call, with Bash command substitution's removal of trailing
newlines. Write `outer([inner(...)])` when the inner call names a listed
function. A failed inner call returns its status for the enclosing call
without running the outer action. This applies even when the inner call
produced stdout.

## Combinators and loops (draft grammar)

| DSL | Intent |
|---|---|
| `;` | Run both expressions in sequence. |
| `;;` | Run the right expression when the left succeeds. |
| `++` | Run the right expression when the left fails. |
| `-;-` | Run expressions in parallel and wait for their completion. |
| `+` | Pipe stdout to the next expression's stdin. |
| `--` | Redirect stdout to a path, replacing its contents. |
| `---` | Redirect stdout to a path, appending. |

The sequence returns the last expression's status. Short-circuit operators
return the status of the last expression evaluated. A redirection takes one
path and fails if that path cannot be opened. The chain examples use
`[echo(v-baz)];[echo(foobar)]` when both calls name the listed builtin.
The README's `grep(foobar)` requires an actual ASC pivot named `grep`.

The README sketches array iteration as `[[echo(v-item)]v-foobar_arr]`
and output-line iteration as `[[echo(v-item)]myfunc]`. These are DSL
sketches. The producer's spelling, how `v-item` is scoped, and iteration
and failure behavior need review before loop support.

## Open decisions

| Topic | Decision needed before the relevant slice |
|---|---|
| Option tokens | Define the name/value separator when names or values contain hyphens, how to express an empty value, and where the forwarders obtain option arity. A dash prefix alone cannot distinguish `-q file` as a flag plus positional argument from an option with a value. Define the handling of `--` within bound argv and grouped short options. |
| Functions | Name the initial list and document allowed side effects for each entry. |
| Combinators | Define mixed-operator precedence and associativity, whitespace and token boundaries, pipeline status, and how parallel failures are reported. |
| Loops | Specify producer syntax, line handling and iterator scope, and status on producer or body failure. |
| Make | First-slice `ASC_DS_EXPR` carrier is observed above (expression not a Make goal). Still open: host `ds` alias migration; whether Make should carry bound argv; README proposal merge. |
| Embeddings | Define how YAML validates a field and supplies `p1` and `dN`. Define a filename-safe subset and its hook integration separately. Prompt dispatch and replay require their own consumers. |

The README's YAML example expresses the intent to test a value against its
slug and snake forms. [`asc/test/in.sh`](../../../asc/test/in.sh) is empty, so
it cannot validate membership. Bash `[[ … ]]` does not invoke a script.
Use a fixture with known positive and negative results for interpreter
acceptance, and give YAML validation its own end-to-end test once the action
and the embedding exist.

[The workflow extension's draft entity](../../../asc/extensions/workflow/change/change.entity.yml)
still uses `a-1` in its validation sketches. That spelling predates the
proposed `p1` binding.

## Historical notes

The July filename-DSL plan was removed in `b3122f2`. The July and August
DSL ideas were removed in `c458a94`. The
[July living-docs snapshot](../../plans/2026/07/26-living-docs-readme-status.md)
records the vocabulary and filename rules from that period. The
[print-only plan](../../plans/2026/09/22-make-ds-literal.md) was abandoned
on 2026-11-17.
