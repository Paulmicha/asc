# `make agent-plan` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement headless `make agent-plan` per the settled contracts in [10-agent-plan-cursor-codex-ollaya.md](./10-agent-plan-cursor-codex-ollaya.md): Cursor writer, Codex reviewer, Ollaya decider, staging/promotion, JSON harness I/O.

**Architecture:** Abstract `chat/new`, `chat/reply`, and `decide/run` in `asc/extensions/agent` select a **bound** role-qualified hook (enumerate via `hook -t`, rank like `hook_ms`, seed opt-incs, source once) and emit one JSON object on stdout. Contrib: `scripts/asc/contrib/asc/cursor` (writer), `…/codex` (reviewer), `…/ollaya` (decider). `make agent-plan` owns staging, isolation, flock+recheck promotion, reviewer prompt assembly, and the loop; it calls the abstract harnesses and does **not** embed Ollaya HTTP itself.

**Tech Stack:** Bash 4 / ASC bootstrap, Make pivots, Cursor Agent CLI (`agent`), Codex CLI (install on host), Ollaya local API (`127.0.0.1:11435`) via `asc/ollaya` hooks, shunit2 under `asc/test/`, optional `bwrap` for `enforced` isolation.

**Spec:** [10-agent-plan-cursor-codex-ollaya.md](./10-agent-plan-cursor-codex-ollaya.md) — contracts §1–§8 are normative. This file does not relax them.

**Authorization:** Still **not** an implementation go-ahead by itself. Do not enable `agent` / `asc/cursor` / `asc/codex` / `asc/ollaya` on the mother by default. Do not add Claude hooks. Do not invent a gates row unless the human asks. Commit only when the human asks for commits during execution.

## Global Constraints

- **Headless only** — CLI/SDK sessions; no desktop composer injection.
- **Models** — Cursor **Auto**; Codex **GPT Terra 6.1 – High effort** (exact CLI flags verified in Task 0).
- **Roles** — chat: `writer` / `reviewer` via `CHAT_ROLE`; decide: `decider` via `DECIDE_ROLE`; mapping by hook filename placement; no provider env config.
- **Promotion race** — flock + recheck + same-dir rename is **not** kernel content-CAS; an editor that ignores `*.asc-plan.lock` can still race (§3 of the spec). Log that limit; do not claim it is closed.
- **Weakened isolation** — detects differences visible in before/after docroot content inventories at scan time only; temporary writes restored before the after-scan are invisible; outside-docroot writes are not claimed prevented.
- **Ollaya / decider** — classifies **review text** only; does not prove the plan is correct. Prefer `/v1/systemone`; truncation → `invalid`. Lives in `scripts/asc/contrib/asc/ollaya`, not in `plan.sh`.
- **Hook cache** — `data/asc/cache/hook/*.sh` freezes lookup results until removed; tests and manual smokes must clear relevant cache keys after adding/changing hooks or extensions (see Task 1).
- **ASC authoring** — follow `.agents/skills/asc-author-code/SKILL.md` (templates + anti-patterns) before writing shell; no second make pivot per tool.
- **Mother guard** — no client-identifying content in this tree.

---

## File map

