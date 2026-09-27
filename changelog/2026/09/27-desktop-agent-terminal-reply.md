# Terminal reply into a desktop agent session

| Field | Value |
|-------|--------|
| **Date** | 2026-09-27 |
| **Status** | **plan / review**. The habit and the Cursor attachment are described. Nothing in this note is an implementation go-ahead. |
| **Scope** | A short reply typed in a terminal on the same machine, landing in the desktop agent session the human is already watching. Cursor is the worked example. Codex is the same habit with a different attachment, checked before any code. Claude comes after those two. |
| **Out of this plan** | A gates row. A new pivot, hook, include, or extension. Enabling `agent`, `asc/cursor`, `asc/codex`, or `asc/claude`. A cloud-agent follow-up API. An MCP tool that blocks until stdin has a line. Writing into a session database or a transcript log. A phone, browser, or chat-app relay. Shipping a script. |

`gates.core.yml` is a later agent approval surface. Do not add a row for this note.

This note was written on branch `to-review`. That branch was already level with `origin/to-review`, and `git pull --ff-only` reported already up to date.

---

## The habit

The desktop session stays the monitor: the thread, the tool calls, the diffs. The terminal submits one short user message into that same conversation and then gets out of the way. The reply client does not keep its own transcript.

| Piece | Role |
|-------|------|
| Desktop session | The conversation the human watches. |
| Reply client | One command on localhost. It submits the text and exits. |
| Session store | Whichever store that desktop product already uses. The client does not become a second store. |

The three products do not share an attachment. A command that works for one is not assumed for the next. The order is Cursor, then Codex, then Claude, because that is the order in which the official session bridge is missing, partial, or already present.

---

## What already fails this habit

These exist and do something nearby. They are not this plan.

| Approach | What it actually does |
|----------|------------------------|
| Cursor `agent --resume <id>` | Resumes a CLI chat under `~/.cursor/chats/<workspace-hash>/<chat-id>/` (`meta.json` and `store.db`). An IDE composer id is a different store. Cursor staff confirmed on 2026-08-31 that there is no shared session id and no IDE-to-CLI bridge. Passing an IDE composer id to `--resume` does not load that conversation, and it can overwrite the JSONL transcript for that id. |
| Appending `~/.cursor/projects/<workspace>/agent-transcripts/<composer-id>/*.jsonl`, or writing `state.vscdb` | The IDE sidebar loads the composer record in `~/.config/Cursor/User/globalStorage/state.vscdb` (`composerHeaders`, `composerData`, `bubbleId`). The JSONL is a log beside that record. Writing either file does not submit a user message. |
| Cursor Cloud Agent, `POST /v1/agents/<id>/runs`, or a CLI message that starts with `&` | A cloud run. A follow-up is accepted only when the current run is finished (`409` while it is `CREATING` or `RUNNING`). The desktop list of cloud agents is a separate sync path and has failed open in the web-to-IDE direction. |
| An MCP tool that waits on stdin | Stays inside the IDE chat, and only while the agent is blocked on that tool. A line typed at any other time never enters the composer. |
| `codex resume`, `claude --resume` | Opens that product's session on the client that ran the command. Useful when the terminal is allowed to become the live client. This habit keeps the desktop as the live client. |

---

## Prior art, send path only

