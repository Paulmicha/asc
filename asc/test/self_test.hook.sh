#!/usr/bin/env bash

##
# Implements hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'.
#
# Runs ASC core tests (checks ASC itself). Verifies that the generic ASC
# functions can successfully run on current host.
#
# @requires running the tests with the same user that will use ASC.
#
# @example
#   asc/test/self_test.sh
#

u_fs_file_list asc/test/asc '*.test.sh'

for test_script in $file_list; do
  echo "# Executing ASC core $test_script ..."

  # Execute shunit2 test case.
  # See https://github.com/kward/shunit2
  asc/test/asc/$test_script

  # Do not carry on if a test failed in current test case.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "The test case '$test_script' did not pass" >&2
    echo "-> aborting (see details above)." >&2
    echo >&2
    echo "# Executing ASC core $test_script : done."
    echo
    break
  fi

  echo "# Executing ASC core $test_script : done."
  echo
done
