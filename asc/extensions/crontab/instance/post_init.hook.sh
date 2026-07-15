#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init'.
#
# Regenerates crontab definitions (files only by default).
# @see u_cron_settings_setup() in asc/extensions/crontab/crontab.inc.sh
#

echo "Writing generated crontab definitions ..."

u_cron_settings_setup

case "${ASC_CRON_SYNC_ON_INIT:-false}" in true|TRUE|yes|YES|1)
  echo "Syncing host crontab (ASC_CRON_SYNC_ON_INIT) ..."
  u_cron_sync
esac

echo "Writing generated crontab definitions : done."
echo
