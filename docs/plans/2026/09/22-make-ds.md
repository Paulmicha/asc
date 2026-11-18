# `make ds` and the DSL interpreter

| Field | Value |
|---|---|
| Date | 2026-09-22, revised 2026-11-18 |
| Status | Draft (plan / review) |
| Scope | Deliver an executable DSL interpreter through `f_asc_dsl` and `asc/dsl.sh`, and verify the supported `make ds` carrier. |
| Contract | [ASC custom DSL](../../../specs/asc/dsl.md) |
| Gate | [`gates.core.yml`](../../../../gates.core.yml), `make ds` row, currently `lane: discuss`, `approved: "no"`, `go: "no"`. |

The gate's go-ahead accepts the reviewed contract for the implementation
slice. Its lane and approval must satisfy the registry's rules. Items
listed as open in the spec need decisions before the affected slices.
Merging README proposals is a separate editorial decision.

## Baseline

Commit `65de058` removed `asc/instance/ds.sh` and made `ds` a hardcoded
target that dispatches to `asc/dsl.sh`. The shell function still prints a
TODO and returns zero. The
[print-only child](22-make-ds-literal.md) was abandoned on 2026-11-17.
The first delivery must execute a call and report its result.

The supported entry points, resolver, binding and status contract belong
in the [DSL spec](../../../specs/asc/dsl.md). The direct script is the first
command-line caller. The YAML validator, filename hooks, replay and model
prompting are follow-ups with their own contracts.

## Delivery and acceptance

### 1. Direct and in-process interpretation

The proposed first slice supports one pivot call, literal arguments, and
explicit caller argv binding (`pN`, `a`, `sN`). Include both direct script and
in-process calls. Reject forms outside the implemented grammar and report
supported forms in the usage text.

- [ ] Reuse the discovered Make pivot names and define the eligible
  hardcoded paths. Reconcile `f_make_list_hardcoded` with `default.mk`,
  including `ds`, the `init.sh` paths and recipe-specific arguments.
- [ ] Verify actual dispatch with `asc/dsl.sh 'slug(foobar)'` producing
  `foobar`. Use harmless fixtures to verify a discovered action and an
  eligible hardcoded path, exact final-name lookup, and rejection of
  `ds`, `debug`, compound recipe names and collisions under reserved names.
- [ ] Compare the fixture's received argv with an expected vector. Cover
  quoted delimiters, an empty argument, a quoted reserved word, literal
  `%`/`%%` substitution, bound spaces, an empty bound vector and an
  out-of-range positional. A literal or bound value reaches the fixture
  unchanged by shell parsing and pathname expansion.
- [ ] Use a fixture that returns a known nonzero status. Assert that
  `f_asc_dsl` returns it and a caller's post-call marker still runs.
  Assert the same status from `asc/dsl.sh`. Assert a diagnostic and no
  execution marker for malformed syntax and unknown or unsupported calls.
  `asc/test/in.sh` is empty and cannot serve as the failing fixture.

### 2. Make carrier and upgrade compatibility

- [ ] Define a supported invocation that delivers one expression to
  `asc/dsl.sh`. Test the actual Make route with parentheses and the
  supported quoting and argv conventions. Include punctuation cases
  (`%`, `=`, `#`, `$`, quotes and whitespace), separator arguments and
  words that also name Make targets. For input outside the Make contract,
  document use of the direct script.
- [ ] **Shell-syntax safety at both Make boundaries.** The recipe
  interpolates `MAKECMDGOALS` into shell source before `asc/dsl.sh` runs,
  and [the Make wrapper](../../../../asc/make/call_wrap.make.sh) later
  builds a string for `eval`. A DSL operator such as `;` must not become
  shell control syntax that runs an unintended command. Use a **harmless
  execution marker** (for example a fixture that only creates or appends a
  known temp path when it runs) and assert:
  1. **Recipe boundary:** a Make invocation whose expression contains a
     DSL combinator or other shell-significant character either delivers
     that whole expression as one argv element to `asc/dsl.sh`, or fails
     the recipe **with the marker absent** (no side command ran).
  2. **Wrapper `eval` boundary:** the same class of input, once inside
     `call_wrap.make.sh`, either reaches `f_asc_dsl` / `asc/dsl.sh` as
     data or is rejected **with the marker absent**.
  3. **Unsupported expressions:** while Make does not yet carry the full
     combinator grammar (or when the expression is outside the documented
     Make-supported set), those invocations still satisfy (1) and (2) —
     reject or refuse before any unintended command, including in the
     period before Make carrier support for that punctuation is complete.
  4. Cover at least `;` and one other DSL operator from the combinator
     set (for example `+` or `;;`), plus an unsupported Make-carrier case
     that would be valid later as DSL. Direct `asc/dsl.sh` / `f_asc_dsl`
     remain the path for general strings until Make support is verified.
- [ ] Test the function, direct script and Make separately. For Make,
  verify the script's failure surfaces as a failed recipe. GNU Make owns
  the status returned to its caller.
- [ ] Check a clean fixture and an upgrade fixture with the former
  generated `ds` recipe. Use the normal generation path to refresh
  `data/asc/pivots.mk` and `data/asc/cache/pivots.sh`. Confirm there is one
  Make recipe for `ds`, including when a discovered name collides, and
  no cached dispatch path to the removed script.
  This checkout's pre-removal files currently produce an overriding-recipe
  warning in `make -n ds`.
- [ ] Decide the migration for the optional host `ds` shell alias.
  `ASC_HOST_SHELL_ALIASES` still includes it by default.
  [The alias writer](../../../../asc/host/shell/write_aliases.sh) accepts
  only discovered dispatch paths of the form `asc/instance/<name>.sh`.
  Verify the chosen behavior in a temporary alias map.

### 3. Broader grammar

- [ ] Add nesting, variable and YAML depth bindings, functions, options,
  combinators and loops in executable slices after resolving their open
  decisions in the spec. Test nested failure before the outer action,
  binding scope, function allowlisting, short-circuiting, and the status
  of failed pipeline, parallel and loop components as each lands.
- [ ] Update the spec with the behavior demonstrated by the tests and
  keep dated README proposals aligned. Track a separate acceptance case
  for any consumer that embeds DSL.
