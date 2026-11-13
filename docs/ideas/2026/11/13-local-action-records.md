# Local action logs, chat archives, and thread state

| Field | Value |
|-------|-------|
| **Date** | 2026-11-13 |
| **Status** | Idea in progress. Paths for wrapper logs and chat archives express the current direction; concurrency, migration, and implementation details remain open. This is not an implementation go-ahead. |
| **Scope** | Local files produced around ASC actions: captured process output, ASC-handled agent conversations, and running thread state. Deprecate the old `data/changes/` layout. |

`$action` means the wrapped ASC make entry point; `$entry` is the same kind of
name in existing thread code. Paths are relative to the project docroot unless
explicitly stated otherwise. A host is the machine running the work, such as a
laptop or Raspberry Pi.

## Four distinct things

| Thing | Purpose | Proposed or current home |
|-------|---------|--------------------------|
| Wrapper log | Combined stdout and stderr of one logged launch, for inspection and troubleshooting | Proposed dated file under `data/logs/` |
| Chat archive | Prompts and replies handled by ASC, for a human to read as a conversation | Proposed Markdown under `data/agent/chats/` |
| Thread state | Identify and control running thread-wrapped work on the host | Currently one YAML record and lock per project entry under `data/threads/`, plus a host index |
| Action work product | Whatever the action itself creates, such as a plan or an export | Owned by that action, not by the log wrapper |

One launch can have all four. A wrapper log is an **additional file**; it does
not replace a chat archive or a plan. A chat may span several process runs; a
run can create or use more than one chat. A log is not the authority for whether
a process is alive, and a chat archive is not a process-control record.

## Logged actions: one output file per launch

The direction for every `logged-*` action, including `logged-thread` (`lt`), is
to capture stdout and stderr together in a new local text file:

```text
data/logs/YYYY/MM/DD/$action/HH-MM-SS-MS.txt
data/logs/2026/11/13/agent-plan/14-05-09-123.txt
```

`$action` identifies the wrapped entry point, not the `lt` alias. Each launch
gets its own file, so a later launch does not truncate the previous output.
The wrapper should tell the caller the exact path and, when a thread record is
available, record that path there. `.txt` describes captured output without
assuming arbitrary output is Markdown. Stdout and stderr share one destination;
the result is not a guarantee that the two streams can later be separated or
that concurrently written bytes are neatly grouped by child.

This capture is the wrapper's responsibility. Calling an action directly
continues to show its output normally and does not create a **wrapper log**;
the action may independently create its own files, including a chat archive.
The idea does not require an unwrapped action to suppress its own output or
change its own work products.

**Current code:** the default [storage hook](../../../../asc/log/storage.hook.sh)
backgrounds the wrapped call with `nohup`, redirects both streams to
`data/logs/$entry.txt`, and appends a launch line to
`data/logs/$entry.sidecar.txt`. A later launch normally truncates that output;
the log wrapper first skips a start it detects as already running. `make lt`
returns after starting the background wrapper and does not return the eventual
wrapped action's exit status. The existing
[smoke test](../../../../asc/test/core/wrap.test.sh) covers a log/thread
composition, not this dated scheme or the complete `logged-*` family. This is
an observation from code, not a new runtime test.

The [disk inventory](../../../plans/2026/11/06-simplify-disk-entities-contracts.md)
describes the old files and previously proposed keeping them. This idea changes
that direction; it does not itself change the writer. The
[thread-control plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md)
explicitly keeps the current logged-wrapper exit limitation and does not
implement this log redesign.

### Log design still to resolve

- **Compositions:** a batch, sequence, pipe, chain, or loop may wrap several
  entries or a wrapper action rather than a single target. Define `$action`
  for each and whether it produces one consolidated launch log, per-child logs,
  or both. Do not assume the current log wrapper accepts every composition in
  the same way as `lt`; inspect and test each actual call path.
- **Unique creation:** two launches can share the same millisecond. Choose a
  collision suffix and atomic no-overwrite creation; never silently clobber an
  earlier log. Specify timezone, clock changes, and date ownership.
- **Start versus completion:** decide whether and how launch rejection, a
  failed log creation, exit status and eventual completion reach the caller
  and/or a record. The present outer `lt` success is not the child's success.
  Do not imply the dated filename alone fixes that contract.
- **Old files and retention:** decide how to handle existing `*.txt`,
  `*.sidecar.txt`, and `.1` / `.2` files, and whether `log-rotate` should
  change. Per-launch files avoid truncation but need an explicit retention
  decision; there is no automatic deletion in this idea.
- **Naming and path safety:** validate entry names and test paths, concurrent
  output, missing directories, write errors, and caller-visible path reporting.
  Keep remote service logs distinct from wrapper launches.

## ASC-handled chats: a separate Markdown archive

The direction is for `chat-new` to create a human-readable conversation file:

```text
data/agent/chats/YYYY/MM/DD/HHhMMmSS.$subject.md
data/agent/chats/2026/11/13/14h05m09.revise-agent-chat-actions.md
```

