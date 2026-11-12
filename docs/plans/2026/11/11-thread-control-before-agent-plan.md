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

**Orientation:** [preliminary minimal agent control](../../../ideas/2026/11/11-preliminary-minimal-agent-control.md). Draft record of today's wrapper: [agent threads](../../../specs/asc/agent-threads.md). Sibling implementation plan: [agent-plan](10-agent-plan-cursor-codex-ollaya-impl.md).

## Global constraints

- Proposed behavior is labeled proposed. Observed behavior is what the mother code did on 2026-11-11.
- A run id distinguishes records. It does not, by itself, prove that a pid is still that run, and it does not, by itself, make a signal safe.
- Exit 0 from wrap, hold, or stop means the command finished the branch it documents. It does not mean a new run started, a tree exited, or a workload is authorized.
- Each new action documents its own exit codes. The wider exit table in [record conventions](../../../ideas/2026/11/11-record-conventions.md) stays unadopted.
- The model, the writer, and the reviewer do not stop or replace the supervising thread. Sandbox profiles do not grant that.
- No queue, pause, resume, cross-host listing, central ledger, chat copy, `agent-*` rename, or gates change.
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
4. Read a final record that names the writer, the reason, and a completeness value.

The result also says the following, which this plan does not turn into stronger claims:

- Completeness `unknown` or `degraded` is a finished result. It is not permission to operate the same unattended workload under a weaker supervisor.
- A child that has left the unit, a process started through another service, and a remote call are outside a cgroup stop. The probe describes them. It does not promise they stopped.
- Stop does not delete a chat or a plan file. It can interrupt a write, and it leaves in place whatever those files already contain. Their state after stop is whatever a later read observes. Stop is not rollback.
- A hold established under the lock does not cancel a start that has already committed. A hold file created without the lock can still appear inside a start's critical section; the next admission sees it.
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

A lock refusal inside the background supervisor is not the foreground process's exit code. Hold refusal has to be decided before the `&` if the original caller is going to see it.

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
| `stop_requested` | `true` once stop has chosen this run under the record mutex. Otherwise `false`. |
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

A start's foreground process, before `&`:

1. Take `admit.lock`.
2. If `data/threads/hold` exists, release the lock, print a refusal on stderr, exit 3. Do not print `Thread started`.
3. Take the per-entry lock long enough to read the current record.
4. If that record is `running` and its pid identity is still live, release both locks and keep today's pile-up behavior: print the skip line, exit 0.
5. Publish the new run's identity, set `final` to `false`, release both locks, then background the supervisor.

A hold that arrives after step 5 does not cancel that run. A start that has not passed step 5 is refused when it reaches step 2. Creating `data/threads/hold` without `thread-hold` is still noticed at the next step 2, and it can still land inside an in-flight step 1–5. The closed boundary is the pair of actions that share `admit.lock`.

Proposed exit 3 is hold refusal for `thread-wrap` only. Invalid entries stay exit 1. Pile-up skip stays exit 0, and exit 0 still does not mean a new run was started.

### Final record

The supervisor's `EXIT` trap cannot be the writer that survives a kill of the supervisor. `systemd-run` and `systemctl --user stop` can kill that process before the trap runs. SIGKILL does not run the trap.

Proposed writers:

- The supervisor trap writes the final record only when it runs, `stop_requested` is still `false`, and `final` is still `false`. It sets `final_writer` to `supervisor`.
- `thread-stop` is outside the unit. It is the writer for a run it marked `stop_requested`. After the signalled identity is gone, it takes the record mutex and, if `run_id` is still the one it signalled and `final` is still `false`, writes `status: exited`, the signal's exit code when it has one, `stop_reason: stopped`, `final_writer: stop`, and the completeness the decision task assigned.
- If `final` is already `true`, the second writer leaves the closing fields alone.
- If stop is killed after it sets `stop_requested` and before it writes `final`, the record stays `running` with `stop_requested: true`. Readers report that as unfinished. They do not invent `exited`.

Stop sequence, proposed:

1. Take the record mutex. Load the record. Apply the run-id rule above. If signalling will proceed, set `stop_requested` for that `run_id` and copy `pid`, `pid_start`, `unit`, and `invocation_id`. Release the mutex.
2. Immediately before the signal, check that copied identity again. For `subshell`, the pid's start field still matches `pid_start`. For `systemd-user`, `systemctl --user show -p InvocationID --value` on that unit still matches. If it does not, do not signal, and do not write a final record for a different run.
3. Signal the copied identity. Wait until that identity is gone. Do not wait by re-reading the YAML pid, which may already be the next run.
4. Take the record mutex. Write the final record only if the file is still that `run_id` and `final` is `false`. If the file is a newer run, report that the copied identity was the signal target and leave the new record untouched.

A pid can still be recycled between the check in step 2 and the signal call. Copying the identity narrows the window. It does not erase it. `invocation_id` is the check to use when the supervisor is a unit. Completeness stays `unknown` when the signal target was only a pid.

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

Write the note as `changelog/2026/11/11-thread-control-probe.md` when the probe is run, not before. Include the commands, the unit properties shown by `systemctl --user show`, and the process list before and after stop.

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
| `asc/thread/thread.wrap.sh` | Foreground admission; background only after commit; trap calls the function that exists |
| `asc/thread/probe_sleep.sh` | Test-only entry `thread-probe-sleep`. Exits 1 unless `ASC_THREAD_PROBE=1`. One integer argument, 1 through 30. |
| `asc/thread/hold.sh` | `thread-hold on` / `off` under `admit.lock` |
| `asc/thread/stop.sh` | The two stop forms and the outside writer |
| `asc/thread/list.sh`, `asc/thread/status.sh` | Print `run_id`; status uses pid identity |
| `asc/test/core/thread_control.test.sh` | New core tests, batched by `asc/test/core.hook.sh` |
| `asc/test/core/wrap.test.sh` | Existing smokes keep passing |
| `changelog/2026/11/11-thread-control-probe.md` | Created by Task 3 when the probe runs |

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

