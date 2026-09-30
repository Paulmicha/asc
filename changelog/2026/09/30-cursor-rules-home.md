# Cursor rule ownership moves to the home user rules

The procedure text those home rules still carry is the subject of [30-asc-guidance-as-project-skills.md](./30-asc-guidance-as-project-skills.md). This work tree no longer has `.cursor/rules/`. The pertinent sentences were moved into `AGENTS.md` and `.agents/skills/` first. `origin/main` still contains the four files and an `upgrade.sh` that copies them. Publishing this deletion before those older scripts have upgraded makes that copy exit 4 after `asc/` is replaced.

| Field | Value |
|-------|-------|
| **Date** | 2026-09-30 |
| **Status** | Implemented for the mother checkout and inspected dev stack instances on this host. Other checkouts and remote instances unverified. |
| **Scope** | Generic Cursor rules only. `AGENTS.md` and `.agents/skills/` remain project files. |
| **Authorization** | Direct user instruction for this move. The file-transport gate in `gates.core.yml` remains unchanged and does not authorize its separate hook and `AGENTS.md` proposal. |

Cursor loads `.mdc` files under `$HOME/.cursor/rules/` as host user rule files in every workspace. The home repository is now the version-control owner for shared ASC Cursor guidance there. Project-specific Cursor rules remain in each instance. The four shared Cursor rules have been removed from this mother checkout and from the `core-upgrade` copy list; that command continues to transport the three ASC agent skills and `AGENTS.md`.

`make host-cursor-rules-sync` now reports the host user rules and local ASC project rules without pulling the mother or copying files. The Cursor contrib README describes the new scope.

The earlier [shared agent-instructions plan](28-agent-instructions-travel.md) used mother-owned Cursor rules. Its Cursor transport and staged retirement sections are superseded by this direct instruction. Its separate `AGENTS.md` and post-upgrade hook proposal remains gated and unimplemented.

An older `core-upgrade` process still has the four Cursor rule paths in its running script. Against a mother clone without those files, it can replace `asc/` and then fail at the rule copy. Update that instance's `asc/core/upgrade.sh` before running `core-upgrade`. Remote instances have not been inspected or changed.
