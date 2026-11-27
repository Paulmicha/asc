#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'settings' using crontab.
#

f_crontab_settings_setup || exit 1

echo
echo "=== Effective crontab definitions ==="
echo

shopt -s nullglob
for f in data/asc/crontab/*.sh; do
  # shellcheck disable=SC1090
  . "$f"
  echo "entry      : $ASC_CRON_ENTRY"
  echo "  preset   : $ASC_CRON_PRESET"
  echo "  enabled  : $ASC_CRON_ENABLED"
  echo "  schedule : $ASC_CRON_SCHEDULE"
  echo "  wrap     : $ASC_CRON_WRAP"
  echo "  lock     : $ASC_CRON_LOCK"
  echo "  retry    : max=$ASC_CRON_RETRY_MAX delay=$ASC_CRON_RETRY_DELAY"
  echo "  cmd      : $ASC_CRON_CMD"
  echo "  source   : $ASC_CRON_SOURCE"
  echo
done
