#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'start' using crontab.
#

if [[ -z "$p_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

if [[ ! -d data/asc/crontab ]]; then
  f_crontab_settings_setup || exit 1
fi

f_crontab_start_entry "$p_entry"
