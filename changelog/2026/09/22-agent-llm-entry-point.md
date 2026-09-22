# `make agent-llm` — abstract hook call, cursor hook implementation

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **proposal** — plan / review (not implemented). Docs only until `gates.yml` go. |
| **Scope** | One new `$subject-$action` pivot: `agent-llm`. Hook call in the agent core extension. Hook implementation in the cursor ASC contrib extension. No second pivot (`cursor-llm`), no second entity/able per tool. |
| **Out of this plan** | Writing the entry-point script, the hook call body, or any `*.hook.sh`. Ollama / Codex / Claude LLM bodies. Prompt sandwich variants. Builder / workflow. README rewrite. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

Go-ahead is the `agent-llm` row in [`gates.yml`](../../../gates.yml). `go` stays `no` until that row is approved. Approving authorizes implementing this layout only.

**Git context:** mother tree was dirty (gates / make-ds changelogs) when this plan was written; no pull.

---

## Context (verified in this tree)

### Abstract entry point (agent core extension)

Exists today for sibling pivots, e.g. `asc/extensions/agent/agent/start.sh`:

```bash
. asc/bootstrap.sh
hook_ms -s 'agent' -a 'start' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
```

Same shape: `stop.sh`, `list.sh`, `status.sh`, `pull.sh`, `stop_all.sh`. Make discovers them as `agent-start`, `agent-stop`, etc. The agent extension is opt-in core under `asc/extensions/agent/`.

There is already an empty stub `asc/extensions/agent/llm/llm.entity.yml` (subject folder `llm`, not the action). This plan’s pivot is `agent` / `llm` → `asc/extensions/agent/agent/llm.sh` (**to add**). Do not treat the empty entity stub as the entry point.

### Hook implementation (cursor contrib)

Cursor lives at `scripts/asc/contrib/asc/cursor/`. Today it only has an empty `agent/wrap.sh`. No `*.hook.sh` yet.

Sibling pattern for a tool extension that wins `hook_ms`: `scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh` for `hook_ms -s 'db' -a 'dump'` (entry point `asc/extensions/db/db/dump.sh` → `f_db_dump` → `hook_ms`). Subject folder name matches `-s`.

Closest agent precedent: ollama ships `scripts/asc/contrib/asc/ollama/gpt/*.hook.sh` with comments claiming `hook_ms -s 'agent' -a 'start'`. Those files sit under subject `gpt`, not `agent`. This plan does **not** copy that layout; the cursor hook implementation belongs under `…/cursor/agent/` so the subject matches the hook call.

### `hook_ms` ranking (code, done 2026-09-21)

Confirmed in `asc/core/hook.manual-inc.sh` (`f_hook_ms_measure`) and [21-hook-specificity-rungs.md](./21-hook-specificity-rungs.md). Low to high:

1. `asc/` and `asc/extensions/` (rung 0)
2. `scripts/asc/contrib/asc/` (rung 1)
3. other `scripts/asc/contrib/$vendor/` (rung 2)
4. `scripts/asc/extend/` (rung 3)
5. project-root path from `-r` (rung 4)

Inside one rung: dot-parts + slash-parts; equal rank keeps the later file. So a cursor contrib hook implementation **beats** any core / `asc/extensions` candidate. Contrib does not lose to the agent extension’s own files.

### Enabled / disabled

README § “Enabling and disabling extensions”: `.asc_extensions_ignore` lists **disabled** extensions. Not listed ⇒ enabled. Contrib lines use the vendor prefix (e.g. `asc/cursor`).

In this mother checkout both are ignored today:

- `agent`
- `asc/cursor`

`make list-extensions` inspects the current instance. Disabled extensions are not in `ASC_EXTENSIONS`; their active dirs and hook implementations are not discovered.

“Cursor enabled ⇒ default hook implementation” here means: with `asc/cursor` removed from the ignore file, `scripts/asc/contrib/asc/cursor/agent/llm.hook.sh` is a candidate and, as the usual only match for this hook call, is what `hook_ms` sources. No second make pivot. No `DB_DRIVER`-style env required for this first cut.

---

## Plan (when gates go)

### 1. Hook call — agent core extension

| Piece | Path / shape |
|-------|----------------|
| Entry point (**to add**) | `asc/extensions/agent/agent/llm.sh` |
| Pivot | `make agent-llm` (discovered like `agent-start`) |
| Hook call | `hook_ms -s 'agent' -a 'llm'` (variants only if a real caller needs them; start uses `HOST_OS HOST_TYPE INSTANCE_TYPE`) |
| Entity | Keep sharing `asc/extensions/agent/agent/agent.entity.yml`. Do not mint a cursor-specific entity for this pivot. |

Script shape matches `start.sh`: bootstrap, then the one `hook_ms` line. No tool logic in that file.

### 2. Hook implementation — cursor contrib

| Piece | Path / shape |
|-------|----------------|
| Hook implementation (**to add**) | `scripts/asc/contrib/asc/cursor/agent/llm.hook.sh` |
| Subject dir | `agent` (matches `-s 'agent'`) |
| Role | Concrete Cursor LLM call when the hook call runs |

Optional later: variant files (`llm.<variant>.hook.sh`) if an instance needs them. Not required for the first slice.

### 3. What “enabled” does

| Instance state | Result |
|----------------|--------|
| `agent` enabled, `asc/cursor` enabled | `make agent-llm` exists; `hook_ms` sources the cursor hook implementation (rung 1). |
| `agent` enabled, `asc/cursor` disabled | Pivot exists; `hook_ms` finds no cursor file. Unless another enabled contrib supplies `agent/llm*.hook.sh`, nothing is sourced (same empty-winner behavior as other abstract agent pivots without a match). |
| `agent` disabled | Pivot is not registered; ignore file (or enable) is the control, not a second namespace. |

Project override remains `scripts/asc/override/` after the pick (existing mechanism). Extend (rung 3) can still beat contrib if an instance adds its own hook implementation.

### 4. Why this split

One abstract `$subject-$action`. The agent extension owns the harness (hook call). The tool extension owns the body (hook implementation). Matches the harness law in `.cursor/rules/asc-lightweight.mdc` and the db / mysql split. Cursor is not a second make pivot.

---

## README note (report only; no README edit)

README Workflow still names `make agent-loop`, `make llm-call`, and an env-var provider pick (like `DB_DRIVER`). This plan uses `agent-llm` and enablement of `asc/cursor` as the default hook implementation. Prefer no README change until a human settles those names.

## Safety notes

- Do not implement until `gates.yml` sets `go: "yes"` for this row.
- Do not add `cursor-llm` or score entry points so one namespace drops the other ([21-hook-specificity-rungs.md](./21-hook-specificity-rungs.md) follow-up: no entry-point score).
- Do not place the first hook implementation under `asc/extensions/agent/` if cursor is meant to be the default concrete body — that would sit on rung 0 and lose to any contrib match, and would bake a tool into the abstract extension.
- Leave the empty `llm.entity.yml` alone unless a separate entity plan owns it.
- Mother ignore list currently disables both extensions; enabling is an instance decision after the files exist.

---

## Open tasks

- [ ] After gates go: add `asc/extensions/agent/agent/llm.sh` (hook call only).
- [ ] After gates go: add `scripts/asc/contrib/asc/cursor/agent/llm.hook.sh` (hook implementation).
- [ ] After gates go: enable `agent` and `asc/cursor` on a test instance; run `make agent-llm` / dry-run `hook_ms` and confirm the cursor path wins.
- [ ] Optional: measure or document what the entry point should do when no hook implementation matches (today: no source).
- [ ] Do not commit from this proposal note alone.
