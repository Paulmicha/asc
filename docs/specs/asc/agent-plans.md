---
status: draft
updated: 2026-11-11
---

# Agent plans

Draft. **Observed** means present in the mother tree on 2026-11-11. **Proposed** means written in a plan and not implemented. Nothing proposed here is approved. Gates, next-steps files and the needs inbox are themselves under review; their shapes are recorded as they stand.

A **plan** is a dated Markdown document describing task-specific work. This spec covers the plan file, the evidence an agent loop produces about it, and the files that say whether work may start.

Reasoning and alternatives: [queue and priority](../../ideas/2026/11/11-agent-queue-and-priority.md), [drift guardrails](../../ideas/2026/11/11-agent-drift-guardrails.md), [gates and next steps](../../ideas/2026/11/10-gates-and-next-steps.md), [record conventions](../../ideas/2026/11/11-record-conventions.md).

## Four separate questions

| Question | Answered by |
|---|---|
| What does the work need? | the plan |
| What did a reviewer find? | a review result tied to the plan's digest |
| Is this revision ready for a named step? | `plan-is 'ready'` |
| May the step start? | gates, or a direct human instruction |

Readiness never grants authorisation.

## Plan file (observed)

| Item | Convention |
|---|---|
| Path | `docs/plans/YYYY/MM/DD-subject.md` |
| Status words | `draft`, `ready`, `in-progress`, `completed`, `abandoned`, `superseded` |
| Header | not uniform: status lines, bullets or a table |
| Authority | the Markdown file, over any derived index |

Defined in the [documentation spec](documentation.md).

## Plan content (proposed)

Per named step, the plan declares:

| Declaration | Meaning |
|---|---|
| Prerequisites | must hold before the step starts |
| Outcomes | results of the step; never start blockers |
| Open decisions | human or evidence gates; missing means pause |

Machine-readable prerequisites, one block per named step:

```text
<!-- asc-prerequisites named_step="Task 0" -->
["host_bwrap"]
<!-- /asc-prerequisites -->
```

A missing, duplicated or malformed block means the list is not established. An empty array is established. Implementation plans also carry a file map and a "Do not create" list.

## `agent-plan` (proposed)

```bash
make agent-plan plan:$path prompt:$file named_step:"'Task 0'"
```

| Argument | Required | Meaning |
|---|---|---|
| `plan:` | yes | live plan path under the project root |
| `prompt:` or stdin | yes | the operator's brief |
| `named_step:` | yes | step assessed for start; nested quotes when it has spaces |
| `required_prerequisites:` | no | path to a JSON array of ids; else read from the plan block |

Roles: one writer and one reviewer, each a [chat](agent-chats.md) turn. At most 8 rounds.

### Paths and bytes

- The live path is canonical, strictly under the project root, and not a symlink. Failure tokens: `live_symlink`, `path_escape`, `missing_parent`, `live_not_regular_file`.
- The writer edits a staging copy outside the project tree.
- Before each writer turn the live state is recorded: `kind=absent`, or `kind=file` with `digest` (sha256) and `size`.
- Promotion holds `flock` on `$live_plan.asc-plan.lock`, re-checks the live state, writes a temporary file in the same directory, syncs, renames. A change found at re-check gives `live_changed` and no overwrite. Editors that ignore the lock can still race; the plan says so.
- The reviewer receives, in order: the review task, the expected response, the brief, the declared needs, the live path and digest, the exact plan bytes. Oversize gives `oversized_plan`; nothing is truncated.

### Isolation

| Mode | Meaning | Logged as |
|---|---|---|
| `enforced` | each turn runs in a `bwrap` profile; the reviewer cannot write the project or staging | `writer_isolation`, `reviewer_isolation` |
| `weakened` | no sandbox; a before and after inventory (sha256 and size of every regular file) detects writes | same keys |

### Outcomes

| Situation | Action |
|---|---|
| blocking findings the writer can fix | revise; unchanged digest gives `stalled_draft` |
| missing evidence, open decision, or `unknown` | pause: `needs_human_review` |
| only optional suggestions | stop revising |
| `yes` and digests match | success: the named step may be considered |
| crash or malformed JSON | abort: `missing_result_json` |

Other abort tokens: `missing_draft`, `write_boundary`, `reviewer_write`, `inventory_error`, `max_rounds`.

## Review result (proposed)

```json
{
  "verdict": "blocking",
  "plan_digest": "<sha256>",
  "named_step": "Task 0",
  "blocking": [{"id": "B1", "text": "…", "fixable_by_writer": true}],
  "optional": [{"id": "O1", "text": "…"}],
  "rationale": "…"
}
```

`verdict` is `blocking`, `ready_for_named_step` or `needs_human_or_evidence`. A digest or step mismatch, or a verdict that contradicts its lists, makes the result unusable: `review_digest_mismatch`, `review_named_step_mismatch`, `review_contradiction`.

## `plan-is 'ready'` (proposed)

