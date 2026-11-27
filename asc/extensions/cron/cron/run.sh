#!/usr/bin/env bash

##
# [abstract] Run a scheduled cron entry.
#
# @example
#   make cron-run e:insta-save
#   asc/extensions/cron/cron/run.sh insta-save
#

. asc/bootstrap.sh

p_entry="${1:-}"
p_entry="${p_entry#e:}"

if [[ -z "$p_entry" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - entry name required (e:<make-entry>)." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Check before dispatch: the selected hook can itself call hook_ms and replace
# most_specific_match. Dispatch still goes through hook_ms for overrides.
hook_ms 'dry-run' -s 'cron' -a 'run' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ -z "${most_specific_match:-}" || ! -f "$most_specific_match" ]]; then
  echo >&2 "Error: no hook -s cron -a run implementation found."
  exit 1
fi

hook_ms -s 'cron' -a 'run' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS' || exit $?
