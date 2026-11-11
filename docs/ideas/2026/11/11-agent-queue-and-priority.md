# Queue and priority: two levels, and which tool owns each

- **Date:** 2026-11-11
- **Status:** open idea / comparison. Nothing here is decided.
- **Scope:** what "queue a task" and "prioritise" mean for ASC, and what already provides them.
- **Method:** mother docs and code read on 2026-11-11. External tool behaviour is taken from their documentation and one third-party comparison page; none of the queue tools was installed or run.
- **Specs this feeds:** [agent-threads](../../../specs/asc/agent-threads.md), [agent-plans](../../../specs/asc/agent-plans.md)
- **Siblings:** [control actions](11-agent-control-actions.md), [gates and next steps](10-gates-and-next-steps.md)

## Two different queues

| | Work-item queue | Process queue |
|---|---|---|
| Holds | things someone decided are worth doing | commands waiting for a slot |
| Ordered by | a human | arrival, or a number |
| Lives for | days to months | seconds to hours |
| Consumer | a human, or a human starting an agent | the OS, a lock, a daemon |
| Candidate home | gates rows, next-steps file, plans | lock, systemd, a queue tool |

One store for both is the mistake to avoid. A work item carries approval; a queued process carries a command line.

## Work-item level

What exists or is proposed, none settled:

- **Gates file.** Rows have `lane` (`sequential`, `parallel`, `discuss`, `held`) and `order`. `go: yes` is allowed only for approved rows whose predecessors in a sequential lane are done. Rows are removed after implementation. Nothing in the runtime reads it. This is already an ordered, approved backlog.
- **Next-steps file.** Generated from plan status cells. Sections: Sequential, Parallel, Awaiting approval, Do not re-run. The generator still scans `changelog/` by default.
- **`workflow-next`** (proposed in the workflow plan): print the runnable gates rows. That is "peek at the head of the queue".
- **Needs inbox** (proposed). The plan says outright that it is not a queue: no consumer, no ordering promise, no dispatch.
- **Plan status** (`ready`) and the `plan-is 'ready'` predicate. Readiness is not authorisation.

So at this level ASC does not lack a queue. It lacks a decision about which of these files is the one. That is the question in [gates and next steps](10-gates-and-next-steps.md).

Other shapes worth comparing before deciding:

- A checklist in the plan itself (`[ ]`, `[~]`, `[x]`, `[!]`), as AgentTrail's `PLAN.md` does. Order is line order. No second file.
- One file per item in a directory, state as a field. This is what the needs inbox proposes; it could hold approved work too, at the cost of merging two things the plans keep apart.
- The registry (one key per task). Considered and found awkward in the gates-registry plan.

## Process level

What exists:

- `ASC_THREAD_LOCK_MODE=skip` (default): a second start of a running entry is dropped.
- `ASC_THREAD_LOCK_MODE=wait`: it blocks on `flock`. Waiters are live processes. Order among waiters is not guaranteed. A reboot loses them.
- `thread-sequence`, `thread-batch workers:N`: fixed lists decided at call time.

What is missing: add work later, see what is waiting, cancel a waiter, reorder.

### Options

| Option | Daemon | Queue survives reboot | Parallel limit | Priority | List / cancel waiting | Machine-readable |
|---|---|---|---|---|---|---|
| `flock` wait (today) | no | no | 1 per lock | no | `ps` | no |
| `nq` | no | no | 1 | no | files in a directory | no |
| `task-spooler` | yes | no | slots | no | yes | no |
| `pueue` | yes | yes | per group | yes | yes, plus pause | JSON |
| `systemd-run` + slices | user manager | no | no (weights, not slots) | CPU and IO weight | units | JSON |
| `at` / `batch` | system | yes | load-based | no | `atq`, `atrm` | no |
| Spool directory + timer | no | yes | by the consumer | file name order | `ls`, `rm` | files |

Notes:

- `pueue` is the only one that covers queue, priority, groups and stop together. It is a second supervisor beside systemd and a Rust binary to install on every host.
- systemd does not queue. It runs everything now and shares the CPU by weight. For "the laptop stays usable while an agent builds", weight is the right tool and no queue is needed.
- A spool directory read by a timer is "timer, not broker" from the reviews: one file per item, lowest name first, a high-water mark. It is also the first step of a home-made queue. Take it only with a named need.
- One model on one GPU is the real slot limit. The model server already serialises requests (`OLLAMA_NUM_PARALLEL=1` in the reviews). ASC queuing in front of it adds nothing.
- Codex keeps its own queue of pending turns per thread, in its own store. A product that queues its own turns does not need ASC to.

### Two meanings of "priority"

- **Which goes first.** A queue property. Today: a human reading `order:`.
- **Which gets the machine.** A scheduler property: `nice`, `ionice`, cgroup weights. Available now with no queue.

Most of the stated need ("an agent run should not starve my editor") is the second.

## Lean

1. Process level: keep `flock`. Add resource weight when runs become units. Do not install a queue tool until a real waiting list exists; if one does, try `pueue` before writing anything.
2. Work-item level: settle gates versus next-steps first. Whichever survives is the queue, and `order` is the priority.
3. Keep the two levels in separate files with separate words. Suggested words: *backlog* for work items, *queue* for processes.

## Open questions

- Will there ever be more than one unattended run waiting? If not, there is no process queue to build.
- Should a waiting thread be visible in `thread-list` (a `waiting` status), since `wait` mode already creates waiters?
- Is `order:` in gates a priority or only a dependency?
- Does a LAN box that sleeps by default need a "send this when it wakes" mechanism? That would be the first true queue. The reviews leave it as "a file on a share or a flag over SSH".

## Sources

- Mother: `gates.core.yml`, `SPECIMEN.gates.yml`, `asc/doc/next_steps.sh`, plans [workflow](../../../plans/2026/09/22-workflow.md), [gates like env](../../../plans/2026/09/22-gates-like-env.md), [gates registry alternative](../../../plans/2026/09/22-gates-registry-alternative.md), [concert order](../../../plans/2026/09/25-concert-order.md), [host needs](../../../plans/2026/11/06-host-needs-and-skill-feedback.md).
- External, read 2026-11-11: `pueue` README; a local job-queue comparison published by the `spoolctl` project (a vendor comparing itself, so weigh accordingly); AgentTrail README.
