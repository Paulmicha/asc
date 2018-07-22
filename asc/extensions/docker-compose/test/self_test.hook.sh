#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute docker-compose actions normally.
#
# @see u_test_batch_exec() in asc/test/test.inc.sh
#
# @example
#   make self-test
#   # Or :
#   asc/test/self_test.sh
#

u_test_batch_exec 'asc/extensions/docker-compose/test/self'
