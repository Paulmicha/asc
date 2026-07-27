# Plan stub: ASC DSL in filename patterns

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (not implemented; multi-shell groundwork WIP; Cursor rules partially landed) |
| **Tracked SoT** | [`changelog/2026/07/24-filename-dsl.md`](../../../changelog/2026/07/24-filename-dsl.md) |
| **Note** | `data/plans/review/*` is gitignored except `README.md`. Full plan + decision record lives in the changelog (same convention as `changelog/2026/07/23-f-e-naming-convention.md`). Keep this stub here for lifecycle lane only; update status / move folder when review → iterate → accepted / rejected. |

## Scope (see changelog)

- Filename DSL: `()` wrap, `.` nest, `[]` args / `b-*` booleans / `o-*` options; MAKE_TASKS_SHORTER; explicit `$action` files; **DSL hook stems under `$subject/`** (not `$subject/$action/`).
- **Documentation `$` notation** (locked): any `$`-prefixed name in **documentation files** = **"any make entry point"**; docs only — **not** file names; purpose = precise shared vocabulary.
- **Exception — `$subject` (only):** `$subject` **can** be plain **slugified string** values (like any var or function name), **or**, in the case of `*.hook.yml` or `*.hook.sh`, our **custom DSL notation**.
- **Slot** (locked): lives in the **YAML hook definition** (`*.hook.yml`) — not as a filename bracket token.
- **First `-` policy** (locked): no same-word `_` separator; intra-token head/tail from position of the first `-`.
- **Optional `_`** (locked intent, not enforced; **position matters**): soft **prefix in `$action`** naming — `$subject` / `$object` `_` `$action` `. (variants)? . (hook|inc|opt-inc)? . sh`. Not a relation; not a replacement for `--` field/triple forms; first `-` unchanged. Peer IDs like `remote_db` = demoted historical note only. Phase 0a = docs; no DSL parser rule yet.
- **Relations / fields (mapping complete):** `($field.able.subject)--($field.able.object)`; `($triple.able.subject)--($triple.able.predicate)--($triple.able.object)`; via `$action.able.yml` → `$subject.$action` (distinct from first-`-`).
- **Shell genericity:** `ASC_SHELL` default `bash`; shell-specific alternates `*.$ASC_SHELL.inc.sh` / `*.$ASC_SHELL.opt-inc.sh` if present; complete WIP groundwork (`648a4d7`, `8f3faa8`, `f971316`).
- **Single include-loader hook** (locked): one dedicated hook loads includes by `ASC_SHELL`. Include files are **not** hook implementations. Bash unqualified `*.inc.sh` / `*.opt-inc.sh` = default + fallback. Eager vs lazy timing unchanged.
- **Primordial layout (settled):** eager `asc/asc/{core,global,hook,autoload}.inc.sh`; lazy `asc/asc/utils/{array,fs,shell,string}.opt-inc.sh` (`asc` → `core`).
- **Tests (required):** create shunit2 cases under existing `make test-core` / `asc/test/asc/*.test.sh` harness (Phase 1 onward). Test steps may use nest/wrap DSL; synonyms `llv-get`/`llv-set` ↔ `log.level_get`/`log.level_set`.
- **Cursor rules (Phase 0c — partially landed):** `.cursor/rules/doc-notation.mdc` + `naming.mdc` — agents must use `$` doc notation + locked field/triple forms; **`$subject` sole exception** (slug **or** hook DSL); broader DSL/prefix locks in `naming.mdc`.
- **Living docs + next-steps (Phase 0d — required):** thorough update of ASC `docs/asc/**` + home `~/docs/next-steps.md` for `$` notation / relations / multi-shell notes as touched.

## Quick card (see changelog for full plan)

```text
# DOC NOTATION (docs only — not filenames): $name = any make entry point
# Exception ($subject only): plain slugified string, OR (*.hook.yml / *.hook.sh) custom DSL notation
# PATH: DSL hook stems under $subject/ (not $subject/$action/)
#   $subject/lt(agent…).start.hook.(sh|yml) ; $subject/entity_yml[state](p-1).is_default.hook.yml
foo(bar)              → wrap
foo.bar               → nest
foo[bar]              → arg(*) → p_
foo[b-oneline]        → boolean(b-*) → b_
foo[…,o-…]            → option(o-*) | arg(*) → o_ / p_
# first '-' = intra-token split (no same-word '_' rule)
# optional '_' prefix in $action (position matters, not enforced):
#   $subject/$object _ $action . (variants)? . (hook|inc|opt-inc)? . sh
# relations are '--' able forms (always $ in docs) — optional '_' is NOT a relation
# peer IDs like remote_db = demoted historical note only
($field.able.subject)--($field.able.object)
                      → field → $action.able.yml → $subject.$action
($triple.able.subject)--($triple.able.predicate)--($triple.able.object)
                      → triple (the rest) → $action.able.yml
# mapping complete — no bare -- / --relation-- / triple.predicate / missing-$
# slot → *.hook.yml (not foo[slot])
MAKE_TASKS_SHORTER: arg→argument(p_), o→option(o_), b→boolean(b_), f→function/action (no var prefix; explicit $action file)
  llv-get → log.level_get ; llv-set → log.level_set

# Test steps (same grammar):
test(log.level_get) / test.llv-get / assert(llv-set[debug])
Tests: make test-core → asc/test/asc/*.test.sh (shunit2); Phase 1 creates cases

ASC_SHELL — single include-loader hook:
  try *.$ASC_SHELL.inc.sh / *.$ASC_SHELL.opt-inc.sh if exists
  else *.inc.sh / *.opt-inc.sh                 → bash (default + fallback)
  # e.g. *.zsh.inc.sh / *.posix.opt-inc.sh
  # NOT *.opt-inc.posix.sh (superseded)
  # includes ≠ hook implementations; one hook loads them

Primordial (settled) — include files:
  asc/asc/{core,global,hook,autoload}.inc.sh      → eager
  asc/asc/utils/{array,fs,shell,string}.opt-inc.sh → lazy

Cursor rules (landed): .cursor/rules/doc-notation.mdc + naming.mdc
Living docs pass: Phase 0d (includes ~/docs/next-steps.md)
```
