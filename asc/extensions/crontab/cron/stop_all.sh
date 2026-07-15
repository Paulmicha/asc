#!/usr/bin/env bash

##
# Remove all ASC-managed crontab lines for this project.
#
# @example
#   make cron-stop-all
#

. asc/bootstrap.sh

u_cron_require_crontab || exit 1
u_cron_crontab_write_block ''
echo "Removed all ASC-managed crontab lines for $(u_cron_project_marker)."
