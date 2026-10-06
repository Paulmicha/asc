#!/usr/bin/env bash

##
# Generic Drupal settings renderer: one pass, unknown tokens kept, values literal.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see scripts/asc/contrib/asc/drupalwt/test/core.hook.sh
#
# @example
#   scripts/asc/contrib/asc/drupalwt/test/core/drupal_settings_tokens.test.sh
#

. asc/bootstrap.sh

if [[ "$(type -t f_dwt_write_drupal_settings)" != function ]]; then
  # shellcheck disable=SC1091
  . scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh
fi

##
# Writes one settings file from the temporary template.
#
# @param 1 String : DB_PASS value.
#
_dwt_token_render() {
  local p_pass="$1"

  DB_USER='dbuser'
  DB_PASS="$p_pass"
  DRUPAL_HASH_SALT='say "hi" \path {{ DB_USER }}'

  f_db_set() {
    DB_USER='dbuser'
    DB_PASS="$p_pass"
  }

  f_db_vars_list() {
    db_vars_list='USER PASS'
  }

  f_global_list() {
    asc_globals_var_names_arr=(
      'DRUPAL_HASH_SALT'
      'DRUPAL_FILES_DIR'
      'DRUPAL_CONFIG_SYNC_DIR'
    )
  }

  hook_ms() {
    most_specific_match="$dwt_token_template"
  }

  rm -f "$DRUPAL_SETTINGS_FILE"
  f_dwt_write_drupal_settings 'default'
}

##
# Token contract for the generic renderer.
#
test_dwt_settings_tokens_are_literal_php() {
  local root
  local rendered
  local php_status

  root="$(mktemp -d "${TMPDIR:-/tmp}/asc-dwt-tokens.XXXXXX")"
  dwt_token_template="$root/settings.tpl.php"
  SERVER_DOCROOT="$root/web"
  DRUPAL_SETTINGS_FILE="$SERVER_DOCROOT/sites/default/settings.php"
  DRUPAL_FILES_DIR="$root/files"
  DRUPAL_CONFIG_SYNC_DIR="$root/config/sync"
  DRUPAL_FILES_DIR_C="$root/cfiles"
  DRUPAL_CONFIG_SYNC_DIR_C="$root/csync"
  SERVER_DOCROOT_C="$root/cweb"
  DWT_USE_SETTINGS_LOCAL_OVERRIDE=''
  DWT_MULTISITE=''
  ASC_DB_IDS=''
  FS_P_FILES='0644'
  mkdir -p "$SERVER_DOCROOT/sites/default" "$DRUPAL_FILES_DIR" "$DRUPAL_CONFIG_SYNC_DIR"

  printf '%s\n' '<?php' > "$SERVER_DOCROOT/sites/default/default.settings.php"
  cat > "$dwt_token_template" <<'EOF'
<?php
$settings['hash_salt'] = '{{ DRUPAL_HASH_SALT }}';
$settings['file_public_path'] = '{{ DRUPAL_FILES_DIR }}';
$settings['config_sync'] = '{{ DRUPAL_CONFIG_SYNC_DIR }}';
$databases['default']['default']['password'] = '{{ DB_PASS }}';
$settings['kept'] = '{{ NOT_A_KNOWN_VAR }}';
EOF

  local hash_line
  local kept_line
  local pass_line
  local files_line
  local sync_line

  _dwt_token_render 'a,b'
  hash_line="$(grep "hash_salt" "$DRUPAL_SETTINGS_FILE")"
  kept_line="$(grep "kept" "$DRUPAL_SETTINGS_FILE")"
  pass_line="$(grep "password" "$DRUPAL_SETTINGS_FILE")"
  files_line="$(grep "file_public_path" "$DRUPAL_SETTINGS_FILE")"
  sync_line="$(grep "config_sync" "$DRUPAL_SETTINGS_FILE")"

  assertEquals 'inserted token stays literal' \
    "\$settings['hash_salt'] = 'say \"hi\" \\path {{ DB_USER }}';" \
    "$hash_line"
  assertEquals 'unknown token that is present stays' \
    "\$settings['kept'] = '{{ NOT_A_KNOWN_VAR }}';" \
    "$kept_line"
  assertEquals 'comma in a value is literal' \
    "\$databases['default']['default']['password'] = 'a,b';" \
    "$pass_line"

  if command -v php >/dev/null 2>&1; then
    php_status=0
    php -l "$DRUPAL_SETTINGS_FILE" >/dev/null 2>&1 || php_status=$?
    assertEquals 'rendered settings file is valid PHP' '0' "$php_status"
  else
    echo "PENDING: php -l was not run because php is not installed." >&2
  fi

  f_fs_relative_path "$DRUPAL_FILES_DIR" "$SERVER_DOCROOT"
  assertEquals 'files dir is converted relative to the docroot' \
    "\$settings['file_public_path'] = '${relative_path}';" \
    "$files_line"
  f_fs_relative_path "$DRUPAL_CONFIG_SYNC_DIR" "$SERVER_DOCROOT"
  assertEquals 'config sync dir is converted relative to the docroot' \
    "\$settings['config_sync'] = '${relative_path}';" \
    "$sync_line"

  # PROVISION_USING is readonly after bootstrap. Ask the resolver for compose.
  f_global_list
  f_dwt_settings_resolve_token 'DRUPAL_FILES_DIR' 'compose'
  f_fs_relative_path "$DRUPAL_FILES_DIR_C" "$SERVER_DOCROOT_C"
  assertEquals 'compose files dir uses the _C path' \
    "$relative_path" "$token_value"
  f_dwt_settings_resolve_token 'DRUPAL_CONFIG_SYNC_DIR' 'compose'
  f_fs_relative_path "$DRUPAL_CONFIG_SYNC_DIR_C" "$SERVER_DOCROOT_C"
  assertEquals 'compose config sync dir uses the _C path' \
    "$relative_path" "$token_value"

  _dwt_token_render "a'b"
  pass_line="$(grep "password" "$DRUPAL_SETTINGS_FILE")"
  assertEquals 'single quote in a value is raw bytes' \
    "\$databases['default']['default']['password'] = 'a'b';" \
    "$pass_line"

  rm -rf "$root"
  unset dwt_token_template
  unset -f f_db_set f_db_vars_list f_global_list hook_ms
}

