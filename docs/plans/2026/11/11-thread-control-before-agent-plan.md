# Thread control before `agent-plan`

| Field | Value |
|-------|-------|
| **Date** | 2026-11-11 (rewritten 2026-11-13) |
| **Status** | Draft. Aligned with active-only claims. Not an implementation go-ahead. No unattended or real long-running `agent-plan` operation is authorized by this plan. |
| **Aim** | A small change to the thread wrapper: name the run, refuse new starts, stop a named or current claim, and clear only when completion is confirmed or an operator has investigated. |
| **Size** | First slice is singleton claims only. If a task needs a daemon, a retained thread ledger, parallel/sequence claim trees, or a second supervisor, stop and revise this plan. |

**Goal:** Before a real long-running `agent-plan` loop is operated, an operator can name a run, refuse new thread starts, stop the claim that stop resolves, tell an accepted stop request from observed completion, and see active claims removed only when it is safe to start again.

**Architecture:** Control stays on the thread wrapper in `asc/thread/`. A thread claim is an **active file** while a start is claimed or the associated work may still be active. On confirmed completion, remove that file; do not keep completed YAML as thread history. Wrapper logs and chat archives are separate (see [local action records](../../../ideas/2026/11/13-local-action-records.md)). The plan file is the work product the loop edits; stop does not roll it back. `agent-plan` consumes this control by being started as a wrapped entry. It does not grow its own supervisor.

**Tech stack:** Bash, active claim YAML under `data/threads/`, atomic claim creation, `flock` where a short critical section is required, and, if a later probe supports it, one transient `systemd-run --user` unit per run. No queue tool, no retained thread ledger, no listener.

**Orientation:** [local action records](../../../ideas/2026/11/13-local-action-records.md) (authoritative for file lifecycle). [preliminary minimal agent control](../../../ideas/2026/11/11-preliminary-minimal-agent-control.md). Draft record of today's wrapper: [agent threads](../../../specs/asc/agent-threads.md). Sibling implementation plan: [agent-plan](10-agent-plan-cursor-codex-ollaya-impl.md). Clone clues: [clone clues for open decisions](../../../ideas/2026/11/12-clone-clues-for-open-decisions.md). How earlier drafts relate: [how the agent drafts were determined](../../../ideas/2026/11/12-how-the-agent-drafts-were-determined.md).

## Global constraints

- Proposed behavior is labeled proposed. Observed behavior is what the mother code did on 2026-11-11 (reconfirm at Task 1).
- Direction for logs, chats, and `data/changes/` lives in the local-action-records idea. This plan does **not** redesign the log wrapper, chat archives, or ignore rules.
- A run id distinguishes claims. It does not, by itself, prove that a pid is still that run, and it does not, by itself, make a signal safe.
- Exit 0 from wrap, hold, stop, or clear means the command finished the branch it documents. It does not mean a new run started, a tree exited, or a workload is authorized.
- The model, the writer, and the reviewer do not stop or replace the supervising thread. Sandbox profiles do not grant that.
- No queue, pause, resume, cross-host listing, central ledger, chat copy, `agent-*` rename, or gates change. No daemon. Clone examples that use random ids, leases, or HTTP cancel codes do not replace `$started_compact-$pid` plus `pid_start` and the two local stop forms.
- First slice: **one concurrent instance per entry** via `data/threads/singleton/$action.yml`. Parallel, sequence, and independently numbered concurrent layouts remain open in the idea; do not implement them here.
- `data/asc/pivots.mk` is generated. Add action files, then `make make-generate`. Do not hand-edit the include. `make cc` keeps the previous include.
- Commit only when asked. Do not enable `agent` on the mother as part of this plan.

## What was discarded (2026-11-13)

This rewrite removes the earlier proposal's incompatible assumptions:

| Discarded | Why |
|-----------|-----|
| Retained final YAML after completion | Thread files are active claims, not history |
| `reuse_allowed` and `thread-release` as flag-on-final clearance | Clearance is remove the claim (or refuse until an operator clears it) |
| One forever path `data/threads/$action.yml` as the only layout | Target layout distinguishes singleton / parallel / sequence / numbered runs |
| Today's `$action.lock` as a permanent design goal | Coordination mechanism remains open; first slice uses atomic claim create plus a short critical section where needed |
| Stop result that exists only as a durable final record | Caller-visible stop outcome and fields on the **active** claim; history, if wanted, belongs in a wrapper log |

