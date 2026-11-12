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
2. Refuse a new start when the hold is established under the admission lock.
3. Stop either the run id they pass, or whichever run is current at the moment stop resolves that choice under the record mutex.
4. Read a final record that names the writer, the reason, and a completeness value, and tell an accepted stop request apart from a confirmed observation.

The result also says the following, which this plan does not turn into stronger claims:

- Completeness `unknown` or `degraded` is a finished result. It is not permission to operate the same unattended workload under a weaker supervisor.
- `stop_requested: true` without `final: true` is an unfinished stop. It is not a delivered signal and not a stopped workload.
- A child that has left the unit, a process started through another service, and a remote call are outside a cgroup stop. The probe describes them. It does not promise they stopped.
- Stop does not delete a chat or a plan file. It can interrupt a write, and it leaves in place whatever those files already contain. Their state after stop is whatever a later read observes. Stop is not rollback. A local process stop is not a provider chat cancel.
- A hold established under the lock does not cancel a start that has already committed. A hold file created without the lock can still appear inside a start's critical section; the next admission sees it. A `wait` caller is not admitted until publish; a hold taken while it waits still refuses that start.
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
| `pid_start` | Field 22 of `/proc/$pid/stat` at publish time. Empty if `/proc` cannot be read, and then liveness is `unknown`. |
| `supervisor` | `subshell` for today's wrapper. `systemd-user` only after Task 4 records a unit the wrapper started. |
| `unit`, `invocation_id` | Empty unless `supervisor` is `systemd-user`. |
| `stop_requested` | `true` once stop has chosen this run under the record mutex. Otherwise `false`. Request only: not proof of signal delivery or of workload exit. |
| `final` | `true` once a writer has committed the closing status. Later writers leave status, exit code, end time, reason, and completeness alone. |
| `final_writer` | `supervisor` or `stop`. |
| `stop_reason` | Empty when the run returns on its own. `stopped` when `stop_requested` was set. |
| `completeness` | `cgroup`, `degraded`, or `unknown`. |

`thread-list` and `thread-status` print `run_id`. List keeps skipping non-YAML names, so a hold file in `data/threads/` is not an entry.

Liveness for `running` is: the recorded pid exists and its `/proc` start field still equals `pid_start`. A live pid with a different start field is a different process. `thread-status` then marks the record `stale`, as it does today when `kill -0` fails. `stale` is not `exited`.

The host index gains `run_id`, `host`, and the offset on `mtime`. It stays latest-only.

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

Paths, proposed:

| Path | Role |
|------|------|
| `data/threads/admit.lock` | Project-wide lock for hold changes and for committing a start. Held only for that critical section, not for the life of the run. |
| `data/threads/hold` | Present means new starts are refused. |
| `data/threads/$entry.lock` | Becomes the short record mutex in Task 4. |
| `data/threads/$entry.occupy.lock` | Held by the supervisor for the whole run, so `ASC_THREAD_LOCK_MODE=wait` still waits for occupancy after Task 4 moves the long hold off `$entry.lock`. |

The per-entry lock does not serialize a project hold against other entries. Hold and start both take `admit.lock` first, and any per-entry lock second. The reverse order is a deadlock.

`thread-hold on` and `thread-hold off` (`asc/thread/hold.sh`) take `admit.lock`, create or remove `data/threads/hold`, and release. Exit 0 when the file matches the request. The action prints that an already committed run keeps running.

#### `skip` mode (default)

A start's foreground process, before the supervisor may do workload work:

1. Take `admit.lock`.
2. If `data/threads/hold` exists, release the lock, print a refusal on stderr, exit 3. Do not print `Thread started`.
3. Take the per-entry lock long enough to read the current record.
4. If that record is `running` and its pid identity is still live, release both locks and keep today's pile-up behavior: print the skip line, exit 0.
5. Create the child under the handshake below, publish the new run's identity, set `final` to `false`, release both locks, then allow the child to begin work.

A hold that arrives after step 5 does not cancel that run. A start that has not passed step 5 is refused when it reaches step 2. Creating `data/threads/hold` without `thread-hold` is still noticed at the next step 2, and it can still land inside an in-flight step 1–5. The closed boundary is the pair of actions that share `admit.lock`.

