# `make agent-plan` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement headless `make agent-plan` per the settled contracts in [10-agent-plan-cursor-codex-ollaya.md](./10-agent-plan-cursor-codex-ollaya.md): Cursor writer, Codex reviewer, Ollaya decider, staging/promotion, JSON harness I/O.

**Architecture:** Abstract `chat/new`, `chat/reply`, and `decide/run` call an **extended core `hook_ms` / role-pick API** (not a forked ranker in agent). Contrib: `cursor` (writer), `codex` (reviewer), `ollaya` (decider). `make agent-plan` owns staging, **sandbox profiles**, flock+recheck promotion, reviewer prompt assembly, and the loop; it calls harnesses and does not embed Ollaya HTTP.

**Tech Stack:** Bash 4 / ASC bootstrap, Make pivots, Cursor Agent CLI, Codex CLI, Ollaya API via `asc/ollaya`, shunit2 via `make test-core` + agent `test/core.hook.sh`, optional `bwrap` profiles for `enforced` isolation.

**Spec:** [10-agent-plan-cursor-codex-ollaya.md](./10-agent-plan-cursor-codex-ollaya.md) — contracts §1–§8 are normative.

**Authorization:** Not an implementation go-ahead by itself. Do not enable `agent` / `asc/cursor` / `asc/codex` / `asc/ollaya` on the mother by default. Mother `.asc_extensions_ignore` **must** list `asc/ollaya` whenever that contrib exists (already added preemptively; keep it). No Claude. No gates row unless asked. Commit only when asked.

## Global Constraints

- **Headless only** — no desktop composer injection.
- **Models** — Cursor **Auto**; Codex **GPT Terra 6.1 – High effort** (Task 0).
- **Roles** — `CHAT_ROLE` writer/reviewer; `DECIDE_ROLE` decider; file placement; no provider env config.
- **hook_ms contract** — extend core; harnesses call the extended pick; no duplicated `f_hook_ms_measure` in agent (design §1).
- **Promotion race** — flock + recheck + rename is not kernel CAS; unlocked editors can still race.
- **Weakened isolation** — scan-time docroot inventories only; temporary restores invisible; outside-docroot not claimed.
- **Enforced isolation** — harness subprocess runs inside a bwrap profile; ASC cache on staging-backed RW binds; cwd alone is insufficient; provider profiles verified only after Tasks 3–4 create+resume.
- **Ollaya / decider** — classifies review text only; `/v1/systemone`; truncation → `invalid`; body in `asc/ollaya`.
- **Hook cache** — clear `data/asc/cache/hook/*` keys after hook/extension changes in tests and smokes.
- **Includes** — unset `AGENT_HARNESS_INC_OK` before bootstrap; opt-inc sets it only on full success; on failure harness uses **inline** JSON abort (never `harness_result`).
- **ASC cache binds** — per-role staging-backed mounts; never reuse writer cache for reviewer/orchestrator.
- **Tests** — verified entry: enable `agent`, then `make test-core`; assert agent suite files ran (see Task 1). Never `make test-agent || fallback`.
- **Mother ignore** — `asc/ollaya` line required; instance ignore overrides can enable locally.
- **ASC authoring** — templates + anti-patterns; mother guard.

---

## File map

