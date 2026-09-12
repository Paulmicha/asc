#!/usr/bin/env bash

##
# ASC core global vars related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# List of acronyms used (must not collide) :
# - nftascgevhnc = name for testing ASC global env vars hopefully not colliding
# - nftascgevdehnc = name for testing ASC global env vars dummy extension hopefully not colliding
#
# TODO test the different globals keys.
# @see global() in asc/utilities/global.sh
#
# @example
#   asc/test/asc/global.test.sh
#

. asc/bootstrap.sh
. asc/test/test.inc.sh

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  local s
  local s_upper

  # Hook dry-run results are cached at init/warmup; clear those before creating
  # temporary global.vars.sh files so f_global_lookup_paths can see them.
  # @see hook() in asc/utilities/hook.sh
  rm -f data/asc/cache/hook/*global*vars*

  for s in $ASC_SUBJECTS; do
    # Skip subjects whose folder is not a normal subject namespace (bootstrap
    # phases live under asc/bootstrap/ without being a hook subject dir).
    case "$s" in bootstrap) continue ;; esac
    f_str_uppercase "$s" 's_upper'
    cat > "asc/$s/global.vars.sh" <<EOF
#!/usr/bin/env bash
global NFTASCGEVHNC_VAR_ASC_$s_upper 'test'
EOF

    # Failsafe : cannot carry on if touch did not complete without error.
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing ASC globals." >&2
      echo "-> aborting" >&2
      echo >&2
      exit 2
    fi
  done

  # Also test with a dummy extension (requires bootstrap reload, see below).
  # Failsafe : cannot carry on without an existing ASC extensions dir.
  if [[ ! -d "asc/extensions" ]]; then
    echo >&2
    echo "Error (3) in $BASH_SOURCE line $LINENO: ASC extensions dir does not exist." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 3
  fi

  mkdir -p "asc/extensions/nftascgevdehnc/instance"

  # Failsafe : cannot carry on without successful temporary extension dir creation.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing ASC globals." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  cat > "asc/extensions/nftascgevdehnc/global.vars.sh" <<'EOF'
#!/usr/bin/env bash
global NFTASCGEVHNC_VAR_1 'test'
EOF

  cat > "asc/extensions/nftascgevdehnc/instance/global.vars.sh" <<'EOF'
#!/usr/bin/env bash
global NFTASCGEVHNC_EXT_INSTANCE_VAR_1 'test'
EOF

  # Forces detection of our newly created temporary extension.
  f_asc_extend
}

##
# Does the initial aggregation process work ?
#
test_asc_global_aggregate() {
  local global_lookup_paths=''
  local p_ascii_dry_run=1
  local p_ascii_yes=1
  local test_asc_global_aggregate=1

  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()
  GLOBALS_DRY_RUN=0

  f_global_aggregate
  # f_global_debug

  local s
  local s_upper
  local s_varname
  for s in $ASC_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    f_str_uppercase "$s" 's_upper'
    s_varname="NFTASCGEVHNC_VAR_ASC_${s_upper}"
    assertEquals "Value of NFTASCGEVHNC_VAR_ASC_$s_upper is missing or incorrect." "test" "${!s_varname}"
  done

  assertEquals 'Value of NFTASCGEVHNC_VAR_1 is missing or incorrect.' "test" "$NFTASCGEVHNC_VAR_1"
  assertEquals 'Value of NFTASCGEVHNC_EXT_INSTANCE_VAR_1 is missing or incorrect.' "test" "$NFTASCGEVHNC_EXT_INSTANCE_VAR_1"
}

##
# f_global_lookup_paths must include subject + extension global.vars.sh files.
#
test_f_global_lookup_paths() {
  local global_lookup_paths=''
  local s
  local found_subject=0

  f_global_lookup_paths

  assertTrue 'lookup paths should be non-empty' "[[ -n \"$global_lookup_paths\" ]]"

  for s in $ASC_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    assertTrue "should list asc/$s/global.vars.sh" \
      "[[ \" \$global_lookup_paths \" == *\" asc/$s/global.vars.sh \"* ]]"
    found_subject=1
    break
  done
  assertTrue 'at least one subject global.vars.sh should be checked' \
    "[[ $found_subject -eq 1 ]]"

  assertTrue 'should list dummy extension root global.vars.sh' \
    "[[ \" \$global_lookup_paths \" == *\" asc/extensions/nftascgevdehnc/global.vars.sh \"* ]]"
  assertTrue 'should list dummy extension instance global.vars.sh' \
    "[[ \" \$global_lookup_paths \" == *\" asc/extensions/nftascgevdehnc/instance/global.vars.sh \"* ]]"
}

##
# f_global_list must fill parallel name/value arrays from aggregated globals.
#
test_f_global_list() {
  local p_ascii_dry_run=1
  local p_ascii_yes=1
  local test_asc_global_aggregate=1
  local i
  local found=0

  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()
  GLOBALS_DEFERRED=()
  GLOBALS_DRY_RUN=0

  f_global_aggregate

  asc_globals_var_names_arr=()
  asc_globals_values_arr=()
  f_global_list

  assertTrue 'f_global_list should populate names' \
    "[[ ${#asc_globals_var_names_arr[@]} -gt 0 ]]"
  assertEquals 'names and values arrays should match in length' \
    "${#asc_globals_var_names_arr[@]}" "${#asc_globals_values_arr[@]}"

  for ((i = 0; i < ${#asc_globals_var_names_arr[@]}; i++)); do
    if [[ "${asc_globals_var_names_arr[i]}" == 'NFTASCGEVHNC_VAR_1' ]]; then
      assertEquals 'listed value for NFTASCGEVHNC_VAR_1' \
        'test' "${asc_globals_values_arr[i]}"
      found=1
      break
    fi
  done
  assertTrue 'NFTASCGEVHNC_VAR_1 should appear in f_global_list names' \
    "[[ $found -eq 1 ]]"
}

##
# Direct script run must dry-run aggregate GLOBALS metadata (bootstrap alone
# only loads data/asc/global.vars.sh values, not the associative array).
#
# @see asc/instance/globals_debug.sh
#
test_globals_debug_script_without_prior_aggregation() {
  local output
  local status

  output="$(asc/instance/globals_debug.sh 2>&1)"
  status=$?

  assertEquals 'globals_debug.sh should exit 0' 0 "$status"

  case "$output" in
    *'syntax error'*)
      fail 'globals_debug.sh should not hit a GLOBALS subscript syntax error'
      ;;
  esac

  case "$output" in
    *'Defined globals'*) ;;
    *) fail 'globals_debug.sh should print the Defined globals header' ;;
  esac

  case "$output" in
    *'PROJECT_DOCROOT'*) ;;
    *) fail 'globals_debug.sh should list PROJECT_DOCROOT after dry-run aggregate' ;;
  esac
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local s
  for s in $ASC_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    rm -f "asc/$s/global.vars.sh"
  done
  rm -fr 'asc/extensions/nftascgevdehnc'
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
