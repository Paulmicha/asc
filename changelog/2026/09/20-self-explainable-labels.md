# Self-explainable labels in the always-applied rule

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | done (rule). Comments aligned. No runtime change. |
| **Scope** | [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc) — labels / human↔token loop. Comments that still said `phase 90` or `@see …/90-caller-opt-inc.bootstrap-inc.sh`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

A **label** says what the thing does. Example: **caller opt-inc** (the always-run tail of `asc/bootstrap.sh`) instead of **phase 90** (old numbered `90-*.bootstrap-inc.sh`).

Human NL (FR / EN / PT-BR) is redundant; memory is disparate. **Synonyms** declare equivalences. They raise the hit rate of disparate recall onto a small, self-explainable set.

Does not pick mirror vs caller opt-inc for `db/dump.sh`. Does not add a glossary `.mdc`.