[CursorRemote](https://github.com/len5ky/CursorRemote) already drives a local Cursor window. Cursor stays a stock Electron app, launched with `--remote-debugging-port`. A relay on the same machine speaks the Chrome DevTools Protocol. Its public architecture is the source for the Cursor steps below.

This plan keeps the send path: find the open composer, type, press Enter. It leaves out the rest of that project: DOM polling, a phone UI, a chat-app transport, and anything that listens beyond localhost.

The reason the send path uses the input pipeline, from that project's own notes: the composer is ProseMirror / TipTap. Setting a DOM value, or `document.execCommand`, updates the element and skips the editor document, so the send control still sees an empty draft. `Input.insertText` and `Input.dispatchKeyEvent` go through Chromium's input pipeline, which that editor handles as `beforeinput` / `input`.

---

## Cursor session, as it stands

Two stores, one log.

| Store | Path | What resumes it |
|-------|------|-----------------|
| IDE composer | `~/.config/Cursor/User/globalStorage/state.vscdb` | The editor sidebar. |
| IDE transcript log | `~/.cursor/projects/<workspace>/agent-transcripts/<composer-id>/<composer-id>.jsonl` | Nothing. Same composer id as the sidebar row. The sidebar does not load the chat from this file. |
| CLI chat | `~/.cursor/chats/<workspace-hash>/<chat-id>/store.db` plus `meta.json` | `agent ls`, `agent resume`, `agent --resume <chat-id>`, `agent --continue`. |
| ACP session | `~/.cursor/acp-sessions/` | `agent acp`. A third store. |

`agent create-chat` prints a CLI chat id. The local CLI help has no flag that attaches to an open IDE composer. `cursor --chat` opens another IDE chat window. It is not a terminal reply pipe.

---

## Cursor client, step by step

One command. It connects, types, disconnects. It does not poll the transcript, because the IDE is the display.

### 1. Open the debugging port on a fresh process

Quit Cursor completely. A second `cursor` process attaches to the one already running and does not open the port.

Start Cursor with the remote debugging port. Then read `http://127.0.0.1:9222/json`. The body is a list of page targets. Confirm the listen address is loopback. If that port answers on another interface, stop and do not send a message. The protocol can click, type, approve tools, open files, and change settings. It is not limited to the composer.

### 2. Choose the editor page

Every Cursor window is a `page` target on that one port. Each entry has a title and a WebSocket URL. Keep the workbench whose title is the workspace in front of the human. The first entry in the list is often a different window. If more than one workbench matches, the command exits and prints the titles. It does not pick one.

Open the WebSocket for that single target.

### 3. Find the composer and stop if it is ambiguous

Ask the page, through `Runtime.evaluate`, for the chat input. The node is a ProseMirror editor, not a plain textarea. The attribute that finds it belongs to one Cursor build. Record it when the client is first tried, and treat a Cursor upgrade as a reason to look again. A public report against CursorRemote after the 3.8 DOM shift is enough evidence: message nodes lost `data-message-index`, and a finder that assumed the old tree returned nothing.

Zero matches, or more than one match: exit without typing. Do not fall through to a nearby contenteditable.

### 4. Submit through the input pipeline

On that node only:

1. Focus it and click it, so the draft that receives the keys is the open composer.
2. Select the existing draft and clear it (select-all, then Backspace), so a half-written line is not prefixed onto the reply.
3. `Input.insertText` with the reply.
4. `Input.dispatchKeyEvent` for Enter, which is the same submit the human would press.

The IDE then queues or sends that line in the conversation already on screen. Tool calls and the assistant reply stay in the sidebar.

### 5. Disconnect

The client exits. It does not store the composer id, the reply, or a copy of the thread. The next reply is another run of the same command against whatever composer is open then.

What a day looks like:

```text
# once per Cursor process that should accept a reply
# quit the running app first
cursor --remote-debugging-port=9222

# each follow-up, from any terminal on this machine
reply 'looks good, continue with the tests'
```

`reply` is a name for the client. This note does not create the file.

### What the client must refuse

| Situation | Behavior |
|-----------|----------|
| Port is not loopback | Exit before connecting. |
| Title was not passed, or two workbenches match | Print the titles and exit. |
| Composer node is missing or duplicated | Exit. Print that the finder needs a recheck after the upgrade. |
| A draft is present and `--replace-draft` was not passed | Exit. Wiping a human's half-typed line is a separate, explicit flag. |
| The text is empty | Exit. |

Printing the window title it is about to type into is part of the command's stdout, so a reply aimed at the wrong workspace is visible before Enter is sent. A `--yes` flag is what skips that pause. The default is to print the title and require the flag, or to accept the title as an argument that must match.

---

## Codex counterpart

Same habit. The attachment is not known to be the debugging port, and this note does not pretend it is.

Checked on 2026-09-27:

| Fact | Source |
|------|--------|
| A thread can move from the CLI to the desktop app when one client has stopped and the other resumes it. | Codex maintainer note on [openai/codex#21513](https://github.com/openai/codex/issues/21513). |
| Two clients on one thread at the same time are unsupported. Each client runs its own app-server process, and those processes do not share a live turn. A prompt from the desktop while a CLI session was running has diverged the two views. | Same issue. |
| `/app` opens the current CLI thread in Codex Desktop with `codex://threads/<id>`. It is implemented for macOS and native Windows. It is hidden on WSL and on ordinary Linux. | [openai/codex#25638](https://github.com/openai/codex/issues/25638). |
| The Windows desktop package is an Electron app (`resources/app.asar` shows up in that handoff path). | Same issue. That does not by itself mean the Linux build exposes a debugging port. |

On ordinary Linux, `/app` is not the implementation. `codex resume` makes the terminal the live client, which breaks the habit of watching the desktop.

Discovery before any Codex code:

1. With the desktop showing a thread, is there a local app-server method that appends one user message to that thread and lets the desktop render the turn?
2. If yes, the Codex client is that call. It names the thread id the desktop already has open. It does not start a second app-server against the same thread.
3. If no, and the desktop build is Electron, reuse the Cursor steps: loopback debugging port, one page target, one composer node, input pipeline, fail closed. Confirm the Linux binary before writing that down as the design.
4. Do not symlink `~/.codex` session directories between clients. That workaround is how the two views diverge.

---

## Claude, after Cursor and Codex

Same habit. Official session sharing is further along, and it still may not be this habit. No Claude client until the two checks below are done.

Checked on 2026-09-27 against the Claude Code docs:

| Fact | What it means here |
|------|--------------------|
| The VS Code extension and the standalone CLI share conversation history. `claude --resume` in a terminal continues an extension conversation. | [Use Claude Code in VS Code](https://code.claude.com/docs/en/vscode). The turn runs in the CLI. |
| The desktop app, Claude Code on the web, and the VS Code extension each keep their own session history. The CLI and the extension's local history are the pair that is shared. A desktop-app session resumes in the desktop app. | [Manage sessions](https://code.claude.com/docs/en/sessions). |
| `claude --resume <name>` and `claude -p` can continue a named session without the picker. | That submits a prompt as the CLI client. It does not say the open panel repaints the live turn. |

Two checks, in order:

1. Start a session in the VS Code extension panel. From another terminal, `claude -p --resume <id>` with one short line. Watch the panel. If the panel shows that line and the rest of the turn, Claude needs no UI client for the extension. The reply command is the official resume.
2. If the panel stays stale, or the session to watch is the desktop app rather than the extension, the panel is a separate live client. Only then consider the Cursor send path. The extension's composer lives in a webview, so a debugging port on the editor window may not see it until the client attaches to that webview target. Find the target the same way as a Cursor window: list pages, match one title, fail if two match.

---

## Order of work

| Step | Product | Done when |
|------|---------|-----------|
| 1 | Cursor | A human go-ahead exists, then a send-only client passes the refuse table on one local window. |
| 2 | Codex | The discovery questions above are answered in this file. A client is written only for the attachment that discovery found. |
| 3 | Claude | The panel check above is answered in this file. A UI client is written only if official resume leaves the panel stale. |

This note is step 0. It does not authorize step 1.

---

## Open tasks

- [ ] On a current Cursor build, record the composer node attribute that a fail-closed finder should use. Do not guess a second selector when the first misses.
- [ ] Decide the command name and the path of the Cursor client. This note does not add that file.
- [ ] Codex: with the desktop thread open, check for a local app-server follow-up that the desktop renders. Record the answer here.
- [ ] Codex: on ordinary Linux, confirm `/app` is absent before treating the debugging port as the candidate.
- [ ] Claude: run one `claude -p --resume` against an open VS Code panel and record whether the panel shows the turn.
- [ ] Claude desktop: confirm it is still a separate session store before any UI work.
