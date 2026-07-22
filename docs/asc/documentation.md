# ASC core concept : Documentation

Table of contents :

1. ideas
1. changelogs
1. living

ASC recognizes **three** documentation kinds only. Everything else (tickets, chat logs, vendor READMEs outside the tree) is out of this model.

Overarching goals that documentation should keep visible (from working notes):

1. **Self-explanatory filenames and filepaths** — *Let's make words matter.*
2. **Every durable datum has a lifetime** (`forget.able` / rotate) — see [entities.md](entities.md) § capabilities.
3. **Organizational precepts are self-buildable, replicable, and nestable** (recursive iterations) — see [builder.md](builder.md), [wrappers.md](wrappers.md) § nested.

---

## ideas

Design-before-implement specs. Product-generic: no personal host paths, infra IPs, or client names.

Prefer **stories** (short scenarios) when an idea is hard to name: what a human or agent would try, what files appear, what fails closed. Stories complement `*.able.yml` sketches; they do not replace dated idea files under `scripts/asc/ideas/`.

| Location | Role |
|----------|------|
| `scripts/asc/ideas/YYYY/MM/DD/*.md` | Dated idea packs (entities, wrappers, organization, auth, …) |
| Pack README | Index of empty vs seeded files |

Ideas answer “what should exist and why” before code. Typical pack waves: vocabulary (`entities`) → nesting → agents → layers/organization/synonyms → wrappers/sidecars → contracts/links → blueprints/self-builder → cognition/taxonomy/plans.

Empty idea files are intentional stubs, not living docs. When an idea lands in code, update the matching [living](#living) page and optionally close the idea with a changelog pointer.

Related living pages: [entities.md](entities.md), [wrappers.md](wrappers.md), [organization.md](organization.md), [builder.md](builder.md).

---

## changelogs

Dated record of **done** or **in-progress** planified work, plus minimal tracking.

```text
changelog/YYYY/MM/DD-<short-label>.md
```

Example: `changelog/2026/07/17-implement-new-ollama-subject.md`.

| Trait | Guidance |
|-------|----------|
| Scope | One topic per file; status + context + what changed + open tasks |
| SoT | Changelogs win for “what we decided / shipped on a date” |
| Living docs | Prefer linking here rather than duplicating long history |
| Time-stamped artifacts | Runtime traces use `data/<name>/YYYY/MM/DD/HH.MM.SS.MS.<file>.md` — different from changelog naming |

Project instances may keep a root `changelog/` (optional). Upstream ASC history that matters to consumers is summarized in living docs; detailed fork/cutover narratives stay in dated changelog entries in the consuming repo.

---

## living

Always-current explanation of how ASC works **now**.

| Location | Role |
|----------|------|
| `docs/asc/*.md` | This suite — one file per major concept (see [README.md](README.md)) |
| Nested `README.md` | Why *this folder* exists (function, capabilities, usage) |
| Root `README.md` | Product identity, TL;DR, pointers into living docs |

Living docs should be:

1. **Structured** — H1 + TOC + H2 sections matching [README.md](README.md).
2. **Compiled** — synthesize sources; do not leave raw extract dumps as the reader path.
3. **Honest about gaps** — mark open questions and stubs instead of inventing behavior.
4. **Polished like code** — polish prose the same way you polish implementation (clarity, typography, consistent terms). Naming is the hard problem; living docs are part of solving it.

Aim for two readable paths over time: a **tutorial for humans** and a **tutorial for agents** (same facts, different density) — both should point at this suite, not fork a second SoT.

Maintenance: after a meaningful tip change, update the relevant living page and add or close a changelog entry. Playbooks that split passive vs active ops (e.g. observability vs monitoring) stay under [wrappers.md](wrappers.md) / organization as appropriate.

Index of this suite: [README.md](README.md).
