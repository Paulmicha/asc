# DSL line breaks and `*.dsl.txt`

| Field | Value |
|---|---|
| Date | 2026-11-19 (revised same day: plan-review; commas + `~` pointer; NUL/CRLF; sequencing log; newline-first / `;` later) |
| Status | **completed** (implemented 2026-11-19; gap fixes same day: single-snapshot load, bare-CR non-sequencing, exact `.dsl.txt` suffix; gates untouched) |
| Parent | [`22-make-ds.md`](../09/22-make-ds.md) (first interpreter + `ASC_DS_EXPR` carrier) |
| Contract | [ASC custom DSL](../../../specs/asc/dsl.md) — living notes; this plan owns the slice detail |
| Gate | Parent row in [`gates.core.yml`](../../../../gates.core.yml) (`make ds`, `approved: "no"`, `go: "no"`). A **new child row may be needed later**; leave gates untouched until a human adds one. |
| Authorization | Direct human go-ahead or an applicable gate flip. Status `draft` / plan-review grants neither. |

Child / next-slice plan under the Make `ds` delivery work. Implemented
2026-11-19 under explicit human go-ahead. Do not commit unless asked.

## Intent

Make multi-line DSL first-class:

1. A **top-level newline** sequences calls: run the next expression even when
   the previous returns nonzero; return the **last** expression’s status.
   This slice accepts **top-level newlines**; the **`;` token follows later**
   (same sequencing intent when that combinator lands).
2. **Ignore blank lines.**
3. Allow **line breaks for layout inside `(...)`** (argument lists may wrap),
   including an empty list that contains only whitespace/newlines.
4. **Preserve newlines inside quoted arguments.**
5. Interpreter accepts a whole `*.dsl.txt` program so callers (including a
   future replay) can check syntax, resolve pivots, and expand bindings
   **before** the first call runs — matching the stub intent at
   [`asc/instance/replay.sh`](../../../../asc/instance/replay.sh) and the
   preparse notes in the DSL spec. **`make replay` wiring is out of this
   slice** (see Proposed defaults).
6. **`make ds` / carrier** accepts either an **inline expression** or a **path**
   to a `*.dsl.txt` file through the observed **`ASC_DS_EXPR`** contract.

## Baseline (observed 2026-11-19)

Mother checkout on branch `dsl-interpreter`. Parser facts below are from
[`f_asc_dsl` / `f_asc_dsl_parse_call`](../../../../asc/core/dsl.manual-inc.sh).

| Entry | Observed behavior |
|---|---|
| [`f_asc_dsl`](../../../../asc/core/dsl.manual-inc.sh) | One pivot call; parse + expand bindings + resolve before dispatch; status return (never `exit`). Trailing combinators / extra calls rejected. |
| Whitespace inside `(...)` | `[[:space:]]` (including newline) is skipped **between** comma-separated tokens. Line-wrapped argument lists with real tokens already parse. |
| Quotes | Single-quoted arguments accumulate every character until `'`, so an embedded newline is preserved when it reaches the parser. |
| Empty / whitespace-only input | After trim, empty → error (`expression is empty`). |
| Empty list with newline | `name()` is valid. `name(` + only whitespace/newline + `)` is **rejected** today (`)` after skipped whitespace is treated as an empty-argument error, not as close-of-empty-list). |
| [`asc/dsl.sh`](../../../../asc/dsl.sh) | Bootstraps and forwards argv to `f_asc_dsl`. |
| [`asc/make/ds.make.sh`](../../../../asc/make/ds.make.sh) | Requires `ASC_DS_EXPR`; calls `asc/dsl.sh "$ASC_DS_EXPR"`. No file-path branch. Bound argv not carried by Make. |
| [`default.mk`](../../../../asc/make/default.mk) | `make ds` sole goal; expression never a Make goal. |
| Probe | Fixture [`dsl_probe.fixture.sh`](../../../../asc/test/core/dsl_probe.fixture.sh) installed as `asc/instance/dsl_probe.sh`; discovered pivot name **`dsl-probe`**. Argv capture is **NUL-delimited** (`ASC_DSL_PROBE_ARGV`). |
| [`replay.sh`](../../../../asc/instance/replay.sh) | Stub; examples name `path/to/foobar.dsl.txt`. |
| Combinators in [`dsl.md`](../../../specs/asc/dsl.md) | Draft table only. `;` / top-level newline sequencing **not** implemented. |

