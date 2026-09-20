#!/usr/bin/env bash

##
# Primitives: `$subject` / `$object` / `$action` discovery, pivots, hooks, opt-inc.
#
# Dummy extension: nftasoaep (name for testing ASC subject/object/action extra path).
#
# @requires asc/vendor/shunit2
# @see changelog/2026/09/12-subject-object-action-entry-points.md
#
# @example
#   asc/test/core/primitives.test.sh
#

. asc/bootstrap.sh
. asc/test/test.inc.sh

NFTASOAEP_ROOT='asc/extensions/nftasoaep'

oneTimeSetUp() {
  mkdir -p "$NFTASOAEP_ROOT/foobar/baz" \
    "$NFTASOAEP_ROOT/foobar/deep/nested" \
    "$NFTASOAEP_ROOT/foobar/yamlonly" \
    "$NFTASOAEP_ROOT/skipobj/hidden" \
    "$NFTASOAEP_ROOT/skipobj/shown"

  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' > "$NFTASOAEP_ROOT/foobar/run.sh"
  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' > "$NFTASOAEP_ROOT/foobar/baz.sh"
  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' > "$NFTASOAEP_ROOT/foobar/baz/toto.sh"
  touch "$NFTASOAEP_ROOT/foobar/baz/toto.hook.sh"
  touch "$NFTASOAEP_ROOT/foobar/baz/x.test.sh"
  printf '%s\n' '#!/usr/bin/env bash' > "$NFTASOAEP_ROOT/foobar/deep/nested/toto.sh"
  touch "$NFTASOAEP_ROOT/foobar/yamlonly/spec.entity.yml"
  printf '%s\n' 'hidden' > "$NFTASOAEP_ROOT/skipobj/.asc_objects_ignore"
  printf '%s\n' '#!/usr/bin/env bash' > "$NFTASOAEP_ROOT/skipobj/hidden/toto.sh"
  printf '%s\n' '#!/usr/bin/env bash' > "$NFTASOAEP_ROOT/skipobj/shown/toto.sh"

  printf '%s\n' 'nftasoaep_subject_opt=1' > "$NFTASOAEP_ROOT/foobar/foobar.opt-inc.sh"
  printf '%s\n' 'nftasoaep_run_opt=1' > "$NFTASOAEP_ROOT/foobar/run.opt-inc.sh"
  printf '%s\n' 'nftasoaep_toto_opt=1' > "$NFTASOAEP_ROOT/foobar/baz/toto.opt-inc.sh"

  f_asc_extend "$NFTASOAEP_ROOT" 'NFTASOAEP'
}

oneTimeTearDown() {
  rm -rf "$NFTASOAEP_ROOT"
}

test_asc_objects_three_level_discover() {
  assertTrue 'object pair foobar/baz' "[[ \" \$NFTASOAEP_OBJECTS \" == *' foobar/baz '* ]]"
  assertTrue '3-level action' "[[ \" \$NFTASOAEP_ACTIONS \" == *' foobar/baz/toto '* ]]"
}

test_asc_objects_coexistence_two_and_three_level() {
  assertTrue '2-level baz.sh' "[[ \" \$NFTASOAEP_ACTIONS \" == *' foobar/baz '* ]]"
  assertTrue '3-level baz/toto.sh' "[[ \" \$NFTASOAEP_ACTIONS \" == *' foobar/baz/toto '* ]]"
}

test_asc_objects_skip_double_ext_yaml_and_nested() {
  assertTrue 'x.test.sh is not an action' "[[ \" \$NFTASOAEP_ACTIONS \" != *' foobar/baz/x '* ]]"
  assertTrue 'yaml-only dir is not an object' "[[ \" \$NFTASOAEP_OBJECTS \" != *' foobar/yamlonly '* ]]"
  assertTrue 'nested deeper than object is not discovered' "[[ \" \$NFTASOAEP_ACTIONS \" != *' foobar/deep/nested/toto '* ]]"
  assertTrue 'empty deep dir is not an object' "[[ \" \$NFTASOAEP_OBJECTS \" != *' foobar/deep '* ]]"
}

test_asc_objects_ignore_dotfile() {
  assertTrue 'shown object kept' "[[ \" \$NFTASOAEP_OBJECTS \" == *' skipobj/shown '* ]]"
  assertTrue 'hidden object ignored' "[[ \" \$NFTASOAEP_OBJECTS \" != *' skipobj/hidden '* ]]"
  assertTrue 'hidden action ignored' "[[ \" \$NFTASOAEP_ACTIONS \" != *' skipobj/hidden/toto '* ]]"
  assertTrue 'shown action kept' "[[ \" \$NFTASOAEP_ACTIONS \" == *' skipobj/shown/toto '* ]]"
}

test_asc_make_deeper_wins_same_namespace() {
  local saved_actions="$ASC_ACTIONS"
  local saved_ext="$ASC_EXTENSIONS"
  local saved_extend="${EXTEND_ACTIONS-}"
  local i
  local script=''

  ASC_ACTIONS='foobar/baz_toto foobar/baz/toto'
  ASC_EXTENSIONS=''
  EXTEND_ACTIONS=''

  pivots_arr=()
  real_scripts_arr=()
  f_make_list_entry_points

  assertEquals 'pivots and scripts stay zipped' "${#pivots_arr[@]}" "${#real_scripts_arr[@]}"

  for i in "${!pivots_arr[@]}"; do
    if [[ "${pivots_arr[i]}" == 'foobar-baz-toto' ]]; then
      script="${real_scripts_arr[i]}"
      break
    fi
  done

  assertEquals 'deeper path wins' 'asc/foobar/baz/toto.sh' "$script"

  local count=0
  for i in "${!pivots_arr[@]}"; do
    if [[ "${pivots_arr[i]}" == 'foobar-baz-toto' ]]; then
      count=$((count + 1))
    fi
  done
  assertEquals 'single make target' '1' "$count"

  ASC_ACTIONS="$saved_actions"
  ASC_EXTENSIONS="$saved_ext"
  EXTEND_ACTIONS="$saved_extend"
}

