# Headless `make agent-plan`: Cursor writer, Codex reviewer, Ollaya stop

| Field | Value |
|-------|--------|
| **Date** | 2026-11-10 |
| **Status** | **idea / design** — the conversation archive addition has open contracts; implementation planning is in [10-agent-plan-cursor-codex-ollaya-impl.md](../../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md). Nothing here is an implementation go-ahead. |
| **Goal** | One ASC action that drafts a changelog plan with Cursor, reviews it with Codex against the **original brief and declared needs**, and stops when that named next step is ready—preserving the distinction between “reviewer found no blockers” and “ready for the next step” **inside the result**, with one public predicate `plan-is 'ready'` for independent callers. |
| **v1 products** | Cursor (writer), Codex (reviewer). Optional Ollaya hook behind `plan-is 'ready'` only when free-form interpretation earns its keep. Claude deferred. |
| **Visibility** | Headless CLI / SDK sessions. Desktop-visible “type into the open composer” stays in [27-desktop-agent-terminal-reply.md](../../../plans/2026/09/27-desktop-agent-terminal-reply.md). |
| **Boundaries** | No project-level provider env vars. Live plan path updated only by the orchestrator after flock + recheck (§3 residual race acknowledged). **Enforced reviewer filesystem claim (narrow):** writes to live docroot paths and staging **plan** bytes are blocked, except (1) enumerated auth/session RW binds and (2) the **sandbox-only** mount of `data/asc/cache` whose **backing store is outside the live tree** and is **per-role / not shared** (§4). Network/socket side effects are out of claim. Weakened = detection only. Mother keeps `asc/ollaya` on `.asc_extensions_ignore`. No Claude. No gates row in this note. |
| **Out of this plan** | Desktop UI injection. Shipping the scripts without a later go-ahead. A second make pivot per tool (`cursor-plan`, `codex-plan`). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

> **2026-11-13: CLI reuse and new stubs.** The headless approach can reuse
> substantial provider configuration; it does not require controlling a desktop
> composer. The later [`agent` stub survey](13-agent-stubs-and-retrieval.md)
> records naming and hook conflicts with this earlier design. Until they are
> reconciled, the file names and selection contract below are an earlier
> proposal, not an implementation instruction to overwrite the newer stubs.

## Host configuration is useful, but not identical to a desktop session

