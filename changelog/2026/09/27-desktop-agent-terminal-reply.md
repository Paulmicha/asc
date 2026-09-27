# Terminal reply into a desktop agent session

| Field | Value |
|-------|--------|
| **Date** | 2026-09-27 |
| **Status** | **plan / review**. Discovery for Cursor, Codex, and Claude can proceed. Nothing here is an implementation go-ahead. |
| **v1, if a later go-ahead names Cursor** | One product. Explicit window target. Send only to the composer visible at send time. That composer must be idle and empty. One bounded check, then one of three outcomes: **accepted**, **not sent**, **delivery unknown**. No automatic retry. |
| **Boundaries** | Do not write a session database or a transcript log. Do not open a second live client on a Codex thread. Do not click an approval, a permission dialog, or a tool button. A debugging port can drive the whole editor, so v1 also refuses any listener that is not loopback and any WebSocket URL whose host is not loopback. `--yes` does not skip a target check. |
| **Scope** | The habit: the desktop stays the live session, and a terminal on the same machine is only the input. Cursor is the first implementation candidate. Codex and Claude get an attachment-discovery pass in the same effort, not after a Cursor client exists. |
| **Out of this plan** | A gates row. A pivot, hook, include, or extension. Enabling `agent`, `asc/cursor`, `asc/codex`, or `asc/claude`. A cloud-agent follow-up API. An MCP tool that blocks on stdin. Draft replacement. Steering a running turn. A phone, browser, or chat-app relay. Shipping a script. |

`gates.core.yml` is a later agent approval surface. Do not add a row for this note.

---

## The habit

The desktop session stays on screen: the thread, the tool calls, the diffs. The terminal submits one short user message into that session and exits. The reply client does not keep a transcript.

A workspace window is not a conversation. One window can hold several chats, and the visible chat can change between lookup and submit. v1 does not claim a stable conversation id. Its contract is narrower:

> Send to the composer that is visible in the named window at the moment of send.

If discovery later finds a stable conversation id on that surface, a later note can add it and recheck it immediately before send. Until then, the command's help text states the limitation in those words.

| Piece | Role |
|-------|------|
| Desktop session | The conversation the human watches. |
| Reply client | One shot. It reports one outcome and exits. |
| Session store | The store that product already uses. The client does not become another store. |

---

## Evidence

Claims in the first draft mixed local inspection, staff statements, third-party notes, and untested hypotheses. This table is the replacement. A row is not a license to implement.

