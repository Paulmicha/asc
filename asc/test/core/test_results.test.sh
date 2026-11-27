#!/usr/bin/env bash

##
# ASC core test : isolated test result archive behavior.
#
# @requires asc/vendor/shunit2
#

. asc/bootstrap.sh
. asc/test/test.opt-inc.sh

test_results_self_root="$PWD"
test_results_self_tmp=''

oneTimeSetUp() {
  test_results_self_tmp="$(mktemp -d)"
  export ASC_TEST_RESULTS=1
}

setUp() {
  cd "$test_results_self_tmp" || exit 1
}

tearDown() {
  cd "$test_results_self_root" || exit 1
}

oneTimeTearDown() {
  cd "$test_results_self_root" || exit 1
  rm -rf "$test_results_self_tmp"
}

##
# Full and partial batches retain trusted results without basename collisions.
#
test_archive_partial_merge_and_distinct_batches() {
  local first second

  f_test_results_batch_begin 'asc/test/core' 0
  first="$test_results_slug"
  assertTrue 'batch output directory exists' "[ -f 'data/test/result/$first/output.txt' ]"
  f_test_results_tree_put 'demo' 'test_first' 'PASS'
  f_test_results_batch_end 0

  f_test_results_batch_begin 'asc/test/core' 1
  f_test_results_tree_put 'demo' 'test_second' 'FAIL'
  f_test_results_batch_end 1
  assertEquals 'partial keeps first' 'PASS' "$(f_test_results_case_status "$first" demo test_first)"
  assertEquals 'partial adds second' 'FAIL' "$(f_test_results_case_status "$first" demo test_second)"

  f_test_results_batch_begin 'asc/extensions/foo/test/core' 0
  second="$test_results_slug"
  f_test_results_tree_put 'demo' 'test_first' 'FAIL'
  f_test_results_batch_end 1
  assertNotEquals 'same basename has independent key' "$first" "$second"
  assertEquals 'first batch remains unchanged' 'PASS' "$(f_test_results_case_status "$first" demo test_first)"
  assertEquals 'second batch has its own result' 'FAIL' "$(f_test_results_case_status "$second" demo test_first)"
}

##
# Old summaries and frozen results cannot become trusted partial-run results.
#
test_archive_legacy_and_frozen_statuses_are_not_trusted() {
  local slug

  f_test_results_batch_begin 'fixtures/legacy' 0
  slug="$test_results_slug"
  mkdir -p 'data/test/frozen'
  printf 'demo:\n  test_old: PASS\n' > "data/test/result/$slug/summary.yml"
  printf 'demo.test_old PASS\n' > "data/test/frozen/$slug.txt"
  f_test_results_batch_begin 'fixtures/legacy' 1
  f_test_results_tree_put demo test_new PASS
  f_test_results_batch_end 0
  assertNotEquals 'legacy PASS must not survive as trusted' 'PASS' "$(f_test_results_case_status "$slug" demo test_old)"
  assertEquals 'new result is trusted' 'PASS' "$(f_test_results_case_status "$slug" demo test_new)"
  assertFalse 'regeneration removes frozen fallback' "[ -f 'data/test/frozen/$slug.txt' ]"

  f_test_results_batch_begin 'fixtures/legacy' 1
  f_test_results_tree_put demo test_later FAIL
  f_test_results_batch_end 1
  assertEquals 'later partial retains valid result' 'PASS' "$(f_test_results_case_status "$slug" demo test_new)"
}

