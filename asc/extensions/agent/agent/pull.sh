#!/usr/bin/env bash

##
# List usable agent models.
#
# @example
#   make agent-pull
#   # Or :
#   asc/extensions/agent/agent/pull.sh
#

. asc/bootstrap.sh

hook_ms -s 'agent' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
