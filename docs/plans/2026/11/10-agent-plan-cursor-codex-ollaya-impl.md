# `make agent-plan` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement headless `make agent-plan` per the settled contracts in [10-agent-plan-cursor-codex-ollaya.md](../../../ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md): Cursor writer, Codex reviewer, single public `plan-is 'ready'`, staging/promotion, JSON action I/O.

**Architecture:** Plain `chat/new`, `chat/reply`, and `plan/is` call existing **`hook_ms` with variants** and encode JSON locally. Contrib: `cursor` (writer), `codex` (reviewer); optional `ollaya` for `is.ready` only. `make agent-plan` owns staging, sandbox, promotion, **brief+needs reviewer assembly**, structured review parsing, and the loop. Defer `review/is` and `plan/needs`.

**Tech Stack:** Bash 4 / ASC bootstrap, Make pivots, Cursor Agent CLI, Codex CLI, Ollaya API via `asc/ollaya`, shunit2 via `make test-core` + agent `test/core.hook.sh`, optional `bwrap` profiles for `enforced` isolation.

**Spec:** [10-agent-plan-cursor-codex-ollaya.md](../../../ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md) — contracts §1–§8 are normative.

**Authorization:** Not an implementation go-ahead by itself. Do not enable `agent` / `asc/cursor` / `asc/codex` / `asc/ollaya` on the mother by default. Mother `.asc_extensions_ignore` **must** list `asc/ollaya` whenever that contrib exists (already added preemptively; keep it). No Claude. No gates row unless asked. Commit only when asked.

**2026-11-13 archive addition:** The [chat spec](../../../specs/asc/agent-chats.md) proposes a human-readable Markdown archive for each ASC-handled conversation. Its association, failure and sandbox handoff contracts are not yet settled; resolve the archive design gate below before implementing the chat actions or the live archive path.

The [local action records idea](../../../ideas/2026/11/13-local-action-records.md) places that archive alongside, but separate from, wrapper logs and thread state.

## Global Constraints

- **Headless only** — no desktop composer injection.
- **Models** — Cursor **Auto**; Codex **GPT Terra 6.1 – High effort** (Task 0).
- **Roles / predicates** — `CHAT_ROLE` writer/reviewer; only public predicate `plan-is 'ready'`; file placement; no provider env config.
- **hook_ms contract** — use existing `hook_ms` and variants, including normal fallback and ranking; do not modify core or duplicate ranking (design §1).
- **Minimality (no loader tower)** — do **not** create harness `*.opt-inc.sh`, `f_agent_source_manual`, include success sentinels, or thin `f_agent_*` wrappers that only forward to core. Handle small I/O contracts **in the action**. Extract a `manual-inc` / function **only** when it encapsulates substantial behavior that would otherwise make the calling script hard to follow (staging/promotion and sandbox profiles are the expected cases). Do not expand the file map for hypothetical sharing—extract when duplication or opacity becomes real.
- **Promotion race** — flock + recheck + rename is not kernel CAS; unlocked editors can still race.
- **Weakened isolation** — scan-time docroot inventories only; temporary restores invisible; outside-docroot not claimed.
- **Enforced isolation** — harness subprocess runs inside a bwrap profile; ASC cache on staging-backed RW binds; cwd alone is insufficient; provider profiles verified only after Tasks 3–4 create+resume.
- **Readiness** — start-readiness for `named_step:` (Make nested quotes `named_step:"'Task 0'"`); **`required_prerequisites`** authoritative via CLI file or plan `asc-prerequisites` block—**never** silent `[]` when unestablished; `review.named_step` must match. Default deterministic `is.ready.hook.sh`. Authorization remains NEXT_STEPS/gates.
- **Hook cache** — clear `data/asc/cache/hook/*` keys after hook/extension changes in tests and smokes.
- **ASC cache binds** — per-role staging-backed mounts; never reuse writer cache for reviewer/orchestrator.
- **Tests** — verified entry: enable `agent`, then `make test-core`; assert agent suite files ran (see Task 1). Never `make test-agent || fallback`.
- **Mother ignore** — `asc/ollaya` line required; instance ignore overrides can enable locally.
- **ASC authoring** — templates + anti-patterns; mother guard.

---

## File map