Proposed exit 3 is hold refusal for `thread-wrap` only. Invalid entries stay exit 1. Pile-up skip stays exit 0, and exit 0 still does not mean a new run was started.

#### `wait` mode

`ASC_THREAD_LOCK_MODE=wait` keeps waiting for occupancy. It is not a durable queue and does not reserve a slot while waiting. Admission and occupancy stay distinct:

1. Take `admit.lock`. If `data/threads/hold` exists, refuse with exit 3 exactly as in `skip`. The waiter is not admitted.
2. Release `admit.lock` before blocking on occupancy. While blocked on `$entry.occupy.lock` (after Task 4 moves the long hold there; until then, on today's long `$entry.lock`), the caller is **not** admitted. A hold established during that wait must still refuse this start when the wait ends.
3. When the occupy lock is acquired, take `admit.lock` again. Recheck `data/threads/hold`. If it is present, release both locks, exit 3, and do not print `Thread started`.
4. Under the record mutex, recheck the current run identity. If a live `running` record for this entry still exists, release both locks and wait on occupancy again (or, if the implementation treats that as skip-after-wait, document that choice in the test; the contract forbids treating a wait that has not published as an admitted run).
5. Only after those rechecks pass does the start enter the handshake and publish. Publication is admission for this run. Until then, `thread-stop` and pile-up readers must not treat the waiter as the current run.

A hold that lands after publication still does not cancel that run. A hold that lands only while the caller was waiting must refuse that caller at step 3. Waiting does not bypass hold, and hold is not a cancel of an already published run.

#### Start handshake

Today the wrapper backgrounds first and only then has `p_pid=$!`. The proposed sequence binds admission to an actual child before that child may run the entry, and before `Thread started` is printed.

Proposed exchange:

| Phase | Who | What becomes true |
|-------|-----|-------------------|
| Create | Foreground, still holding `admit.lock` and the short record mutex | Fork or `systemd-run` the supervisor so its pid (and, for a unit, `unit` / `invocation_id`) is known to the parent. The child must not start the wrapped entry yet. |
| Publish | Foreground | Write `run_id`, `pid`, `pid_start`, `host`, timestamps, `final: false`, and the supervisor fields. Publish is what makes the identity visible to `thread-status`, `thread-stop`, and the host index. |
| Release | Foreground | Release the record mutex and `admit.lock`. |
| Begin | Child | Only after it can observe that its identity was published (or after an explicit parent signal documented in the implementation) may it take the occupy lock for the run and execute the entry. |
| Announce | Foreground | Print `Thread started` only after publish succeeded. |

If either side dies during the exchange:

| Failure | Proposed result |
|---------|-----------------|
| Child dies before publish | Parent does not print `Thread started`. No live `running` record for that attempt. Exit non-zero for the wrap call. |
| Parent dies after create, before publish | Child must exit without starting the entry once it cannot confirm publication within a short bound. No published `run_id`. A leaked child without a record is a bug the tests must catch. |
| Publish writes, then child dies before begin | Record may show `running` briefly; normal-exit or stale marking from Task 1 applies. Stop against that `run_id` is allowed and must not invent success without the stop sequence below. |
| Parent dies after publish, child continues | The published identity is the run. Hold and stop refer to that record. The missing parent is not a rollback. |

`run_id` remains `$started_compact-$pid` with a separate `pid_start` (or `invocation_id`) check. Clone evidence for timestamp-plus-random ids does not replace that shape in this plan.

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
| Pre-signal identity check fails (pid reuse, wrong invocation) | No signal. No final write for another run. Exit 1 (or a documented non-zero for "identity lost before signal"). `stop_requested` may already be true for the id that was current at step 1; readers still treat it as unfinished until a later writer finishes that same id or a replacement run overwrites the file under admission. | Not "signal delivered." Not "workload stopped." |
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

The supervisor must not hold the record mutex for the whole run. If it did, stop would wait on a lock held by the process it needs to signal. Task 4 moves the long hold to the occupy lock and proves, with a sleeper, that stop can take the record mutex while the sleeper still holds the occupy lock.

### Supervisor probe

Task 3 runs this on the host where a long `agent-plan` would run. It uses `sleep` and `setsid`. It does not start `agent-plan`, Cursor, or Codex.

Record the unit settings the probe actually passes. Pass `KillMode=control-group` explicitly. [systemd.kill](https://www.freedesktop.org/software/systemd/man/latest/systemd.kill.html) documents that mode as targeting the remaining processes in the unit's cgroup. A child that calls `setsid` can leave its Unix process group and remain in that cgroup. The probe treats those as different outcomes:

| Descendant | What a matching result shows |
|------------|------------------------------|
| Sleep in the unit, same process group | Unit stop ends it |
| `setsid` sleep, still in the unit cgroup | Unit stop still ends it when `KillMode=control-group` is in effect |
| Sleep started outside the unit, in the probe shell | Unit stop does not end it |

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

- If the cgroup rows matched `KillMode=control-group`, a later `systemd-user` supervisor may record completeness `cgroup` for descendants that were in the unit.
- A process-group implementation is allowed only if the decision says that boundary is acceptable for the operation in question. Its completeness is `degraded` when the signal was a process group and escaped children were not re-checked, and `unknown` when they could not be listed.
- A failed or skipped systemd probe does not authorize the real long-running `agent-plan` loop under the process-group path.

### Artifacts

After any stop, a follow-up read of the plan path and of any chat pointer the run printed is a separate observation. The stop result does not include "unchanged" unless that read happened and was copied into the note.

## File map

| Path | Responsibility |
|------|----------------|
| `asc/thread/thread.inc.sh` | New keys, pid identity check, short record mutex, occupy lock |
| `asc/thread/thread.wrap.sh` | Foreground admission and start handshake; child begins work only after publish; trap calls the function that exists |
| `asc/thread/probe_sleep.sh` | Test-only entry `thread-probe-sleep`. Exits 1 unless `ASC_THREAD_PROBE=1`. One integer argument, 1 through 30. |
| `asc/thread/hold.sh` | `thread-hold on` / `off` under `admit.lock` |
| `asc/thread/stop.sh` | The two stop forms, outside writer, and unfinished-stop retry against the same `run_id` |
| `asc/thread/list.sh`, `asc/thread/status.sh` | Print `run_id`; status uses pid identity; unfinished `stop_requested` is not printed as `exited` |
| `asc/thread/monitor.hook.sh` | Existing host-index consumer. Compatibility: new index fields, identity checks, and older records that lack the new keys |
| `asc/test/core/thread_control.test.sh` | New core tests, batched by `asc/test/core.hook.sh` |
| `asc/test/core/wrap.test.sh` | Existing smokes keep passing |
| `docs/plans/2026/11/11-thread-control-probe.md` | Created by Task 3 when the probe runs |

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

Add a second test that loads a YAML fixture with `status: running`, a dead or reused pid story: write `pid_start` as `1`, point `pid` at `$$` only if `/proc/$$/stat` field 22 is not `1`, and assert `thread-status` prints `stale` and exits 2. Do not use `kill -0` success as "still this run."

- [ ] **Step 2: Run** `. asc/bootstrap.sh` and `make test-core`. Expect the new test to fail. Confirm `asc/test/core/thread_control.test.sh` appears in the batch.

- [ ] **Step 3: Implement** the new keys and the `%:z` timestamps. `type -t u_thread_supervisor_exit` is not `function`; `type -t f_thread_supervisor_exit` is. Point the `EXIT` trap at `f_thread_supervisor_exit`. Keep that trap as the normal-return writer only.

- [ ] **Step 4: `make test-core` passes**, including `asc/test/core/wrap.test.sh`.

## Task 2: Hold, foreground admission, and start handshake

**Files:** `asc/thread/hold.sh`, `asc/thread/probe_sleep.sh`, `asc/thread/thread.wrap.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** a hold the original caller can see, and a published run identity bound to a real child before that child begins the entry. Does not stop a committed run.

- [ ] **Step 1: Failing tests**

1. `thread-hold on`, then `thread.wrap.sh` for an entry whose YAML was removed, exits 3, stderr says refused, stdout does not contain `Thread started`, and no background pid from that call is left running.
2. `thread-hold off`, then wrap of a short entry, exits 0 and prints `Thread started`.
3. Add `asc/thread/probe_sleep.sh` (`thread-probe-sleep`). It exits 1 unless `ASC_THREAD_PROBE=1`, and it accepts one integer from 1 through 30. Wrap it for 30 seconds, wait until the YAML `pid_start` matches `/proc/$pid/stat` field 22, then `thread-hold on`. The pid's start field still matches, and the process is still alive. Remove the hold file and the sleeper in teardown.
4. Two entries: hold refused for the second entry as well. Document in the test comment that this uses `admit.lock`, not the per-entry lock.
5. **Immediate stop during handshake:** after publish of a sleeper and before the child is allowed to begin the entry (or in the first moments after begin, while the record is still the new `run_id`), `thread-stop e:$entry run:$run_id` addresses that published identity. The test fails the contract if stop can only see a pid that exists after today's post-`&` `p_pid=$!` path without a published `run_id`.
6. **Concurrent start:** two wraps of the same entry race under `skip`; at most one publishes a new `run_id` and prints `Thread started`; the other skips or refuses without leaving a second live supervisor for that entry.
7. **Failure before publication:** force the child to exit (or fail to start) before publish completes. The parent does not print `Thread started`, no `running` record for that attempt remains, and no orphan supervisor from that attempt is left running.

- [ ] **Step 2: Implement** `hold.sh`, `probe_sleep.sh`, the foreground admission sequence, and the start handshake in the contract. Leave the long per-entry flock where it is until Task 4. `thread-hold` must be safe to run while that long lock is held.

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

- [ ] **Step 2: Start one transient unit** with an explicit cgroup kill mode. The unit name is local to the probe and uses `--collect`.

```bash
systemd-run --user --unit='asc-probe-stay' --collect \
  -p KillMode=control-group \
  -- "$(command -v sleep)" 300
systemd-run --user --unit='asc-probe-setsid' --collect \
  -p KillMode=control-group \
  -- "$(command -v setsid)" "$(command -v sleep)" 300
"$(command -v sleep)" 120 &
probe_outside_pid=$!
systemctl --user show asc-probe-stay asc-probe-setsid \
  -p Id -p KillMode -p KillSignal -p MainPID -p InvocationID -p ControlGroup
```

For each unit pid, record the process group from `ps -o pid,pgid,cmd` and whether `/proc/$pid/cgroup` contains that unit's cgroup. The `setsid` sleep should show a different process group and the unit cgroup.

- [ ] **Step 3: Stop the two units** with `systemctl --user stop`. Record which of the three pids are gone. The outside `sleep 120` is expected to remain; kill it afterward so the probe does not leave it behind. That cleanup is the probe shell's, and the note says the unit stop did not do it.

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
| Both in-cgroup sleeps are gone and the outside sleep remains, with `KillMode=control-group` shown | A `systemd-user` path may claim completeness `cgroup` for processes that were in the unit |
| `setsid` sleep survives unit stop | Do not claim `cgroup`. Record the `KillMode` that was actually shown |
| User manager unavailable, or the unit fails to start | Systemd is unused. Process-group stop, if anyone still wants it, is a new decision with completeness `degraded` or `unknown`. It does not authorize the real long-running `agent-plan` loop |

## Task 4: Stop forms and the surviving writer

**Depends on:** Task 1, Task 2, and the Task 3 note.

**Files:** `asc/thread/stop.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/thread/monitor.hook.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** the two stop forms, unfinished-stop retry against the same `run_id`, and `wait`-mode admission that rechecks hold after occupancy. Completeness is `cgroup` only when the Task 3 note accepted that claim. Otherwise the supervisor stays `subshell` and completeness stays `unknown`. An `unknown` result is not a process-group tree claim, and it is not permission to operate the real long-running loop.

- [ ] **Step 1: Failing tests, with a sleeper and no requirement that user systemd exist in the test runner**

1. Pass `run:` of an older id after the entry has been replaced. Exit 2. The replacement pid is still alive. The YAML `run_id` is still the replacement.
2. Omit `run:`. Under the mutex, stop copies the current id, sets `stop_requested`, and releases the mutex before signalling. While that sleeper is still alive, a second wrap in `skip` mode exits 0, prints the skip line, and leaves `run_id` unchanged. After stop has written `final`, a new wrap gets a different `run_id`. A fixture that changes `run_id` after `stop_requested` and before the final write is left unchanged by stop.
3. The sleeper holds `data/threads/$entry.occupy.lock` for the whole sleep. `thread-stop` still acquires `data/threads/$entry.lock`, signals, and writes `final_writer: stop`. This is the deadlock test. If it cannot be written without holding the record mutex across the whole run, stop the task.
4. After a final record exists, a second `thread-stop` of the same id does not change `final_writer` or `stop_reason`.
5. Kill the test double that stands in for `thread-stop` after `stop_requested` is `true` and before `final` is `true`. `thread-status` does not print `exited`. Setting `stop_requested` alone must not be treated by the test harness as a delivered signal or a stopped workload.
6. **Retry same identity:** from that unfinished state, `thread-stop e:$entry run:$run_id` with the same recorded id either completes finalization for that id or again leaves a documented unfinished result. It must not exit 0 solely because the pid is missing from a partial check.
7. **Retry must not hit a replacement:** after a new run has published a different `run_id`, `thread-stop e:$entry run:$old_run_id` exits 2 and leaves the replacement alive and unchanged.
8. **`wait` recheck:** while a sleeper holds the occupy lock, start a second wrap with `ASC_THREAD_LOCK_MODE=wait`. During the wait, `thread-hold on`. When the sleeper ends, the waiter must exit 3 (hold refusal) and must not print `Thread started`. A separate case without a hold: after the occupant finishes, the waiter rechecks identity, publishes its own `run_id` only after that recheck, and is not considered admitted while it was only waiting.
9. **Host-index / monitor compatibility:** with a fixture index row and YAML that omit the new keys (`run_id`, `host`, offset on `mtime`, `pid_start`), run the monitor hook path used by `f_thread_monitor_default`. It must not crash, must still heal or refresh using today's readable fields, and after a new publish must accept records that include the new keys. This keeps the existing consumer in the migration analysis; it is not evidence for deleting the index.

The signal in these tests goes to `thread-probe-sleep` under `ASC_THREAD_PROBE=1`. Completeness in the fixture is `unknown`.

- [ ] **Step 2: Implement** the stop sequence from the contract (including the outcome table and retry rules), the occupy lock, and `wait` mode on that occupy lock with the hold recheck after wait. `skip` stays exit 0 when the live identity matches. Adjust `monitor.hook.sh` only as needed for missing new fields and identity checks; do not remove the index.

- [ ] **Step 3: If the probe decision allows `systemd-user`**, wrap one sleeper entry in a transient unit with the `KillMode` the note recorded, stop it with `thread-stop`, and assert completeness `cgroup` only when a `setsid` child started inside that unit is gone and a sleep outside the unit is still present. Otherwise leave `supervisor` as `subshell` and completeness `unknown`. Unit stop still does not claim work outside the unit.

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
| Hold checks need a shared lock, and refusal must reach the caller | Admission and hold; observed baseline; Task 2 |
| Start handshake binds publish to a real child before work | Start handshake; observed baseline; Task 2 tests 5–7 |
| `wait` is occupancy, not admission | Admission `wait` mode; Task 4 test 8 |
| `stop_requested` is not a confirmed stop | Final record outcome table; Task 4 tests 5–6 |
| Unfinished stop retries the same `run_id` only | Retry after an unfinished stop; Task 4 tests 6–7 |
| Host index still has a consumer | Observed baseline; file map; Task 4 test 9 |
| Process group and cgroup are different | Task 3 steps 2–3 |
| Final record has to survive the supervisor | Final record; Task 3 step 4; Task 4 test 5 |
| Fallback is a decision | Task 3 step 6; Task 5 |
| Stop is not rollback | Claims and non-claims |
| Tasks 0, 3, 4, and 6 of the other plan | What can proceed beside this plan |
| Lingering is observed, not assumed | Task 3 step 1 |
| Probe note lives under `docs/plans/` | Supervisor probe; file map; Task 3 |
| Small change is an aim | Status table |
| Clone clues reinforce; they do not replace local IDs, add a daemon or ledger, or extend systemd past the unit | Orientation; start handshake; global constraints; Task 4 step 3 |