Unsupported today: top-level multi-expression input (newline or `;`), treating
`ASC_DS_EXPR` as a path to load, and making whitespace-only empty lists valid.

## Scope

**In scope**

- Top-level newline sequencing with last-status semantics. The `;` token is
  **not** required for this slice; implement newline sequencing now and align
  `;` later as the same operator family.
- Blank lines ignored (no empty expression between separators).
- Layout newlines inside `(...)`, including making whitespace-only empty lists
  valid (see Proposed defaults).
- Newlines preserved inside single-quoted arguments (already mostly observed;
  lock + test).
- Loading a `*.dsl.txt` file as one program via suffix detection on
  `ASC_DS_EXPR` / first argv.
- File byte handling: reject embedded **NUL** before parse; CRLF line-ending
  rules outside quotes; preserve CRLF inside quotes byte for byte (see
  Proposed defaults + acceptance).
- Preparse-all for a program: syntax, static pivot resolve, **and**
  unconditional binding expansion (`pN` / `a` / `sN`) before any dispatch.
- Tests / fixtures / acceptance cases below.
- Living-spec baseline + proposed pointers.

**Out of scope (this slice)**

- The **`;` combinator token** and the rest of the combinator grammar (`;;`,
  `++`, `+`, parallel, redirects, loops, nesting, function brackets). Newline
  sequencing in this slice is the stand-alone first form; `;` follows later.
- **Option-token / attached-value grammar** (`oe-` / `ooe-` with `~`, and
  remaining `ba` / `oa` arity questions) — **not** this slice. Decision and
  deferred checkbox live under the parent and the living spec (see below).
- **`make replay` / finishing `replay.sh`** — deferred; this slice only makes
  the interpreter ready for a whole-file handoff.
- Host `ds` alias migration, Make-carried bound argv, README proposal merge,
  YAML embeddings, gate flips.

### Deferred elsewhere: commas + `~` (not space-separated)

**Decision (2026-11-19):** space-separated arguments are **not** the chosen
path. Commas remain the only argv separator; bare `~` attaches `oe-` /
`ooe-` values. Contract home:
[`dsl.md`](../../../specs/asc/dsl.md)
(Argument separators and attached option values). Parent
[`22-make-ds.md`](../09/22-make-ds.md) §3 owns scheduling an options /
attached-value implementation slice.

This line-break plan does **not** implement `~`, space-separated forms, or
`ba`/`oa` completion. Keep scope to top-level newlines, empty-list layout,
`*.dsl.txt`, and file-or-inline `ASC_DS_EXPR`. The `;` token is a later
combinator landing with the same sequencing intent.

## Proposed defaults (locked for review)

These are **proposed** contract choices for this slice. Ask only if a choice
below is wrong.