| Path | Responsibility |
|------|----------------|
| `asc/extensions/agent/chat/new.sh`, `reply.sh` | Plain actions: bootstrap → require role → `hook_ms` with role variant (**sources hook**) → encode JSON locally |
| `asc/extensions/agent/chat/read.sh`, `archive.sh` | `CHAT_TYPE` rename only |
| `asc/extensions/agent/plan/is.sh` (new) | Plain action: require evidence package; pick `is.ready` |
| `asc/extensions/agent/plan/is.ready.hook.sh` (new) | **Default** deterministic merge (schema, digest, prereqs) → yes/no/unknown + reason |
| `asc/extensions/agent/agent/plan.sh` (new) | Orchestrator loop |
| `asc/extensions/agent/agent/plan_stage.manual-inc.sh` (new, **if needed**) | Path, stage, promote, inventory — **explicit** `.` from `plan.sh` only when inlining would obscure the loop |
| `asc/extensions/agent/agent/plan_sandbox.manual-inc.sh` (new, **if needed**) | Load/run writer & reviewer bwrap profiles; mode selection — same rule |
| `asc/extensions/agent/agent/sandbox/writer.bwrap.conf` (new) | Checked-in writer profile (paths parameterized) |
| `asc/extensions/agent/agent/sandbox/reviewer.bwrap.conf` (new) | Checked-in reviewer RO profile |
| `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh` | Cursor Auto create |
| `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh` | Cursor Auto resume |
| `scripts/asc/contrib/asc/codex/chat/new.reviewer.hook.sh` | Codex High create |
| `scripts/asc/contrib/asc/codex/chat/reply.reviewer.hook.sh` | Codex resume (no force) |
| `scripts/asc/contrib/asc/ollaya/…` | **Not** required for v1; mother ignore stays |
| `.asc_extensions_ignore` (mother) | **Must contain** `asc/ollaya` (preemptively added; keep when committing contrib) |
| `asc/extensions/agent/test/core/*.test.sh` (new) | hook/role + plan_stage, plan_sandbox, plan_is (schema/digest/prereq/outcome), plan_loop |
| `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-host.md` (new) | Host feasibility |

**Do not create:** loader/sentinel machinery; **`review/is.sh`**; **`plan/needs.sh`**; `review/is.clean.hook.sh`.

### Plain action shape (required)

```bash
# chat/new.sh (reply / plan-is analogous)
. asc/bootstrap.sh || exit 1
# require CHAT_ROLE ∈ writer|reviewer; on fail → JSON-encode failure + exit 1
# call hook_ms with subject=chat, action=new, -v CHAT_ROLE
#   → hook_ms sources the selected hook once; do NOT `.` it again
# if most_specific_match is empty → JSON-encode failure + exit 1
# map provider outcome → one stdout JSON object via jq (or equivalent encoder)
#   — never raw printf interpolation of prompt/reply_text
```

**Single-source rule:** `hook_ms` owns `.` of the hook (design §1). A marker-hook test must assert **exactly one** invocation per successful action run.

**JSON encoding:** use `jq -n --arg …` (or another real encoder). Raw `printf '{"prompt":"%s"}'` is forbidden for string fields.

Shared helpers appear **only** when Cursor/Codex/Ollaya/bwrap work still leaves substantial ASC logic (staging, sandbox runner). Providers stay in contrib hooks; orchestration stays in `plan.sh`.

---

### Sandbox handoff (required)

Chat actions are **subprocesses**. They do not inherit functions from `plan.sh`.

**Wrap the action cmdline:**

```bash
f_plan_sandbox_run writer -- env CHAT_ROLE=writer … asc/extensions/agent/chat/new.sh …
f_plan_sandbox_run reviewer -- env CHAT_ROLE=reviewer … asc/extensions/agent/chat/reply.sh …
```

**Writable ASC generated state (exception + trust — design §4):**  
Bootstrap / `hook_ms` may write under `data/asc/cache` ([bootstrap](../../../../asc/bootstrap.sh), [hook.manual-inc.sh](../../../../asc/core/hook.manual-inc.sh)). A fully RO docroot breaks that.

Clarify the exception: inside the sandbox, `$PROJECT_DOCROOT/data/asc/cache` is **mounted RW**, so it *appears* as a writable docroot path; the **backing store** is `$STAGING/asc-state/<role>/cache` (outside the live tree). That does **not** make the live host `data/asc/cache` writable to the provider.

v1 profile **must**:

1. Keep live project tree RO except enumerated auth binds and these **staging-backed** ASC state mounts.
2. Use a **separate backing directory per role** (`writer`, `reviewer`); orchestrator / `plan-is` use host-native or `orchestrator` backing — **never** the writer’s.
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

- [ ] **Step 1: Cursor** — `command -v agent`; `agent about`; `agent create-chat`; one `-p` turn with **Auto** (no foreign `--model`); record resume flag and whether `--force` is required for writes ([design](../../../ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md) Decisions / Cursor model).

- [ ] **Step 2: Codex** — install if needed; record create/resume and **GPT Terra 6.1 – High** selection; confirm how to omit auto-write/`--force`/`--yolo`.

- [ ] **Step 3: Readiness path** — confirm v1 uses deterministic `plan/is.ready.hook.sh`; structured Codex review JSON is the judgment source; Ollaya not on the critical path.

- [ ] **Step 4: Sandbox probe** — `bwrap`; draft profiles with RO docroot + **RW binds for `data/asc/cache` (and other cold-start write paths)** onto staging-backed dirs; prove forbidden docroot write fails; list every RW bind (auth + ASC state); note cold vs warm bootstrap under the draft; optional early auth probe (final verify waits for Tasks 3–4).

- [ ] **Step 5: Write host note** with all of the above.

- [ ] **Step 6: Stop** if Auto or Terra High is unreachable.
---

### Archive design gate (before Task 1 implementation)

- [ ] Specify subject input, filename-safe naming, collision handling, archive path in the action result, and how a later `chat-reply` identifies the same archive and provider session.
- [ ] Specify ordered prompt/reply recording, concurrent replies, partial provider or archive failures, and recovery without blindly re-sending a possibly delivered turn. Preserve JSON stdout and make archive failures visible.
- [ ] Specify an outside-sandbox handoff for `agent-plan`, keeping the live archive unwritable by the sandboxed provider and preserving the reviewer isolation claim. Define how direct chat calls and orchestrated calls each produce one archive without duplication.
- [ ] Plan instance-local exclusion from version control for `data/agent/chats/` and tests for distinct same-second chats, ordered create/reply across invocations, incomplete turns, write failure, and the sandbox boundary. Do not treat the archive as a complete product transcript.

### Task 1: Plain chat actions using `hook_ms` variants + verified tests

**Files:**
- Modify: `chat/new.sh`, `reply.sh`, `read.sh`, `archive.sh`
- Create (only if a real shared need appears later — **not** in this task): none of the removed loader files

**Verified test entry (do not use `make test-agent`):**

1. Ensure **`agent` is not ignored** on the test instance (mother may keep it ignored—use a disposable instance or temporarily enable for the test run only).
2. Run:

```bash
. asc/bootstrap.sh
make test-core
```

3. Assert discovery: `f_test_batch_exec` path for agent is exercised. Concrete check:

```bash
# Hard requirement: fail the task if agent test/*.test.sh files are zero-executed.
# agent test/core.hook.sh already batches asc/extensions/agent/test/core
# Confirm new files appear in that directory and make test-core output lists them
# (or run f_test_batch_exec 'asc/extensions/agent/test/core' directly and
#  assert non-zero testsRan from shunit2).
```

Never: `make test-agent || asc/extensions/agent/test/core.sh` (unknown Make targets can succeed; that fallback path does not exist).

- [ ] **Step 1: Failing tests** — writer/reviewer variant selection, unqualified fallback, rung precedence and normal tie handling; chat action: missing role / missing hook → valid JSON + non-zero exit + no provider body; **marker hook count == 1** on success (fails if action re-sources); JSON with quotes/newlines in `prompt`/`reply_text` round-trips; cache stale/clear after hook/extension fixture changes.

- [ ] **Step 2: `make test-core` with agent enabled — expect FAIL**; confirm intended test files appear in the run/summary.

- [ ] **Step 3: Implement** `new.sh` / `reply.sh` as plain actions using `hook_ms` with `-v CHAT_ROLE` (no second `.`; detect an empty `most_specific_match`; encode JSON with `jq` or equivalent); implement the archive contract once the design gate is resolved; `CHAT_TYPE` on read/archive. Keep core unchanged.

- [ ] **Step 4: Refuse loader creep** — confirm no new harness `*.opt-inc.sh`, `source_manual`, `role_select`, `harness_result`, or sentinel landed in this task.

- [ ] **Step 5: `make test-core` PASS; assert intended cases ran (single-source marker + JSON encode)**

