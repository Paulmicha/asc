# Thread control before `agent-plan`

| Field | Value |
|-------|-------|
| **Date** | 2026-11-11 |
| **Status** | Proposed. Not an implementation go-ahead. No unattended or real long-running `agent-plan` operation is authorized by this plan. |
| **Aim** | A small change to the existing thread wrapper: name the run, refuse new starts, and stop a run with a result the operator can read. |
| **Size** | The aim is small. Coordinating admission, run identity, stop, and a final record that survives the stop may be larger than a wrapper edit. If a task below needs a daemon, a run ledger, or a second supervisor, stop and revise this plan. |

**Goal:** Before a real long-running `agent-plan` loop is operated, an operator can name the run, refuse new thread starts, and stop the run that is current when the stop is resolved, with a written result that says what was observed.

**Architecture:** Control stays on the thread wrapper in `asc/thread/`. A thread is the process tree of one make entry on the host that started it. A chat stays in the product that owns it. The plan file is the work product the loop edits, and stop does not roll it back. `agent-plan` consumes this control by being started as a wrapped entry. It does not grow its own supervisor.

**Tech stack:** Bash, the existing thread YAML record, `flock`, and, if the host probe supports it, one transient `systemd-run --user` unit per run. No queue tool, no ledger, no listener.

**Orientation:** [preliminary minimal agent control](../../../ideas/2026/11/11-preliminary-minimal-agent-control.md). Draft record of today's wrapper: [agent threads](../../../specs/asc/agent-threads.md). Sibling implementation plan: [agent-plan](10-agent-plan-cursor-codex-ollaya-impl.md). Clone clues that reinforce this plan without replacing its shape: [clone clues for open decisions](../../../ideas/2026/11/12-clone-clues-for-open-decisions.md). How the earlier drafts relate to this plan: [how the agent drafts were determined](../../../ideas/2026/11/12-how-the-agent-drafts-were-determined.md).

## Global constraints

- Proposed behavior is labeled proposed. Observed behavior is what the mother code did on 2026-11-11.
- A run id distinguishes records. It does not, by itself, prove that a pid is still that run, and it does not, by itself, make a signal safe.
- Exit 0 from wrap, hold, or stop means the command finished the branch it documents. It does not mean a new run started, a tree exited, or a workload is authorized.
- Each new action documents its own exit codes. The wider exit table in [record conventions](../../../ideas/2026/11/11-record-conventions.md) stays unadopted.
- The model, the writer, and the reviewer do not stop or replace the supervising thread. Sandbox profiles do not grant that.
- No queue, pause, resume, cross-host listing, central ledger, chat copy, `agent-*` rename, or gates change. No daemon. Clone examples that use random ids, leases, or HTTP cancel codes do not replace `$started_compact-$pid` plus `pid_start`, the two local stop forms, or the YAML final-record fields in this plan.
- `data/asc/pivots.mk` is generated. Add action files, then `make make-generate`. Do not hand-edit the include. `make cc` keeps the previous include.
- Commit only when asked. Do not enable `agent` on the mother as part of this plan.

## What can proceed beside this plan

From [the agent-plan implementation plan](10-agent-plan-cursor-codex-ollaya-impl.md):

| Work | Relation to this plan |
|------|------------------------|
| Task 1, Task 2, Task 2b, Task 5 | Isolated tests and their implementation can proceed. |
| Task 6 | Implementation and tests that use doubles can proceed. The optional live run, and any real long-running operation of the loop, wait until this plan's probe has a recorded result and the operation's authorization names that result. |
| Task 0, Task 3, Task 4 | These include real provider feasibility or create/resume checks. They are not blocked as host checks. They are not a substitute for thread control, and they are not "short non-live" work. |

## Claims and non-claims

An operator can, once the tasks that establish each claim have passed:

1. Read a run id, a host, and a timestamp with a numeric UTC offset from `data/threads/$entry.yml`.
2. Refuse a new start when the hold is established under the admission lock (direct `thread-wrap` exit 3), or when the slot is **blocked** (direct exit 4), including after status/monitor have only reported a dead supervisor.
3. Stop either the run id they pass, or whichever run is current at the moment stop resolves that choice under the record mutex.
4. Read a final record that names the writer, the reason, and a completeness value, and tell an accepted stop request apart from a confirmed observation.

The result also says the following, which this plan does not turn into stronger claims:

- Completeness `unknown` or `degraded` is a finished result. It is not permission to operate the same unattended workload under a weaker supervisor.
- `stop_requested: true` without `final: true` is an unfinished stop. It is not a delivered signal and not a stopped workload.
- Liveness **blocked** (orphaned, unknown, report-only stale, or `final` with unknown/degraded completeness without `reuse_allowed`) refuses a new start (exit 4 on direct wrap). Status and monitor may report a dead supervisor; they do not authorize reuse. A dead supervisor pid is not proof the workload is gone.
- `final` with completeness `unknown`/`degraded` is an audit result, not slot clearance. Clearance needs `thread-release` or a cgroup-complete final.
- A child that has left the unit, a process started through another service, and a remote call are outside a cgroup stop. The probe describes them. It does not promise they stopped.
- Stop does not delete a chat or a plan file. It can interrupt a write, and it leaves in place whatever those files already contain. Their state after stop is whatever a later read observes. Stop is not rollback. A local process stop is not a provider chat cancel.
- A hold established under the lock does not cancel a start that has already committed. A hold file created without the lock can still appear inside a start's critical section; the next admission sees it. A `wait` caller is not admitted until publish; a hold taken while it waits still refuses that start.
- Caller-visible hold / unknown-liveness exits are for direct `thread-wrap` only. `logged-thread` / `make lt` keeps today's log-wrapper backgrounding; refusal is not claimed as that outer exit code.
- Logout survival of a user unit is unclaimed until a probe that actually ends the login session records it. This plan does not end that session and does not change lingering.

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
| One YAML file per entry, replaced on the next write | `f_thread_yml_write` |
| The host index repeats a latest-only subset | `f_thread_host_publish` |
| The host index is read and healed by the monitor hook | `asc/thread/monitor.hook.sh` (`f_thread_monitor_default`): refreshes from `data/threads/*.yml`, drops ghosts for this docroot, republishes when a `running` index pid is dead |
| Mother default path does not call that hook | `.asc_extensions_ignore` lists `crontab`; the crontab extension's `thread-monitor` caller is therefore not on the mother's default path. Other callers, including instance-only ones, were not surveyed |

A lock refusal inside the background supervisor is not the foreground process's exit code. Hold refusal has to be decided before the `&` if the original caller is going to see it.

Observed today, the foreground parent only learns `p_pid=$!` after backgrounding the supervisor (`asc/thread/thread.wrap.sh`). That is not a published run identity under the admission lock. Task 2 replaces that with the start handshake below.