| Path | Responsibility |
|------|----------------|
| `asc/core/hook.manual-inc.sh` (modify) | Shared ranking helper; extended role-qualified pick used by harnesses; keep unconstrained `hook_ms` semantics |
| `asc/test/core/hook.test.sh` (modify) | Parity + role conflict / unqualified cases for the extended API |
| `asc/extensions/agent/agent/source_manual.manual-inc.sh` (new) | Defines `f_agent_source_manual` (override XOR original; preserves `.` exit status) |
| `asc/extensions/agent/chat/new.opt-inc.sh` (new) | **First-load** `source_manual` (inline map), then `f_agent_source_manual` for role_select + harness_result |
| `asc/extensions/agent/chat/reply.opt-inc.sh` (new) | Same first-load path as `new.opt-inc.sh` |
| `asc/extensions/agent/decide/run.opt-inc.sh` (new) | Same for decide |
| `asc/extensions/agent/agent/plan.opt-inc.sh` (new) | Same + stage + sandbox manuals |
| `asc/extensions/agent/agent/role_select.manual-inc.sh` (new) | Thin wrapper calling core pick; sets `CHAT_HOOK_SOURCE` / `DECIDE_HOOK_SOURCE` |
| `asc/extensions/agent/agent/harness_result.manual-inc.sh` (new) | JSON stdout emitter for chat + decide |
| `asc/extensions/agent/chat/new.sh`, `reply.sh` | Explicit `.` of manual-incs after bootstrap; extended pick; no pre/post |
| `asc/extensions/agent/chat/read.sh`, `archive.sh` | `CHAT_TYPE` rename only |
| `asc/extensions/agent/decide/run.sh` (new) | Same load route; `DECIDE_ROLE=decider` |
| `asc/extensions/agent/agent/plan.sh` (new) | Orchestrator |
| `asc/extensions/agent/agent/plan_stage.inc.sh` or `.manual-inc.sh` (new) | Path, stage, promote, inventory — **explicit** load from `plan.sh` |
| `asc/extensions/agent/agent/plan_sandbox.manual-inc.sh` (new) | Load/run writer & reviewer bwrap profiles; mode selection |
| `asc/extensions/agent/agent/sandbox/writer.bwrap.conf` (new) | Checked-in writer profile (paths parameterized) |
| `asc/extensions/agent/agent/sandbox/reviewer.bwrap.conf` (new) | Checked-in reviewer RO profile |
| `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh` | Cursor Auto create |
| `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh` | Cursor Auto resume |
| `scripts/asc/contrib/asc/codex/chat/new.reviewer.hook.sh` | Codex High create |
| `scripts/asc/contrib/asc/codex/chat/reply.reviewer.hook.sh` | Codex resume (no force) |
| `scripts/asc/contrib/asc/ollaya/decide/run.decider.hook.sh` (new) | Decide HTTP + class map |
| `.asc_extensions_ignore` (mother) | **Must contain** `asc/ollaya` (preemptively added; keep when committing contrib) |
| `asc/extensions/agent/test/core/*.test.sh` (new) | role_select, plan_stage, plan_sandbox, decide_ollaya, include_load |
| `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md` (new) | Host feasibility |

### Include loading route (required)

ASC auto-loads the **caller** `*.opt-inc.sh` after bootstrap ([bootstrap](../../../asc/bootstrap.sh)). That is the entry for helpers—not an extension-root include.

**Path map** (same rule as [`f_autoload_override`](../../../asc/core/autoload.manual-inc.sh)): `asc/foo` → `scripts/overrides/foo`.

**Break the cycle — two layers:**

1. **`source_manual.manual-inc.sh`** defines `f_agent_source_manual` only:

```bash
f_agent_source_manual() {
  local P="$1"
  local o="${P/asc/scripts/overrides}"
  [[ -f "$P" || -f "$o" ]] || return 1
  if [[ -f "$o" ]]; then
    # shellcheck source=/dev/null
    . "$o"
    return $?   # preserve failure — do NOT force 0
  fi
  # shellcheck source=/dev/null
  . "$P"
  return $?
}
```

2. **Each harness `*.opt-inc.sh`** (auto-loaded by bootstrap **without checking `$?`** — [bootstrap](../../../asc/bootstrap.sh) lines 117–128) performs the first load inline, then `f_agent_source_manual` for the rest. On any failure it must **not** set the success sentinel; on full success it sets `AGENT_HARNESS_INC_OK=1` (and clears `AGENT_HARNESS_INC_ERROR`).

```bash
# Example: asc/extensions/agent/chat/new.opt-inc.sh
AGENT_HARNESS_INC_OK=0
AGENT_HARNESS_INC_ERROR=''
_sm='asc/extensions/agent/agent/source_manual.manual-inc.sh'
_smo="${_sm/asc/scripts/overrides}"
if [[ -f "$_smo" ]]; then
  . "$_smo" || { AGENT_HARNESS_INC_ERROR='source_manual_override'; return 0; }
else
  . "$_sm" || { AGENT_HARNESS_INC_ERROR='source_manual'; return 0; }
fi
f_agent_source_manual 'asc/extensions/agent/agent/role_select.manual-inc.sh' \
  || { AGENT_HARNESS_INC_ERROR='role_select'; return 0; }
f_agent_source_manual 'asc/extensions/agent/agent/harness_result.manual-inc.sh' \
  || { AGENT_HARNESS_INC_ERROR='harness_result'; return 0; }
AGENT_HARNESS_INC_OK=1
```

