#!/usr/bin/env bash

##
# Global (env) vars for the 'drupalwt' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# Make the automatic crontab setup for Drupal cron on local host during 'app
# install' opt-in.
global DWT_USE_CRONTAB "[default]=false"

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in asc/instance/instance.inc.sh
global ASC_MAKE_TASKS_SHORTER "[append]='drupalwt/dwt'"
