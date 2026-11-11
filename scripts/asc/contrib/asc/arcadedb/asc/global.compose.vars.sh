#!/usr/bin/env bash

##
# Global (env) vars for arcadedb extension provisionned using docker-compose.
#
# Provides service name (container) for use in bash aliases.
# @see scripts/asc/contrib/asc/arcadedb/asc/alias.compose.hook.sh
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/core/global.manual-inc.sh
# @see asc/bootstrap.sh
#

global ARCADEDB_SNAME "[default]=arcadedb"