Useful caution from the earlier draft is kept: fail-closed admission, stop request ≠ observed completion, status/monitor must not silently authorize a new start, and logged-thread outer exit codes are not the same as direct wrap.

## What can proceed beside this plan

From [the agent-plan implementation plan](10-agent-plan-cursor-codex-ollaya-impl.md):

| Work | Relation to this plan |
|------|------------------------|
| Task 1, Task 2, Task 2b, Task 5 | Isolated tests and their implementation can proceed. |
| Task 6 | Implementation and tests that use doubles can proceed. The optional live run, and any real long-running operation of the loop, wait until this plan's probe has a recorded result and the operation's authorization names that result. |
| Task 0, Task 3, Task 4 | These include real provider feasibility or create/resume checks. They are not blocked as host checks. They are not a substitute for thread control, and they are not "short non-live" work. |

## Claims and non-claims

An operator can, once the tasks that establish each claim have passed:

1. Read a run id, a host, and a start timestamp with a numeric UTC offset from the **active** singleton claim for `$action`.
2. Refuse a new start when the hold is established (direct `thread-wrap` exit 3), or when an active claim still blocks the singleton slot (direct exit 4), including after status has only reported a dead supervisor.
3. Stop either the run id they pass, or whichever claim is current when stop resolves that choice.
4. Tell an accepted stop request (`stop_requested`) apart from a confirmed observation that the signalled identity is gone.
5. See the active claim **removed** after a confirmed normal completion, or after an operator clear once investigation establishes that a new start is safe.

The result also says the following, which this plan does not turn into stronger claims:

- Presence of a claim means an attempt was made and the claim has not been cleared. It does not prove the workload is currently running, that it started successfully, or that its process tree has stopped.
- Age of a claim is a **signal to investigate**. Age alone never deletes the claim, never proves failure, and never authorizes a new start.
- Completeness `unknown` or `degraded` after stop is a finished stop **attempt result** for the caller. It is not permission to operate the same unattended workload under a weaker supervisor, and it does not remove an uncertain claim.
- `stop_requested: true` without a confirmed gone identity is an unfinished stop. It is not a delivered signal and not a stopped workload.
- A dead supervisor pid is not proof the workload is gone. Status and monitor may report; they do not remove the claim and do not authorize a replacement start.
- A child that has left the unit, a process started through another service, and a remote call are outside a cgroup stop. The probe describes them. It does not promise they stopped.
- Stop does not delete a chat or a plan file. Stop is not rollback. A local process stop is not a provider chat cancel.
- Caller-visible hold / blocked-slot exits are for direct `thread-wrap` only. `logged-thread` / `make lt` keeps today's log-wrapper backgrounding; refusal is not claimed as that outer exit code.
- Logout survival of a user unit is unclaimed until a probe that actually ends the login session records it.

## Observed baseline

Read on 2026-11-11. Confirm again at the start of Task 1; line numbers can move.

| Fact | Where |
|------|--------|
| Pile-up skip runs in the foreground and exits 0 | `asc/thread/thread.wrap.sh` around the `f_thread_pileup_should_skip` call |
| The per-entry lock is taken inside `f_thread_supervised_run`, after that function is backgrounded | same file: the function calls `f_thread_lock_acquire`; the caller backgrounds it with `&` |
| The foreground parent then prints `Thread started` and returns | same file, after `p_pid=$!` |
| The `EXIT` trap command is `u_thread_supervisor_exit` | `asc/thread/thread.wrap.sh` |
| The function that writes `status: exited` is `f_thread_supervisor_exit` | `asc/thread/thread.inc.sh` |
| No definition of `u_thread_supervisor_exit` was found under `asc/` | search on 2026-11-11 |
| Liveness is `kill -0` on the recorded pid | `f_thread_pileup_should_skip` and `asc/thread/status.sh` |
| One YAML file per entry under `data/threads/$action.yml`, replaced on the next write | `f_thread_yml_write` |
| The host index repeats a latest-only subset | `f_thread_host_publish` |
| Mother default path does not call the monitor hook | `.asc_extensions_ignore` lists `crontab` |

