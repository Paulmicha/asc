#!/usr/bin/env bash

##
# Shared writable directories are walked once, then protected files are applied.
#
# A site id that needs variable-name sanitization resolves through that name.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see scripts/asc/contrib/asc/drupalwt/test/core.hook.sh
#
# @example
#   scripts/asc/contrib/asc/drupalwt/test/core/fs_perms_set.test.sh
#

. asc/bootstrap.sh

##
# One walk per shared path, sanitized site directory, protected mode last.
#
test_fs_perms_set_shared_dirs_once() {
  find() {
    printf '%s\n' "FIND $*" >> "$dwt_perms_test_log"
    command find "$@"
  }

  chmod() {
    printf '%s\n' "CHMOD $*" >> "$dwt_perms_test_log"
    command chmod "$@"
  }

  local root
  local shared_tmp
  local shared_private
  local settings
  local alpha_settings
  local find_f
  local find_d
  local first_chmod
  local last_find
  local mode

  root="$(mktemp -d "${TMPDIR:-/tmp}/asc-dwt-perms.XXXXXX")"
  shared_tmp="$root/sites"
  shared_private="$root/private"
  settings="$root/sites/nfdir/settings.php"
  alpha_settings="$root/sites/alpha/settings.php"
  mkdir -p "$root/sites/nfdir" "$root/sites/alpha" "$shared_private"
  printf '%s\n' '<?php' > "$settings"
  printf '%s\n' '<?php' > "$alpha_settings"
  printf '%s\n' 'x' > "$shared_private/file.txt"

  dwt_perms_test_log="$root/log.txt"
  : > "$dwt_perms_test_log"

  DWT_MULTISITE='true'
  FS_W_FILES='0664'
  FS_W_DIRS='0775'
  FS_P_FILES='0440'
  DRUPAL_SETTINGS_FILE="$root/sites/default/settings.php"
  DRUPAL_SETTINGS_LOCAL_FILE="$root/sites/default/settings.local.php"
  dwt_sites_news_fr_dir='nfdir'
  dwt_sites_alpha_dir='alpha'
  site_dir=''

  f_dwt_sites() {
    dwt_sites_ids_arr=('default' 'alpha' 'news-fr')
  }

  f_dwt_get_sites_writeable_paths() {
    dwt_sites_writeable_paths_arr=("$shared_tmp" "$shared_private")
  }

  (
    # shellcheck disable=SC1091
    . scripts/asc/contrib/asc/drupalwt/app/fs_perms_set.hook.sh
  )

  find_f="$(grep -c "^FIND ${shared_tmp} -type f " "$dwt_perms_test_log" || true)"
  find_d="$(grep -c "^FIND ${shared_tmp} -type d " "$dwt_perms_test_log" || true)"
  assertEquals 'shared temporary files are walked once' '1' "$find_f"
  assertEquals 'shared temporary directories are walked once' '1' "$find_d"

  assertTrue 'protected path uses the sanitized site directory' \
    "grep -q \"CHMOD ${FS_P_FILES} ${settings}\" \"$dwt_perms_test_log\""
  assertFalse 'empty site_dir must not produce a doubled slash' \
    "grep -q 'sites//' \"$dwt_perms_test_log\""

  first_chmod="$(grep -n '^CHMOD ' "$dwt_perms_test_log" | head -n 1 | cut -d: -f1)"
  last_find="$(grep -n '^FIND ' "$dwt_perms_test_log" | tail -n 1 | cut -d: -f1)"
  assertTrue 'protected chmod runs after the writable walks' \
    "[[ -n \"$first_chmod\" && -n \"$last_find\" && \"$first_chmod\" -gt \"$last_find\" ]]"

  mode="$(stat -c '%a' "$settings")"
  assertEquals 'a path covered by both ends protected' '440' "$mode"

  rm -rf "$root"
  unset dwt_perms_test_log site_dir dwt_sites_news_fr_dir dwt_sites_alpha_dir
  unset -f f_dwt_sites f_dwt_get_sites_writeable_paths find chmod
}

. asc/vendor/shunit2/shunit2
