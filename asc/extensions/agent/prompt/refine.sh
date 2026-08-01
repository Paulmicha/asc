#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'prompt refine' wrapped command.
#
# @example
#   make prompt-refine $(asc/escape.sh 'Hello "world".')
#   # Or :
#   asc/extensions/agent/prompt/refine.sh 'Hello "world".'
#

. asc/bootstrap.sh

prompt_refine_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'prompt_refine' -v "$prompt_refine_variants"
hook -s 'agent' -p 'pre' -a 'prompt_refine' -v "$prompt_refine_variants"

. asc/extensions/agent/agent/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'prompt_refine' -v "$prompt_refine_variants"
hook -s 'agent' -p 'post' -a 'prompt_refine' -v "$prompt_refine_variants"