A lock refusal inside the background supervisor is not the foreground process's exit code. Hold refusal has to be decided before the `&` if the original caller is going to see it.

Today's retained `status: exited` write is **observation of current code**, not the target lifecycle. The target removes the active claim on confirmed completion instead of leaving a completed YAML as history.

## Proposed contract

`$action` is a make entry point name. `$run_id` is the run id of one start of that entry.

### Active claim lifecycle

| Phase | Proposed meaning |
|-------|------------------|
| Absent | No singleton claim. A new start may attempt atomic create (unless hold is on). |
| Create | Atomically create `data/threads/singleton/$action.yml`. Failure means another claim won or the path could not be created; do not clobber. |
| Active | File exists. Presence is the claim. Fields describe the attempt; they are not proof the tree is healthy. |
| Stop requested | `stop_requested: true` on that same active file. Still a claim. |
| Confirmed complete | Supervisor identity gone **and** completion class is one this plan treats as safe to drop (below). **Remove** the claim file promptly. |
| Uncertain | Supervisor gone or unreadable, stop incomplete, interrupt-like end, or age overdue for investigation — **keep** the claim. Refuse new starts. Operator investigates, then `thread-clear`. |

Unlogged calls need not leave historical thread YAML. If output history is wanted, use a `logged-*` wrapper (separate idea; not redesigned here).

### First-slice paths

| Path | Role |
|------|------|
| `data/threads/singleton/$action.yml` | Active singleton claim for `$action` |
| `data/threads/hold` | Present means new starts are refused |
| `data/threads/admit.lock` | Project-wide lock for hold changes and the short admission critical section |

Legacy `data/threads/$action.yml` and `$action.lock` remain today's on-disk shape until migration in Task 2. Parallel / sequence / numbered-run trees from the idea are **out of scope** for this plan.

Migration: when singleton claims ship, stop writing the legacy flat path for new starts; decide in the task whether to move, ignore, or refuse over an existing legacy file for the same `$action`. Do not silently treat a legacy completed `exited` file as an active claim or as clearance.

### Claim fields (while the file exists)

Add or keep these keys while the claim is active. After removal, they are gone with the file.

| Key | Proposed meaning |
|-----|------------------|
| `run_id` | `$started_compact-$pid`. `$started_compact` is UTC `date -u +%Y%m%dT%H%M%S`. `$pid` is the supervisor pid written at create. |
| `host` | `hostname -s` at start. Untracked path only. |
| `started_ms` | `date +%Y-%m-%dT%H:%M:%S.%3N%:z` |
| `pid`, `pid_start` | Supervisor pid and field 22 of `/proc/$pid/stat` at publish. Empty `pid_start` → liveness `unknown` → fail-closed. |
| `supervisor` | `subshell` for the executable path in this plan. `systemd-user` only after probe and occupy/unit handoff notes both pass. |
| `unit`, `invocation_id` | Empty unless `supervisor` is `systemd-user`. |
| `stop_requested` | `true` once stop has chosen this `run_id`. Request only. |
| `last_observation` | Optional short note from stop or status (e.g. completeness class). Not a retained final history after remove. |
| `expected_duration` | Optional. When present, age beyond it is a status signal to investigate. Never auto-deletes. |

`thread-list` and `thread-status` print `run_id` for active claims. List skips non-claim names so a hold file is not an entry.

### Admission (singleton)

| Outcome | When | Direct wrap |
|---------|------|-------------|
| hold | `data/threads/hold` exists under admit | Exit 3; no `Thread started` |
| live | Claim exists; supervisor identity still matches | `skip`: exit 0 with skip line. `wait`: wait for claim removal, then retry admission. |
| blocked | Claim exists; identity gone/unknown, stop unfinished, or uncertain end — and not yet cleared | Exit 4. Status may report; must not remove the claim. |
| clear | No singleton claim (and no conflicting legacy policy from Task 2) | May attempt atomic create under admit |

