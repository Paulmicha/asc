# Agent session stores: what products keep, and what ASC should keep

- **Date:** 2026-11-11
- **Status:** open idea / survey. Nothing here is decided.
- **Scope:** where coding-agent products store conversations, what their headless commands return, and how little ASC needs to record about a chat.
- **Method:** stores inspected on one Debian host on 2026-11-11 (shape only, no content read into this document); vendor documentation read the same day. Formats marked "documented" were not exercised. Product formats change without notice.
- **Spec this feeds:** [agent-chats](../../../specs/asc/agent-chats.md)
- **Siblings:** [run tracking](11-agent-run-tracking.md), [LLM Space evaluation](11-llm-space-evaluation.md)

## Position

A transcript is a foreign artefact. The product owns it, changes its format when it likes, and already stores it. ASC keeps a **pointer** and the **turn result**, never a copy. The desktop-reply plan already says "do not write a session database or a transcript log"; this survey gives the reasons.

## What the products keep

| Product | Where (under the user's home) | Shape | Identifier |
|---|---|---|---|
| Cursor (editor) | `.cursor/projects/<path-slug>/agent-transcripts/<uuid>/<uuid>.jsonl`, sub-agents beside it | JSON lines: a role and message parts, or a turn-end marker with a status. No timestamp, model or working directory in the lines seen. | the uuid in the path |
| Cursor (editor) plans | `.cursor/plans/<slug>_<hex>.plan.md` | Markdown with front matter: `name`, `overview`, `todos[]` (`id`, `content`, `status`) | file name |
| Cursor (CLI) | a separate chat store per workspace; not present on the host inspected | not inspected | `session_id` printed by the CLI |
| Codex | `.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<uuid>.jsonl`, an index file, and SQLite files for threads, spawn edges and a per-thread queue of pending items | JSON lines with `timestamp`, `ordinal`, `type`, `payload` | the thread uuid |
| Claude Code | documented: `.claude/projects/<path-slug>/<session-id>.jsonl` | documented as internal and unstable; the vendor says to use export or the script interface instead of parsing | the session id |

Things that follow:

- The editor and the CLI of the same vendor do not share a store. A chat opened in one is not resumable from the other.
- Two live clients on one Codex thread are unsupported.
- Paths embed the project's directory name. Any listing of these stores leaks project names. It must not reach a shared repository.
- At least one vendor documents its transcript format as not a contract. Parsing it is a maintenance debt, taken knowingly or not at all.

## What the headless commands return (documented)

| Product | Start a turn | Session id comes from | Continue | Final text |
|---|---|---|---|---|
| Cursor CLI | `agent -p --output-format json "$prompt"` | `session_id` in the result object, or in the first `system` / `init` event of `stream-json` | `--resume $id` | `result` |
| Codex | `codex exec --json "$prompt"` | `thread_id` in the first `thread.started` event | `codex exec resume $id "$prompt"` | last `agent_message` item; or `-o $file` |
| Claude Code | `claude -p --output-format json "$prompt"` | `session_id` in the result | `--resume $id` | `result` |

Caveats found while reading:

- One vendor has an open report that the id printed on a resumed run differs from the stored one. Keep the id from the first turn; do not replace it on resume.
- On failure some commands print no JSON at all. Check the exit code before parsing. The agent-plan contract already covers this with `missing_result_json`.
- Print mode can edit files and run commands. Flags that skip approval exist in all three. Isolation is the caller's job; see the agent-plan plan.
- `codex exec --ephemeral` and `claude -p --no-session-persistence` write no session at all. Useful for one-shot review turns that need no follow-up.

These three interfaces differ in every detail and agree on the shape: a prompt in, an id and a final text out. That is what the proposed chat turn JSON normalises. One small hook per product and role is enough; no adapter layer is needed above the existing `hook_ms` variants.

## What ASC needs to keep

Per turn, the proposed result object (`ok`, `action`, `role`, `chat_id`, `provider_session_id`, `prompt`, `reply_text`, `status`, `error`). Where it is kept is not settled. Candidates:

1. **Nowhere.** stdout to the caller, which decides. The plan allows an optional `result:<path>` mirror.
2. **In the thread record.** The run that drove the chat writes `provider_session_id` next to its pid. One file answers "which run, which chat".
3. **A pointer file per chat.** For example `data/chats/$chat_id.yml` with provider, role, session id, created time, last turn status. Needed only if a chat outlives the run that opened it and another run must find it.
4. **The run ledger**, if one exists: a `chat.turn` line.

Lean: 1 now, 2 when a thread first drives a chat, 3 only when a second run needs to resume a chat by name. Do not start at 3.

## `chat_id` versus `provider_session_id`

The plan has both and does not say how they relate. Two readings:

- They are the same string. Then one field is enough.
- `chat_id` is ASC's stable name and survives a provider change or a lost session. Then a mapping must be stored somewhere, which is option 3 above.

This needs a decision before `chat-read` and `chat-archive` get an implementation; both take `chat_id` and neither has one today.

## What `read` and `archive` could mean without a store

- `chat-read`: ask the product (resume with an empty or "summarise" prompt is not reading). For products with a readable store, print the transcript path. Otherwise say it is not available.
- `chat-archive`: with pointers only, archiving is deleting the pointer. The product keeps its copy under its own retention.

Both may turn out not to be needed. They exist as abstract pivots from an earlier design.

## Reading a transcript when it is worth it

If a review needs what happened inside a session, parse on demand, per product, and label the result as observed from a foreign file. Existing viewers do this already (AgentTrail reads two of the three stores; context-inspection tools exist). ASC does not need a parser of its own.

## Field names from OpenTelemetry

The GenAI semantic conventions (status: development) name the same things: `gen_ai.conversation.id` for the session, `gen_ai.provider.name`, `gen_ai.agent.name`, `gen_ai.operation.name` (`invoke_agent`), `error.type`. They say not to invent a conversation id when the provider gives none. Useful as a mapping for a later export. Not a reason to rename the proposed fields or to run a collector.

## Open questions

- One identifier or two?
- Is a chat a thing with a file, or only a field on a run?
- Which product stores, if any, may an ASC action read?
- Retention: when the product deletes a session, is a dangling pointer an error or normal?
- The chat hooks select on `CHAT_ROLE`. Does a third dimension (which host serves the model) belong in the variants or in configuration?
