#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core' -v 'HOST_TYPE PROVISION_USING'.
#
# Verifies current instance can execute docker-compose actions normally.
#
# @see f_test_batch_exec() in asc/test/test.opt-inc.sh
#
# @example
#   make test-core
#   # Or :
#   asc/test/core.sh
#

if [[ "$(type -t f_test_batch_exec)" != function ]]; then
  # shellcheck disable=SC1091
  . asc/test/test.opt-inc.sh
fi

f_test_batch_exec 'asc/extensions/compose/test/core'
