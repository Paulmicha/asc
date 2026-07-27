#!/usr/bin/env bash

##
# ASC core tests entry point (subject test / action asc).
#
# Triggers the `test asc` hook so core and enabled extensions can run low-level
# checks that validate the base stack on the current host/instance.
#
# @see asc/test/asc.hook.sh
#
# @example
#   make test-core
#   # Or :
#   asc/test/core.sh
#

. asc/bootstrap.sh

hook -s 'test' -a 'core' -v 'PROVISION_USING HOST_TYPE HOST_OS'
