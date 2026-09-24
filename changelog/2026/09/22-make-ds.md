# `make ds` — core DSL entry point

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Contract for one ASC core entry point whose input is a README DSL string. First code slice: [22-make-ds-literal.md](./22-make-ds-literal.md). |
| **Out of this plan** | Executing the compiled string. Combinators, loops, redirects. Calling-scope tokens (`p1`, `a`, `s1`, `v-`, `b-` / `bb-` / `o-` / `oo-` / `oe-` / `ooe-`, `ba` / `bba` / `oa` / `ooa`). YAML `d0` / `d1` / `d2`. Hook filenames. A neural author of DSL. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the `make ds` row in [`gates.yml`](../../../gates.yml). `go` stays `no` until that row is approved. Approving it authorizes the literal-print slice only.

---

## What this is

README § “ASC domain-specific language : *DSL* syntax” is the language. The checklist item “Stabilize DSL” is that text, already checked. No parser, compiler, or `ds` script exists in this tree.

`make ds` is the core pivot that accepts one DSL string. Same shape as `make cc`: a script under `asc/core/`, discovered as `$subject` / `$action`, shortened by `ASC_SYNONYMS`.

| Piece | Value |
|-------|--------|
| Script | `asc/core/dsl.sh` (the path says DSL) |
| Primitive | `core/dsl` → task `core-dsl` |
| Synonym | `core-dsl/ds` in `asc/core/global.vars.sh`, next to `core-cache-clear/cc` |
| Pivot | `make ds` |
| Direct call | `asc/core/dsl.sh '<dsl>'` |

`ds` is a short pivot, same mechanism as `cc`. The script name stays `dsl.sh`. Flipping the pivot to `dsl` is a one-line synonym change (`core-dsl/dsl`) if the gate rejects `ds`.

The script sources `asc/bootstrap.sh` and resolves names with `f_make_list_entry_points` plus `f_make_list_hardcoded`. One resolver. An unknown name is an error. The compiled form is the winning script path and quoted arguments, the form README uses for `transcribe-file` and `test-in`.

Print first. The literal slice writes that text to stdout and does not run it. Execution is a later child, after print has tests.

---

## Children

| Plan | Ships | Blocked by |
|------|--------|------------|
| [22-make-ds-literal.md](./22-make-ds-literal.md) | Print one call: bare name, or name plus literal arguments. Includes the `test-*` `[[ … ]] \|\| exit 1` wrapper as text. `%` / `%%` inside a literal. | This gate |
| Calling-scope tokens | `p1`, `a`, `sN`, `v-`, boolean and named option forwarders, YAML `d0` / `d1` / `d2` | A defined caller scope. Bare `make ds` has none |
| Combinators | `;` `;;` `-;-` `+` `++` `--` `---` and loops | README bracket contradiction below |
| Execute | Run the printed string | Literal-print tests, plus an allowlist for `[]` functions (the README names a whitelist and does not list it) |

YAML `validate:` and hook filenames are consumers of a later compiler. They are not further `make ds` slices. Filename notes live in `data/ideas/2026/07/24/filename-dsl.md`. `changelog/2026/07/24-yml-structure.md` points at `changelog/2026/07/24-filename-dsl.md`, and that changelog file is absent.

`data/ideas/2026/08/A simple, minimal DSL for ASC.md` is a design note. Its prefix table (`@`, `b-oneline` = `--oneline`, one open `o-max-4` spelling) disagrees with the README. The README is the spec: `a` and `sN`; `b-` vs `bb-`; `o-` / `oo-` / `oe-` / `ooe-`.

`data/ideas/2026/07/23/dsl.md` is a different grammar (wrappers with `.`, arguments in `[]`). It is not this language.

---

## README conflicts that block later children

These stay in the README until a human proposal lands. This plan does not pick a silent grammar.

1. **Nested calls, two spellings.** The YAML example is `test-in(p1,slug(p1),snake(p1))` with no brackets, compiled to `"$(asc/instance/slug.sh …)"`. The function example requires brackets: `[f_db_clear([slug(p1)])]`.
2. **Chained calls, mixed brackets.** `[echo(v-baz)];echo(foobar)` brackets the first call only.
3. **Two compile targets.** `transcribe-file` and `test-in` compile to a script path. `service-run(d1,a)` is shown as `make service-run` and, in the next comment, as the script path. This plan prints the script path.

---

## Gaps

1. **`ds` needs the synonym footnote.** Self-explainable path is `dsl.sh`. The pivot is two letters. Gate can keep `ds` or switch the synonym to `dsl`.
2. **Bracket grammar** (conflicts 1–2). Combinator and nested-call children stay unwritten until the README has one nesting rule.
3. **Calling scope.** `p1` / `a` / `sN` / `v-` / option forwarders / `dN` refer to a hook, a YAML walk, or both. `make ds` from the shell is neither. Those tokens are a different entry contract (extra argv, an env, or an in-process caller).
4. **`[]` function whitelist** is unnamed. Execute stays closed. The literal slice accepts no `[]`.
5. **Make as the carrier.** GNU make treats `%` as a pattern, `=` as a goal assignment, `#` as a comment, and `$` as expansion. `f_make_check_args` rejects any separate goal that is already a pivot. The contract is one shell-quoted string. Tests call `asc/core/dsl.sh`. `%` through `make ds` is unverified until a test shows it.
6. **Characters inside a literal value.** README forbids most special characters and defines only `%` / `%%`. Space, comma, and parentheses inside one argument have no spelling. The literal slice rejects them.
7. **`test-*` is a prefix rule**, applied when printing, still without running the test script.
8. **No second resolver and no eager include.** Lookup reuses the make pivot lists. Parser code stays inside `asc/core/dsl.sh` until a second caller exists. No new `*.inc.sh`, loader, or global.
9. **Home instance.** `~/asc` has no README and no `dsl.sh`. Its tree is the installed layout (`core/` at the top). This plan changes the mother only. The home instance receives the script when an upgrade copies `asc/` from the mother.
10. **Stale design notes** (August idea, July 23 idea, missing filename-dsl changelog). Implement from the README section, not from those files.

---

## Tasks

- [ ] Confirm pivot `ds` (synonym `core-dsl/ds`) or switch that synonym to `dsl`.
- [ ] Confirm the first code slice is print-only, as in the child plan.
- [ ] Leave combinators unwritten until the README nesting spellings are one rule.
