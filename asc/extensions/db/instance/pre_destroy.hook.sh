#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'destroy' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure DB-related env. vars. get exported for extensions which need them
# during this action - e.g. docker-compose.
#
# @see asc/instance/destroy.sh
# @see asc/extensions/compose/instance/destroy.compose.hook.sh
#

u_db_set_all