The trap name and the function name disagree. Task 1's normal-exit test records whether a process that returns on its own ends with `status: exited`. That test does not show what a killed supervisor writes.

## Proposed contract

`$entry` is a make entry point name. `$run_id` is the run id of one start of that entry.

### Record fields

Add these keys in `f_thread_yml_write`, with `ASC_THREAD_*` falling back to the `thread_*` variables loaded from YAML, and in `f_thread_yml_strip_quotes`. `f_thread_yml_mark_stale` rewrites through that path and must keep the new keys.

| Key | Proposed meaning |
|-----|------------------|
| `run_id` | `$started_compact-$pid`. `$started_compact` is UTC `date -u +%Y%m%dT%H%M%S`. `$pid` is the supervisor pid written at the same time. Distinguishes records. |
| `host` | `hostname -s` at start. Written only under `data/threads/` and the host index, which are untracked. |
| `started_ms`, `ended_ms`, host-index `mtime` | `date +%Y-%m-%dT%H:%M:%S.%3N%:z` |
| `pid_start` | Field 22 of `/proc/$pid/stat` at publish time. Empty if `/proc` cannot be read, and then liveness is `unknown`. Admission treats `unknown` as fail-closed (below). |
| `supervisor` | `subshell` for the executable path in this plan. `systemd-user` only after the occupy-handoff feasibility note and Task 4 unit step both pass. |
| `unit`, `invocation_id` | Empty unless `supervisor` is `systemd-user`. |
| `stop_requested` | `true` once stop has chosen this run under the record mutex. Otherwise `false`. Request only: not proof of signal delivery or of workload exit. |
| `final` | `true` once a writer has committed the closing status. Later writers leave status, exit code, end time, reason, and completeness alone. Does not by itself clear the slot unless completeness is `cgroup` (see replaceability). |
| `final_writer` | `supervisor` or `stop`. |
| `stop_reason` | Empty when the run returns on its own. `stopped` when `stop_requested` was set. |
| `completeness` | `cgroup`, `degraded`, or `unknown`. |
| `reuse_allowed` | `true` only after `thread-release` for this `run_id`, or implied by a `final` with completeness `cgroup`. Absent/false means admission stays blocked when the supervisor is gone or the final is uncertain. Status/monitor must not set this. |

`thread-list` and `thread-status` print `run_id`. List keeps skipping non-YAML names, so a hold file in `data/threads/` is not an entry.

Liveness / replaceability for the current record — **reporting** a dead supervisor is not the same as **authorizing** slot reuse:

| Outcome | When | Admission (`skip` or `wait`) |
|---------|------|------------------------------|
| live | Recorded supervisor pid exists and `/proc` start field still equals `pid_start` (or unit `invocation_id` still matches) | Refuse a new start: `skip` prints the skip line and exits 0. `wait` parks on occupancy (below). |
| clear | No file, or the record carries an explicit reuse authorization for that finished identity (below) | May attempt a new publish, still only after acquiring occupy in lock order |
| blocked | Supervisor gone or unreadable, or stop finished with uncertain descendants, and reuse is not yet authorized | **Fail-closed:** exit 4. Includes `orphaned`, `unknown`, reported-`stale` without reuse ack, and `final` with completeness `unknown`/`degraded` without reuse ack |
| orphaned | Subcase of blocked: unfinished/`running` (or equivalent) while the recorded supervisor identity is gone or mismatched | Exit 4. A dead supervisor does **not** prove workload children are gone |
| unknown | Subcase of blocked: empty `pid_start` (legacy), unreadable `/proc`, or identity check incomplete | Exit 4 |

A live pid with a different start field is a different process (orphaned former identity if the file still claims that run).

**Report versus reuse.** `thread-status`, `thread-list`, and the monitor may **report** that the supervisor identity is dead: print it, and under the writer contract they may rewrite display fields such as `status: stale` or `status: orphaned` for that same `run_id`. That rewrite must leave `reuse_allowed` false (or absent). Admission treats any such report-only record as **blocked**, not clear. Checking status or running the monitor must not, by itself, permit a replacement.

**When a new run is permitted** (slot **clear**), exactly one of:

| Evidence | Meaning |
|----------|---------|
| No YAML for the entry | Never started or removed by an explicit operator cleanup outside this plan's default path |
| `final: true` and `completeness: cgroup` for the previous identity | Probe-backed unit path proved in-unit descendants stopped; reuse of the slot is allowed without a separate ack |
| `reuse_allowed: true` for the recorded `run_id`, set only by `thread-release` (below) | Operator acknowledgment that uncertain descendants are accepted or cleaned up out of band |

**`final` with completeness `unknown` or `degraded`.** That is a finished stop/supervisor **record** for the run: useful audit, request-versus-observation closed for the supervisor identity. It does **not** by itself permit a new run. A following start stays exit 4 until `thread-release` authorizes reuse (or a later cgroup-complete final exists on a unit path). Unattended workloads that require tree-wide stop must not treat unknown/degraded final as clearance.

The host index gains `run_id`, `host`, `reuse_allowed`, and the offset on `mtime`. It stays latest-only.

**Recovery when the old workload cannot be proven gone.**

1. Operator may run `thread-stop` on the recorded `run_id` (or current-run form). Stop signals what it can and may write `final` with completeness `unknown` or `degraded`. Descendants are still unproven.
2. Operator inspects (process list, unit cgroup, manual cleanup). This plan does not automate that inspection.
3. Operator runs `thread-release e:$entry run:$run_id` (`asc/thread/release.sh`, pivot after `make make-generate`). Under the record mutex it re-loads, requires the same `run_id`, requires the supervisor identity to be gone or already `final` for that id, sets `reuse_allowed: true` (and may normalize status for readers), refreshes the index, releases. Exit 2 if the file is a different run. Exit 1 if the identity is still live.
4. Only then may admission treat the slot as **clear**.

`thread-status` / monitor are not a substitute for step 3.

### Two stop forms

Both are `asc/thread/stop.sh`, pivot `thread-stop` after `make make-generate`.

| Form | Meaning |
|------|---------|
| `thread-stop e:$entry run:$run_id` | Under the record mutex, signal only if the file's `run_id` is still `$run_id`. If the file has another run, exit 2, signal nothing, write nothing. This is the form to use from a record the operator looked at earlier. |
| `thread-stop e:$entry` | Under the record mutex, read the run id that is current, then signal that identity. This means "stop whichever run is current when stop resolves." It does not mean "stop a pid remembered from an earlier listing." |

Exit codes for this action, proposed here only:

| Exit | When |
|------|------|
| 0 | The stop procedure finished and wrote a result, or found the run already `final` for that same id. Completeness may be `unknown` or `degraded`. |
| 1 | Missing entry, missing record, or unreadable identity. |
| 2 | `run:` was passed and the current record is a different run. |

Exit 0 does not authorize a workload. A caller that requires cgroup completeness treats any other completeness as failure in its own check. `thread-stop` itself still exits 0 when it has recorded `degraded` or `unknown`, so a weaker result stays visible instead of looking like a crashed command.

