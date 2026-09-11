#!/usr/bin/env bash

##
# ASC core extension discovery tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# List of acronyms used (must not collide) :
# - nftascvehnc = vendor for testing ASC contrib extensions hopefully not colliding
# - nftasceonhnc = enabled contrib extension folder
# - nftasceoffhnc = ignored contrib extension folder
# - nftascext_dry_run = hook action for contrib lookup
#
# @example
#   asc/test/core/extensions.test.sh
#

. asc/bootstrap.sh
. asc/test/test.inc.sh

_nftasc_contrib_vendor='nftascvehnc'
_nftasc_contrib_on='nftasceonhnc'
_nftasc_contrib_off='nftasceoffhnc'
_nftasc_contrib_on_id="${_nftasc_contrib_vendor}/${_nftasc_contrib_on}"
_nftasc_contrib_off_id="${_nftasc_contrib_vendor}/${_nftasc_contrib_off}"
_nftasc_ignore_backup='data/tmp/.asc_extensions_ignore.nftasc.bak'

oneTimeSetUp() {
  mkdir -p data/tmp
  cp .asc_extensions_ignore "${_nftasc_ignore_backup}"

  mkdir -p "scripts/asc/contrib/${_nftasc_contrib_on_id}/instance"
  mkdir -p "scripts/asc/contrib/${_nftasc_contrib_off_id}/instance"
  touch "scripts/asc/contrib/${_nftasc_contrib_on_id}/${_nftasc_contrib_on}.inc.sh"
  touch "scripts/asc/contrib/${_nftasc_contrib_on_id}/instance/nftascext_dry_run.hook.sh"

  printf '\n%s\n' "${_nftasc_contrib_off_id}" >> .asc_extensions_ignore

  ASC_EXTENSIONS=''
  ASC_INC=''
  f_asc_extensions
}

oneTimeTearDown() {
  if [[ -f "${_nftasc_ignore_backup}" ]]; then
    cp "${_nftasc_ignore_backup}" .asc_extensions_ignore
    rm -f "${_nftasc_ignore_backup}"
  fi
  rm -fr "scripts/asc/contrib/${_nftasc_contrib_vendor}"
  rm -f data/asc/cache/hook.*nftascext_dry_run*
}

##
# Contrib extensions under scripts/asc/contrib/$vendor/$extension must be
# registered using the prefixed identity.
#
test_f_asc_extensions_discovers_contrib() {
  f_asc_extension_exists "${_nftasc_contrib_on_id}"
  assertTrue \
    "contrib extension '${_nftasc_contrib_on_id}' should be discovered" \
    $?
}

##
# Prefixed ignore entries (vendor/extension) must skip that contrib folder.
#
test_f_asc_extensions_honors_prefixed_ignore() {
  f_asc_extension_exists "${_nftasc_contrib_off_id}"
  assertFalse \
    "ignored contrib '${_nftasc_contrib_off_id}' should not be registered" \
    $?
}

##
# Root ignore entries like asc/apache apply to scripts/asc/contrib, not to
# unprefixed core extension names.
#
test_f_asc_extensions_prefixed_ignore_targets_contrib() {
  f_asc_extension_exists 'asc/apache'
  assertFalse \
    "prefixed ignore 'asc/apache' should exclude scripts/asc/contrib/asc/apache" \
    $?
}

##
# f_asc_extension_path must resolve prefixed contrib names under contrib/.
#
test_f_asc_extension_path_contrib() {
  local ext_path=''

  f_asc_extension_path "${_nftasc_contrib_on_id}"
  assertEquals \
    'prefixed contrib extension path should be scripts/asc/contrib' \
    'scripts/asc/contrib' \
    "$ext_path"
  assertTrue \
    "resolved contrib dir should exist" \
    "[ -d \"${ext_path}/${_nftasc_contrib_on_id}\" ]"
}

##
# Hook lookup must include enabled contrib extension implementations.
#
test_hook_finds_contrib_extension() {
  local hook_dry_run_matches=''
  local expected_list="scripts/asc/contrib/${_nftasc_contrib_on_id}/instance/nftascext_dry_run.hook.sh"

  rm -f data/asc/cache/hook.*nftascext_dry_run*
  hook -a 'nftascext_dry_run' -t

  f_test_compare_expected_lookup_paths
  f_test_lookup_paths_assertion "Contrib extension hook lookup failed." $flag
}

. asc/vendor/shunit2/shunit2
