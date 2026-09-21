#!/usr/bin/env bash

##
# ASC core hook-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# List of acronyms used (must not collide) :
# - nftaschhnc = name for testing ASC hooks hopefully not colliding
# - nftaschdehnc = name for testing ASC hooks dummy extension hopefully not colliding
#
# @example
#   asc/test/asc/hook.test.sh
#

. asc/bootstrap.sh
if [[ "$(type -t f_test_batch_exec)" != function ]]; then
  # shellcheck disable=SC1091
  . asc/test/test.opt-inc.sh
fi

##
# Creates temporary files for verification purposes in current test case.
#
oneTimeSetUp() {
  local s

  # Clear dry-run hook caches so newly touched files are visible.
  # @see hook() in asc/utilities/hook.sh
  rm -f data/asc/cache/hook/*nftaschhnc*

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

  f_asc_extend
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

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Single action hook test failed." $flag
}

##
# Does subject filter work ?
#
test_asc_hook_subject() {
  local hook_dry_run_matches=''
  local expected_list="asc/test/nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh"

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Subject filter hook test failed." $flag
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

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -e 'nftaschdehnc' -v 'HOST_TYPE INSTANCE_TYPE' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Combinatory variants filter hook test failed." $flag
}

##
# Does prefix filter work ?
#
test_asc_hook_prefix() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/pre_nftaschhnc_dry_run.hook.sh"

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -p 'pre' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Prefix filter hook test failed." $flag
}

##
# Does prefix filter work with default variants ?
#
test_asc_hook_prefix_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.hook.sh
asc/extensions/nftaschdehnc/test/post_nftaschhnc_dry_run.$INSTANCE_TYPE.hook.sh
"

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -e 'nftaschdehnc' -p 'post' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Prefix + variants filter hook test failed." $flag
}

##
# Does prefix filter work with combinatory variants ?
#
test_asc_hook_prefix_combinatory_variants() {
  local hook_dry_run_matches=''
  local expected_list="asc/extensions/nftaschdehnc/test/undo_nftaschhnc_dry_run.$HOST_TYPE.$INSTANCE_TYPE.hook.sh"

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -v 'HOST_TYPE INSTANCE_TYPE' -p 'undo' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Prefix + combinatory variants filter hook test failed." $flag
}

##
# Canonical hook cache key: parsed flags, variant values, no -d / -w.
#
test_f_hook_cache_key_canonical() {
  local o_subjects_filter='site instance'
  local o_actions_filter='fs_perms_set'
  local o_prefixes_filter='pre'
  local o_variants_filter='STACK_VERSION HOST_TYPE INSTANCE_TYPE'
  local o_extensions_filter=''
  local o_custom_filter=''
  local b_debug=1
  local b_dry_run=0
  local b_root_lookup=0
  local b_cache_warmup=1
  local hook_cache_key=''

  f_hook_cache_key
  assertEquals 'canonical key from parsed flags' \
    "s-site,instance.a-fs_perms_set.p-pre.v-${STACK_VERSION},${HOST_TYPE},${INSTANCE_TYPE}" \
    "$hook_cache_key"
}

##
# Dry-run and root-lookup stay in the key; debug and warmup do not.
#
test_f_hook_cache_key_flags() {
  local o_subjects_filter=''
  local o_actions_filter='global'
  local o_prefixes_filter=''
  local o_variants_filter=''
  local o_extensions_filter=''
  local o_custom_filter='vars.sh'
  local b_debug=1
  local b_dry_run=1
  local b_root_lookup=1
  local b_cache_warmup=1
  local hook_cache_key=''

  f_hook_cache_key
  assertEquals 'custom + t + r; no d/w' 'a-global.c-vars.sh.t.r' "$hook_cache_key"
}

##
# Same -s/-a/-v with and without -d or -w share one cache file.
#
test_hook_cache_debug_and_warmup_share_file() {
  local n1
  local n2

  rm -f data/asc/cache/hook/*nftaschhnc*
  hook -a 'nftaschhnc_dry_run' -s 'test' -t
  n1=$(find data/asc/cache/hook -name '*nftaschhnc*' 2>/dev/null | wc -l)

  hook -a 'nftaschhnc_dry_run' -s 'test' -t -d
  hook -a 'nftaschhnc_dry_run' -s 'test' -t -w
  n2=$(find data/asc/cache/hook -name '*nftaschhnc*' 2>/dev/null | wc -l)

  assertEquals 'one cache file for the match set' '1' "$(echo "$n1" | tr -d ' ')"
  assertEquals '-d and -w must not add cache files' "$n1" "$n2"
}

##
# f_provision_using_lookup_values: dual-compat + printf -v output.
#
test_f_provision_using_lookup_values() {
  local out=''

  f_provision_using_lookup_values 'compose' 'out'
  assertEquals 'compose dual-compat via printf -v' 'compose docker-compose' "$out"

  out=''
  f_provision_using_lookup_values 'docker-compose' 'out'
  assertEquals 'docker-compose dual-compat via printf -v' 'compose docker-compose' "$out"

  out=''
  f_provision_using_lookup_values 'asc' 'out'
  assertEquals 'plain provision value via printf -v' 'asc' "$out"

  # Stdout path kept for callers that still capture.
  assertEquals 'stdout fallback' 'asc' "$(f_provision_using_lookup_values 'asc')"
}

##
# f_hook_variant_values_add expands PROVISION_USING without duplicating.
#
test_f_hook_variant_values_add() {
  local v_values=''

  f_hook_variant_values_add 'PROVISION_USING' 'compose' 'v_values'
  assertEquals 'compose expands to both tokens' 'compose docker-compose ' "$v_values"

  f_hook_variant_values_add 'PROVISION_USING' 'docker-compose' 'v_values'
  assertEquals 'second dual add is idempotent' 'compose docker-compose ' "$v_values"

  f_hook_variant_values_add 'INSTANCE_TYPE' 'dev' 'v_values'
  assertEquals 'normal variant appends once' 'compose docker-compose dev ' "$v_values"

  f_hook_variant_values_add 'INSTANCE_TYPE' 'dev' 'v_values'
  assertEquals 'normal variant dedupes' 'compose docker-compose dev ' "$v_values"
}

##
# f_hook_opt_inc_append_candidates finds colocated opt-incs and dedupes.
#
test_f_hook_opt_inc_append_candidates() {
  local opt_incs_arr=()
  local dir='asc/extensions/nftaschdehnc/test'
  local hook_path="$dir/nftaschhnc_dry_run.hook.sh"

  touch "$dir/test.opt-inc.sh" "$dir/nftaschhnc_dry_run.opt-inc.sh"

  f_hook_opt_inc_append_candidates "$hook_path" opt_incs_arr
  assertEquals 'should find subject + action opt-incs' 2 "${#opt_incs_arr[@]}"
  assertTrue 'subject opt-inc' "[[ \" \${opt_incs_arr[*]} \" == *\" $dir/test.opt-inc.sh \"* ]]"
  assertTrue 'action opt-inc' "[[ \" \${opt_incs_arr[*]} \" == *\" $dir/nftaschhnc_dry_run.opt-inc.sh \"* ]]"

  f_hook_opt_inc_append_candidates "$hook_path" opt_incs_arr
  assertEquals 'second append must dedupe' 2 "${#opt_incs_arr[@]}"

  f_hook_opt_inc_append_candidates "$dir/not_a_hook.sh" opt_incs_arr
  assertEquals 'non-hook paths ignored' 2 "${#opt_incs_arr[@]}"

  rm -f "$dir/test.opt-inc.sh" "$dir/nftaschhnc_dry_run.opt-inc.sh"
}

##
# hook_ms ranks a path before it adds dot-parts and slash-parts.
#
test_hook_ms_rung_order() {
  local -a paths=(
    'asc/db/dump.hook.sh'
    'asc/extensions/db/db/dump.hook.sh'
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh'
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh'
    'scripts/asc/extend/db/dump.hook.sh'
    'env.local.dev.yml'
  )
  local expect_rungs=(0 0 1 2 3 4)
  local i

  for i in "${!paths[@]}"; do
    f_hook_ms_measure "${paths[$i]}"
    assertEquals "rung ${paths[$i]}" "${expect_rungs[$i]}" "$hook_ms_rung"
  done

  # Inside rung 0 the sum is unchanged: more slashes still beat a shallower core file.
  f_hook_ms_measure 'asc/db/dump.hook.sh'
  local core_sum=$hook_ms_sum
  f_hook_ms_measure 'asc/extensions/db/db/dump.hook.sh'
  assertTrue 'extension sum beats core sum' "[[ $hook_ms_sum -gt $core_sum ]]"

  # The old sum picked the deep ASC-shipped hook implementation (15) over extend (12 or 13).
  # Rung 3 must beat rung 1 even when the extend filename has fewer dots.
  local best=''
  local best_rung=-1
  local best_sum=-1
  local f
  for f in \
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.hook.sh' \
    'scripts/asc/extend/db/dump.hook.sh'
  do
    f_hook_ms_measure "$f"
    if [[ $hook_ms_rung -gt $best_rung ]] \
      || { [[ $hook_ms_rung -eq $best_rung ]] && [[ $hook_ms_sum -ge $best_sum ]]; }; then
      best="$f"
      best_rung=$hook_ms_rung
      best_sum=$hook_ms_sum
    fi
  done
  assertEquals 'extend beats asc-shipped contrib' \
    'scripts/asc/extend/db/dump.hook.sh' "$best"

  best=''
  best_rung=-1
  best_sum=-1
  for f in \
    'scripts/asc/contrib/asc/mysql/db/dump.mysql.aaa.bbb.hook.sh' \
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh'
  do
    f_hook_ms_measure "$f"
    if [[ $hook_ms_rung -gt $best_rung ]] \
      || { [[ $hook_ms_rung -eq $best_rung ]] && [[ $hook_ms_sum -ge $best_sum ]]; }; then
      best="$f"
      best_rung=$hook_ms_rung
      best_sum=$hook_ms_sum
    fi
  done
  assertEquals 'other vendor beats asc-shipped contrib' \
    'scripts/asc/contrib/acme/mysql/db/dump.hook.sh' "$best"
}

##
# Remove zzscore fixture files created by test_hook_ms_extend_beats_contrib.
#
_hook_test_zzscore_cleanup() {
  rm -f \
    scripts/asc/contrib/asc/zzscorea/zzscore/zzscore.aaa.bbb.hook.sh \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore/zzscore.hook.sh \
    scripts/asc/extend/zzscore/zzscore.hook.sh \
    data/asc/cache/hook/*zzscore*
  rmdir \
    scripts/asc/extend/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev \
    scripts/asc/contrib/zzvendor \
    scripts/asc/contrib/asc/zzscorea/zzscore \
    scripts/asc/contrib/asc/zzscorea \
    2>/dev/null || true
}

##
# hook_ms dry-run prefers scripts/asc/extend over both contrib rungs.
#
test_hook_ms_extend_beats_contrib() {
  local saved_ext="$ASC_EXTENSIONS"
  local saved_extend_subjects="${EXTEND_SUBJECTS-}"
  local saved_extend_actions="${EXTEND_ACTIONS-}"
  local saved_extend_objects="${EXTEND_OBJECTS-}"
  local saved_inc="${ASC_INC-}"
  local dir

  _hook_test_zzscore_cleanup

  for dir in \
    scripts/asc/contrib/asc/zzscorea/zzscore \
    scripts/asc/contrib/zzvendor/zzscorev/zzscore \
    scripts/asc/extend/zzscore
  do
    mkdir -p "$dir"
  done

  # More dots on the ASC-shipped file, on purpose.
  touch scripts/asc/contrib/asc/zzscorea/zzscore/zzscore.aaa.bbb.hook.sh
  touch scripts/asc/contrib/zzvendor/zzscorev/zzscore/zzscore.hook.sh
  touch scripts/asc/extend/zzscore/zzscore.hook.sh

  f_asc_extend 'scripts/asc/contrib/asc/zzscorea'
  f_asc_extend 'scripts/asc/contrib/zzvendor/zzscorev'
  f_asc_extend 'scripts/asc/extend'

  ASC_EXTENSIONS="$saved_ext asc/zzscorea zzvendor/zzscorev extend"
  rm -f data/asc/cache/hook/*zzscore*

  most_specific_match=''
  hook_ms 'dry-run' -s 'zzscore' -a 'zzscore' -t

  assertEquals 'dry-run winner is extend' \
    'scripts/asc/extend/zzscore/zzscore.hook.sh' \
    "$most_specific_match"

  _hook_test_zzscore_cleanup
  ASC_EXTENSIONS="$saved_ext"
  EXTEND_SUBJECTS="$saved_extend_subjects"
  EXTEND_ACTIONS="$saved_extend_actions"
  EXTEND_OBJECTS="$saved_extend_objects"
  ASC_INC="$saved_inc"
  unset ZZSCOREA_SUBJECTS ZZSCOREA_ACTIONS ZZSCOREA_OBJECTS
  unset ZZSCOREV_SUBJECTS ZZSCOREV_ACTIONS ZZSCOREV_OBJECTS
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
  _hook_test_zzscore_cleanup
}

. asc/vendor/shunit2/shunit2
