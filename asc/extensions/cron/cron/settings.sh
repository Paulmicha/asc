#!/usr/bin/env bash

##
# [abstract] Run the cron settings operation.
#
# @example
#   make cron-settings
#

. asc/bootstrap.sh

p_entry="${1:-}"

hook_ms 'dry-run' -s 'cron' -a 'settings' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ -z "$most_specific_match" || ! -f "$most_specific_match" ]]; then
  echo "Error in $BASH_SOURCE: no cron settings implementation found." >&2
  exit 1
fi

hook_ms -s 'cron' -a 'settings' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'
