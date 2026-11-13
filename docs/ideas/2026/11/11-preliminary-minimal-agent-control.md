# Thread control as a preliminary to agent-plan

> **2026-11-13 update:** The [active-claim direction](13-local-action-records.md) replaces retained final thread records with files removed after confirmed completion. The linked thread-control plan requires revision before implementation; a real long-running `agent-plan` operation remains unauthorized. Earlier settled-record examples below are orientation, not the new file-lifecycle contract.

**Status:** Direction-setting idea. The outcome, its limits and the sequence below are proposed; no implementation or unattended operation is authorized by this document.  
**Updated:** 2026-11-12 (added Microsoft AI Engineering Coach to the source list; prior orientation 2026-11-11)

## Initial prompt

Can you review docs/ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md in the context of the latest work done in docs/specs/asc?

In particular, I'm inclined to think that the need for control of agent (threads) deserves to be part of this plan as a preliminary step, perhaps as a separate plan to be executed first.

Does it make sense?

## Direction

Yes: process control deserves to be treated separately from `agent-plan`'s chat, staging, isolation and readiness contracts. Before an unattended or real long-running `agent-plan` loop is operated, the proposed outcome is that an operator can identify the run, prevent new starts, and stop a running instance with a known result. The scope and limits of those guarantees still need to be established.

This is a dependency on **operation**, not necessarily on all implementation. Host feasibility work, provider hooks and isolated tests can proceed while the control approach is investigated. The limits in this idea are carried into the proposed plan [thread control before agent-plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md). This idea stays the orientation. That plan is not an implementation go-ahead.

The draft specs distinguish three things:

- A **thread** is an ASC-owned process tree started from an entry point; see [agent threads](../../../specs/asc/agent-threads.md).
- A **chat** is a product conversation that can outlive the process driving a turn; see [agent chats](../../../specs/asc/agent-chats.md).
- A **model server** is a provider service, not an ASC run.

The proposed [`agent-plan` loop](10-agent-plan-cursor-codex-ollaya.md) drives chats and may be long-running. Its design covers roles, staging, isolation and `plan-is 'ready'`, but does not establish how its running process is supervised or stopped. The thread spec records existing gaps including no stop action and pid-only liveness. Stopping a process does not itself end a product session; a chat may remain resumable.

## External orientation: DeerFlow Harness vs App

