#!/usr/bin/env bash

##
# List usable model models.
#
# @example
#   make model-pull
#   # Or :
#   asc/extensions/agent/model/pull.sh
#

. asc/bootstrap.sh

hook_ms -s 'model' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
