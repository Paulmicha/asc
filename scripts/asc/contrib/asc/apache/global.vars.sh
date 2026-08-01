#!/usr/bin/env bash

##
# Global (env) vars for the 'apache' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global ASC_APACHE_INIT_VHOST "[default]=false [help]='Set to « true » to automatically generate a vhost definition for this instance during instance init.'"
