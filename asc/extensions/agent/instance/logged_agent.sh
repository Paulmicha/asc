#!/usr/bin/env bash

##
# Logged agent composition: log/wrap → thread/agent.
#
# @example
#   make logged-agent e:blueprint-generate e:transcribe-all
#   # Or :
#   asc/instance/logged_agent.sh e:blueprint-generate e:transcribe-all
#

. asc/bootstrap.sh

logged_agent_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_agent' -v "$logged_agent_variants"
hook -s 'agent' -p 'pre' -a 'logged_agent' -v "$logged_agent_variants"

asc/log/log.wrap.sh asc/extensions/agent/agent/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'logged_agent' -v "$logged_agent_variants"
hook -s 'agent' -p 'post' -a 'logged_agent' -v "$logged_agent_variants"