| Topic | Proposed default |
|---|---|
| Top-level newline (this slice) | Unconditional sequence: continue-on-nonzero + last-status. Accept **newlines now**; do **not** require `;` in this slice. |
| `;` token | **Follows later.** When it lands, treat it as an exact synonym of top-level newline sequencing (including `a;b` on one line vs `a` newline `b`). Whitespace around `;` is insignificant then. |
| Other combinators | Newline is **only** the sequence operator in this slice. It does not soft-wrap `;;`, `++`, or `+` without an explicit operator. |
| Empty / blank-only program | **Error** (same family as empty expression). |
| Empty list with only whitespace/newlines | **Valid** — same as `name()`. Proposed layout fix over today’s rejection. |
| File detection | If the program argument **ends with exact `.dsl.txt`** (case-sensitive; independent of `nocasematch`), enter **file mode**. In file mode, missing, non-regular, and unreadable paths are **file errors** (nonzero diagnostic). **No** silent fallback to treating the string as inline DSL. If the argument does **not** end with `.dsl.txt`, treat it as inline DSL (do not open the filesystem for bare pivot names). |
| Where detection lives | Shared in **`f_asc_dsl`** (so `asc/dsl.sh` and `ASC_DS_EXPR` → `ds.make.sh` share one rule). |
| Embedded NUL | In file mode, if the loaded bytes contain a **NUL** (`\0`), **reject before parsing** (nonzero diagnostic, no dispatch). Bash command-substitution reads can discard NUL and join surrounding text; do not parse a silently corrupted program. |
| CRLF | Sequence on **LF only**. CRLF works because the CR is trimmed as trailing whitespace from the preceding expression. **Bare CR does not sequence** (fails closed at parse; no dispatch). Inside `(...)`, CR is layout whitespace. **Inside single-quoted arguments: preserve CR and LF byte for byte**. |
| File load snapshot | Record source size, copy **once** into a snapshot, then validate that buffer only (checked `tr` / `stat` statuses — failed tools are file errors, not empty-equal success). Reject when snapshot size ≠ pre-copy size (in-place truncate/extend during capture). Incomplete load → file error, no dispatch. **Writers:** prefer atomic rename into place; in-place truncate during read is unsupported and fail-closed when it changes length mid-capture. |
| Preparse-all | **Required** for this slice (no streaming run-until-error). |
| Bindings on unconditional sequence | Expand **all** `pN` / `a` / `sN` (and fail closed on any binding error) **before** any call dispatches — same fail-before-run family as unknown pivots / bad syntax. |
| Sequencing evidence | Prefer **one append-only log** with distinct call IDs (exact contents asserted) over separate marker files that only prove both calls ran. |
| Replay | This slice: interpreter + `make ds` / `asc/dsl.sh` file-path support. **`make replay` not in scope**; leave `replay.sh` stub until a later plan. |
| Gates | Untouched in this docs pass. Human decides later whether to add a child `gates.core.yml` row. |

## Proposed contract (draft)

### Line structure

Treat the input as a **program string** (inline argv or file contents).

| Context | Newline meaning |
|---|---|
| Top level (not inside `(...)`, not inside quotes) | Sequence operator for this slice: continue after nonzero; status is the last expression evaluated. (`;` later shares this intent.) |
| Inside `(...)` | Insignificant whitespace (layout), including before the closing `)` of an empty list. |
| Inside `'...'` | Literal data; LF and CR preserved byte for byte when present. |
| Blank line (top level, only whitespace) | Ignored; not an empty expression. |

Trailing newline after the last expression is insignificant.

### File vs inline

```text
ASC_DS_EXPR='slug(foobar)' make ds
ASC_DS_EXPR='path/to/prog.dsl.txt' make ds
asc/dsl.sh 'slug(foobar)'
asc/dsl.sh path/to/prog.dsl.txt
f_asc_dsl 'dsl-probe'
f_asc_dsl path/to/prog.dsl.txt
asc/dsl.sh path/to/prog.dsl.txt -- 'bound arg'
```

`ds.make.sh` keeps passing `"$ASC_DS_EXPR"` unchanged; file mode is decided
inside `f_asc_dsl`.

### Preparse then run

For a multi-expression program (file or inline with top-level newlines; `;`
when that token lands later):

1. In file mode: load bytes; **reject embedded NUL** before any parse.
2. Split / parse the full program (blank-line, in-paren, in-quote, CRLF rules).
3. For each expression: parse call form, **expand bindings**, resolve static
   pivot names — all **before** any expression runs.
4. Any syntax, binding, resolution, NUL, or (in file mode) file I/O error:
   diagnostic on stderr, nonzero return, **no** dispatch / log entries from
   any call.
5. On success: run in order; return the last expression’s status.

## Tasks

