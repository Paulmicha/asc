---
status: draft
updated: 2026-11-15
---

# Agent models and providers

Draft. **Stub direction** means read from the action files in commit `75a25a8` (2026-11-15). Those files set entry-point names, the model hook calls, and the example arguments. Argument handling in each model action is still a TODO. The provider action files are empty. The mother has no `model` or `agent/provider` hook implementation. These actions were not run for this spec. The `agent` extension is listed in `.asc_extensions_ignore`, so a default init does not enable them.

A **model action** is a `model` hook call. The provider is a positional argument in the examples. A **provider action** is a path under `agent/provider/`. A [thread](agent-threads.md) is a process tree. A [chat](agent-chats.md) is a product conversation. Load, unload, and prompt stay in this spec.

## Model actions (stub direction)

Each file is `asc/extensions/agent/model/$action.sh`. After bootstrap it calls `hook_ms` with subject `model`, that action, and variant names `HOST_OS HOST_TYPE INSTANCE_TYPE`. That call is how one implementation would be selected once the script runs. The provider appears in the examples. It is not a name in `-v`.

Each file still has a TODO for the arguments docblock and for argument handling. The examples are the intended invocation. The scripts do not yet declare or handle those arguments, and this spec does not claim the hook sees them.

| Make name | Primitive pair | Arguments in the example | What the comment decides |
|---|---|---|---|
| `model-list` | `model/list` | one provider name | List the models that provider can use. The comment text is "List usable model models." |
| `model-load` | `model/load` | provider, then model name | Load that model through that provider. |
| `model-unload` | `model/unload` | provider, then model name | Unload that model through that provider. |
| `model-prompt` | `model/prompt` | provider, then model name | Prompt that model through that provider. The comment says "models"; the example names one. |
| `model-pull` | `model/pull` | provider, then model name | Pull that model when the provider has a pull. The comment says this applies for some providers and names local model servers as the examples. |

Make names are `f_make_task_name` on the primitive pair: `/` and other non-alphanumeric characters become `-`.

The strings in the action examples show those positions. The scripts do not read or forward them. Both a hosted product name and a local runtime name appear in that example position. Those five files are git mode `100644`. The Make refusal is the same one stated for the empty provider files below.

`model-prompt` is this hook call. `prompt-generate` and `prompt-refine` stay the actions under `prompt/`. A chat turn stays a `chat` action.

## Provider actions (stub direction)

These files are empty. When the extension is enabled, discovery treats a `*.sh` file that is not a double-extension helper as an action, so an enabled extension would register the names. An empty file chooses no hook call, no arguments, and no result.

The five files are git mode `100644`, and so are the five `model/*.sh` files. `asc/make/call_wrap.make.sh` runs the action path with `eval`. A path with no execute bit is permission denied, exit 126. That was checked with a disposable non-executable file, not by enabling the `agent` extension. Registering the names does not make the targets runnable. The execute bit belongs with an implementation of the action.

| Path | Primitive pair | Make name |
|---|---|---|
| `asc/extensions/agent/agent/provider/list.sh` | `agent/provider/list` | `agent-provider-list` |
| `asc/extensions/agent/agent/provider/load.sh` | `agent/provider/load` | `agent-provider-load` |
| `asc/extensions/agent/agent/provider/models.sh` | `agent/provider/models` | `agent-provider-models` |
| `asc/extensions/agent/agent/provider/unload.sh` | `agent/provider/unload` | `agent-provider-unload` |
| `asc/extensions/agent/agent/provider/update.sh` | `agent/provider/update` | `agent-provider-update` |

The reserved verbs are list, load, models, unload, and update, on object `provider` under subject `agent`. `agent-provider-list`, `agent-provider-models`, and `model-list` are three entry points. Only `model-list` has a comment. The same split holds for load and unload: the `model-*` file has the comment and the example, and the `agent-provider-*` file is empty. `agent-provider-update` has no `model-update` beside it.

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
| `model-prompt` text and result | The example gives a provider name and a model name. Where the prompt text comes from, and what the action returns, are unset. |
| Empty provider verbs | The paths exist. What list, models, load, unload, and update return is unset. |
| `agent-status`, `agent-stop`, `agent-stop_all` beside `model-load` and `model-unload` | Those three files were outside this commit. Accepting the stub filenames still needs an explicit decision that reconciles them. This spec is draft. |
| Which endpoint a chat uses | Open in [agent chats](agent-chats.md). The model-action examples do not select the chat hook. |
| Role, provider, and model mapping | Open in the stubs note. A role is not a model. |

Earlier notes leaned toward an `llm-*` rename, or toward folding the call into `run-agent`. The files from commit `75a25a8` use subject `model`, and subject `agent` with object `provider`. The mother tree has no `llm` subject directory. Those filenames are a draft record. They are not an accepted naming contract while `agent-status`, `agent-stop`, and `agent-stop_all` remain.

## Related

- Ideas: [agent stubs and retrieval](../../ideas/2026/11/13-agent-stubs-and-retrieval.md), [control actions](../../ideas/2026/11/11-agent-control-actions.md), [open decisions](../../ideas/2026/11/12-agent-spec-open-decisions.md).
- Code: `asc/extensions/agent/model/`, `asc/extensions/agent/agent/provider/`.
