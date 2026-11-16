---
status: draft
updated: 2026-11-15
---

# Agent goals, tasks, memory, and knowledge

Commit `469ad37` groups these actions in the `agent` extension. `goal` is a
subject of its own. `task`, `memory`, and `knowledge` are objects under the
`agent` subject. ASC uses object directories to group actions. Hook lookup
uses subjects, so any future hook calls need their own subject and action
choices.

## Action names (observed)

Paths are relative to `asc/extensions/agent/`. The last column gives the
Make name prefix and the suffixes discovered from the files.

| Path | Placement | Make names |
|---|---|---|
| `goal/` | subject `goal` | `goal-*` with `align`, `create`, `delete`, `list`, `update` |
| `agent/task/` | object `task` under `agent` | `agent-task-*` with `clear`, `create`, `delegate`, `execute`, `list`, `oriented`, `prioritize`, `update` |
| `agent/memory/` | object `memory` under `agent` | `agent-memory-*` with `create`, `delete`, `oriented`, `search`, `update` |
| `agent/knowledge/` | object `knowledge` under `agent` | `agent-knowledge-*` with `memory`, `oriented`, `task` |

All 21 files are empty and have Git mode `100644`. The mother disables `agent`
by default through `.asc_extensions_ignore`. When the extension is enabled,
discovery includes the files and the Make wrapper attempts to execute them
directly. The wrapper exits 126 with permission denied. Invoking an empty
file through Bash returns success with no result. The layout records candidate
entry points. Arguments, hooks, and results are still open.

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
- `agent-knowledge-memory` and `agent-knowledge-task` suggest points of
  contact with memory and tasks. Their purpose could be lookup, linking, or
  another operation. The three `oriented` names also need a clear purpose
  and a caller. Decide whether they list agents by orientation, select an
  orientation, or start work before implementing any of them.

Tracked `.asc_actions_ignore` files in the action directories can keep empty
placeholders out of the generated targets. Start with an action that has a
caller and a clear input, result, and effect on state.
