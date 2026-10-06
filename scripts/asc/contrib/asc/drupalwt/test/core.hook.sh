#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core' -v 'HOST_TYPE PROVISION_USING'.
#
# @see f_test_batch_exec() in asc/test/test.opt-inc.sh
#
# @example
#   make test-core
#   # Or :
#   asc/test/core.sh
#

f_test_batch_exec 'scripts/asc/contrib/asc/drupalwt/test/core' || exit $?
