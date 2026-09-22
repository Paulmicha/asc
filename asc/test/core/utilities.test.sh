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
. asc/core/utils/fs_compression.manual-inc.sh
. asc/core/utils/str_slug.manual-inc.sh

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
# f_str_split1 must fill a caller array (incl. empty segments / spaces).
#
test_f_str_split1() {
  local parts_arr=()

  f_str_split1 'parts_arr' 'one,two three,four' ','
  assertEquals 'f_str_split1 length mismatch.' '3' "${#parts_arr[@]}"
  assertEquals 'f_str_split1[0]' 'one' "${parts_arr[0]}"
  assertEquals 'f_str_split1[1]' 'two three' "${parts_arr[1]}"
  assertEquals 'f_str_split1[2]' 'four' "${parts_arr[2]}"

  f_str_split1 'parts_arr' 'a,,b' ','
  assertEquals 'f_str_split1 empty-segment length.' '3' "${#parts_arr[@]}"
  assertEquals 'f_str_split1 empty middle.' '' "${parts_arr[1]}"
}

##
# f_str_convert_tokens must resolve nested token values.
#
test_f_str_convert_tokens_nested() {
  local USER_NAME='paul'
  local NESTED_PATTERN='{{ USER_NAME }}-db'
  local DUMP_PATTERN='backup-{{ NESTED_PATTERN }}.sql'
  local dump_pattern=''

  f_str_convert_tokens DUMP_PATTERN 'dump_pattern'
  assertEquals 'nested tokens should fully resolve.' \
    'backup-paul-db.sql' "$dump_pattern"
}

##
# f_str_convert_tokens must expand date-format tokens (strftime / printf %()T).
#
test_f_str_convert_tokens_datestamp() {
  local DB_ID='site'
  local DUMP_FILE_EXTENSION='sql'
  local ASC_DB_DUMPS_LOCAL_PATTERN='{{ %Y-%m-%d.%H-%M-%S }}_local-{{ DB_ID }}.{{ DUMP_FILE_EXTENSION }}'
  local dump_pattern=''
  local before after

  # Same formatter as f_str_convert_tokens; allow either second if the clock ticks.
  printf -v before '%(%Y-%m-%d.%H-%M-%S)T' -1
  f_str_convert_tokens ASC_DB_DUMPS_LOCAL_PATTERN 'dump_pattern'
  printf -v after '%(%Y-%m-%d.%H-%M-%S)T' -1

  assertTrue 'datestamp token should match YYYY-mm-dd.HH-MM-SS_local-site.sql' \
    "[[ \"$dump_pattern\" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\\.[0-9]{2}-[0-9]{2}-[0-9]{2}_local-site\\.sql\$ ]]"

  assertTrue 'datestamp should match current time (before or after call).' \
    "[[ \"$dump_pattern\" == \"${before}_local-site.sql\" || \"$dump_pattern\" == \"${after}_local-site.sql\" ]]"
}

##
# Case / join / escape / append helpers.
#
test_f_str_case_join_escape_append() {
  local lowercase='' uppercase='' joined_str='' escaped_arg='' sed_escaped='' str_append_once=''

  f_str_lowercase 'AbC_X'
  assertEquals 'f_str_lowercase' 'abc_x' "$lowercase"

  f_str_uppercase 'AbC_X' 'uppercase'
  assertEquals 'f_str_uppercase' 'ABC_X' "$uppercase"

  f_str_join '|' one 'two three' four
  assertEquals 'f_str_join' 'one|two three|four' "$joined_str"

  f_str_escape_single_quotes "it's a test" 'escaped_arg'
  assertEquals 'f_str_escape_single_quotes' "'it'\"'\"'s a test'" "$escaped_arg"

  f_str_sed_escape 'a,b.c*/d' 'sed_escaped'
  assertEquals 'f_str_sed_escape' 'a\,b\.c\*\/d' "$sed_escaped"

  f_str_append_once '--B' 'Foo--A' 'str_append_once'
  assertEquals 'f_str_append_once first' 'Foo--A--B' "$str_append_once"
  f_str_append_once '--B' "$str_append_once" 'str_append_once'
  assertEquals 'f_str_append_once idempotent' 'Foo--A--B' "$str_append_once"
}

