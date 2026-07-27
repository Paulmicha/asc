#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute MySQL actions normally.
#
# @see u_test_batch_exec() in asc/test/test.inc.sh
#
# @example
#   make test-core
#   # Or :
#   asc/test/core.sh
#

u_test_batch_exec 'asc/extensions/mysql/test/asc'
