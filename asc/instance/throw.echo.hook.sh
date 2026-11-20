#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'throw' -v 'LV HANDLER HOST_TYPE'.
#
# @see asc/core/utils/shell.manual-inc.sh
#
# @example
#   make throw "Hello world"
#   # Or :
#   asc/instance/throw.sh
#

echo "$ARGS" >&2
