# `make ds` — DSL interpreter entry point

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 (rewritten 2026-11-17) |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Contract for the ASC custom DSL interpreter. Grammar and proposed resolutions: [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md). |
| **Out of this plan** | Merging escaped README proposals into human prose. Filling whitelist membership beyond “deny by default”. Filename-hook consumers. A neural author of DSL. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the `make ds` row in [`gates.core.yml`](../../../../gates.core.yml). `go` stays `no` until that row is approved.

**What gate approval means:** `go: "yes"` **accepts the proposed semantic defaults in the DSL spec as the implementation contract** (caller binding, return-vs-exit, pivot resolution, reserved literal quoting, chaining rules, `test-*` status, and the rest of that file’s proposed table). It authorizes implementing `f_asc_dsl` against that contract. It does not itself rewrite README prose. The 2026-11-17 commits locked **entry-point shape** only; they did not accept those semantics by themselves.

---

## Entry shape locked 2026-11-17 (commits)

1. Treat the custom DSL like `asc/escape.sh` at the make boundary: a **top-level** script and a **hardcoded** `make ds`, not a discovered `core-dsl` synonym.
2. Interpreter lives in `f_asc_dsl` (`asc/core/dsl.manual-inc.sh`), sourced from bootstrap; `asc/dsl.sh` is the carrier.
3. `asc/instance/ds.sh` is removed.
4. **`f_asc_dsl` is an interpreter from the start** — not a print-then-later-execute product.
5. Target grammar is the README DSL section; semantic forks are proposed in the DSL spec (accepted when this gate goes).
6. The former print-only child ([22-make-ds-literal.md](22-make-ds-literal.md)) is **abandoned**.

| Piece | Value |
|-------|--------|
| Script | `asc/dsl.sh` |
| Interpreter | `f_asc_dsl` in `asc/core/dsl.manual-inc.sh` |
| Pivot | hardcoded `ds` in `asc/make/default.mk` |
| Spec | [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) |
| Direct call | `asc/dsl.sh '<dsl>'` or `f_asc_dsl '<dsl>' [-- …]` |

---

## What this is

README § “ASC domain-specific language : *DSL* syntax” is the language. Runtime stubs exist; they do not yet interpret.

`f_asc_dsl` parses one DSL string, resolves pivots per the spec (discovered paths; DSL-safe hardcoded map without embedded flags), binds optional caller argv after `--`, and **runs** the result. It **returns** status; it does not `exit` on test failure.

Coverage may land in waves (literals first, then combinators, then calling-scope, and so on). Every wave executes; none ships print-only as the product. A debug/dry-run print flag may appear later without changing that framing.

The backlog dependency “accepted valid Bash for the validation example” is met when this gate accepts the spec’s `test-*` / embedding form (`script … || exit 1` at the embedding boundary; `return` from `f_asc_dsl`).

---

## Children / related

| Item | Role |
|------|------|
| [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md) | Living grammar + proposed resolutions |
| [22-make-ds-literal.md](22-make-ds-literal.md) | **Abandoned** (print-only slice cancelled) |
| Combinator / loop / calling-scope coverage | Waves under this plan, gated by the same row unless a human splits them |
| YAML `validate:` / hook filenames | Consumers that call `f_asc_dsl` with binding; not separate print products |

`data/ideas/2026/08/A simple, minimal DSL for ASC.md` and `data/ideas/2026/07/23/dsl.md` disagree with the README. Implement from the README and the DSL spec.

---

## Gaps

1. **`f_make_list_hardcoded` omits `ds`** and still disagrees with `default.mk` (`init.make.sh` vs `init.sh`; flag-bearing entries). Align Make hygiene and keep a DSL-safe path-only map.
2. **Make carrier** for `%`, `=`, `#`, `$` — tests should call `asc/dsl.sh` / `f_asc_dsl`; `make ds` carrier cases need explicit verification.
3. **Whitelist membership** — deny by default; exact list still open.
4. **Home instance** receives scripts when an upgrade copies `asc/` from the mother.

---

## Tasks

- [ ] Align `default.mk` and `f_make_list_hardcoded` (including `ds`); define the DSL-safe hardcoded path map (reject compound recipe names).
- [ ] Implement `f_asc_dsl` per [docs/specs/asc/dsl.md](../../../specs/asc/dsl.md): binding `--`, return-not-exit, resolver rules, reserved quoting, coverage waves OK.
- [ ] Tests: `f_asc_dsl` / `asc/dsl.sh` for literals; binding examples (direct, hook-style `-- "$@"`, YAML-style `dN`); reject compound hardcoded names; assert `f_asc_dsl` does not `exit` the test harness on a failed `test-*`.
- [ ] Leave README human text alone except dated escaped proposals next to changed passages.
