#!/usr/bin/env bash

##
# Implements hook -p 'post' -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:app p:pre a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
# $ make hook-debug s:app p:post a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   asc/app/install.sh
#

# Provide default cron job implementation for this Drupal instance on local host
# using crontab. This setup is opt-in, i.e. the DWT_USE_CRONTAB global.
# @see asc/extensions/drupalwt/global.vars.sh
# @see asc/extensions/drupalwt/app/global.vars.sh
# @see f_host_crontab_add() in asc/host/host.inc.sh
case "$DWT_USE_CRONTAB" in 1|y*|true)
  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host ..."

  f_host_crontab_add "cd $PROJECT_DOCROOT && asc/extensions/drupalwt/instance/drush.sh cron" "$DWT_CRON_FREQ"

  echo "Setup Drupal cron job for instance $INSTANCE_DOMAIN on local host : done."
  echo
esac
