#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'prompt create' wrapped command.
#
# @example
#   make prompt-create $(asc/escape.sh 'Hello "world".')
#   # Or :
#   asc/extensions/agent/prompt/create.sh 'Hello "world".'
#

. asc/bootstrap.sh

prompt_create_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'prompt_create' -v "$prompt_create_variants"
hook -s 'agent' -p 'pre' -a 'prompt_create' -v "$prompt_create_variants"

. asc/extensions/agent/agent/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'prompt_create' -v "$prompt_create_variants"
hook -s 'agent' -p 'post' -a 'prompt_create' -v "$prompt_create_variants"
