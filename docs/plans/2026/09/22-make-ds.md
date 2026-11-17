# `make ds` — DSL interpreter entry point

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 (rewritten 2026-11-17) |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Contract for the ASC custom DSL interpreter. Grammar and proposed resolutions: [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md). |
| **Out of this plan** | Accepting README proposals. Filling the function whitelist membership list beyond “deny by default”. Filename-hook consumers. A neural author of DSL. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the `make ds` row in [`gates.core.yml`](../../../../gates.core.yml). `go` stays `no` until that row is approved. Approving it authorizes implementing `f_asc_dsl` against the DSL spec (interpreter that runs DSL). It does not silently rewrite the README.

---

## Decisions locked 2026-11-17

The last two mother commits are accepted for this plan:

1. Treat the custom DSL like `asc/escape.sh` at the make boundary: a **top-level** script and a **hardcoded** `make ds`, not a discovered `core-dsl` synonym.
2. Interpreter lives in `f_asc_dsl` (`asc/core/dsl.manual-inc.sh`), sourced from bootstrap; `asc/dsl.sh` is the carrier.
3. `asc/instance/ds.sh` is removed.
4. **`f_asc_dsl` is an interpreter from the start** — not a print-then-later-execute product.
5. Target grammar is the README DSL section; the living spec proposes defaults where the README forks.
6. The former print-only child ([22-make-ds-literal.md](22-make-ds-literal.md)) is **abandoned**.

| Piece | Value |
|-------|--------|
| Script | `asc/dsl.sh` |
| Interpreter | `f_asc_dsl` in `asc/core/dsl.manual-inc.sh` |
| Pivot | hardcoded `ds` in `asc/make/default.mk` |
| Spec | [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) |
| Direct call | `asc/dsl.sh '<dsl>'` |

Keep `f_make_list_hardcoded` in sync with `default.mk` for `ds`.

---

## What this is

README § “ASC domain-specific language : *DSL* syntax” is the language. The checklist item “Stabilize DSL” is that text. Runtime stubs exist; they do not yet interpret.

`f_asc_dsl` parses one DSL string, resolves pivots with the same lists as make (`f_make_list_hardcoded`, `f_make_list_entry_points`), and **runs** the result. Unknown names and out-of-scope tokens are errors.

Coverage may land in waves (literals first, then combinators, then calling-scope, and so on). Every wave executes; none ships print-only as the product. A debug/dry-run print flag may appear later without changing that framing.

---

## Children / related

| Item | Role |
|------|------|
| [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) | Living grammar + proposed resolutions |
| [22-make-ds-literal.md](22-make-ds-literal.md) | **Abandoned** (print-only slice cancelled) |
| Combinator / loop / calling-scope coverage | Waves under this plan, gated by the same row unless a human splits them |
| YAML `validate:` / hook filenames | Consumers of the interpreter or of a later embedding helper; not separate print products |

`data/ideas/2026/08/A simple, minimal DSL for ASC.md` and `data/ideas/2026/07/23/dsl.md` disagree with the README. Implement from the README and the DSL spec.

---

## README conflicts

Tracked and given **proposed** defaults in the DSL spec (nesting brackets, chained brackets, run form, invalid `test-*` `[[ … ]]` wrapper, unnamed function whitelist, calling scope for bare `make ds`). Do not pick a silent second grammar in code. Land README wording through escaped proposals or a human edit.

---

## Gaps

1. **`f_make_list_hardcoded` omits `ds`** while `default.mk` has it.
2. **Make carrier** for `%`, `=`, `#`, `$` — tests should call `asc/dsl.sh`; `make ds` carrier cases need explicit verification.
3. **Calling scope** — bare `make ds` has none; spec proposes hard errors for those tokens.
4. **Whitelist membership** — deny by default; exact list still open.
5. **Home instance** receives scripts when an upgrade copies `asc/` from the mother.

---

## Tasks

- [ ] Keep `default.mk` `ds` and `f_make_list_hardcoded` aligned.
- [ ] Implement `f_asc_dsl` as an interpreter per [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) (coverage waves OK; no print-only product).
- [ ] Add tests that invoke `asc/dsl.sh` / `f_asc_dsl` (not only `make ds`).
- [ ] Leave README human text alone except dated escaped proposals next to changed passages.
