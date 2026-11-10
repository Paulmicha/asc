# Headless `make agent-plan`: Cursor writer, Codex reviewer, Ollaya stop

| Field | Value |
|-------|--------|
| **Date** | 2026-11-10 |
| **Status** | **plan / review**. Contract section below must stay settled before implementation. Nothing here is an implementation go-ahead. |
| **Goal** | One ASC action that drafts a changelog plan with Cursor, reviews it with Codex in a headless loop, and stops when a local Ollaya decision says the review is clean **for staged plan bytes the reviewer actually received**. |
| **v1 products** | Cursor (writer) and Codex (reviewer) only. Claude is the same shape later; not this slice. |
| **Visibility** | Headless CLI / SDK sessions. Desktop-visible “type into the open composer” stays in [27-desktop-agent-terminal-reply.md](../09/27-desktop-agent-terminal-reply.md). |
| **Boundaries** | No project-level provider env vars. Live plan path updated only by the orchestrator after flock + recheck (§3 residual race acknowledged). Reviewer writes: **prevented** in `enforced` isolation; **detected / not claimed prevented** in `weakened` (logged). No mother default enablement of `agent`, `asc/cursor`, or `asc/codex`. No Claude hook implementations in this plan. No gates row in this note. |
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
| Reviewer writes (boundary wording) | Enforced = no reviewer writes by sandbox. Weakened = omit auto-write flags + post-scan detection only; **not** a prevention guarantee |
| Review input | Immutable snapshot bytes **inlined** in the reviewer prompt |
| Stop condition | Ollaya on reviewer reply, bound to snapshot digest; live path must still match at success |
| Ollaya transport | Prefer `/v1/systemone` (truncation → `422`); never accept truncated state as success |
| Ollaya clean floor | `answers.plan_ready.choice == clean` and `confidence ≥ 0.75` on the **recorded** model after fixture tuning |
| Uncertainty | Not treated as writer “issues”; separate `needs_human_review` |
| Stalled draft | After `issues`, if staged digest is unchanged → always `stalled_draft` |
| Role selection | Rank all candidates like `hook_ms`; **sourced path must be that overall winner and role-qualified**; else fail. Seed opt-incs before source (§1) |
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

**Required implementation route (v1 harness — do not call `hook_ms` for select-then-run):**

1. Require `CHAT_ROLE` ∈ `{writer, reviewer}`.
2. In the harness calling scope: `hook_dry_run_matches=''`, then  
   `hook -t -s 'chat' -a '<new|reply>' -v '… CHAT_ROLE …'`.  
   `hook()` writes `hook_dry_run_matches` into the **caller** when not shadowed by `hook_ms`’s `local`.
3. Rank **all** candidates with the same rules as `f_hook_ms_measure` / `hook_ms` (rung, then sum; equal keeps later). Call the unique overall winner `C_win` (lookup path before override).
4. **Missing:** no candidates → `no_hook_for_role`.
5. **Winner must be role-qualified:** basename of `C_win` must match  
   `^(new|reply)\.${CHAT_ROLE}\.hook\.sh$`.  
   If `C_win` is unqualified (e.g. `new.hook.sh`) **or** carries another role → fail `unqualified_hook_winner`.  
   **Do not** fall through to a lower-ranked role-qualified file on the same rung. Example: same rung has `new.hook.sh` (higher sum) and `new.writer.hook.sh` (lower sum) → **fail**, do not source the writer file.
6. **Same-rung role conflicts:** if **two or more** role-qualified candidates exist on `C_win`’s rung (regardless of sum order among them) → fail `hook_role_conflict` and list them. (If exactly one role-qualified exists on that rung but it is not `C_win`, step 5 already failed.)
7. Resolve override **once** for `C_win` (`f_autoload_override` / `f_hook_resolve_source_path`, same as `hook_ms`). Store the final path in `CHAT_HOOK_SOURCE`.
8. **Opt-incs:** call `f_hook_source_opt_incs_for_path` on the lookup path **before** sourcing, matching `hook_ms` (so implementer `*.opt-inc.sh` files are not skipped).
9. Source **only** `CHAT_HOOK_SOURCE`. No second lookup.

