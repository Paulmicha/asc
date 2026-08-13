#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make agent-stop-all
#   # Or :
#   asc/extensions/agent/agent/stop_all.sh
#

. asc/bootstrap.sh

hook_ms -s 'agent' -a 'stop_all' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
