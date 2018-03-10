#!/usr/bin/env bash

##
# ASC core hook-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# @example
#   asc/test/asc/hook.test.sh
#

. asc/bootstrap.sh

##
# Single arg hook : action.
#
test_asc_hook_single_action() {
  local dry_run_hook=1
  hook -a 'install'
  assertFalse 'Global ASC_INC is empty (bootstrap test failed)' "[ -e \"$ASC_INC\" ]"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
