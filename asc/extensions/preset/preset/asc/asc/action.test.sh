#!/usr/bin/env bash

##
# {{ DOCBLOCK }}
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# @example
#   {{ ACTION_TEST_PATH }}
#

. asc/bootstrap.sh

{{ <ONE_TIME_SETUP> }}

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  {{ ONE_TIME_SETUP }}
}

{{ </ONE_TIME_SETUP> }}

{{ ACTION_TEST }}
