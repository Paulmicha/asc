# README proposal workflow (changelog, not `README.*` siblings)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | done (rule). 2026-09-20: human asked the agent to apply listed `changelog/2026/09/20-readme-*.md` files to root README. |
| **Scope** | New always-applied [asc-readme-proposals.mdc](../../../.cursor/rules/asc-readme-proposals.mdc). Pointer in [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

Rejected: `README.<timestamp>.<slug>.md` at repo root (looks like a second SoT). Rejected: `.diff` files (root or changelog) — patch, not decision; hunks go stale.

Locked: agent writes `changelog/YYYY/MM/DD-readme-<slug>.md`; human reviews and applies to root `README.md`. Agent does not patch README unless asked.

This `.mdc` is a human-requested **workflow** rule, not a third glossary.