| Path | Responsibility |
|------|----------------|
| `asc/extensions/agent/role_select.inc.sh` (new) | Shared §1 select for chat and decide; sets `CHAT_HOOK_SOURCE` or `DECIDE_HOOK_SOURCE` |
| `asc/extensions/agent/chat/chat_result.inc.sh` (new) | Emit single JSON result on stdout (chat + reusable bits for decide) |
| `asc/extensions/agent/chat/new.sh` | Abstract `chat-new`: select + source writer/reviewer hook; no pre/post |
| `asc/extensions/agent/chat/reply.sh` | Abstract `chat-reply`: same |
| `asc/extensions/agent/chat/read.sh`, `archive.sh` | Rename variant `chat_TYPE` → `CHAT_TYPE` only |
| `asc/extensions/agent/decide/run.sh` (new) | Abstract `decide-run`: select + source `decider` hook; JSON stdout |
| `asc/extensions/agent/agent/plan.sh` (new) | `make agent-plan` orchestrator (calls chat + decide) |
| `asc/extensions/agent/agent/plan_stage.inc.sh` (new) | Path validation, staging dir, digests, flock promotion, inventories |
| `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh` | Cursor Auto create |
| `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh` | Cursor Auto resume/reply |
| `scripts/asc/contrib/asc/codex/chat/new.reviewer.hook.sh` | Codex Terra 6.1 High create |
| `scripts/asc/contrib/asc/codex/chat/reply.reviewer.hook.sh` | Codex resume/reply (no force) |
| `scripts/asc/contrib/asc/ollaya/decide/run.decider.hook.sh` (new) | `/v1/systemone` decide + class mapping per spec §6 |
| `asc/extensions/agent/test/core/role_select.test.sh` (new) | Role selection + **hook cache** (chat + decide) |
| `asc/extensions/agent/test/core/plan_stage.test.sh` (new) | Path, digest, flock, inventory |
| `asc/extensions/agent/test/core/decide_ollaya.test.sh` (new) | Decider fixtures + truncation (+ cache after hook add) |
| `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md` (new, after Task 0) | Host feasibility record |

Split names may shrink if a single caller only needs an inline helper (asc-author-code: do not extract without a second caller).

---

### Task 0: Host feasibility record

**Files:**
- Create: `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md`

**Produces:** pinned CLI flags, isolation mode, Ollaya model id, confirmed or revised clean threshold, Codex install path.

- [ ] **Step 1: Probe Cursor Agent CLI**

```bash
. asc/bootstrap.sh
command -v agent
agent about
agent create-chat
# Note id; then probe model Auto for -p / --print (no --model override).
agent -p --output-format json "Reply with exactly: pong" </dev/null || true
```

Record: binary path, version, how to pass **Auto** (omit `--model` vs explicit), resume flag (`--resume <id>`), whether `--force` is required for writes.

- [ ] **Step 2: Probe Codex CLI**

```bash
command -v codex || ls ~/.codex 2>/dev/null | head
# Install if missing; then:
codex --help 2>&1 | head -80
```

Record: create/resume commands, how to set **GPT Terra 6.1 – High effort**, how to omit write/auto-apply flags. If read-only invocation cannot be shown, note `reviewer_isolation` must be `weakened` or fail-closed per operator policy (default: allow weakened with loud logs).

- [ ] **Step 3: Probe Ollaya + sandbox**

```bash
command -v ollaya; curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:11435/api/tags || true
command -v bwrap; bwrap --version 2>&1 | head -1 || true
ollaya list 2>&1 | head -40
```

Pull a decide model if needed (`winnow:e4b` or `laya` / `coba:150m-ternary`). Run one `/v1/systemone` decide with the `plan_ready` questions from the spec against a short “clean” and a short “issues” string; note raw `confidence` values.

- [ ] **Step 4: Write the host note**

Fill `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md` with: date, `writer_isolation` / `reviewer_isolation` (`enforced`|`weakened`), Cursor flags, Codex flags, Ollaya binary/API reachability, decide model id, measured confidences, whether threshold stays **0.75** or a revised value to copy back into the design changelog before Task 5–6. Note that the decider body will live under `scripts/asc/contrib/asc/ollaya`.

- [ ] **Step 5: Stop if blockers**

If Cursor Auto or Codex High cannot be invoked headlessly, stop and report—do not invent alternate models.

---

### Task 1: Shared role selection + chat JSON + hook-cache tests

