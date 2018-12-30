#!/usr/bin/env bash

##
# [abstract] Starts this project instance's necessary services on host.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# @example
#   make start
#   # Or :
#   asc/instance/start.sh
#

. asc/bootstrap.sh

hook -s 'instance app' -a 'start' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
