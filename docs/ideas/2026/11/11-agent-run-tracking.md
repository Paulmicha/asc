# Agent run tracking: what runs, where, and who records it

> **2026-11-13 direction:** [Local action records](13-local-action-records.md) now proposes active thread claims removed after confirmed completion, with old or uncertain claims investigated before reuse. The retained-record and ledger options below are earlier exploration, not the current thread-history direction. ASC-handled chats also have a separate proposed Markdown archive.

- **Date:** 2026-11-11
- **Status:** open idea / comparison. Nothing here is decided or approved.
- **Scope:** how ASC knows which agent work is running, on which host, and where that state is stored.
- **Method:** mother code and docs read on 2026-11-11; earlier review notes kept outside this repository; vendor docs read the same day. One throwaway `systemd-run --user` unit was started to check the journal fields quoted below. Listing and stopping a live unit were not tested.
- **Spec this feeds:** [agent-threads](../../../specs/asc/agent-threads.md)
- **Siblings:** [control actions](11-agent-control-actions.md), [queue and priority](11-agent-queue-and-priority.md), [session stores](11-agent-session-stores.md), [record conventions](11-record-conventions.md)

## Question

A laptop starts agent work. Some steps call a decision model served locally (Ollaya). Some may call a larger model served by a box on the LAN. Later a second machine may start work on its own. Where is the one place to look to see what is running, and what has to exist for that place to be true?

## Three things get called "an agent running"

They need different answers. Mixing them is how a central state manager gets invented.

| Thing | What it is | Who already tracks it | What ASC needs |
|---|---|---|---|
| **Thread** | An OS process tree started from a make entry point on one host. | ASC: `data/threads/$action.yml`. | A record. This is the only one ASC owns. |
| **Session** | A conversation held by a product (Cursor, Codex, Claude Code). It outlives processes and may have none. | The product, in its own store. | A pointer (`provider_session_id`) in the thread or chat result. No copy. |
| **Model server** | A long-lived service answering requests (Ollama, Ollaya, a LAN endpoint). | Its service manager and its own `ps` / `status` verb. | A status probe. No run record. |

A decision-model call is a request lasting milliseconds. It is a line in the trace of the thread that made it, not a run of its own.

## The LAN box is a provider, not a host

Every earlier review reaches the same place by a different road:

- The laptop is the control plane. The LAN box serves inference and keeps no project state.
- Nothing listens for work. A timer may start work; no broker hands it out.
- A hook variant can select the endpoint; the brand of the box does not enter any schema.

If that holds, a thread that talks to the LAN box still runs on the laptop. Its record is local. **The cross-host problem only appears when a second machine starts ASC entry points itself** (a timer on the box, a server). That is a much smaller problem than "unified state", and it is the one to design for.

The motivating case in the request (a small inference appliance behind a single-board computer, serving a large model on the LAN) fits this: the single-board computer exposes an API, the laptop calls it.

## What exists today (observed)

See the spec for the field list. The gaps that matter here:

1. **One record per entry, overwritten.** No run id, no history. Two runs of the same entry cannot be told apart afterwards.
2. **No host field.** The record cannot be merged with another machine's.
3. **Local time without offset.** Records from two machines cannot be ordered.
4. **The host index is latest-only too.** `$HOME/.local/share/asc/threads/<hash>.yml` repeats seven fields of the instance record. It needs a sweep (`thread` `monitor` hook) to stay true, and that sweep is driven by the `crontab` extension, which the mother ignores by default.
5. **Liveness is `kill -0 $pid`.** A reused pid reads as running.
6. **No link to a session.** A thread that drives a chat does not record which one.

## Options

### A. Add two fields, change nothing else

Add `run_id` and `host` to the thread record and the host index. Write timestamps with an offset.

- Cost: a few lines in `thread.wrap.sh` and `f_thread_host_publish`.
- Gives: records that can be merged and ordered.
- Does not give: history.

### B. A plus an append-only run ledger

One JSON line when a thread starts, one when it ends. Never rewritten.

- Where, two candidates:
  - per instance, by making the existing launch line in `data/logs/$action.sidecar.txt` structured and adding an end line. No new file. Cross-project view needs a walk over known instances.
  - per host, `$XDG_STATE_HOME/asc/runs/YYYY/MM/DD.$host.jsonl`. One glob answers "what ran today". One more location to explain.
- One file per day per writing host means no lock, no rotation job, and merging two machines is `cat`.
- The host index YAML files become a derived view (last line per `docroot` + `entry`) and could be dropped.
- Liveness still needs a probe; a ledger says what started, not what is alive.
- A model never writes a ledger line. The wrapper does.

### C. Let `systemd --user` be the supervisor

Start each thread as a transient unit. ASC names it and records the name.

```bash
systemd-run --user --unit="asc-$slug-$action" --collect \
  -p LogExtraFields="ASC_ENTRY=$action" -- make "$action"
```

