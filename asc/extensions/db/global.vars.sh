#!/usr/bin/env bash

##
# Global (env) vars for the 'db' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global ASC_DB_MODE "[default]=none [help]='Specifies if ASC should handle DB credentials, and how. Possible values are none = credentials are handled externally, auto = local instance DB credentials are automatically generated (using random password), or manual = requests values once (using interactive terminal prompts).'"

global ASC_DB_DUMPS_BASE_PATH "[default]=$PROJECT_DOCROOT/dumps"
