#!/usr/bin/env bash

##
# Sync ASC upstream repo.
#
# 1. Either asc/core/install.sh or asc/core/upgrade.sh
# 2. Run asc/core/sync.sh for any ("deploy") sync e.g. "inboxes".
#
# Turns possible things like :
# - updating select ("diff") cached pivots and/or hook implementations,
#   instead of doing a full "make reinit" every time ;
# - extensions hooks like "ext-install.hook.sh"
# - uninstalled extensions hooks like "ext-uninstall.hook.sh"
# - agents skills as well ("skill-install.hook.sh", "ext-uninstall.hook.sh")
#
# @example
#   # Sync ASC upstream into current project instance :
#   asc/core/sync.sh
#   # Or :
#   make core-sync
#
#   # Sync ASC upstream repo into given project instance :
#   asc/core/sync.sh path/to/folder
#   # Or :
#   make core-sync path/to/folder
#

export instance_path="$1"

if [[ -z "$instance_path" ]]; then
  instance_path="$PROJECT_DOCROOT"
fi

if [[ ! -d "$instance_path" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: instance path does not exist." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Instead of a full, slow "make reinit", target specific diffed trees only.
# "Wireable" as a git hook or anything.
asc/dsl.sh << DSL

ext-sync
cache-sync
data-sync
specs-sync
providers-sync
models-sync
skills-sync
host-sync
remote-hosts-sync
agents-sync
docs-sync
stack-sync

DSL

exit $?