### Admission and hold

Paths, proposed — the short/occupancy split lands in **Task 2**, not deferred to Task 4.

| Path | Role |
|------|------|
| `data/threads/admit.lock` | Project-wide lock for hold changes and for the short admission critical section. Never held while blocked on occupancy. |
| `data/threads/hold` | Present means new starts are refused. |
| `data/threads/$entry.lock` | Short **record mutex**. Taken only for load / identity check / publish / final / stale rewrite. Not held for the life of the run. |
| `data/threads/$entry.occupy.lock` | **Occupancy** lock. Taken **last** in the admission critical section, then held by the run owner for the whole run after handoff. |

#### One lock order for every path

Both `skip` and `wait` use the same acquisition order. The reverse is a deadlock (including the mixed-mode race where a waiter held occupy while re-taking `admit.lock` while a `skip` holder of `admit.lock` needed occupy):

1. `admit.lock`
2. `$entry.lock` (record mutex)
3. `$entry.occupy.lock` (occupancy) — **only with a non-blocking acquire** while (1) and (2) are held

Blocking waits on occupancy happen **only** after releasing (1) and (2). After a blocking wait returns, the waiter **must unlock occupy immediately** and retry from step 1. Occupy is never held while acquiring or holding `admit.lock`. Publish/handoff holds all three, acquired in that order, then hands occupy to the child and releases admit + record.

Hold actions take only `admit.lock`. They never need occupy. The per-entry locks do not serialize a project hold against other entries.

`thread-hold on` and `thread-hold off` (`asc/thread/hold.sh`) take `admit.lock`, create or remove `data/threads/hold`, and release. Exit 0 when the file matches the request. The action prints that an already committed run keeps running.

#### Shared admission loop (both modes)

Before the supervisor may do workload work:

1. Take `admit.lock`. If `data/threads/hold` exists, release, print refusal on stderr, exit 3. Do not print `Thread started`.
2. Take the record mutex. Classify the current record (table above).
3. If **live**: release admit + record. In `skip`, print the skip line, exit 0. In `wait`, block on occupy, unlock occupy when acquired, go to step 1.
4. If **blocked** (including orphaned, unknown, report-only stale/orphaned without reuse, or final with unknown/degraded completeness without reuse): release both, exit 4.
5. If **clear**: while still holding admit + record, `flock -n` on occupy.
   - Failure in `skip`: release both, print skip (slot busy in handshake or still occupied), exit 0.
   - Failure in `wait`: release both, block on occupy, unlock when acquired, go to step 1.
   - Success: enter the handshake holding admit + record + occupy (order preserved).

A hold that arrives after publish does not cancel that run. A start that has not published is refused when it reaches step 1. Creating `data/threads/hold` without `thread-hold` is still noticed at the next step 1.

Proposed exits for `thread-wrap` only (see logged-path limit below): exit 3 hold refusal; exit 4 blocked slot (orphaned, unknown, report-only stale, or uncertain final without release); invalid entries stay exit 1; pile-up / busy skip stays exit 0, and exit 0 still does not mean a new run was started.

#### Start handshake

Today the wrapper backgrounds first and only then has `p_pid=$!`. The proposed sequence binds admission to an actual child before that child may run the entry, and before `Thread started` is printed. Occupy is already held by the parent (non-blocking acquire in the shared loop) before create.

**Occupancy ownership:**

| Phase | Occupy owner | Notes |
|-------|--------------|-------|
| After step 5 success | parent | Non-blocking acquire while holding admit + record. |
| Create | parent | Child is created. **Executable in this plan:** subshell path — child inherits the occupy fd (same OFD). **Not executable yet:** `systemd-user` unit path — see occupancy handoff gate below; do not implement unit supervision until that gate passes. |
| Publish | parent | Atomic YAML + host-index publish under the writer contract. Occupy stays held. |
| Handoff | child | Parent closes its occupy fd; lock remains with the child's OFD. Parent releases record mutex and `admit.lock` only. |
| Begin | child | Child runs the entry only while it holds occupy, until exit trap / unit end. |
| Announce | child still holds occupy | Parent prints `Thread started` after publish + handoff succeeded. |

Proposed exchange:

| Phase | Who | What becomes true |
|-------|-----|-------------------|
| Create | Foreground, holding admit + record + occupy | Fork or `systemd-run` the supervisor so its pid (and unit fields) are known. Child must not start the entry yet. |
| Publish | Foreground | Atomically write the run identity and refresh the host index from those same bytes (see record writers). |
| Handoff | Foreground → child | Transfer occupy. Release record mutex and `admit.lock` only after handoff. |
| Begin | Child | After observing publication (or an explicit parent signal), execute the entry while holding occupy. |
| Announce | Foreground | Print `Thread started` only after publish and handoff succeeded. |

If either side dies during the exchange:

| Failure | Occupy and record |
|---------|-------------------|
| Child dies before publish | Parent does not print `Thread started`. Parent unlocks occupy. No live `running` record. Exit non-zero. |
| Parent dies after create, before publish | Child exits without starting once publication cannot be confirmed. Child releases occupy. No published `run_id`. |
| Publish writes, then child dies before begin | Record may show `running` briefly → **orphaned** once the supervisor pid is gone; occupy releases when the child exits. Stop may finalize. Admission must not treat orphaned as clear. |
| Stop before begin | Stop targets the published identity. Child holds occupy until it exits; waiters block on occupy only after releasing admit/record, then retry the shared loop. |
| Parent dies after publish and handoff, child continues | Published identity is the run. Child holds occupy. |

`run_id` remains `$started_compact-$pid` with a separate `pid_start` (or `invocation_id`) check. Clone evidence for timestamp-plus-random ids does not replace that shape in this plan.

#### Logged-thread callers

Exit 3 (hold) and exit 4 (unknown liveness) are claimed for a **direct** `thread-wrap` / `make` thread entry that runs `asc/thread/thread.wrap.sh` in the foreground of that call.

They are **not** claimed for `logged-thread` / `make lt`. Observed today, `asc/log/storage.hook.sh` backgrounds the inner script with `nohup … &`, prints `Log started`, and returns success from the outer call. A hold refusal inside the wrapped `thread.wrap.sh` would appear in `data/logs/…` later, not as the original caller's exit status. This plan does not redesign the log wrapper. A Task 2 test documents that limit so it is not mistaken for a regression of the direct-wrap claim.

### Record writers and atomic publish

Today `f_yaml_write_file` in `asc/yml/yml.inc.sh` writes with `printf … > "$p_yml_file"` (truncated in place). An interrupted write can leave a partial record. `f_thread_yml_mark_stale`, `thread-status`, `thread-list`, and the monitor can load a record and later rewrite it without holding the record mutex or re-checking `run_id`, so a replacement published in between can be overwritten as `stale`. The monitor also calls `f_thread_host_publish` from an earlier observation (`asc/thread/monitor.hook.sh`), which can push a stale index row after a newer YAML/index write.

