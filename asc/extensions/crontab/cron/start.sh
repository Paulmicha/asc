#!/usr/bin/env bash

##
# Install/sync host crontab including given entry (full enabled set).
#
# @example
#   make cron-start e:insta-save
#

. asc/bootstrap.sh

a_entry="${1:-}"
if [[ -z "$a_entry" ]]; then
  echo >&2 "Error: e:<entry> required."
  exit 1
fi

if [[ ! -d data/asc/cron ]]; then
  f_cron_settings_setup || exit 1
fi

f_cron_start_entry "$a_entry"