1. [x] **Lexer / program split** — top-level newline vs in-paren vs in-quote;
   blank lines; CRLF outside quotes; sequence runner for **newlines in this
   slice** (wire `;` later as the same sequencing operator).
2. [x] **Empty-list layout** — after `(`, skip whitespace, then `)` → empty argv.
3. [x] **File load** — `.dsl.txt` suffix → file mode; missing / non-regular /
   unreadable → file error; no inline fallback; **reject embedded NUL**
   before parse.
4. [x] **Preparse-all** — resolve pivots **and** expand bindings for every call
   before first dispatch.
5. [x] **Carrier usage text** — `f_asc_dsl_usage`, `ds.make.sh` help examples for
   file paths; keep expression-not-a-goal.
6. [x] **Tests** — acceptance below in `asc/test/core/dsl.test.sh` (+ temp
   `*.dsl.txt` fixtures). Use pivot **`dsl-probe`**. Prefer one append-only
   sequencing log with distinct call IDs.
7. [x] **Living docs** — keep [`dsl.md`](../../../specs/asc/dsl.md) observed vs
   proposed aligned when demonstrated; gate stays no/no until human review.

## Acceptance criteria

Fixture: pivot **`dsl-probe`** (`dsl_probe.sh`). Prefer disposable temp
`*.dsl.txt` files. Where argv matters, compare **NUL-delimited**
`ASC_DSL_PROBE_ARGV` bytes directly (e.g. `printf` expected `\0` stream or
`cmp` against a prepared file). **Do not** `tr '\0' '\n'` (or similar) in a way
that conflates one argument containing a newline with two arguments.

### Sequencing (append-only log and statuses)

Prefer **one append-only log file** over separate per-call marker files.
Each successful dispatch appends one line (or fixed record) with a **distinct
call ID**. Assert the log’s **exact contents** so order is proven and a
duplicate dispatch is visible (repeated ID / unexpected extra line). Two
marker files that only show both paths exist do **not** suffice.

- [x] Two-call top-level newline program: probe (or fixture) appends distinct
      call IDs to **one** log; assert exact log bytes/lines for order
      (e.g. `call-a` then `call-b` only). Use **two distinct statuses** via
      probe env (or equivalent) per call.
- [x] Status combination **`7 → 0`**: first call status 7, second 0; log shows
      both IDs in order; function / process status is **0**.
- [x] Status combination **`0 → 7`**: first 0, second 7; log shows both IDs in
      order; status is **7**.
- [x] Run the **`7 → 0`** case in a Bash **subprocess with `errexit` enabled**
      in the shell that **runs the interpreter**. Use `bash -e asc/dsl.sh …`,
      **or** bootstrap and invoke `f_asc_dsl` directly as a plain command inside
      the `bash -e` child. Do **not** treat bare `asc/dsl.sh` under a parent
      `bash -e` as sufficient: the script shebang starts another Bash that does
      **not** inherit `-e`. Avoid a function call on the left of `||` (that form
      suppresses `errexit` inside the function). Capture the child’s exit status
      from the **parent**. Expect the subprocess to finish with status 0 and the
      exact two-ID log when the interpreter is correct.
- [x] Intervening blank line: same as two-call sequence (no empty-expression
      error; same exact log).

### Layout and quotes

- [x] Wrapped argument list with pivot spelling `dsl-probe`:

  ```text
  dsl-probe(
    'a',
    'b'
  )
  ```

  NUL argv is `a\0b\0`; status 0.
- [x] Empty list with newline only inside parens is **valid** and equivalent to
      `dsl-probe()` (proposed layout fix).
- [x] Quoted newline: one argument whose value is `line1` + LF + `line2`;
      assert via **raw NUL-delimited** capture (exactly one `\0`-terminated
      field containing the LF). Harness may build the program with a real
      newline inside quotes in a `.dsl.txt` or with Bash `$'…'` **only in the
      test harness**, not as DSL syntax.
- [x] Unclosed quote spanning a newline: diagnostic, nonzero, empty sequencing
      log (no dispatch).

### Preparse-all (syntax, resolve, bindings)

