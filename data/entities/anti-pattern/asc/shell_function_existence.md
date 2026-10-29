---
description: Every ASC shell function must encapsulate substantial behavior beyond naming the expression it replaces. Multiple callers alone do not justify extraction. Prefer direct variable expansions, local path assignments, and simple shell conditions.
globs: '*.sh'
---

Do not create functions that are clogging up the amount of bash functions in any ASC bootstrapped context.

# Anti-pattern example (don't)

```sh
##
# Ensure local software state dir exists.
#
f_software_ensure_state_dir() {
  mkdir -p data/asc/software
}
```

# Correct example (do)

```sh
# Just call this directly where appropriate :
mkdir -p data/asc/software
```