**Files:**
- Create: `asc/extensions/agent/role_select.inc.sh`
- Create: `asc/extensions/agent/chat/chat_result.inc.sh`
- Modify: `asc/extensions/agent/chat/new.sh`
- Modify: `asc/extensions/agent/chat/reply.sh`
- Modify: `asc/extensions/agent/chat/read.sh`, `archive.sh` (`CHAT_TYPE` only)
- Create: `asc/extensions/agent/test/core/role_select.test.sh`

**Interfaces:**
- Consumes: `hook`, `f_hook_ms_measure`, `f_hook_source_opt_incs_for_path`, `f_autoload_override` / `f_hook_resolve_source_path`
- Produces: `f_agent_role_select` (subject, action, role_var name, role value, out_var for source path); `f_chat_result_emit` prints one JSON object

- [ ] **Step 1: Write failing selection tests (including cache)**

Follow `asc/test/core/hook.test.sh` (unique `nftasc…` prefixes, `rm -f data/asc/cache/hook/*<token>*` in setup/teardown).

Required cases (chat **and** parallel decide stubs under a temp contrib/extend path):

1. No role file → `no_hook_for_role`.
2. Only `new.hook.sh` / `run.hook.sh` → `unqualified_hook_winner`.
3. `new.writer.hook.sh` / `run.decider.hook.sh` present → winner basename matches.
4. Same rung: unqualified higher sum + role-qualified lower → **fail**.
5. Two role-qualified on same winning rung → `hook_role_conflict`.
6. **Cache stale:** warm cache; add role file without deleting cache; assert stale `hook -t` behavior; `rm` cache key; role file wins.
7. **Cache after extension/hook change:** same as design for enablement toggles; clear cache then win.
8. Opt-inc marker after select+source.

- [ ] **Step 2: Run tests — expect FAIL**

```bash
. asc/bootstrap.sh
make test-agent 2>/dev/null || asc/extensions/agent/test/core.sh
```

- [ ] **Step 3: Implement `f_agent_role_select`**

```bash
# Match hook_ms ranking; do not call hook_ms for select-then-run.
# hook -t -s "$subject" -a "$action" -v "… $role_var …"
# C_win must match ^${action}.${role}.hook.sh$; conflict/unqualified rules per spec §1
# f_hook_source_opt_incs_for_path; resolve override → out_var
```

- [ ] **Step 4: Implement JSON emitter + slim `new.sh` / `reply.sh`**

- Drop pre/post hooks.
- `f_agent_role_select` then `. "$CHAT_HOOK_SOURCE"`.
- Harness failures still emit JSON with null ids; stderr only for logs.

- [ ] **Step 5: Rename `chat_TYPE` → `CHAT_TYPE` on read/archive**

- [ ] **Step 6: Re-run tests — expect PASS**

- [ ] **Step 7: Commit only if the human asked**
---

### Task 2: Staging, path validation, promotion, inventory

**Files:**
- Create: `asc/extensions/agent/agent/plan_stage.inc.sh`
- Create: `asc/extensions/agent/test/core/plan_stage.test.sh`

**Produces:** `f_plan_path_validate`, `f_plan_stage_init`, `f_plan_live_before`, `f_plan_promote`, `f_plan_inventory_capture`, `f_plan_inventory_diff`

- [ ] **Step 1: Failing tests**

Cases from spec §3–§4a: `..` escape; live symlink; missing parent; create-from-absent; digest change during “writer” (simulate); flock held by second promoter; weakened inventory: ignored file content change, addition, deletion, symlink, unreadable → `write_boundary` / `inventory_error`; document residual unlocked promotion race in a test comment (optional flaky interval test marked as best-effort).

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement**

- Validate under canonical `PROJECT_DOCROOT`.
- Staging outside project tree.
- Lock: `<live>.asc-plan.lock`, exclusive `flock`, recheck `live_before`, temp+fsync+rename.
- Inventory: full docroot walk including ignored files; no git-only shortcut.

- [ ] **Step 4: Run — expect PASS**

---

### Task 3: Cursor writer hooks

**Files:**
- Create: `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh`
- Create: `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh`

