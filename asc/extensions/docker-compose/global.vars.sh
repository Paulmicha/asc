#!/usr/bin/env bash

##
# Global (env) vars for the 'docker-compose' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# Specifies where the generated (& to be git-ignored) docker-compose.yml file
# will be (over)written.
# @see u_stack_template()
global DC_YML "[default]='$PROJECT_DOCROOT/docker-compose.yml'"

# Determines which docker-compose.yml "template" will be used for current project
# instance.
# @see u_stack_template()
global DC_YML_VARIANTS "[default]='INSTANCE_TYPE HOST_TYPE'"
