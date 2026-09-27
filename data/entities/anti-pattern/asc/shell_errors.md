---
description: Errors must always give feedback and provide enough contextual information to be self-explainable.
globs: '*.sh'
---

Errors must write feedback to stderr and provide details where it originates.

# Anti-pattern example (don't)

Don't write to stdout, and don't give feedback without contextual details.

```sh
if [[ -z "$DB_NAME" ]]; then
  echo "Unable to set active DB"
  exit 1
fi
```

# Correct example (do)

```sh
if [[ -z "$DB_NAME" ]]; then
  echo >&2
  echo "Error in f_db_set() - $BASH_SOURCE line $LINENO: DB_NAME is empty." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi
```