##
# Real shUnit2 captures attribute failures and leave mixed skips unknown.
#
test_archive_real_mixed_suites() {
  local slug suite_test="test_"
  mkdir -p fixtures
  cat > fixtures/mixed.test.sh <<SUITE
#!/usr/bin/env bash
${suite_test}first() { assertEquals 1 2; }
${suite_test}second() { assertEquals 1 1; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  chmod +x fixtures/mixed.test.sh
  f_test_results_batch_begin fixtures 0
  slug="$test_results_slug"
  f_test_file_exec fixtures/mixed.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 1
  assertEquals 'first failing assertion belongs to first case' 'FAIL' "$(f_test_results_case_status "$slug" mixed test_first)"
  assertEquals 'second passing case is not aggregate failure' 'PASS' "$(f_test_results_case_status "$slug" mixed test_second)"

  cat > fixtures/mixed.test.sh <<SUITE
#!/usr/bin/env bash
${suite_test}first() { assertEquals 1 1; }
${suite_test}second() { assertEquals 1 2; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  f_test_results_batch_begin fixtures 0
  f_test_file_exec fixtures/mixed.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 1
  assertEquals 'first passing case' 'PASS' "$(f_test_results_case_status "$slug" mixed test_first)"
  assertEquals 'second failing case' 'FAIL' "$(f_test_results_case_status "$slug" mixed test_second)"

  cat > fixtures/mixed.test.sh <<SUITE
#!/usr/bin/env bash
${suite_test}first() { startSkipping; assertEquals 1 1; }
${suite_test}second() { assertEquals 1 1; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  f_test_results_batch_begin fixtures 0
  f_test_file_exec fixtures/mixed.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 0
  assertEquals 'first case records its own skip' 'SKIP' "$(f_test_results_case_status "$slug" mixed test_first)"
  assertEquals 'second case records its own pass' 'PASS' "$(f_test_results_case_status "$slug" mixed test_second)"
}

##
# A later setup failure must not be attributed to the preceding case.
#
test_archive_setup_failure_is_not_misattributed() {
  local slug suite_test="test_"

  mkdir -p fixtures
  cat > fixtures/setup.test.sh <<SUITE
#!/usr/bin/env bash
setUp() { count=\$((\${count:-0} + 1)); if [[ \$count -eq 2 ]]; then assertEquals 1 2; fi; }
${suite_test}first() { assertEquals 1 1; }
${suite_test}second() { assertEquals 1 1; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  chmod +x fixtures/setup.test.sh
  f_test_results_batch_begin fixtures 0
  slug="$test_results_slug"
  f_test_file_exec fixtures/setup.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 1
  assertEquals 'first case passes before later setup fails' 'PASS' "$(f_test_results_case_status "$slug" setup test_first)"
  assertEquals 'second case includes its setup failure' 'FAIL' "$(f_test_results_case_status "$slug" setup test_second)"
}

##
# A legacy capture has no case-level skip evidence.
#
test_archive_unmarked_capture_is_unknown() {
  local slug

  mkdir -p fixtures
  printf 'test_first\n__ASC_CASE_END__ 42 test_first 0 0 1\ntest_second\nRan 2 tests.\nOK (skipped=1)\n__ASC_CASE_BEGIN__ 42 test_third\n' > fixtures/legacy.capture
  f_test_results_batch_begin fixtures 0
  slug="$test_results_slug"
  f_test_results_parse_shunit_suite legacy fixtures/legacy.capture
  f_test_results_batch_end 0
  assertEquals 'first unmarked case is unknown' 'UNKNOWN' "$(f_test_results_case_status "$slug" legacy test_first)"
  assertEquals 'second unmarked case is unknown' 'UNKNOWN' "$(f_test_results_case_status "$slug" legacy test_second)"
  assertEquals 'incomplete marked case is unknown' 'UNKNOWN' "$(f_test_results_case_status "$slug" legacy test_third)"
}

##
# Nested test runners cannot close or replace the enclosing case boundary.
#
test_archive_nested_runner_keeps_outer_case() {
  local slug suite_test="test_"

  mkdir -p fixtures
  cat > fixtures/nested.sh <<SUITE
#!/usr/bin/env bash
${suite_test}inner() { assertEquals 1 1; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  chmod +x fixtures/nested.sh
  cat > fixtures/outer.test.sh <<SUITE
#!/usr/bin/env bash
${suite_test}outer() { bash fixtures/nested.sh; assertEquals 1 1; }
. '$test_results_self_root/asc/vendor/shunit2/shunit2'
SUITE
  chmod +x fixtures/outer.test.sh
  f_test_results_batch_begin fixtures 0
  slug="$test_results_slug"
  f_test_file_exec fixtures/outer.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 0
  assertEquals 'outer case has its own complete evidence' 'PASS' "$(f_test_results_case_status "$slug" outer test_outer)"
}

##
# Suite names containing punctuation survive a partial archive merge.
#
test_archive_suite_names_round_trip() {
  local slug

  f_test_results_batch_begin 'fixtures/names' 0
  slug="$test_results_slug"
  f_test_results_tree_put 'foo-bar' 'test_first' 'PASS'
  f_test_results_tree_put 'foo.bar' 'test_first' 'FAIL'
  f_test_results_batch_end 1
  assertEquals 'hyphenated suite is readable' 'PASS' "$(f_test_results_case_status "$slug" foo-bar test_first)"
  assertEquals 'dotted suite is readable' 'FAIL' "$(f_test_results_case_status "$slug" foo.bar test_first)"

  f_test_results_batch_begin 'fixtures/names' 1
  f_test_results_tree_put 'new' 'test_second' 'PASS'
  f_test_results_batch_end 0
  assertEquals 'hyphenated suite survives merge' 'PASS' "$(f_test_results_case_status "$slug" foo-bar test_first)"
  assertEquals 'dotted suite survives merge' 'FAIL' "$(f_test_results_case_status "$slug" foo.bar test_first)"
}

##
# An unwritable summary must fail without deleting the frozen fallback.
#
test_archive_summary_write_failure_preserves_frozen() {
  local slug rc=0

  f_test_results_batch_begin 'fixtures/write-failure' 0
  slug="$test_results_slug"
  mkdir -p "data/test/result/$slug/summary.yml" 'data/test/frozen'
  printf 'previous frozen result\n' > "data/test/frozen/$slug.txt"
  f_test_results_tree_put demo test_one PASS
  f_test_results_batch_end 0 2>/dev/null || rc=$?
  assertNotEquals 'failed summary write returns nonzero' 0 "$rc"
  assertTrue 'frozen fallback survives failed write' "[ -f 'data/test/frozen/$slug.txt' ]"
}

##
# A failed rerun cannot leave old PASS results for that suite in the summary.
#
test_archive_failed_partial_invalidates_attempted_suite() {
  local slug

  mkdir -p fixtures
  f_test_results_batch_begin fixtures 0
  slug="$test_results_slug"
  f_test_results_tree_put 'example' test_old PASS
  f_test_results_tree_put 'example.other' test_keep PASS
  f_test_results_batch_end 0
  printf '#!/usr/bin/env bash\nexit 7\n' > fixtures/example.test.sh
  chmod +x fixtures/example.test.sh

  f_test_results_batch_begin fixtures 1
  f_test_file_exec fixtures/example.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 7
  assertNotEquals 'attempted suite cannot retain prior PASS' 'PASS' "$(f_test_results_case_status "$slug" example test_old)"
  assertEquals 'other suite remains valid' 'PASS' "$(f_test_results_case_status "$slug" example.other test_keep)"

  printf '#!/usr/bin/env bash\nprintf "__ASC_CASE_BEGIN__ %%s test_new\\n" "$$"\nexit 7\n' > fixtures/example.test.sh
  f_test_results_batch_begin fixtures 1
  f_test_file_exec fixtures/example.test.sh >/dev/null 2>&1 || :
  f_test_results_batch_end 7
  assertEquals 'incomplete rerun remains unknown' 'UNKNOWN' "$(f_test_results_case_status "$slug" example test_new)"
  assertEquals 'unattempted suite still remains valid' 'PASS' "$(f_test_results_case_status "$slug" example.other test_keep)"
}

##
# Archive output errors must stop the batch rather than report success.
#
test_archive_output_write_failures_propagate() {
  local slug status
  slug="blocked-$(printf '%s' fixtures/blocked | sha256sum | cut -d' ' -f1)"
  mkdir -p "data/test/result/$slug/output.txt"
  f_test_results_batch_begin fixtures/blocked 0 2>/dev/null
  status=$?
  assertNotEquals 'batch start fails when output cannot be opened' 0 "$status"

  f_test_results_batch_begin fixtures/write_failure 0 || fail 'cannot initialize archive fixture'
  mkdir -p "data/test/result/$test_results_slug/example.test_case.txt"
  f_test_results_flush_case example test_case output PASS 2>/dev/null
  status=$?
  assertNotEquals 'case capture failure propagates' 0 "$status"

  mkdir -p fixtures/write_failure
  printf '#!/usr/bin/env bash\nprintf "output\\n"\n' > fixtures/write_failure/example.test.sh
  chmod +x fixtures/write_failure/example.test.sh
  rm "data/test/result/$test_results_slug/output.txt"
  mkdir "data/test/result/$test_results_slug/output.txt"
  f_test_file_exec fixtures/write_failure/example.test.sh >/dev/null 2>&1
  status=$?
  assertNotEquals 'batch output capture failure propagates' 0 "$status"
}

. asc/vendor/shunit2/shunit2
