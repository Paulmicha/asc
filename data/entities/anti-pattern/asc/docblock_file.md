---
description: Every ASC shell script files must have a leading docblock after its shebang line describing what it does, how (when deemed not self-explanatory), and follows a Javadoc-like syntax to list eventual arguments, return codes, and references.
globs: '*.sh'
---

ASC uses unconventional Bash coding styleguides. In particular, it uses a DocBlock convention originating from the classic Javadoc blueprint, but tailored for eventual static analysis.

# Anti-pattern example (don't)

```sh
#!/usr/bin/env bash
# Deletes all traces of this project instance on current host.
. asc/bootstrap.sh
hook -s 'instance' -p 'pre' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'post' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
```

# Correct example (do)

```sh
#!/usr/bin/env bash

##
# [abstract] Deletes all traces of this project instance stack on current host.
#
# This action provides an entry point for triggering a specific hook. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this action to have any effect, it is necessary
# to use an extension that implements at least one of these hooks.
#
# To list all the possible paths that are sourceable when the hook is triggered,
# run (in this order) :
# $ make hook-debug s:instance p:pre a:destroy v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance a:destroy v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
# $ make hook-debug s:instance p:post a:destroy v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# @example
#   make destroy
#   # Or :
#   asc/instance/destroy.sh
#

. asc/bootstrap.sh

hook -s 'instance' -p 'pre' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
hook -s 'instance' -p 'post' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
```
