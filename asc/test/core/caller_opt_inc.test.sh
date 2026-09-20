#!/usr/bin/env bash

##
# Caller opt-inc: nested `$extension/$subject/$action.sh` is 2-level.
#
# Pick A: load `<caller-dir>/<subject>.opt-inc.sh`. Do **not** load
# `$extension/$extension.opt-inc.sh` (the eager twin). Same shape as
# `asc/extensions/db/db/dump.sh` and `remote_instance/db/db.opt-inc.sh`.
#
# Dummy extension: nftcoi (name for testing caller opt-inc).
#
# @requires asc/vendor/shunit2
# @see changelog/2026/09/19-eager-vs-lazy-include-cases.md
# @see asc/bootstrap.sh (caller opt-inc)
#
# @example
#   asc/test/core/caller_opt_inc.test.sh
#

. asc/bootstrap.sh

NFTCOI_ROOT='asc/extensions/nftcoi'

oneTimeSetUp() {
  mkdir -p "$NFTCOI_ROOT/db" "$NFTCOI_ROOT/nftcoi" "$NFTCOI_ROOT/foobar"

  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' \
    > "$NFTCOI_ROOT/db/dump.sh"
  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' \
    > "$NFTCOI_ROOT/nftcoi/dump.sh"
  printf '%s\n' '#!/usr/bin/env bash' '. asc/bootstrap.sh' \
    > "$NFTCOI_ROOT/foobar/run.sh"

  printf '%s\n' 'nftcoi_extension_root_opt=1' \
    > "$NFTCOI_ROOT/nftcoi.opt-inc.sh"
  printf '%s\n' 'nftcoi_nested_db_opt=1' \
    > "$NFTCOI_ROOT/db/db.opt-inc.sh"
  printf '%s\n' 'nftcoi_same_name_opt=1' \
    > "$NFTCOI_ROOT/nftcoi/nftcoi.opt-inc.sh"

  f_asc_extend "$NFTCOI_ROOT" 'NFTCOI'
}

oneTimeTearDown() {
  rm -rf "$NFTCOI_ROOT"
}

f_nftcoi_clear_opt_markers() {
  nftcoi_extension_root_opt=''
  nftcoi_nested_db_opt=''
  nftcoi_same_name_opt=''
}

##
# `remote_instance/db/sync_to.sh` shape: extension name ≠ inner subject.
#
test_asc_caller_opt_inc_nested_subject_loads_caller_dir_not_extension_root() {
  local saved_ext="$ASC_EXTENSIONS"

  f_nftcoi_clear_opt_markers
  ASC_EXTENSIONS="$saved_ext nftcoi"
  # shellcheck disable=SC1091
  . "$NFTCOI_ROOT/db/dump.sh"

  assertEquals 'caller-dir db.opt-inc.sh loads' '1' "${nftcoi_nested_db_opt:-}"
  assertEquals 'extension-root nftcoi.opt-inc.sh does not load' '' "${nftcoi_extension_root_opt:-}"
  assertEquals 'same-name inner opt-inc does not load' '' "${nftcoi_same_name_opt:-}"

  ASC_EXTENSIONS="$saved_ext"
}

##
# `db/db/dump.sh` shape: extension folder and inner subject share a name.
# Still 2-level (not `$subject/$object`).
#
test_asc_caller_opt_inc_same_name_extension_and_subject_is_two_level() {
  local saved_ext="$ASC_EXTENSIONS"

  f_nftcoi_clear_opt_markers
  ASC_EXTENSIONS="$saved_ext nftcoi"
  # shellcheck disable=SC1091
  . "$NFTCOI_ROOT/nftcoi/dump.sh"

  assertEquals 'caller-dir nftcoi/nftcoi.opt-inc.sh loads' '1' "${nftcoi_same_name_opt:-}"
  assertEquals 'extension-root nftcoi.opt-inc.sh does not load' '' "${nftcoi_extension_root_opt:-}"
  assertEquals 'other nested subject opt-inc does not load' '' "${nftcoi_nested_db_opt:-}"

  ASC_EXTENSIONS="$saved_ext"
}

##
# Wrong caller (`foobar/run.sh`) must not pull another subject's opt-inc.
#
test_asc_caller_opt_inc_wrong_caller_does_not_load_nested_subject() {
  local saved_ext="$ASC_EXTENSIONS"

  f_nftcoi_clear_opt_markers
  ASC_EXTENSIONS="$saved_ext nftcoi"
  # shellcheck disable=SC1091
  . "$NFTCOI_ROOT/foobar/run.sh"

  assertEquals 'nested db opt-inc stays unset' '' "${nftcoi_nested_db_opt:-}"
  assertEquals 'same-name inner opt-inc stays unset' '' "${nftcoi_same_name_opt:-}"
  assertEquals 'extension-root opt-inc stays unset' '' "${nftcoi_extension_root_opt:-}"

  ASC_EXTENSIONS="$saved_ext"
}

. asc/vendor/shunit2/shunit2
