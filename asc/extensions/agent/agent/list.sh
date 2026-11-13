#!/usr/bin/env bash

##
# List usable agents.
#
# @example
#   make agent-list
#   # Or :
#   asc/extensions/agent/agent/list.sh
#

. asc/bootstrap.sh

hook -s 'agent' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
