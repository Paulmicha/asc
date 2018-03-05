#!/usr/bin/env bash

##
# ASC core bootstrap-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# @example
#   asc/test/asc/bootstrap.test.sh
#

. asc/bootstrap.sh

##
# Are all required ASC core globals successfully initialized ?
#
# @see u_asc_extend()
#
test_asc_has_essential_globals() {
  assertFalse 'Global ASC_SUBJECTS is empty (bootstrap test failed)' "[ -e \"$ASC_SUBJECTS\" ]"
  assertFalse 'Global ASC_ACTIONS is empty (bootstrap test failed)' "[ -e \"$ASC_ACTIONS\" ]"
  assertFalse 'Global ASC_INC is empty (bootstrap test failed)' "[ -e \"$ASC_INC\" ]"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