**Report versus clear.** Status, list, and monitor may report a dead supervisor. They must not remove the claim and must not treat report-only state as permission to create a replacement.

**When the claim may be removed automatically**

| Evidence | Action |
|----------|--------|
| Supervisor trap runs; `stop_requested` still false; wait status exactly `0`; no sticky uncertainty on this run | Remove the singleton claim |
| Stop confirmed the signalled identity is gone **and** completeness is `cgroup` (unit path only, after probes) | Remove the claim |

**When the claim must stay**

| Evidence | Action |
|----------|--------|
| Signal-like wait status `128`–`165`, or other non-zero, with trap | Keep claim; mark observation; new starts exit 4 until `thread-clear` |
| Stop wrote `stop_requested` but completeness is `unknown` / `degraded` | Keep claim until operator clear (or a later cgroup-complete path removes it) |
| Supervisor gone with no successful normal-completion remove | Keep claim (orphaned / unknown); exit 4 until clear |
| Age beyond `expected_duration` (or operator policy when unset) | Status warns; still keep claim; still exit 4 for new starts |

**Retries.** Do not retry wait statuses in `128`–`165`. A later `0` after an earlier uncertain attempt in the same run must not remove the claim. Sticky uncertainty on the active claim blocks automatic remove. Overlap of leftover descendants with a retry of plain `1`–`127` remains an accepted subshell limitation unless a unit/cgroup path proves otherwise.

### Operator clear

`thread-clear e:$action run:$run_id` (`asc/thread/clear.sh`, pivot after `make make-generate`):

1. Under the short critical section, load the singleton claim.
2. Require the same `run_id`. Exit 2 if a different run is claimed. Exit 1 if missing or supervisor identity still live.
3. Remove the claim file and refresh any host-index row for that entry.
4. Exit 0.

Clear is operator acknowledgment after investigation. It is not proof descendants exited. Do not use clear after a normal automatic remove; the file should already be gone.

### Two stop forms

Both are `asc/thread/stop.sh`, pivot `thread-stop` after `make make-generate`.

| Form | Meaning |
|------|---------|
| `thread-stop e:$action run:$run_id` | Signal only if the active claim's `run_id` is still `$run_id`. Otherwise exit 2; signal nothing. |
| `thread-stop e:$action` | Read the current claim's run id, then signal that identity. Means "stop whichever claim is current when stop resolves." |

| Exit | When |
|------|------|
| 0 | Stop procedure finished and reported an observation for that id, or found the identity already gone and recorded that on the claim (or removed it when the cgroup-complete rule applies). Completeness may be `unknown` or `degraded`. |
| 1 | Missing entry, missing claim, or unreadable identity. |
| 2 | `run:` was passed and the current claim is a different run. |

Exit 0 does not authorize a workload and does not imply the claim was removed.

**Request versus observation.** `stop_requested: true` means only that stop chose this `run_id`. A caller that needs a confirmed stop reads that the signalled identity is gone **and** whether the claim was removed or left for investigation. `stop_requested` alone is never enough.

Stop sequence, proposed:

1. Enter the short critical section. Load the claim. Apply the run-id rule. If signalling will proceed, set `stop_requested` and copy `pid`, `pid_start`, `unit`, `invocation_id`. Leave the critical section.
2. Immediately before the signal, re-check the copied identity (`pid_start` or `invocation_id`). If it does not match, do not signal.
3. Signal. Wait until that identity is gone. Do not wait by re-reading a YAML pid that may already be a newer claim.
4. Re-enter the critical section. If the claim is still that `run_id`, record the observation. Remove the claim only under the automatic-remove rules above; otherwise keep it for investigation.

Unfinished stop (`stop_requested` set, identity not confirmed gone): leave the claim. A later `thread-stop … run:$run_id` against the **same** id is the recovery path. Against a replacement id, exit 2.

### Hold and start handshake

`thread-hold on` / `off` take `admit.lock`, create or remove `data/threads/hold`, and release. Exit 0 when the file matches the request. An already committed run keeps running.

Before workload work:

