#!/usr/bin/env bash

##
# List agent roles.
#
# @example
#   make agent-role-list
#   # Or :
#   asc/extensions/agent/agent/role/list.sh
#

. asc/bootstrap.sh

agent_roles=()

hook -s 'agent_role' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
