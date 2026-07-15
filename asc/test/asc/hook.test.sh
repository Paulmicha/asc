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
# @example
#   asc/test/asc/hook.test.sh
#

. asc/bootstrap.sh
. asc/test/asc.inc.sh

##
# Creates temporary files for verification purposes in current test case.
#
oneTimeSetUp() {
  local s

  # Clear dry-run hook caches so newly touched files are visible.
  # @see hook() in asc/utilities/hook.sh
  rm -f scripts/asc/local/cache/hook.*nftaschhnc*

  for s in $ASC_SUBJECTS; do
    # bootstrap/ holds phase includes, not a normal subject action namespace.
    case "$s" in bootstrap) continue ;; esac
    touch "asc/$s/nftaschhnc_dry_run.hook.sh"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error (2) in $BASH_SOURCE line $LINENO: cannot create temporary file for testing ASC hooks." >&2
      echo "-> aborting" >&2
      echo >&2
      exit 2
    fi
  done

  if [[ ! -d "asc/extensions" ]]; then
    echo >&2
    echo "Error (3) in $BASH_SOURCE line $LINENO: ASC extensions dir does not exist." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 3
  fi

  # Dummy extension subjects reuse core subject names plus extra ones so hook
  # subject scanning covers extension namespaces (no dependency on removed
  # core `app` / `presets` subjects).
  mkdir -p "asc/extensions/nftaschdehnc/instance"
  mkdir -p "asc/extensions/nftaschdehnc/stack"
  mkdir -p "asc/extensions/nftaschdehnc/remote"
  mkdir -p "asc/extensions/nftaschdehnc/test"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error (4) in $BASH_SOURCE line $LINENO: cannot create temporary extension dir for testing hooks." >&2
    echo "-> aborting" >&2
    echo >&2
    exit 4
  fi

  touch "asc/extensions/nftaschdehnc/instance/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/stack/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/remote/nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.sh"

  if [[ -z "$INSTANCE_TYPE" ]]; then
    INSTANCE_TYPE='dev'
  fi
  if [[ -z "$HOST_TYPE" ]]; then
    HOST_TYPE='local'
  fi
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  touch "asc/extensions/nftaschdehnc/test/pre_nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$HOST_TYPE.hook.sh"
  touch "asc/extensions/nftaschdehnc/test/undo_nftaschhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  u_asc_extend
}

##
# Will single action hooks load every matching files and none other ?
#
test_asc_hook_single_action() {
  local hook_dry_run_matches=''
  local expected_list=''
  local s

  for s in $ASC_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    expected_list+="asc/$s/nftaschhnc_dry_run.hook.sh"$'\n'
  done
  expected_list+="asc/extensions/nftaschdehnc/instance/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/remote/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh
asc/extensions/nftaschdehnc/stack/nftaschhnc_dry_run.hook.sh
"

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
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

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
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
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$HOST_TYPE.hook.sh
"

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -e 'nftaschdehnc' -v 'HOST_TYPE INSTANCE_TYPE' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Combinatory variants filter hook test failed." $flag
}

##
# Does prefix filter work ?
#
test_asc_hook_prefix() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/pre_nftaschhnc_dry_run.hook.sh"

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
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

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -e 'nftaschdehnc' -p 'post' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + variants filter hook test failed." $flag
}

##
# Does prefix filter work with combinatory variants ?
#
test_asc_hook_prefix_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/undo_nftaschhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  rm -f scripts/asc/local/cache/hook.*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -v 'HOST_TYPE INSTANCE_TYPE' -p 'undo' -t

  u_test_compare_expected_lookup_paths
  u_test_lookup_paths_assertion "Prefix + combinatory variants filter hook test failed." $flag
}

##
# Cleans up any leftovers from previous tests.
#
oneTimeTearDown() {
  local s
  for s in $ASC_SUBJECTS; do
    case "$s" in bootstrap) continue ;; esac
    rm -f "asc/$s/nftaschhnc_dry_run.hook.sh"
  done
  rm -fr "asc/extensions/nftaschdehnc"
}

. asc/vendor/shunit2/shunit2
