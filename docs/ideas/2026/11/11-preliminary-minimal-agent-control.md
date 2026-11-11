---
name: Thread control prelude
overview: "Explore the minimum process control needed before unattended or real long-running agent-plan operation, separately from chat and plan contracts."
todos: []
isProject: false
---

# Thread control as a preliminary to agent-plan

**Status:** Direction-setting idea. The outcome, its limits and the sequence below are proposed; no implementation or unattended operation is authorized by this document.

## Initial prompt

Can you review docs/ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md in the context of the latest work done in docs/specs/asc?

In particular, I'm inclined to think that the need for control of agent (threads) deserves to be part of this plan as a preliminary step, perhaps as a separate plan to be executed first.

Does it make sense?

## Direction

Yes: process control deserves to be treated separately from `agent-plan`'s chat, staging, isolation and readiness contracts. Before an unattended or real long-running `agent-plan` loop is operated, the proposed outcome is that an operator can identify the run, prevent new starts, and stop a running instance with a known result. The scope and limits of those guarantees still need to be established.

This is a dependency on **operation**, not necessarily on all implementation. Host feasibility work, provider hooks and isolated tests can proceed while the control approach is investigated. A separate plan may be useful once the minimum outcome and its limits are understood; this idea does not create one or prescribe its execution order.

The draft specs distinguish three things:

- A **thread** is an ASC-owned process tree started from an entry point; see [agent threads](../../../specs/asc/agent-threads.md).
- A **chat** is a product conversation that can outlive the process driving a turn; see [agent chats](../../../specs/asc/agent-chats.md).
- A **model server** is a provider service, not an ASC run.

The proposed [`agent-plan` loop](10-agent-plan-cursor-codex-ollaya.md) drives chats and may be long-running. Its design covers roles, staging, isolation and `plan-is 'ready'`, but does not establish how its running process is supervised or stopped. The thread spec records existing gaps including no stop action and pid-only liveness. Stopping a process does not itself end a product session; a chat may remain resumable.

## Outcome and limits to establish

The operator needs to know which run is being controlled, whether new starts are being prevented, and what happened when a stop was requested. The result must not imply that all relevant processes have exited unless that has been established. How to identify runs, represent a stop result, handle races and verify the outcome remains open.

Whole-tree termination is an unresolved boundary. [Control actions](11-agent-control-actions.md) describes a systemd user unit as a candidate for cgroup-based supervision and a separate session and process group as a fallback. Children that change process group can escape the latter. Host support, failure behavior and the guarantee each approach can actually provide need investigation; a process-group fallback is not automatically equivalent to reliable tree termination.

A hold that refuses new starts is distinct from stopping work already running. Neither control grants permission to run unattended. The [agent plans spec](../../../specs/asc/agent-plans.md) likewise distinguishes readiness from authorization. [Run tracking](11-agent-run-tracking.md) reports that earlier reviews said unattended runs were not yet allowed; that report is not itself a new policy or authorization decision.

Potential mechanisms include a `thread-stop` action, a hold, stronger run identity, and clearer provider lifecycle names. Their exact form, whether all are necessary for the outcome, and how a thread relates to a chat session remain open. Any eventual verification should exercise the stated guarantees and their failure cases on the intended hosts.

## Scope and sequencing

The proposed prerequisite does not include a queue, priority, pause/resume, cross-host listing, a central ledger or full run history, OSC 7501, or a terminal runtime. A gates or next-steps redesign and a full chat pointer store are also outside this slice. Chat hooks, staging and sandbox profiles remain concerns of the existing `agent-plan` design rather than being folded into process control.

Further work should establish the control outcome and host limitations, then decide what must exist before unattended or real long-running operation. Any later plan and dependency links should reflect that decision without blocking independent feasibility work and isolated tests.

## Related

- Draft specs: [agent threads](../../../specs/asc/agent-threads.md), [agent chats](../../../specs/asc/agent-chats.md), [agent plans](../../../specs/asc/agent-plans.md).
- Ideas: [agent-plan design](10-agent-plan-cursor-codex-ollaya.md), [control actions](11-agent-control-actions.md), [run tracking](11-agent-run-tracking.md), [session stores](11-agent-session-stores.md).
- Existing proposal: [agent-plan implementation plan](../../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md).
