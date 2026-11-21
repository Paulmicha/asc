---
status: draft
updated: 2026-11-19
---

# ASC custom DSL

The [README DSL section](../../../README.md#asc-domain-specific-language--dsl-syntax)
describes the language's purpose and sketches its syntax. This draft records
the proposed interpreter contract and the decisions still open. The
[delivery plan](../../plans/2026/09/22-make-ds.md) owns sequencing and acceptance
checks. The [make ds gate](../../../gates.core.yml) remains in discussion with
`approved: "no"` and `go: "no"`.

**Observed (line-break / `*.dsl.txt` slice, 2026-11-19):** top-level newline
sequencing (continue-on-nonzero, last-status), blank-line ignore,
whitespace-only empty lists as valid layout, `*.dsl.txt` whole-file load with
NUL reject / CRLF rules, preparse-all (bindings + resolve before any dispatch),
and `ASC_DS_EXPR` / first argv as either inline DSL or a `.dsl.txt` path — see
[19-dsl-line-breaks-and-dsl-txt.md](../../plans/2026/11/19-dsl-line-breaks-and-dsl-txt.md).
The **`;` token**, other combinators, options / `~`, and `make replay` remain
deferred.

## Current implementation

Status: **implemented in-tree, not gate-accepted** (`approved: "no"`, `go: "no"`).

| Entry | Behavior in this checkout |
|---|---|
| [`f_asc_dsl`](../../../asc/core/dsl.manual-inc.sh) | Program (inline or `*.dsl.txt`): top-level newline sequencing, literals, exact `pN` / `a` / `sN` bindings expanded and pivots resolved for **every** call before any dispatch, last-status return after a successful preparse. Diagnostics use [`throw()`](../../../asc/core/utils/shell.manual-inc.sh) (exit; no `f_asc_dsl_err`). Requires a closing `)` before each call dispatches. |
| [`asc/dsl.sh`](../../../asc/dsl.sh) | Bootstraps ASC and passes its argv to `f_asc_dsl`; process exit status is the function status. |
| [`make ds`](../../../asc/make/default.mk) | Hardcoded target runs [`asc/make/ds.make.sh`](../../../asc/make/ds.make.sh). Expression or `*.dsl.txt` path comes from **`ASC_DS_EXPR`** (not Make goals). Stray goals with `ds` are refused at makefile parse time. |
| Former `asc/instance/ds.sh` | Removed in `65de058`. `f_make_generate` skips hardcoded reserved names and drops cached paths to the removed script. |
| Probe fixture | [`asc/test/core/dsl_probe.fixture.sh`](../../../asc/test/core/dsl_probe.fixture.sh) (not a Make action). `dsl.test.sh` installs it as `asc/instance/dsl_probe.sh`; discovered pivot name is **`dsl-probe`**. Argv capture is NUL-delimited. |

### Observed parser whitespace, quotes, and programs

- Inside `(...)`, `[[:space:]]` (including newline) is skipped between
  comma-separated arguments, so wrapped argument lists with real tokens parse.
- Single-quoted arguments preserve embedded newlines and CR byte for byte
  (every character until the closing `'`).
- All-whitespace / empty program after split is rejected (`expression is empty`).
- An empty argument list written `name()` is valid. Whitespace-only content
  between `(` and `)` (including layout newlines) is a valid empty list.
- Top-level **LF** sequences calls (continue-on-nonzero; last status). CRLF
  works via trailing-CR trim; **bare CR does not sequence** (fails closed).
  Blank lines are ignored. The `;` token is not implemented yet.
- A program argument ending in exact `.dsl.txt` (case-sensitive; independent of
  `nocasematch`) enters file mode: record source size, copy one snapshot, then
  validate that buffer (NUL via checked `tr`+`stat`, loaded length via checked
  write+`stat`). Snapshot size must match the pre-copy size (in-place
  truncate/extend during capture → file error). Validation tool failure is a
  file error (not empty-equal success). Prefer atomic rename for writers;
  missing / non-regular / unreadable / incomplete → file error. Otherwise the
  argument is inline DSL. Path may contain `=`; that character is not treated
  as program text for file-mode open.

### Observed Make carrier

Supported:

```text
ASC_DS_EXPR='slug(foobar)' make ds
ASC_DS_EXPR="slug('a b')" make ds
ASC_DS_EXPR='path/to/prog.dsl.txt' make ds
```

The expression or `*.dsl.txt` path is **not** a Make goal. `make ds` must be
the only goal; companions such as `debug` and stray expression goals are
refused at makefile parse time so they cannot be interpolated as unquoted
shell. `ds.make.sh` calls `asc/dsl.sh` directly and does not run
`f_make_unescape`, so characters that reach the interpreter are not rewritten
by Make unescape. Unimplemented combinators (including `;`) and reserved
argument tokens in program text are **rejected by the interpreter**.

**Carrier regression note (proposed `=` ban):** today’s suite still asserts that
quoted `'a=b'` survives Make and direct carriers unchanged. Under the
[raw `=` rule](#raw-equals-character-ban-proposed-contract) that source is
**invalid**; when the ban is implemented, replace those cases with: literal
`=` anywhere in program text fails closed; an `=` that appears only via a
**bound** argument (or via generated attached-value argv from `~`) succeeds.
Keep separate carrier checks that `∓` and `$` in allowed source are not
mutated.

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
calls `throw()` (stderr diagnostic via the instance throw hook, then exit)
before execution begins. Values needed only by a branch are resolved when that
branch runs.

After a successful preparse, the function returns the expression status to the
caller. The direct script uses that status as its process exit status. Make
reports a failing recipe and uses GNU Make's own exit status. In-process
callers that need to survive a diagnostic must run `f_asc_dsl` in a subshell.
A `test-*` call follows the same rules as any other pivot, including within a
chain.

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

Parentheses enclose arguments and unquoted commas separate them. An unquoted
comma separates **DSL argument expressions**, not necessarily “one argv entry
each”: a single expression such as `a` can expand to zero or many argv
entries after binding expansion. Unquoted literal values use ASCII letters
and digits or `.`, `/`, `_`, `-`, and `%`. `%` supplies a literal `*`, and
`%%` supplies `**`. Any pattern evaluation belongs to the receiving action.
The interpreter preserves each expanded value as argv data, including paths
containing wildcard characters.

Single quotes enclose one literal argument, including spaces, commas,
parentheses, operator characters, and reserved spellings — subject to the
[raw `=` ban](#raw-equals-character-ban-proposed-contract). `''` supplies an
empty argument. Quoted values bypass substitutions, including `%`. Escaping
a literal apostrophe inside that form is open. Use a bound argument to pass
a value containing one.

| Token | Argument value |
|---|---|
| `p1`, `p2`, … | One bound positional argument. An out-of-range index is an error. |
| `a` | All bound arguments, as separate argv entries (zero or more). |
| `s1`, `s2`, … | Bound arguments after dropping N. Dropping exactly the number bound yields zero entries. Dropping more is an error. |
| `v-name` | One scalar Bash variable from the interpreter's shell. |
| `d0`, `d1`, … | One YAML property name at depth N, supplied by the embedding caller. |
| `b-y`, `bb-oneline` | `-y`, `--oneline`. |
| `pivot(-m,4)`, `pivot(--max,4)` | Preferred split-value form: two DSL argument expressions → `-m` then `4`, or `--max` then `4`. |
| `oe-max~4`, `ooe-max~4` | `-max=4`, `--max=4`, as one argv entry each (**proposed**; see attached values). |
| `ba`, `bba` | Single-dash or double-dash boolean options from bound argv. Classification is open. |
| `oa`, `ooa` | Single-dash or double-dash options with values from bound argv. Classification is open. |

**Historical (not preferred / not the attached-value contract):** older README
sketches such as `o-m-4`, `oo-max-4`, `oe-max-4`, and `ooe-max-4` used
hyphen-attached value packing. Prefer already-supported comma-separated
literals (`pivot(-m,4)`, `pivot(--max,4)`) for split argv, and `oe-` /
`ooe-` with an explicit `~` for a single attached `name=value` argv entry.
Do not treat `oo-max-4` as ambiguous with `ooe-` / `~` forms.

### Raw equals character ban (proposed contract)

**Accepted decision (2026-11-19, revised):** DSL **program text** must
**not** contain the ASCII `=` character **anywhere**, including inside
single-quoted arguments. Example: `pivot('a=b')` is **invalid source**
under this rule.

`ASC_DS_EXPR` (and the first argv to `asc/dsl.sh` / `f_asc_dsl`) may be
either a **file path** or **inline DSL**. Decide file versus inline
**first** (see the child plan’s `.dsl.txt` suffix rule). Apply the raw
`=` ban **after** that decision, to the **loaded program bytes** (file
mode) or the **inline expression string** (inline mode) — **not** to the
path string used to open the file. A path such as
`jobs/release=2.dsl.txt` remains a valid carrier value when the file’s
contents obey the ban.

Validate the ban on that program text **before expanding bindings**.
A **bound** argument whose bytes contain `=` still reaches the action
unchanged — bindings are data, not program text. Attached-value forms
(`oe-` / `ooe-` with `~`) may **generate** an argv entry that contains `=`;
that `=` is produced when building argv, never required as a character in
the DSL spelling.

| Source | Result under this rule |
|---|---|
| `pivot('a=b')` (inline or file contents) | Invalid program text (quoted `=` still banned). |
| `pivot(p1)` with `-- 'a=b'` | Valid; bound value `a=b` passes through. |
| `pivot(oe-max~4)` | Valid spelling; argv is `-max=4` after generation. |
| Literal `=` in loaded / inline **program text** | Fail closed before dispatch. |
| Path `jobs/release=2.dsl.txt` whose file contents have no `=` | Valid file mode; path `=` is not program text. |

**Observed today:** the first-slice parser and
[`dsl.test.sh`](../../../asc/test/core/dsl.test.sh) still accept quoted
`'a=b'` through direct and Make carriers (carrier “keeps `=`” cases). Those
observations and tests **must be updated** when this ban is implemented:
literal `=` in program text fails; `=` only via binding or via `~`-generated
attached argv succeeds. File-or-inline path detection is still proposed
(child plan); until then there is no path-versus-source split to observe.

### Argument separators and attached option values (proposed contract)

**Accepted decision (2026-11-19):** commas remain the **only** separator
between DSL argument expressions. Do **not** accept space-separated forms
such as `pivot(-q file)` as an alternate spelling of `pivot(-q,file)`. Use
a bare `~` so an attached option token can produce a single argv entry that
contains `=`.

| Proposed DSL | Argument(s) passed |
|---|---|
| `pivot(-m,4)` | `-m`, `4` |
| `pivot(--max,4)` | `--max`, `4` |
| `pivot(oe-max~4)` | `-max=4` |
| `pivot(ooe-max~4)` | `--max=4` |
| `pivot(ooe-output-file~)` | `--output-file=` |
| `pivot(ooe-output-file~draft-v2~backup)` | `--output-file=draft-v2~backup` |
| `pivot(oe-max~p1)` | `-max=p1` (literal characters `p1`, **not** a binding) |
| `pivot(oe-max~%x)` | `-max=%x` (`%` **not** expanded in the value part) |

Rules for `oe-` / `ooe-` attached forms:

- The `~` delimiter is **required**. A token that begins with `oe-` or
  `ooe-` but lacks a `~` (including older hyphen-attached `oe-max-4` /
  `ooe-max-4`) is a **malformed attached token**: diagnostic, nonzero
  status, **no dispatch**. Do **not** fall through to treating it as an
  ordinary unquoted literal argument.
- Require a nonempty option name between the prefix and the first `~`
  (`oe-` / `ooe-` alone, or `oe-~…` / `ooe-~…` with an empty name, are
  errors: diagnostic, nonzero, no dispatch).
- Split on the **first** `~` only.
- Allow an empty value (`ooe-output-file~` → `--output-file=`).
- Preserve any later literal tildes in the value
  (`ooe-output-file~draft-v2~backup` → `--output-file=draft-v2~backup`).
- The value part after the first `~` is **literal** spelling: a suffix such
  as `p1` is **not** expanded as a binding; `%` / `%%` are **not** expanded
  there. To attach a dynamic value (or one that needs `/`, `=`, spaces, or
  other rejected characters), bind the **complete** argv entry through
  `p1` (or another binding) instead.
- Generate `=` only when building argv (not as a character in program text).

**Filename-safe characters (name and value):** the option **name** and the
literal **value** (each character of each) must stay inside the unquoted
literal charset **without** `/` — that is `[A-Za-z0-9._%-]` — so an
`oe-…` / `ooe-…` token can sit in a single filename component (README
filename-safe intent; `/` is a path separator on Linux and reserved on
Windows). Additional rules on top of that set:

| Piece | Allowed characters | Reject (diagnostic, nonzero, no dispatch) |
|---|---|---|
| Name (between prefix and first `~`) | Nonempty `[A-Za-z0-9._%-]+` | Empty name; `/`; `\`; `=`; whitespace; any other byte; `~` (first `~` ends the name) |
| Value (after first `~`) | Empty, or `[A-Za-z0-9._%-]*`, plus any later literal `~` | `/`; `\`; `=`; whitespace; any other byte outside that set and `~` |

**Slash rule (locked):** reject `/` in the attached **name** and **value**.
Ordinary unquoted literals may still use `/` for paths (`pivot(some/path)`).
For an option value that is a path containing `/` or `=`, bind the full
argv entry (for example `p1` holding `--output-file=some/path=v2`).

**Where `~` is reserved:** as the attached-value delimiter inside `oe-` /
`ooe-` token spellings. Outside those prefixes, `~` is not part of the
ordinary unquoted literal charset and remains unsupported as a free
character in other tokens.

**Acceptance cases (options / attached-value slice):**

| Case | Expectation |
|---|---|
| Missing delimiter (`oe-max4`, `ooe-max-4`) | Diagnostic, nonzero, **no dispatch**; not a literal argv token. |
| Empty name (`oe-~4`, `ooe-~`) | Diagnostic, nonzero, no dispatch. |
| Slash in name or value (`oe-out/put~1`, `ooe-file~a/b`) | Diagnostic, nonzero, no dispatch. |
| Empty value (`ooe-output-file~`) | One argv entry `--output-file=`. |
| Later literal tildes (`ooe-output-file~a~b`) | One argv entry `--output-file=a~b`. |
| Exact one-entry argv (`pivot(ooe-max~4)`) | NUL-delimited capture is exactly `--max=4\0` (one field). |
| Path / `=` via binding | `pivot(p1)` with `-- '--output-file=some/path'` succeeds; attached spelling with `/` or `=` does not. |

Together with bindings, this is enough to pass arbitrary arguments. For a
value containing spaces, slashes, or `=`, bind through `p1` (or bind the
complete attached argument such as `--output-file=some/path with spaces`
when the action needs one argv entry). Selective forwarding (`ba` / `oa`)
still needs the source command’s option rules; the caller can select args
and forward via `a`.

**Observed today:** the first-slice parser still rejects the proposed `~`
form. Unquoted argument characters are limited to
`[A-Za-z0-9./_%-]` in
[`asc/core/dsl.manual-inc.sh`](../../../asc/core/dsl.manual-inc.sh)
(binding/token area near line 419), so `oe-max~4` fails until an options
slice implements the contract (attached name/value then use that set
**without** `/`, plus later `~` in the value). Older hyphen-attached
sketches such as `o-m-4`, `oo-max-4`, `oe-max-4`, and `ooe-max-4` remain
**historical** README wording, superseded by comma-separated literals and
`~` attached values.

**Filename note (rationale, not an end-to-end Windows claim):** a hook-style
filename containing `ooe-max~4` works on Linux (user-verified). Windows
ordinary filenames may contain a bare `~` under
[Microsoft naming conventions](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file)
(`~` is not among the reserved characters). This is recorded so filename
hooks can use the same spelling; it does not assert that Windows ASC is
tested end-to-end.

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

**Observed:** top-level newline sequencing (continue-on-nonzero, last-status),
blank-line rules, whitespace-only empty lists, multi-line `*.dsl.txt` programs,
and preparse-all (including later binding errors failing before any dispatch) —
delivered under
[19-dsl-line-breaks-and-dsl-txt.md](../../plans/2026/11/19-dsl-line-breaks-and-dsl-txt.md).
The **`;` token follows later** as an exact synonym of that sequencing.

The README sketches array iteration as `[[echo(v-item)]v-foobar_arr]`
and output-line iteration as `[[echo(v-item)]myfunc]`. These are DSL
sketches. The producer's spelling, how `v-item` is scoped, and iteration
and failure behavior need review before loop support.

## Open decisions

| Topic | Decision needed before the relevant slice |
|---|---|
| Option tokens (partially decided) | **Decided (2026-11-19):** commas separate DSL argument expressions only; bare `~` is required for `oe-` / `ooe-` attached values (nonempty name; first `~` splits; empty value allowed; later tildes literal; value part is literal — `p1` / `%` not expanded there; name/value charset `[A-Za-z0-9._%-]` plus later `~` in value; `/` rejected in attached tokens; missing `~` after `oe-`/`ooe-` is fail-closed, not a literal; `=` only in generated argv). Program-text raw `=` ban **after** file-versus-inline: see [Raw equals character ban](#raw-equals-character-ban-proposed-contract). See [Argument separators and attached option values](#argument-separators-and-attached-option-values-proposed-contract). **Still open:** where `ba` / `oa` obtain option arity from the source command; handling of `--` within bound argv; grouped short options. A dash prefix alone still cannot distinguish `-q` plus a positional from an option with a value without those source rules. **Implementation:** smallest options slice can ship `~` + program-text `=` validation without `ba`/`oa`; under [22-make-ds.md](../../plans/2026/09/22-make-ds.md) — not the line-break child, and not assumed done while the parser rejects `~`. |
| Argument separators | **Decided (2026-11-19):** keep commas as the only separator between DSL argument expressions (`a` may expand to zero or many argv entries). Space-separated forms such as `pivot(-q file)` are **not** accepted. The former open question tracked from [19-dsl-line-breaks-and-dsl-txt.md](../../plans/2026/11/19-dsl-line-breaks-and-dsl-txt.md) is closed in favor of commas + `~` attached values. |
| Functions | Name the initial list and document allowed side effects for each entry. |
| Combinators | Define mixed-operator precedence and associativity, whitespace and token boundaries, pipeline status, and how parallel failures are reported. Line-break ≈ `;` defaults live in the child plan above. |
| Loops | Specify producer syntax, line handling and iterator scope, and status on producer or body failure. |
| Make | `ASC_DS_EXPR` carrier is observed above (inline expression or `.dsl.txt` path; not a Make goal). Still open: host `ds` alias migration; whether Make should carry bound argv; README proposal merge. |
| Embeddings | Define how YAML validates a field and supplies `p1` and `dN`. Define a filename-safe subset and its hook integration separately. Prompt dispatch and replay require their own consumers. Replay Make wiring remains deferred. |

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