- [ ] **Step 6: Commit only if asked**
---

### Task 2: Staging, path validation, promotion, inventory

**Normative:** design §3, §4a.

**Files:**
- Create: `asc/extensions/agent/agent/plan_stage.manual-inc.sh` **when** validate/stage/promote/inventory would make `plan.sh` hard to follow; otherwise keep logic in `plan.sh` until that threshold is clear.
- Create: `asc/extensions/agent/test/core/plan_stage.test.sh`

- [ ] **Step 1: Failing tests** — path escape / live symlink / missing parent; create-from-absent; `live_changed` when live edited during simulated writer turn; flock second promoter; `stalled_draft` identical digest after issues; weakened inventory: ignored-file change, add/delete, symlink, unreadable, `inventory_error`; document residual unlocked promotion race.

- [ ] **Step 2: Implement** validate, stage, `live_before`, flock+recheck+rename, inventories.

- [ ] **Step 3: Load only via explicit `.` from `plan.sh` / tests** if extracted—no opt-inc, no custom loader.

- [ ] **Step 4: `make test-core` (agent enabled) — PASS; cases discovered**

---

### Task 2b: Enforced sandbox profiles (required for claiming `enforced`)

**Normative:** design §4 (narrow reviewer claim + handoff).

**Files:**
- Create: `asc/extensions/agent/agent/plan_sandbox.manual-inc.sh` **when** profile selection + wrap cmdline is substantial; else keep in `plan.sh` until needed.
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

- [ ] **Step 4: Document handoff + state binds** next to the runner (header comment).

---

### Task 3: Cursor writer hooks

**Normative:** design Decisions (Cursor Auto); §2 JSON; §4 writer; Sandbox handoff above.

**Files:**
- Create: `scripts/asc/contrib/asc/cursor/chat/new.writer.hook.sh`
- Create: `scripts/asc/contrib/asc/cursor/chat/reply.writer.hook.sh`

- [ ] **Step 1: Implement** create-chat + Auto `-p` / resume per host note; `--force` only if host note requires it for staging writes; instruct the writer to keep **declared needs** (acceptance criteria, prerequisites, open decisions) in the plan; leave JSON assembly to the plain chat action.

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

- [ ] **Step 1: Implement** create/resume with High effort; **no** `--force`/`--yolo`/auto-write; do not strip inlined **brief, needs, or plan bytes** from the prompt; emit structured verdict (blocking vs optional).

- [ ] **Step 2: Clear hook cache; enable `asc/codex` on test instance**

- [ ] **Step 3: Acceptance (real hooks; required before reviewer profile = verified)**  
  - Wrapped **create** + **resume** (two harness invocations) with authenticated Codex under the reviewer profile.  
  - JSON contract; docroot/staging writes blocked; enumerated auth RW binds only.  
  - Cold + warm ASC cache binds still hold for the wrapped harness.

- [ ] **Step 4: Update host note** — reviewer profile verified only after Step 3 passes.

- [ ] **Step 5: Tests/smoke PASS**
---

### Task 5: `plan-is 'ready'` + default deterministic hook

**Normative:** design §6 (named-step readiness, review schema, evidence interface, default hook).

**Files:**
- Create: `asc/extensions/agent/plan/is.sh`
- Create: `asc/extensions/agent/plan/is.ready.hook.sh` (**default**, deterministic)
- Create: fixtures under `asc/extensions/agent/test/core/fixtures/plan_is_ready/`
- Create: `asc/extensions/agent/test/core/plan_is.test.sh`

**Do not create (v1):** `review/is.sh`, `plan/needs.sh`, ollaya `is.ready` unless explicitly authorized later.

- [ ] **Step 1: Fixtures** — valid yes (established list all `pass`); established `[]` + empty `checks` → yes when review ok; **unestablished list → unknown** (not silent `[]`); non-empty list + empty `checks` → unknown; id absent → unknown; prereq fail → no; digest / **`named_step` mismatch** / contradiction / malformed → unknown.

- [ ] **Step 2: Failing tests** — evidence inputs; answer ∈ yes/no/unknown with reason; unknown≠yes.

- [ ] **Step 3: Implement** `plan/is.sh` using `hook_ms` with a `ready` variant, plus deterministic `is.ready.hook.sh` per design §6. Test variant selection, normal fallback and missing hook. No LLM in this task.

- [ ] **Step 4: `make test-core` PASS** with agent enabled; cases discovered.