Proposed contract for every read-modify-write of `data/threads/$entry.yml`, for admission publish, and for host-index refresh of that entry:

1. Take the record mutex (`$entry.lock`).
2. Re-load the file (or the bytes about to be replaced).
3. If the write is about a specific `run_id` (stop finalization, supervisor exit, stale mark of a former identity, or a monitor refresh tied to an observed id), proceed only when the file's `run_id` still matches that id. Otherwise leave the YAML and the index alone and release.
4. Build the new document, write it to a temp file on the same filesystem, then `mv -f` onto `data/threads/$entry.yml` (atomic replace).
5. While still holding the record mutex, refresh the host-index row from the **just-written** (or just re-read) fields for that same `run_id` — also via temp+`mv` if the index writer truncates in place today. Do not publish index bytes loaded before step 2.
6. Release the record mutex.

Callers in scope: admission publish, supervisor final write, `thread-stop` final write, `thread-release`, report-only stale/orphaned rewrites from status/list/monitor, and every `f_thread_host_publish` path used by those writers. Pure readers may read without the mutex; any reader that then writes YAML or index must follow this path.

Report-only stale/orphaned rewrites must **not** set `reuse_allowed`. They never clear the slot. `thread-release` is the only writer that sets `reuse_allowed: true` without a cgroup-complete final. Completeness `cgroup` on `final: true` is the only automatic clearance without release.

#### Occupancy handoff gate (`systemd-user`)

The subshell inherited-fd handoff is part of the executable contract (Task 2). The unit path is **deferred**.

Task 3's cgroup probe measures stop scope for descendants. It does **not** prove occupy can be acquired and retained across `systemd-run` creation, parent failure, or unit failure. Until a separate feasibility note records a working handoff (including: parent holds occupy → unit starts → unit retains occupy if parent exits after handoff; parent or unit failure before handoff releases occupy and does not leave a published clear slot; no unlock-to-the-room window), Task 4 must not switch `supervisor` to `systemd-user` and must not claim completeness `cgroup` from wrap.

Write that feasibility note, when run, as `docs/plans/2026/11/11-thread-control-unit-occupy-handoff.md` (same documentation home as the probe). If the note fails or is skipped, the implemented supervisor stays `subshell`. Revising this plan is required before unit supervision ships.

### Final record

The supervisor's `EXIT` trap cannot be the writer that survives a kill of the supervisor. `systemd-run` and `systemctl --user stop` can kill that process before the trap runs. SIGKILL does not run the trap.

Proposed writers:

- The supervisor trap writes the final record only when it runs, `stop_requested` is still `false`, and `final` is still `false`. It sets `final_writer` to `supervisor`.
- `thread-stop` is outside the unit. It is the writer for a run it marked `stop_requested`. After the signalled identity is gone, it takes the record mutex and, if `run_id` is still the one it signalled and `final` is still `false`, writes `status: exited`, the signal's exit code when it has one, `stop_reason: stopped`, `final_writer: stop`, and the completeness the decision task assigned.
- If `final` is already `true`, the second writer leaves the closing fields alone.
- If stop is killed after it sets `stop_requested` and before it writes `final`, the record stays `running` with `stop_requested: true`. Readers report that as unfinished. They do not invent `exited`.

**Request versus observation.** `stop_requested: true` means only that stop chose this `run_id` under the record mutex. It does not mean a signal was delivered, that the workload exited, or that `final` may be assumed. DeerFlow's split between an accepted cancel and a completed run is the prompt for keeping those separate; ASC keeps them as fields on one record rather than as HTTP status codes. A caller that needs a confirmed stop reads `final`, `final_writer`, `stop_reason`, and `completeness` together. `stop_requested` alone is never enough.

Stop sequence, proposed:

1. Take the record mutex. Load the record. Apply the run-id rule above. If signalling will proceed, set `stop_requested` for that `run_id` and copy `pid`, `pid_start`, `unit`, and `invocation_id`. Release the mutex. At this point the operator has an accepted request for that identity, not a confirmed stop.
2. Immediately before the signal, check that copied identity again. For `subshell`, the pid's start field still matches `pid_start`. For `systemd-user`, `systemctl --user show -p InvocationID --value` on that unit still matches. If it does not, do not signal, and do not write a final record for a different run.
3. Signal the copied identity. Wait until that identity is gone. Do not wait by re-reading the YAML pid, which may already be the next run.
4. Take the record mutex. Write the final record only if the file is still that `run_id` and `final` is still `false`. If the file is a newer run, report that the copied identity was the signal target and leave the new record untouched.

A pid can still be recycled between the check in step 2 and the signal call. Copying the identity narrows the window. It does not erase it. `invocation_id` is the check to use when the supervisor is a unit. Completeness stays `unknown` when the signal target was only a pid.

Proposed caller-visible outcomes when the happy path does not finish:

| Case | What the caller sees | What must not be claimed |
|------|----------------------|--------------------------|
| Stop controller dies after `stop_requested`, before final write | Record remains `running` with `stop_requested: true`, `final: false`. Exit of that stop attempt is non-zero or the process is gone. Status readers report unfinished. | Not `exited`. Not completeness of a finished stop. |
| Pre-signal identity check fails (pid reuse, wrong invocation) | No signal. No final write for another run. Exit 1 (or a documented non-zero for "identity lost before signal"). `stop_requested` may already be true for the id that was current at step 1; readers still treat it as unfinished / orphaned until a later writer finishes that same id (`final` or `stale`). Admission must not treat that unfinished row as clear. | Not "signal delivered." Not "workload stopped." |
| Signal syscall / `systemctl` failure | `stop_requested` stays true. No confirmed observation that the target is gone. Exit non-zero. Completeness not written as a successful stop. | Not exit 0 with a quiet partial. |
| Target exits on its own between check and wait | Wait observes the identity gone. Final write may proceed for that same `run_id` if `final` is still false. `stop_reason` stays `stopped` when `stop_requested` was set; the supervisor trap must not overwrite once stop owns finalization, and must not race a second `exited` with a conflicting reason. | Not a claim that the signal caused the exit unless completeness and the wait path recorded that. |
| Wait cannot establish that the target is gone (timeout, unreadable `/proc`, unit state unknown) | Leave `final` false. Report incompleteness to the caller (non-zero or a written `completeness: unknown` only if the contract for that attempt documents an explicit unfinished write — default is: do not set `final`). | Not success inferred from "pid missing in a partial read." |
| `run:` names an id that is no longer current | Exit 2. Signal nothing. Write nothing. | Not a stop of the replacement. |

#### Retry after an unfinished stop

Recovery stays a small explicit contract. It does not add Hermes's queue or lease system; it does reuse the fail-closed idea that a retry continues only against the same recorded run identity.

