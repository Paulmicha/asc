#!/usr/bin/env bash

##
# ASC core test : test results archiving helpers.
#
# @requires asc/vendor/shunit2
#

. asc/bootstrap.sh

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

. asc/vendor/shunit2/shunit2
