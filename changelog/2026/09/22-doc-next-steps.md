# `doc` next-steps list

> **2026-09-25 concertation.** This file is done. [25-concert-order.md](./25-concert-order.md) does not reopen it.

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **implemented** |
| **Scope** | `asc/doc/next_steps.sh` writes `./NEXT_STEPS.agent.md`. `./NEXT_STEPS.md` is the human approval file. Both are project-docroot hook data (`hook_ms` dry-run, `-c md -r`), same rung model as `env.yml`. |
| **Not this change** | An `asc/extensions/agent/` hook implementation. Root README wording (`hook_ms` is still a TODO there). The `reg-get` / `reg-set` store — [22-gates-registry-alternative.md](./22-gates-registry-alternative.md). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

The entry point reads changelog status rows. Implemented, done, shipped, and skipped notes are not tasks. "Later" / "no code" / review notes are pointers for `NEXT_STEPS.md`. The agent file orders the rest as sequential or parallel. Re-run `asc/doc/next_steps.sh` to refresh the agent file. The script does not write `NEXT_STEPS.md` or `gates.yml`. Go-ahead for a listed task is the matching `go` field in `gates.yml`.