**Consumes:** Task 0 Cursor flags; cwd = staging dir; plan relative path only.

- [ ] **Step 1: Manual smoke (instance with `asc/cursor` enabled)**

```bash
# Clear hook cache after adding files:
rm -f data/asc/cache/hook/*chat*
CHAT_ROLE=writer make chat-new …
```

- [ ] **Step 2: Implement hooks**

- `new`: `agent create-chat` + first `-p` turn with Auto; capture `provider_session_id` / `chat_id`; fill JSON via `f_chat_result_emit` (or set vars the abstract script emits).
- `reply`: `--resume` with session id.
- Allow `--force` only as recorded in host note; writes only under staging cwd.

- [ ] **Step 3: Automated test or scripted smoke**

Assert JSON `ok:true`, non-null session ids, empty_reply / failed paths set `ok:false`.

- [ ] **Step 4: Re-clear hook cache in test teardown after file touches**

---

### Task 4: Codex reviewer hooks

**Files:**
- Create: `scripts/asc/contrib/asc/codex/chat/new.reviewer.hook.sh`
- Create: `scripts/asc/contrib/asc/codex/chat/reply.reviewer.hook.sh`

- [ ] **Step 1: Implement with Task 0 flags — no `--force` / yolo / auto-write**

- [ ] **Step 2: Smoke create + resume; JSON contract**

- [ ] **Step 3: Confirm prompt is supplied by orchestrator later; hooks must not strip inlined bytes**

- [ ] **Step 4: Hook cache clear after install**

---

### Task 5: Abstract `decide-run` + `scripts/asc/contrib/asc/ollaya` decider

**Files:**
- Create: `asc/extensions/agent/decide/run.sh`
- Create: `scripts/asc/contrib/asc/ollaya/decide/run.decider.hook.sh`
- Create: `asc/extensions/agent/test/core/decide_ollaya.test.sh`
- Create: `asc/extensions/agent/test/core/fixtures/ollaya_plan_ready/*.txt`
- Create: `asc/extensions/agent/test/core/fixtures/ollaya_plan_ready/expected.tsv`
- Optional: `scripts/asc/contrib/asc/ollaya/README.md` (one short paragraph: enablement + `DECIDE_ROLE=decider`)

**Produces:** `make decide-run` with `DECIDE_ROLE=decider`; JSON per spec §6 (`class`, `choice`, `confidence`, `model`, `raw`, …).

- [ ] **Step 1: Fixture files** matching spec §6 table (clean, issues, caveats, negation, mixed, empty, garbage, truncation).

- [ ] **Step 2: Failing tests**

- Selection: `DECIDE_ROLE=decider` finds `run.decider.hook.sh`; missing/unqualified/conflict; **hook cache** clear after adding the ollaya hook.
- Classify: fixture → expected `class`; `422` / missing `confidence` → `invalid`.

- [ ] **Step 3: Implement abstract `decide/run.sh`**

```bash
. asc/bootstrap.sh
# DECIDE_ROLE=decider (required in v1)
f_agent_role_select 'decide' 'run' 'DECIDE_ROLE' 'decider' 'DECIDE_HOOK_SOURCE'
. "$DECIDE_HOOK_SOURCE"
```

No pre/post. Pass state (reviewer reply) via arg / file / stdin — pick one and document in the script header; orchestrator must use that form.

- [ ] **Step 4: Implement `run.decider.hook.sh`**

```bash
# POST /v1/systemone with plan_ready questions from spec §6
# Map choice+confidence → class; emit JSON via shared emitter
# Model + threshold from host note
```

- [ ] **Step 5: Live decide + mocked truncation; clear `data/asc/cache/hook/*decide*` after file install**

- [ ] **Step 6: If threshold must change, update the design changelog in the same authorized change set**
---

### Task 6: `make agent-plan` orchestrator

