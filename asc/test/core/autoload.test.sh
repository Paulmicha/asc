#!/usr/bin/env bash

##
# ASC core autoload helper tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# @example
#   asc/test/core/autoload.test.sh
#

. asc/bootstrap.sh

##
# f_autoload_item_split_version: name vs name-version.
#
test_f_autoload_item_split_version() {
  local parts_arr=()

  f_autoload_item_split_version parts_arr 'app_test_a-name-test-1.2'
  assertEquals 'versioned name' 'app_test_a-name-test' "${parts_arr[0]}"
  assertEquals 'versioned version' '1.2' "${parts_arr[1]}"
  assertEquals 'versioned length' '2' "${#parts_arr[@]}"

  parts_arr=()
  f_autoload_item_split_version parts_arr 'compose.dev'
  assertEquals 'no-version single element' 'compose.dev' "${parts_arr[0]}"
  assertEquals 'no-version length' '1' "${#parts_arr[@]}"

  parts_arr=()
  f_autoload_item_split_version parts_arr 'lib-1.2.3'
  assertEquals 'multi-dot name' 'lib' "${parts_arr[0]}"
  assertEquals 'multi-dot version' '1.2.3' "${parts_arr[1]}"

  # Characters that break eval-based array writes must still round-trip.
  parts_arr=()
  f_autoload_item_split_version parts_arr 'foo"bar-1.0'
  assertEquals 'quoted name survives' 'foo"bar' "${parts_arr[0]}"
  assertEquals 'quoted version survives' '1.0' "${parts_arr[1]}"
}

##
# f_autoload_add_lookup_level: plain + versioned path expansion.
#
test_f_autoload_add_lookup_level() {
  local lookup_paths_arr=()

  f_autoload_add_lookup_level 'asc/test/init.' 'hook.sh' 'compose' lookup_paths_arr
  assertEquals 'plain path' 'asc/test/init.compose.hook.sh' "${lookup_paths_arr[0]}"
  assertEquals 'plain count' '1' "${#lookup_paths_arr[@]}"

  lookup_paths_arr=()
  f_autoload_add_lookup_level 'asc/test/init.' 'hook.sh' 'app-1.2' lookup_paths_arr
  assertTrue 'versioned base without number' \
    "[[ \" \${lookup_paths_arr[*]} \" == *\" asc/test/init.app.hook.sh \"* ]]"
  assertTrue 'versioned 1' \
    "[[ \" \${lookup_paths_arr[*]} \" == *\" asc/test/init.app-1.hook.sh \"* ]]"
  assertTrue 'versioned 1.2' \
    "[[ \" \${lookup_paths_arr[*]} \" == *\" asc/test/init.app-1.2.hook.sh \"* ]]"

  lookup_paths_arr=()
  f_autoload_add_lookup_level 'asc/test/init.' 'hook.sh' 'compose' lookup_paths_arr
  f_autoload_add_lookup_level 'asc/test/init.' 'hook.sh' 'compose' lookup_paths_arr
  assertEquals 'add_once dedupes' '1' "${#lookup_paths_arr[@]}"
}

##
# f_autoload_print_lookup_paths must keep path components intact (no word-split).
#
test_f_autoload_print_lookup_paths() {
  local tmpdir
  local spaced
  local other
  local paths_arr
  local out

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/asc-autoload.XXXXXX")"
  spaced="$tmpdir/my file.txt"
  other="$tmpdir/other.txt"
  touch "$spaced" "$other"
  paths_arr=("$spaced" "$other")

  out="$(f_autoload_print_lookup_paths paths_arr 'Space test')"

  assertTrue 'title present' "[[ \"$out\" == *\"Space test lookup paths :\"* ]]"
  assertTrue 'spaced path intact' "[[ \"$out\" == *\"$spaced\"* ]]"
  assertTrue 'spaced path marked exists' \
    "[[ \"$out\" == *\"$spaced\"*$'\n'*\"  exists\"* ]]"
  assertTrue 'other path present' "[[ \"$out\" == *\"$other\"* ]]"

  rm -rf "$tmpdir"
}

. asc/vendor/shunit2/shunit2
