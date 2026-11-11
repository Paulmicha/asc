# Agent control actions: what exists, what is missing

- **Date:** 2026-11-11
- **Status:** open idea / gap list. No action here is approved for implementation.
- **Scope:** the verbs a human needs over running agent work: list, inspect, stop, queue, prioritise, pause, wait, limit.
- **Method:** mother code read on 2026-11-11. Tool behaviour marked "documented" was not run.
- **Spec this feeds:** [agent-threads](../../../specs/asc/agent-threads.md)
- **Siblings:** [run tracking](11-agent-run-tracking.md), [queue and priority](11-agent-queue-and-priority.md)

## Rule for this list

A missing verb is first a question: which existing tool already does it? An ASC action is justified only when it adds the project's naming or records the result. Candidate pivot names are placeholders.

## Verbs

| Verb | Today (observed) | Gap | Cheapest existing tool | Candidate |
|---|---|---|---|---|
| Start | `thread-wrap`, `log-wrap`, `make lt e:$entry` | — | — | — |
| Start many | `thread-batch` (`workers:N`), `thread-sequence`, `thread-pipe` | static lists only | — | — |
| List, this project | `thread-list` | latest run per entry only | — | — |
| List, this host | host index files exist; no action prints them | no reader | `systemctl --user list-units 'asc-*'` if runs are units | `host-thread-list` |
| List, other host | none | — | `ssh $host make thread-list` | no new action |
| Status | `thread-status e:$entry` (exit 0 running, 2 not running, 1 no record) | pid reuse | unit state | — |
| Read output | `data/logs/$entry.txt` | truncated each run | `tail -f`; `journalctl --user -fu` | no new action |
| **Stop** | none | whole verb | `systemctl --user stop`; else `kill` on a process group | `thread-stop e:$entry` |
| **Stop all** | none | whole verb | `systemctl --user stop 'asc-*'` | `thread-stop-all`, or a hold file |
| Pause / resume | none | — | `systemctl --user freeze` / `thaw`; `kill -STOP` / `-CONT` | probably none |
| Wait | poll `thread-status` | — | `systemd-run --wait`; `wait $pid` | none |
| Retry | `ASC_WRAP_RETRY_MAX`, `ASC_WRAP_RETRY_DELAY` | — | — | — |
| Serialise | `ASC_THREAD_LOCK_MODE=wait` | waiters are processes, unordered | see queue idea | — |
| **Queue** | none | whole verb | see queue idea | undecided |
| **Prioritise** | none | two meanings, see below | `nice`, `ionice`, slices; `order:` in gates | undecided |
| Time limit | none | — | `timeout(1)`; `RuntimeMaxSec=` | an env knob on the wrapper |
| Token / cost limit | none | no counter exists | harness flags | later |
| Needs a human | `needs_interactive: true` on exit 75, 126, 130 | nobody is told | `notify-send`; `OnFailure=`; OSC 7501 `blocked` | a `post` hook, not an action |
| Model server up / down | `agent-start`, `agent-stop`, `agent-stop_all`, `agent-status`, `agent-list`, `agent-pull` (abstract pivots; extension off by default) | names read as run control | provider CLIs | rename, see below |

## Stop is the hard one

A harness spawns shells, language servers and sub-agents. Killing the recorded pid leaves the rest.

- Today the command runs in the background with no process group of its own (`nohup … &` in the log storage hook, a backgrounded subshell in the thread wrapper). The recorded pid is the supervising subshell. The record lists the tree as `pid:comm` at start, which is a snapshot.
- Without systemd: start under `setsid`, record the process group, `kill -TERM -- -$pgid`, wait, then `KILL`. Children that change group escape.
- With systemd: one cgroup per unit; `stop` reaches everything. This is the strongest argument for transient units.
- Either way, check the pid still belongs to the run before signalling (start time in `/proc/$pid/stat`, or the unit's invocation id).
- After a stop the wrapper should write `status: exited` with the signal exit code, not leave `running` for the sweep to find.

Stopping the process does not end the product session. The chat stays in the product's store and can be resumed. That is wanted.

## "Stop all" as a file, not a process

The reviews ask for a kill switch (`autonomy: manual`). The smallest form is a hold file the wrapper refuses to start under. It needs no daemon and survives reboot. Its path and name are undecided; it would be the first control that is state rather than a command.

## The `agent-*` names

`agent-stop` today means "unload a model". A reader expects "stop the agent". Three ways out:

1. Leave it; document it. Cheapest, stays confusing.
2. Move provider lifecycle to `llm-*` (the `llm` subject directory already exists, empty). Runs stay `thread-*`. `agent-*` is then free or unused.
3. Give `agent-*` to runs and add `agent-run`, `agent-inspect`, as Projet Complexe sketches. That duplicates `thread-*`.

Lean: 2. A run is a thread; ASC already has the word.

## What should not become an action

- Listing another host. It is the same action over SSH.
- Reading logs. It is `tail` or `journalctl`.
- Pause. Nobody has needed it yet.
- A "dashboard". `thread-list` in `watch` is one.

## Open questions

- Does `thread-stop` take an entry (today's key) or a run id?
- Should a stopped run be `exited` with code 143, or a fourth status `stopped`? The record has `running`, `exited`, `stale`.
- Is the hold file per project, per host, or both?
- Does the time limit belong to the wrapper, or to each entry point that knows its own duration?
- Who is told when a run needs a human, and through what?
