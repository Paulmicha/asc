#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'restart_all' using crontab.
#

f_crontab_require_crontab || exit 1
f_crontab_write_block '' || exit $?

if [[ ! -d data/asc/crontab ]]; then
  f_crontab_settings_setup || exit 1
fi

f_crontab_sync || exit $?
echo "Restarted all enabled cron host lines."
