#!/usr/bin/env bash

##
# List usable model models.
#
# TODO wip: Arguments docblock section.
#
# @example
#   make model-list 'codex'
#   # Or :
#   asc/extensions/agent/model/list.sh 'codex'
#

. asc/bootstrap.sh

# TODO wip: Arguments handling.

hook_ms -s 'model' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