##
# Slug/snake/transliterate must not load from kernel `str.manual-inc.sh` (nested
# bootstrap). Callers source `asc/core/utils/str_slug.manual-inc.sh`. `f_str_random` stays eager
# (global.vars / drupalwt hash salt).
# @see changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md
#
test_f_str_slug_helpers_absent_from_kernel_bootstrap() {
  local out
  out="$(bash -c '. asc/bootstrap.sh
printf "%s" "$(type -t f_str_slug)"
printf " %s" "$(type -t f_str_snake)"
printf " %s" "$(type -t f_transliterate_char)"
printf " %s" "$(type -t f_str_random)"')"
  assertEquals 'slug/snake/transliterate unset; random still eager' \
    '   function' "$out"

  out="$(bash -c '. asc/bootstrap.sh
. asc/core/utils/str_slug.manual-inc.sh
printf "%s" "$(type -t f_str_slug)"
printf " %s" "$(type -t f_str_snake)"
printf " %s" "$(type -t f_transliterate_char)"')"
  assertEquals 'slug/snake/transliterate exist after opt-inc' \
    'function function function' "$out"
}

##
# Subsequences, slug/snake, transliterate, random.
#
test_f_str_subsequences_slug_random() {
  local str_subsequences='' slug_val='' snake_val='' transliterated_char=''
  local rnd rnd2

  f_str_subsequences 'a b c'
  assertEquals 'f_str_subsequences' 'a ab abc ac b bc c ' "$str_subsequences"

  f_transliterate_char 'É'
  assertEquals 'f_transliterate_char É' 'e' "$transliterated_char"
  f_transliterate_char '~'
  assertEquals 'f_transliterate_char ~' '' "$transliterated_char"

  f_str_slug 'Hello, Été!'
  assertEquals 'f_str_slug' 'hello-ete' "$slug_val"

  f_str_snake 'Hello, Été!'
  assertEquals 'f_str_snake' 'hello_ete' "$snake_val"

  rnd="$(f_str_random 12)"
  assertEquals 'f_str_random length' '12' "${#rnd}"
  assertTrue 'f_str_random charset' "[[ \"$rnd\" =~ ^[A-Za-z0-9]+\$ ]]"
  rnd2="$(f_str_random 12)"
  # Extremely unlikely to collide; still a weak uniqueness smoke check.
  assertNotEquals 'f_str_random should vary' "$rnd" "$rnd2"
}

##
# Basic-auth encoder with explicit registry seed (avoids random path).
#
test_f_str_basic_auth_credentials() {
  local key="shunit_basic_auth_$$"
  local creds

  f_instance_registry_set "$key" 'alice:s3cret'
  creds="$(f_str_basic_auth_credentials "$key")"
  assertTrue 'basic auth should start with alice:' "[[ \"$creds\" == alice:* ]]"
  assertNotEquals 'basic auth should include a hash suffix' 'alice:' "$creds"
}