1. Take `admit.lock`. If hold exists, release, refuse (exit 3).
2. Classify the singleton claim (table above). Live → skip or wait. Blocked → exit 4. Clear → continue.
3. Create the supervisor so its pid is known **before** the entry runs. Atomically create the claim with `run_id`, `pid`, `pid_start`, and `stop_requested: false`. On create failure, do not print `Thread started`.
4. Hand off so the child runs the entry only after the claim exists. Print `Thread started` only after create succeeded.
5. On confirmed normal completion, remove the claim. On uncertain ends, keep it.

Exact fd/lock details for waiting without deadlocks are an implementation concern inside Task 2; the contract is: hold must complete while another entry's claim is live; `wait` must not hold `admit.lock` across a long block; two racing creates must not both succeed for the same singleton path.

### Logged-thread callers

Exit 3 and exit 4 are claimed for **direct** `thread-wrap` only. They are **not** claimed for `logged-thread` / `make lt`. Observed today, the log storage hook backgrounds with `nohup … &` and returns outer success. This plan does not redesign that wrapper.

### Atomic claim publish

Today `f_yaml_write_file` truncates in place. Proposed for singleton claims:

1. Build the document.
2. Create with exclusive create (or temp on the same filesystem then link/rename that fails if the target exists) so a concurrent starter cannot clobber.
3. Updates to an existing claim (stop_requested, observation) re-load, require the same `run_id`, then replace atomically.
4. Removal deletes only when the on-disk `run_id` still matches the identity being completed or cleared.

Host-index refresh, if kept, must follow the same `run_id` check and must not resurrect a removed claim.

### Supervisor probe and fallback

Task 3 runs on the host where a long `agent-plan` would run. It uses `sleep` and `setsid`. It does not start `agent-plan`, Cursor, or Codex.

Pass `KillMode=control-group` explicitly. Record three outcomes: unit main ends; supervisor-spawned `setsid` child in the unit cgroup ends; sleep started outside the unit survives.

Write `docs/plans/2026/11/11-thread-control-probe.md` when the probe runs. Lingering is recorded and left unchanged. A process-group fallback, if ever chosen, is completeness `degraded` or `unknown` and does **not** authorize the real long-running `agent-plan` loop.

Unit supervision additionally needs a separate occupy/unit handoff feasibility note before `supervisor` may become `systemd-user`. Until then, stay on `subshell` and do not claim completeness `cgroup` from wrap.

## File map

| Path | Responsibility |
|------|----------------|
| `asc/thread/thread.inc.sh` | Claim paths, identity/liveness classify, atomic create/update/remove helpers |
| `asc/thread/thread.wrap.sh` | Foreground admission, claim create before begin, remove on confirmed normal completion, trap calls the function that exists |
| `asc/thread/probe_sleep.sh` | Test-only `thread-probe-sleep`. Exits 1 unless `ASC_THREAD_PROBE=1`. Optional exit-sequence env for sticky-retry tests |
| `asc/thread/hold.sh` | `thread-hold on` / `off` |
| `asc/thread/clear.sh` | `thread-clear e:$action run:$run_id` — operator removes a blocked claim after investigation |
| `asc/thread/stop.sh` | Two stop forms; unfinished-stop retry against the same `run_id` |
| `asc/thread/list.sh`, `asc/thread/status.sh` | Print `run_id`; report dead supervisor without removing the claim; unfinished stop is not "cleared" |
| `asc/thread/monitor.hook.sh` | Existing host-index consumer; must not clear claims or authorize reuse by rewrite |
| `asc/test/core/thread_control.test.sh` | New core tests under an isolated docroot |
| `asc/test/core/wrap.test.sh` | Existing smokes keep passing; must not mutate live thread/log state when the full core batch is required |
| `docs/plans/2026/11/11-thread-control-probe.md` | Created by Task 3 when the probe runs |
| `docs/plans/2026/11/11-thread-control-unit-occupy-handoff.md` | Optional; required before `systemd-user` supervision |

## Task 1: Normal completion removes the claim

