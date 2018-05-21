#!/usr/bin/env bash

##
# ASC core global vars related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# List of acronyms used (must not collide) :
# - nftascgevhnc = name for testing ASC global env vars hopefully not colliding
# - nftascgevdehnc = name for testing ASC global env vars dummy extension hopefully not colliding
#
# @example
#   asc/test/asc/global.test.sh
#

. asc/bootstrap.sh
. asc/test/self_test.inc.sh

##
# Creates temporary files for verification purposes in current test case.
#
# (Internal shunit2 function called before all tests have run.)
#
oneTimeSetUp() {
  local s
  local s_upper

  for s in $ASC_SUBJECTS; do
    u_str_uppercase "$s" 's_upper'
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

  mkdir -p "asc/extensions/nftascgevdehnc/app"

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

  cat > "asc/extensions/nftascgevdehnc/app/global.vars.sh" <<'EOF'
#!/usr/bin/env bash
global NFTASCGEVHNC_APP_VAR_1 'test'
EOF

  # Forces detection of our newly created temporary extension.
  u_asc_extend
}

##
# Does the initial aggregation process work ?
#
test_asc_global_aggregate() {
  local global_lookup_paths=''
  local p_ascii_dry_run=1
  local p_ascii_yes=1

  unset GLOBALS
  declare -A GLOBALS
  GLOBALS_COUNT=0
  GLOBALS_UNIQUE_NAMES=()
  GLOBALS_UNIQUE_KEYS=()

  u_global_aggregate
  u_global_debug

  local s
  local s_upper
  local s_test_val
  for s in $ASC_SUBJECTS; do
    u_str_uppercase "$s" 's_upper'
    eval "s_test_val=\"\$$NFTASCGEVHNC_VAR_ASC_$s_upper\""
    assertEquals "Value of NFTASCGEVHNC_VAR_ASC_$s_upper is missing or incorrect." "test" "$s_test_val"
  done

  assertEquals 'Value of NFTASCGEVHNC_VAR_1 is missing or incorrect.' "test" "$NFTASCGEVHNC_VAR_1"
  assertEquals 'Value of NFTASCGEVHNC_APP_VAR_1 is missing or incorrect.' "test" "$NFTASCGEVHNC_APP_VAR_1"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local s
  for s in $ASC_SUBJECTS; do
    rm -f "asc/$s/global.vars.sh"
  done
  rm -fr 'asc/extensions/nftascgevdehnc'
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
