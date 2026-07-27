#!/usr/bin/env bash

##
# {{ docblock }}
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# @example
#   {{ ACTION_TEST_PATH }}
#

. asc/bootstrap.sh

<asc-if not-empty="one_time_setup">

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  {{ one_time_setup }}
}

</asc-if>

{{ slot }}
