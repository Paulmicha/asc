#!/usr/bin/env bash

##
# Remove host crontab lines for one entry (YAML def kept_arr).
#
# @example
#   make cron-stop e:insta-save
#

. asc/bootstrap.sh

a_entry="${1:-}"
if [[ -z "$a_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

f_cron_stop_entry "$a_entry"
