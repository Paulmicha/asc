# Headless `make agent-plan`: Cursor writer, Codex reviewer, Ollaya stop

| Field | Value |
|-------|--------|
| **Date** | 2026-11-10 |
| **Status** | **plan / review** — contracts settled; implementation planning in [10-agent-plan-cursor-codex-ollaya-impl.md](./10-agent-plan-cursor-codex-ollaya-impl.md). Nothing here is an implementation go-ahead. |
| **Goal** | One ASC action that drafts a changelog plan with Cursor, reviews it with Codex in a headless loop, and stops when a local Ollaya decision says the review is clean **for staged plan bytes the reviewer actually received**. |
| **v1 products** | Cursor (writer), Codex (reviewer), Ollaya (decider). Claude chat roles are the same shape later; not this slice. |
| **Visibility** | Headless CLI / SDK sessions. Desktop-visible “type into the open composer” stays in [27-desktop-agent-terminal-reply.md](../09/27-desktop-agent-terminal-reply.md). |
| **Boundaries** | No project-level provider env vars. Live plan path updated only by the orchestrator after flock + recheck (§3 residual race acknowledged). **Enforced reviewer filesystem claim (narrow):** writes to live docroot paths and staging **plan** bytes are blocked, except (1) enumerated auth/session RW binds and (2) the **sandbox-only** mount of `data/asc/cache` whose **backing store is outside the live tree** and is **per-role / not shared** (§4). Network/socket side effects are out of claim. Weakened = detection only. Mother keeps `asc/ollaya` on `.asc_extensions_ignore`. No Claude. No gates row in this note. |
| **Out of this plan** | Desktop UI injection. Shipping the scripts without a later go-ahead. A second make pivot per tool (`cursor-plan`, `codex-plan`). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

## Why headless

