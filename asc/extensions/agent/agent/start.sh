#!/usr/bin/env bash

##
# Abstract local LLM bring-up: bootstrap → most-specific hook.
#
# @example
#   make agent-start
#   # Or :
#   asc/extensions/agent/agent/start.sh
#

. asc/bootstrap.sh

hook_ms -s 'agent' -a 'start' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
