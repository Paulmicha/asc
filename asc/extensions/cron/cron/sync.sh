#!/usr/bin/env bash

##
# Sync host crontab from generated definitions.
#
# @example
#   make cron-sync
#   make cron-sync e:insta-save
#

. asc/bootstrap.sh

# Ensure generated defs exist.
if [[ ! -d data/asc/cron ]] || [[ -z "$(echo data/asc/cron/*.sh 2>/dev/null)" ]]; then
  f_cron_settings_setup || exit 1
fi

f_cron_sync "$@"
