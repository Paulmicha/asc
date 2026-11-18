# Model prompting as the main LLM entry point

Status: open idea  
Created: 2026-11-15

Make `model-prompt` the principal ASC entry point for interacting with any LLM.
The one-shot reply stubs introduced by `7ecb4c4` give standalone answers their
own list, read, and review actions. The chat actions handle conversation
turns. Whether those actions call `model-prompt` remains open.
[Agent chats](../../../specs/asc/agent-chats.md#one-shot-replies-and-conversation-turns)
describes the two action groups.

## Prose or DSL in the last argument

The current stub sketches four positions for provider, model, workspace, and
prompt. The idea is to let the final argument carry plain prose, a DSL
expression, or a combination such as a DSL operation with prose inside it.
These examples show possible values for the fourth position. The stub
does not read its arguments.

```text
Draft a plan from Foobar prose.
prompt-new-plan('Foobar prose')
```

In the second form, `prompt-new-plan` illustrates a named prompt operation and
`'Foobar prose'` uses the literal syntax proposed in the
[ASC DSL draft](../../../specs/asc/dsl.md#arguments-proposed). The operation
and the decision to use ASC DSL for this input remain open.

## Open questions

- How does the caller explicitly select prose or DSL? How does the
  supported carrier preserve the chosen payload as one argument?
- What does the workspace argument identify? Would `workspace-list` supply
  that identifier?
- What does `model-prompt` return, and how would a caller refer to the result
  through `agent-reply-read` if standalone replies are retained?

The draft [agent models spec](../../../specs/asc/agent-models.md) records the
stub. The [agent stubs and retrieval note](13-agent-stubs-and-retrieval.md)
has the broader context on providers and workspaces.
