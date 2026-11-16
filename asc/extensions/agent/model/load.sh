#!/usr/bin/env bash

##
# Load model by provider.
#
# TODO wip: Arguments docblock section.
#
# @example
#   make model-load 'tiiny' 'foobar-model'
#   # Or :
#   asc/extensions/agent/model/load.sh 'tiiny' 'foobar-model'
#

. asc/bootstrap.sh

# TODO wip: Arguments handling.

hook_ms -s 'model' -a 'load' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
