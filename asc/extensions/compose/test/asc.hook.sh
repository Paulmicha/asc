#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'asc' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute docker-compose actions normally.
#
# @see u_test_batch_exec() in asc/test/test.inc.sh
#
# @example
#   make test-asc
#   # Or :
#   asc/test/asc.sh
#

u_test_batch_exec 'asc/extensions/compose/test/asc'