**Files:** `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/probe_sleep.sh`, `asc/thread/list.sh`, `asc/thread/status.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** a fixture entry whose successful wrap creates then **removes** the singleton claim; status can report a dead supervisor without clearing a kept claim. No stop action yet.

**Isolation (required):**

- Use only fixture entries (`thread-probe-sleep`, `zzthreadctlfixt`). Never delete live project entry claims.
- Run hold-sensitive and claim-mutating tests under an **isolated temporary project docroot**. Do not create, delete, or rewrite the live checkout's `data/threads/hold`.
- Before any required full `make test-core` batch: run that batch under the same isolation class, **or** first make `wrap.test.sh` (and any other core test that mutates real `data/threads/` / `data/logs/` for shared entries) fixture-safe. Otherwise stop and revise — do not run the batch against the live tree.

- [ ] **Step 1:** Add and register `asc/thread/probe_sleep.sh` (`thread-probe-sleep`). `make make-generate`. Confirm the entry is recognized.
- [ ] **Step 2:** Failing tests in `asc/test/core/thread_control.test.sh` under the isolated docroot:
  1. Wrap `thread-probe-sleep` 1 with `ASC_THREAD_PROBE=1`. While running (or immediately after publish), the singleton claim exists with matching `run_id` / `pid_start`. After successful completion, the claim file is **gone**.
  2. Fixture claim with dead/mismatched supervisor identity: `thread-status` reports stale/orphaned and does **not** remove the file. A following direct wrap exits 4.
- [ ] **Step 3:** Run the failing tests under isolation. Confirm failures are missing remove-on-success / report-without-clear behavior, not invalid entry.
- [ ] **Step 4:** Implement singleton claim path helpers, `run_id` / offsets / `pid_start`, trap pointing at `f_thread_supervisor_exit`, remove-on-normal-completion, expanded non-retry for `128`–`165`, sticky uncertainty that blocks automatic remove.
- [ ] **Step 5:** Full core batch only under Task 1's safety rule. Passes without mutating live shared entry claims/logs.

## Task 2: Hold, admission, clear, and start handshake

**Files:** `asc/thread/hold.sh`, `asc/thread/clear.sh`, `asc/thread/probe_sleep.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/status.sh`, `asc/thread/monitor.hook.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** hold visible to direct wrap; atomic singleton create; blocked claims until `thread-clear`; publish-before-begin. No unit supervision.

- [ ] **Step 1: Failing tests** (isolated docroot; live hold byte-identical after suite):
  1. `thread-hold on` → wrap exits 3, no `Thread started`, no leftover supervisor from that call.
  2. `thread-hold off` → wrap of probe 1 prints `Thread started` and removes the claim on success.
  3. Two sequential successful wraps of the same fixture: first claim gone before second create; second `run_id` differs; no `thread-clear` required between normal successes.
  4. Hold while a long claim is live: hold exits 0 promptly; sleeper keeps running.
  5. Racing two wraps under `skip`: at most one creates the singleton claim and prints `Thread started`.
  6. Failure before claim create: no `Thread started`, no active claim left for that attempt.
  7. Legacy/unknown identity fixture (running claim, empty `pid_start`): wrap exits 4; file remains.
  8. Orphaned claim: status/monitor report; file remains; wrap exits 4; `thread-clear` for that `run_id` removes it; then a new wrap may create. Clear of a different `run_id` exits 2. Clear while supervisor still live exits 1.
  9. Interrupt outside `thread-stop` (signal-like status): claim kept; following wrap exits 4 until clear.
  10. Sticky uncertainty (`1` then `0` retry with leftover child): claim kept after the run; wrap without clear exits 4; after clear, a new wrap may create. Record the accepted overlap limitation.
  11. Logged-thread limit: outer success / `Log started` while inner refusal is only in the log. Comment states exit 3 is not claimed for that path.
  12. Live hold untouched after suite.
- [ ] **Step 2:** Implement hold, clear, atomic create, admission outcomes, start handshake, migration policy for legacy flat paths, status/monitor report-without-clear.
- [ ] **Step 3:** `make make-generate`; `make thread-hold` with no args prints usage and exits 1.
- [ ] **Step 4:** Full core batch under Task 1 Step 5's safety rule. Passes.

## Task 3: Probe the host

