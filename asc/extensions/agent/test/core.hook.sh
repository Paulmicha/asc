#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'core'.
#
# @see asc/extensions/entity/test/core.hook.sh
#

f_test_batch_exec 'asc/extensions/agent/test/core' || exit $?
