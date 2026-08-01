#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'post' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrite Drupal local settings file.
#
# @see asc/instance/rebuild.sh
# @see asc/extensions/drupalwt/drupalwt.inc.sh
#

f_dwt_write_settings