**Files:**
- Create: `asc/extensions/agent/agent/plan.sh`
- Create: `asc/extensions/agent/test/core/plan_loop.test.sh` (heavy cases may mock chat hooks via `scripts/asc/extend` test doubles)

**Consumes:** Tasks 1–5.

- [ ] **Step 1: CLI**

```text
make agent-plan plan:<path> prompt:<file>
make agent-plan plan:<path> < promptfile
```

Reject unsupported bare multiword prompt. Log `writer_isolation` / `reviewer_isolation` from host note / runtime detect.

- [ ] **Step 2: Loop per spec summary**

1. Validate path; stage; snapshot `live_before`.
2. `chat-new` writer — parse JSON; abort on `missing_result_json` / failed / empty.
3. Inventory; promote D0 or `live_changed`.
4. Build reviewer message: **task + expected response + path + digest + inlined bytes**.
5. `chat-new` reviewer; then **`decide-run` with `DECIDE_ROLE=decider`** (state = reviewer `reply_text`) — do not curl Ollaya from `plan.sh`.
6. `clean` → success if live digest matches; `issues` → writer reply / stall / promote D1 / re-review; `uncertain` → one more `decide-run` then `needs_human_review`; `invalid` → abort.
7. Max 8 rounds.

- [ ] **Step 3: Tests with mocked provider hooks** (extend-rung doubles for writer/reviewer/decider) for loop branches; optional live smoke `AGENT_PLAN_LIVE=1`.

- [ ] **Step 4: Document residual limits in orchestrator stderr banner once per run**

```text
limits: promotion race if lock ignored; weakened scan-time only; decider classifies review text only
```

---

### Task 7: Instance smoke + mother hygiene

**Files:** none on mother enable list.

- [ ] **Step 1: On a disposable instance**, enable `agent`, `asc/cursor`, `asc/codex`, `asc/ollaya` (not on mother).

- [ ] **Step 2: After syncing hooks, clear hook cache**

```bash
rm -f data/asc/cache/hook/*
```

- [ ] **Step 3: Run one success path and one forced failure** (`live_changed` or `stalled_draft` or decide `issues` then stall).

- [ ] **Step 4: Confirm mother `.asc_extensions_ignore` still disables these if that was the prior state; no accidental enable commit**

- [ ] **Step 5: Point design changelog Status / Open tasks at completed work only after human go-ahead to mark done**

---

## Spec coverage checklist

| Spec area | Task |
|-----------|------|
| §1 role select (chat + decide), conflict, opt-incs, bound source | 1, 5 |
| Hook cache after hook/extension changes | 1, 3, 4, 5, 7 |
| §2 / decide JSON I/O, null ids, `missing_result_json` | 1, 5, 6 |
| §3 path, staging, flock promotion, residual race | 2, 6 |
| §3 reviewer task + expected response + bytes | 6 |
| §4 / §4a isolation + inventory | 0, 2, 6 |
| §5 prompt file/stdin | 6 |
| §6 Ollaya via `asc/ollaya` `decider` + fixtures | 0, 5 |
| §7 uncertainty / rounds / stall | 6 |
| §8 acceptance / compatibility CHAT_TYPE, no pre/post | 1 |
| Cursor Auto / Codex High / Ollaya model | 0, 3, 4, 5 |
| No Claude / no mother enable (`asc/ollaya` included) | 7 + Global Constraints |

## Self-review notes

- Decider is a contrib extension (`asc/ollaya`), not an agent-core HTTP helper.
- Promotion not over-claimed: Global Constraints + Task 2/6 banners.
- Hook cache called out for chat and decide.

---

**Plan saved to** `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md` (ASC changelog location; overrides `docs/superpowers/plans/`).

**Execution options (when you authorize implementation):**

1. **Subagent-Driven** — fresh subagent per task, review between tasks  
2. **Inline Execution** — this session with executing-plans checkpoints  

Which approach, and do you authorize starting Task 0 (host feasibility only) now?