Create + resume by id works today on Cursor Agent CLI / SDK. Those chats do **not** appear in the desktop IDE store (staff confirmed again 2026-10-20: [forum 165486](https://forum.cursor.com/t/local-ide-agent-chats-and-the-agent-cli-still-use-separate-session-stores/165486)).

Codex CLI / app-server can create and resume threads, but two live clients on one thread are unsupported ([openai/codex#21513](https://github.com/openai/codex/issues/21513)), and an external process cannot reliably inject into a Desktop-owned thread (`thread already has an active writer`; [discussion #46797](https://github.com/openai/codex/discussions/46797)).

v1 therefore accepts background conversations and a durable changelog file as the human-facing result.

---

## Decisions locked in review

| Topic | Choice |
|-------|--------|
| Automation surface | Headless Cursor ↔ Codex loop |
| Plan bytes | Orchestrator-owned **staging file**; live path updated only by orchestrator promotion (§3). Not kernel content-CAS; remaining race stated explicitly |
| Write isolation | Same mode for writer and reviewer: **enforced** when sandbox works; otherwise **weakened** with explicit non-claims (§4). Smoke logs both. |
| Reviewer writes (boundary wording) | Enforced = no writes to docroot + staging except enumerated auth RW binds (§4). Weakened = omit auto-write flags + post-scan detection only |
| Sandbox handoff | `agent-plan` (and tests) run each writer/reviewer **chat harness subprocess inside** `f_plan_sandbox_run`; hooks do not need to call the runner |
| Review input | Immutable snapshot bytes **inlined** in the reviewer prompt |
| Stop condition | Ollaya on reviewer reply, bound to snapshot digest; live path must still match at success |
| Ollaya transport | Prefer `/v1/systemone` (truncation → `422`); never accept truncated state as success |
| Ollaya clean floor | `answers.plan_ready.choice == clean` and `confidence ≥ 0.75` on the **recorded** model after fixture tuning |
| Uncertainty | Not treated as writer “issues”; separate `needs_human_review` |
| Stalled draft | After `issues`, if staged digest is unchanged → always `stalled_draft` |
| Role selection | **Extend core `hook_ms`** with role-qualified pick + conflict (§1); harnesses call that API. Chat: `writer` / `reviewer`. Decide: `decider` |
| Cursor model | **Auto** |
| Codex model | **GPT Terra 6.1 – High effort** |
| Max rounds | **8** (§7) |
| Prompt interface | File or stdin primary |
| `chat/read` + `chat/archive` | Rename `chat_TYPE` → `CHAT_TYPE`; keep plain `hook`; no JSON I/O |
| `chat/new` + `chat/reply` pre/post | **Dropped** in v1 |
| Claude | Deferred |

---

## Contracts (must settle before code)

Implementation follows these rules; it does not invent softer ones.

### 1. Role hook selection, conflicts, and bound execution [P1]

`hook_ms` ranks by **rung first**, then dot/slash sum inside that rung, and sources nothing when there is no match ([`hook_ms`](../../../asc/core/hook.manual-inc.sh)). Its dry-run keeps `hook_dry_run_matches` **local**. Before sourcing, normal `hook_ms` calls `f_hook_source_opt_incs_for_path` then applies override ([lines 829–836](../../../asc/core/hook.manual-inc.sh)).

The same role rules apply to **chat** (`CHAT_ROLE`, subject `chat`, actions `new`|`reply`) and **decide** (`DECIDE_ROLE`, subject `decide`, action `run`).

**Maintained-contract decision (do not silently fork ranking):**  
The [asc-author-code](../../../.agents/skills/asc-author-code/SKILL.md) harness law is “generic `$subject-$action` makes a **`hook_ms`** call.” Role qualification and same-rung conflict detection are **stricter** than today’s winner-only `hook_ms`. v1 therefore **extends the shared core** in `asc/core/hook.manual-inc.sh` rather than duplicating rank math in the agent extension:

1. Factor candidate ranking into a core helper used by existing `hook_ms` (unconstrained callers keep today’s semantics).
2. Add a documented selection mode (name locked at implementation, e.g. `hook_ms` flag or `f_hook_ms_pick`) that, when given required action + role token:
   - enumerates candidates (not only the winner);
   - requires the overall winner’s basename to match `^<action>\.<role>\.hook\.sh$`;
   - fails `unqualified_hook_winner` if the overall winner is unqualified or another role (**no** fall-through to a lower-ranked role file);
   - fails `hook_role_conflict` if two or more role-qualified files sit on the winning rung;
   - seeds opt-incs, resolves override once, and sources that bound path.
3. Abstract `chat/new`, `chat/reply`, and `decide/run` call that **extended** API — they do not reimplement `f_hook_ms_measure`.
4. Keep the skill’s “harness → `hook_ms`” wording true after the extension; if the public entry name differs, update the skill in the same authorized change with one sentence naming the mode.

**Harness steps (using the extended API):**

1. Require the role ∈ `{writer, reviewer}` (chat) or `{decider}` (decide).
2. Invoke the extended pick with subject/action/role (and `-v` variants as needed).
3. On missing / unqualified / conflict → JSON failure; non-zero exit.
4. Bound source path does not change between validation and `.` (single pick).

**Tests:** missing; unqualified-only; writer/decider overall winner; extend beats contrib; two role files on same rung → conflict; unqualified higher-sum + role lower-sum → `unqualified_hook_winner`; **parity** unconstrained `hook_ms` dry-run winner equals extended pick on the same fixtures; opt-inc seeded; hook-cache clear after hook/extension changes.

### 2. Chat turn I/O contract [P1]

Make runs the target in a **subprocess** ([`call_wrap.make.sh`](../../../asc/make/call_wrap.make.sh)).

- Diagnostics → **stderr**.
- Machine result → **exactly one JSON object on stdout**.
- Optional `result:<path>` mirror; stdout authoritative.

**Schema** (always attempt before exit; ids nullable when no session yet):

```json
{
  "ok": false,
  "action": "new",
  "role": "writer",
  "chat_id": null,
  "provider_session_id": null,
  "prompt": "…",
  "reply_text": "",
  "status": "failed",
  "error": "no_hook_for_role"
}
```

| Field | Rule |
|-------|------|
| `chat_id` / `provider_session_id` | string when known; else **`null`** |
| `status` | `completed` \| `failed` \| `empty_reply` |
| `error` | `null` on success; short token otherwise |

Orchestrator on crash / empty / malformed stdout: `error=missing_result_json`, abort, no Ollaya success, no promotion.

**Tests:** create/resume both roles; empty/failed provider; harness failure with null ids; `missing_result_json`.

### 3. Path validation, staging, promotion, reviewer bytes [P1]

**Plan path validation (before staging and before every promotion):**

1. Reject empty path.
2. Resolve to a canonical absolute path (`realpath -m` / equivalent for the parent, then join the final component if the file does not exist yet).
3. Require the resolved path is **strictly under** the canonical `PROJECT_DOCROOT` (no `..` escape after resolve).
4. **Symlinks:** the live plan path itself must not be a symlink at validation time (`live_symlink` failure). Parent directories may be real directories only after resolve; if a parent component is a symlink that escapes docroot, reject `path_escape`.
5. Parent directory must exist and be a directory (`missing_parent` if not). The plan file may be absent on first run (creation case).
6. Refuse to use a path whose basename is `.` or `..`.

**Inputs:**

| Input | Required |
|-------|----------|
| Validated plan path | yes |
| Prompt via file or stdin | yes (§5) |

**Staging:**

1. Unique staging dir outside the project tree.
2. If live file exists as a regular file → copy bytes into staging. If absent → empty staging file (creation). If live is a symlink/directory → fail before the loop (`live_not_regular_file`).
3. Writer modifies only the staging plan file (§4).

**Pre-writer live snapshot:**  
Immediately before each writer turn, record `live_before`:

| Live state | Token |
|------------|--------|
| Absent | `kind=absent` |
| Regular file | `kind=file`, `digest=sha256(bytes)`, `size` |
| Other | fail (`live_not_regular_file`) |

**Promotion — guarantee (honest, not kernel CAS):**

Linux `rename` in the same directory makes the **final replacement** atomic, but a separate “stat/hash then rename” sequence is **not** an atomic compare-and-swap on file contents. A human (or any process) can create or edit the live path in the gap after the check and before/during the rename, and that edit can be overwritten.

v1 therefore **weakens** the claim as follows and does not pretend otherwise:

1. Sibling lock file: `\<live-plan\>.asc-plan.lock` in the same directory. From the promotion check through the rename, hold an exclusive `flock` on that lock file. Other `agent-plan` instances must use the same lock (cooperative).
2. Under that lock: re-read live state; refuse (`live_changed`) if it does not match `live_before` (absent↔file, digest change, symlink/dir/type change).
3. Still under the lock: write staging bytes to a temp name in the **same directory**, `fsync`, `rename` over the live path (or into place if `live_before` was absent). Never follow a symlink as the write target. For the **create** case only, prefer `link`/`O_EXCL`/`renameat2 RENAME_NOREPLACE` so a concurrent create fails instead of clobbering—when the platform supports it; otherwise the same flock + recheck applies.
4. Release the lock after rename (or after refused promotion).
5. **Deletion:** the loop never unlinks the live plan; empty staging after a non-first turn → `missing_draft`.
6. On `live_changed`: keep staging; do **not** overwrite live; exit non-zero.

**Remaining race (stated in logs and this plan):** any writer that modifies the live path **without** acquiring `*.asc-plan.lock` can still lose or clobber in the check→rename window (typical editors). Primary mitigation for humans is the pre-writer `live_before` check after the writer turn (edits **during** the writer turn → `live_changed` before promotion). The lock only serializes cooperative promoters.

**Also refuse promotion** if a post-writer docroot scan fails (`write_boundary`).

**Reviewer user message (required parts, in order):**

1. **Review task** — fixed orchestrator text: assess the changelog plan for mistakes, gaps, and improvement opportunities; do not edit files.
2. **Expected response** — fixed orchestrator text: either list concrete remaining issues, or state that there are no remaining issues and the plan is ready for implementation (so Ollaya can classify).
3. Live **path** string and **digest**.
4. **Inlined snapshot bytes** (exact staging bytes for that digest). No “read this path” reliance.
5. Optional short pointer that the operator’s original prompt was for the **writer** (draft), not a substitute for (1)–(2).

Do **not** send only the operator draft prompt to the reviewer. Oversize inlined bytes → `oversized_plan` (no truncate).

**Stalled draft:** prior Ollaya class `issues` and post-writer staging digest equals the last reviewed digest → `stalled_draft`.

**Success:** Ollaya `clean` at threshold **and** live digest equals the inlined snapshot digest from that reviewer turn.

**Tests:** edit live **during** writer turn → `live_changed`, human bytes preserved; inject an unlocked edit in the promotion check→rename interval (document flake risk; assert best-effort detection or overwrite risk acknowledgment in the test note); second cooperative promoter blocks on flock; create from absent / `RENAME_NOREPLACE` when available; reject live symlink; traversal/`..`; missing parent; promote D0 then D1 before each review.

### 4. Write isolation (writer and reviewer) [P1]

Post-turn scans are **detection**, not prevention, unless a sandbox enforces the boundary.

**Modes (same enum for both roles; logged as `writer_isolation` / `reviewer_isolation`):**

| Mode | When | Guarantee |
|------|------|-----------|
| `enforced` | Host sandbox + checked-in profiles verified in step 0 + Task 2b | **Writer:** RW staging (+ enumerated auth binds). **Reviewer:** RO docroot + RO staging contents; **no** write to those trees. Auth/session paths that must be RW are listed in the profile **and** the host note as **exceptions** to the “no reviewer writes” slogan. Symlink escapes into denied trees are blocked by the profile. The **chat harness process** is started *inside* the sandbox by the orchestrator (not merely `cd` to staging). |
| `weakened` | Sandbox/profile unavailable | Allowed when step 0 records it. Omit reviewer `--force`/`--yolo`; inventory (§4a) detects docroot diffs. Does not prevent command-tool writes, ignored-channel writes, restores-before-scan, or writes via allowlisted auth paths. Smoke prints `weakened`. |

**Handoff:** `f_plan_sandbox_run writer|reviewer -- <chat-new|chat-reply cmdline…>` wraps the entire harness subprocess so provider hooks inherit confinement without loading `plan_sandbox` themselves. Bare `make chat-new` outside that wrapper is **not** an `enforced` path.

**ASC generated state (exception + trust boundary):**

Inside the sandbox namespace, `$PROJECT_DOCROOT/data/asc/cache` (and any other listed cold-start write paths) is **RW** via a bind mount. That is an **intentional exception** to “docroot is not writable”: the path *looks like* docroot, but the **backing directory is under staging** (`$STAGING/asc-state/<role>/…`), not the live project tree on the host. The live `data/asc/cache` on disk is not what the sandboxed provider writes.

| Rule | Requirement |
|------|-------------|
| Ownership | Orchestrator creates per-role backing dirs (`writer`, `reviewer`; orchestrator/decide uses a third `orchestrator` or host-native cache **outside** any provider bind). |
| Lifetime | Fresh empty backing dir (or **orchestrator-prepared pristine seed**) at the start of each wrapped turn; discard or quarantine under staging after the turn; **never** promote provider-backed cache into the live docroot cache. |
| Non-reuse | Writer-backed cache must not be mounted for reviewer or for a later trusted orchestrator/`decide-run` process. Warm starts use only orchestrator-controlled seeds, never the previous writer turn’s dirty cache. |
| Tests | Cold empty bind; warm from pristine seed; writer double poisons its cache → reviewer/orchestrator turn must not observe that poison. |

**Include-load failure (harness, not bootstrap):** ASC bootstrap sources `*.opt-inc.sh` without checking `$?` ([bootstrap](../../../asc/bootstrap.sh)). Opt-inc return status alone does **not** stop the action.

| Rule | Requirement |
|------|-------------|
| Pre-bootstrap | Harness **unsets or zeros** `AGENT_HARNESS_INC_OK` (and clears `AGENT_HARNESS_INC_ERROR`) **before** `. asc/bootstrap.sh`, so an inherited env value cannot mask a missing/skipped opt-inc. |
| Success sentinel | Opt-inc sets `AGENT_HARNESS_INC_OK=1` only after every required include succeeds (including `harness_result`). |
| Abort path | If after bootstrap the sentinel is unset/≠1 → emit failure JSON and `exit 1` **before** any provider body. |
| Emitter independence | That failure JSON **must not** call `harness_result` / its emitter: load of `source_manual`, `role_select`, or `harness_result` may already have failed. Use a **minimal inline** `printf` (or equivalent) of valid `ok:false` / `error=include_load_failed` (+ optional `detail` from `AGENT_HARNESS_INC_ERROR`). |
| Tests | Fail each of the three load points separately; assert valid JSON on stdout, non-zero exit, and no provider-body execution. |

**Enforced reviewer acceptance (minimum):** authenticated **create and resume** (Tasks 3–4); write to live docroot fails; write to staging plan path fails; cache exception + non-reuse rules above; every other RW bind listed; sockets out of filesystem claim. A `--help` probe alone is insufficient.

#### 4a. Weakened inventory (precise)

**Scope:** all regular files under canonical `PROJECT_DOCROOT`, **including ignored files**, following the walk rules below.

**Before** each provider turn and **after** it, build a map `rel_path → record`:

| File kind | Record |
|-----------|--------|
| Regular file | `sha256` of contents + size |
| Symlink | `kind=symlink`, target string (do not hash through the link for the link’s own entry) |
| Directory | skip as a hashed leaf (walk into it) |
| Unreadable | `kind=unreadable`, errno; **after** turn, any new unreadable or change → `write_boundary` / scan error |
| Other (fifo, device) | `kind=other`; unexpected appearance → fail |

**Walk:** directory tree under docroot; do not follow symlinks to directories outside docroot (`path_escape` / skip with fail if a link would leave the tree). Do not use git-only status as the inventory.

**Compare:** additions, deletions, regular-file digest changes, symlink target changes → fail `write_boundary` (writer) or `reviewer_write` (reviewer), except the **live plan path** may change only via orchestrator promotion. For writer turns, the live plan path is expected to stay at `live_before` until promotion; if the agent also wrote the live path directly, promotion recheck or inventory fails.

**Scan errors** (walk aborted, permission on a directory mid-tree): fail `inventory_error` (do not continue).

**Limit:** this detects differences **at scan time**. Temporary writes created and restored before the after-scan are invisible—state that limit next to `weakened` in logs.

**Tests:** ignored file content change; already-dirty file further change; addition/deletion; symlink add; unreadable; scan error; temporary restore documented as out of scope for detection.

### 5. Prompt / Make argument interface [P2]

1. `make agent-plan plan:<path> prompt:<file>` (preferred)  
2. stdin / pipe  
3. Inline only `prompt:"'…'"` — no multiline inline  

Unsupported: bare multiword Make args ([`call_wrap.make.sh`](../../../asc/make/call_wrap.make.sh)).

### 6. Decide harness + Ollaya `decider` contract [P2]

Classification is **not** an inline helper inside `agent-plan`. It uses the same contrib pattern as Cursor/Codex:

| Piece | Path / rule |
|-------|-------------|
| Abstract harness | `asc/extensions/agent/decide/run.sh` → `make decide-run` |
| Role | call-local `DECIDE_ROLE=decider` (hardcoded literal; no provider env) |
| Contrib | `scripts/asc/contrib/asc/ollaya` (enablement-gated like `asc/cursor`) |
| Hook implementation | `decide/run.decider.hook.sh` |
| Selection | §1 with subject `decide`, action `run`, role `decider` |
| I/O | One JSON object on stdout (stderr diagnostics); orchestrator never reads hook-locals |

**Decide JSON (success or failure):**

```json
{
  "ok": true,
  "action": "run",
  "role": "decider",
  "class": "clean",
  "choice": "clean",
  "confidence": 0.81,
  "model": "winnow:e4b",
  "state": "…reviewer reply…",
  "raw": {},
  "status": "completed",
  "error": null
}
```

| Field | Rule |
|-------|------|
| `class` | `clean` \| `issues` \| `uncertain` \| `invalid` (orchestrator switch) |
| `choice` / `confidence` / `model` | from Ollaya when parseable; else null with `class=invalid` |
| `raw` | parsed decide body or null |
| Crash / empty stdout | orchestrator `missing_result_json` (same as chat) |

The `agent-plan` loop calls `make decide-run` (or the abstract script) with `DECIDE_ROLE=decider` and the reviewer `reply_text` as state. It does **not** embed `/v1/systemone` curl in `plan.sh`.

**Transport (truncation = unconditional failure) — implemented inside the ollaya hook:**

| API | Truncation behavior | v1 rule |
|-----|---------------------|---------|
| **Primary:** `POST http://127.0.0.1:11435/v1/systemone` | `422 STATE_TRUNCATED` | Class `invalid` |
| Optional native `POST /api/decide` | May set `state_truncated: true` | Require key present and JSON `false`; else `invalid`. Test API-side truncation below any local length cap |

**Request:**

- `model`: pinned id from host feasibility (record in implementation note).
- `state`: reviewer `reply_text` only (not the plan body).
- `questions`:

```json
{
  "plan_ready": {
    "type": "choice",
    "instructions": "Does this Codex review say the changelog plan is ready with no remaining issues?",
    "criteria": {
      "clean": "No remaining issues; ready for implementation",
      "issues": "Still finds mistakes, gaps, or improvements to address before implementation"
    }
  }
}
```

**Field validation (all required for a usable decide):**

| Check | Rule |
|-------|------|
| Transport | HTTP success / CLI exit 0; not `422` |
| `answers.plan_ready.choice` | exactly `clean` or `issues` |
| `answers.plan_ready.confidence` | present, finite number, in `[0, 1]` |
| `answers.plan_ready.probabilities` | persist in logs (both labels) |
| Malformed / missing confidence, non-finite, wrong type, bad choice | `invalid` |

**Meaning of `confidence`:** TypeSafe/Ollaya **normalized top probability** `(K · p_max − 1) / (K − 1)` ([API](https://ollaya.dev/docs/api)). For **K = 2**, `confidence = 0.75` means `p_max = 0.875`. Tune the threshold **per answering model** on the fixture corpus; if fixtures fail at 0.75, revise the threshold in this plan before coding the stop rule. Log canonical `model` on every decide.

**Classification:**

| Condition | Class |
|-----------|--------|
| `choice == issues` | `issues` |
| `choice == clean` and `confidence ≥ 0.75` (or revised pinned threshold) | `clean` |
| `choice == clean` and `confidence <` threshold | `uncertain` |
| Transport/schema/`STATE_TRUNCATED`/`state_truncated` not false / missing fields | `invalid` |

Ollaya classifies the **review text**; it does not prove the plan is correct.

**Fixture corpus (minimum; assert expected class):**

| Fixture | Expect |
|---------|--------|
| Short “no remaining issues, ready” | `clean` (if model+threshold agree) |
| Bullet list of gaps | `issues` |
| Clean-with-caveats | typically `issues` or `uncertain` (record expected per model) |
| Unresolved questions only | `issues` or `uncertain` |
| Negation (“no issues except …”) | not `clean` |
| Mixed findings | `issues` |
| Empty `state` | `invalid` or `uncertain` (pin one) |
| Non-JSON / garbage decide response | `invalid` |
| `422 STATE_TRUNCATED` or `state_truncated: true` | `invalid` |

### 7. Uncertainty and rounds [P2]

| Class | Action |
|-------|--------|
| `issues` | Writer; unchanged digest → `stalled_draft`; else promote (§3) and re-review |
| `uncertain` | No writer; ≤1 reclassify on same `reply_text`; else `needs_human_review` |
| `invalid` | Abort |
| `clean` | Success iff digest binding holds |

**Round:** writer + reviewer + one primary Ollaya decide. Max **8**.

### 8. Acceptance matrix and compatibility [P2]

Cover §1–§7 including: live edit during writer → no overwrite; promotion race documentation + flock test; unqualified-vs-role ranking; opt-incs; weakened inventory; path validation; reviewer message contains task + expected response + bytes; Ollaya fixtures; promotion of each digest before review.

**Compatibility:** new/reply drop pre/post + JSON I/O; read/archive only `CHAT_TYPE` rename; document break for sourced `chat_id` parents.

---

## Architecture

### Abstract harness (`asc/extensions/agent`)

| Path | Pivot | Role |
|------|-------|------|
| `asc/extensions/agent/chat/new.sh` | `make chat-new` | §1 select + opt-incs + JSON |
| `asc/extensions/agent/chat/reply.sh` | `make chat-reply` | Same |
| `asc/extensions/agent/decide/run.sh` | `make decide-run` | §1 select + JSON for `DECIDE_ROLE` |
| Orchestrator | `make agent-plan` | Validate path, stage, isolate, promote (§3), loop; calls chat + decide harnesses |

### Contrib hooks

| Role | Extension | Files |
|------|-----------|--------|
| `writer` | `scripts/asc/contrib/asc/cursor` | `chat/new.writer.hook.sh`, `chat/reply.writer.hook.sh` |
| `reviewer` | `scripts/asc/contrib/asc/codex` | `chat/new.reviewer.hook.sh`, `chat/reply.reviewer.hook.sh` |
| `decider` | `scripts/asc/contrib/asc/ollaya` | `decide/run.decider.hook.sh` |

### Loop (summary)

```text
make agent-plan plan:<path> prompt:<file>
  → validate plan path under PROJECT_DOCROOT (§3)
  → create staging; log writer_isolation / reviewer_isolation
  → live_before snapshot
  → chat-new writer (staging)
  → inventory check; flock + recheck + rename promote → live (D0) or live_changed
  → reviewer msg: task + expected response + path + D0 + inlined bytes
  → chat-new reviewer
  → decide-run DECIDE_ROLE=decider (state = reviewer reply) per §6
       clean     → success if live digest == D0
       issues    → live_before'; writer; if digest==D0 → stalled_draft
                   else promote D1; reviewer task+bytes for D1; decide-run again …
       uncertain → one reclassify (second decide-run) or needs_human_review
       invalid   → abort
  → max 8 rounds
```

---

## Failure modes (orchestrator exits)

| Situation | Behavior |
|-----------|----------|
| Path validation / `live_symlink` / `path_escape` / `missing_parent` | Fail before loop |
| Hook missing / unqualified winner / conflict | Fail; list paths |
| `missing_result_json` / chat failed / empty | Abort; no promotion |
| `live_changed` | Abort; **do not** overwrite live; keep staging |
| Promotion race (unlocked editor in check→rename gap) | Acknowledged residual risk (§3); not claimed solved |
| `missing_draft` / `oversized_plan` / `stalled_draft` / `write_boundary` / `reviewer_write` / `inventory_error` | Abort |
| Ollaya `invalid` / unavailable | Abort |
| `needs_human_review` / `max_rounds` | Non-zero + artifacts |

---

## Order of work

| Step | Work | Done when |
|------|------|-----------|
| 0 | Host feasibility: providers, Ollaya, **sandbox profile draft** | Host note; enforced vs weakened chosen honestly |
| 1 | Extend core `hook_ms` + chat harness + explicit manual-inc loads | Parity + role tests via `make test-core` (agent enabled) |
| 2 | Staging / promotion / inventory | §3–§4a tests green |
| 2b | Writer/reviewer bwrap profiles + runner | Prohibited-write tests; auth binds; no false `enforced` |
| 3 | Cursor writer + Codex reviewer hooks (sandboxed) | Auto / Terra 6.1 High |
| 4 | `decide/run` + `asc/ollaya` + **mother ignore `asc/ollaya`** | Corpus green; ignore hygiene |
| 5 | `agent-plan` orchestrator | Loop §3–§8 |
| 6 | Instance smoke; mother still lists `asc/ollaya` (and peers) as disabled | Success + failure; ignore grep passes |

This note is not step 0–6.

---

## Related notes

- [27-desktop-agent-terminal-reply.md](../09/27-desktop-agent-terminal-reply.md) — desktop reply client (out of v1).
- [22-agent-llm-entry-point.md](../09/22-agent-llm-entry-point.md) — abstract pivot + contrib hook precedent.
- [21-hook-specificity-rungs.md](../09/21-hook-specificity-rungs.md) — `hook_ms` rungs.

---

## Open tasks

- [ ] After go-ahead: implement §1–§8 as written (including host feasibility step 0).
- [ ] After go-ahead: Cursor writer + Codex reviewer + Ollaya decider (no Claude).
- [ ] Pin Ollaya model id; confirm or revise 0.75 against fixtures (K=2 ⇒ p_max 0.875).
- [ ] Record `writer_isolation` / `reviewer_isolation` (`enforced` / `weakened`) on the laptop.
- [ ] Do not add a gates row from this note alone.
- [ ] Keep `asc/ollaya` (and peers) on mother `.asc_extensions_ignore`; instance overrides may enable locally.
