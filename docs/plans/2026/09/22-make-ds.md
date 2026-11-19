# `make ds` and the DSL interpreter

| Field | Value |
|---|---|
| Date | 2026-09-22, revised 2026-11-18 |
| Status | Draft (plan / review) — first slice in progress; **not accepted** |
| Scope | Deliver an executable DSL interpreter through `f_asc_dsl` and `asc/dsl.sh`, and verify the supported `make ds` carrier. |
| Contract | [ASC custom DSL](../../../specs/asc/dsl.md) |
| Gate | [`gates.core.yml`](../../../../gates.core.yml), `make ds` row, currently `lane: discuss`, `approved: "no"`, `go: "no"`. |

The gate's go-ahead accepts the reviewed contract for the implementation
slice. Its lane and approval must satisfy the registry's rules. Items
listed as open in the spec need decisions before the affected slices.
Merging README proposals is a separate editorial decision. This plan does
**not** mark the interpreter or Make carrier accepted.

## Baseline

Commit `65de058` removed `asc/instance/ds.sh` and made `ds` a hardcoded
target that dispatches to `asc/dsl.sh`. Tests live in
`asc/test/core/dsl.test.sh` with the fixture
`asc/test/core/dsl_probe.fixture.sh` installed as a disposable
`instance/dsl_probe` action for the suite.

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

- [x] Reuse the discovered Make pivot names and define the eligible
  hardcoded paths. Reconcile `f_make_list_hardcoded` with `default.mk`,
  including `ds`, the `init.sh` paths and recipe-specific arguments.
- [x] Verify actual dispatch with `asc/dsl.sh 'slug(foobar)'` producing
  `foobar`. Use harmless fixtures to verify a discovered action and an
  eligible hardcoded path, exact final-name lookup, and rejection of
  `ds`, `debug`, compound recipe names and collisions under reserved names.
- [x] Compare the fixture's received argv with an expected vector. Cover
  quoted delimiters, an empty argument, a quoted reserved word, literal
  `%`/`%%` substitution, bound spaces, an empty bound vector and an
  out-of-range positional. A literal or bound value reaches the fixture
  unchanged by shell parsing and pathname expansion. Binding tokens require
  an entire numeric suffix (`p12abc` stays a literal).
- [x] Use a fixture that returns a known nonzero status. Assert that
  `f_asc_dsl` returns it and a caller's post-call marker still runs.
  Assert the same status from `asc/dsl.sh`. Assert a diagnostic and no
  execution marker for malformed syntax (including truncated /
  trailing-comma forms) and unknown or unsupported calls.
  `asc/test/in.sh` is empty and cannot serve as the failing fixture.

### 2. Make carrier and upgrade compatibility

- [x] Define a supported invocation that delivers one expression to
  `asc/dsl.sh` **without placing the expression among Make goals**:
  `ASC_DS_EXPR='…' make ds` via `asc/make/ds.make.sh`. Makefile parse
  refuses stray goals when `ds` is requested. Bound argv and general
  strings use `asc/dsl.sh` / `f_asc_dsl`. Spaces in the expression are
  carried through `ASC_DS_EXPR`. `$` / `=` as Make goal text remain out of
  scope for this carrier (expression is not a goal).
- [x] **Shell-syntax safety.** Expression is not interpolated into other
  recipes' `MAKECMDGOALS`. Marker tests cover `;`, `+`, and `;;` (markers
  that would run if shell-interpreted), plus `make -k` with colliding
  `debug` in **both goal orders**. Unsupported combinators delivered via
  `ASC_DS_EXPR` are rejected by the interpreter with the expression visible
  in the diagnostic. `call_wrap` does not apply `f_make_unescape` on the
  DSL path; `ds.make.sh` calls `asc/dsl.sh` directly.
- [x] Test the function, direct script and Make separately. For Make,
  verify the script's failure surfaces as a failed recipe. GNU Make owns
  the status returned to its caller (typically exit 2 when a recipe exits
  nonzero).
- [x] Check a **disposable** clean fixture, an upgrade fixture with the
  former generated `ds` → `asc/instance/ds.sh` recipe, and a discovered-name
  collision with reserved hardcoded `ds`. `f_make_generate` skips hardcoded
  reserved names and accepts
  `ASC_MAKE_GENERATE_PIVOTS_MK` / `ASC_MAKE_GENERATE_PIVOTS_SH` /
  `ASC_MAKE_GENERATE_TEST_CASES` so tests do not rewrite live
  `data/asc/` outputs.
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
  (Spec “observed” notes updated 2026-11-18 for the revised carrier;
  README proposal merge remains editorial. Gate stays no/no.)
