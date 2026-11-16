---
status: draft
updated: 2026-11-16
---

# Agent work, permissions, and sandboxes

The stubs put `goal` in its own subject, alongside
[`plan` and `need`](agent-plans.md). Task, memory, knowledge, cognition,
permission, sandbox, and one-shot reply actions are grouped under the
`agent` subject. The directory layout determines the Make names.

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
| `agent/reply/` | object `reply` under `agent` | `agent-reply-*` with `list`, `read`, `review` |
| `agent/sandbox/` | object `sandbox` under `agent` | `agent-sandbox-*` with `create`, `delete`, `list`, `load`, `review`, `unload`, `update` |

All files in the table are empty and have Git mode `100644`. The mother
disables `agent` by default through `.asc_extensions_ignore`. With `agent`
enabled, ASC discovers these names. Its Make wrapper attempts to execute the
files directly. An earlier isolated probe of the files added by `477106c`
and `93571e0` returned 126 for non-executable paths. Explicitly passing an
empty file to Bash returns success with no result.

An unregistered target can match the catch-all rule in the root `Makefile`
and exit 0 without running an action. Isolated probes reproduced this for
`agent-permission-check`, `agent-sandbox-load`, and the removed
`agent-task-clear`.

## Subject and object placement

Hook lookup uses `$subject/$action` paths, such as `goal/review`.
`f_hook_build_lookup_by_subject` skips `$subject/$object/$action` paths.
An object action can make its own hook call using a subject and action
eligible for that lookup.

The knowledge stubs include record creation, update, and deletion. The
cognition stubs introduce scanning and reading. The data flow between
the two objects remains open. The `reply` object concerns
[one-shot results](agent-chats.md#one-shot-replies-and-conversation-turns).

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
- Commit `af6d125` replaced task `clear` with separate `complete` and
  `delete` stubs. The direction is to distinguish recording completion
  from removing a task record. Define who can mark a task complete, what
  evidence supports it, and what deletion preserves when plans or runs
  reference the task. How a thread exit contributes to completion is open.
  See [agent threads](agent-threads.md).
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