- [ ] **Step 5: Commit only if asked**

### Task 6: `make agent-plan` orchestrator

**Normative:** design loop summary; §3–§7; Sandbox handoff; design §1 minimality; §6 predicates.

**Files:**
- Create: `asc/extensions/agent/agent/plan.sh`
- Create: `asc/extensions/agent/test/core/plan_loop.test.sh`

- [ ] **Step 1: Keep `plan.sh` readable** — bootstrap + loop in the action; explicit `.` of `plan_stage` / `plan_sandbox` **only if** those files exist because the logic is substantial. No `plan.opt-inc.sh`.

- [ ] **Step 2: CLI** — `plan:` + `prompt:` / stdin + **`named_step:"'…'"`** (design §5 nested quoting); optional `required_prerequisites:<file>`; reject missing `named_step:`; reject bare multiword Make prompts. **E2E test:** `make agent-plan … named_step:"'Task 0'"` delivers `Task 0` intact.

- [ ] **Step 3: Loop**
  1. Validate + stage; `live_before`.
  2. `f_plan_sandbox_run writer -- <chat-new writer…>`; parse JSON; abort on `missing_result_json` / failed / empty.
  3. Inventory; promote or `live_changed`.
  4. Build reviewer message (brief + needs/criteria + path + digest + plan bytes) — design §3.
  5. `f_plan_sandbox_run reviewer -- <chat-new/reply reviewer…>`.
  6. Parse structured review JSON (§6 schema); malformed/contradiction/digest mismatch → pause.
  7. Establish `required_prerequisites` (CLI file else plan `asc-prerequisites` block); if unestablished → unknown (do not write `[]`). Else call `plan-is 'ready'` with full evidence package; max 8 rounds.

- [ ] **Step 4: Log** isolation mode; print `enforced` for a role only if that role’s profile was verified in Task 3 (writer) / Task 4 (reviewer), not merely after 2b doubles.

- [ ] **Step 5: Banner once:** promotion race if lock ignored; weakened scan-time only; review≠readiness; prerequisites≠outcomes for named step; gates/NEXT_STEPS authorize; ASC cache on staging-backed binds.

- [ ] **Step 6: Tests** with extend doubles for writer/reviewer/`plan-is`; false-stop cases; optional `AGENT_PLAN_LIVE=1`.

- [ ] **Step 7: Refuse loader creep** — diff must not introduce harness opt-incs, include loaders, or thin forwarder wrappers “for consistency.”
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
| §1 existing variants, fallback and ranking | 1, 5 |
| §1 minimality / no loader tower | 1, 5, 6 |
| Per-role ASC cache non-reuse / poison | 2b, 6 |
| Verified `make test-core` + discovery assert | 1, 2, 2b, 5 |
| §3 staging / promotion | 2 |
| §4 sandbox doubles + cold/warm ASC state binds | 0, 2b |
| §4 provider create+resume before profile verified | 3, 4 |
| Sandbox wraps chat action subprocess | 2b, 3, 4, 6 |
| §6 plan-is + default deterministic is.ready | 5, 6 |
| Mother `asc/ollaya` ignore | 5 Step 0, 7 (preemptive line already in tree) |
| Loop + limits banner | 6 |
| Hook cache | 1, 3, 4, 5, 7 |

## Self-review notes

- Dropped the include-loader tower. Plain actions + local JSON via a real encoder; `hook_ms` sources the hook once (marker test); no second `.` in the action.
- Nested Make quoting for `named_step`; `required_prerequisites` via CLI or plan marker block—unestablished → unknown; review step mismatch → unknown; gates still authorize.
- Existing hook variants handle selection; extract staging/sandbox helpers only where behavior is substantial.
- Tasks 1 and 6 include an explicit **refuse loader creep** check.
- P1 cache mount: staging-backed per-role exception; poison non-reuse; cold/warm pristine seeds only.
- P1 sandbox visibility: wrap action cmdline; 2b = doubles; 3–4 = authenticated create **and** resume before profile verified.
- Mother ignore + `make test-core` discovery asserts retained.

---

**Plan saved to** `docs/plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md`.

**Also done now:** added `asc/ollaya` to mother [`.asc_extensions_ignore`](../../../../.asc_extensions_ignore).

**Execution options (when you authorize implementation):**

1. **Subagent-Driven** (recommended)  
2. **Inline Execution**

Which approach, and may Task 0 start?