Codex's local app, IDE extension and CLI share configuration layers, including
configured MCP servers; cached login can also be reused. Cursor's CLI reads the
editor's `mcp.json` and supports project rules. This makes local CLI invocation
a plausible thin-wrapper integration, not a request for ASC to replicate a
desktop application. Sharing configuration does not prove a specific server,
desktop-only tool, plugin, credential, past command approval or UI context is
available in a particular headless run. Project trust, role, environment,
version, network, sandbox, and server startup all matter. See [Codex developer
settings](https://learn.chatgpt.com/docs/developer-settings), [Codex
authentication](https://learn.chatgpt.com/docs/auth?surface=cli), and [Cursor
CLI](https://cursor.com/docs/cli/using).

Cursor documents separate CLI permission configuration and says print mode
cannot ask for approval: permitted actions proceed; actions requiring approval
are rejected. Workspace edits can proceed without `--force`; `--force` is not
a necessary default. Codex's non-interactive mode likewise needs explicit
effective sandbox and approval settings. Neither a previous desktop approval
nor a shared MCP definition proves headless authorization. See [Cursor
permissions](https://cursor.com/docs/cli/reference/permissions), [Cursor
headless](https://cursor.com/docs/cli/headless), and [Codex
non-interactive](https://developers.openai.com/codex/noninteractive/).

Each product owns its conversation and supports CLI session continuation.
Cursor staff report separate editor and CLI chat stores. Codex shares local
state across supported clients, but visibility and resumption between the
installed desktop and CLI versions, and interaction with an active thread,
must be probed rather than assumed. ASC's proposed archive contains the prompts
and replies ASC handles, not a complete provider transcript. A CLI-launched
agent can use a local model only if that product actually supports the desired
endpoint and the model meets the task's tool, context, output and quality needs;
a model server alone is not an agent harness. A gradual local-first migration
is an evaluation goal, not a promise of equivalent results or offline operation.

---

## Why headless

Create + resume by id works today on Cursor Agent CLI / SDK. Those chats do **not** appear in the desktop IDE store (staff confirmed again 2026-10-20: [forum 165486](https://forum.cursor.com/t/local-ide-agent-chats-and-the-agent-cli-still-use-separate-session-stores/165486)).

Codex CLI / app-server can create and resume threads, but two live clients on one thread are unsupported ([openai/codex#21513](https://github.com/openai/codex/issues/21513)), and an external process cannot reliably inject into a Desktop-owned thread (`thread already has an active writer`; [discussion #46797](https://github.com/openai/codex/discussions/46797)).

v1 therefore accepts background conversations and a durable changelog file as the human-facing result.

---

## Design decisions and open additions

| Topic | Choice |
|-------|--------|
| Automation surface | Headless Cursor ↔ Codex loop |
| Plan bytes | Orchestrator-owned **staging file**; live path updated only by orchestrator promotion (§3). Not kernel content-CAS; remaining race stated explicitly |
| Write isolation | Same mode for writer and reviewer: **enforced** when sandbox works; otherwise **weakened** with explicit non-claims (§4). Smoke logs both. |
| Reviewer writes (boundary wording) | Enforced = no writes to docroot + staging except enumerated auth RW binds (§4). Weakened = omit auto-write flags + post-scan detection only |
| Sandbox handoff | `agent-plan` (and tests) run each writer/reviewer **chat harness subprocess inside** `f_plan_sandbox_run`; hooks do not need to call the runner |
| Review input | Immutable snapshot bytes **inlined** in the reviewer prompt |
| Stop condition | Structured review non-blocking for the **named next step**; digest binding holds; `plan-is 'ready'` → **yes** (prerequisites for that step pass; outcomes of that step not required). Optional suggestions do **not** keep the loop alive |
| Needs ownership | Declared **in the plan** (acceptance criteria, prerequisites, open decisions, tied to steps). Not a second Make target in v1 |
| Reviewer input | Original operator brief + declared needs/acceptance criteria + exact plan bytes (digest-bound). Not plan-only |
| Public predicate | **Only** `make plan-is 'ready'`. Defer `review/is.sh` and `plan/needs.sh` until a concrete caller needs them |
| Readiness evidence | Original brief, plan revision, structured review result, and any required host/check outcomes the review-text alone cannot see |
| Authorization | Separate: discussion in `NEXT_STEPS.core.md`; human go-ahead in `gates.core.yml`. `plan-is` does not authorize implementation |
| Uncertainty / pause | Missing evidence or human decision → **pause** (`unknown` / `needs_human_review`); never coerce to ready |
| Stalled draft | Blocking findings + unchanged staging digest after a writer turn → `stalled_draft` |
| Role / predicate selection | **Existing `hook_ms` variants** (§1). Chat: `writer` / `reviewer`. Predicate: `plan`/`is`/`ready`. |
| Cursor model | **Auto** |
| Codex model | **GPT Terra 6.1 – High effort** |
| Max rounds | **8** (§7) |
| Prompt interface | File or stdin primary |
| Conversation archive | Proposed human-readable Markdown per chat; see [agent chats](../../../specs/asc/agent-chats.md). The sandbox handoff and recovery contract remain to be designed. |
| `chat/read` + `chat/archive` | Rename `chat_TYPE` → `CHAT_TYPE`; keep plain `hook`; no JSON I/O |
| Claude | Deferred |

---

## Contracts (must settle before code)

Implementation follows these rules; it does not invent softer ones.

### 1. Role and predicate selection with existing variants [P1]

Use the existing `hook_ms` and variant lookup in
[`hook.manual-inc.sh`](../../../../asc/core/hook.manual-inc.sh). No core selection
API or alternate ranking is needed. `CHAT_ROLE` selects `writer` or `reviewer`
for `chat/new` and `chat/reply`; a variable holding `ready` selects the predicate
variant for `plan/is`. Pass the variable name to `-v`. Include other existing
variants only when needed by the action.

Normal lookup considers the unqualified hook as well as variant combinations.
`hook_ms` ranks by location rung first, then dot/slash sum, and resolves ties
using the later candidate. Consequently an unqualified hook on a higher rung
can win; normal fallback, combinations, overrides, and tie handling are
intentional here. There is no role-conflict error or exact-basename requirement.
Other roles are not requested by `CHAT_ROLE` alone. Overrides and opt-incs use
normal `hook_ms` behavior.

**Harness steps (plain action):**

1. Require the role/predicate token: chat ∈ `{writer, reviewer}`; `plan-is`
   requires argument `ready` (v1). Reject other tokens with JSON failure.
2. Call `hook_ms` once with subject, action, and the appropriate `-v` variable.
   It sources the selected hook; the action must not source it again.
3. Detect a missing match using the documented `most_specific_match` result;
   emit local JSON failure and exit non-zero. Also handle provider failure.
   Normal `hook_ms` does not itself report a missing match as an error.
4. Map the provider outcome to one stdout JSON object using a proper encoder.
5. For `plan-is`, return `yes` | `no` | `unknown` plus a reason. Missing,
   uncertain, malformed, truncated, or unavailable evidence is `unknown`;
   a bare Boolean or exit status is not readiness. Readiness does not authorize
   execution.

**Minimality:** Do not add a selection wrapper, duplicate ranking, or modify
core hooks for this workflow. Do not add `*.opt-inc.sh` for these actions, a
custom include loader, a success sentinel for bootstrap include status, or thin
`f_agent_*` wrappers that only forward to core. Extract a `manual-inc` / function
only when it encapsulates substantial behavior.

**Tests:** writer and reviewer variants select their implementations; `ready`
selects its variant; missing match returns JSON failure; unqualified fallback,
higher-rung precedence and ties follow normal `hook_ms` behavior; marker hook is
invoked exactly once; JSON strings round-trip; clear hook cache after fixture
changes. Test predicate evidence and unknown handling as specified in §6.

### 2. Chat turn I/O contract [P1]

Make runs the target in a **subprocess** ([`call_wrap.make.sh`](../../../../asc/make/call_wrap.make.sh)).

- Diagnostics → **stderr**.
- Machine result → **exactly one JSON object on stdout**.
- Encode string fields (`prompt`, `reply_text`, errors that may carry text) with a proper JSON encoder; do not interpolate unescaped shell strings into JSON via `printf`.
- Optional `result:<path>` mirror; stdout authoritative.
- `chat-new` and `chat-reply` are also to maintain the proposed human-readable
  conversation archive in [agent chats](../../../specs/asc/agent-chats.md).
  Its path must be available to callers without parsing Markdown. Association,
  failure handling, and the sandbox-to-orchestrator handoff are open design
  work; do not weaken §4 isolation to write the live archive.

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

Orchestrator on crash / empty / malformed stdout: `error=missing_result_json`, abort, no readiness **yes**, no promotion.

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

**Plan content (writer must produce / keep):** The plan is the canonical place to **declare what the work needs**, each tied to a named step:

| Declaration | Meaning |
|-------------|---------|
| **Prerequisites** (for a step) | Must already hold **before** that step may start; v1 also emits them as the `<!-- asc-prerequisites named_step="…" -->` JSON array block (§6) so `agent-plan` can establish the authoritative id list |
| **Outcomes** (of a step) | Expected results **of** running the step—must not be treated as start blockers |
| **Open decisions** | Human/evidence gates; missing → pause, not silent start |

Example: a plan may be **ready to begin Task 0** while Task 0’s outcomes (e.g. authenticated create+resume verified) do not exist yet; those are outcomes of Task 0, not prerequisites for starting it. Implementation of later work can remain blocked by other declared needs. **Ready for a named step does not authorize that step**—[`NEXT_STEPS.core.md`](../../../../NEXT_STEPS.core.md) / [`gates.core.yml`](../../../../gates.core.yml) still govern go-ahead.

**Needs wording:** Extracting needs from the plan alone cannot reveal a need the writer omitted. Supplying the **original brief** gives the reviewer a chance to spot that omission; that remains a **review judgment**, not a guaranteed mechanical check.

**Reviewer user message (required parts, in order):**

1. **Review task** — fixed orchestrator text: assess whether this plan revision fits the **original operator brief** and the plan’s **declared needs**; separate **blocking** findings from **optional** suggestions; do not edit files.
2. **Expected response** — structured JSON (schema §6) the loop can act on without a second Make target.
3. **Original operator brief** (intent) — required, same bytes the writer received.
4. **Declared needs excerpt** — from the plan (prerequisites / outcomes / open decisions for the named step under review). Present for convenience; omission-catching still depends on (3) + reviewer judgment.
5. Live **path** string and **digest**.
6. **Inlined snapshot bytes** (exact staging bytes for that digest).

Do **not** send only the plan bytes, and do **not** omit the brief. Oversize inlined bytes → `oversized_plan` (no truncate).

**Review result (loop-internal evidence, not a Make target):** Schema and failure rules in §6. Blocking → **revise**; missing evidence/human decision → **pause**; optional suggestions alone do not keep the loop alive.

**Stalled draft:** prior review had **blocking** findings and post-writer staging digest equals the last reviewed digest → `stalled_draft`.

**Success:** structured review allows readiness assessment, live digest matches the reviewed snapshot, **and** `plan-is 'ready'` → **yes** with a reason (prerequisites for the named step met; outcomes of that step not required yet).

**Tests:** edit live **during** writer turn → `live_changed`, human bytes preserved; inject an unlocked edit in the promotion check→rename interval (document flake risk; assert best-effort detection or overwrite risk acknowledgment in the test note); second cooperative promoter blocks on flock; create from absent / `RENAME_NOREPLACE` when available; reject live symlink; traversal/`..`; missing parent; promote D0 then D1 before each review.

### 4. Write isolation (writer and reviewer) [P1]

Post-turn scans are **detection**, not prevention, unless a sandbox enforces the boundary.

**Modes (same enum for both roles; logged as `writer_isolation` / `reviewer_isolation`):**

| Mode | When | Guarantee |
|------|------|-----------|
| `enforced` | Host sandbox + checked-in profiles verified in step 0 + Task 2b | **Writer:** RW staging (+ enumerated auth binds). **Reviewer:** RO docroot + RO staging contents; **no** write to those trees. Auth/session paths that must be RW are listed in the profile **and** the host note as **exceptions** to the “no reviewer writes” slogan. Symlink escapes into denied trees are blocked by the profile. The **chat harness process** is started *inside* the sandbox by the orchestrator (not merely `cd` to staging). |
| `weakened` | Sandbox/profile unavailable | Allowed when step 0 records it. Omit reviewer `--force`/`--yolo`; inventory (§4a) detects docroot diffs. Does not prevent command-tool writes, ignored-channel writes, restores-before-scan, or writes via allowlisted auth paths. Smoke prints `weakened`. |

**Handoff:** `f_plan_sandbox_run writer|reviewer -- <chat-new|chat-reply cmdline…>` wraps the entire harness subprocess so provider hooks inherit confinement without loading `plan_sandbox` themselves. Bare `make chat-new` outside that wrapper is **not** an `enforced` path.

**Archive handoff remains open:** the proposed ASC chat archive belongs in the
live instance, but the sandboxed harness cannot write it there under this
boundary. Specify and test how the outside orchestrator persists ASC-handled
turns before implementing that path; do not add a live writable provider bind.

**ASC generated state (exception + trust boundary):**

Inside the sandbox namespace, `$PROJECT_DOCROOT/data/asc/cache` (and any other listed cold-start write paths) is **RW** via a bind mount. That is an **intentional exception** to “docroot is not writable”: the path *looks like* docroot, but the **backing directory is under staging** (`$STAGING/asc-state/<role>/…`), not the live project tree on the host. The live `data/asc/cache` on disk is not what the sandboxed provider writes.

| Rule | Requirement |
|------|-------------|
| Ownership | Orchestrator creates per-role backing dirs (`writer`, `reviewer`; orchestrator / `plan-is` use a third `orchestrator` or host-native cache **outside** any provider bind). |
| Lifetime | Fresh empty backing dir (or **orchestrator-prepared pristine seed**) at the start of each wrapped turn; discard or quarantine under staging after the turn; **never** promote provider-backed cache into the live docroot cache. |
| Non-reuse | Writer-backed cache must not be mounted for reviewer or for a later trusted orchestrator / predicate-action process. Warm starts use only orchestrator-controlled seeds, never the previous writer turn’s dirty cache. |
| Tests | Cold empty bind; warm from pristine seed; writer double poisons its cache → reviewer/orchestrator turn must not observe that poison. |

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

**Make quoting:** ASC’s wrapper strips one quote layer ([`call_wrap.make.sh`](../../../../asc/make/call_wrap.make.sh)). Values with spaces need the **nested** form `key:"'value with spaces'"` (same pattern as `prompt:"'…'"`). A single layer such as `named_step:'Task 0'` is consumed before the script runs and will split or drop the value. Prefer file paths without spaces when possible; still document nested quoting for `named_step`.

**`agent-plan`:**

```bash
make agent-plan plan:changelog/…/plan.md prompt:brief.md named_step:"'Task 0'"
# optional explicit prereq list file:
make agent-plan … named_step:"'Task 0'" required_prerequisites:data/…/task-0-prereqs.json
```

| Arg | Required | Meaning |
|-----|----------|---------|
| `plan:` | yes | Live plan path under docroot |
| `prompt:` / stdin | yes | Original operator brief (writer intent); multiword inline only as `prompt:"'…'"` — no multiline inline |
| `named_step:` | yes | Next step for **start** readiness; use `named_step:"'Task 0'"` when the value has spaces |
| `required_prerequisites:` | no | Path to JSON array of prerequisite **ids** for that step. If omitted, §6 extraction from the plan applies. |

Unsupported: bare multiword Make args; omitting `named_step:`; single-layer quotes around multiword `named_step` / `prompt`.

**Tests:** end-to-end Make invocation with `named_step:"'Task 0'"` reaches the orchestrator with `named_step=Task 0` (not split tokens).

**`plan-is`:** evidence keys in §6; same nested quoting for any multiword `named_step:` value.

### 6. Readiness: one public predicate `plan-is 'ready'` [P2]

Keep **one** public question for independent callers: `make plan-is 'ready'`. Preserve “reviewer found no blockers” vs “ready for the named next step” **in evidence**, not as two Make targets.

| Question | Where the answer lives |
|----------|------------------------|
| What does this plan require? | **In the plan** (prerequisites / outcomes / open decisions per step) |
| What did the reviewer find? | **Structured review result** (loop artifact), digest-tied |
| Is this revision ready for the named next step? | **`plan-is 'ready'`** |
| May the agent start that step? | **`NEXT_STEPS.core.md` + `gates.core.yml`**—not this predicate |

Defer **`review/is.sh`** and **`plan/needs.sh`**. Do not use `chat-is 'done'` / `chat-is 'over'`.

#### Named-step readiness (definition)

`plan-is 'ready'` answers: **may the named next step start**, given the evidence package—not “has the whole plan’s work already been finished.”

| Check kind | Blocks `yes` for starting `named_step`? |
|------------|----------------------------------------|
| Prerequisite for `named_step` | **Yes**—must be recorded `pass` |
| Outcome **of** `named_step` | **No**—absence is expected before the step runs |
| Open decision / missing human gate for starting | → **`unknown`** or **`no`** with reason (pause), never silent `yes` |
| Prerequisite recorded `fail` | → **`no`** with actionable reason |
| Prerequisite required but record `missing` / absent | → **`unknown`**, reason lists the missing id |

Example: ready to start **Task 0** (host feasibility) does not require Task 0’s create+resume outcome to exist yet. Ready to start **Task 3** may require Task 0 outcomes as **prerequisites** once Task 0 is declared done.

#### Structured review result (minimum fields)

Produced by the reviewer turn (Codex); consumed by the loop and by `plan-is`. Prefer one JSON object (file or stdout field). Minimum:

```json
{
  "verdict": "blocking",
  "plan_digest": "<sha256 of reviewed plan bytes>",
  "named_step": "Task 0",
  "blocking": [
    {"id": "B1", "text": "…", "fixable_by_writer": true}
  ],
  "optional": [
    {"id": "O1", "text": "…"}
  ],
  "rationale": "short prose"
}
```

| Field | Rule |
|-------|------|
| `verdict` | exactly `blocking` \| `ready_for_named_step` \| `needs_human_or_evidence` |
| `plan_digest` | sha256 of the inlined bytes for that turn |
| `named_step` | non-empty string; **must equal** caller `named_step:` or merge returns `unknown` |
| `blocking` / `optional` | arrays (may be empty); each item has `text`; `blocking[].fixable_by_writer` boolean when present |
| `rationale` | non-empty string |

**Malformed / unusable review → treat as not ready to proceed silently:**

| Condition | Loop | `plan-is` if invoked |
|-----------|------|----------------------|
| Missing/non-JSON / wrong types / unknown `verdict` | Pause / abort path; do not promote success | `answer=unknown`, `reason` cites parse error |
| `plan_digest` ≠ digest of plan bytes in the evidence package | Pause | `unknown`, reason `review_digest_mismatch` |
| `named_step` ≠ caller’s `named_step:` (even if digest and verdict look valid) | Pause | `unknown`, reason `review_named_step_mismatch` |
| `verdict=blocking` but `blocking` empty; or `ready_for_named_step` with non-empty blocking | Pause | `unknown`, reason `review_contradiction` |
| `verdict=needs_human_or_evidence` | Pause | `unknown` (or `no` if reason says revise)—never `yes` |
| Free-form reply that fails schema | Pause; optional later Ollaya only if explicitly added—not v1 default | n/a until structured |

#### Evidence interface (caller → `plan-is`)

`make plan-is 'ready'` plus Make `key:value` paths (style locked in the action header; same keys for `agent-plan` when it invokes the action):

| Input | Required | Meaning |
|-------|----------|---------|
| `named_step:` | yes | Step being assessed for **start** readiness |
| `brief:` | yes | Path to original operator brief bytes |
| `plan:` | yes | Path to plan file (or staging file) |
| `plan_digest:` | yes | Expected sha256 of those plan bytes |
| `review:` | yes | Path to structured review JSON for that digest |
| `required_prerequisites:` | yes | Path to JSON **array of prerequisite id strings** required to **start** `named_step` (authoritative; may be `[]`) |
| `checks:` | yes | Path to JSON array of check **records** (results); may be `[]` |

**Authoritative required IDs (prevents false `yes` on empty `checks`):**

- `required_prerequisites` is the **only** list of IDs that must be satisfied for start-readiness. It is **not** inferred from which rows appear in `checks`.
- For each `id` in that list: find a `checks` record with the same `id`, `kind=prerequisite`, and (if present) matching `named_step`.  
  - no row → treat as absent → **`unknown`**, `reason` lists the id (and `missing_evidence`)  
  - `status=missing` → **`unknown`**  
  - `status=fail` → **`no`**, actionable reason  
  - `status=pass` → ok for that id  
- Extra `checks` rows whose ids are **not** in `required_prerequisites` do not create requirements (outcome rows still ignored for start-readiness).
- If the established list is `[]`, an empty `checks` array can yield **`yes`** (subject to review/digest rules)—that means “this step declares no start prerequisites,” not “we forgot to pass checks.”
- **Never silently invent `[]`:** if the authoritative list cannot be established, readiness is **`unknown`** (`reason=required_prerequisites_unestablished`), not a false `yes`.

**How `agent-plan` establishes `required_prerequisites` (concrete, in order):**

1. **CLI file** — if `required_prerequisites:<path>` was passed (§5), read that JSON array of id strings. Invalid JSON / non-array → unestablished → **`unknown`** (do not coerce to `[]`).
2. **Else parse the plan** — look for a single, fixed machine-readable block the writer is instructed to keep, e.g. an HTML comment or fenced block with stable markers:

   `<!-- asc-prerequisites named_step="Task 0" -->` … JSON array … `<!-- /asc-prerequisites -->`

   Matching `named_step` (exact string equality with CLI `named_step:`). If the block is missing, duplicated, wrong step, or not a JSON array → unestablished → **`unknown`**. A present block whose array is literally `[]` **is** established (step declares no start prereqs).
3. **Do not** scan `checks`, host notes, or free-form prose to invent ids. Do not invent a second needs framework beyond this block + optional CLI file.

`agent-plan` writes the established array to a staging evidence file and passes its path into `plan-is`. If unestablished, it still invokes `plan-is` only with an explicit failure signal (or skips merge and records the same `unknown` outcome)—**never** by writing a synthetic empty array and treating it as success-eligible.

**Check record:**

```json
{
  "id": "host_bwrap",
  "kind": "prerequisite",
  "named_step": "Task 0",
  "status": "pass"
}
```

| `kind` | `status` |
|--------|----------|
| `prerequisite` \| `outcome` | `pass` \| `fail` \| `missing` |

v1 merge **ignores** `kind=outcome` for the yes/no/unknown decision (may log them).

**`agent-plan` package:** `named_step:` from CLI (§5, nested quotes tested); `brief:` from `prompt:`; plan path + digest; review JSON path; `required_prerequisites:` = established list file from the route above (or unestablished → unknown); `checks:` = known result records only. Independent callers of `plan-is` must pass an already-established `required_prerequisites:` file themselves.

#### Answer contract

| `answer` | When | `reason` must |
|----------|------|----------------|
| `yes` | Review usable; `review.named_step` == caller `named_step:`; `verdict` is `ready_for_named_step` (or equivalent: no blocking, not needs_human); digests match; **every** id in `required_prerequisites` has a `pass` record | State that named step may start; cite digest |
| `no` | Review `blocking` with fixable items, or a required prerequisite `fail`, or verdict implies revise | Be **actionable** (what to fix / which check failed) |
| `unknown` | Malformed/contradictory/digest-mismatched/`named_step` mismatch; **required list unestablished**; required id absent or `missing`; `needs_human_or_evidence`; unavailable evidence file | Say **what is missing** (including unestablished list / absent ids) |

Never coerce `unknown` → `yes`. Crash / empty stdout → orchestrator `missing_result_json`.

```json
{
  "ok": true,
  "subject": "plan",
  "action": "is",
  "question": "ready",
  "answer": "unknown",
  "reason": "missing prerequisite record: cursor_create_resume (required to start Task 3)",
  "named_step": "Task 3",
  "missing_evidence": ["cursor_create_resume"],
  "status": "completed",
  "error": null
}
```

#### v1 default implementation (Ollaya absent)

| Piece | Path / rule |
|-------|-------------|
| Abstract | `asc/extensions/agent/plan/is.sh` → `make plan-is 'ready'` |
| **Default hook** | `asc/extensions/agent/plan/is.ready.hook.sh` — **deterministic evidence merge** (no LLM). Always shipped with agent so §1 pick has a winner when agent is enabled |
| Optional later | `scripts/asc/contrib/asc/ollaya/plan/is.ready.hook.sh` only if free-form interpretation is still needed after structured review; mother ignore remains |
| Selection | §1 subject `plan`, action `is`, role `ready` |

**What the deterministic hook does:** validate evidence files; verify `plan_digest` matches plan bytes; require `review.named_step` == caller `named_step:`; validate review schema and contradiction rules; refuse unestablished / invalid `required_prerequisites` (→ unknown, not `[]`); for each id in an established list, require a matching pass record (absent → unknown); emit yes/no/unknown + reason.

**What it does not do:** independently infer that the plan covers every requirement in a free-form brief. Coverage of the brief is a **structured review judgment**. The merge trusts a valid review result; it does not re-read the brief to invent findings.

`agent-plan` calls this on the path toward success after a non-blocking review. It does not embed Ollaya HTTP in `plan.sh`.

#### Ollaya (non-default)

If added later: truncation → `unknown`; confidence floor alone never yields `yes`; false-stop fixtures required. Not required for v1 green path.

### 7. Loop outcomes and rounds [P2]

| Situation | Action |
|-----------|--------|
| Blocking findings the writer can address | **Revise** (writer); unchanged digest → `stalled_draft`; else promote (§3) and re-review |
| Missing evidence, open human decision, or `plan-is` → **unknown** | **Pause** (`needs_human_review` / missing_evidence)—no silent success |
| Only optional suggestions | **Do not** keep revising; proceed to readiness assessment |
| `plan-is` → **no** with revise reason | Writer path |
| `plan-is` → **yes** + digest binding | Success: **named next step may start** (authorization remains gates/NEXT_STEPS; step outcomes not required yet) |
| Crash / malformed JSON | Abort |

**Round:** writer + reviewer (+ readiness when review is non-blocking). Max **8**. Optional improvements alone do not consume rounds after agreed work is accounted for.

### 8. Acceptance matrix and compatibility [P2]

Cover §1–§7 including: live edit during writer → no overwrite; promotion race documentation + flock test; normal variant fallback and ranking; weakened inventory; path validation; reviewer message contains **brief + needs + bytes**; `required_prerequisites` vs empty `checks` (no false yes); `review.named_step` mismatch → unknown; `agent-plan` requires nested-quoted `named_step:"'…'"`; unestablished prereq list → unknown (no silent `[]`); `plan-is` yes/no/unknown+reason; promotion of each digest before review.

**Compatibility:** new/reply drop pre/post + JSON I/O; read/archive only `CHAT_TYPE` rename; document break for sourced `chat_id` parents.

---

## Architecture

### Plain actions (`asc/extensions/agent`)

| Path | Pivot | Role |
|------|-------|------|
| `asc/extensions/agent/chat/new.sh` | `make chat-new` | Plain action: §1 `hook_ms` variants + local JSON |
| `asc/extensions/agent/chat/reply.sh` | `make chat-reply` | Same |
| `asc/extensions/agent/plan/is.sh` | `make plan-is 'ready'` | Pick default deterministic `is.ready` hook; evidence package → yes/no/unknown + reason |
| Orchestrator | `make agent-plan` | Validate path, stage, isolate, promote (§3), loop; chat + review evidence + plan-is |

### Contrib hooks

| Role / predicate | Extension | Files |
|------------------|-----------|--------|
| `writer` | `scripts/asc/contrib/asc/cursor` | `chat/new.writer.hook.sh`, `chat/reply.writer.hook.sh` |
| `reviewer` | `scripts/asc/contrib/asc/codex` | `chat/new.reviewer.hook.sh`, `chat/reply.reviewer.hook.sh` |
| `ready` | `asc/extensions/agent` (default deterministic) | `plan/is.ready.hook.sh` |
| `ready` (optional) | `scripts/asc/contrib/asc/ollaya` | only if free-form interpretation is added later |

### Loop (summary)

```text
make agent-plan plan:<path> prompt:<file> named_step:"'Task 0'"
  → validate plan path under PROJECT_DOCROOT (§3)
  → create staging; log writer_isolation / reviewer_isolation
  → live_before snapshot
  → chat-new writer (staging)
  → inventory check; flock + recheck + rename promote → live (D0) or live_changed
  → reviewer msg: brief + needs/criteria + path + D0 + plan bytes
  → chat-new reviewer
  → parse structured review result (blocking vs optional) — loop-internal, not review-is
       blocking → writer revise / stalled_draft / promote+re-review
       needs_human_or_evidence → pause
       ready_for_named_step (or only optional suggestions) → plan-is 'ready'
            yes + digest → success (gates still govern implementation)
            no (revise reason) → writer
            unknown / no (missing evidence) → pause
  → max 8 rounds
```

---

## Failure modes (orchestrator exits)

| Situation | Behavior |
|-----------|----------|
| Path validation / `live_symlink` / `path_escape` / `missing_parent` | Fail before loop |
| Hook missing | Fail with JSON error |
| `missing_result_json` / chat failed / empty | Abort; no promotion |
| `live_changed` | Abort; **do not** overwrite live; keep staging |
| Promotion race (unlocked editor in check→rename gap) | Acknowledged residual risk (§3); not claimed solved |
| `missing_draft` / `oversized_plan` / `stalled_draft` / `write_boundary` / `reviewer_write` / `inventory_error` | Abort |
| `plan-is` crash or persistent **unknown** / missing evidence | Pause or abort per §7 |
| `needs_human_review` / `max_rounds` | Non-zero + artifacts |

---

## Order of work

| Step | Work | Done when |
|------|------|-----------|
| 0 | Host feasibility: providers, optional Ollaya, **sandbox profile draft** | Host note; enforced vs weakened chosen honestly |
| 1 | Use existing `hook_ms` variants in plain chat actions | Variant and fallback tests via `make test-core` (agent enabled) |
| 2 | Staging / promotion / inventory | §3–§4a tests green |
| 2b | Writer/reviewer bwrap profiles + runner | Prohibited-write tests; auth binds; no false `enforced` |
| 3 | Cursor writer + Codex reviewer hooks (sandboxed) | Auto / Terra 6.1 High |
| 4 | `plan-is 'ready'` + default `is.ready.hook.sh` (deterministic) | Schema/digest/prereq fixtures; optional ollaya later |
| 5 | `agent-plan` orchestrator | Loop §3–§8 |
| 6 | Instance smoke; mother still lists `asc/ollaya` (and peers) as disabled | Success + failure; ignore grep passes |

This note is not step 0–6.

---

## Related notes

- [Local action records](13-local-action-records.md) — proposed separate wrapper logs, chat archives and thread state.
- [27-desktop-agent-terminal-reply.md](../../../plans/2026/09/27-desktop-agent-terminal-reply.md) — desktop reply client (out of v1).
- [21-hook-specificity-rungs.md](../../../plans/2026/09/21-hook-specificity-rungs.md) — `hook_ms` rungs.

---

## Open tasks

- [ ] After go-ahead: implement §1–§8 as written (including host feasibility step 0).
- [ ] After go-ahead: Cursor writer + Codex reviewer + `plan-is 'ready'` (Ollaya optional; no Claude).
- [ ] If Ollaya used: pin model id; false-stop fixtures; do not treat 0.75 alone as readiness.
- [ ] Record `writer_isolation` / `reviewer_isolation` (`enforced` / `weakened`) on the laptop.
- [ ] Do not add a gates row from this note alone.
- [ ] Keep `asc/ollaya` (and peers) on mother `.asc_extensions_ignore`; instance overrides may enable locally.
