#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# @see f_moodle_write_settings() in asc/extensions/moodle_d4php/moodle_d4php.inc.sh
# @see f_instance_init() in asc/instance/instance.inc.sh
#

f_moodle_write_settings
