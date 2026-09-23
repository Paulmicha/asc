# Next-steps files follow env.yml lookup

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | implemented |
| **Scope** | Docroot next-steps discovery for the mother checkout. |
| **Not this change** | A specimen next-steps file. A synonym that makes hook lookup treat `mother` as `core`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## What

`NEXT_STEPS.core.md` is the human file. `NEXT_STEPS.agent.core.md` is the agent file. `asc/doc/next_steps.sh` rewrites only the agent file. With `INSTANCE_TYPE=core` the paths are:

```sh
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' \
  -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r
# → NEXT_STEPS.core.md

next_steps_actor=agent
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' \
  -v 'next_steps_actor STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r
# → NEXT_STEPS.agent.core.md
```

`next_steps_actor` stays first so the agent variant is `agent.core`, not `core.agent`.

## Check

`asc/test/core/next_steps.test.sh` — `test_doc_next_steps_docroot_rung`.
