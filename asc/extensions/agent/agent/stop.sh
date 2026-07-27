#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make agent-stop
#   # Or :
#   asc/extensions/agent/agent/stop.sh
#

. asc/bootstrap.sh

u_hook_most_specific -s 'agent' -a 'stop' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
