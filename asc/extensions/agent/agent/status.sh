#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make agent-status
#   # Or :
#   asc/extensions/agent/agent/status.sh
#

. asc/bootstrap.sh

u_hook_most_specific -s 'agent' -a 'status' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
