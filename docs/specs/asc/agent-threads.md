---
status: draft
updated: 2026-11-11
---

# Agent threads

Draft. It records what the code does, what earlier plans propose, and what is undecided about tracking and controlling running work. **Observed** means read in the mother code on 2026-11-11. **Proposed** means written in a plan or idea and not implemented. Nothing proposed here is approved.

A **thread** is a process tree started from a make entry point on one host. An agent run is a thread. A product conversation is a [chat](agent-chats.md). A model server is neither.

Reasoning, comparisons and sources: [run tracking](../../ideas/2026/11/11-agent-run-tracking.md), [control actions](../../ideas/2026/11/11-agent-control-actions.md), [queue and priority](../../ideas/2026/11/11-agent-queue-and-priority.md), [record conventions](../../ideas/2026/11/11-record-conventions.md), [loose ends](../../ideas/2026/11/11-agent-tracking-loose-ends.md).

The later [local action records idea](../../ideas/2026/11/13-local-action-records.md) sets the direction for active-only thread files, with target paths for singleton, parallel, sequence and independent concurrent runs. Their existence means an attempt has claimed a slot, and confirmed completion removes them. An unusually old claim calls for investigation, not automatic deletion. The observed paths below remain the current-code inventory; the new layout and lifecycle are not implemented.

## Locations (observed)

| Path | Content | Lifetime |
|---|---|---|
| `data/threads/$action.yml` | thread record | overwritten each run |
| `data/threads/$action.lock` | `flock` lock file, fd 9 | permanent |
| `data/logs/$action.txt` | stdout and stderr | truncated each run; rotated to `.1`, `.2` by `log-rotate` above 1 MiB |
| `data/logs/$action.sidecar.txt` | one launch line per run | appended |
| `$HOME/.local/share/asc/threads/$hash.yml` | host index entry | overwritten; healed by the `thread` `monitor` hook |

`$action` is a make entry point name. Only valid entry points are accepted. `$hash` is the first 16 hex characters of the sha256 of `$docroot::$action`. All of `data/threads/` and `data/logs/` is git-ignored.

## Thread record (observed)

Flat YAML, one record per entry per project.

| Key | Value |
|---|---|
| `entry` | entry point name |
| `owner`, `uid`, `euid`, `run_as`, `sudoing` | who started it |
| `script`, `args` | resolved script and arguments |
| `pid`, `ppid` | supervising subshell and its parent |
| `started_ms`, `ended_ms` | `%Y-%m-%dT%H:%M:%S.%3N`, local time, no offset |
| `status` | `running`, `exited`, `stale` |
| `exit_code` | integer, empty while running |
| `output` | log path, or `nohup.out` when not log-wrapped |
| `attempt`, `max_attempts` | retry counters |
| `lock_mode` | `skip`, `wait` |
| `trigger` | free word, default `manual` |
| `needs_interactive` | `true` when the exit code is 75, 126 or 130 |
| `tree` | list of `pid:comm`, taken at start |

`stale` means the record says `running` and `kill -0 $pid` fails.

## Host index entry (observed)

Keys: `docroot`, `entry`, `pid`, `status`, `owner`, `mtime`, `trigger`. Written with each thread record unless `ASC_MONITORING` or `ASC_HOST_THREAD_MONITOR` is off.

## Log sidecar line (observed)

```text
$datestamp : $human_user (euid=$euid) : $script $args
```

## Environment (observed)

| Variable | Default | Effect |
|---|---|---|
| `ASC_THREAD_LOCK_MODE` | `skip` | `skip` drops a second start; `wait` blocks on the lock |
| `ASC_WRAP_RETRY_MAX` | `0` | extra attempts; none after exit 0, 130, 143 |
| `ASC_WRAP_RETRY_DELAY` | `10s` | pause between attempts |
| `ASC_THREAD_TRIGGER` | `manual` | recorded as `trigger` |
| `ASC_WRAP_EMITTER`, `ASC_WRAP_RECEIVER`, `ASC_WRAP_KIND` | `manual`, `$action`, `thread-wrap` | exported to the child |
| `ASC_MONITORING`, `ASC_HOST_THREAD_MONITOR` | on | host index publish and sweep |

