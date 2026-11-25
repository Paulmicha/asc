---
description: Every ASC script using the single *.sh file extension gets discovered as an entry point (also called an ASC action), which is not free. It grows the list of make entries of the project instance.
globs: '*.sh'
---

Do not create entry points that are not truly worth it.

# Anti-pattern example (don't)

Create a new `path/to/subject/$action.sh` file e.g. just to store some function reused elsewhere.

# Correct example (do)

Only create entry points that are meaningful, substancial, and justified.
