#!/usr/bin/env bash

##
# Restart all enabled cron host entries (stop-all then sync).
#
# @example
#   make cron-restart-all
#

. asc/bootstrap.sh

f_cron_require_crontab || exit 1
f_cron_crontab_write_block ''

if [[ ! -d data/asc/cron ]]; then
  f_cron_settings_setup || exit 1
fi

f_cron_sync
echo "Restarted all enabled cron host lines."