The short, filename-safe subject describes the conversation. `chat-reply`
continues the same file, recording prompts and replies in order. This archive
is for human review and does not need a machine-consumption format. It is
written from the turns ASC handles, not copied from a provider's private store;
it cannot claim turns made outside ASC. Failed or incomplete turns must be
distinguishable without inventing a reply. The chat actions' proposed JSON
stdout remains separate from the archive.

The [chat spec](../../../specs/asc/agent-chats.md) and
[agent-plan design](10-agent-plan-cursor-codex-ollaya.md) describe this proposal.
The [implementation plan](../../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md)
keeps a design gate for subject and collision handling, matching replies to the
same archive and provider session across invocations, concurrency, failures,
and recovery. In particular, the chat harness in `agent-plan` runs inside a
sandbox that cannot write the live project: an outside-orchestrator handoff
must be designed and tested without weakening that boundary. Do not blindly
repeat a provider turn merely because recording it failed.

## Deprecate `data/changes/`

The imagined `data/changes/` hierarchy, including its `agent/accepted`,
`agent/iterate`, `agent/rejected`, `agent/review`, and `human/inbox` branches,
is deprecated and should be removed from the current layout and `.gitignore`
in a later implementation change. Do not introduce new producers there.

This supersedes the location in the older
[agent review feedback note](../../../plans/2026/09/20-agent-review-feedback-home.md),
which proposed `data/changes/agent/review/` for write-watcher notes. It does
not decide a replacement home for those notes or authorize deleting existing
files. Before removing ignore rules, inspect the instance for existing ignored
data and account for its migration or retention: removing a rule can expose
previously ignored files to Git. Other ASC instances may have their own data;
this mother note does not migrate them.

## Thread state and concurrency: advice

**Current shape.** `data/threads/$entry.yml` is a latest-only record and
`data/threads/$entry.lock` is an entry lock within one project instance. The
wrapper uses PID-based checks. A host index under the user's home is keyed by
project docroot and entry, but the mother configuration does not run its
monitor automatically. The [thread spec](../../../specs/asc/agent-threads.md)
records the observed fields and limits. A record or PID alone is not proof
that the original process tree has stopped.

**Composition is different from tracking.** `thread-batch` launches its
specified Make steps concurrently in bounded waves; `thread-sequence` runs
steps in order. Those helpers invoke Make directly: the presence of a batch
does not mean each child is independently `thread-wrap`-tracked. The current
`skip` / `wait` entry lock controls repeated launches of an entry; it is not
a durable, ordered queue or a general limit across unrelated entries.

**Recommendation.** Keep the current small, single-run-per-entry thread
control plan as a first step. Different entries can run concurrently, and a
batch can run its children concurrently within its existing bound. Keep
sequential composition explicit where ordering matters. Separate these
questions before adding new storage:

1. **Identity:** if two independent runs of the *same* entry must be tracked
   concurrently, each needs its own run identity and independently addressable
   status. One `$entry.yml` cannot represent both. A run ID must be checked
   against process identity before signalling; a filename or PID alone does
   not establish it.
2. **Admission:** decide which work conflicts based on what it actually
   shares. One entry at a time may be adequate for the first slice; a shared
   resource could instead need a common lock across different entries. Such
   groups and their scope are not designed here.
3. **Composition:** decide whether a batch is one tracked parent process or
   whether selected children also need independent records, stop controls and
   logs. Avoid assuming one implies the other; nested tracking needs an
   explicit ownership and signal contract.
4. **Host scope:** per-project files are not automatically a machine-wide view
   or machine-wide lock. Decide whether listing and mutual exclusion need to
   span project instances or users, and how a project directory shared between
   machines avoids conflating their local state. The existing home-directory
   index is per user and can be stale; it is not a complete host-wide ledger.
5. **Waiting:** a lock waiter is a process, not a persistent FIFO. Only add a
   durable queue, scheduling or priority mechanism if there is a concrete need
   to inspect, reorder, cancel, or survive a restart.

The existing [thread-control plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md)
proposes a run ID, separate short record and long occupancy locks, hold, stop,
and conservative recovery for one current run per entry. It is not an
implementation or an authorization to run the agent loop. A same-entry
concurrent-run design would change its single-current-run and stop semantics;
revise that plan explicitly before trying to combine the two. A normal
supervisor return and an uncertain stop have different slot-reuse rules there.

## Git and remaining decisions

- `data/logs/` and `data/threads/` are already ignored, including nested
  paths. Retain those rules for the proposed files.
- Add a narrow ignore rule for `data/agent/chats/` when implementing the
  archive; it is not currently ignored by the root `.gitignore`. Do not infer
  that every future file under `data/agent/` should be ignored.
- Remove the obsolete `data/changes/` ignore block only alongside the data
  audit and migration decision above. Keep existing rules for instance data,
  caches, private files and scratch unless separately reviewed.
- `data/test-results/` contains tracked frozen fixtures and has a separate
  history. Do not apply a blanket `data/` ignore or change test-result policy
  as a side effect.
- Decide separately whether `.txt` logs need metadata, how long local logs and
  chat archives are kept, and whether any thread history beyond latest state is
  needed. Logs, chat archives and thread state need not have the same lifetime.

This note starts the design. Implementation, migration, tests, and any changes
to the existing single-entry thread-control contract need their own concrete
plan and authorization.