(`return 0` here only ends the opt-inc; bootstrap ignores status. The sentinel carries failure.)

3. **Each harness action** (`new.sh` / `reply.sh` / `decide/run.sh`):

```bash
# BEFORE bootstrap — defeat inherited env masking a skipped/missing opt-inc
unset AGENT_HARNESS_INC_OK AGENT_HARNESS_INC_ERROR
# or: AGENT_HARNESS_INC_OK=0; AGENT_HARNESS_INC_ERROR=''

. asc/bootstrap.sh || exit 1

if [[ "${AGENT_HARNESS_INC_OK:-}" != 1 ]]; then
  # Independent minimal JSON — do NOT call harness_result / f_agent_* emitters
  # (source_manual, role_select, or harness_result may have failed to load).
  _detail="${AGENT_HARNESS_INC_ERROR:-unknown}"
  printf '{"ok":false,"error":"include_load_failed","detail":"%s"}\n' "$_detail"
  exit 1
fi
# provider / pick body only below this line
```

`agent/plan.sh` uses the same pre-bootstrap unset + sentinel; if it has no JSON contract yet, stderr + non-zero exit is enough for the orchestrator path.

| Caller action | Opt-inc loads after first-load |
|---------------|--------------------------------|
| `chat/new.sh` → `chat/new.opt-inc.sh` | role_select + harness_result |
| `chat/reply.sh` → `chat/reply.opt-inc.sh` | same |
| `decide/run.sh` → `decide/run.opt-inc.sh` | same |
| `agent/plan.sh` → `agent/plan.opt-inc.sh` | those two + stage + sandbox manuals |

**Tests (`include_load.test.sh`) — complete path in a fresh process:**

1. Happy path: harness defines select/emitter; `AGENT_HARNESS_INC_OK=1`.
2. Override `source_manual` with a marker; fresh process hits marker.
3. **Three failure points** (separate cases; each uses a failing override / bad path so that load aborts **before** later manuals):
   - `source_manual` fails
   - `role_select` fails
   - `harness_result` fails  
   For each: stdout is **valid JSON** `ok:false` / `error=include_load_failed` (optional `detail`), exit ≠ 0, body-only marker **absent**. Assert the abort path did **not** require a loaded `harness_result` emitter (e.g. stub harness with only the inline `printf`).
4. Inherited `AGENT_HARNESS_INC_OK=1` in the environment **before** the harness runs: harness still fails if opt-inc is skipped/missing (pre-bootstrap unset wins).
5. Successful override of `role_select` is sourced exactly once (not also the original).
---

### Sandbox handoff (required)

Chat harnesses are **subprocesses**. They do not inherit functions from `plan.sh`.

**Wrap the harness cmdline:**

```bash
f_plan_sandbox_run writer -- env CHAT_ROLE=writer … asc/extensions/agent/chat/new.sh …
f_plan_sandbox_run reviewer -- env CHAT_ROLE=reviewer … asc/extensions/agent/chat/reply.sh …
```

**Writable ASC generated state (exception + trust — design §4):**  
Bootstrap / `hook_ms` may write under `data/asc/cache` ([bootstrap](../../../asc/bootstrap.sh), [hook.manual-inc.sh](../../../asc/core/hook.manual-inc.sh)). A fully RO docroot breaks that.

Clarify the exception: inside the sandbox, `$PROJECT_DOCROOT/data/asc/cache` is **mounted RW**, so it *appears* as a writable docroot path; the **backing store** is `$STAGING/asc-state/<role>/cache` (outside the live tree). That does **not** make the live host `data/asc/cache` writable to the provider.

v1 profile **must**:

1. Keep live project tree RO except enumerated auth binds and these **staging-backed** ASC state mounts.
2. Use a **separate backing directory per role** (`writer`, `reviewer`); orchestrator/`decide-run` uses host-native or `orchestrator` backing — **never** the writer’s.
3. **Lifetime:** empty (cold) or **orchestrator-prepared pristine seed** (warm) at the start of each wrapped turn; discard/quarantine after the turn; never copy provider-backed cache into live docroot cache.
4. **Cold test:** empty role backing; wrapped harness bootstrap succeeds; new cache bytes land only in that backing dir.
5. **Warm test:** seed from orchestrator-controlled pristine copy only (not from a prior writer turn).
6. **Poison test:** writer double writes a marker into its bound cache; following reviewer wrap and orchestrator process must **not** see that marker when sourcing cache.

Hooks remain sandbox-unaware. Bare `make chat-new` without the wrapper is not `enforced`.

**Task split for verification:** Task 2b uses **doubles** (including poison/non-reuse); Tasks 3–4 require authenticated **create and resume** before a profile is marked verified.
---

### Task 0: Host feasibility + sandbox profile draft

**Normative:** design §4, §6 (models/threshold), Decisions table.

**Files:**
- Create: `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md`
- Draft: `asc/extensions/agent/agent/sandbox/writer.bwrap.conf`, `reviewer.bwrap.conf`

**Produces:** Cursor Auto flags; Codex Terra 6.1 High flags; Ollaya model id; threshold keep/revise; isolation mode; **enumerated RW auth binds**; create/resume smoke notes under draft profile if attempted.

- [ ] **Step 1: Cursor** — `command -v agent`; `agent about`; `agent create-chat`; one `-p` turn with **Auto** (no foreign `--model`); record resume flag and whether `--force` is required for writes ([design](./10-agent-plan-cursor-codex-ollaya.md) Decisions / Cursor model).

- [ ] **Step 2: Codex** — install if needed; record create/resume and **GPT Terra 6.1 – High** selection; confirm how to omit auto-write/`--force`/`--yolo`.

- [ ] **Step 3: Ollaya** — `ollaya` / `127.0.0.1:11435`; one `/v1/systemone` decide with `plan_ready` questions (design §6); record `confidence` on clean vs issues samples; keep or revise 0.75.

- [ ] **Step 4: Sandbox probe** — `bwrap`; draft profiles with RO docroot + **RW binds for `data/asc/cache` (and other cold-start write paths)** onto staging-backed dirs; prove forbidden docroot write fails; list every RW bind (auth + ASC state); note cold vs warm bootstrap under the draft; optional early auth probe (final verify waits for Tasks 3–4).

- [ ] **Step 5: Write host note** with all of the above.

- [ ] **Step 6: Stop** if Auto, Terra High, or Ollaya decide is unreachable.
---

### Task 1: Extend core `hook_ms` + harness load route + verified tests

**Files:**
- Modify: `asc/core/hook.manual-inc.sh`
- Modify: `asc/test/core/hook.test.sh`
- Create: `asc/extensions/agent/agent/source_manual.manual-inc.sh`
- Create: `asc/extensions/agent/agent/role_select.manual-inc.sh`
- Create: `asc/extensions/agent/agent/harness_result.manual-inc.sh`
- Create: `asc/extensions/agent/chat/new.opt-inc.sh`, `chat/reply.opt-inc.sh`
- Create: `asc/extensions/agent/test/core/include_load.test.sh`
- Create: `asc/extensions/agent/test/core/role_select.test.sh`
- Modify: `chat/new.sh`, `reply.sh`, `read.sh`, `archive.sh`

**Verified test entry (do not use `make test-agent`):**

1. Ensure **`agent` is not ignored** on the test instance (mother may keep it ignored—use a disposable instance or temporarily enable for the test run only).
2. Run:

```bash
. asc/bootstrap.sh
make test-core
```

3. Assert discovery: `f_test_batch_exec` path for agent is exercised. Concrete check in `include_load.test.sh` / CI step:

```bash
# After make test-core, or inside a meta-test:
grep -E 'role_select|include_load|hook' data/logs/...   # prefer: shunit2 counts
# Hard requirement: fail the task if agent test/*.test.sh files are zero-executed.
# Implement: agent test/core.hook.sh already batches asc/extensions/agent/test/core
# Confirm new files appear in that directory and make test-core output lists them
# (or run: ASC_TEST_FILTER=role_select make test-core if such a filter exists;
#  otherwise run f_test_batch_exec 'asc/extensions/agent/test/core' directly and
#  assert non-zero testsRan from shunit2).
```