##
# A mode 0444 template is still rendered, and a refused chmod is not success.
#
test_dwt_settings_write_errors_are_not_success() {
  local root
  local status
  local output
  local hash_line

  root="$(mktemp -d "${TMPDIR:-/tmp}/asc-dwt-write.XXXXXX")"
  dwt_token_template="$root/settings.tpl.php"
  SERVER_DOCROOT="$root/web"
  DRUPAL_SETTINGS_FILE="$SERVER_DOCROOT/sites/default/settings.php"
  DRUPAL_FILES_DIR="$root/files"
  DRUPAL_CONFIG_SYNC_DIR="$root/config/sync"
  DWT_USE_SETTINGS_LOCAL_OVERRIDE=''
  DWT_MULTISITE=''
  ASC_DB_IDS=''
  FS_P_FILES='0644'
  mkdir -p "$SERVER_DOCROOT/sites/default" "$DRUPAL_FILES_DIR"
  printf '%s\n' '<?php' > "$SERVER_DOCROOT/sites/default/default.settings.php"
  printf '%s\n' "<?php" "\$settings['hash_salt'] = '{{ DRUPAL_HASH_SALT }}';" > "$dwt_token_template"
  chmod 0444 "$dwt_token_template"
  DRUPAL_HASH_SALT='say "hi" \path {{ DB_USER }}'

  f_db_set() {
    DB_USER='dbuser'
    DB_PASS='a,b'
  }

  f_db_vars_list() {
    db_vars_list='USER PASS'
  }

  f_global_list() {
    asc_globals_var_names_arr=('DRUPAL_HASH_SALT' 'DRUPAL_FILES_DIR' 'DRUPAL_CONFIG_SYNC_DIR')
  }

  hook_ms() {
    most_specific_match="$dwt_token_template"
  }

  status=0
  output="$(_dwt_token_render 'a,b' 2>&1)" || status=$?
  hash_line="$(grep "hash_salt" "$DRUPAL_SETTINGS_FILE")"
  assertEquals '0444 template still renders' '0' "$status"
  assertEquals '0444 template tokens are replaced' \
    "\$settings['hash_salt'] = 'say \"hi\" \\path {{ DB_USER }}';" \
    "$hash_line"
  assertTrue '0444 template reports done' "[[ \"\$output\" == *': done.'* ]]"

  chmod() {
    if [[ "$1" == 'u+w' && "$2" == "$DRUPAL_SETTINGS_FILE" ]]; then
      return 1
    fi

    command chmod "$@"
  }

  rm -f "$DRUPAL_SETTINGS_FILE"
  status=0
  output="$(f_dwt_write_drupal_settings 'default' 2>&1)" || status=$?
  assertTrue 'refused chmod is a failure' "[[ $status -ne 0 ]]"
  assertFalse 'refused chmod does not report done' "[[ \"\$output\" == *': done.'* ]]"
  assertTrue 'refused chmod leaves the copied template' \
    "grep -q '{{ DRUPAL_HASH_SALT }}' \"$DRUPAL_SETTINGS_FILE\""

  unset -f chmod f_db_set f_db_vars_list f_global_list hook_ms
  rm -rf "$root"
  unset dwt_token_template
}

