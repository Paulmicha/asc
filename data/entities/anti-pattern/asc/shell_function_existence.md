---
description: Every ASC shell function must have a valid reason to exist as a function. It must do something substancial and it must carry intrinsic value for avoiding repeating blocks of code reused in several places.
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
