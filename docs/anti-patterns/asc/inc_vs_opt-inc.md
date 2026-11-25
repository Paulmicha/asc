---
description: Never add eager loaded shell includes without a strong reason to do so.
globs: '*.sh'
---

If you use eager `*.inc.sh` double extension scripts in active dirs, those get loaded on *every* ASC-bootstrapped contexts. It is not free on slower hardware.

# Anti-pattern example (don't)

Eager `*.inc.sh` for specific tasks like `f_skill_render()` (e.g. `asc/extensions/agent/skill/skill.inc.sh`).

# Correct example (do)

- Prefer the leazy-loaded `*.opt-inc.sh` double extension scripts (e.g. `asc/extensions/agent/skill/skill.opt-inc.sh`).
- Manual, direct include of any "self-contained" action-specific functions is also an option, ex: `asc/git/write_hooks.sh`