- A later `thread-stop e:$entry run:$run_id` against the **same** recorded `run_id` that still has `stop_requested: true` and `final: false` is the recovery path. It repeats the identity check, may signal again if the identity is still live, waits again, and may write `final` for that id.
- The same form against a **replacement** run (file `run_id` differs) exits 2, signals nothing, and leaves the new record alone.
- `thread-stop e:$entry` without `run:` on an unfinished record means "stop whichever run is current now." If that current id is still the unfinished one, it is the same recovery. If a new run has already been published, it targets the new run under the current-run form, not the old unfinished id.
- Missing or dead pid is not success. Retry must re-check `pid_start` or `invocation_id`. A gone identity with `final` still false may finalize that same `run_id` only after the wait path has confirmed the copied identity is gone; it must not treat "no pid in the file" or "kill -0 failed once" as proof without that check.
- After `final: true` for that id, a repeated stop of the same id leaves `final_writer` and `stop_reason` alone (already in Task 4).

The supervisor must not hold the record mutex for the whole run. If it did, stop would wait on a lock held by the process it needs to signal. Task 2 introduces the occupy lock and the short record mutex; Task 4 proves, with a sleeper, that stop can take the record mutex while the sleeper still holds occupy.

### Supervisor probe

Task 3 runs this on the host where a long `agent-plan` would run. It uses `sleep` and `setsid`. It does not start `agent-plan`, Cursor, or Codex.

Record the unit settings the probe actually passes. Pass `KillMode=control-group` explicitly. [systemd.kill](https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html) documents that mode as targeting the remaining processes in the unit's cgroup. A child that calls `setsid` can leave its Unix process group and remain in that cgroup. The probe treats those as different outcomes:

| Descendant | What a matching result shows |
|------------|------------------------------|
| Sleep as the unit main process, same process group | Unit stop ends it |
| Child of the unit supervisor that called `setsid`, still in the unit cgroup | Unit stop still ends that child when `KillMode=control-group` is in effect |
| Sleep started outside the unit, in the probe shell | Unit stop does not end it |

The middle row is the claim Task 4's cgroup acceptance test needs. A unit whose **main** command is `setsid sleep` only shows a different session for the main pid; it does not show a supervisor-spawned descendant.

A process launched through another service, and a call that only reaches a remote API, are described in the probe note as outside the unit. The probe does not need a provider CLI to say that.

The same note records who writes a marker after:

- the unit's main process returns on its own;
- `systemctl --user stop` on the unit;
- a forced kill of the main process;
- a crash of the supervisor while a child is still running.

"Stop, then write exited" is one possible outcome of that note. It is not assumed.

Lingering is recorded and left unchanged. The probe runs:

```bash
loginctl show-user "$USER" -p Linger -p State -p Sessions
```

It also records `systemctl --user is-system-running`. It does not log the operator out, and it does not run `loginctl enable-linger` or `disable-linger`. [loginctl](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html) is the reference for the fields. What they mean for a unit after logout stays unclaimed.

Write the note as `docs/plans/2026/11/11-thread-control-probe.md` when the probe is run, not before. That path follows the shared documentation home for task verification and decisions ([documentation specification](../../../specs/asc/documentation.md)); do not place a new dated probe note under `changelog/`. Include the commands, the unit properties shown by `systemctl --user show`, and the process list before and after stop.

### Fallback

A process-group signal is a weaker boundary: a child that has changed process group can survive it. Task 3's `setsid` row is the illustration.

After the probe note exists, Task 3 ends in an explicit decision:

- If the cgroup rows matched `KillMode=control-group` **and** the unit occupy-handoff note has passed, a later `systemd-user` supervisor may record completeness `cgroup` for descendants that were in the unit.
- A process-group implementation is allowed only if the decision says that boundary is acceptable for the operation in question. Its completeness is `degraded` when the signal was a process group and escaped children were not re-checked, and `unknown` when they could not be listed.
- A failed or skipped systemd probe does not authorize the real long-running `agent-plan` loop under the process-group path.

### Artifacts

After any stop, a follow-up read of the plan path and of any chat pointer the run printed is a separate observation. The stop result does not include "unchanged" unless that read happened and was copied into the note.

## File map

| Path | Responsibility |
|------|----------------|
| `asc/thread/thread.inc.sh` | New keys, pid identity / liveness classify, short record mutex, occupy lock, atomic YAML replace helper used by writers |
| `asc/thread/thread.wrap.sh` | Foreground admission and start handshake with occupy handoff; child begins only after publish; never holds `admit.lock` while blocking on occupy; trap calls the function that exists |
| `asc/yml/yml.inc.sh` | Only if the atomic temp+`mv` helper belongs on the shared YAML writer; otherwise keep the replace inside the thread helper and leave other YAML callers unchanged |
| `asc/thread/probe_sleep.sh` | Test-only entry `thread-probe-sleep`. Exits 1 unless `ASC_THREAD_PROBE=1`. One integer argument, 1 through 30. |
| `asc/thread/hold.sh` | `thread-hold on` / `off` under `admit.lock` only |
| `asc/thread/release.sh` | `thread-release e:$entry run:$run_id` — operator ack that sets `reuse_allowed` for a blocked finished/orphaned identity |
| `asc/thread/stop.sh` | The two stop forms, outside writer, unfinished-stop retry against the same `run_id` |
| `asc/thread/list.sh`, `asc/thread/status.sh` | Print `run_id`; report dead supervisor without setting `reuse_allowed`; unfinished `stop_requested` is not printed as `exited` |
| `asc/thread/monitor.hook.sh` | Existing host-index consumer. Report/heal under the writer contract; never sets `reuse_allowed` |
| `asc/test/core/thread_control.test.sh` | New core tests, batched by `asc/test/core.hook.sh` |
| `asc/test/core/wrap.test.sh` | Existing smokes keep passing |
| `docs/plans/2026/11/11-thread-control-probe.md` | Created by Task 3 when the cgroup/stop probe runs |
| `docs/plans/2026/11/11-thread-control-unit-occupy-handoff.md` | Created only if/when the unit occupy-handoff feasibility check is run; required before `systemd-user` supervision |

## Task 1: Normal exit and run identity

