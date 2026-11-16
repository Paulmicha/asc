---
status: draft
updated: 2026-11-16
---

# Agent work, permissions, and sandboxes

Commit `469ad37` placed `goal` in its own subject and put `task`, `memory`,
and `knowledge` under the `agent` subject. Commit `08c8a51` adds `cognition`
as another object under `agent`. It removes `agent/knowledge/memory.sh` and
`agent/knowledge/task.sh`, and adds `create`, `delete`, and `update` under
knowledge. `oriented` stays.

Commit `e7cda9a` adds `permission` and `sandbox` as separate objects under
`agent`. The filenames group permission queries and changes separately from
sandbox management and loading.

Commit `af6d125` drops `agent-task-clear` and adds separate `complete` and
`delete` stubs under `agent/task/`. The `need` subject has its own action
group. See the [needs inbox](agent-plans.md#needs-inbox-proposed).

Commit `477106c` adds `review` across action groups, adds `agent-sandbox-update`,
and removes the `goal-align` and `agent-task-prioritize` stubs. Git can pair
unrelated additions and removals because they contain the same empty blob.

Hook lookup walks `$subject/$action` paths. `f_hook_build_lookup_by_subject`
in `asc/core/hook.manual-inc.sh` skips paths with two slashes. `goal/review`
can be a hook target. An object action such as `agent/permission/check`
can make a hook call by naming the subject and action for that lookup.

## Action names (observed)

Paths are relative to `asc/extensions/agent/`. The last column gives the
Make name prefix and the suffixes discovered from the files.

| Path | Placement | Make names |
|---|---|---|
| `goal/` | subject `goal` | `goal-*` with `create`, `delete`, `list`, `review`, `update` |
| `agent/task/` | object `task` under `agent` | `agent-task-*` with `complete`, `create`, `delegate`, `delete`, `execute`, `list`, `oriented`, `review`, `update` |
| `agent/memory/` | object `memory` under `agent` | `agent-memory-*` with `create`, `delete`, `oriented`, `review`, `search`, `update` |
| `agent/knowledge/` | object `knowledge` under `agent` | `agent-knowledge-*` with `create`, `delete`, `oriented`, `review`, `update` |
| `agent/cognition/` | object `cognition` under `agent` | `agent-cognition-*` with `list`, `read`, `review`, `scan` |
| `agent/permission/` | object `permission` under `agent` | `agent-permission-*` with `check`, `get`, `list`, `remove`, `review`, `set` |
| `agent/sandbox/` | object `sandbox` under `agent` | `agent-sandbox-*` with `create`, `delete`, `list`, `load`, `review`, `unload`, `update` |

Git records the two removed knowledge files as renames:
`knowledge/memory.sh` to `cognition/list.sh`, and `knowledge/task.sh` to
`cognition/read.sh`. Both sides are the same empty blob, so the pairing is
Git's similarity match. `cognition/scan.sh` and the new knowledge files are
adds. What those pairs mean is open.

All 42 files in the table are empty and have Git mode `100644`. The mother
disables `agent` by default through `.asc_extensions_ignore`. With `agent`
enabled, ASC discovers these names. The Make wrapper attempts to execute the
files directly. In an isolated probe, the wrapper returned 126 for each of
the 30 new paths across `477106c` and `93571e0`. Explicitly passing an empty
file to Bash returns success with no result.

An unregistered target can match the catch-all rule in the root `Makefile`
and exit 0 without running an action. Isolated probes reproduced this for
`agent-permission-check`, `agent-sandbox-load`, and the removed
`agent-task-clear`.

## What the filenames decide

- `goal` is a subject. Its `goal/$action` paths are eligible for hook lookup.
- `agent-task-*`, `agent-memory-*`, `agent-knowledge-*`, and
  `agent-cognition-*` group actions under objects. `agent-permission-*` and
  `agent-sandbox-*` follow the same layout.

## Review actions (proposed)

The shared verb suggests an assessment of the named subject or object. Each
action still needs to define what is reviewed, which evidence it uses, and
whether it returns findings or stores them. A review that can affect state
needs to identify the record or revision it assessed. The existing draft
plan review result ties findings to a plan digest and a named step. Its
approval and execution boundaries are described in [agent plans](agent-plans.md#four-separate-questions).

## Permissions and sandboxing (proposed)

- **Permissions.** The names suggest using `get` and `list` to inspect
  records, `set` and `remove` to change them, and `check` to evaluate the
  effective permission for one operation. The rule format, scope, precedence,
  and authority to change grants are open. A caller should proceed only on an
  explicit allow for the requested operation. A denial, an unresolved check,
  or a missing result should block the operation. Make's exit status alone
  cannot supply that decision.
- **Sandboxes.** The names suggest managing definitions with `create`,
  `list`, `update`, and `delete`. Whether `load` and `unload` prepare a
  profile or manage a running sandbox is open. Define how the launcher
  applies the selected restrictions to the agent process, and how update,
  unload, or delete affects active runs. A run that requires isolation
  should stop if setup fails.
  The proposed plan runner already distinguishes enforced and weakened modes.
  See [plan isolation](agent-plans.md#isolation).

Plan approval, permission to perform a specific operation, and runtime
isolation answer separate questions. How these actions connect to the draft
plan runner remains open. See [agent plans](agent-plans.md#four-separate-questions).

## Still open

- What identifies a goal and whether `goal-review` assesses alignment or
  another property.
- How a task refers to a plan, a named step, or an execution attempt. What
  `delegate` hands off and whether task review includes a recommendation
  about priority are open. When a task runs a plan step, readiness
  and authorisation stay distinct. See [agent plans](agent-plans.md).
- The separate `complete` and `delete` stubs suggest a task state transition
  and a record removal operation. Define who can mark a task complete, what
  evidence supports completion, and what deletion preserves when plans or
  runs reference the task. A thread exit describes one execution attempt.
  How that result contributes to task completion is open. See
  [agent threads](agent-threads.md).
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
