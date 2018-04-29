#!/usr/bin/env bash

##
# ASC core global vars related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# @example
#   asc/test/asc/fsop.test.sh
#

. asc/bootstrap.sh

##
# TODO [wip] Does the initial agregation process work ?
#
test_asc_global_aggregate() {
  # assertTrue 'Directory missing (creation test failed)' "[ -d '_asc_dir_test' ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
# oneTimeTearDown() {
#   rm -fr '_asc_dir_test'
# }

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