**Files:** `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/list.sh`, `asc/thread/status.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** a record that can be told from the next start of the same entry, and a normal-exit write that the test watched. No stop action yet.

- [ ] **Step 1: Failing test** in `asc/test/core/thread_control.test.sh`, same harness style as `asc/test/core/wrap.test.sh`. Use entry `make-list-entry-points`. Delete its YAML first.

```bash
test_thread_normal_exit_records_run_identity() {
  local p_entry='make-list-entry-points'
  local p_yml="data/threads/${p_entry}.yml"
  local i=0

  rm -f "$p_yml"
  asc/thread/thread.wrap.sh "$p_entry" >/dev/null

  for i in $(seq 1 50); do
    if [[ -f "$p_yml" ]]; then
      unset thread_tree_arr
      f_thread_yml_load "$p_entry"
      if [[ "$thread_status" == 'exited' ]]; then
        break
      fi
    fi
    sleep 0.1
  done

  assertEquals 'a process that returns becomes exited' 'exited' "$thread_status"
  assertTrue 'pid is recorded' "[[ -n '$thread_pid' ]]"
  assertTrue 'run_id is UTC compact time, a hyphen, and that pid' \
    "[[ '$thread_run_id' =~ ^[0-9]{8}T[0-9]{6}-${thread_pid}$ ]]"
  assertTrue 'started_ms has a numeric offset' \
    "[[ '$thread_started_ms' == *+[0-9][0-9]:[0-9][0-9] || '$thread_started_ms' == *-[0-9][0-9]:[0-9][0-9] ]]"
  assertTrue 'host is non-empty' "[[ -n '$thread_host' ]]"
  assertTrue 'pid_start was recorded' "[[ -n '$thread_pid_start' ]]"
}
```

Add a second test that loads a YAML fixture with `status: running`, a dead or reused pid story: write `pid_start` as `1`, point `pid` at `$$` only if `/proc/$$/stat` field 22 is not `1`, and assert `thread-status` **reports** the supervisor gone (prints `stale` or `orphaned`, exits 2) without setting `reuse_allowed`. Do not use `kill -0` success as "still this run." Admission clearance for that fixture is Task 2 (still blocked after status alone).

- [ ] **Step 2: Run** `. asc/bootstrap.sh` and `make test-core`. Expect the new test to fail. Confirm `asc/test/core/thread_control.test.sh` appears in the batch.

- [ ] **Step 3: Implement** the new keys and the `%:z` timestamps. `type -t u_thread_supervisor_exit` is not `function`; `type -t f_thread_supervisor_exit` is. Point the `EXIT` trap at `f_thread_supervisor_exit`. Keep that trap as the normal-return writer only.

- [ ] **Step 4: `make test-core` passes**, including `asc/test/core/wrap.test.sh`.

## Task 2: Hold, foreground admission, lock split, and start handshake

**Files:** `asc/thread/hold.sh`, `asc/thread/release.sh`, `asc/thread/probe_sleep.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/status.sh`, `asc/thread/monitor.hook.sh`, `asc/test/core/thread_control.test.sh` (and `asc/yml/yml.inc.sh` only if atomic replace is shared)

**Produces:** a hold the **direct** `thread-wrap` caller can see; short record mutex + occupy lock from this task; subshell occupy handoff; fail-closed admission on blocked slots; `thread-release` as the only non-cgroup clearance path. Does not stop a committed run. Does not implement `systemd-user` supervision.

- [ ] **Step 1: Failing tests**

1. `thread-hold on`, then `thread.wrap.sh` for an entry whose YAML was removed, exits 3, stderr says refused, stdout does not contain `Thread started`, and no background pid from that call is left running.
2. `thread-hold off`, then wrap of a short entry, exits 0 and prints `Thread started`.
3. Add `asc/thread/probe_sleep.sh` (`thread-probe-sleep`). It exits 1 unless `ASC_THREAD_PROBE=1`, and it accepts one integer from 1 through 30. Wrap it for 30 seconds, wait until the YAML `pid_start` matches `/proc/$pid/stat` field 22, then `thread-hold on`. The pid's start field still matches, and the process is still alive. Remove the hold file and the sleeper in teardown.
4. Two entries: hold refused for the second entry as well. Document in the test comment that this uses `admit.lock`, not the per-entry lock.
5. **Hold while a competing start exists:** wrap a long sleeper so the entry is occupied. In parallel, start a second `thread.wrap.sh` of the same entry under `ASC_THREAD_LOCK_MODE=wait` (it must block on occupy, **not** on `admit.lock`). While that waiter is blocked, `thread-hold on` exits 0 promptly. Then unblock/kill the sleeper; the waiter must exit 3 and must not print `Thread started`. This fails today's design if admission can hold `admit.lock` across a long per-entry wait.
6. **Mixed-mode lock order:** with one run holding occupy, start a `wait` wrap that is blocked on occupy. Concurrently start a `skip` wrap of the same entry. Neither call may hang until timeout: `skip` must exit 0 (skip/busy) without holding `admit.lock` while waiting for occupy; when the occupant later releases, `wait` unlocks and retries the shared loop (admit → record → non-blocking occupy) rather than holding occupy while taking `admit.lock`. Use a test timeout shorter than the sleeper to catch deadlock.
7. **Publish before begin + occupy handoff:** wrap a sleeper that can observe a "begin" gate. Parent holds occupy (non-blocking) before publish; after publish the YAML has that `run_id` / `pid` / `pid_start` while the child has not yet started the entry; after handoff the child owns occupy. A racing `wait` wrap blocks only after releasing admit/record, then retries. (The stop against that identity is Task 4.)
8. **Concurrent start:** two wraps of the same entry race under `skip`; at most one publishes a new `run_id` and prints `Thread started`; the other skips or refuses without leaving a second live supervisor for that entry.
9. **Failure before publication:** force the child to exit (or fail to start) before publish completes. The parent does not print `Thread started`, no `running` record for that attempt remains, occupy is not left held by a dead attempt, and no orphan supervisor from that attempt is left running.
10. **Unknown liveness — legacy:** fixture `status: running` with a pid that still `kill -0`s but **no** `pid_start` field. Direct wrap exits 4, does not print `Thread started`, and leaves the fixture unchanged.
11. **Orphaned supervisor — status/monitor do not clear:** fixture `status: running`, `final: false`, `reuse_allowed` absent/false, pid dead / not matching `pid_start`, occupy free. Direct wrap exits 4. Then run `thread-status` and the monitor hook path. Both may report the dead supervisor. Assert `reuse_allowed` is still false/absent. Direct wrap again exits 4 (neither status nor monitor silently authorized reuse).
12. **Release ack clears; final+unknown alone does not:** from a fixture with `final: true`, `completeness: unknown`, `reuse_allowed` false, wrap exits 4. `thread-release e:$entry run:$run_id` sets `reuse_allowed: true` for that id; wrap may then publish. A second release against a different `run_id` exits 2 and does not clear a replacement. Document that release is operator acknowledgment, not proof descendants exited.
13. **Unknown liveness — unreadable:** fixture `status: running` with `pid_start` set but the identity check forced unreadable. Direct wrap exits 4 and does not publish over it.
14. **Logged-thread limit:** under the project's logged-thread / log-wrap path (or a minimal double of `storage.hook.sh`'s `nohup … &` + immediate success), a held project still yields an outer success / `Log started` style result while the inner refusal is only in the log file. The test's comment states that exit 3 is not claimed for this path.

- [ ] **Step 2: Implement** `hold.sh`, `release.sh`, `probe_sleep.sh`, the short record mutex, the occupy lock, the shared admission loop (lock order admit → record → non-blocking occupy; blocking occupy only after release + unlock-and-retry), blocked-slot rules including report-versus-reuse, the subshell start handshake with occupy handoff, and atomic YAML + host-index replace for thread record writes. Adjust status/monitor so report-only rewrites never set `reuse_allowed`. `thread-hold` must complete while a sleeper holds occupy and while a waiter is blocked on occupy.

- [ ] **Step 3: `make make-generate`**, then `make thread-hold` with no arguments prints usage and exits 1.

- [ ] **Step 4: `make test-core` passes.**

## Task 3: Probe the host

**Files:** `docs/plans/2026/11/11-thread-control-probe.md` (only after the run)

**Produces:** a note of observed stop scope and of who wrote the final marker. No change to wrap's supervisor yet.

- [ ] **Step 1: Record lingering without changing it**

```bash
loginctl show-user "$USER" -p Linger -p State -p Sessions
systemctl --user is-system-running
```

Copy the output into the note. Do not run `loginctl enable-linger` or `disable-linger`. Do not log out.

- [ ] **Step 2: Start transient units** with an explicit cgroup kill mode. Unit names are local to the probe and use `--collect`.

```bash
# Main process is sleep (same session / process group as typical unit main).
systemd-run --user --unit='asc-probe-stay' --collect \
  -p KillMode=control-group \
  -- "$(command -v sleep)" 300

