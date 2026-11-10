# Refactor current changelog usage

The problem is not just that `changelog/` has an ambiguous name: it currently mixes documents that answer different questions, and an agent can mistake a historical proposal for current behavior or permission to act.

My recommendation is to **organize primarily by document purpose, and record lifecycle status inside the document**. Keep paths stable as a document progresses. Use a separate gate to authorize execution.

There is no single industry-standard directory tree for agentic coding. The durable practices are more general: make repository knowledge discoverable, distinguish current contracts from plans and history, record important decisions, and give long-running work enough context to resume. The exact names below are an ASC convention I recommend, not a standard imposed by a tool.

## Recommended convention

```text
README.md                          # Project introduction and authoritative ASC concepts
AGENTS.md                          # Agent entry point and pointers to applicable guidance
CHANGELOG.md                       # Optional: notable delivered changes by release

docs/
  README.md                        # Short map: what lives where, authority, status
  ideas/
    2026/
      11/
        10-foobar.md               # Exploration, questions, rough proposals
  plans/
    2026/
      11/
        10-foobar.md               # Task-specific execution plan
  specs/
    foobar.md                      # Living behavior or contract for a subject
  decisions/
    2026/
      11/
        10-foobar.md               # Significant decision and its rationale
  guides/
    foobar.md                      # Optional: how to perform a task
```

The central distinction is:

| Kind | Main question | Typical lifetime |
|---|---|---|
| **Idea** | What might we explore, and why? | Informal; may be abandoned or inform a plan |
| **Plan** | What work is proposed or underway, and how will we verify it? | Task-specific; retained as a historical record after completion |
| **Spec** | What behavior or contract is intended or currently supported? | Maintained as the subject evolves |
| **Decision** | What significant choice did we make, and why? | Historical; a later decision can supersede it |
| **Changelog** | What notable changes were delivered? | Release history, written for readers who need to understand changes |

An individual document can contain some of the other kinds of information. A plan may briefly state requirements and record implementation decisions; it only needs to produce a separate spec or decision record when that knowledge deserves a longer-lived home. This avoids turning every small change into a paperwork exercise.

### Why stable paths rather than `drafts/`, `ready/`, and `archived/`?

Your proposed directories make state easy to see at a glance. Their downside is that **every state transition changes the path**. In ASC that would affect links, gate entries, generated next steps, code comments, and potentially search indexes or external references. It also creates questions such as whether “archived” means completed, abandoned, superseded, or merely old.

I would keep one path throughout a plan’s life and put its status prominently at the top:

```markdown
# Foobar implementation plan

Status: draft
Created: 2026-11-10
Related spec: ../specs/foobar.md
```

A small vocabulary is enough:

- **Plans:** `draft`, `ready`, `in-progress`, `completed`, `abandoned`, `superseded`.
- **Specs:** `draft`, `current`, `superseded` or `retired`.
- **Decisions:** `proposed`, `accepted`, `superseded` or `rejected`.

These are proposed ASC labels, not universal standards. In particular, **`ready` means the plan is sufficiently prepared for review or execution; it does not itself grant authorization**. Existing ASC gates or a direct human instruction determine whether an agent may proceed. A completed plan remains in `docs/plans/`, clearly labeled as historical.

If the plans directory eventually gets crowded, add a generated index or search by status before introducing moves. If a physical archive later becomes necessary, it can be added without changing the meaning of the document types.

### Dates and naming

I prefer paths like `docs/ideas/2026/11/10-changelog-refactor.md` to `docs/ideas/2026-11-10-changelog-refactor.md` for plans and ideas, mostly because busy projects may generate a lot of files over time, making it harder to browse for humans.

Use **stable subject names without dates for living specs**, such as `docs/specs/foobar.md`. A spec changes over time; its creation date is usually less useful in its address than its subject. If a project eventually accumulates thousands of records, year subdirectories can be introduced for new dated records without forcing every project to adopt deep nesting immediately.

## What the research supports