test_asc_make_equal_depth_first_wins() {
  local saved_actions="$ASC_ACTIONS"
  local saved_ext="$ASC_EXTENSIONS"
  local saved_extend="${EXTEND_ACTIONS-}"
  local i
  local script=''

  ASC_ACTIONS='foobar/baz_toto foobar/baz-toto'
  ASC_EXTENSIONS=''
  EXTEND_ACTIONS=''

  pivots_arr=()
  real_scripts_arr=()
  f_make_list_entry_points

  for i in "${!pivots_arr[@]}"; do
    if [[ "${pivots_arr[i]}" == 'foobar-baz-toto' ]]; then
      script="${real_scripts_arr[i]}"
      break
    fi
  done

  assertEquals 'equal depth keeps first' 'asc/foobar/baz_toto.sh' "$script"

  ASC_ACTIONS="$saved_actions"
  ASC_EXTENSIONS="$saved_ext"
  EXTEND_ACTIONS="$saved_extend"
}

test_asc_make_cross_namespace_prefixes() {
  local saved_actions="$ASC_ACTIONS"
  local saved_ext="$ASC_EXTENSIONS"
  local saved_extend="${EXTEND_ACTIONS-}"
  local i
  local core_script=''
  local found_prefixed=0

  ASC_ACTIONS='foobar/baz/toto'
  ASC_EXTENSIONS='extend'
  EXTEND_ACTIONS='foobar/baz/toto'

  pivots_arr=()
  real_scripts_arr=()
  f_make_list_entry_points

  for i in "${!pivots_arr[@]}"; do
    if [[ "${pivots_arr[i]}" == 'foobar-baz-toto' ]]; then
      core_script="${real_scripts_arr[i]}"
    fi
    if [[ "${pivots_arr[i]}" == 'extend-foobar-baz-toto' ]]; then
      found_prefixed=1
    fi
  done

  assertEquals 'core keeps unprefixed script' 'asc/foobar/baz/toto.sh' "$core_script"
  assertEquals 'extend is prefixed' '1' "$found_prefixed"
  assertEquals 'arrays stay zipped' "${#pivots_arr[@]}" "${#real_scripts_arr[@]}"

  ASC_ACTIONS="$saved_actions"
  ASC_EXTENSIONS="$saved_ext"
  EXTEND_ACTIONS="$saved_extend"
}

test_asc_hook_unfiltered_skips_object_dir() {
  local saved_ext="$ASC_EXTENSIONS"
  local hook_dry_run_matches=''

  ASC_EXTENSIONS="$saved_ext nftasoaep"
  rm -f data/asc/cache/hook/*nftasoaep*

  hook -e 'nftasoaep' -v 'INSTANCE_TYPE' -t

  assertTrue 'no object-dir hook path' "[[ \"\$hook_dry_run_matches\" != *foobar/baz/toto.hook.sh* ]]"

  ASC_EXTENSIONS="$saved_ext"
}

test_asc_bootstrap_opt_inc_two_level() {
  local saved_ext="$ASC_EXTENSIONS"
  nftasoaep_subject_opt=''
  nftasoaep_run_opt=''
  nftasoaep_toto_opt=''

  ASC_EXTENSIONS="$saved_ext nftasoaep"
  # shellcheck disable=SC1091
  . "$NFTASOAEP_ROOT/foobar/run.sh"

  assertEquals '2-level seeds subject opt-inc' '1' "${nftasoaep_subject_opt:-}"
  assertEquals '2-level seeds action opt-inc' '1' "${nftasoaep_run_opt:-}"
  assertEquals '2-level does not seed object action opt-inc' '' "${nftasoaep_toto_opt:-}"

  ASC_EXTENSIONS="$saved_ext"
}

test_asc_bootstrap_opt_inc_three_level() {
  local saved_ext="$ASC_EXTENSIONS"
  nftasoaep_subject_opt=''
  nftasoaep_run_opt=''
  nftasoaep_toto_opt=''

  ASC_EXTENSIONS="$saved_ext nftasoaep"
  # shellcheck disable=SC1091
  . "$NFTASOAEP_ROOT/foobar/baz/toto.sh"

  assertEquals '3-level seeds subject opt-inc from subject dir' '1' "${nftasoaep_subject_opt:-}"
  assertEquals '3-level seeds colocated action opt-inc' '1' "${nftasoaep_toto_opt:-}"
  assertEquals '3-level does not seed sibling 2-level action opt-inc' '' "${nftasoaep_run_opt:-}"

  ASC_EXTENSIONS="$saved_ext"
}

##
# Test helpers must not load from eager `test.inc.sh` (nested bootstrap).
# Callers `.` `asc/test/test.opt-inc.sh`. `asc/test/` entry points seed it.
# @see changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md
#
test_f_test_batch_exec_helpers_absent_from_kernel_bootstrap() {
  local out
  out="$(bash -c '. asc/bootstrap.sh
printf "%s" "$(type -t f_test_batch_exec)"')"
  assertEquals 'f_test_batch_exec unset after kernel bootstrap' \
    '' "$out"

  out="$(bash -c '. asc/bootstrap.sh
. asc/test/test.opt-inc.sh
printf "%s" "$(type -t f_test_batch_exec)"')"
  assertEquals 'f_test_batch_exec exists after opt-inc' \
    'function' "$out"
}

. asc/vendor/shunit2/shunit2
