#!/usr/bin/env bash

##
# List usable model models.
#
# @example
#   make model-list
#   # Or :
#   asc/extensions/agent/model/list.sh
#

. asc/bootstrap.sh

hook_ms -s 'model' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
