---
status: draft
updated: 2026-11-15
---

# Agent goals, tasks, memory, knowledge, and cognition

Commit `469ad37` placed `goal` in its own subject and put `task`, `memory`,
and `knowledge` under the `agent` subject. Commit `08c8a51` adds `cognition`
as another object under `agent` and changes the knowledge verbs. ASC uses
object directories to group actions. Hook lookup uses subjects, so any
future hook calls need their own subject and action choices.

## Action names (observed)

Paths are relative to `asc/extensions/agent/`. The last column gives the
Make name prefix and the suffixes discovered from the files.

| Path | Placement | Make names |
|---|---|---|
| `goal/` | subject `goal` | `goal-*` with `align`, `create`, `delete`, `list`, `update` |
| `agent/task/` | object `task` under `agent` | `agent-task-*` with `clear`, `create`, `delegate`, `execute`, `list`, `oriented`, `prioritize`, `update` |
| `agent/memory/` | object `memory` under `agent` | `agent-memory-*` with `create`, `delete`, `oriented`, `search`, `update` |
| `agent/knowledge/` | object `knowledge` under `agent` | `agent-knowledge-*` with `create`, `delete`, `oriented`, `update` |
| `agent/cognition/` | object `cognition` under `agent` | `agent-cognition-*` with `list`, `read`, `scan` |

The current tree drops `agent-knowledge-memory` and `agent-knowledge-task`.
Git reports two renames to cognition paths because the files have identical
empty contents. Any relationship between the old and new actions is open.

All 25 files in the table are empty and have Git mode `100644`. The mother
disables `agent` by default through `.asc_extensions_ignore`. When the
extension is enabled, discovery includes the files and the Make wrapper
attempts to execute them directly. The wrapper exits 126 with permission
denied. Invoking an empty file through Bash returns success with no result.
The layout records candidate entry points. Arguments, hooks, and results
are still open.

## Implementation direction

- `goal-*` gives goals a separate action prefix. The names distinguish
  goal maintenance from alignment work. Whether `goal-align` checks a
  relationship or changes one remains open, as do the scope and identity of a
  goal.
- `agent-task-*` groups work item management with delegation and execution.
  Define how a task refers to a plan, a named step, or an execution attempt
  before choosing a task record. Settle what `clear` affects, what `delegate`
  hands off, and whether `prioritize` changes the backlog or reports an
  assessment. When a task runs a plan step, the draft plan contract
  still distinguishes readiness from authorisation. The thread spec covers
  process tracking. See [agent plans](agent-plans.md) and
  [agent threads](agent-threads.md).
- `agent-memory-*` sketches operations on information available to an agent.
  Decide who owns a memory entry, which scope search covers, and whether
  actions delegate storage and search to a provider or an existing ASC store.
  The separate [`memory` extension](../../../asc/extensions/memory/) already
  has storage and store entry points, including a `store-search` stub. The
  new filenames select no backend.
- `agent-knowledge-*` groups create, update, and delete under knowledge.
  The record type, identifier, and backing store are open. Define what
  callers update or delete, and whether knowledge shares storage with agent
  memory.
- `agent-cognition-*` groups listing, reading, and scanning under cognition.
  Decide what gets scanned, whether a scan returns findings or also writes
  records, and what `list` and `read` identify. They could expose knowledge
  entries maintained by `agent-knowledge-*` or findings produced by a scan.
  If scans use workspaces, clarify how scanning relates to `workspace-index`.
  See [agent models and providers](agent-models.md) for the workspace stubs.
- The `oriented` stubs remain in task, memory, and knowledge. Their purpose
  and caller are open. They could list agents by orientation, select an
  orientation, or start work.

Tracked `.asc_actions_ignore` files in the action directories can keep empty
placeholders out of the generated targets. Start with an action that has a
caller and a clear input, result, and effect on state.
