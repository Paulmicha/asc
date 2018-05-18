#!/usr/bin/env bash

##
# ASC core hook-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# List of acronyms used (must not collide) :
# - nftaschhnc = name for testing ASC hooks hopefully not colliding
# - nftaschdehnc = name for testing ASC hooks dummy extension hopefully not colliding
#
# TODO test dotfiles like '.asc_subjects_ignore' in extensions.
# TODO test folder names with dots (extensions + subjects + actions + prefixes).
#
# @example
#   asc/test/asc/hook.test.sh
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
  for s in $ASC_SUBJECTS; do
    touch "asc/$s/nftaschhnc_dry_run.hook.sh"

    # Failsafe : cannot carry on if touch did not complete without error.
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing ASC hooks." >&2
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

  mkdir -p "asc/extensions/nftaschdehnc/app"

  # Failsafe : cannot carry on without successful temporary extension dir creation.
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing hooks." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  mkdir "asc/extensions/nftaschdehnc/stack"
  mkdir "asc/extensions/nftaschdehnc/remote"
  mkdir "asc/extensions/nftaschdehnc/test"

  # Empty files are enough to trigger positive detection during ASC primitives
  # values aggregation during bootstrap and during hook lookup paths generation.
  # @see u_asc_extend()
  # @see hook()
  touch "asc/extensions/nftaschdehnc/app/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/stack/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/remote/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.sh"

  # Variants tests require the following globals. We set them with dummy values
  # if instance init hasn't been run in current instance yet.
  # @see u_instance_init()
  # @see asc/instance/init.sh
  if [[ -z "$INSTANCE_TYPE" ]]; then
    INSTANCE_TYPE='dev'
  fi
  if [[ -z "$HOST_TYPE" ]]; then
    HOST_TYPE='local'
  fi
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.$HOST_TYPE.hook.sh"

  # Prefix tests.
  touch "asc/extensions/nftaschdehnc/test/pre_nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/undo_nftaschhnc_dry_run.$INSTANCE_TYPE.$HOST_TYPE.hook.sh"

  # Forces detection of our newly created temporary extension.
  u_asc_extend
}

##
# Will single action hooks load every matching files and none other ?
#
test_asc_hook_single_action() {
  local hook_dry_run_matches=''
  local expected_list="asc/app/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/app/nftaschhnc_dry_run.hook.sh
asc/git/nftaschhnc_dry_run.hook.sh
asc/host/nftaschhnc_dry_run.hook.sh
asc/instance/nftaschhnc_dry_run.hook.sh
asc/remote/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/remote/nftaschhnc_dry_run.hook.sh
asc/test/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh
asc/extensions/nftaschdehnc/stack/nftaschhnc_dry_run.hook.sh
"
  hook -a 'nftaschhnc_dry_run' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Single action hook test failed." $flag
}

##
# Does subject filter work ?
#
test_asc_hook_subject() {
  local hook_dry_run_matches=''
  local expected_list="asc/test/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"

  hook -a 'nftaschhnc_dry_run' -s 'test' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Subject filter hook test failed." $flag
}

##
# Does combinatory variants filter work ?
#
test_asc_hook_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.$HOST_TYPE.hook.sh
"

  hook -a 'nftaschhnc_dry_run' -s 'test' -v 'INSTANCE_TYPE HOST_TYPE' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Combinatory variants filter hook test failed." $flag
}

##
# Does prefix filter work ?
#
test_asc_hook_prefix() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/pre_nftaschhnc_dry_run.hook.sh"

  hook -a 'nftaschhnc_dry_run' -p 'pre' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix filter hook test failed." $flag
}

##
# Does prefix filter work with default variants ?
#
test_asc_hook_prefix_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh
"

  hook -a 'nftaschhnc_dry_run' -s 'test' -p 'post' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + variants filter hook test failed." $flag
}

##
# Does prefix filter work with combinatory variants ?
#
test_asc_hook_prefix_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/undo_nftaschhnc_dry_run.$INSTANCE_TYPE.$HOST_TYPE.hook.sh"

  hook -a 'nftaschhnc_dry_run' -s 'test' -v 'INSTANCE_TYPE HOST_TYPE' -p 'undo' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + combinatory variants filter hook test failed." $flag
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local s
  for s in $ASC_SUBJECTS; do
    rm -f "asc/$s/nftaschhnc_dry_run.hook.sh"
  done
  rm -fr "asc/extensions/nftaschdehnc"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
