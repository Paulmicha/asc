#!/usr/bin/env bash

##
# ASC shell utility tests (asc/utils/shell.inc.sh).
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#

. asc/bootstrap.sh

##
# f_print_current_user should return a non-empty username.
#
test_f_print_current_user() {
  local user
  user="$(f_print_current_user)"
  assertNotNull 'f_print_current_user should print something' "$user"
  assertTrue 'f_print_current_user should look like a username' \
    "[[ \"$user\" =~ ^[A-Za-z0-9._-]+\$ ]]"
}

##
# i_am_su reflects whether the effective user is root.
#
test_i_am_su() {
  if [[ "$(id -u)" -eq 0 ]]; then
    assertTrue 'root should satisfy i_am_su' 'i_am_su'
  else
    assertFalse 'non-root should not satisfy i_am_su' 'i_am_su'
  fi
}

##
# wait_for should succeed quickly when the command is already true.
#
test_wait_for() {
  local output
  output="$(wait_for 'shunit-ready' 'true' 3 0 0)"
  assertTrue 'wait_for should report started' \
    "[[ \"$output\" == *'has started'* ]]"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
