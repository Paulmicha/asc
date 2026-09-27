---
description: Every ASC shell Yaml files must have a leading docblock describing what it does, how (when deemed not self-explanatory).
globs: '*.yml, *.yaml'
---

Notice the line break before the file docblock. Unlike scripts, Yaml files do not use a shebang, so the first line must be an empty line.

# Anti-pattern example (don't)

```sh
# Local instance global (.env) vars definitions.
stack:
  version: specimen-2026
asc:
  apps: site api auth index
```

# Correct example (do)

```sh

##
# Local instance global (.env) vars definitions.
#
# This is used to generate the .env file in project docroot.
# @see u_instance_init() in asc/instance/instance.inc.sh
#
# By convention, variable names ending with "_C" are container paths, e.g. :
# API_APP_DOCROOT (on local machine) = API_APP_DOCROOT_C (in container).
#

stack:
  version: specimen-2026

asc:
  apps: site api auth index

```
