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

# Multi-site setup switch.
global DWT_MULTISITE "[default]=false"

# Manage settings files automatically.
# @see asc/extensions/drupalwt/instance/post_init.hook.sh
# @see asc/extensions/drupalwt/instance/post_rebuild.hook.sh
global DWT_MANAGE_SETTINGS_FILES "[default]=true [help]='After instance init and/or rebuild, this global determines wether the files sites/default/settings.php, sites/default/settings.local.php, and sites/sites.php (if this is a multi-site setup) will be automatically (re)written where appropriate. Also, if no sites/default/settings.php file exists, the Drupal core default file will be used. If this is a multi-site setup, all the settings files of all sites will also get (re)written.'"

global DWT_USE_SETTINGS_LOCAL_OVERRIDE "[default]=true [help]='When true, after instance init and/or rebuild, if no sites/default/settings.php file exists, the Drupal core default file will be used with local override support (i.e. the last lines about settings.local.php activated). Also, the generated Drupal settings file will be sites/default/settings.local.php.'"

global DWT_MANAGE_MULTISITE_SETTINGS_FILE "[default]=true [help]='Make (re)generating the multi-site settings file - e.g. sites/sites.php - optional.'"

# Make the automatic crontab setup for Drupal cron on local host during 'app
# install' opt-in.
global DWT_USE_CRONTAB "[default]=false [help]='When true, during app install, a generic crontab entry for running Drupal cron will be created on local host (if it has the crontab program installed).'"
# global DWT_CRON_FREQ "[default]='*/20 * * * *'"
global DWT_CRON_FREQ "[default]='0 * * * *'"

# [optional] Shorter generated make tasks names.
# @see u_make_task_name() in asc/instance/instance.inc.sh
global ASC_SYNONYMS "[append]='drupalwt/dwt'"
