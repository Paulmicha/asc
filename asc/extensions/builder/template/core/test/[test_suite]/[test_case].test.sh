#!/usr/bin/env bash

##
# C
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see {{ path }}/test/{{ test_suite }}.sh
#
# @example
#   {{ examples }}
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
