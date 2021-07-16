#!/usr/bin/env bash

##
# Global (env) vars for pgsql extension provisionned using docker-compose.
#
# Provides service name (container) for use in bash aliases.
# @see asc/extensions/pgsql/asc/bootstrap.docker-compose.hook.sh
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global ARANGODB_SNAME "[default]=arangodb"
