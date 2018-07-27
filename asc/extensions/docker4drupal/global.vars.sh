#!/usr/bin/env bash

##
# Global (env) vars for the 'docker4drupal' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# [optional] Shorter generated make tasks names.
# @see u_instance_task_name() in asc/instance/instance.inc.sh
global ASC_MAKE_TASKS_SHORTER "[append]='docker4drupal/d4d'"

# Add custom 'make' entry points (CLI shortcuts).
# @see asc/extensions/docker4drupal/cli/drush.make.sh
# @see asc/extensions/docker4drupal/cli/drupal.make.sh
global ASC_MAKE_INC "[append]='asc/extensions/docker4drupal/make.mk'"