Never: `make test-agent || asc/extensions/agent/test/core.sh` (unknown Make targets can succeed; that fallback path does not exist).

- [ ] **Step 1: Failing tests** — core parity/role/conflict; cache stale/clear; `include_load` happy + three fail points (`source_manual` / `role_select` / `harness_result`) with **inline** JSON abort (no emitter); inherited sentinel masked; body marker absent.

- [ ] **Step 2: `make test-core` with agent enabled — expect FAIL**; confirm new test files appear in the run/summary.

- [ ] **Step 3: Implement** core extended pick; `source_manual.manual-inc.sh`; `role_select` / `harness_result`; opt-incs with sentinel; first-load sequence.

- [ ] **Step 4: Slim `new.sh` / `reply.sh`** — **unset sentinel before bootstrap**; after bootstrap require `AGENT_HARNESS_INC_OK=1` else **inline** JSON `include_load_failed` + `exit 1` (no `harness_result` call); drop pre/post; `CHAT_TYPE` on read/archive.

- [ ] **Step 5: `make test-core` PASS; assert intended cases ran (three include-fail points + inherited-sentinel)**

- [ ] **Step 6: Commit only if asked**
---

### Task 2: Staging, path validation, promotion, inventory

**Normative:** design §3, §4a.

**Files:**
- Create: `asc/extensions/agent/agent/plan_stage.manual-inc.sh`
- Create: `asc/extensions/agent/test/core/plan_stage.test.sh`

- [ ] **Step 1: Failing tests** — path escape / live symlink / missing parent; create-from-absent; `live_changed` when live edited during simulated writer turn; flock second promoter; `stalled_draft` identical digest after issues; weakened inventory: ignored-file change, add/delete, symlink, unreadable, `inventory_error`; document residual unlocked promotion race.

- [ ] **Step 2: Implement** validate, stage, `live_before`, flock+recheck+rename, inventories.

- [ ] **Step 3: Load only via `f_agent_source_manual` from `plan.sh` and from tests** (same override rules).

- [ ] **Step 4: `make test-core` (agent enabled) — PASS; cases discovered**

---

### Task 2b: Enforced sandbox profiles (required for claiming `enforced`)

**Normative:** design §4 (narrow reviewer claim + handoff).

**Files:**
- Create: `asc/extensions/agent/agent/plan_sandbox.manual-inc.sh`
- Create: `asc/extensions/agent/agent/sandbox/writer.bwrap.conf`
- Create: `asc/extensions/agent/agent/sandbox/reviewer.bwrap.conf`
- Create: `asc/extensions/agent/test/core/plan_sandbox.test.sh`

**Produces:** `f_plan_sandbox_run writer|reviewer -- <cmdline…>`; fails closed if `enforced` requested but profile cannot run.

- [ ] **Step 1: Failing tests (doubles only — no Cursor/Codex contrib dependency)**

1. Writer profile: forbidden docroot write fails; staging plan RW works.
2. Reviewer profile: write to docroot fails; write to staging plan path fails.
3. ASC state binds: cold (empty per-role backing) and warm (orchestrator pristine seed) wrapped harness bootstrap succeed; live docroot cache unchanged.
4. Poison: writer-backed cache marker must not appear in reviewer bind or orchestrator-sourced cache.
5. Listed auth RW binds allow writes; unlisted paths do not.
6. Hostile **double** via wrapped `chat/new.sh` writing `PROJECT_DOCROOT/evil` leaves no file.
7. `bwrap` missing → `enforced` errors; `weakened` OK; cwd-only ≠ `enforced`.
8. Do **not** mark profiles “verified for providers” until Tasks 3–4.

- [ ] **Step 2: Implement profiles + runner** (docroot, staging, ASC state binds, auth binds from host note).

- [ ] **Step 3: `make test-core` PASS; cases discovered**

- [ ] **Step 4: Document handoff + state binds** in `plan_sandbox.manual-inc.sh` header.

---

### Task 3: Cursor writer hooks

**Normative:** design Decisions (Cursor Auto); §2 JSON; §4 writer; Sandbox handoff above.

**Files:**
- Create: `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh`
- Create: `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh`