## Task 2: Hold and foreground admission

**Files:** `asc/thread/hold.sh`, `asc/thread/probe_sleep.sh`, `asc/thread/thread.wrap.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** a hold the original caller can see. Does not stop a committed run.

- [ ] **Step 1: Failing tests**

1. `thread-hold on`, then `thread.wrap.sh` for an entry whose YAML was removed, exits 3, stderr says refused, stdout does not contain `Thread started`, and no background pid from that call is left running.
2. `thread-hold off`, then wrap of a short entry, exits 0 and prints `Thread started`.
3. Add `asc/thread/probe_sleep.sh` (`thread-probe-sleep`). It exits 1 unless `ASC_THREAD_PROBE=1`, and it accepts one integer from 1 through 30. Wrap it for 30 seconds, wait until the YAML `pid_start` matches `/proc/$pid/stat` field 22, then `thread-hold on`. The pid's start field still matches, and the process is still alive. Remove the hold file and the sleeper in teardown.
4. Two entries: hold refused for the second entry as well. Document in the test comment that this uses `admit.lock`, not the per-entry lock.

- [ ] **Step 2: Implement** `hold.sh`, `probe_sleep.sh`, and the foreground sequence in the contract. Leave the long per-entry flock where it is until Task 4. `thread-hold` must be safe to run while that long lock is held.

- [ ] **Step 3: `make make-generate`**, then `make thread-hold` with no arguments prints usage and exits 1.

- [ ] **Step 4: `make test-core` passes.**

## Task 3: Probe the host

**Files:** `changelog/2026/11/11-thread-control-probe.md` (only after the run)

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

- [ ] **Step 5: Write the changelog note** with outputs, the three-pid table, the marker table, and a sentence for work outside the unit (another service, a remote API) that this probe did not run.

- [ ] **Step 6: Decision, in the same note**

| Probe result | Decision |
|--------------|----------|
| Both in-cgroup sleeps are gone and the outside sleep remains, with `KillMode=control-group` shown | A `systemd-user` path may claim completeness `cgroup` for processes that were in the unit |
| `setsid` sleep survives unit stop | Do not claim `cgroup`. Record the `KillMode` that was actually shown |
| User manager unavailable, or the unit fails to start | Systemd is unused. Process-group stop, if anyone still wants it, is a new decision with completeness `degraded` or `unknown`. It does not authorize the real long-running `agent-plan` loop |

## Task 4: Stop forms and the surviving writer

**Depends on:** Task 1, Task 2, and the Task 3 note.

**Files:** `asc/thread/stop.sh`, `asc/thread/thread.inc.sh`, `asc/thread/thread.wrap.sh`, `asc/test/core/thread_control.test.sh`

**Produces:** the two stop forms. Completeness is `cgroup` only when the Task 3 note accepted that claim. Otherwise the supervisor stays `subshell` and completeness stays `unknown`. An `unknown` result is not a process-group tree claim, and it is not permission to operate the real long-running loop.

- [ ] **Step 1: Failing tests, with a sleeper and no requirement that user systemd exist in the test runner**

1. Pass `run:` of an older id after the entry has been replaced. Exit 2. The replacement pid is still alive. The YAML `run_id` is still the replacement.
2. Omit `run:`. Under the mutex, stop copies the current id, sets `stop_requested`, and releases the mutex before signalling. While that sleeper is still alive, a second wrap in `skip` mode exits 0, prints the skip line, and leaves `run_id` unchanged. After stop has written `final`, a new wrap gets a different `run_id`. A fixture that changes `run_id` after `stop_requested` and before the final write is left unchanged by stop.
3. The sleeper holds `data/threads/$entry.occupy.lock` for the whole sleep. `thread-stop` still acquires `data/threads/$entry.lock`, signals, and writes `final_writer: stop`. This is the deadlock test. If it cannot be written without holding the record mutex across the whole run, stop the task.
4. After a final record exists, a second `thread-stop` of the same id does not change `final_writer` or `stop_reason`.
5. Kill the test double that stands in for `thread-stop` after `stop_requested` is `true` and before `final` is `true`. `thread-status` does not print `exited`.

The signal in these tests goes to `thread-probe-sleep` under `ASC_THREAD_PROBE=1`. Completeness in the fixture is `unknown`.

- [ ] **Step 2: Implement** the stop sequence from the contract, the occupy lock, and `wait` mode on that occupy lock. `skip` stays exit 0 when the live identity matches.

- [ ] **Step 3: If the probe decision allows `systemd-user`**, wrap one sleeper entry in a transient unit with the `KillMode` the note recorded, stop it with `thread-stop`, and assert completeness `cgroup` only when a `setsid` child started inside that unit is gone and a sleep outside the unit is still present. Otherwise leave `supervisor` as `subshell` and completeness `unknown`.

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
| Process group and cgroup are different | Task 3 steps 2–3 |
| Final record has to survive the supervisor | Final record; Task 3 step 4; Task 4 test 5 |
| Fallback is a decision | Task 3 step 6; Task 5 |
| Stop is not rollback | Claims and non-claims |
| Tasks 0, 3, 4, and 6 of the other plan | What can proceed beside this plan |
| Lingering is observed, not assumed | Task 3 step 1 |
| Small change is an aim | Status table |
