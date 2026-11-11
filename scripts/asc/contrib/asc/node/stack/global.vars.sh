#!/usr/bin/env bash

##
# Stack-specific custom ASC globals.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/core/global.manual-inc.sh
# @see asc/bootstrap.sh
#

global NODE_PORT '[default]=3000'
