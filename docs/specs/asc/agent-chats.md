---
status: draft
updated: 2026-11-11
---

# Agent chats

Draft. **Observed** means read in the mother code on 2026-11-11. **Proposed** means written in a plan and not implemented. **External** means taken from a product's documentation or seen in its files; products change these without notice. Nothing proposed here is approved.

A **chat** is a conversation held by an agent product. The product stores it. ASC starts turns, receives their result, and keeps at most a pointer. A chat is not a [thread](agent-threads.md): a thread is the process that drives a turn.

Reasoning and survey: [session stores](../../ideas/2026/11/11-agent-session-stores.md). Related evaluation: [LLM Space](../../ideas/2026/11/11-llm-space-evaluation.md).

## Entry points (observed)

In the `agent` extension, ignored by default.

| Action | Today |
|---|---|
| `chat-new`, `chat-reply` | `pre`, main and `post` `chat` hooks; variants `STACK_VERSION HOST_TYPE chat_TYPE`; input `chat_id` |
| `chat-read`, `chat-archive` | same shape |

No hook implementation exists in the mother. No file is written.

## Selection (proposed)

| Action | Variant variable | Values |
|---|---|---|
| `chat-new`, `chat-reply` | `CHAT_ROLE` | `writer`, `reviewer` |
| `chat-read`, `chat-archive` | `CHAT_TYPE` (renamed from `chat_TYPE`) | product |

Selection uses `hook_ms` as it is. One hook per product and role, for example `cursor/chat/new.writer.hook.sh`, `codex/chat/reply.reviewer.hook.sh`. No selection wrapper, no adapter layer. `chat-new` and `chat-reply` drop the `pre` and `post` hooks.

## Turn result (proposed)

Diagnostics on stderr. Exactly one JSON object on stdout, built with a JSON encoder. An optional `result:$path` argument mirrors it to a file; stdout is authoritative.

```json
{
  "ok": false,
  "action": "new",
  "role": "writer",
  "chat_id": null,
  "provider_session_id": null,
  "prompt": "…",
  "reply_text": "",
  "status": "failed",
  "error": "no_hook_for_role"
}
```

| Field | Rule |
|---|---|
| `ok` | boolean |
| `action` | `new`, `reply` |
| `role` | `writer`, `reviewer` |
| `chat_id`, `provider_session_id` | string when known, else `null` |
| `prompt`, `reply_text` | strings |
| `status` | `completed`, `failed`, `empty_reply` |
| `error` | `null` on success, else a short token |

A caller that gets a crash, empty or malformed stdout records `missing_result_json` and treats the turn as failed. `read` and `archive` have no JSON contract.

## Desktop reply outcomes (proposed)

For a reply typed into a desktop client from a terminal habit, not the headless path.

| Outcome | Exit |
|---|---|
| `accepted` | 0 |
| `not sent` | 2 |
| `delivery unknown` | 3; never retried |

## Product stores (external)

Foreign artefacts. ASC does not copy them and does not treat their format as a contract.

| Product | Location under the user's home | Identifier |
|---|---|---|
| Cursor editor | `.cursor/projects/$path_slug/agent-transcripts/$uuid/$uuid.jsonl` | `$uuid` |
| Cursor CLI | a separate per-workspace chat store | `session_id` |
| Codex | `.codex/sessions/YYYY/MM/DD/rollout-$timestamp-$uuid.jsonl` | `$uuid` |
| Claude Code | `.claude/projects/$path_slug/$session_id.jsonl` | `$session_id` |

Editor and CLI stores of one vendor are separate. Two live clients on one Codex thread are unsupported. Store paths embed project directory names; listings of them stay out of shared repositories.

## Headless commands (external)

| Product | New turn | Identifier in output | Continue |
|---|---|---|---|
| Cursor CLI | `agent -p --output-format json` | `session_id` | `--resume $id` |
| Codex | `codex exec --json` | `thread_id` in the first `thread.started` event | `codex exec resume $id` |
| Claude Code | `claude -p --output-format json` | `session_id` | `--resume $id` |

Check the exit code before parsing. Keep the identifier from the first turn.

## Rules

- ASC writes no transcript log and no session database.
- A turn's write access is the caller's concern; see isolation in [agent-plans](agent-plans.md).
- Headless only. Driving a session that is open in a desktop client is out of scope.

## Not decided

| Topic | Candidates |
|---|---|
| `chat_id` versus `provider_session_id` | one string; or an ASC name mapped to a provider id |
| Where a turn result is kept | nowhere beyond stdout; in the thread record; a pointer file per chat; a ledger line |
| Pointer file, if any | `data/chats/$chat_id.yml` with provider, role, session id, created, last status |
| Meaning of `read` and `archive` without a store | print the product's transcript path; drop the pointer; or remove both actions |
| Endpoint dimension | a hook variant; or instance configuration |
| Field names for export | OpenTelemetry GenAI names (`gen_ai.conversation.id`, `gen_ai.provider.name`) as a mapping only |
| Claude Code | deferred |

## Related

- Idea: [agent-plan design](../../ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md) §1, §2, §8.
- Plans: [its implementation plan](../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md); [desktop agent terminal reply](../../plans/2026/09/27-desktop-agent-terminal-reply.md).
- Code: `asc/extensions/agent/chat/`.
