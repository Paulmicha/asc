#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init'.
#
# Regenerates crontab definitions (files only by default).
# @see f_crontab_settings_setup() in scripts/asc/contrib/asc/crontab/cron/cron.opt-inc.sh
#

. scripts/asc/contrib/asc/crontab/cron/cron.opt-inc.sh

echo "Writing generated crontab definitions ..."

f_crontab_settings_setup || exit $?

case "${ASC_CRON_SYNC_ON_INIT:-false}" in true|TRUE|yes|YES|1)
  echo "Syncing host crontab (ASC_CRON_SYNC_ON_INIT) ..."
  f_crontab_sync || exit $?
esac

echo "Writing generated crontab definitions : done."
echo