**Tests:** missing; unqualified-only; writer is overall winner; extend beats contrib; two `.writer.` on same rung → conflict; **unqualified higher-sum + writer lower-sum on same rung → `unqualified_hook_winner` (not sourcing writer)**; reviewer never sources `.writer.`; opt-inc side effect observed when a colocated opt-inc exists; bound path equals sourced path.

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
| `enforced` | Host sandbox (`bwrap` or recorded equivalent) available and profile verified in step 0 | Writer: RW only staging. Reviewer: project + staging **read-only**; no write binds. Symlink escapes denied by profile. |
| `weakened` | Sandbox unavailable | **Explicitly allowed.** Omits `--force`/`--yolo`/auto-write for reviewer; writer may use force only inside staging cwd. Post-turn inventory (§4a) detects docroot differences. **Does not** prevent command-tool writes, ignored-channel writes, or restores-before-scan. Smoke must print `weakened`. |

Top-level “no reviewer writes” means: **required** under `enforced`; **best-effort detection only** under `weakened`. There is no third “prefer sandbox but claim no writes” state.

If step 0 cannot verify reviewer RO flags **and** cannot run `enforced`, the loop may still run in `weakened` after logging the weaker guarantee (host feasibility records the choice). If the operator requires enforcement, step 0 fails closed—that is a host policy flag for later, default v1 = allow weakened with loud logs.

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

### 6. Ollaya decide contract [P2]

This section is the maintained classifier contract for `agent-plan` (do not defer to a prior draft of this file).

**Transport (truncation = unconditional failure):**

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
| Orchestrator | `make agent-plan` | Validate path, stage, isolate, promote (§3), loop, Ollaya |

### Contrib hooks

| Role | Extension | Files |
|------|-----------|--------|
| `writer` | `scripts/asc/contrib/asc/cursor` | `chat/new.writer.hook.sh`, `chat/reply.writer.hook.sh` |
| `reviewer` | `scripts/asc/contrib/asc/codex` | `chat/new.reviewer.hook.sh`, `chat/reply.reviewer.hook.sh` |

### Loop (summary)

```text
make agent-plan plan:<path> prompt:<file>
  → validate plan path under PROJECT_DOCROOT (§3)
  → create staging; log writer_isolation / reviewer_isolation
  → live_before snapshot
  → chat-new writer (staging)
  → inventory check; flock + recheck + rename promote → live (D0) or live_changed
  → reviewer msg: task + expected response + path + D0 + inlined bytes
  → ollaya (/v1/systemone) per §6
       clean     → success if live digest == D0
       issues    → live_before'; writer; if digest==D0 → stalled_draft
                   else promote D1; reviewer task+bytes for D1; …
       uncertain → one reclassify or needs_human_review
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
| 0 | Host feasibility: sandbox, provider flags, Ollaya model/fixtures, isolation mode choice | Recorded; weakened explicitly logged if used |
| 1 | Chat harness §1–§2 + `CHAT_TYPE` on read/archive + drop pre/post | Ranking/opt-inc/JSON tests green |
| 2 | Cursor writer + staging | Auto; promotion flock/recheck + isolation tests |
| 3 | Codex reviewer | Terra 6.1 High; inlined bytes; enforced or weakened reviewer logged |
| 4 | Ollaya helper + fixtures + truncation | Corpus green |
| 5 | `agent-plan` orchestrator | §3–§8 including live-edit-during-writer |
| 6 | Instance smoke | Success + failure path; mother ignore list unchanged |

This note is not step 0–6.

---

## Related notes

- [27-desktop-agent-terminal-reply.md](../09/27-desktop-agent-terminal-reply.md) — desktop reply client (out of v1).
- [22-agent-llm-entry-point.md](../09/22-agent-llm-entry-point.md) — abstract pivot + contrib hook precedent.
- [21-hook-specificity-rungs.md](../09/21-hook-specificity-rungs.md) — `hook_ms` rungs.

---

## Open tasks

- [ ] After go-ahead: implement §1–§8 as written (including host feasibility step 0).
- [ ] After go-ahead: Cursor writer + Codex reviewer only (no Claude).
- [ ] Pin Ollaya model id; confirm or revise 0.75 against fixtures (K=2 ⇒ p_max 0.875).
- [ ] Record `writer_isolation` / `reviewer_isolation` (`enforced` / `weakened`) on the laptop.
- [ ] Do not add a gates row from this note alone.
- [ ] Do not enable `agent` / `asc/cursor` / `asc/codex` on the mother by default.
