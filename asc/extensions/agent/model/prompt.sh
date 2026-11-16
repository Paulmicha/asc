#!/usr/bin/env bash

##
# Prompt usable models by provider.
#
# TODO wip: Arguments docblock section.
#
# @example
#   make model-prompt 'codex' 'gpt-6.1-terra-high' 'worspace-foobar' '(TODO prompt ID ? Args ? DSL ?)'
#   # Or :
#   asc/extensions/agent/model/prompt.sh 'codex' 'gpt-6.1-terra-high'' 'worspace-foobar' '(TODO prompt ID ? Args ? DSL ?)'
#

. asc/bootstrap.sh

# TODO wip: Arguments handling.

hook_ms -s 'model' -a 'prompt' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
