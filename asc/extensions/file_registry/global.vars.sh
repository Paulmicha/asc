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

global FILE_REGISTRY_HOST_LEVEL_PATH "[default]='/opt/asc-registry' [help]='Specifies where the files used as key/value store backend should be written. Important note : when hosting multiple ASC projects and/or project instances on the same host, if this value differs, the host-level values won’t be shared (which defeats their purpose).'"