The only public predicate. Its default implementation merges evidence without a model.

Inputs, all required: `named_step:`, `brief:`, `plan:`, `plan_digest:`, `review:`, `required_prerequisites:`, `checks:`.

Check record:

```json
{"id": "host_bwrap", "kind": "prerequisite", "named_step": "Task 0", "status": "pass"}
```

`kind` is `prerequisite` or `outcome`. `status` is `pass`, `fail` or `missing`. Only ids in `required_prerequisites` create requirements. Outcome records are ignored for start readiness.

Answer:

```json
{
  "ok": true,
  "subject": "plan",
  "action": "is",
  "question": "ready",
  "answer": "unknown",
  "reason": "…",
  "named_step": "Task 3",
  "missing_evidence": ["cursor_create_resume"],
  "status": "completed",
  "error": null
}
```

| `answer` | When |
|---|---|
| `yes` | usable review, matching step and digest, every required id `pass` |
| `no` | fixable blocking findings, or a required id `fail`; the reason is actionable |
| `unknown` | anything missing, malformed, contradictory or unestablished (`required_prerequisites_unestablished`) |

`unknown` is never coerced to `yes`.

## Gates file (observed; under review)

Selected like `env.yml`, never sourced, read by nothing at runtime:

```bash
hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r
```

```yaml
source: NEXT_STEPS.agent.md
gates:
  - changelog: changelog/YYYY/MM/DD-example.md
    lane: discuss
    order: 1
    task: "…"
    summary: "One or two sentences a human can approve without opening the note."
    approved: "no"
    go: "no"
```

- `lane`: `sequential`, `parallel`, `discuss`, `held`.
- `go: yes` only when `approved` is yes, the lane is `sequential` or `parallel`, and every lower `order` in a sequential lane already has `go: yes`.
- A row is removed once its task is implemented.
- The key `changelog:` still names the note path, which now lives under `docs/plans/`.

## Next-steps files (observed; under review)

| File | Written by |
|---|---|
| `NEXT_STEPS[.$INSTANCE_TYPE].md` | a human; selected by `hook_ms` |
| `NEXT_STEPS.agent[.$INSTANCE_TYPE].md` | `asc/doc/next_steps.sh`, from status cells of dated notes |

Generated sections: Sequential, Parallel, Awaiting approval, Do not re-run. The generator's default scan directory is `changelog/`.

## Needs inbox (proposed)

| Item | Convention |
|---|---|
| Path | `$HOME/.local/state/asc/needs/YYYY/MM/DD/HHhMM-$slug-need.md`; collisions get `-2`, `-3`; created exclusively |
| Identifier | the path relative to the inbox root |
| Record | title; metadata table (`Captured`, `Status`, `Origin`); sections Need, Evidence, Current approach; optional Possible reuse, Review |
| Status | `new`, `reviewed`, `planned`, `addressed`, `deferred`, `duplicate`; a field, not a directory |
| Time | ISO 8601 with offset, inside the record |

It is an inbox. It promises no order, no consumer and no dispatch. A need may lead to a plan; the plan links back.

## Product plan files (external)

Products keep their own plan files, for example Markdown with `todos` in front matter under the user's home. They are foreign artefacts, like transcripts. An ASC plan lives in `docs/plans/`.

## Not decided

| Topic | Candidates |
|---|---|
| Authorisation surface | gates file; a status in the plan; a checklist in the plan; direct instruction only |
| Backlog order | `order` in gates; line order in a next-steps file; a `workflow-next` action printing runnable rows |
| Next-steps generator | repoint to `docs/plans/`; retire |
| Gates storage | docroot file (today); registry keys (considered, awkward) |
| Plan header | one shape for status, date, scope |
| Step progress inside a plan | none; checkboxes `[ ]`, `[~]`, `[x]`, `[!]` |
| Where loop evidence is kept | staging only; a dated directory under `data/` |
| Decision-model readiness hook | deferred; the deterministic merge is the default |
| Plan budget | declared count of new files, globals, entry points |

## Related

- Plans: [agent-plan design](../../plans/2026/11/10-agent-plan-cursor-codex-ollaya.md), [its implementation plan](../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md), [host needs and skill feedback](../../plans/2026/11/06-host-needs-and-skill-feedback.md), [workflow](../../plans/2026/09/22-workflow.md), [gates like env](../../plans/2026/09/22-gates-like-env.md), [gates prune approved work](../../plans/2026/09/22-gates-prune-approved-work.md), [gates registry alternative](../../plans/2026/09/22-gates-registry-alternative.md), [doc next steps](../../plans/2026/09/22-doc-next-steps.md), [backlog priority](../../plans/2026/09/27-backlog-priority.md).
- Files: `gates.core.yml`, `SPECIMEN.gates.yml`, `NEXT_STEPS.core.md`, `NEXT_STEPS.agent.core.md`, `asc/doc/next_steps.sh`.
