#!/usr/bin/env bash

##
# ASC core test : test results archiving helpers.
#
# @requires asc/vendor/shunit2
#

. asc/bootstrap.sh
if [[ "$(type -t f_test_batch_exec)" != function ]]; then
  # shellcheck disable=SC1091
  . asc/test/test.opt-inc.sh
fi

test_results_self_tmp=''

oneTimeSetUp() {
  test_results_self_tmp="$(mktemp -d)"
  export ASC_TEST_RESULTS_ROOT="${test_results_self_tmp}/test-results"
  export ASC_TEST_RESULTS=1
}

oneTimeTearDown() {
  if [[ -n "$test_results_self_tmp" && -d "$test_results_self_tmp" ]]; then
    rm -rf "$test_results_self_tmp"
  fi
}

test_u_test_results_parse_shunit_suite() {
  local batch_dir capture suite_dir
  local tree_file

  batch_dir="${ASC_TEST_RESULTS_ROOT}/batch"
  mkdir -p "$batch_dir"
  capture="$(mktemp)"

  cat >"$capture" <<'EOF'
test_demo_one
line one

Ran 1 test.

OK
test_demo_two
assert failure

Ran 1 test.

FAILED (failures=1)
EOF

  f_test_results_batch_begin "$batch_dir" 0
  f_test_results_parse_shunit_suite 'demo' "$capture"
  f_test_results_batch_end 0

  assertTrue "missing case one output" \
    "[ -f '${ASC_TEST_RESULTS_ROOT}/frozen/batch.demo.test_demo_one.txt' ]"
  assertTrue "missing case two output" \
    "[ -f '${ASC_TEST_RESULTS_ROOT}/frozen/batch.demo.test_demo_two.txt' ]"

  tree_file="${ASC_TEST_RESULTS_ROOT}/test-batch.yml"
  assertTrue "missing tree file" "[ -f '${tree_file}' ]"
  grep -A5 '^demo:$' "$tree_file" | grep -q 'test_demo_one: PASS'
  assertEquals "case one should PASS" 0 "$?"
  grep -A5 '^demo:$' "$tree_file" | grep -q 'test_demo_two: FAIL'
  assertEquals "case two should FAIL" 0 "$?"

  rm -f "$capture"
}

##
# Feed one shunit2 capture and return the archived status of one case.
#
# @param $1 String : batch directory name.
# @param $2 String : capture body.
# @param $3 String : case name (test_*).
#
_u_archived_status() {
  local name="$1"
  local body="$2"
  local case_name="$3"
  local batch_dir capture tree_file line

  batch_dir="${ASC_TEST_RESULTS_ROOT}/${name}"
  mkdir -p "$batch_dir"
  capture="$(mktemp)"
  printf '%s\n' "$body" >"$capture"
  f_test_results_batch_begin "$batch_dir" 0
  f_test_results_parse_shunit_suite 'suite' "$capture"
  f_test_results_batch_end 0
  rm -f "$capture"

  tree_file="${ASC_TEST_RESULTS_ROOT}/test-${name}.yml"
  line="$(grep -E "^[[:space:]]+${case_name}: " "$tree_file" | head -n 1)"
  printf '%s' "${line##*: }"
}

##
# Single-function summaries archive PASS, SKIP, and FAIL.
# A mixed file does not mark the later function SKIP.
#
test_u_test_results_summary_status() {
  local green=$'\033[1;32m'
  local none=$'\033[0m'
  local yellow=$'\033[1;33m'
  local status=''

  status="$(_u_archived_status 'plain-ok' $'test_only\n\nRan 1 test.\n\nOK' 'test_only')"
  assertEquals 'plain OK archives PASS' 'PASS' "$status"

  status="$(_u_archived_status 'skipped' $'test_only\n\nRan 1 test.\n\nOK (skipped=1)' 'test_only')"
  assertEquals 'OK (skipped=1) archives SKIP' 'SKIP' "$status"

  status="$(_u_archived_status 'fail-only' $'test_only\n\nRan 1 test.\n\nFAILED (failures=1)' 'test_only')"
  assertEquals 'FAILED (failures=1) archives FAIL' 'FAIL' "$status"

  status="$(_u_archived_status 'fail-skip' $'test_only\n\nRan 1 test.\n\nFAILED (failures=1,skipped=1)' 'test_only')"
  assertEquals 'FAILED with skips archives FAIL' 'FAIL' "$status"

  status="$(_u_archived_status 'colored-skip' "$(printf 'test_only\n\nRan 1 test.\n\n%sOK%s (%sskipped=1%s)' "$green" "$none" "$yellow" "$none")" 'test_only')"
  assertEquals 'colored OK (skipped=1) archives SKIP' 'SKIP' "$status"

  status="$(_u_archived_status 'mixed' $'test_first_skipped\ntest_second_passed\nRan 2 tests.\nOK (skipped=1)' 'test_first_skipped')"
  assertEquals 'mixed first function stays the flush default PASS' 'PASS' "$status"

  status="$(_u_archived_status 'mixed' $'test_first_skipped\ntest_second_passed\nRan 2 tests.\nOK (skipped=1)' 'test_second_passed')"
  assertEquals 'mixed later function is not SKIP' 'PASS' "$status"
}

. asc/vendor/shunit2/shunit2