- [ ] **Step 1: Implement** create-chat + Auto `-p` / resume per host note; `--force` only if host note requires it for staging writes; emit JSON via harness emitter vars/contract.

- [ ] **Step 2: Clear** `data/asc/cache/hook/*` after adding files; enable `asc/cursor` on test instance.

- [ ] **Step 3: Acceptance (real hooks; required before writer profile = verified)**  
  - `f_plan_sandbox_run writer -- …/chat/new.sh …` → JSON `ok:true`, non-null session ids (**create**).  
  - Same session **resume** via wrapped `chat/reply.sh` → `ok:true`.  
  - Staging plan updates; cold + warm ASC cache binds still hold.  
  - Hostile double still blocked for docroot writes when wrapped.

- [ ] **Step 4: Update host note** — writer profile verified only after Step 3 passes.

- [ ] **Step 5: Tests/smoke PASS**
---

### Task 4: Codex reviewer hooks

**Normative:** design Decisions (Codex Terra 6.1 High); §2; §3 reviewer message consumed as prompt input; §4 narrow reviewer claim; Sandbox handoff.

**Files:**
- Create: `scripts/asc/contrib/asc/codex/chat/new.reviewer.hook.sh`
- Create: `scripts/asc/contrib/asc/codex/chat/reply.reviewer.hook.sh`

- [ ] **Step 1: Implement** create/resume with High effort; **no** `--force`/`--yolo`/auto-write; do not strip inlined plan bytes from the prompt.

- [ ] **Step 2: Clear hook cache; enable `asc/codex` on test instance**

- [ ] **Step 3: Acceptance (real hooks; required before reviewer profile = verified)**  
  - Wrapped **create** + **resume** (two harness invocations) with authenticated Codex under the reviewer profile.  
  - JSON contract; docroot/staging writes blocked; enumerated auth RW binds only.  
  - Cold + warm ASC cache binds still hold for the wrapped harness.

- [ ] **Step 4: Update host note** — reviewer profile verified only after Step 3 passes.

- [ ] **Step 5: Tests/smoke PASS**
---

### Task 5: Abstract `decide-run` + `scripts/asc/contrib/asc/ollaya`

**Normative:** design §1 (decide role), §6 (full Ollaya contract), Boundaries (mother ignore).

**Files:**
- Create: `asc/extensions/agent/decide/run.sh`
- Create: `scripts/asc/contrib/asc/ollaya/decide/run.decider.hook.sh`
- Create: fixtures under `asc/extensions/agent/test/core/fixtures/ollaya_plan_ready/`
- Create: `asc/extensions/agent/test/core/decide_ollaya.test.sh`
- Optional short: `scripts/asc/contrib/asc/ollaya/README.md`

- [ ] **Step 0:** `grep -qx 'asc/ollaya' .asc_extensions_ignore` or add the line in the same change set as the first ollaya file. README: instance ignore may omit the line to enable.

- [ ] **Step 1: Fixtures** per design §6 table (clean, issues, caveats, negation, mixed, empty, garbage, `422`/`state_truncated`).

- [ ] **Step 2: Failing tests** — role select for `run.decider.hook.sh`; cache clear after add; classify fixtures → classes; malformed confidence → `invalid`.

- [ ] **Step 3: `decide/run.opt-inc.sh` + `decide/run.sh`** — same first-load path as chat opt-incs; extended pick `DECIDE_ROLE=decider`; pass reviewer `reply_text` as state (document arg/file/stdin in header).

- [ ] **Step 4: `run.decider.hook.sh`** — `POST /v1/systemone` with §6 questions; map to `class`; emit decide JSON schema from §6.

- [ ] **Step 5: Live + mocked truncation; clear decide hook cache keys**

- [ ] **Step 6: If threshold changes, edit design §6 in the same authorized change**

- [ ] **Step 7: Hygiene** — `grep -qx 'asc/ollaya' .asc_extensions_ignore` must pass.

---

### Task 6: `make agent-plan` orchestrator

**Normative:** design loop summary; §3–§7; Sandbox handoff; Include loading route.

**Files:**
- Create: `asc/extensions/agent/agent/plan.sh`
- Create: `asc/extensions/agent/test/core/plan_loop.test.sh`

