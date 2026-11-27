#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'stop' using crontab.
#

if [[ -z "$p_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

f_crontab_stop_entry "$p_entry"