##
# Standalone renders reread an edited template. A batch keeps one list per path.
#
test_dwt_settings_token_cache_stays_in_the_batch() {
  local root
  local path_a
  local path_b
  local path_empty
  local status

  root="$(mktemp -d "${TMPDIR:-/tmp}/asc-dwt-cache.XXXXXX")"
  path_a="$root/a.tpl.php"
  path_b="$root/b.tpl.php"
  path_empty="$root/empty.tpl.php"
  printf '%s\n' '{{ DRUPAL_HASH_SALT }}' > "$path_a"
  printf '%s\n' '{{ DB_PASS }}' > "$path_b"
  : > "$path_empty"

  f_dwt_settings_batch_begin
  f_dwt_settings_collect_tokens "$path_a"
  assertTrue 'batch reads the first template' \
    "[[ \"\$dwt_settings_token_names\" == *DRUPAL_HASH_SALT* ]]"
  chmod a-r "$path_a"
  status=0
  f_dwt_settings_collect_tokens "$path_a" || status=$?
  assertEquals 'batch does not reread the first template' '0' "$status"
  assertTrue 'cached names survive an unreadable file' \
    "[[ \"\$dwt_settings_token_names\" == *DRUPAL_HASH_SALT* ]]"

  f_dwt_settings_collect_tokens "$path_b"
  assertTrue 'batch reads a second template' \
    "[[ \"\$dwt_settings_token_names\" == *DB_PASS* ]]"
  f_dwt_settings_collect_tokens "$path_empty"
  assertEquals 'token-free template is cached as an empty list' '' "$dwt_settings_token_names"
  chmod a-r "$path_empty"
  status=0
  f_dwt_settings_collect_tokens "$path_empty" || status=$?
  assertEquals 'token-free template is not reread' '0' "$status"

  chmod u+r "$path_a"
  printf '%s\n' '{{ DB_USER }}' >> "$path_a"
  f_dwt_settings_collect_tokens "$path_a"
  assertFalse 'same batch keeps the first list for path A' \
    "[[ \"\$dwt_settings_token_names\" == *DB_USER* ]]"
  f_dwt_settings_batch_end

  f_dwt_settings_collect_tokens "$path_a"
  assertTrue 'standalone render reads the edited template' \
    "[[ \"\$dwt_settings_token_names\" == *DB_USER* ]]"

  rm -rf "$root"
}

