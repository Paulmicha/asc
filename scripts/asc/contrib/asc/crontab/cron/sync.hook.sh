#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'sync' using crontab.
#

# Ensure generated defs exist.
if [[ ! -d data/asc/crontab ]] || [[ -z "$(echo data/asc/crontab/*.sh 2>/dev/null)" ]]; then
  f_crontab_settings_setup || exit 1
fi

f_crontab_sync
