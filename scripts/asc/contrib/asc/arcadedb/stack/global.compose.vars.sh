#!/usr/bin/env bash

##
# Stack-specific custom ASC globals for instances using docker-compose.
#
# See https://hub.docker.com/_/arcadedb/
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global ARCADEDB_TAG "[default]='3.7.12'"
