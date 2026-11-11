---
status: draft
updated: 2026-11-11
---

# Agent skills

Draft. **Observed** means present in the mother tree on 2026-11-11. **Proposed** means written in a plan or idea and not implemented. **External** means taken from a published format or a product's documentation. Nothing proposed here is approved.

A **skill** is a directory with a `SKILL.md` that gives an agent a procedure. It is a brief, not an executable: what runs is a make entry point. `AGENTS.md` says when a skill is mandatory.

Reasoning and alternatives: [agent skills manager](../../ideas/2026/11/11-agent-skills-manager.md), [drift guardrails](../../ideas/2026/11/11-agent-drift-guardrails.md), [loose ends](../../ideas/2026/11/11-agent-tracking-loose-ends.md).

## Locations (observed)

| Path | Role | Owner |
|---|---|---|
| `.agents/skills/$id/SKILL.md` | the skill; hand-written source | mother for `asc-*`, instance for others |
| `AGENTS.asc.md` | shared routing to the ASC skills | mother |
| `AGENTS.md` | instance entry point; points at `AGENTS.asc.md` | instance |

Shared skills in the mother: `asc-actions-priority`, `asc-author-code`, `asc-author-docs`, `asc-mother-guard`. Each is one file, 18 to 145 lines.

When the user's home is itself an ASC instance, its `.agents/skills/` is also user-wide for products that read that location.

## `SKILL.md` format

Observed front matter: `name`, `description`. Nothing else is used.

The published Agent Skills format (external):

| Field | Required | Constraint |
|---|---|---|
| `name` | yes | 1 to 64 characters; lowercase letters, digits, hyphens; no leading, trailing or double hyphen; equals the directory name |
| `description` | yes | 1 to 1024 characters; what it does and when to use it |
| `license`, `compatibility`, `metadata`, `allowed-tools` | no | `metadata` is a string map; `allowed-tools` is experimental |

Optional sibling directories: `scripts/`, `references/`, `assets/`. Guidance from the same source: keep `SKILL.md` under 500 lines and move detail to referenced files. The reference validator rejects unknown top-level fields; some products ignore them.

The four mother skills conform. Their descriptions start with "Use when" or "Use before".

## `AGENTS.md` (external)

Plain Markdown, no required fields. The closest file to the edited path wins; a direct user instruction wins over both. Products differ in how they combine nested files: one concatenates from the project root down to the working directory under a size cap; another reads a different file name natively and reaches `AGENTS.md` through an import or a link. Test with the products in use.

## Distribution (observed)

`asc/core/upgrade.sh`, run in an instance:

| Path | Effect |
|---|---|
| `asc`, `docs/specs/asc`, `scripts/asc/contrib/asc` | deleted and replaced |
| `.agents/skills/asc-actions-priority`, `asc-author-code`, `asc-author-docs`, `asc-mother-guard` | deleted and replaced, one by one |
| `AGENTS.asc.md` | overwritten |
| `AGENTS.md` | left alone; created only when absent |
| other directories under `.agents/skills/` | untouched |
| `.claude/skills` link to `.agents/skills` | present in the script, commented out |

This spec directory is in the replaced set: every file here travels to every instance.

## Product discovery (external)

| Product | Reads |
|---|---|
| Cursor | `.agents/skills/`, a project `AGENTS.md`, and its own rules directory |
| Codex | `.agents/skills/`; `AGENTS.md` from the project root to the working directory |
| Claude Code | `.claude/skills/$id/SKILL.md`; `AGENTS.md` only through an import, a link, or when no native file competes |

Taken from product documentation cited in the [guidance-as-skills plan](../../plans/2026/09/30-asc-guidance-as-project-skills.md). Discovery makes a skill available; it does not make an agent apply it.

## Rules (observed practice)

- One source per skill: the hand-written `SKILL.md`. No generated copy, no `data/skills/`.
- Routing lives in `AGENTS.asc.md`, not in each skill.
- A skill names where to find templates and anti-pattern records; it does not restate them.
- Instance-specific guidance stays in the instance.

## Needs feed skills (proposed)

A reviewed need may end in a change to a skill. The mapping in the needs plan names what a skill is made of: trigger, procedure, resources, scripts, checks, guard, learning. The inbox itself is described in [agent-plans](agent-plans.md).

## Install and uninstall (proposed)

| Entry point | Contract |
|---|---|
| `make skill-install $id` | copy a whole known skill directory into `.agents/skills/$id/`; refuse when the destination exists |
| `make skill-uninstall $id` | remove only a copy this mechanism installed and that is unchanged |

Requires an ownership record (source and content fingerprint). Updates are a separate action. The four upgrade-managed directories are not taken over. Third-party sources are a later decision, preferably left to an existing installer.

## Not decided

| Topic | Candidates |
|---|---|
| Structured skill source | none (today); a `skill` entity rendered to product paths. The earlier render design is not in the mother and the reviews reversed it. |
| Ownership record location | committed project file; host state |
| Extra front matter | none; `metadata` keys for provenance and last review |
| Description shape | free; three parts: what, use when, not for |
| Claude Code path | the commented link; a copy; nothing until Claude Code is in use |
| Who may edit a skill | a human only, with agents proposing changes in their report; or agents under review |
| Skills for agent tracking | none yet; a skill should follow a settled action, not precede it |
| User-wide scope | rely on the home instance; a separate user directory |

## Related

- Plans: [guidance as project skills](../../plans/2026/09/30-asc-guidance-as-project-skills.md), [agent instructions travel](../../plans/2026/09/28-agent-instructions-travel.md), [host needs and skill feedback](../../plans/2026/11/06-host-needs-and-skill-feedback.md), [simplify disk entities](../../plans/2026/11/06-simplify-disk-entities-contracts.md), [guidance from anti-patterns](../../plans/2026/09/27-agent-guidance-from-antipatterns.md).
- Files: `AGENTS.md`, `AGENTS.asc.md`, `.agents/skills/`, `asc/core/upgrade.sh`.
