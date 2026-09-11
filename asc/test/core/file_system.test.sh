#!/usr/bin/env bash

##
# ASC core file system related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
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
# Update : removed (would require sudoing, not enforceable).
#
# test_asc_can_chown() {
#   local rtrn
#   chown 81:81 '_asc_dir_test/_asc_file_test.txt'
#   rtrn=$?
#   assertEquals 'Chown failed (returned non-zero code)' 0 $rtrn
# }

##
# f_fs_get_file_contents must load exact file bytes into a caller var.
#
test_f_fs_get_file_contents() {
  mkdir -p '_asc_dir_test'
  local f='_asc_dir_test/get_file_contents.txt'
  local got=''
  local expected=$'alpha\nbeta gamma\n'

  printf '%s' "$expected" > "$f"
  f_fs_get_file_contents "$f" 'got'
  assertEquals 'f_fs_get_file_contents should preserve contents.' "$expected" "$got"

  printf 'no-trailing-newline' > "$f"
  f_fs_get_file_contents "$f" 'got'
  assertEquals 'f_fs_get_file_contents should preserve missing final newline.' \
    'no-trailing-newline' "$got"

  assertFalse 'missing file should fail.' \
    "f_fs_get_file_contents '_asc_dir_test/missing.txt' 'got' 2>/dev/null"
}

##
# f_fs_relative_path must compute paths without forking dirname.
#
test_f_fs_relative_path() {
  relative_path=''
  f_fs_relative_path '/var/www/html/yetetets/testtset/fdsf.fd' '/var/www/html'
  assertEquals 'child under source' 'yetetets/testtset/fdsf.fd' "$relative_path"

  relative_path=''
  f_fs_relative_path '/' '/var/www/html'
  assertEquals 'root from nested source' '../../../' "$relative_path"

  relative_path=''
  f_fs_relative_path '/var/www/yetetets/testtset/fdsf.fd' '/opt/app'
  assertEquals 'sibling trees' '../../var/www/yetetets/testtset/fdsf.fd' "$relative_path"

  relative_path=''
  f_fs_relative_path 'data/db-dumps/foo.sql' '/project'
  assertEquals 'project-relative target' 'data/db-dumps/foo.sql' "$relative_path"
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
