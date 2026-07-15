#!/usr/bin/env bash

##
# ASC core evaluates entry point (subject evaluate / action asc).
#
# Triggers the `evaluate asc` hook so core and enabled extensions can run low-level
# checks that validate the base stack on the current host/instance.
#
# @see asc/extensions/principle/evaluate/asc.sh
#
# @example
#   make evaluate-asc
#   # Or :
#   asc/extensions/principle/evaluate/asc.sh
#

. asc/bootstrap.sh

hook -s 'evaluate' -a 'asc' -v 'PROVISION_USING INSTANCE_TYPE HOST_TYPE HOST_OS'
