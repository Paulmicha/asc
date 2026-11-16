#!/usr/bin/env bash

##
# [abstract] Triggers a generic 'prompt review' wrapped command.
#
# @example
#   make prompt-review $(asc/escape.sh 'Hello "world".')
#   # Or :
#   asc/extensions/agent/prompt/review.sh 'Hello "world".'
#

. asc/bootstrap.sh

prompt_review_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'prompt_review' -v "$prompt_review_variants"
hook -s 'agent' -p 'pre' -a 'prompt_review' -v "$prompt_review_variants"

. asc/extensions/agent/agent/wrap.sh "$@"

hook -s 'log' -p 'post' -a 'prompt_review' -v "$prompt_review_variants"
hook -s 'agent' -p 'post' -a 'prompt_review' -v "$prompt_review_variants"
