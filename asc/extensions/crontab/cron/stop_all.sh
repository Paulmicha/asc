#!/usr/bin/env bash

##
# Remove all ASC-managed crontab lines for this project.
#
# @example
#   make cron-stop-all
#

. asc/bootstrap.sh

f_cron_require_crontab || exit 1
f_cron_crontab_write_block ''
f_cron_project_marker 'marker'
echo "Removed all ASC-managed crontab lines for ${marker}."
