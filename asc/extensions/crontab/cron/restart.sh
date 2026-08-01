#!/usr/bin/env bash

##
# Restart one cron host entry (stop then start/sync).
#
# @example
#   make cron-restart e:insta-save
#

. asc/bootstrap.sh

a_entry="${1:-}"
if [[ -z "$a_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

f_cron_stop_entry "$a_entry"
f_cron_start_entry "$a_entry"
