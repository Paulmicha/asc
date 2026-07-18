#!/usr/bin/env bash

##
# Global (env) vars for the 'nested_git' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global ASC_SYNONYMS "[append]='nested-git/subgit'"