# Supervisor is the unit main; it spawns a setsid child, records both pids, then waits.
# Replace the inline script with a tiny probe helper if quoting is painful; the shape matters.
systemd-run --user --unit='asc-probe-setsid-child' --collect \
  -p KillMode=control-group \
  -- "$(command -v bash)" -c '
    setsid "$(command -v sleep)" 300 &
    child=$!
    printf "ASC_PROBE_MAIN=%s ASC_PROBE_CHILD=%s\n" "$$" "$child" > /tmp/asc-probe-setsid-child.pids
    wait "$child"
  '

"$(command -v sleep)" 120 &
probe_outside_pid=$!
systemctl --user show asc-probe-stay asc-probe-setsid-child \
  -p Id -p KillMode -p KillSignal -p MainPID -p InvocationID -p ControlGroup
```

Read `/tmp/asc-probe-setsid-child.pids` (or the helper's output path). For **main** and **child**, record `ps -o pid,pgid,sid,cmd` and whether `/proc/$pid/cgroup` contains that unit's cgroup. The child must show a different session/process group from the supervisor **and** still be in the unit cgroup before stop. The outside sleep must not be in that cgroup.

- [ ] **Step 3: Stop the two units** with `systemctl --user stop`. Record which of: stay main, setsid-child supervisor main, setsid-child descendant, and the outside sleep are gone. The outside `sleep 120` is expected to remain; kill it afterward so the probe does not leave it behind. That cleanup is the probe shell's, and the note says the unit stop did not do it. Decision rows that mention "`setsid` sleep" mean the **spawned child**, not a setsid main.

- [ ] **Step 4: Who writes the marker.** Repeat a short unit four times. The unit command appends `trap` to a marker file from an `EXIT` trap, then sleeps or exits as the case requires.

| Case | How it ends |
|------|-------------|
| Return | Command exits 0 |
| Unit stop | `systemctl --user stop` |
| Forced kill | `systemctl --user kill -s KILL` on that unit, if the user manager accepts it; if it does not, record the refusal and skip the guess |
| Supervisor crash with a child | Main process `kill -9`s itself after forking a sleep; record whether the child is still in the cgroup and whether the trap line appeared |

- [ ] **Step 5: Write the probe note** at `docs/plans/2026/11/11-thread-control-probe.md` with outputs, the three-pid table, the marker table, and a sentence for work outside the unit (another service, a remote API) that this probe did not run.

- [ ] **Step 6: Decision, in the same note**

| Probe result | Decision |
|--------------|----------|
| Stay main and the supervisor-spawned `setsid` child are both gone, outside sleep remains, `KillMode=control-group` shown | Stop-scope evidence for a future `systemd-user` path; **not** by itself an occupy-handoff design. Completeness `cgroup` in wrap still waits on the handoff gate |
| Supervisor-spawned `setsid` child survives unit stop | Do not claim `cgroup`. Record the `KillMode` that was actually shown |
| User manager unavailable, or the unit fails to start | Systemd is unused. Process-group stop, if anyone still wants it, is a new decision with completeness `degraded` or `unknown`. It does not authorize the real long-running `agent-plan` loop |

- [ ] **Step 7 (optional, separate from stop-scope): Unit occupy-handoff feasibility.** Only if pursuing `systemd-user` in a later change. Record acquiring occupy, starting a transient unit, retaining occupy across handoff, and releasing on parent/unit failure before publish. Write `docs/plans/2026/11/11-thread-control-unit-occupy-handoff.md`. This step is not required to finish Tasks 1–2 or the subshell stop path. A failed or skipped handoff note leaves supervision as `subshell`.

## Task 4: Stop forms and the surviving writer

**Depends on:** Task 1, Task 2, and the Task 3 stop-scope note. Unit supervision additionally depends on the Task 3 step 7 handoff note.

**Files:** `asc/thread/stop.sh`, `asc/thread/release.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/monitor.hook.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** the two stop forms, unfinished-stop retry against the same `run_id`, confirmation that `final`+unknown leaves the slot blocked until release, stale-report-versus-replacement safety, and confirmation that Task 2's `wait` / hold / occupy split still holds under stop. The executable supervisor remains `subshell` unless the unit occupy-handoff note passed. Completeness `cgroup` only when both the stop-scope probe and the handoff note accepted that path. An `unknown` completeness result is not a process-group tree claim, not slot clearance, and not permission to operate the real long-running loop.

- [ ] **Step 1: Failing tests, with a sleeper and no requirement that user systemd exist in the test runner**

