#!/usr/bin/env bash

##
# ASC core file system permissions-related tests.
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
# Can ASC create directories in current dir ?
#
# @evol see asc/vendor/shunit2/examples/mkdir_test.sh
#
test_asc_can_create_dir() {
  mkdir '_asc_dir_test'
  assertTrue 'Directory missing (creation test failed)' "[ -d '_asc_dir_test' ]"
}

##
# Can ASC change permissions ?
#
test_asc_can_chmod() {
  local rtrn
  chmod 700 '_asc_dir_test'
  rtrn=$?
  assertEquals 'Chmod failed (returned non-zero code)' 0 $rtrn
}

##
# Can ASC create files in current dir ?
#
test_asc_can_create_file() {
  touch '_asc_dir_test/_asc_file_test.txt'
  assertTrue 'File missing (creation test failed)' "[ -f '_asc_dir_test/_asc_file_test.txt' ]"
}

##
# Can ASC change ownership ?
#
test_asc_can_chown() {
  local rtrn
  chown 81:81 '_asc_dir_test/_asc_file_test.txt'
  rtrn=$?
  assertEquals 'Chown failed (returned non-zero code)' 0 $rtrn
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  rm -fr '_asc_dir_test'
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
