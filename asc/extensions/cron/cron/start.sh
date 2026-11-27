#!/usr/bin/env bash

##
# [abstract] Run the cron start operation.
#
# @example
#   make cron-start
#

. asc/bootstrap.sh

p_entry="${1:-}"

hook_ms 'dry-run' -s 'cron' -a 'start' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ -z "$most_specific_match" || ! -f "$most_specific_match" ]]; then
  echo "Error in $BASH_SOURCE: no cron start implementation found." >&2
  exit 1
fi

hook_ms -s 'cron' -a 'start' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'
