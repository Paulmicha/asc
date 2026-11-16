---
status: draft
updated: 2026-11-16
---

# Agent models and providers

The opt-in `agent` extension uses `model/` for model operations and
`agent/provider/` for provider operations. The mother ignores the extension
by default through `.asc_extensions_ignore`. Argument handling is a TODO
in the model scripts, and the provider scripts are empty.

## Model prompting direction

`model-prompt` is the proposed entry point for sending input to a model. The
stub sketches provider, model, workspace, and prose or DSL as its four
positional arguments in that order. The neighbouring `prompt-create`,
`prompt-list`, `prompt-review`, and `prompt-delete` paths indicate a
separate lifecycle for prompts. How a stored prompt can supply input to
`model-prompt` remains open.

A standalone call can produce a one-shot reply for the caller. The
`agent-reply-*` stubs indicate a separate way to list, read, or review
those replies. Continuing a conversation requires its provider session
identity. Whether the chat actions delegate model invocation to
`model-prompt` remains open. See
[one-shot replies and conversation turns](agent-chats.md#one-shot-replies-and-conversation-turns).

## Model actions (stub direction)

Each file is `asc/extensions/agent/model/$action.sh`. After bootstrap it calls
`hook_ms` with subject `model` and variant names `HOST_OS HOST_TYPE INSTANCE_TYPE`.
The table records the copied calls whose verb differs from the filename.
The provider appears in the examples as data, separate from the variant names.

Each file has TODOs for the arguments docblock and argument handling. The
examples show draft positions. The scripts currently leave those arguments
unread and do not forward them to the hook.

| Make name | Primitive pair | Arguments in the example | Source notes |
|---|---|---|---|
| `model-list` | `model/list` | one provider name | List the models that provider can use. The comment text is "List usable model models." |
| `model-load` | `model/load` | provider, then model name | Load that model through that provider. |
| `model-unload` | `model/unload` | provider, then model name | Unload that model through that provider. |
| `model-prompt` | `model/prompt` | provider, model name, workspace, prose or DSL | The fourth position shows prose in `93571e0`. Argument handling is a TODO. |
| `model-pull` | `model/pull` | provider, then model name | Pull that model when the provider has a pull. The comment says this applies for some providers and names local model servers as the examples. |
| `model-select` | `model/select` | copied unload example | The script calls `model/unload`. Selection is open. |
| `model-review` | `model/review` | copied unload example | The script calls `model/unload`. The review subject and result are open. |

Make names are `f_make_task_name` on the primitive pair: `/` and other non-alphanumeric characters become `-`.

The seven files have Git mode `100644`. In isolated probes through Bash,
`model-select` and `model-review` each called the unload hook. Their routing
and examples need correction before the targets become runnable.

The revised `model-prompt` Make example preserves the prose as one argument
through the Make wrapper in an isolated probe. The direct example has an
extra single quote after the model name and fails shell parsing. The
[model prompting idea](../../ideas/2026/11/15-model-prompt.md) sketches the
prose and DSL inputs.

## Provider actions (stub direction)

These files are empty. When the extension is enabled, discovery treats a `*.sh` file that is not a double-extension helper as an action, so an enabled extension would register the names. An empty file chooses no hook call, no arguments, and no result.

The seven provider files have Git mode `100644`. The Make wrapper attempts
direct execution, which returns 126 on a non-executable path. See the
[action discovery probe](agent-work.md#action-names-observed).

| Path | Primitive pair | Make name |
|---|---|---|
| `asc/extensions/agent/agent/provider/list.sh` | `agent/provider/list` | `agent-provider-list` |
| `asc/extensions/agent/agent/provider/load.sh` | `agent/provider/load` | `agent-provider-load` |
| `asc/extensions/agent/agent/provider/models.sh` | `agent/provider/models` | `agent-provider-models` |
| `asc/extensions/agent/agent/provider/review.sh` | `agent/provider/review` | `agent-provider-review` |
| `asc/extensions/agent/agent/provider/select.sh` | `agent/provider/select` | `agent-provider-select` |
| `asc/extensions/agent/agent/provider/unload.sh` | `agent/provider/unload` | `agent-provider-unload` |
| `asc/extensions/agent/agent/provider/update.sh` | `agent/provider/update` | `agent-provider-update` |

Provider and model selection have separate stubs. A provider choice
identifies the service or harness, and the model choice identifies a model
available through it. A role such as writer or reviewer describes the job a
caller wants done. Whether a role supplies defaults and whether either
`select` action returns a value or changes a default remain open. Any
default needs a defined scope and precedence when `model-prompt` receives
explicit arguments.

## Prompt and workspace actions (stub direction)

| Subject | Paths in the current tree |
|---|---|
| `prompt` | `create`, `delete`, `list`, `review` |
| `workspace` | `create`, `delete`, `index`, `list`, `review`, `scan`, `sync`, `update` |

The source drops `prompt-generate` and `prompt-refine`. `prompt-create` and
`prompt-review` call `log` and `agent` hooks before and after attempting to
source the absent `asc/extensions/agent/agent/wrap.sh`. Successful post hooks
can mask that failure. `prompt-delete`, `prompt-list`, and all eight workspace
files are empty. The prompt record format and identifier are open.

For workspaces, define the identifier used by `model-prompt`, what `scan`
discovers, what `index` persists, and the direction and conflict policy of
`sync`. `delete` needs a clear distinction between workspace registration
and the underlying files. See [agent work](agent-work.md#review-actions-proposed)
for the review direction across subjects.

## Actions that remain on subject `agent`

Commit `75a25a8` left these files as they were:

| File | Hook call | Example |
|---|---|---|
| `agent/list.sh` | `hook` on subject `agent`, action `list`, variants `HOST_OS HOST_TYPE INSTANCE_TYPE` | `make agent-list`. Comment: list usable agents. |
| `agent/status.sh` | `hook_ms` on subject `agent`, action `status`, same variants | `make agent-status` |
| `agent/stop.sh` | `hook_ms` on subject `agent`, action `stop`, same variants | `make agent-stop` |
| `agent/stop_all.sh` | `hook_ms` on subject `agent`, action `stop_all`, same variants | `make agent-stop-all` |

The status, stop, and stop_all comments still say "Abstract local LLM bring-up". Their examples include no provider and no model name.

## Not decided

| Topic | What the stubs leave open |
|---|---|
| Missing or unknown provider or model | No failure token and no usage text. Argument handling is a TODO. |
| How the selected hook receives the names | The action shows no variable and no forwarded argument list. |
| Hook implementation home | No matching hook file in the mother. |
| Stdout and exit status | No result contract. |
| `model-prompt` workspace | Which workspace identifier the third position accepts, and whether `workspace-list` supplies it, is open. |
| `model-prompt` text and result | How to distinguish prose from DSL, how to pass DSL punctuation through Make, and what the action returns are open. |
| Empty provider verbs | Arguments, results and state changes for all seven verbs are open. |
| Which endpoint a chat uses | Open in [agent chats](agent-chats.md). The model-action examples do not select the chat hook. |
| Role, provider, and model mapping | Which caller resolves the role and where it gets its defaults. |

The current naming direction comes from `model/` and `agent/provider/`
in `75a25a8`. Earlier notes explored `llm-*` and a generic agent run action.
Commit `d8df2b8` removed `agent/run.sh`. The remaining top-level agent status
and stop actions still need reconciliation with the model lifecycle and
[thread controls](agent-threads.md).

## Related

- Ideas: [agent stubs and retrieval](../../ideas/2026/11/13-agent-stubs-and-retrieval.md), [control actions](../../ideas/2026/11/11-agent-control-actions.md), [open decisions](../../ideas/2026/11/12-agent-spec-open-decisions.md).
- Code: `asc/extensions/agent/model/`, `asc/extensions/agent/agent/provider/`, `asc/extensions/agent/workspace/`.
