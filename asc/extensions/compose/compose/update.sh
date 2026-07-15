#!/usr/bin/env bash

##
# Apply changes to the compose stack services.
#
# (Re)generate the git-ignored compose files + restart all stack services.
#
# @example
#   make compose-update
#   # Or :
#   asc/extensions/compose/compose/update.sh
#

. asc/extensions/compose/compose/write.sh
. asc/instance/restart.sh
