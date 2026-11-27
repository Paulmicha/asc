#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'stop_all' using crontab.
#

f_crontab_require_crontab || exit 1
f_crontab_write_block '' || exit $?
f_crontab_project_marker 'marker'
echo "Removed all ASC-managed crontab lines for ${marker}."
