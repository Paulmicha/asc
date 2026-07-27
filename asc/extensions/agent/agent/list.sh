#!/usr/bin/env bash

##
# List usable agent models.
#
# @example
#   make agent-list
#   # Or :
#   asc/extensions/agent/agent/list.sh
#

. asc/bootstrap.sh

u_hook_most_specific -s 'agent' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