##
# Current-site DB values, other-site names, ASC_DB_IDS, and SITE_* paths.
#
test_dwt_settings_db_ids_and_site_tokens() {
  local root
  local calls
  local user_line
  local news_line
  local extra_line
  local files_line
  local private_line
  local domain_line

  root="$(mktemp -d "${TMPDIR:-/tmp}/asc-dwt-sites.XXXXXX")"
  dwt_token_template="$root/settings.tpl.php"
  SERVER_DOCROOT="$root/web"
  DRUPAL_SETTINGS_FILE="$SERVER_DOCROOT/sites/default/settings.php"
  dwt_sites_news_dir='news'
  DWT_USE_SETTINGS_LOCAL_OVERRIDE=''
  DWT_MULTISITE='true'
  ASC_DB_IDS='extra'
  FS_P_FILES='0644'
  dwt_sites_ids_arr=('default' 'news')
  dwt_sites_news_domain='news.example'
  dwt_site_path_calls=0
  mkdir -p "$SERVER_DOCROOT/sites/news" "$SERVER_DOCROOT/sites/default" "$root/files" "$root/private"
  printf '%s\n' '<?php' > "$SERVER_DOCROOT/sites/default/default.settings.php"
  cat > "$dwt_token_template" <<'EOF'
<?php
$databases['default']['default']['username'] = '{{ DB_USER }}';
$databases['news']['default']['username'] = '{{ NEWS_DB_USER }}';
$databases['extra']['default']['username'] = '{{ EXTRA_DB_USER }}';
$settings['file_public_path'] = '{{ SITE_FILES_DIR }}';
$settings['file_private_path'] = '{{ SITE_PRIVATE_DIR }}';
$settings['domain'] = '{{ SITE_DOMAIN }}';
EOF

  f_db_vars_list() {
    db_vars_list='USER'
  }

  f_db_set() {
    DB_USER='default-user'
    NEWS_DB_USER='news-user'
    EXTRA_DB_USER='extra-user'

    case "$1" in
      news)
        DB_USER='news-user'
        ;;
    esac
  }

  f_global_list() {
    asc_globals_var_names_arr=()
  }

  hook_ms() {
    most_specific_match="$dwt_token_template"
  }

  f_dwt_get_sites_writeable_paths() {
    dwt_site_path_calls=$((dwt_site_path_calls + 1))
    dwt_sites_writeable_paths_arr=("$root/files" "$root/tmp" "$root/sync" "$root/private")
  }

  f_dwt_sites_yml_keys() {
    dwt_sites_yml_keys='domain'
  }

  f_dwt_write_drupal_settings 'news'
  calls="$dwt_site_path_calls"
  user_line="$(grep -F "['default']['default']['username']" "$SERVER_DOCROOT/sites/news/settings.php")"
  news_line="$(grep -F "['news']['default']['username']" "$SERVER_DOCROOT/sites/news/settings.php")"
  extra_line="$(grep -F "['extra']['default']['username']" "$SERVER_DOCROOT/sites/news/settings.php")"
  files_line="$(grep -F "file_public_path" "$SERVER_DOCROOT/sites/news/settings.php")"
  private_line="$(grep -F "file_private_path" "$SERVER_DOCROOT/sites/news/settings.php")"
  domain_line="$(grep -F "['domain']" "$SERVER_DOCROOT/sites/news/settings.php")"

  assertEquals 'current site DB_USER' \
    "\$databases['default']['default']['username'] = 'news-user';" \
    "$user_line"
  assertEquals 'other site DB name' \
    "\$databases['news']['default']['username'] = 'news-user';" \
    "$news_line"
  assertEquals 'ASC_DB_IDS token' \
    "\$databases['extra']['default']['username'] = 'extra-user';" \
    "$extra_line"
  f_fs_relative_path "$root/files" "$SERVER_DOCROOT"
  assertEquals 'SITE_FILES_DIR is relative' \
    "\$settings['file_public_path'] = '${relative_path}';" \
    "$files_line"
  assertEquals 'SITE_PRIVATE_DIR is the fourth writable path' \
    "\$settings['file_private_path'] = '${root}/private';" \
    "$private_line"
  assertEquals 'SITE_DOMAIN comes from the site field' \
    "\$settings['domain'] = 'news.example';" \
    "$domain_line"
  assertEquals 'writable paths are loaded once per site' '1' "$calls"

  rm -rf "$root"
  unset dwt_token_template dwt_sites_news_domain dwt_site_path_calls
  unset -f f_db_set f_db_vars_list f_global_list hook_ms f_dwt_get_sites_writeable_paths f_dwt_sites_yml_keys
}

. asc/vendor/shunit2/shunit2
