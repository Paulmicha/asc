#!/usr/bin/env bash

##
# Implements hook -s 'agent_role' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'.
#
# Provides ASC core default agent roles.
#
# @see asc/extensions/agent/agent/role/list.sh
#

agent_roles+=('reviewer')
agent_roles+=('writer')
