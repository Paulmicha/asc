#!/usr/bin/env bash

##
# Unload model by provider.
#
# TODO wip: Arguments docblock section.
#
# @example
#   make model-unload 'tiiny' 'foobar-model'
#   # Or :
#   asc/extensions/agent/model/unload.sh 'tiiny' 'foobar-model'
#

. asc/bootstrap.sh

# TODO wip: Arguments handling.

hook_ms -s 'model' -a 'unload' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
