#!/usr/bin/env bash

##
# Pull model in given provider (if applicable, e.g. ollama, ollaya).
#
# TODO wip: Arguments docblock section.
#
# @example
#   make model-pull 'ollama' 'qwen3.8-flash'
#   # Or :
#   asc/extensions/agent/model/pull.sh 'ollama' 'qwen3.8-flash'
#

. asc/bootstrap.sh

# TODO wip: Arguments handling.

hook_ms -s 'model' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
