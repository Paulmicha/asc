#!/usr/bin/env bash

##
# Smoke tests for asc/log/log.wrap.sh and asc/thread/thread.wrap.sh.
#
# @requires asc/vendor/shunit2
#
# @example
#   asc/test/asc/wrap.test.sh
#

. asc/bootstrap.sh

a_test_entry='make-list-entry-points'

oneTimeTearDown() {
  rm -f \
    "data/threads/${a_test_entry}.txt" \
    "data/threads/${a_test_entry}.sidecar.txt" \
    "data/threads/${a_test_entry}.pid" \
    "data/threads/${a_test_entry}.yml" \
    "data/logs/${a_test_entry}.txt" \
    "data/logs/${a_test_entry}.sidecar.txt"
}

test_wrap_rejects_invalid_entry() {
  local exit_code=0

  asc/thread/thread.wrap.sh '__not_a_make_entry__' >/dev/null 2>&1 || exit_code=$?

  assertEquals 'invalid entry point must abort' 1 "$exit_code"
}

test_thread_wrap_starts_debug() {
  local output=''
  local exit_code=0
  local a_yml="data/threads/${a_test_entry}.yml"

  rm -f "$a_yml" "data/threads/${a_test_entry}.pid"

  output="$(asc/thread/thread.wrap.sh "$a_test_entry" 2>&1)" || exit_code=$?

  # Allow supervisor to write / finalize YAML.
  sleep 0.2

  assertEquals 'thread wrap must succeed' 0 "$exit_code"
  assertTrue 'yaml record must exist' "[[ -f '$a_yml' ]]"
  assertTrue 'output mentions PID' "[[ '$output' == *'Thread started'* ]]"
  assertFalse 'thread output file must not exist' \
    "[[ -f 'data/threads/${a_test_entry}.txt' ]]"
  assertFalse 'legacy pid file must not exist' \
    "[[ -f 'data/threads/${a_test_entry}.pid' ]]"

  unset thread_tree_arr
  f_thread_yml_load "$a_test_entry"

  assertTrue 'owner must be set' "[[ -n '$thread_owner' ]]"
  assertTrue 'script must be absolute' "[[ '$thread_script' == /* ]]"
  assertTrue 'started_ms has fractional seconds' \
    "[[ '$thread_started_ms' == *.* ]]"
  assertTrue 'status is set' \
    "[[ '$thread_status' == 'running' || '$thread_status' == 'exited' ]]"
}

test_log_wrap_chains_thread_wrap() {
  local output=''
  local exit_code=0
  local a_yml="data/threads/${a_test_entry}.yml"

  rm -f \
    "data/logs/${a_test_entry}.txt" \
    "data/logs/${a_test_entry}.sidecar.txt" \
    "$a_yml"

  output="$(asc/log/log.wrap.sh asc/thread/thread.wrap.sh "$a_test_entry" 2>&1)" || exit_code=$?

  sleep 0.2

  assertEquals 'log wrap chain must succeed' 0 "$exit_code"
  assertTrue 'log sidecar must exist' \
    "[[ -f 'data/logs/${a_test_entry}.sidecar.txt' ]]"
  assertTrue 'log output must exist' \
    "[[ -f 'data/logs/${a_test_entry}.txt' ]]"
  assertTrue 'output mentions PID' "[[ '$output' == *'Log started'* ]]"
  assertTrue 'yaml record must exist' "[[ -f '$a_yml' ]]"
  assertFalse 'thread output file must not exist' \
    "[[ -f 'data/threads/${a_test_entry}.txt' ]]"
}

. asc/vendor/shunit2/shunit2
