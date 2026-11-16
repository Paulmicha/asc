---
status: draft
updated: 2026-11-15
---

# Agent goals, tasks, memory, knowledge, and cognition

Commit `469ad37` placed `goal` in its own subject and put `task`, `memory`,
and `knowledge` under the `agent` subject. Commit `08c8a51` adds `cognition`
as another object under `agent`. It removes `agent/knowledge/memory.sh` and
`agent/knowledge/task.sh`, and adds `create`, `delete`, and `update` under
knowledge. `oriented` stays.

Hook lookup walks `$subject/$action` paths. `f_hook_build_lookup_by_subject`
in `asc/core/hook.manual-inc.sh` skips a path with two slashes, so an
object-directory action is not a hook target. `goal/align` can be one.
`agent/task/create` and the other object actions in the table below cannot,
until a script names a subject and an action for its hook call.

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

Git records the two removed knowledge files as renames:
`knowledge/memory.sh` to `cognition/list.sh`, and `knowledge/task.sh` to
`cognition/read.sh`. Both sides are the same empty blob, so the pairing is
Git's similarity match. `cognition/scan.sh` and the new knowledge files are
adds. What those pairs mean is open.

All 25 files in the table are empty and have Git mode `100644`. The mother
disables `agent` by default through `.asc_extensions_ignore`. When the
extension is enabled, discovery includes the files and the Make wrapper
attempts to execute them directly. The wrapper exits 126 with permission
denied. Invoking an empty file through Bash returns success with no result.
The layout records candidate entry points. These directories contain no
`.asc_actions_ignore`, so an enabled extension registers all 25 names.
A discovery probe of `asc/extensions/agent` on 2026-11-15 listed those 25
and did not list `agent/knowledge/memory` or `agent/knowledge/task`.
Arguments, hook calls, and results are still open.

## What the filenames decide

- `goal-*` is a subject. Its verbs are `align`, `create`, `delete`, `list`,
  and `update`. `goal/$action` is a hook-eligible path.
- `agent-task-*`, `agent-memory-*`, `agent-knowledge-*`, and
  `agent-cognition-*` group actions under objects. Those paths are not hook
  targets.
- Knowledge's filenames are `create`, `delete`, `oriented`, and `update`.
- Cognition's filenames are `list`, `read`, and `scan`.

## Still open

- Whether `goal-align` checks a relationship or changes one, and what
  identifies a goal.
- How a task refers to a plan, a named step, or an execution attempt. What
  `clear` affects, what `delegate` hands off, and whether `prioritize`
  changes a backlog or reports an assessment. When a task runs a plan step,
  readiness and authorisation stay distinct. Process tracking stays with
  threads. See [agent plans](agent-plans.md) and [agent threads](agent-threads.md).
- Who owns a memory entry, which scope `search` covers, and whether these
  actions delegate storage to a provider or to the
  [`memory` extension](../../../asc/extensions/memory/). That extension's
  `storage/*` and `store/*` actions, including `store-search`, are TODO
  stubs. These filenames select no backend.
- What a knowledge record is, which identifier create, update, and delete
  use, and whether that store is the same one agent memory would use.
- What `agent-cognition-scan` reads, whether a scan returns findings or also
  writes records, and what `list` and `read` identify. A scan might read
  knowledge records or its own findings. `workspace-index` and
  `workspace-list` are empty files with no behavior to call. See
  [agent models and providers](agent-models.md).
- What the `oriented` stubs under task, memory, and knowledge do, and which
  caller needs them. A list of agents, a selected orientation, and the start
  of work are separate possibilities.

Tracked `.asc_actions_ignore` files in the action directories can keep empty
placeholders out of the generated targets. Start with an action that has a
caller and a clear input, result, and effect on state.
