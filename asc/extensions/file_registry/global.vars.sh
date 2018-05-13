#!/usr/bin/env bash

##
# Global (env) vars for the 'file_registry' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# Specifies where the files used as key/value store "backend" should be written.
# @see u_file_registry_get_path()
global FILE_REGISTRY_PATH "[default]='/opt/asc-registry'"