| Claim | Kind | Source |
|-------|------|--------|
| Cursor IDE build `3.21.18` and Agent CLI `2026.07.23-e383d2b` were the builds inspected on 2026-09-27. CLI help includes `create-chat`, `--resume`, and `resume`. It has no flag that attaches to an open IDE composer. | Observed locally, one Linux host. | `cursor --help`, `agent about`, `agent --help`. |
| IDE composer rows live in `~/.config/Cursor/User/globalStorage/state.vscdb` (`composerHeaders`, `composerData`, `bubbleId`). A JSONL log sits beside them at `~/.cursor/projects/<workspace>/agent-transcripts/<composer-id>/`. | Observed locally, same day. That the sidebar loads the chat from `state.vscdb` is a hypothesis. This note did not watch the sidebar read the file. | Local `state.vscdb` table and key prefixes. |
| IDE chats and CLI chats are different stores. There is no shared session id and no `--resume` bridge from an IDE chat to the CLI. ACP sessions are a further store (`~/.cursor/acp-sessions/`). | Documented by Cursor staff, 2026-08-31. | [Forum thread 165486](https://forum.cursor.com/t/local-ide-agent-chats-and-the-agent-cli-still-use-separate-session-stores/165486). |
| Passing an IDE composer id to `agent --resume` can overwrite that id's JSONL transcript. | Forum report. Not reproduced for this note. | Same thread, original report. Staff confirmed the separate stores, not this overwrite. |
| CLI chats resume from `~/.cursor/chats/<workspace-hash>/<chat-id>/store.db`. | Documented by Cursor staff in that thread, and by third-party notes. This host had no `~/.cursor/chats` directory on 2026-09-27, so the path was not opened here. | [Forum thread 165486](https://forum.cursor.com/t/local-ide-agent-chats-and-the-agent-cli-still-use-separate-session-stores/165486). |
| A Cloud Agent follow-up is `POST /v1/agents/<id>/runs`. A second run while the current one is `CREATING` or `RUNNING` returns `409`. | Documented. | [Cloud Agents API](https://cursor.com/docs/cloud-agent/api/endpoints). |
| Cloud agents started on the web or phone have been missing from the desktop sidebar. | Forum reports. Not a claim that every desktop fails this way. | [Forum thread 158067](https://forum.cursor.com/t/cloud-agents-do-not-show-in-agents-recent-agents-sidebar/158067). |
| CursorRemote drives a stock Electron Cursor via `--remote-debugging-port`, and it types with `Input.insertText` because it treats the composer as ProseMirror. | Their documented approach. It supports CDP as a candidate. It does not validate this client's selectors, Enter handling, or delivery check. | [CursorRemote](https://github.com/len5ky/CursorRemote), [architecture](https://github.com/len5ky/CursorRemote/blob/main/docs/architecture.md). |
| Setting a DOM value or calling `execCommand` skips the editor document. | Their rationale, not a reproduction on Cursor `3.21.18`. v1 may claim only the input method that was shown to submit on a named build. | Same architecture note. |
| After Cursor 3.8, some message-row attributes CursorRemote relied on changed. | Their issue report. Enough to treat selectors as build-specific. Not a test of this client. | [CursorRemote issue 44](https://github.com/len5ky/CursorRemote/issues/44). |
| Codex: moving a thread from CLI to desktop works when one client has stopped. Two live clients on one thread are unsupported, because each process has its own app server. | Maintainer statement. | [openai/codex#21513](https://github.com/openai/codex/issues/21513). |
| Codex `/app` opens `codex://threads/<id>` in the desktop app on macOS and native Windows, and is hidden on WSL and ordinary Linux. The Windows package path in that change mentions `resources/app.asar`. | Documented in the change. The `app.asar` mention does not prove the Linux build exposes a debugging port. | [openai/codex#25638](https://github.com/openai/codex/issues/25638). |
| A Codex Desktop task can expose `send_message_to_thread` with a target task and a follow-up prompt. | Seen in a Desktop review session on 2026-09-27. Public issues use the same name for task-to-task sends, and they also show the tool missing, rejected, or reporting failure after the target thread had already received the text. | Review session. [openai/codex#29886](https://github.com/openai/codex/issues/29886), [#40865](https://github.com/openai/codex/issues/40865), [#37075](https://github.com/openai/codex/issues/37075). |
| Claude Code's VS Code extension and the standalone CLI share history. `claude --resume` continues an extension conversation in the CLI. | Documented. That is continuation in the CLI, not a supported way to inject a line into the open panel. | [Switch between extension and CLI](https://code.claude.com/docs/en/vscode#switch-between-extension-and-cli). |
| The Claude desktop app, Claude Code on the web, and the VS Code extension each keep their own session history. A desktop-app session resumes in the app. | Documented. | [Manage sessions](https://code.claude.com/docs/en/sessions). |

---

## Discovery before any client

Do this pass for all three products first. Cursor can still be the first product implemented. Codex discovery does not wait on that client.

| Product | Question the pass has to answer |
|---------|----------------------------------|
| Cursor | Does the visible composer expose a stable conversation id? If it does not, v1 stays "currently visible composer" and the help text says so. Which DOM signal, on a named build, means the composer is idle, empty of text, empty of attachments, and empty of mention chips? Which signal means a user message was submitted? |
| Codex | `send_message_to_thread` is a lead inside a Desktop task. Can a process that is not a Desktop task call the same operation on the thread the human is watching? If the call exists, can its result be one of accepted, not sent, or delivery unknown? A tool name in a task does not establish a terminal command. |
| Claude | On a disposable session, does official resume leave the desktop as the live owner? See the Claude section. Shared history alone is not that answer. |

Record the answers in this file. Do not start the Cursor client from an unanswered Cursor row.

---

## Cursor v1 contract

### Command

```text
reply --window <exact-title> --visible-composer '<message>'
```

`--window` is required. It must match one page target exactly. Zero matches or two matches: **not sent**, print the titles, exit.

`--visible-composer` is required in v1. It is the operator's acknowledgement that the target is whatever composer is visible in that window when the send is attempted. There is no interactive pause and no `--yes`. A confirmation flag must not bypass the window match, the visible-composer recheck, the idle check, or the empty check.

A message that is empty or only whitespace is **not sent**.

`reply` is a placeholder name. This note does not create the file.

### Session state

v1 submits only when the visible composer is **idle**. The other states are **not sent**, and the client does not type.

| State | v1 |
|-------|----|
| Idle | The only state that may reach input events. |
| Running | Not sent. Steering a live turn is a later test, not v1. "The IDE will queue it" is not an acceptance result. |
| Awaiting approval or any permission dialog | Not sent. The client does not click the dialog. |
| Unavailable | Not sent. Missing composer, more than one composer match, or the window no longer matches. |

Passing a refusal table is not the acceptance test. The acceptance test is a named Cursor build, an idle empty composer, a message that arrives as a submitted user turn, and the refuse paths above leaving that turn unchanged.

### Empty composer

Before any input event, read the visible composer. **Not sent** if it holds text, an attachment, or a mention chip. v1 has no draft-replacement flag and does not clear the draft.

### Targeting recheck

Focusing a node does not pin later keystrokes to it. The procedure rechecks immediately before insert, and again immediately before Enter.

1. Resolve the window. Confirm the WebSocket host is loopback. Remember the target id from the debugging list.
2. Resolve the visible composer. Remember the best identity the build exposes (a conversation id if discovery found one, otherwise a weak token such as the selected chat title plus the composer node). Absence of a stable id stays inside the visible-composer contract. It is not a silent upgrade to "the conversation you meant."
3. Require idle and empty.
4. Immediately before insert, repeat steps 1–3. If the window, the visible composer, the idle state, or the empty state differs, **not sent**, and do not insert.
5. Insert the text.
6. Immediately before Enter, repeat the identity check and confirm the draft is exactly the inserted text, with no new chip or attachment. If that fails, do not press Enter. Outcome **not sent** if the draft still holds the text and no submitted turn appeared. Say that the draft was left holding the text.

### Delivery

Enter is not delivery. It can insert a newline, hit a popup, or do nothing. Disconnecting after Enter can also race a success the client never reads.

After the Enter attempt, one bounded read. No second read, no sleep-and-retry loop.

| Outcome | When | Retry |
|---------|------|-------|
| **accepted** | The same visible composer now shows that text as a submitted user message, and the draft is empty. The signal used is the one discovery recorded for this build. | Another command is a new message. |
| **not sent** | No submit event went out, or the draft still holds the text and the thread has no new submitted user message. | The operator may run the command again after looking. |
| **delivery unknown** | A submit event went out, and the bounded read cannot prove the message landed in that visible composer. | Do not retry. A retry can duplicate the message. |

The client prints one of those three words and exits. Suggested status codes, so a wrapper cannot confuse them: `0` accepted, `2` not sent, `3` delivery unknown.

### Loopback

Fetching `http://127.0.0.1:9222/json` only shows that this client can open that URL. It does not show who else can.

Before any target is used:

1. The listening socket's address is `127.0.0.1` or `[::1]`. Any other address, including `0.0.0.0` and an unspecified IPv6 address, is **not sent**.
2. The owning process is the Cursor process just started for this port.
3. The page's `webSocketDebuggerUrl` host is loopback. A list fetched through `127.0.0.1` can still hand back a WebSocket URL on another host. That URL is **not sent**.

Quit Cursor before starting it with the debugging port. A second `cursor` process attaches to the running app and does not open the port. That restart behavior was not re-tested for this revision. Treat it as a hypothesis until the discovery pass records it on the named build.

### What v1 does not do

It does not poll the transcript, write `state.vscdb`, append a JSONL file, or call `agent --resume`. It does not store the reply. The next invocation is a new attempt against whatever composer is visible then.

---

## Codex

Same habit. The attachment is still a discovery result.

Use the evidence rows above. On ordinary Linux, `/app` is not the implementation. `codex resume` makes the terminal the live client.

The lead to investigate is `send_message_to_thread`: a Desktop task tool that takes a target task and a follow-up prompt. Public reports already show a delivery-unknown failure mode, where the tool returns an error and the target thread has the message anyway ([openai/codex#29886](https://github.com/openai/codex/issues/29886)). That is why a Codex client, if the call is reachable outside a Desktop task, uses the same three outcomes and does not retry **delivery unknown**.

If that call is not reachable from an ordinary terminal, write that down and stop. Do not fall through to a debugging port unless the Linux desktop build is shown to be Electron and to expose a loopback port. Do not symlink `~/.codex` session directories between clients.

A Codex client must not start a second app server against a thread the desktop already has open ([openai/codex#21513](https://github.com/openai/codex/issues/21513)).

---

## Claude

Same habit. The docs confirm shared history between the VS Code extension and the CLI, and they describe continuing that conversation in the CLI. They do not describe injecting a line into the panel while the panel remains the owner of the turn. [Switch between extension and CLI](https://code.claude.com/docs/en/vscode#switch-between-extension-and-cli).

A panel that repaints a CLI turn does not, by itself, show who owns the running session, where a tool approval is decided, or what a later message typed in the panel does.

On a disposable session, record all of these before calling official resume suitable:

| Check | Pass looks like |
|-------|-----------------|
| Alternating messages | A short line from the CLI, then one from the panel, then one from the CLI again, in one session, in that order, with no lost or duplicated turn. |
| Tool approval | An approval raised by a CLI turn is decided where the operator expects, and the panel does not approve it on its own. |
| Overlap | A turn that is still running on one surface, plus a message from the other, has one recorded result: queued, rejected, or steered. "Something happened" is not a pass. |

If those checks pass, the Claude reply command is official resume, and this note says so with the build versions that passed. If they fail, the panel is still a separate live client. Only then is a UI send path a candidate, and the extension composer is a webview target, not the editor's top-level page. Matching a window title is not enough to find it.

The desktop app stays a separate store until its own check says otherwise ([Manage sessions](https://code.claude.com/docs/en/sessions)).

---

## Order of work

| Step | Work | Done when |
|------|------|-----------|
| 1 | Attachment discovery for Cursor, Codex, and Claude | The three questions in the discovery table are answered in this file. |
| 2 | Cursor v1, only after a human go-ahead | On one named build: idle, empty, explicit window, visible composer, bounded check, no retry on unknown. Running, approval, occupied, and ambiguous targets stay **not sent**. |
| 3 | Codex or Claude client | Only for an attachment step 1 actually found. |

This note is not step 2.

---

## Open tasks

- [ ] Cursor discovery: record whether the visible composer has a stable conversation id on the inspected build. Record the idle, empty, attachment, mention-chip, and "submitted user message" signals.
- [ ] Cursor discovery: record the listening address, owning process, and `webSocketDebuggerUrl` host for a Cursor started with the debugging port. Record whether a second `cursor` launch attaches to the running process.
- [ ] Decide the command name and path. This note does not add that file.
- [ ] Codex discovery: can a process outside a Desktop task invoke `send_message_to_thread` on the thread the desktop is showing, and can the result distinguish accepted, not sent, and delivery unknown?
- [ ] Codex discovery: on ordinary Linux, confirm `/app` is absent before treating a debugging port as a candidate.
- [ ] Claude discovery: run the alternating-message, tool-approval, and overlap checks on a disposable session. Record versions. Do not treat a repaint as a pass.
- [ ] Claude desktop: confirm it is still a separate session store before any UI work.
