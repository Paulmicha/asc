#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'prompt generate' wrapped command.
#
# @example
#   make prompt-generate $(asc/escape.sh 'Hello "world".')
#   # Or :
#   asc/extensions/agent/prompt/generate.sh 'Hello "world".'
#

. asc/bootstrap.sh

prompt_generate_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'prompt_generate' -v "$prompt_generate_variants"
hook -s 'agent' -p 'pre' -a 'prompt_generate' -v "$prompt_generate_variants"

. asc/extensions/agent/agent/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'prompt_generate' -v "$prompt_generate_variants"
hook -s 'agent' -p 'post' -a 'prompt_generate' -v "$prompt_generate_variants"
