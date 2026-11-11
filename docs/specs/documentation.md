# ASC project documentation

Status: current

This specification defines a common documentation convention for ASC projects.
Projects can add categories and need not create empty directories or optional
files. The [ASC README](../../README.md) remains authoritative for the meaning
and purpose of ASC concepts; instance-specific documentation belongs in its own
project.

## Document homes

| Path | Purpose |
|---|---|
| `README.md` | Introduce the project; the mother README defines ASC concepts and scope. |
| `AGENTS.md` | Entry point for agent instructions and pointers to applicable guidance. |
| `CHANGELOG.md` | Optional record of notable delivered changes, typically grouped by release. |
| `docs/README.md` | Optional map of the project's documentation and its authority. |
| `docs/ideas/YYYY/MM/DD-subject.md` | Exploration, questions, and rough proposals. |
| `docs/plans/YYYY/MM/DD-subject.md` | Task-specific work, progress, decisions, and verification. |
| `docs/decisions/YYYY/MM/DD-subject.md` | Significant decisions, their context, rationale, and consequences. |
| `docs/specs/subject.md` | Living specifications and technical reference for a subject. |
| `docs/guides/subject.md` | Optional task-oriented guidance; `how-to-subject.md` is also suitable. |

Choose the home by the document's primary purpose. A plan can include
requirements and decisions without requiring separate documents for every task.
Create a separate spec or decision record when the knowledge deserves a
longer-lived home. A guide should make its reader's goal clear near the start.

Dated records use the year and month directories and day-prefixed filename
shown above. Living specs and guides use stable subject names; subject
subdirectories can be added as they grow. Keep a document's path stable through
status changes so links and references continue to work.

## Status and authority

Place a clear status near the top when a document's lifecycle matters. The
following labels provide a common vocabulary:

- Plans: `draft`, `ready`, `in-progress`, `completed`, `abandoned`, `superseded`.
- Specs: `draft`, `current`, `superseded`, `retired`.
- Decisions: `proposed`, `accepted`, `superseded`, `rejected`.

A `ready` plan is prepared for review or execution; its status does not grant
authorization. Applicable gates or direct human instructions govern execution.
Keep completed plans as historical records in `docs/plans/`. A later decision
may supersede an earlier one. Do not infer a status merely from a document's
age or treat an old proposal as current behavior or permission to act. Existing
historical documents may use different status wording and need not be relabeled
without review.

Specs describe an enduring contract or current technical reference. Clearly
distinguish required behavior, observed implementation, limitations, and
proposed changes when they differ. Link related plans and update the relevant
spec when a delivered change alters its contract. A task's acceptance criteria
can remain in its plan. Markdown source documents are authoritative over any
derived index or status dashboard.

## Adoption and existing material

This convention is the shared documentation model, not a claim that every ASC
instance already has every file or has migrated its history. The mother
checkout's [completed migration plan](../plans/2026/11/10-changelog-refactor.md)
records the move of dated legacy notes to `docs/plans/`; it did not migrate
other instances or implement all categories. Its retained
[legacy index](../../changelog/README.md) preserves historical context.

The mother README still describes `changelog/` as a home for past or planned
work. Its historical wording and this convention have not yet been reconciled.
The next-steps scanner's legacy default and related workflow are addressed by
the separate [gates and next-steps idea](../ideas/2026/11/10-gates-and-next-steps.md).