- [x] Second expression unknown pivot: diagnostic, nonzero, sequencing log
      **empty** (no first-call dispatch).
- [x] Second expression truncated syntax (`dsl-probe(foo`): same — empty log.
- [x] Second expression out-of-range positional (e.g. `dsl-probe(p2)` with only
      one bound argv after `--`): diagnostic, nonzero, empty log (binding
      errors fail before any dispatch on an unconditional sequence).

### `*.dsl.txt` and Make carrier

- [x] `asc/dsl.sh "$fixture.dsl.txt"` multi-line program matches inline
      equivalent (exact sequencing log + status).
- [x] `ASC_DS_EXPR="$fixture.dsl.txt" make ds` (sole goal) same for a
      successful multi-line fixture.
- [x] `ASC_DS_EXPR='slug(foobar)' make ds` regression still works.
- [x] Missing `ASC_DS_EXPR` still fails closed (existing diagnostic family).
- [x] **File errors (suffix `.dsl.txt`, file mode):** missing path, non-regular
      path, and unreadable path each → nonzero, diagnostic, empty sequencing
      log; **not** parsed as inline DSL.
- [x] **Embedded NUL:** a `.dsl.txt` fixture whose bytes contain `\0` →
      nonzero diagnostic **before** parse/dispatch; sequencing log empty
      (proves rejection before dispatch; avoids Bash command-substitution NUL
      loss).
- [x] **CRLF fixture:** file uses `\r\n` between two top-level calls → same
      sequencing as LF (statement separation). A quoted argument whose raw
      bytes are `x\r\ny` is preserved **byte for byte** in NUL argv capture
      (exactly one field containing CR and LF).
- [x] **Bare CR:** two calls separated only by `\r` → nonzero, empty sequencing
      log (no dispatch); CR is not a sequence operator.
- [x] **Single-snapshot load:** pre-copy size matches loaded length on success;
      truncating the snapshot **between copy and validation** (simulated
      mid-capture race) → nonzero, empty log; failed validation commands
      (e.g. unreadable snap) → nonzero, empty log; embedded NUL still fails
      closed with empty log (no partial prefix dispatch).
- [x] **Exact suffix under `nocasematch`:** argument ending in `.DSL.TXT` is
      **not** file mode (inline parse fails closed; empty log).
- [x] Bound argv with file form:
      `asc/dsl.sh "$fixture.dsl.txt" -- 'bound'` expands `p1` inside the file.

### Replay readiness (interpreter only)

- [x] Whole-file program validated before first call (covered by preparse
      cases). **No** acceptance requirement to run `make replay` or finish
      `replay.sh` in this slice.

## Open decisions (remaining for the user)

Most former questions are locked under Proposed defaults. Still human-owned:

1. **New `gates.core.yml` row?** Keep under the parent `make ds` discuss row,
   or add a child changelog row when this plan leaves draft — this plan does
   not flip gates.
2. **Later options slice (parent §3 / spec):** implement commas-only + `~`
   attached values (including the raw `=` ban and acceptance cases in the
   spec) and remaining `ba`/`oa` arity rules — not blocking this draft’s
   line-break work; do not expand this plan to cover `~`.
3. **When to land `;`:** after this newline slice, as an exact synonym — timing
   stays under the parent combinator work.

If any Proposed default is wrong, say which row to flip before go-ahead.

## Spec and parent links

- [`dsl.md`](../../../specs/asc/dsl.md): observed parser baseline for
  whitespace/quotes/empty lists; proposed/deferred pointer to this plan
  (top-level newlines now; `;` later).
- [`22-make-ds.md`](../09/22-make-ds.md): children/related note; commas + `~`
  attached-value decision deferred to an options slice (not this child).

## Non-goals reminder

Do not expand this slice into the `;` token itself, full combinator
precedence, pipeline status, parallel failure reporting, loop producers,
option-token / `~` attached-value implementation, space-separated argv
grammar, or replay Make wiring. Those stay under parent §3, the spec, or a
later options / combinator plan.
