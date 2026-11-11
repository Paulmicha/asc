# Steering coding agents away from unnecessary abstraction

- **Date:** 2026-11-11
- **Status:** open idea / collected practice. Nothing here is a rule yet.
- **Scope:** how specs, plans and skills can keep a coding agent from adding layers nobody asked for, with the agent-tracking work as the test case.
- **Method:** mother plans and skills read on 2026-11-11; earlier review notes kept outside this repository. No measurement was made; the claims about what works are judgement.
- **Specs this feeds:** [agent-plans](../../../specs/asc/agent-plans.md), [agent-skills](../../../specs/asc/agent-skills.md)
- **Related:** [patterns and anti-patterns](../../../plans/2026/09/26-patterns-and-antipatterns.md), [agent guidance from anti-patterns](../../../plans/2026/09/27-agent-guidance-from-antipatterns.md)

## The drift

Present in the tree (observed):

- Empty files created "for later": 17 empty `*.entity.yml` and 122 empty `*.able.yml` counted by the simplify plan.
- Entry points that source a file that does not exist.
- Directories named in the README with no reader or writer.

Proposed at some point, then refused in a plan:

- Thin `f_agent_*` wrappers that only forward to a core call.
- Loader, sentinel or harness machinery for a single case.
- A second store for something that has a file (a registry for gates rows).

Each was a reasonable next step for whoever wrote it. The sum is a system that describes more than it does.

## What already works here

1. **A "Do not create" list in the plan.** The agent-plan implementation plan names the files not to add (`review/is.sh`, `plan/needs.sh`, loader machinery). An agent that reads a negative list rarely crosses it. This is the cheapest guard found.
2. **A file map.** The same plan lists every file to touch. Anything else in the diff is a question.
3. **Selection through what exists.** "Use `hook_ms` variants; no new selection API" closed a whole class of proposals in one sentence.
4. **Existence rules in the authoring skill.** A hook call needs an implementation; a function needs a caller.
5. **Anti-pattern records with a "don't" and a "do"** (`data/entities/anti-pattern/`), read before and after editing.

## What the reviews add

- **Need before mechanism.** Write what was missing, with the evidence, before naming a solution. The needs inbox is this as a habit.
- **A refuse list.** Short rows: the tempting thing, why not, what to do instead, since when. Examples from the reviews: a named runtime, a gateway or daemon, a scheduler the agent owns, a multi-agent topology by default, a YAML schema the shell cannot read.
- **An audit that prints and never edits.** A check that lists empty files, hook calls without implementation and entry points with missing sources. Two of those are one `rg` each today.
- **Only a human writes guidance.** An agent may propose a skill change in its report; it does not edit the skill.
- **A reviewer from a different model family.** The agent-plan design already separates writer and reviewer.

## Proposed additions, smallest first

### A delegation line in every spec

For each capability a spec describes, one line: *which existing tool does this, and what does ASC add?* If ASC adds nothing, there is no ASC code. The control-actions idea is written this way; half its rows end in "no new action".

### A budget in every plan

Before writing: how many new files, new globals, new entry points. After: the count. A plan that needs more than it declared stops and says why. This is the file map with a number on it.

### "Would deleting this change behaviour?"

One question per new function or file at review time. A wrapper that only forwards fails it.

### State is suspect

A new stored thing needs a named reader and a named writer in the same change. This single rule would have prevented most of the empty directories.

### Prefer a field to a file, a file to a directory, a directory to a service

Applied to tracking: `run_id` and `host` are fields. A ledger is a file. A host tree is a directory. A queue daemon is a service. Stop at the first level that answers the question.

## What probably does not work

- Long rule lists. The authoring skill is read; a forty-row matrix is skimmed.
- Rules without an example of the wrong thing.
- Asking the agent to "keep it simple". It agrees and adds a helper.
- Guidance in several places. One pointer in `AGENTS.md`, one skill.

## Where this belongs

- The delegation line: in the spec convention ([documentation spec](../../../specs/asc/documentation.md)), if adopted.
- The budget and the "Do not create" list: in whatever defines the plan format.
- The audit: an existing check or test before a new action.
- The refuse list: one page, linked from the authoring skill. Not copied into it.

## Open questions

- Is a refuse list a spec, a skill reference, or a section of the README's non-goals? The README already has non-goals.
- Should `plan-is 'ready'` check that a plan has a file map and a "Do not create" list? That makes the predicate do more; the plan says it should stay small.
- Who removes a rule that no longer earns its place?
