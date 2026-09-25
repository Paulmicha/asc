# Gitflow — mother, buffer, machine branch

> **2026-09-25 concertation.** Order of work is [25-concert-order.md](./25-concert-order.md). This file keeps its contract. The name Gitflow is the wrong folklore; the candidate is merge upward. It is not the queue.

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | The git half of [22-workflow.md](./22-workflow.md). Candidate contract for how a changelog that closed its lap moves between instances. |
| **Out of this plan** | New git scripts. Changing `make git-acp`. Editing the README proposal into human text. Host filesystem sync. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the gitflow row in [`gates.yml`](../../../gates.yml). `go` stays `no`. Approving it accepts this contract as the one to implement later. It does not authorize a script.

---

## Candidate

README § Workflow contains a `proposal-2026-09-22` block. It is not a human-written line. The checklist item “Stabilize workflow + git flow” is still open. This file records that block as the candidate, in shorter words:

- Every local instance takes updates from the ASC mother.
- Several machines sharing one repo use a common branch as the buffer they pull and push.
- A machine branch is a child of that buffer. That machine pulls the buffer before it pushes.
- A change those machines share moves up onto the buffer.
- A change every instance shares moves up into the mother.
- The linux home-directory repo is the example. Its buffer branch is `debian-13`. A machine checkout of that same repo uses `debian-13` plus a machine suffix. Both checkouts may sit on one host. Git commits move through the buffer. A work-tree mirror between those two directories is a separate pass, not this plan.

No script in this plan creates those branches. Accepting the row means a later session may write the smallest pull-buffer-then-push helper. Rejecting the row leaves the proposal untouched.

---

## What the tree does instead

`make git-acp` (`asc/git/acp.sh`) runs `git add .`, commits, and pushes the current branch. It does not pull a buffer first. A workflow that called `git-acp` at the end of a lap would publish whatever is in the work tree, including the dirty files this kind of planning leaves behind.

`asc/core/upgrade.sh` (`make core-upgrade`) replaces the `asc/` and `scripts/asc/contrib/asc/` folders from the public mother repo. That is a file replace, not a branch relationship. Host sibling docroots are a third path: [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) only catalogs them.

Three different “syncs” stay three:

| Mechanism | Moves |
|-----------|--------|
| Buffer / machine branch | Git commits between machines that share a repo |
| `make core-upgrade` | Mother file tree into this instance’s `asc/` |
| `host-instance-discover` | Nothing. It lists paths. |

`workflow-next` does not call any of them.

---

## Gaps

1. **The only written gitflow is an unaccepted README proposal.** Implementing from it alone would promote proposal text to source of truth.
2. **`debian-13` is an example inside that proposal,** not a branch this plan creates.
3. **`git-acp` is the opposite of “pull the buffer first”.** Replacing it is a separate go, after this contract is accepted.
4. **`core-upgrade` and host discover are not this gitflow.** A closed lap on the mother does not, by itself, update `~/asc` or any other docroot on the machine.

---

## Tasks

- [ ] Accept or reject the mother / buffer / machine-branch contract.
- [ ] Leave `git-acp` and `core-upgrade` unchanged until a later row says otherwise.
