#!/usr/bin/env bash

##
# ASC core generic utilities tests.
#
# TODO [wip] to complete for all ASC core utilities.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# @example
#   asc/test/asc/utilities.test.sh
#

. asc/bootstrap.sh

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  local f='data/asc/_tmphnc.txt'
  echo 'This is a test for ASC filesystem compression-related utilities.' > "$f"
}

##
# Basic string sanitizing test.
#
test_u_str_sanitize() {
  local sanitized_str
  local expected_output

  sanitized_str=''
  f_str_sanitize 'test space'
  expected_output='test-space'
  assertEquals 'u_str_sanitize() simple space test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  f_str_sanitize 'custom replacement: underscore' '_'
  expected_output='custom_replacement__underscore'
  assertEquals 'u_str_sanitize() custom replacement: underscore test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  f_str_sanitize 'custom replacement: empty string' ''
  expected_output='customreplacementemptystring'
  assertEquals 'u_str_sanitize() custom replacement: empty string test failed.' "$expected_output" "$sanitized_str"

  sanitized_str=''
  f_str_sanitize "test&special@chars#with|numbers^123~and[brackets]and\\backslashes\$and/slashes+plus quotes'single'and\"double\""
  expected_output='test-special-chars-with-numbers-123-and-brackets-and-backslashes-and-slashes-plus-quotes-single-and-double-'
  assertEquals 'u_str_sanitize() special chars test failed.' "$expected_output" "$sanitized_str"
}

##
# Var name sanitizing test.
#
test_u_str_sanitize_var_name() {
  local sanitized_var_name
  local expected_output

  sanitized_var_name=''
  f_str_sanitize_var_name 'the.var-name Test' 'sanitized_var_name'
  expected_output='the_var_name_Test'
  assertEquals 'u_str_sanitize_var_name() space test failed.' "$expected_output" "$sanitized_var_name"
}

##
# File compression test.
#
# TODO [wip] complete series with all arguments + using folder (not just file).
#
test_u_fs_compress_in_place() {
  f_fs_compress_in_place 'data/asc/_tmphnc.txt'
  assertTrue 'Failed to compress test file.' "[ -f 'data/asc/_tmphnc.txt.tgz' ]"
}

##
# Extraction test.
#
# TODO [wip] complete series with all arguments + using folder (not just file).
#
test_u_fs_extract_in_place() {
  # Delete existing result before attempting the test.
  if [[ -f 'data/asc/_tmphnc.txt' ]]; then
    rm 'data/asc/_tmphnc.txt'
  fi
  f_fs_extract_in_place 'data/asc/_tmphnc.txt.tgz'
  assertTrue 'Failed to extract test file.' "[ -f 'data/asc/_tmphnc.txt' ]"
}

##
# f_in_array / f_array_add_once (nameref + uniqueness).
#
test_f_in_array_and_add_once() {
  local my_array_arr=('test1' 'hello world' 'test3')

  assertTrue 'f_in_array should find an existing item.' \
    "f_in_array 'test1' my_array_arr"
  assertTrue 'f_in_array should match items containing spaces.' \
    "f_in_array 'hello world' my_array_arr"
  assertFalse 'f_in_array should miss absent items.' \
    "f_in_array 'missing' my_array_arr"

  f_array_add_once 'test1' my_array_arr
  f_array_add_once 'test4' my_array_arr
  f_array_add_once 'hello world' my_array_arr

  assertEquals 'f_array_add_once should keep length when item exists.' \
    '4' "${#my_array_arr[@]}"
  assertEquals 'f_array_add_once should append new items once.' \
    'test4' "${my_array_arr[3]}"
}

##
# f_array_qsort must terminate and sort values (lexicographic [[ < ]]).
#
test_f_array_qsort() {
  sorted_arr=()
  f_array_qsort a c b f 3 5
  assertEquals 'f_array_qsort length mismatch.' '6' "${#sorted_arr[@]}"
  assertEquals 'f_array_qsort[0]' '3' "${sorted_arr[0]}"
  assertEquals 'f_array_qsort[1]' '5' "${sorted_arr[1]}"
  assertEquals 'f_array_qsort[2]' 'a' "${sorted_arr[2]}"
  assertEquals 'f_array_qsort[3]' 'b' "${sorted_arr[3]}"
  assertEquals 'f_array_qsort[4]' 'c' "${sorted_arr[4]}"
  assertEquals 'f_array_qsort[5]' 'f' "${sorted_arr[5]}"

  sorted_arr=('stale')
  f_array_qsort
  assertEquals 'empty f_array_qsort should leave sorted_arr untouched.' \
    'stale' "${sorted_arr[0]}"
}

##
# f_array_reverse must reverse without losing space-containing items.
#
test_f_array_reverse() {
  reversed_arr=()
  f_array_reverse a 'b c' d
  assertEquals 'f_array_reverse length mismatch.' '3' "${#reversed_arr[@]}"
  assertEquals 'f_array_reverse[0]' 'd' "${reversed_arr[0]}"
  assertEquals 'f_array_reverse[1]' 'b c' "${reversed_arr[1]}"
  assertEquals 'f_array_reverse[2]' 'a' "${reversed_arr[2]}"

  reversed_arr=('stale')
  f_array_reverse
  assertEquals 'empty f_array_reverse should yield empty result.' \
    '0' "${#reversed_arr[@]}"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  if [[ -f 'data/asc/_tmphnc.txt' ]]; then
    rm 'data/asc/_tmphnc.txt'
  fi
  if [[ -f 'data/asc/_tmphnc.txt.tgz' ]]; then
    rm 'data/asc/_tmphnc.txt.tgz'
  fi
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