**Files:** `docs/plans/2026/11/11-thread-control-probe.md` (only after the run)

**Produces:** observed stop scope and who wrote markers. No change to wrap's supervisor yet.

- [ ] **Step 1:** Record lingering without changing it (`loginctl show-user`, `systemctl --user is-system-running`).
- [ ] **Step 2:** Start transient units with `KillMode=control-group`: stay main; supervisor that spawns a `setsid` child still in the unit cgroup; outside sleep not in the cgroup.
- [ ] **Step 3:** `systemctl --user stop` both units. Record which pids end. Kill the outside sleep afterward in the probe shell.
- [ ] **Step 4:** Who writes markers on return, unit stop, forced kill, and supervisor crash with a child still running.
- [ ] **Step 5:** Write the probe note with outputs and the three-pid table.
- [ ] **Step 6:** Decision rows: cgroup evidence for a future unit path; or do not claim `cgroup`; or systemd unused. None of these authorize the real long-running `agent-plan` loop by themselves.
- [ ] **Step 7 (optional):** Unit handoff feasibility note before any `systemd-user` supervision.

## Task 4: Stop forms

**Depends on:** Task 1, Task 2, and the Task 3 stop-scope note. Unit supervision also depends on Task 3 step 7.

**Files:** `asc/thread/stop.sh`, `asc/thread/clear.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** both stop forms; unfinished-stop retry against the same `run_id`; uncertain stop leaves the claim until clear; executable supervisor remains `subshell` unless handoff passed.

- [ ] **Step 1: Failing tests** with sleeper fixture (no requirement that user systemd exist in the runner):
  1. `run:` of an older id after replacement → exit 2; replacement still alive.
  2. Omit `run:` → stop targets current claim; while live, second wrap in `skip` skips; after stop with completeness `unknown`, claim remains and wrap exits 4 until `thread-clear`.
  3. Stop can take its critical section and signal while the sleeper still holds the workload; no deadlock that requires holding a mutex for the whole run.
  4. Kill the stop double after `stop_requested` and before identity-gone confirmation → status does not treat the claim as cleared.
  5. Retry same `run_id` may finish observation; retry against a replacement exits 2.
  6. After a normal completion remove (no stop), a `wait` starter can create a new claim without `thread-clear`.
  7. Stale report versus replacement: a stale rewrite must re-read and leave a newer `run_id` untouched; must not remove a newer claim.
- [ ] **Step 2:** Implement the stop sequence. Wire claim create/update/remove through `run_id` checks. Keep report-without-clear on status/monitor.
- [ ] **Step 3:** Unit path only if Task 3 stop-scope and handoff notes passed; otherwise stay `subshell`.
- [ ] **Step 4:** `make make-generate` and full core batch under the isolation rule.

## Task 5: What may operate afterward

- [ ] Re-read the probe note. The real long-running `agent-plan` loop stays unauthorized until a human authorization names the completeness value the probe and Task 4 actually produced.
- [ ] A process-group result does not satisfy an authorization written for `cgroup`.
- [ ] Do not start that loop from this task.

## Coverage

| Correction | Where |
|------------|--------|
| Active claim, not retained final history | Lifecycle; Task 1 |
| Automatic remove only on confirmed safe completion | Admission remove table; Task 1–2 |
| Uncertain / orphaned / stop-unknown keep the claim | Blocked outcome; `thread-clear`; Task 2–4 |
| Age investigates; age never auto-clears | Claims and non-claims; status |
| Singleton first slice only | Global constraints; paths |
| Atomic create; no silent clobber | Claim publish; Task 2 race test |
| Stop request ≠ observed completion | Stop sequence; Task 4 |
| Same-`run_id` stop retry only | Stop forms; Task 4 |
| Status/monitor report ≠ clear | Admission; Task 1–2 |
| Hold + blocked exits for direct wrap only | Logged-thread limit; Task 2 |
| Isolation for tests and full core batch | Task 1 isolation; Tasks 2–4 |
| Probe and handoff before unit/`cgroup` | Task 3–4 |
| Log/chat/`data/changes/` redesign out of scope | Global constraints |
| Real long-running `agent-plan` unauthorized | Status; Task 5 |