**Separate reader needs and document purposes.** [Diátaxis](https://diataxis.fr/) distinguishes tutorials, how-to guides, reference, and explanation. It does not prescribe ASC’s proposed tree, but it supports the underlying principle that readers benefit when a document has a clear job. Plans and decision records complement those documentation types; they are not themselves the four Diátaxis categories.

**Keep plans as first-class, resumable artifacts.** OpenAI describes using a short `AGENTS.md` as a map into repository documentation, with active and completed execution plans stored in the repository. Its [harness engineering account](https://openai.com/index/harness-engineering/) is one engineering example, not evidence of a universal standard. The [ExecPlan guidance](https://developers.openai.com/cookbook/articles/codex_exec_plans) also emphasizes plans that retain progress, decisions, and verification context for extended work.

**Separate significant decisions from mutable implementation plans.** [AWS’s ADR guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html) describes recording context, a decision, and consequences, then superseding an accepted decision when it changes. This is especially relevant to the README’s unfinished “Doubts” concept: an ADR can preserve alternatives and uncertainty without making a plan the permanent authority on current behavior. I would reserve it for decisions that are consequential or difficult to reverse.

**Use “changelog” for delivered changes.** [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) describes a human-readable record of notable project changes, usually grouped by release. ASC can retain detailed implementation history elsewhere and optionally maintain a root `CHANGELOG.md` for readers who need the outcome.

## How this fits ASC and the Second Brain reviews

The [ASC README](README.md) already distinguishes specs, plans, issues, priorities, and gates conceptually, while identifying the README as authoritative for ASC concepts. This proposal gives those distinctions concrete homes without changing that authority. A spec should link back to the relevant README concept where appropriate; the README should point to a spec for detail only when that relationship is explicitly established.

The Second Brain reviews reinforce three useful ideas:

1. The [agentic software work review](<agentic-ai, rag, retrieval, packing, workflow, anonymization/06-agentic-software-work-specs-evals-cli-ergonomics.md>) separates a task’s intent, constraints, acceptance criteria, and verification from the agent performing it. ASC can use that distinction without requiring a heavyweight spec for every task.
2. The [data architecture synthesis](<data stores, databases, wiki, plain file storage (md, json, yaml)/06-synthesis-data-architecture-v6-delta-and-rebuild-first-roadmap.md>) values an identifiable source of record, provenance, and rebuildable indexes. For ASC documentation, the practical consequence is to keep the Markdown document authoritative and treat any future search index or status dashboard as derived.
3. The [operations synthesis](<devops, linux, servers, networking, hosting, security, privacy/06-synthesis-the-recommended-stack-remediations-and-place-staged-roadmap.md>) distinguishes versioned source material from backups and derived data. These reviews are project-specific proposals, not proof that all their infrastructure or retention policies belong in ASC.

I would also distinguish **a task specification** from **a living subject spec**. A plan may contain task-specific acceptance criteria; `docs/specs/foobar.md` describes the enduring contract. When a task changes that contract, the plan should say what spec needs updating and how the outcome will be verified.

## Migration implications

This needs more than a rename. I found **73 files under `changelog/`** in this checkout, plus references in `gates.core.yml`, `NEXT_STEPS` files, README, code comments, and tests. The next-steps test fixtures also explicitly exercise a changelog directory. The inventory is indicative, not an exhaustive dependency audit.

A safe migration would be:

1. Agree on the document types, status vocabulary, authority rules, and how gates relate to plans.
2. Inventory existing files and references. Classify mixed documents by their **primary purpose**, preserving uncertainty instead of assuming every old checkbox is actionable.
3. Pilot the convention with a few representative files, including an active gated plan and a completed historical record.
4. Update consumers, tests, links, gate entries, and any discovery exclusions together; verify both active work and historical links.
5. Migrate the remainder incrementally. Leave existing files in place until each has an explicit destination or disposition. Avoid fabricating creation times or rewriting historical claims as current specifications.
6. Document a lightweight default for ASC instances, allowing a project to add categories without requiring every instance to mirror the mother’s exact tree.

My preference is to adopt the **meaning and authority rules as the durable cross-project convention**, while keeping the directory scheme small and allowing optional categories. That is more likely to survive changes in agents and tooling than tying the whole structure to a particular agent’s workflow.

## Follow-up notes

Remove `docs/reference/` and use **`docs/specs/` as the shared home for living specifications and technical reference**. For ASC, maintaining both directories would often force an arbitrary choice: a page describing a hook’s contract could naturally include its parameters, behavior, and examples.

There is a real distinction in meaning: a specification can state what a system **must** do, while reference documentation can describe what it **currently** does. But they do not need separate directories. The important thing is to make the distinction clear **within the document**, especially when intended and implemented behavior differ:

```markdown
# Foobar

Status: current

## Contract

The behavior implementations are expected to provide.

## Current implementation

What exists today, including known limitations.

## Proposed changes

Changes under consideration, linked to the relevant plan.
```

Not every spec needs all three sections. The point is that an agent should not interpret an aspirational statement as a description of working code—or treat an observed implementation detail as a required contract. That fits ASC’s existing distinction between the authoritative README, proposals, and actual implementations. [Diátaxis](https://diataxis.fr/) describes reference as a documentation purpose; it does not require a separate `reference/` directory.

For `guides/`, a combined approach makes sense : let's allow both `foobar.md` and `how-to-foobar.md`, with the opening lines making the reader’s goal clear. A prefix can be useful when two guides cover the same subject from different angles; it need not become mandatory everywhere.

The resulting structure would be:

```text
docs/
  README.md
  ideas/2026/11/10-foobar.md
  plans/2026/11/10-foobar.md
  decisions/2026/11/10-foobar.md
  specs/foobar.md
  guides/foobar.md
  guides/how-to-foobar.md
```

I would keep specs and guides organized primarily by **subject**, since readers are more likely to look for the current documentation about a topic than for its creation date. Dated, task-specific records remain grouped chronologically. As those living directories grow, subject subdirectories can help navigation without forcing dates onto documents that are continually maintained.
