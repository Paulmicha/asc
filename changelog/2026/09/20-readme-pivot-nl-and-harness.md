# README proposal: pivot NL + harness

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **applied** (2026-09-20). Three clauses in root [`README.md`](../../../README.md). |
| **Scope** | Three short clauses in root [`README.md`](../../../README.md). One example per idea. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

## 1. Target — Overarching goal

### Why

README already says *Let's make words matter*, but it does not name English as the canonical label spelling (distinct from a make pivot).

### Exact edit

After `***Let's make words matter*** 📚`, add:

```markdown
English is the **pivot NL** for labels (canonical spelling — not a make `$subject-$action` pivot). French and Brazilian Portuguese map onto that same English label, then the token. A later Projet Complexe instance may declare its counterpart.
```

### Not this edit

No FR/EN/PT synonym table.

---

## 2. Target — Specificity and collisions handling

### Why

The lookup list is there; the law is not: generic `$subject-$action` stays the pivot; contrib is `hook_ms` specificity; same entity/able contracts.

### Exact edit

After the paragraph that starts *The bottom of this list wins*, before the numbered paths, add:

```markdown
The generic `$subject-$action` stays the pivot. Contrib (and `scripts/asc/extend/`) is `hook_ms` specificity. Implementations share the same `*.entity.yml` / `*.able.yml` contracts; they do not mint a parallel pivot per tool. Example: `make db-dump` vs `dump.mysql.hook.sh` / `dump.pgsql.hook.sh`.
```

### Not this edit

No `agent-swarm-start` / `cursor-swarm-start` files (those names are not in this tree).

---

## 3. Target — ASC domain-specific language : *DSL* syntax

### Why

The bullet *Custom LLMs "harness" (see `asc/extensions/agent`)* points at a dir whose `wrap.sh` and `llm.entity.yml` are empty. The on-disk harness is `make agent-start`.

### Exact edit

Replace:

```markdown
- Custom LLMs "harness" (see `asc/extensions/agent`)
```

with:

```markdown
- Agent harness: `make agent-start` → `hook_ms -s agent -a start` (`asc/extensions/agent/agent/start.sh`). Contrib is the most-specific hook; it shares `agent.entity.yml`.
```

### Not this edit

Do not document `wrap.sh` or swarm-start paths.
