#!/usr/bin/env bash

##
# Global (env) vars for the 'mysql' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global SQL_CHARSET "[default]=utf8mb4 [help]='Some DB operations like import (a db dump) require that we specify the default DB charset, i.e. the --default_character_set argument of the mysql program.'"

global SQL_COLLATION "[default]=utf8mb4_general_ci [help]='SQL collation setting required by some language-specific implementations.'"
