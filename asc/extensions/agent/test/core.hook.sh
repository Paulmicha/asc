#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core'.
#
# @see asc/extensions/entity/test/core.hook.sh
#

if [[ "$(type -t f_test_batch_exec)" != function ]]; then
  # shellcheck disable=SC1091
  . asc/test/test.opt-inc.sh
fi

f_test_batch_exec 'asc/extensions/agent/test/core' || exit $?