Observed on this host (systemd 257) with a throwaway unit:

- `--wait` returns the child's exit code.
- The journal keeps start, output, exit status and result per unit, queryable as JSON by `USER_UNIT=` or by a custom field set with `LogExtraFields=`.
- Each start gets an invocation id (`USER_INVOCATION_ID`). That is a free run id.
- `--collect` removes the unit after exit, including failed ones.

From documentation, not tested here: `systemctl --user list-units 'asc-*'` lists live runs, `systemctl --user stop` kills the whole cgroup, slices and `Nice=` set priority, `RuntimeMaxSec=` caps duration, `OnFailure=` can notify. A second start of a loaded unit name is refused, which may replace the `skip` lock.

Limits:

- Runs survive logout only with lingering enabled for the user.
- Unit state is runtime-only. History is the journal, which is size-capped and local.
- `systemctl --user --host=` is refused ("Cannot access user instance remotely"). Another machine is reached with `ssh $host systemctl --user …`.
- No TTY. Interactive harness sessions do not fit.
- Hosts without systemd (containers, other OSes) need the current path anyway. The existing way to hold both is a `hook_ms` variant on `HOST_OS`, the same way `log` `storage` is selected. That is two implementations to keep.

### D. A queue tool as supervisor

`pueue`, `task-spooler`, `nq`. Compared in [queue and priority](11-agent-queue-and-priority.md). They add ordering; they do not add cross-host.

### E. A terminal runtime for interactive sessions

`herdr-core` (`hc`) keeps programs in terminals that survive the window, lists them across machines added over SSH, and takes status from the program through OSC 7501 instead of guessing. `tmux` is the old, boring version of the first half.

- Fits the one case C cannot: an interactive harness a human may take over.
- A new dependency from a young project, with its own daemon. Study only.
- OSC 7501 on its own is cheap: one `printf` from the wrapper, harmless where nothing reads it.

### F. A central store

A database, a collector, a daemon on the LAN. Every review refuses it: nothing listens, live SQLite is never synced, logs are not shipped. Listed so the refusal is on record.

## Comparison

| Need | Today | A | B | C | E |
|---|---|---|---|---|---|
| Tell two runs apart | no | yes | yes | yes (invocation id) | yes |
| History | no | no | yes | journal, capped | no |
| All projects on this host | index, unhealed | same | one glob | `list-units 'asc-*'` | `hc ls` |
| Another host | no | field only | pull files | `ssh … systemctl --user` | `hc machine add` |
| Liveness without a sweep | no | no | no | yes | yes |
| Stop the whole tree | no | no | no | yes (cgroup) | yes |
| New dependency | — | none | none | none on systemd hosts | yes |
| ASC code added | — | small | small | medium, two paths | small glue |

## Cross-host view, if a second machine ever starts work

Pull, do not push. The machine that wants the view asks.

- Files: each machine writes its own day file; the laptop reads them over SSH or from a synced folder. Never sync a file two machines write.
- systemd: `ssh $host systemctl --user list-units 'asc-*' --output=json`.
- Clocks: offsets in every timestamp; `chrony` or equivalent on both ends, or ordering across machines is a guess.
- A fencing token (`run_epoch`) only matters if two machines may run the same entry on the same data. Do not add it before that exists.

## Lean

1. Do A now. It is cheap and every other option needs it.
2. Try C on one long entry before writing B. If the journal is enough history, B is not needed on systemd hosts.
3. If B is written, reuse the sidecar file before adding a host-level tree.
4. Keep the LAN box out of run tracking. Give it a status probe under the existing provider pivots.
5. Emit OSC 7501 from the wrapper only when something reads it.
6. Refuse F.

## Open questions

- Is the unit of record the entry (today) or the run? Everything above assumes the run.
- Does a thread that drives a chat write the `provider_session_id` into its own record, or does the chat result file carry it alone?
- Is `$HOME/.local/share/asc/threads/` state or data? The registry and the proposed needs inbox use `$HOME/.local/state/asc/`.
- Who runs the liveness sweep when the `crontab` extension is off?
- Are unattended agent runs allowed at all? The reviews say not yet. Tracking design should not outrun that.
- Is the journal an acceptable place for run history, given it is capped and excluded from backups?

## Sources

- Code: `asc/thread/`, `asc/log/`, `asc/extensions/crontab/thread/`.
- Plans: [simplify disk entities](../../../plans/2026/11/06-simplify-disk-entities-contracts.md), [host scan](../../../plans/2026/09/20-host-scan-project-instances.md), [XDG state store](../../../plans/2026/09/22-xdg-state-store.md).
- External, read 2026-11-11: systemd issue 24261 (remote user instance refused); `systemd-run(1)`; herdr-core README and command reference; Ollaya CLI reference (`ollaya run … --format json` prints the decision response; the CLI starts its own server when none answers).