- [ ] **Step 1: Rely on `agent/plan.opt-inc.sh`** for first-load + manuals (stage, sandbox, select, result); `plan.sh` only bootstraps and runs the loop.

- [ ] **Step 2: CLI** — `plan:<path>` + `prompt:<file>` or stdin (design §5); reject bare multiword Make prompts.

- [ ] **Step 3: Loop**
  1. Validate + stage; `live_before`.
  2. `f_plan_sandbox_run writer -- <chat-new writer…>`; parse JSON; abort on `missing_result_json` / failed / empty.
  3. Inventory; promote or `live_changed`.
  4. Build reviewer message (task + expected response + path + digest + inlined bytes) — design §3.
  5. `f_plan_sandbox_run reviewer -- <chat-new/reply reviewer…>`.
  6. `decide-run` with `DECIDE_ROLE=decider` (no Ollaya curl in `plan.sh`).
  7. Branch on `class` per §7; max 8 rounds.

- [ ] **Step 4: Log** isolation mode; print `enforced` for a role only if that role’s profile was verified in Task 3 (writer) / Task 4 (reviewer), not merely after 2b doubles.

- [ ] **Step 5: Banner once:** promotion race if lock ignored; weakened scan-time only; decider classifies review text only; enforced reviewer claim is docroot+staging except listed auth RW binds; ASC cache lives on staging-backed binds.

- [ ] **Step 6: Tests** with extend doubles for writer/reviewer/decider; optional `AGENT_PLAN_LIVE=1`.
---

### Task 7: Instance smoke + mother hygiene

- [ ] Enable on **disposable instance**: `agent`, `asc/cursor`, `asc/codex`, `asc/ollaya` (remove those lines from **instance** ignore only).

- [ ] `rm -f data/asc/cache/hook/*`

- [ ] Success + failure path.

- [ ] **Mother checks (must all pass):**

```bash
grep -qx 'asc/ollaya' .asc_extensions_ignore
grep -qx 'asc/cursor' .asc_extensions_ignore   # still disabled on mother if that was prior policy
grep -qx 'asc/codex' .asc_extensions_ignore
# agent line still present if mother keeps agent disabled
test -d scripts/asc/contrib/asc/ollaya
# No commit that deletes asc/ollaya from mother ignore while adding the contrib
```

- [ ] Do not treat “extensions dir exists” as enabled.

---

## Spec coverage checklist

| Spec / gap | Task |
|------------|------|
| §1 extended `hook_ms` + parity | 1 |
| Include load + harness abort sentinel / JSON | 1, 5 |
| Per-role ASC cache non-reuse / poison | 2b, 6 |
| Verified `make test-core` + discovery assert | 1, 2, 2b, 5 |
| §3 staging / promotion | 2 |
| §4 sandbox doubles + cold/warm ASC state binds | 0, 2b |
| §4 provider create+resume before profile verified | 3, 4 |
| Sandbox wraps chat harness subprocess | 2b, 3, 4, 6 |
| §6 ollaya contrib + ignore line | 5, 7 |
| Mother `asc/ollaya` ignore | 5 Step 0, 7 (preemptive line already in tree) |
| Loop + limits banner | 6 |
| Hook cache | 1, 3, 4, 5, 7 |
| Override via `scripts/overrides/…` + `f_agent_source_manual` | Include route, 1 |

## Self-review notes

- P1 include abort: pre-bootstrap unset; sentinel; **inline** JSON (independent of `harness_result`); tests for `source_manual` / `role_select` / `harness_result` fails + inherited sentinel + body not run.
- P1 cache mount: staging-backed per-role exception; poison non-reuse across writer → reviewer/orchestrator; cold/warm with pristine seeds only.
- P1 sandbox visibility: wrap harness cmdline; 2b = doubles; 3–4 = authenticated create **and** resume before profile verified.
- P1 reviewer claim: docroot+staging; auth RW exceptions enumerated.
- Mother ignore + `make test-core` discovery asserts retained.

---

**Plan saved to** `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md`.

**Also done now:** added `asc/ollaya` to mother [`.asc_extensions_ignore`](../../../.asc_extensions_ignore).

**Execution options (when you authorize implementation):**

1. **Subagent-Driven** (recommended)  
2. **Inline Execution**

Which approach, and may Task 0 start?