##
# Output-var paths for waves 1–3 migrated scalars (no caller capture).
# @see changelog/2026/07/31-subshell-printf-v-candidates.md
#
test_f_migrated_scalar_output_vars() {
  local software_scalar='' cron_scalar='' test_results_root='' out=''

  # shellcheck disable=SC1091
  . asc/extensions/software/host/provision.opt-inc.sh
  # shellcheck disable=SC1091
  . asc/extensions/crontab/crontab.inc.sh
  if [[ "$(type -t f_test_results_root)" != function ]]; then
    # shellcheck disable=SC1091
    . asc/test/test.opt-inc.sh
  fi

  f_software_scalar '"quoted"' 'out'
  assertEquals 'f_software_scalar strips double quotes' 'quoted' "$out"
  f_software_scalar "'quoted'"
  assertEquals 'f_software_scalar default var' 'quoted' "$software_scalar"

  f_cron_scalar '  spaced  ' 'out'
  assertEquals 'f_cron_scalar trims' 'spaced' "$out"
  f_cron_scalar '"cron"'
  assertEquals 'f_cron_scalar default var' 'cron' "$cron_scalar"

  ASC_TEST_RESULTS_ROOT='/tmp/asc-test-results-fixture' f_test_results_root 'out'
  assertEquals 'f_test_results_root honors env' '/tmp/asc-test-results-fixture' "$out"
  unset ASC_TEST_RESULTS_ROOT
  f_test_results_root
  assertEquals 'f_test_results_root default path' 'data/test-results' "$test_results_root"
}

##
# Wave 4: software status enums write via printf -v.
# @see changelog/2026/07/31-subshell-printf-v-candidates.md
#
test_f_software_status_output_vars() {
  local st='' software_ensure_status='' dir

  # shellcheck disable=SC1091
  . asc/extensions/software/host/provision.opt-inc.sh

  f_software_ensure_status 'bash' 'st'
  assertEquals 'ensure bash is ok' 'ok' "$st"
  f_software_ensure_status 'asc-no-such-cmd-$$'
  assertEquals 'ensure missing default var' 'missing' "$software_ensure_status"

  dir="$(mktemp -d)"
  f_software_tarball_status "$dir" '1.0' 'bin' 'st'
  assertEquals 'tarball missing without binary' 'missing' "$st"
  printf 'x' > "${dir}/bin"
  chmod +x "${dir}/bin"
  f_software_tarball_status "$dir" '1.0' 'bin' 'st'
  assertEquals 'tarball ok without marker' 'ok' "$st"
  printf '1.0' > "${dir}/.asc-software-version"
  f_software_tarball_status "$dir" '1.0' 'bin' 'st'
  assertEquals 'tarball ok with matching marker' 'ok' "$st"
  f_software_tarball_status "$dir" '2.0' 'bin' 'st'
  assertEquals 'tarball outdated on version mismatch' 'outdated' "$st"
  rm -rf "$dir"

  f_software_appimage_status '/no/such/app.AppImage' '' 'st'
  assertEquals 'appimage missing' 'missing' "$st"

  f_software_unit_status 'asc-no-such-unit-$$' 'st'
  assertEquals 'unit missing' 'missing' "$st"
}

##
# Waves 7–8: git staged-files + test case helpers via printf -v.
# @see changelog/2026/07/31-subshell-printf-v-candidates.md
#
test_f_git_and_test_helper_output_vars() {
  local staged='unset' suffix='' target='' runner='' batch_dir=''

  if [[ "$(type -t f_git_get_staged_files)" != function ]]; then
    # shellcheck disable=SC1091
    . asc/git/git.opt-inc.sh
  fi
  if [[ "$(type -t f_test_case_make_target)" != function ]]; then
    # shellcheck disable=SC1091
    . asc/test/test.opt-inc.sh
  fi

  f_git_get_staged_files "$PROJECT_DOCROOT" '' 'staged'
  assertTrue 'f_git_get_staged_files sets output var' "[[ \"\$staged\" != 'unset' ]]"

  f_test_case_stem_to_suffix 'search_results' 'suffix'
  assertEquals 'stem to suffix' 'search-results' "$suffix"
  f_test_case_make_target 'test-browser' 'impersonation' 'target'
  assertEquals 'make target' 'test-browser-impersonation' "$target"
  f_test_case_runner_path 'asc/test/core' 'runner'
  assertEquals 'runner path' 'asc/test/core.case.sh' "$runner"
  f_test_batch_dir_from_script 'asc/test/core.sh' 'batch_dir'
  assertEquals 'batch dir from script' 'asc/test/core' "$batch_dir"
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