1. Pass `run:` of an older id after the entry has been replaced. Exit 2. The replacement pid is still alive. The YAML `run_id` is still the replacement.
2. Omit `run:`. Under the mutex, stop copies the current id, sets `stop_requested`, and releases the mutex before signalling. While that sleeper is still alive, a second wrap in `skip` mode exits 0, prints the skip line, and leaves `run_id` unchanged. After stop has written `final` with completeness `unknown`, a new wrap still exits 4 until `thread-release` for that id; after release, a new wrap gets a different `run_id`. A fixture that changes `run_id` after `stop_requested` and before the final write is left unchanged by stop.
3. The sleeper holds `data/threads/$entry.occupy.lock` for the whole sleep. `thread-stop` still acquires `data/threads/$entry.lock`, signals, and writes `final_writer: stop`. This is the deadlock test. If it cannot be written without holding the record mutex across the whole run, stop the task.
4. After a final record exists, a second `thread-stop` of the same id does not change `final_writer` or `stop_reason`.
5. Kill the test double that stands in for `thread-stop` after `stop_requested` is `true` and before `final` is `true`. `thread-status` does not print `exited`. Setting `stop_requested` alone must not be treated by the test harness as a delivered signal or a stopped workload.
6. **Immediate stop on a published identity:** using the Task 2 publish-before-begin arrangement (or the first moments after begin while the record is still that `run_id`), `thread-stop e:$entry run:$run_id` addresses the published identity. Completeness remains whatever this task's supervisor path allows. Occupy ownership stays with the child until it exits.
7. **Retry same identity:** from an unfinished `stop_requested` / not-`final` state, `thread-stop e:$entry run:$run_id` with the same recorded id either completes finalization for that id or again leaves a documented unfinished result. It must not exit 0 solely because the pid is missing from a partial check.
8. **Retry must not hit a replacement:** after a new run has published a different `run_id`, `thread-stop e:$entry run:$old_run_id` exits 2 and leaves the replacement alive and unchanged.
9. **`wait` recheck (regression on Task 2):** while a sleeper holds occupy, start a second wrap with `ASC_THREAD_LOCK_MODE=wait`. During the wait, `thread-hold on` succeeds promptly. When the sleeper ends, the waiter must exit 3 and must not print `Thread started`. A separate case without a hold: after the occupant finishes, the waiter rechecks identity, publishes its own `run_id` only after that recheck, and is not considered admitted while it was only waiting.
10. **Host-index / monitor compatibility:** with a fixture index row and YAML that omit the new keys (`run_id`, `host`, offset on `mtime`, `pid_start`), run the monitor hook path used by `f_thread_monitor_default`. It must not crash; for a still-`running` legacy row without `pid_start`, admission remains fail-closed (exit 4) and monitor/status must not invent a live successor by overwriting. After a new publish of a well-formed record, the monitor accepts the new keys. This keeps the existing consumer; it is not evidence for deleting the index.
11. **Stale-check versus replacement:** load a fixture as if `thread-status` or the monitor had observed an old `running` identity (dead pid). Before the stale write, publish a replacement with a new `run_id`. The stale path, under the record mutex, must re-read, see the new `run_id`, and leave the replacement untouched (not rewritten as `stale`).
12. **Monitor index refresh versus replacement:** let the monitor load observation A for an entry. Before it publishes the host index, admission publishes replacement B (new `run_id`) and updates the index. The monitor's refresh must re-read under the record mutex, see B, and either publish B's fields or skip — it must not write A's pid/status/run_id over B's index row.

The signal in these tests goes to `thread-probe-sleep` under `ASC_THREAD_PROBE=1`. Completeness in the fixture is `unknown`.

- [ ] **Step 2: Implement** the stop sequence from the contract (including the outcome table and retry rules). Confirm occupy handoff and lock order from Task 2 still hold under stop. Wire every thread YAML and host-index read-modify-write through the record mutex + run_id re-check + atomic replace. `skip` stays exit 0 when the live identity matches. Adjust `list.sh`, `status.sh`, and `monitor.hook.sh` for the writer contract and missing new fields; do not remove the index.

- [ ] **Step 3: Unit path only if both Task 3 stop-scope and Task 3 step 7 handoff notes passed.** Then wrap one sleeper entry in a transient unit with the recorded `KillMode`, stop it with `thread-stop`, and assert completeness `cgroup` only when a **`setsid` child spawned by that unit's supervisor** is gone and a sleep outside the unit is still present. Otherwise leave `supervisor` as `subshell` and completeness `unknown` (slot still needs release before replacement unless a future cgroup final applies). Unit stop still does not claim work outside the unit.

- [ ] **Step 4: `make make-generate` and `make test-core`.** The cgroup assertion runs only when Step 3 ran.

## Task 5: What may operate afterward

- [ ] Re-read the probe note. The real long-running `agent-plan` loop stays unauthorized until a human authorization names the completeness value the probe and Task 4 actually produced.
- [ ] A process-group result does not satisfy an authorization written for `cgroup`.
- [ ] Do not start that loop from this task.

## Coverage

| Correction | Where |
|------------|--------|
| Run id is not liveness or a safe signal | Record fields; stop sequence steps 2–4; Task 1 stale test |
| Optional run id has an explicit meaning | Two stop forms; Task 4 tests 1 and 2 |
| Hold checks need a shared lock, and refusal must reach the direct wrap caller | Admission and hold; logged-thread limit; Task 2 tests 1–5, 14 |
| One lock order: admit → record → non-blocking occupy; unlock-and-retry after blocking wait | Admission shared loop; Task 2 tests 5–6; Task 4 test 9 |
| Mixed `skip`/`wait` must not deadlock | Task 2 test 6 |
| Occupy handoff is explicit for subshell; occupy held before publish | Start handshake ownership table; Task 2 test 7; Task 4 test 6 |
| Start handshake binds publish to a real child before work | Start handshake; observed baseline; Task 2 tests 7–9; Task 4 test 6 |
| `wait` is occupancy, not admission | Shared admission loop; Task 2 test 5; Task 4 test 9 |
| Report ≠ reuse; status/monitor do not clear blocked slots | Replaceability table; recovery; Task 1 stale report; Task 2 test 11 |
| `final`+unknown/degraded does not clear; `thread-release` or cgroup final does | Replaceability; Task 2 test 12; Task 4 test 2 |
| Unit occupy handoff is a separate gate; cgroup probe ≠ handoff | Occupancy handoff gate; Task 3 step 7; Task 4 step 3 |
| Every YAML and host-index RMW re-checks `run_id` under the record mutex; publish is atomic | Record writers and atomic publish; Task 4 tests 11–12 |
| Probe middle row is supervisor-spawned `setsid` child | Supervisor probe; Task 3 steps 2–3, 6; Task 4 step 3 |
| `stop_requested` is not a confirmed stop | Final record outcome table; Task 4 tests 5–7 |
| Unfinished stop retries the same `run_id` only | Retry after an unfinished stop; Task 4 tests 7–8 |
| Host index still has a consumer | Observed baseline; file map; Task 4 test 10 |
| Process group and cgroup are different | Task 3 steps 2–3 |
| Final record has to survive the supervisor | Final record; Task 3 step 4; Task 4 test 5 |
| Fallback is a decision | Task 3 step 6; Task 5 |
| Stop is not rollback | Claims and non-claims |
| Tasks 0, 3, 4, and 6 of the other plan | What can proceed beside this plan |
| Lingering is observed, not assumed | Task 3 step 1 |
| Probe note lives under `docs/plans/` | Supervisor probe; file map; Task 3 |
| Small change is an aim | Status table |
| Clone clues reinforce; they do not replace local IDs, add a daemon or ledger, or extend systemd past the unit | Orientation; start handshake; global constraints; Task 4 step 3 |