A wrapped command runs with stdin from `/dev/null`, `ASC_WRAP_NONINTERACTIVE=1` and `GIT_TERMINAL_PROMPT=0`. Entry points marked `@requires interactive` are refused.

## Actions (observed)

| Action | Contract |
|---|---|
| `thread-wrap` | start one entry in the background and write its record |
| `log-wrap` | start one entry with output in `data/logs/` |
| `logged-thread` (`lt`), `logged-batch` (`lb`), `logged-sequence` (`ls`), `logged-pipe` (`lp`) | log wrap around the thread action of the same name |
| `logged-chain` (`lc`) | log wrap around `asc/instance/chain.sh` |
| `thread-list` | table: entry, pid, owner, status, started, last update, output |
| `thread-status e:$action` | exit 0 running, 2 not running, 1 no record |
| `thread-batch e:$action a:$arg workers:$n` | waves of at most `$n`; worst exit code |
| `thread-sequence`, `thread-pipe` | fixed lists |
| `log-rotate` | size-based rotation |

Provider lifecycle pivots (`agent-list`, `agent-pull`, `agent-start`, `agent-status`, `agent-stop`, `agent-stop_all`) are abstract hook calls in the `agent` extension, which is ignored by default. They address model servers, not threads.

## Limitations (observed)

- One record per entry. No run identifier, no history.
- No host in any record. Timestamps cannot be ordered across machines.
- Liveness by pid only.
- No stop, queue, priority, time limit or cross-project listing action.
- The host index is corrected only by a sweep that the default configuration does not run.
- No link from a thread to a chat.

## Proposed, not decided

| Topic | Candidates | Lean in the ideas |
|---|---|---|
| Unit of record | entry (today); run | run |
| Run identifier | `$started_compact-$pid`; systemd invocation id; ULID or UUIDv7 | first |
| Host field | short hostname; a name from the host registry | undecided; never in tracked files |
| Timestamps | add the UTC offset | yes |
| History | Active thread files are removed after confirmed completion; a separate logged-wrapper output may remain | No retained completed thread record in the new direction; optional log completion metadata remains open |
| Supervisor | background subshell (today); `systemd-run --user` transient unit; a queue daemon; a terminal runtime | try transient units on one long entry |
| Host index location | `.local/share` (today); `.local/state` with the registry | undecided |
| Stop | `thread-stop e:$action`: process group signal, or unit stop | needed; cgroup is the reliable form |
| Stop all | unit glob; a hold file the wrapper refuses to start under | undecided |
| Queue | `flock` wait (today); a queue tool; a spool directory and timer | none until a waiting list exists |
| Priority | resource weight (`nice`, slices); order in the backlog | weight first |
| Other hosts | pull over SSH; per-host files merged by the reader | pull; no listener |
| LAN inference endpoint | a provider selected by hook variant or configuration; status probe only | not a tracked host |
| Status signal | OSC 7501 from the wrapper | only when something reads it |
| Provider pivot names | keep `agent-*`; move to `llm-*` | move |

Constraints carried from earlier reviews: the control host owns state; nothing listens for work; a timer may start work, no broker; a model never writes a record; unattended agent runs are not yet allowed.

## Related

- Plans: [simplify disk entities](../../plans/2026/11/06-simplify-disk-entities-contracts.md), [host scan of project instances](../../plans/2026/09/20-host-scan-project-instances.md), [XDG state store](../../plans/2026/09/22-xdg-state-store.md), [concert order](../../plans/2026/09/25-concert-order.md).
- Code: `asc/thread/`, `asc/log/`, `asc/instance/logged/`, `asc/extensions/crontab/thread/`, `asc/extensions/agent/agent/`.
