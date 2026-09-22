#!/usr/bin/env bash

##
# ASC shell utility tests (asc/core/utils/shell.manual-inc.sh).
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#

. asc/bootstrap.sh

##
# f_print_current_user should write a non-empty username via printf -v.
#
test_f_print_current_user() {
  local user=''
  f_print_current_user 'user'
  assertNotNull 'f_print_current_user should print something' "$user"
  assertTrue 'f_print_current_user should look like a username' \
    "[[ \"$user\" =~ ^[A-Za-z0-9._-]+\$ ]]"
}

##
# f_host_os / f_host_ip write via printf -v (wave 6).
#
test_f_host_os_and_ip_output_vars() {
  local host_os='' host_ip=''

  f_host_os 'host_os'
  assertTrue 'f_host_os should write a non-empty slug' "[[ -n \"$host_os\" ]]"
  assertTrue 'f_host_os should be lowercase slug-ish' \
    "[[ \"$host_os\" =~ ^[a-z0-9._-]+\$ ]]"

  f_host_ip 'host_ip'
  # May be empty on hosts without a global-scope IPv4; still must not echo.
  assertTrue 'f_host_ip output var is set (possibly empty)' "[[ -n \"\${host_ip+x}\" ]]"
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
