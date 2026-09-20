# Root README is the only source of truth

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | done (rule). 2026-09-20: human asked the agent to apply the listed `*-readme-*` deltas; working table stayed out of README. |
| **Scope** | [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc) — root `README.md` is the human SoT; agents always point out when it is wrong. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

Set in the mother always-applied rule: [`README.md`](../../../README.md) at this repo root is the **only** source of truth for what ASC is. The human writes it. Changelog / plans / this rule do not silently override it. When README is wrong or incomplete, the agent **says so** — it does not paper over, and it does not dump the long form into README.

The eager/lazy case table ([19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md)) is a **working table** for the lazy-include split, not a competing SoT.

Does not fill the README `TODO [wip]` example rows. Does not move builder.