Read 2026-11-11 from DeerFlow’s published docs ([Harness vs App](https://deerflow.tech/en/docs/introduction/harness-vs-app), [Agents and Threads](https://deerflow.tech/en/docs/application/agents-and-threads), [Lead Agent](https://deerflow.tech/en/docs/harness/lead-agent)). External product docs; not an ASC contract and not a proposal to adopt DeerFlow.

**Layering.** DeerFlow splits a reusable **Harness** (runtime: skills, tools, sandbox, memory, subagents, configurable execution) from an **App** (opinionated product that assembles those primitives into conversations, tasks, artifacts and operations). ASC already leans the same way: thread wrap / list / status are runtime machinery; `agent-plan`, gates and operator brief are an assembled workflow. Process control belongs with the runtime layer. It should not be redesigned inside the `agent-plan` chat and staging contracts, and it should not wait on an App-like UI or checkpoint database.

**Conversation versus run (vocabulary clash).** In DeerFlow, a **thread** is the durable conversation (messages, artifacts, title, agent reference); each user message triggers a **run** that updates that state. Checkpointing makes the conversation survive process restarts. ASC uses the words differently: ASC **chat** ≈ DeerFlow thread; ASC **thread** ≈ DeerFlow run (the process tree for one entry). Keep ASC names. Orient identity and stop at the ASC thread (the run), not at the chat id or the plan path. Plan Markdown is closer to DeerFlow’s accumulated artifacts: durable work product, not the process to kill.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from the split |
|---|---|
| What does identify / stop / hold address? | The ASC **thread** (process / run). Chat and plan bytes outlive stop. |
| Where does control live? | Runtime / wrap layer. `agent-plan` consumes it; it does not own the supervisor design. |
| Is a chat pointer or session store required for the minimum outcome? | No. DeerFlow keeps conversation state so *resume* survives restart; ASC already treats product chats as foreign stores. Pointers may help later; they are not the stop guarantee. |
| Hold vs authorization? | Hold is runtime refuse-start. Authorization stays in the App/policy layer (gates / human instruction), as [agent plans](../../../specs/asc/agent-plans.md) already separates readiness from go-ahead. |
| Rename ASC “thread” to match DeerFlow? | No. Document the mapping when comparing; do not rename. |

**What DeerFlow does not settle.** Their App docs emphasize checkpointed conversation state and sandbox-mounted thread data. They do not establish, for ASC, how to terminate a provider harness process tree, what a stop result may claim, or how a hold file should be scoped. Whole-tree termination and host guarantees remain the investigation below. Checkpoint-style durability is also not a substitute for stop: surviving a restart is not the same as an operator ending a live run with a known result.

## External orientation: DeepSeek Harness

Read 2026-11-11 from [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) (README, [architecture](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md), [sandbox](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/subsystems/sandbox.md), [workflow](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/workflow/workflow/README.md), [SAFETY.md](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md), and published notes on worker-thread cancel/dispose). Developer-preview external software; not an ASC dependency and not a proposal to adopt it. Their [safety notice](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md) states sandboxing and approvals reduce risk but do not guarantee isolation.

**Layering (complements DeerFlow).** DeepSeek Harness is a plugin-composed runtime (Cordis): profiles/bundles assemble web, headless, SDK, and ACP entry points on a shared base. That again separates runtime primitives (session log, agent loop, sandbox, tools) from product surfaces. ASC’s analogous split stays: wrap/control in the runtime layer; `agent-plan` as a consumer workflow.

**Holder-owned run, cancel, dispose (stronger on control than DeerFlow’s App docs).** Their workflow contract is explicit about ownership and stop semantics:

- A **run is holder-owned**: the caller that starts it must `dispose()`; unloading the engine **prevents new starts** but does **not** revoke accepted runs.
- `cancel` records a reason and asks cooperative stop; after a grace window the host may force-terminate the worker and settle the run as cancelled.
- The run **result does not reject**: settlement carries a known `stopReason` (for example error vs cancelled).
- Observability after forced stop is limited: they document that termination can only report **host-observed** child starts; work still queued inside the worker may be unknowable.
- A worker-thread (or `worker.terminate()`) stop is **containment of that thread**, not a security boundary and **not** a guarantee that OS processes the worker spawned are gone.

That maps cleanly onto ASC’s proposed outcome: **hold ≈ refuse new starts**; **stop ≈ cancel/dispose of an accepted run**; **known result ≈ settled status with explicit non-claims**. It also matches the existing lean that a hold file is not a substitute for stopping work already running.

**Sandbox honesty (aligns with ASC enforced / weakened).** Their process sandbox is a **file-effect** policy (`read-only` / `workspace-write` / `danger-full-access`) with reported `full` or `partial` enforcement. Confined policies **fail closed** (`SANDBOX_UNAVAILABLE`); silent unconfined passthrough is forbidden. Network and process visibility are **outside** that vocabulary. Consumers must distinguish runner failure (command never ran) from policy denial (confinement worked). ASC already needs the same discipline for `writer_isolation` / `reviewer_isolation` and for stop results: never advertise a stronger guarantee than the host proved.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from DeepSeek Harness |
|---|---|
| Hold vs stop | Hold/unload blocks **future** starts only; accepted runs need an explicit stop/dispose path. |
| Shape of a stop result | Prefer a **settled** record with a known reason (stopped/cancelled/exited/error), not a rejected/unknown void; list what was observed. |
| Soft then hard stop | Cooperative cancel + grace + force is a candidate pattern; the grace and force boundaries must be stated. |
| Who owns cleanup? | DeepSeek makes the run handle holder responsible for disposal. ASC still needs to decide who owns cleanup when the starter exits or a separate operator requests stop. |
| What stop may claim | Claim only what the supervisor observed (recorded pid/unit/children at stop time). Do not imply escaped or never-started children exited. |
| Sandbox vs process stop | File-effect sandbox and process-tree stop are separate guarantees; both need claims and non-claims. |
| Adopt DeepSeek Harness? | No. Use the contracts as orientation; ASC stays on its wrap/Make/bash surface. |

**What DeepSeek Harness does not settle.** It does not choose ASC’s supervisor (systemd user unit vs process group vs today’s subshell), hold-file location, or authorization policy. Their worker-thread engine is a different process model from Cursor/Codex harnesses ASC will wrap. Their security discussions also show that “terminate the worker” and “confine file effects” can diverge in practice—another reason ASC must keep stop claims narrow until host probes say otherwise.

## External orientation: Goose

Read 2026-11-11 from [goose guides](https://goose-docs.ai/docs/category/guides) and [aaif-goose/goose](https://github.com/aaif-goose/goose) (CLI commands, permissions, CLI/ACP providers, recipes, [roaming agents](https://goose-docs.ai/docs/guides/roaming-agents), ACP app notes). External product; not an ASC dependency and not a proposal to adopt Goose or ACP as ASC’s control plane.

**Session, turn, and backend are three different stops.** Goose’s durable unit is a **session** (local conversation history; resume by session id). Interactive work interrupts with Ctrl+C on the **current request**; emptying the line and Ctrl+C exits the session. ACP clients are told a stop button should send `session/cancel` for the **active turn**, not kill the backend `goose serve` process. The prompt response reports a **`stopReason`**. That reinforces a three-way split ASC should keep explicit:

| Layer | Goose analogue | ASC analogue | Control act |
|---|---|---|---|
| Durable conversation | session | chat (product store) / plan file | leave intact on stop |
| In-flight work unit | turn / request | one `agent-plan` loop or one chat turn | cooperative cancel with a known reason |
| Supervising process | Desktop-backed or remote `goose serve` | ASC **thread** (wrap / entry process tree) | identify, hold new starts, process stop |

So the minimum ASC outcome (identify / hold / stop with a known result) targets the **thread**. A future cooperative cancel inside the orchestrator is useful but is not the same guarantee as stopping the process tree—and neither erases chats or plan bytes.

**Permission mode is not sandbox is not process stop.** Goose separates [permission modes](https://goose-docs.ai/docs/guides/managing-tools/goose-permissions.md) (`auto` / `approve` / `smart_approve` / `chat`) from file/tool isolation (including CLI-provider sandbox flags and optional `--container` for extensions). ACP docs state plainly that permission callbacks are **not** a sandbox: tools still run with the backend’s machine access. That matches ASC’s readiness vs authorization vs isolation vs process-control axes: a hold or gate answer does not confine writes, and bwrap on a writer turn does not stop the outer `agent-plan` thread.

**Forked OS children remain a documented residual.** Goose roaming notes that revoking a peer stops the agent and drops in-flight turns at the next step, but “an OS process a tool had already spawned … may run to completion — revocation stops the agent, not processes it already forked.” Same non-claim ASC must keep when stating stop results for Cursor/Codex harness children.

**Recipes and headless run are assembled workflows, not the supervisor.** [Recipes](https://goose-docs.ai/docs/guides/recipes/) package extensions, prompts and settings; `goose run` executes instructions or a recipe, with `--interactive`, `--resume`, `--no-session`, `--max-turns`, and optional containers. That is closer to `agent-plan` as a packaged loop than to ASC thread wrap. Orientation: keep process control out of the recipe/plan contracts; loop bounds (`max-turns`) and “no session file” are orchestrator concerns, not substitutes for stop/hold.

**Remote / roaming access is authorization of a control plane, not ASC’s first slice.** Roaming is framed as an authenticated ACP **transport** to a host that already runs the agent; acceptance is all-or-nothing and grants tool/shell reach. Cross-host listing and remote drive stay outside this idea’s scope (as already excluded). Useful only as a reminder that “who may start or steer” is policy, while “can this host’s operator stop what is running here” is the local runtime outcome.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from Goose |
|---|---|
| What does stop address first? | The ASC **thread** (supervising process). Optionally later: cooperative cancel of the in-flight loop/turn. |
| Must stop kill the chat backend’s notion of session? | No. Prefer turn/loop cancel semantics that leave durable conversation/plan intact when possible. |
| Hold vs approve/mode vs sandbox? | Three different controls. Hold = refuse new ASC starts. Gates/modes = authorization. Sandbox/container = effect confinement. |
| Stop result non-claim | Stopping the agent/thread does not imply already-forked tool processes exited. |
| Recipes / `agent-plan` | Assembled workflow; consume thread control; do not redefine it. |
| Adopt Goose or ACP for ASC control? | No. Keep Make/`thread-*` (and later stop) as ASC’s local verbs. |

**What Goose does not settle.** It does not choose ASC’s systemd vs process-group supervisor, hold-file layout, or gates design. Desktop/CLI session storage and ACP transport are Goose-specific. Their permission and container features do not replace host probes for ASC wrap stop completeness.

## External orientation: Aider

Read 2026-11-11 from [aider docs](https://aider.chat/docs/) and [Aider-AI/aider](https://github.com/Aider-AI/aider) ([commands](https://aider.chat/docs/usage/commands.html), [chat modes](https://aider.chat/docs/usage/modes.html), [scripting](https://aider.chat/docs/scripting.html), [git](https://aider.chat/docs/git.html), [docker](https://aider.chat/docs/install/docker.html), [options](https://aider.chat/docs/config/options.html)). External product; not an ASC dependency and not a proposal to adopt Aider.

**One process, durable chat file, git as recovery.** Aider is mostly a single terminal (or browser) process over a git working tree. Conversation durability is a **chat history file** (default `.aider.chat.history.md`), optionally restored on next launch—not a separate session server. [Ctrl-C](https://aider.chat/docs/usage/commands.html) interrupts the current LLM response; the **partial reply stays in the conversation**. `/exit` / `/quit` end the application. That is a simple form of the same split: interrupt in-flight work without erasing history; exiting the process is separate from keeping the history file.

**Scripted one-shot runs are holder-owned processes.** [`--message` / `--message-file`](https://aider.chat/docs/scripting.html) send one instruction, apply edits, then exit (chat mode off). Shell loops and the Python `Coder.run()` API compose multiple such runs. Orientation for ASC: an unattended `agent-plan` is closer to a **long-lived holder-owned process** than to Aider’s default interactive REPL, but Aider’s scripting model still says the **OS process is the run**—stopping it is process control; the history file and git commits are leftover artifacts, not the thing to “cancel.”

**Git undo is artifact recovery, not process stop.** Aider auto-commits edits, separates dirty-user commits from aider commits, and offers `/undo` to discard the last aider commit. That is a strong **work-product** recovery story. ASC already has related ideas for plan bytes (staging, promotion, digest). Orientation: do not confuse “revert what the agent wrote” with “stop the agent process.” Both matter; only the latter is this idea’s minimum outcome.

**Modes and dry-run are capability / effect knobs.** [Chat modes](https://aider.chat/docs/usage/modes.html) (`code` / `ask` / `architect` / `help`) change whether and how files are edited (ask never edits; architect splits propose vs apply across models—loosely analogous to writer/reviewer roles). `--dry-run` proposes without modifying files; `--yes` skips confirmations. Docker runs aider with the repo bind-mounted and notes that `/run` executes **inside the container**, not on the host. Again: mode/autonomy ≠ file-effect confinement ≠ killing the aider process.

**Architect dual-model is workflow, not supervision.** Architect + editor is a product pattern for better edits, similar in spirit to ASC’s writer/reviewer loop, not a process-control design.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from Aider |
|---|---|
| Where is the run? | The aider (or ASC wrap) **process**. History files and git commits outlive it. |
| Interrupt vs exit | Interrupt in-flight model work without discarding conversation; exit/kill ends the process. ASC should keep that distinction when stating stop claims. |
| Scripted / unattended | One-shot `--message` then exit is the simple unattended shape; multi-message loops still need an owner who can stop the process. |
| Undo / staging | Recover or reject **artifacts** (git, plan staging). Do not treat that as the stop guarantee. |
| dry-run / ask / --yes | Effect and confirmation policy—not hold, not thread-stop. |
| Adopt Aider? | No. Useful as a minimal reference for “pair-programming agent in one process,” not as ASC’s orchestrator. |

**What Aider does not settle.** No formal cancel/dispose result vocabulary, no cgroup story, no hold-file for refusing new starts across a fleet of entries. Docker is optional whole-tool isolation, not ASC’s per-role bwrap profiles. Host probes for ASC wrap stop completeness remain open.

## External orientation: OpenHands

Read 2026-11-11 from [OpenHands introduction](https://docs.openhands.dev/overview/introduction) and related docs ([Agent Canvas architecture](https://docs.openhands.dev/openhands/usage/agent-canvas/architecture), [workspace](https://docs.openhands.dev/sdk/arch/workspace), [pause/resume](https://docs.openhands.dev/sdk/guides/convo-pause-and-resume), [persistence](https://docs.openhands.dev/sdk/guides/convo-persistence), [security & confirmation](https://docs.openhands.dev/sdk/guides/security), [docker sandbox](https://docs.openhands.dev/sdk/guides/agent-server/docker-sandbox), [archive sandbox](https://docs.openhands.dev/cookbook/archive-sandbox)), plus [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands). External ecosystem; not an ASC dependency and not a proposal to adopt OpenHands, Agent Canvas, or their cloud control plane.

**Component map (strongest layering statement in this survey).** The introduction separates:

| Component | Owns |
|---|---|
| Agent Canvas | Browser client / control center — **not** the runtime or sandbox |
| Agent Server / Software Agent SDK | Conversation execution, tools, workspaces (REST/WebSocket) |
| Automation Server | Scheduled and event-driven run lifecycle |
| Sandbox / workspace | Files, processes, credentials, network the agent may touch |
| Sandbox Server (community) | Standalone API that creates/manages sandboxes hosting Agent Server |

Canvas “presents backend state and sends requests”; Agent Server executes; the workspace/sandbox is the isolation boundary. That is DeerFlow’s harness/app split made more operational, and it matches ASC: Make/`thread-*` and wrap are runtime; `agent-plan` is a consumer workflow; bwrap/profiles are effect isolation; gates/automations-style enablement are policy—not one blob.

**Pause, stop, and delete are different results with different resource claims.** SDK [`conversation.pause()`](https://docs.openhands.dev/sdk/guides/convo-pause-and-resume) requests pause between run-loop steps; an in-flight LLM call may finish first; `execution_status` is observable; `run()` resumes. Cloud/enterprise sandbox docs distinguish RUNNING / PAUSED (compute down, storage kept) / STOPPED (pod gone, PVC often kept for resume) / DELETED (storage released). Orientation for ASC: a stop result must say what stopped (loop vs process vs sandbox) and what was **not** claimed (workspace files, chats, already-running tool children). Pause is optional and out of this idea’s first slice; the honesty about **when** pause takes effect and what storage survives is the useful part.

**Confirmation policy ≠ workspace isolation.** [Security & confirmation](https://docs.openhands.dev/sdk/guides/security) (`AlwaysConfirm` / `NeverConfirm` / `ConfirmRisky` + analyzer) gates whether actions execute. [Local vs Docker/remote workspace](https://docs.openhands.dev/sdk/arch/workspace) gates where commands run. Same three-axis lesson as Goose/Aider: authorization ≠ confinement ≠ process/thread stop.

**Persistence outlives the process; automations are a separate lifecycle.** Conversation persistence restores history and `execution_status` across sessions. Automation Server enable/disable and schedules are closer to “may new unattended work start?” than to stopping one live ASC thread—useful analogy for **hold**, not for stop.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from OpenHands |
|---|---|
| Where does control UI live vs execution? | Client/control center must not be confused with the supervising process. ASC’s stop targets the wrap/thread, not a doc or chat UI. |
| Pause vs stop vs discard artifacts? | Separate verbs with separate claims (compute vs storage vs conversation). ASC minimum outcome is stop-with-known-result + hold; pause and full workspace teardown stay optional/out of slice. |
| When does cooperative pause apply? | Between steps; not guaranteed mid-LLM or mid-tool. State that non-claim if ASC adds loop cancel later. |
| Confirmation / gates | Policy for actions—not thread-stop, not sandbox completeness. |
| Sandbox lifecycle | Useful vocabulary for *claims*; ASC’s first hosts may only have process-group/systemd, not K8s PVCs—do not import their resource model wholesale. |
| Adopt OpenHands? | No. Use the component and lifecycle vocabulary; keep ASC Make/bash wrap. |

**What OpenHands does not settle.** It does not choose ASC’s local supervisor (systemd vs process group), hold-file path, or gates design. Their Agent Server + sandbox stack is heavier than wrapping Cursor/Codex CLIs. Host probes for what ASC’s existing wrapper can actually stop remain open.

## External orientation: Hermes Agent

Read 2026-11-11 from [Hermes Agent docs](https://hermes-agent.nousresearch.com/docs) and [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) ([architecture](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture), [security](https://hermes-agent.nousresearch.com/docs/user-guide/security), [gateway internals](https://hermes-agent.nousresearch.com/docs/developer-guide/gateway-internals), [SECURITY.md](https://github.com/NousResearch/hermes-agent/blob/main/SECURITY.md)). External product; not an ASC dependency and not a proposal to adopt Hermes.

**One agent core, many entry points.** Architecture puts CLI, messaging gateway, ACP, batch, API, and cron in front of a shared `AIAgent` loop. Session storage (SQLite) and tool backends (local / Docker / SSH / serverless sandboxes) sit beside it. Design principles call out **interruptible** execution (cancel API/tool work mid-flight), **platform-agnostic core**, and **profile isolation** (each profile its own home, sessions, and gateway PID). Orientation: ASC’s wrap/thread is the local supervising process; messaging UIs and `agent-plan` are entry points/consumers—not alternate supervisors.

**`/stop` and interrupt are first-class while a run is active.** Gateway inbound handling uses a two-level guard: new messages either queue+interrupt or, for `/approve`, `/deny`, `/stop` (and a few peers), bypass the running-agent guard and dispatch inline. Other traffic can call `running_agent.interrupt()`. That is Goose’s turn-cancel idea with an explicit operator verb. ASC’s minimum outcome still targets process stop; Hermes strengthens the case for a **named cooperative stop** that works while the loop is busy, without conflating it with killing the gateway.

**Authorization ≠ session id; unattended has its own approval policy.** Security docs separate who may talk to the agent (allowlists, DM pairing) from dangerous-command approval modes (`smart` / `manual` / `off`), including `unattended_mode` / `cron_mode` / `single_query_mode` defaults that **deny** risky commands when no human is there. [SECURITY.md](https://github.com/NousResearch/hermes-agent/blob/main/SECURITY.md) states session identifiers are **routing handles, not authorization boundaries**. Same lesson for ASC: knowing a chat or entry name does not authorize unattended work; hold and gates remain distinct from identity.

**Container isolation does not waive self-termination of the controller.** Dangerous-command checks may skip for container backends on the rationale that the container is the **host-safety** boundary—but Hermes carved out **self-disruption** (killing/restarting the gateway, `hermes gateway stop`, related patterns) so those still require approval, and hard-blocks some gateway self-restarts even in YOLO. Rationale: restarting the gateway from inside a turn can tear down the process running the conversation. Orientation for ASC: writer/reviewer bwrap (file-effect isolation) must **not** be treated as permission for the agent to stop or replace the ASC supervising thread; **stop belongs to the operator/runtime**, outside the sandboxed tool surface. That is a sharper form of “sandbox ≠ process stop.”

**Background processes are acknowledged.** Architecture lists a `process_registry` for background process management under terminal tools—another reminder that stopping the agent loop and reclaiming every child are not automatic synonyms.

**What this orients now (proposed decisions for this idea).**

| Open question | Orientation from Hermes |
|---|---|
| Named stop while busy? | Prefer an operator-visible stop/interrupt path that works during a run, separate from killing the whole gateway/service. |
| Who may stop the supervisor? | Not the sandboxed agent via host-lifecycle commands. Outside/runtime only (Hermes hard-block / approval carve-out). |
| Session/chat id vs auth? | Ids route; they do not authorize. |
| Unattended dangerous actions? | Explicit policy when no human is present (`deny` by default in Hermes)—aligns with ASC’s soft gate before unattended `agent-plan` operation. |
| Container/bwrap bypass? | Isolates host file effects; does **not** waive controller self-stop. |
| Adopt Hermes? | No. Keep ASC Make/`thread-*`; borrow the interrupt/stop and self-termination distinctions. |

**What Hermes does not settle.** It does not choose ASC’s systemd vs process-group supervisor or hold-file layout. Their gateway+SQLite+multi-platform stack is a full agent product, not a thin wrap around Cursor/Codex. Host probes for ASC wrap stop completeness remain open.

## Source comparison: control boundaries and evidence

The table compares selected execution and cleanup paths, not every feature of these large projects. Documentation was consulted on 2026-11-11; source observations below are from the local clones at the listed revisions, not from running the tools. Product documentation may describe other versions or backends. A conversation, request, workflow, process group and container are different control units: the same word “stop” does not make their guarantees equivalent.

| Tool and inspected revision | Identified work and state | Stop mechanism observed | Boundary and lesson for ASC |
|---|---|---|---|
| DeerFlow `13e6fc29e542` | Thread plus distinct run ID; checkpoint persists conversation state. | Run API offers interrupt or rollback, optionally waiting for completion; distinguishes accepted request from completed cancellation. | An HTTP acceptance is not proof of termination; checkpoint rollback is a conversation-state operation, not proof of filesystem or process rollback. |
| DeepSeek Harness `e8f7b93a3449` | Workflow run handle and ID; settled result carries a reason. | Handle aborts pending work and disposes known children; disposal joins settlement. | Holder lifecycle and settled result are useful patterns; workflow-child settlement is not proof that all OS descendants are dead. |
| Goose `392ccbf20a72` | Session and active run tracked separately. | ACP cancel looks up the active session's cancellation token; the response reports a stop reason. | Cooperative turn cancellation is narrower than OS tree termination. The official roaming guide explicitly warns that already-forked processes may continue. |
| Aider `5dc9490bb35f` | Interactive process, in-memory messages and optional restored chat history. | Keyboard interrupt during a response follows the interrupted path; one-shot invocation exits after a message. | A process owner can supervise a one-shot invocation, but an interactive interrupt is not a documented descendant cleanup contract. |
| OpenHands `2071c036fade` | Conversation and its runtime/sandbox have separate lifecycles. | The app's interrupt targets the conversation; its runtime pause invokes cloud sandbox pause, while local mode interrupts the agent and leaves the server running. | A single UI word can mean different operations on different backends; report the operation and backend rather than promising a uniform process-tree outcome. |
| OpenHands SDK `89469eb670b6` | Conversation state and async run; agent server exposes separate pause and interrupt endpoints. | Pause takes effect between steps; interrupt cancels the async task, marks a token and asks the active tool to interrupt. | Tool interruption is cooperative and the default tool implementation is a no-op; a server response is not proof that all tool work has stopped. |
| OpenHands CLI `283c6ac3610f` | Session and conversation, driven through TUI or ACP. | TUI requests SDK pause; ACP requests pause, waits up to ten seconds, then cancels its task if needed. | Different client paths expose different cancellation behavior; neither provides a general OS-tree guarantee. |
| Open Operator `12615a28d0e9` | Research catalogue of computer-use capabilities, tools and benchmarks. | No agent runtime or stop implementation found in this repository. | Useful as a survey, not an independent process-control implementation to compare. |
| Hermes Agent `a84025ade22d` | Agent session, foreground commands and environment-owned long-lived processes are tracked separately. | Local POSIX command cleanup snapshots descendants, signals the process group, waits, escalates and attempts to kill identified escapees. | Stronger than killing a pid, but snapshots and best-effort identity checks leave limits; a separate outer supervisor cannot assume it owns this internal registry. |
| AI Engineering Coach `c5cfba17e732` | Local analytics over AI coding-assistant session logs (VS Code extension). | No agent runtime or stop implementation found in this repository. | Useful for harness-usage observation, not an independent process-control implementation to compare. |

### What the selected paths actually do

**DeerFlow.** The [run cancel endpoint at the inspected revision](https://github.com/bytedance/deer-flow/blob/13e6fc29e542/backend/app/gateway/routers/thread_runs.py#L1365-L1423) takes both thread and run IDs, checks cancel permission, and selects `interrupt` or `rollback`. Without waiting it can return `202`; `204` is returned when the relevant completion wait succeeds, while conflicts are reported separately. Its multi-worker path can request cancellation from the owner or take over an expired lease. This is useful evidence for separating *request accepted* from *completion observed*, not a reason to bring leases or a server into ASC. The [official thread documentation](https://deerflow.tech/en/docs/application/agents-and-threads) describes the conversation/run relationship; an ASC process may drive more than one product turn, so the mapping is conceptual, not one-to-one.

**DeepSeek Harness.** [The workflow host](https://github.com/deepseek-ai/deepseek-harness/blob/e8f7b93a3449/packages/workflow/workflow-ptc/src/host.ts#L148-L166) makes the first cancellation reason win, aborts its controller, initiates disposal of tracked children, and shares a disposal promise tied to settlement. The [result type](https://github.com/deepseek-ai/deepseek-harness/blob/e8f7b93a3449/packages/workflow/workflow/src/types.ts#L58-L84) distinguishes `completed`, `cancelled` and `error`, and explicitly weakens its child count to what the host observed after termination. The [workflow contract](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/workflow/workflow/README.md) gives the caller lifecycle obligations. These are application-level contracts; neither their names nor a resolved result establish ASC's OS-level cleanup guarantee. The earlier holder-ownership analogy is a question for ASC, not a decision that the original starter must always perform cleanup.

**Goose.** [ACP `on_cancel`](https://github.com/aaif-goose/goose/blob/392ccbf20a72/crates/goose/src/acp/server.rs#L2367-L2382) finds the active session's token and cancels it; [the prompt path](https://github.com/aaif-goose/goose/blob/392ccbf20a72/crates/goose/src/acp/server.rs#L2244-L2321) supplies that token to the agent and derives a response reason from the observed outcome. This is a protocol request against a live turn, not an OS supervisor. The [roaming guide](https://goose-docs.ai/docs/guides/roaming-agents/) says revocation cannot necessarily stop processes already forked by a tool. An ASC stop result should preserve that distinction even if a provider exposes cooperative cancellation.

**Aider.** [The coder's interrupted response path](https://github.com/Aider-AI/aider/blob/5dc9490bb35f/aider/coders/base_coder.py#L1455-L1495) catches `KeyboardInterrupt`; [its later handling](https://github.com/Aider-AI/aider/blob/5dc9490bb35f/aider/coders/base_coder.py#L1555-L1582) records an interruption in the conversation and returns before the normal apply-updates path. Its [shell subprocess path](https://github.com/Aider-AI/aider/blob/5dc9490bb35f/aider/run_cmd.py#L42-L88) launches a shell, reads output and waits; that path does not itself establish a process-tree stop guarantee. The [scripting documentation](https://aider.chat/docs/scripting.html) explains one-message runs. The particular point at which interruption occurs matters; this is not a claim that it reverses earlier edits or external effects.

**OpenHands.** The [application mutation code](https://github.com/OpenHands/OpenHands/blob/2071c036fade/src/hooks/mutation/conversation-mutation-utils.ts#L48-L79) distinguishes interrupting the current conversation from pausing its runtime: cloud pause calls a sandbox API; local pause delegates to conversation interrupt and leaves the agent server running. The [SDK pause/resume documentation](https://docs.openhands.dev/sdk/guides/convo-pause-and-resume) describes SDK behavior. The `OpenHands/OpenHands` clone is the app; the separately inspected SDK below supplies the agent-server and local execution paths, but not the cloud sandbox service. Neither app nor SDK pause is evidence of whole-tree termination.

**OpenHands SDK and agent server.** [Local conversation code](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-sdk/openhands/sdk/conversation/impl/local_conversation.py#L3031-L3087) distinguishes pause, which takes effect between agent steps and can wait for an LLM call, from interrupt, which sets a cancellation token before scheduling cancellation of the async run. A synchronous run falls back to pause. The [parallel executor](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-sdk/openhands/sdk/agent/parallel_executor.py#L200-L252) asks an active tool to interrupt when its asyncio task is cancelled, but the worker thread continues until its tool returns; the [default tool interrupt](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-sdk/openhands/sdk/tool/tool.py#L317-L327) is a no-op unless overridden. The [terminal executor](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-tools/openhands/tools/terminal/impl.py#L610-L625) asks its active sessions to interrupt; [one subprocess terminal backend](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-tools/openhands/tools/terminal/terminal/subprocess_terminal.py#L501-L514) sends SIGINT to a PTY process group, without proving all processes exited. Other backends may differ.

The [agent-server interrupt handler](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-agent-server/openhands/agent_server/event_service.py#L2178-L2202) waits up to five seconds for the run task, shields cleanup from that timeout, and retains a still-running task reference to avoid overlapping starts. The [HTTP endpoint](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-agent-server/openhands/agent_server/conversation_router.py#L381-L400) can therefore return after that bounded wait; success does not by itself establish full cleanup. Separately, [MCP stdio cleanup](https://github.com/OpenHands/software-agent-sdk/blob/89469eb670b6/openhands-sdk/openhands/sdk/mcp/client.py#L175-L261) checks the process group even after its leader exits and escalates TERM to KILL. That is a targeted MCP transport cleanup path, not a blanket contract for every agent tool or escaped descendant.

**OpenHands CLI.** The [TUI runner](https://github.com/OpenHands/OpenHands-CLI/blob/283c6ac3610f/openhands_cli/tui/core/conversation_runner.py#L212-L224) calls `conversation.pause()` from a worker thread. The [ACP cancellation handler](https://github.com/OpenHands/OpenHands-CLI/blob/283c6ac3610f/openhands_cli/acp_impl/agent/base_agent.py#L383-L426) also requests pause, waits for the tracked task for up to ten seconds, and cancels that task on timeout. Task cancellation is not equivalent to terminating an OS process, especially when synchronous work is executing in a thread. The [SDK pause/resume guide](https://docs.openhands.dev/sdk/guides/convo-pause-and-resume) explains the resumable conversation behavior; the SDK and CLI findings are tied to the separately cloned revisions and were not executed together to establish version compatibility.

**Open Operator.** The [repository README](https://github.com/OpenHands/open-operator/blob/12615a28d0e9/README.md) describes a collection of computer-use resources and benchmark comparisons. It does not provide an operator runtime in the inspected tree, so it adds context for future tool discovery rather than an independent stop implementation.

**AI Engineering Coach.** The [repository README](https://github.com/microsoft/ai-engineering-coach/blob/c5cfba17e732/README.md) describes a VS Code extension that reads local AI session logs for practice scores, anti-pattern detection and harness usage insights. It does not provide an agent runtime or stop path in the inspected tree, so it is orientation for observing harness sessions rather than an independent process-control implementation.

**Hermes Agent.** The [local environment teardown](https://github.com/NousResearch/hermes-agent/blob/a84025ade22d/tools/environments/local.py#L902-L1028) snapshots descendants before signalling, checks the group leader's start-time fingerprint where available, sends TERM, waits on the *group*, escalates to KILL and best-effort sweeps snapshotted processes that changed groups. If the leader's identity is demonstrably different it avoids signalling the group; if the fingerprint cannot be read, the implementation deliberately continues best effort. A snapshot can miss descendants already reparented or created after it, and permissions can prevent cleanup. The [foreground shutdown code](https://github.com/NousResearch/hermes-agent/blob/a84025ade22d/tools/environments/base.py#L95-L131) also fences new spawns during hard shutdown and bounds cleanup time. Separately, [long-lived process handling](https://github.com/NousResearch/hermes-agent/blob/a84025ade22d/tools/environments/base_processes.py#L45-L100) records a remote process identity inside the environment because killing a local SSH or container client need not stop the remote process. These are concrete reasons to test start/stop races, identity reuse and backend boundaries; they do not prove a generic process-group solution is complete.

### Implications for this idea

- **A known result has layers:** distinguish refusal to start, stop requested, supervisor observed exit, and any separately verified cleanup. An accepted request or settled workflow is not automatically proof that descendants or remote effects stopped.
- **Identity and admission are coupled to races:** a hold needs a defined point after which starts cannot pass it; a stop needs to avoid targeting a later run or a recycled identifier. Test concurrent start/hold/stop and controller failure before claiming stronger behavior.
- **Stop is not rollback:** conversation checkpoints, staged files, git commits, running processes and external effects have different lifetimes. Record what was actually checked; do not infer that a stopped run left the plan or other artifacts untouched.
- **The host owns what it can observe:** cgroups, process groups, provider APIs and remote sandboxes have different scopes. Experiments should include detached children and remote side effects, and report unknowns when verification cannot reach them.

These observations fit the Projet Complexe v6 context: a local, inspectable control surface, no new broker by default, product sessions kept by their products, and authorization separate from readiness and process control. That context includes its own proposed leans; it is not authorization or proof that a particular supervisor works on the intended host.

## Outcome and limits to establish

The operator needs to know which run is being controlled, whether new starts are being prevented, and what happened when a stop was requested. The result must not imply that all relevant processes have exited unless that has been established. How to identify runs, represent a stop result, handle races and verify the outcome remains open.

Whole-tree termination is an unresolved boundary. [Control actions](11-agent-control-actions.md) describes a systemd user unit as a candidate for cgroup-based supervision and a separate session and process group as a fallback. Children that change process group can escape the latter. Host support, failure behavior and the guarantee each approach can actually provide need investigation; a process-group fallback is not automatically equivalent to reliable tree termination.

A hold that refuses new starts is distinct from stopping work already running. Neither control grants permission to run unattended. The [agent plans spec](../../../specs/asc/agent-plans.md) likewise distinguishes readiness from authorization. [Run tracking](11-agent-run-tracking.md) reports that earlier reviews said unattended runs were not yet allowed; that report is not itself a new policy or authorization decision.

Potential mechanisms include a `thread-stop` action, a hold, stronger run identity, and clearer provider lifecycle names. Their exact form, whether all are necessary for the outcome, and optional recording of chat identity on a thread remain open—except that the minimum outcome is framed on the **run**, not on chat or plan identity. Any eventual verification should exercise the stated guarantees and their failure cases on the intended hosts.

## Scope and sequencing

The proposed prerequisite does not include a queue, priority, pause/resume, cross-host listing, a central ledger or full run history, OSC 7501, or a terminal runtime. A gates or next-steps redesign and a full chat pointer store are also outside this slice. Chat hooks, staging and sandbox profiles remain concerns of the existing `agent-plan` design rather than being folded into process control.

**Next useful steps** (sequenced in the [proposed plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md)):

1. State the minimum identify / hold / stop claims in operator language, including explicit non-claims (escaped or unobserved children, chat state and plan/artifact state as actually verified, sandbox/permission/confirmation mode unrelated to stop completeness). Prefer a settled stop result with a reason over an empty failure. Distinguish process stop from any later cooperative loop/turn pause-or-cancel; say what storage/artifacts survive; and state that sandboxed agent tools must not be the path that stops the ASC supervisor.
2. Probe the intended hosts: what the existing wrapper actually starts today; whether a transient systemd user unit is available for one long entry; what stop can prove afterward; whether a cancel-then-force pattern fits the wrap.
3. Only then decide which mechanisms must exist before unattended or real long-running `agent-plan` operation—without blocking independent feasibility work and isolated tests.

## Related

- Draft specs: [agent threads](../../../specs/asc/agent-threads.md), [agent chats](../../../specs/asc/agent-chats.md), [agent plans](../../../specs/asc/agent-plans.md).
- Ideas: [agent-plan design](10-agent-plan-cursor-codex-ollaya.md), [control actions](11-agent-control-actions.md), [run tracking](11-agent-run-tracking.md), [session stores](11-agent-session-stores.md), [LLM Space evaluation](11-llm-space-evaluation.md) (related DeerFlow-family tooling; separate from this control outcome).
- Proposed plan: [thread control before agent-plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md).
- Existing proposal: [agent-plan implementation plan](../../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md).
- External: [DeerFlow Harness vs App](https://deerflow.tech/en/docs/introduction/harness-vs-app), [Agents and Threads](https://deerflow.tech/en/docs/application/agents-and-threads), [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) ([architecture](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md), [sandbox](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/subsystems/sandbox.md), [workflow](https://github.com/deepseek-ai/deepseek-harness/blob/master/packages/workflow/workflow/README.md), [SAFETY](https://github.com/deepseek-ai/deepseek-harness/blob/master/SAFETY.md)), [Goose guides](https://goose-docs.ai/docs/category/guides) / [aaif-goose/goose](https://github.com/aaif-goose/goose) ([permissions](https://goose-docs.ai/docs/guides/managing-tools/goose-permissions.md), [roaming](https://goose-docs.ai/docs/guides/roaming-agents), [CLI commands](https://goose-docs.ai/docs/guides/goose-cli-commands)), [Aider docs](https://aider.chat/docs/) / [Aider-AI/aider](https://github.com/Aider-AI/aider) ([commands](https://aider.chat/docs/usage/commands.html), [scripting](https://aider.chat/docs/scripting.html), [git](https://aider.chat/docs/git.html), [modes](https://aider.chat/docs/usage/modes.html)), [OpenHands introduction](https://docs.openhands.dev/overview/introduction) / [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands) ([Canvas architecture](https://docs.openhands.dev/openhands/usage/agent-canvas/architecture), [pause/resume](https://docs.openhands.dev/sdk/guides/convo-pause-and-resume), [security](https://docs.openhands.dev/sdk/guides/security), [workspace](https://docs.openhands.dev/sdk/arch/workspace)), [Hermes Agent docs](https://hermes-agent.nousresearch.com/docs) / [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) ([architecture](https://hermes-agent.nousresearch.com/docs/developer-guide/architecture), [security](https://hermes-agent.nousresearch.com/docs/user-guide/security), [gateway internals](https://hermes-agent.nousresearch.com/docs/developer-guide/gateway-internals)), [AI Engineering Coach](https://github.com/microsoft/ai-engineering-coach).
