# `make ds` literal print

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | First slice of [22-make-ds.md](./22-make-ds.md): print one literal DSL call. No execution. |
| **Out of this slice** | Nested calls, `[]`, combinators, loops, calling-scope tokens, YAML `dN`, hook filenames. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Starts only when the mother row in [`gates.yml`](../../../gates.yml) has `go: "yes"`. That go covers this slice and nothing after it.

---

## Behavior

`asc/core/dsl.sh` takes one argument, the DSL string. It bootstraps, builds the pivot lists (`f_make_list_hardcoded`, `f_make_list_entry_points`), and prints a shell command. It does not `eval` and does not exec the target.

Accepted forms:

| Input | Print |
|-------|--------|
| Bare pivot | `start` → the script `f_make_list_entry_points` already maps to `start`, no arguments |
| Literals | `test-in(foobar,bar,baz)` → `asc/test/in.sh 'foobar' 'bar' 'baz'` |
| README example | `transcribe-file(path/to/file.mp4)` → `asc/extensions/transcription/transcribe/file.sh 'path/to/file.mp4'` |
| Wildcard escape | `%` in a value prints `*`. `%%` prints `**` |
| `test-*` | Same resolution, wrapped as text: `[[ <script> <args> ]] || exit 1` |

Resolution is the make task name (`transcribe-file`, `slug`, `test-in`), including the `instance-` strip and `ASC_SYNONYMS`. Unknown name: non-zero exit, message on stderr, no stdout command.

Rejected in this slice (non-zero, no print): empty string, more than one argument, `[]`, `;` `;;` `+` `++` `--` `---`, `-;-`, `p1` `a` `s1` `v-` `d0` `d1`, option prefixes (`b-` `bb-` `o-` `oo-` `oe-` `ooe-` `ba` `bba` `oa` `ooa`), whitespace, a comma or parenthesis inside a value, a second pair of parentheses (a nested call).

Quotes in the printed command are single quotes. A value that is only letters, digits, and the characters README examples already use (`.`, `/`, `_`, `-`, and `*` after `%` expansion) is in scope. Anything else is a reject until a later slice spells it.

`%` is defined on the script. Passing `%` through GNU make is a separate, still open carrier gap on the mother plan. Tests invoke the script.

---

## Files

| File | Change |
|------|--------|
| `asc/core/dsl.sh` | The entry point. Parser stays in this file. |
| `asc/env/global.vars.sh` | One synonym: `core-dsl/ds` (or `core-dsl/dsl` if the gate flipped the pivot). |
| `asc/test/core/dsl.test.sh` | The table above, plus one unknown-name failure and one rejected nested call. |

After the synonym lands, `make reinit` rewrites `data/asc/pivots.mk` so `make ds` exists. The test calls the script, so it does not depend on that rewrite.

No `*.inc.sh`. No new loader. No README edit in this slice.

---

## Tasks

- [ ] After the mother gate is go: add `asc/core/dsl.sh` with the print table above.
- [ ] Add `asc/test/core/dsl.test.sh` and run it.
- [ ] Add the `core-dsl/ds` synonym beside `core-cache-clear/cc`.
