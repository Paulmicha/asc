#!/usr/bin/env bash

##
# [abstract] Run the cron sync operation.
#
# @var VARIANTS : String : space-separated hooks variants' variable names.
#   Defaults to 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'.
#
# @example
#   # Default cron-sync call (no variant) :
#   # e.g. scripts/asc/contrib/asc/crontab/cron/sync.hook.sh
#   make cron-sync
#
#   # Only executes a specific arbitrary namespace in discoverable cron-sync
#   # hooks implementations :
#   # e.g. scripts/asc/contrib/asc/crontab/cron/sync.foobar.hook.sh
#   make cron-sync foobar
#

. asc/bootstrap.sh

p_entry="${1:-}"

export VARIANTS="${VARIANTS:-STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS}"

hook_ms 'dry-run' -s 'cron' -a 'sync' -v "$VARIANTS"

if [[ -z "$most_specific_match" || ! -f "$most_specific_match" ]]; then
  echo "Error in $BASH_SOURCE: no cron sync implementation found." >&2
  exit 1
fi

hook_ms -s 'cron' -a 'sync' -v "$VARIANTS"
