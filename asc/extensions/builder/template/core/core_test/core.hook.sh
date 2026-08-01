#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core' -v 'HOST_TYPE PROVISION_USING'.
#
# @requires running the tests with the same user that will use ASC.
#
# @see f_test_batch_exec() in asc/test/test.inc.sh
#
# @example
#   make test-core
#   # Or :
#   asc/test/core.sh
#

f_test_batch_exec '{{ path }}/test/core' || exit $?
