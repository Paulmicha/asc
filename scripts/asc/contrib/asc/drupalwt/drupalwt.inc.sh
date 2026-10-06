#!/usr/bin/env bash

##
# Docker4drupal utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# (re)Writes settings files where appropriate, e.g. :
#
# - sites/*/settings.php (copied from Drupal core default if non-existing)
# - sites/*/settings.local.php (if DWT_USE_SETTINGS_LOCAL_OVERRIDE = true)
# - sites/sites.php (if this is a multi-site setup)
#
# @requires the following globals in calling scope :
#   - DWT_MULTISITE
#   - DWT_MANAGE_SETTINGS_FILES
#
# @example
#   f_dwt_write_settings
#
f_dwt_write_settings() {
  # This call owns the token and DB-name caches. Standalone renders do not.
  f_dwt_settings_batch_begin

  # Multi-DB (manually set using the ASC_DB_IDS global) support.
  # It is necessary to load every prefixed DB var before (re)writing Drupal
  # settings in case those use multiple databases (thus need those vars loaded
  # already).
  # @see f_dwt_write_drupal_settings()
  local db_id=''
  for db_id in $ASC_DB_IDS; do
    f_db_set "$db_id"
  done

  case "$DWT_MULTISITE" in

    # Multi-site support.
    true)
      local site_id

      f_dwt_sites

      # Each site's DB is managed as a distinct DB_ID. First, we load every
      # site-specific prefixed DB var in order to export them all at once.
      # It is necessary to load every prefixed DB var before (re)writing Drupal
      # settings in case those use multiple databases (thus need those vars
      # loaded already).
      # @see f_dwt_write_drupal_settings()
      for site_id in "${dwt_sites_ids_arr[@]}"; do
        f_db_set "$site_id"
      done

      # (Re)write Drupal settings files (e.g. sites/*/settings.php) for every site.
      case "$DWT_MANAGE_SETTINGS_FILES" in true)
        for site_id in "${dwt_sites_ids_arr[@]}"; do
          f_dwt_write_drupal_settings "$site_id"
        done
      esac

      # (Re)write the multi-site declaration settings file (i.e. sites/sites.php).
      # TODO [evol] Support custom output file (i.e. sites/sites_local.php)
      # + base file ?
      case "$DWT_MANAGE_MULTISITE_SETTINGS_FILE" in true)
        f_dwt_write_multisite_settings
      esac
      ;;

    # "Normal" setups : just write the Drupal settings file.
    *)
      case "$DWT_MANAGE_SETTINGS_FILES" in true)
        f_dwt_write_drupal_settings
      esac
      ;;
  esac

  f_dwt_settings_batch_end
}

##
# Starts one settings-render batch and clears token, DB-name, and site-path caches.
#
# @var dwt_settings_batch
# @var dwt_settings_db_names
# @var dwt_settings_token_cache_arr
# @var dwt_settings_site_paths_key
# @var dwt_settings_site_paths_arr
#
f_dwt_settings_batch_begin() {
  dwt_settings_batch=1
  dwt_settings_db_names=''
  dwt_settings_site_paths_key=''
  unset dwt_settings_token_cache_arr
  unset dwt_settings_site_paths_arr
  declare -gA dwt_settings_token_cache_arr=()
}

##
# Ends the settings-render batch and drops its caches.
#
# @var dwt_settings_batch
# @var dwt_settings_db_names
# @var dwt_settings_token_cache_arr
# @var dwt_settings_site_paths_key
# @var dwt_settings_site_paths_arr
#
f_dwt_settings_batch_end() {
  dwt_settings_batch=0
  dwt_settings_db_names=''
  dwt_settings_site_paths_key=''
  unset dwt_settings_token_cache_arr
  unset dwt_settings_site_paths_arr
}

##
# Drops batch caches when this render is not inside f_dwt_write_settings.
#
# @var dwt_settings_db_names
# @var dwt_settings_token_cache_arr
# @var dwt_settings_site_paths_key
# @var dwt_settings_site_paths_arr
#
f_dwt_settings_standalone_reset() {
  if [[ "${dwt_settings_batch:-0}" -eq 1 ]]; then
    return 0
  fi

  dwt_settings_db_names=''
  dwt_settings_site_paths_key=''
  unset dwt_settings_token_cache_arr
  unset dwt_settings_site_paths_arr
  declare -gA dwt_settings_token_cache_arr=()
}

##
# Collects distinct {{ NAME }} tokens from one template.
#
# During a batch, each path is read once, including a template with no tokens.
# A standalone call reads the file again.
#
# @param 1 String : template path.
#
# @var dwt_settings_token_names
# @var dwt_settings_token_cache_arr
#
# @return
#   0 : names collected
#   1 : template is not readable
#
f_dwt_settings_collect_tokens() {
  local p_file="$1"
  local scan=''
  local found
  local token_re='\{\{ ([A-Za-z0-9_]+) \}\}'
  local -A seen_arr=()

  if [[ "${dwt_settings_batch:-0}" -eq 1 && -n "${dwt_settings_token_cache_arr[$p_file]+x}" ]]; then
    dwt_settings_token_names="${dwt_settings_token_cache_arr[$p_file]}"
    return 0
  fi

  if [[ ! -r "$p_file" ]]; then
    echo >&2
    echo "Error in f_dwt_settings_collect_tokens() - $BASH_SOURCE line $LINENO: cannot read '$p_file'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  IFS= read -r -d '' scan < "$p_file" || true
  dwt_settings_token_names=''

  while [[ "$scan" =~ $token_re ]]; do
    found="${BASH_REMATCH[1]}"

    if [[ -z "${seen_arr[$found]:-}" ]]; then
      seen_arr["$found"]=1
      dwt_settings_token_names+="$found "
    fi

    scan="${scan/"{{ $found }}"/}"
  done

  if [[ "${dwt_settings_batch:-0}" -eq 1 ]]; then
    dwt_settings_token_cache_arr["$p_file"]="$dwt_settings_token_names"
  fi
}

##
# Builds the DB token name list once per settings batch.
#
# A second call in the same batch returns the stored list.
#
# @var dwt_settings_db_names
#
f_dwt_settings_db_names() {
  local v=''
  local site_id=''
  local db_id=''
  local unique_db_ids_arr=()
  local db_vars=''

  if [[ -n "$dwt_settings_db_names" ]]; then
    return 0
  fi

  f_db_vars_list

  for v in $db_vars_list; do
    db_vars+="DB_${v} "
  done

  if [[ -n "${dwt_sites_ids_arr[*]:-}" ]]; then
    for site_id in "${dwt_sites_ids_arr[@]}"; do
      unique_db_ids_arr+=("$site_id")
      f_str_uppercase "$site_id" 'site_id'

      for v in $db_vars_list; do
        db_vars+="${site_id}_DB_${v} "
      done
    done
  fi

  for db_id in $ASC_DB_IDS; do
    if f_in_array "$db_id" unique_db_ids_arr; then
      continue
    fi

    unique_db_ids_arr+=("$db_id")
    f_str_uppercase "$db_id" 'db_id'

    for v in $db_vars_list; do
      db_vars+="${db_id}_DB_${v} "
    done
  done

  dwt_settings_db_names="$db_vars"
}

##
# Resolves one settings token to literal bytes.
#
# Writes $token_value and $token_resolved (1 when the name is a known global,
# DB field, or site field). An unknown name stays unresolved so the caller
# can leave the token in the file. The value is not scanned for further tokens.
#
# @param 1 String : token name.
# @param 2 [optional] String : provision mode. Defaults to $PROVISION_USING.
#   compose and docker-compose select the _C path variables.
#
# @var token_value
# @var token_resolved
#
f_dwt_settings_resolve_token() {
  local p_name="$1"
  local p_provision="${2:-$PROVISION_USING}"
  local g
  local var_val=''
  local var_name_c
  local db_name
  local multisite_key
  local multisite_var
  local candidate
  local i

  token_resolved=0
  token_value=''

  for g in "${asc_globals_var_names_arr[@]}"; do
    if [[ "$g" != "$p_name" ]]; then
      continue
    fi

    var_val="${!p_name-}"

    case "$p_name" in DRUPAL_FILES_DIR|DRUPAL_CONFIG_SYNC_DIR)
      if [[ "${var_val:0:1}" != '/' ]]; then
        var_val="$PROJECT_DOCROOT/$var_val"
      fi

      f_fs_relative_path "$var_val" "$SERVER_DOCROOT"
      var_val="$relative_path"
    esac

    case "$p_provision" in compose|docker-compose)
      var_name_c="${p_name}_C"

      if [[ -n "${!var_name_c-}" ]]; then
        var_val="${!var_name_c}"

        case "$var_name_c" in DRUPAL_FILES_DIR_C|DRUPAL_CONFIG_SYNC_DIR_C)
          if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
            var_val="$APP_DOCROOT_C/$var_val"
          fi

          f_fs_relative_path "$var_val" "$SERVER_DOCROOT_C"
          var_val="$relative_path"
        esac
      fi
    esac

    token_value="$var_val"
    token_resolved=1
    return 0
  done

  for db_name in $dwt_settings_db_names; do
    if [[ "$db_name" == "$p_name" ]]; then
      token_value="${!p_name-}"
      token_resolved=1
      return 0
    fi
  done

  case "$DWT_MULTISITE" in true)
    case "$p_name" in
      SITE_FILES_DIR|SITE_TMP_DIR|SITE_CONFIG_SYNC_DIR|SITE_PRIVATE_DIR)
        local site_path_names_arr=()
        site_path_names_arr+=('SITE_FILES_DIR')
        site_path_names_arr+=('SITE_TMP_DIR')
        site_path_names_arr+=('SITE_CONFIG_SYNC_DIR')
        site_path_names_arr+=('SITE_PRIVATE_DIR')

        f_dwt_settings_site_paths "$p_site" "$p_provision"

        for (( i = 0 ; i < ${#site_path_names_arr[@]} ; i++ )); do
          if [[ "${site_path_names_arr[$i]}" != "$p_name" ]]; then
            continue
          fi

          var_val="${dwt_sites_writeable_paths_arr[$i]}"

          case "$p_name" in SITE_FILES_DIR|SITE_CONFIG_SYNC_DIR)
            case "$p_provision" in
              compose|docker-compose)
                if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
                  var_val="$APP_DOCROOT_C/$var_val"
                fi

                f_fs_relative_path "$var_val" "$SERVER_DOCROOT_C"
                ;;
              *)
                if [[ "${var_val:0:1}" != '/' ]]; then
                  var_val="$PROJECT_DOCROOT/$var_val"
                fi

                f_fs_relative_path "$var_val" "$SERVER_DOCROOT"
                ;;
            esac

            var_val="$relative_path"
          esac

          token_value="$var_val"
          token_resolved=1
          return 0
        done
        ;;
    esac

    f_dwt_sites_yml_keys

    for multisite_key in $dwt_sites_yml_keys; do
      case "$multisite_key" in config_sync_dir)
        continue
      esac

      candidate="SITE_${multisite_key}"
      f_str_uppercase "$candidate" 'candidate'

      if [[ "$candidate" != "$p_name" ]]; then
        continue
      fi

      multisite_var="dwt_sites_${p_site}_${multisite_key}"
      f_str_sanitize_var_name "$multisite_var" 'multisite_var'
      token_value="${!multisite_var-}"
      token_resolved=1
      return 0
    done
  esac

  return 0
}

##
# Loads one site's four writable paths once per site and provision mode.
#
# @param 1 String : site id.
# @param 2 String : provision mode.
#
# @var dwt_sites_writeable_paths_arr
# @var dwt_settings_site_paths_key
# @var dwt_settings_site_paths_arr
#
f_dwt_settings_site_paths() {
  local p_site_id="$1"
  local p_provision="$2"
  local key="${p_site_id}|${p_provision}"

  if [[ "$dwt_settings_site_paths_key" == "$key" ]]; then
    dwt_sites_writeable_paths_arr=("${dwt_settings_site_paths_arr[@]}")
    return 0
  fi

  dwt_sites_writeable_paths_arr=()

  case "$p_provision" in
    compose|docker-compose)
      f_dwt_get_sites_writeable_paths "$p_site_id" 'dc'
      ;;
    *)
      f_dwt_get_sites_writeable_paths "$p_site_id"
      ;;
  esac

  dwt_settings_site_paths_key="$key"
  dwt_settings_site_paths_arr=("${dwt_sites_writeable_paths_arr[@]}")
}

##
# Substitutes known tokens in template text once.
#
# Reads $dwt_settings_token_names. Writes $dwt_settings_rendered.
# Inserted values are literal, including when they contain {{ NAME }}.
#
# @param 1 String : template text.
#
# @var dwt_settings_rendered
#
f_dwt_settings_apply_tokens() {
  local p_content="$1"
  local -A known_arr=()
  local -A values_arr=()
  local name
  local out=''
  local rest="$p_content"
  local before
  local body

  for name in $dwt_settings_token_names; do
    f_dwt_settings_resolve_token "$name"

    if [[ "$token_resolved" -eq 1 ]]; then
      known_arr["$name"]=1
      values_arr["$name"]="$token_value"
    fi
  done

  while [[ "$rest" == *'{{ '* ]]; do
    before="${rest%%\{\{ *}"
    out+="$before"
    rest="${rest#"$before"}"
    body="${rest#\{\{ }"
    name="${body%% \}\}*}"

    if [[ "$body" != "$name }}"* || "$name" == *' '* || "$name" == *'{{'* ]]; then
      out+='{{ '
      rest="${rest:3}"
      continue
    fi

    if [[ -n "${known_arr[$name]:-}" ]]; then
      out+="${values_arr[$name]}"
    else
      out+="{{ $name }}"
    fi

    rest="${body#"$name }}"}"
  done

  dwt_settings_rendered="${out}${rest}"
}

##
# (Re)writes Drupal local settings files.
#
# Creates or override the 'settings.local.php' file for local project instance
# based on the most specific "template" match found.
#
# Also replaces custom "token" values using the following convention, e.g. :
# '{{ DRUPAL_HASH_SALT }}' becomes "$DRUPAL_HASH_SALT" (value).
#
# @requires the following globals in calling scope :
#   - DRUPAL_VERSION
#   - DRUPAL_SETTINGS_FILE
#   - DRUPAL_SETTINGS_LOCAL_FILE
#   - DWT_USE_SETTINGS_LOCAL_OVERRIDE
#
# Uses the following variable in calling scope :
#   - dwt_sites_ids_arr (if available)
#
# To list matches & check which one will be used (the most specific) :
# $ p_site='my_site_id'
#   hook_ms 'dry-run' \
#     -s 'app' \
#     -a 'drupal_settings' \
#     -c 'tpl.php' \
#     -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE p_site' \
#     -t -d
#   echo "match = $most_specific_match"
#
f_dwt_write_drupal_settings() {
  local p_site="$1"
  local content=''
  local most_specific_match=''
  local write_status=0

  f_dwt_settings_standalone_reset

  if [[ -z "$p_site" ]]; then
    p_site='default'
  fi

  # Drupal settings template variants allow using separate files by site ID.
  hook_ms 'dry-run' \
    -s 'app' \
    -a 'drupal_settings' \
    -c 'tpl.php' \
    -v 'DRUPAL_VERSION HOST_TYPE INSTANCE_TYPE p_site' \
    -t

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$most_specific_match" ]]; then
    echo >&2
    echo "Error in f_dwt_write_settings() - $BASH_SOURCE line $LINENO: no Drupal settings template file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Get dir name from multi-site setup (if available).
  local site_dir='default'
  local site_dir_var="dwt_sites_${p_site}_dir"
  f_str_sanitize_var_name "$site_dir_var" 'site_dir_var'
  if [[ -n "${!site_dir_var}" ]]; then
    site_dir="${!site_dir_var}"
  fi

  # Adjust the file settings path according to $p_site.
  local drupal_default_settings="$DRUPAL_SETTINGS_FILE"
  drupal_default_settings=${drupal_default_settings/'sites/default'/"sites/$site_dir"}

  # Support using local settings overrides. It's the difference between writing
  # everything in the settings.php file, or keeping it versionned and having it
  # include a settings.local.php file (kept out of the project repo). That way
  # we can have a shared, common set of settings and only generate dynamically
  # the ones really specific to all the different instances, which can also
  # override anything from the settings.php file.
  local drupal_settings="$DRUPAL_SETTINGS_FILE"
  case "$DWT_USE_SETTINGS_LOCAL_OVERRIDE" in 1|y*|true)
    drupal_settings="$DRUPAL_SETTINGS_LOCAL_FILE"
  esac
  drupal_settings=${drupal_settings/'sites/default'/"sites/$site_dir"}

  # Skip step if Drupal app codebase isn't initialized yet.
  if [[ ! -f "$drupal_default_settings" ]] && [[ ! -f "$SERVER_DOCROOT/sites/default/default.settings.php" ]]; then
    return
  fi

  # Console feedback.
  echo "(Re)write Drupal local settings file ($drupal_settings) ..."
  echo "  using template : $most_specific_match ..."

  case "$DWT_USE_SETTINGS_LOCAL_OVERRIDE" in 1|y*|true)

    # If the "normal" settings file does not exist and we're using local settings
    # overrides, we're going to need the default settings file (thant includes the
    # override) -> create it from Drupal core default.settings.php.
    if [[ ! -f "$drupal_default_settings" ]]; then

      echo "  the required base file $drupal_default_settings doesn't exist"
      echo "    -> create one using Drupal core default.settings.php ..."

      cp "$SERVER_DOCROOT/sites/default/default.settings.php" "$drupal_default_settings"
      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to copy Drupal core default.settings.php to '$drupal_default_settings'." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      fi

      # Enable the settings.local.php override inside it.
      cat >> "$drupal_default_settings" <<'EOF'

// Load local development override configuration, if available.
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
EOF
      echo "    $drupal_default_settings sucessfully created, with settings.local.php override enabled."

      # Keep write-protection.
      chmod "$FS_P_FILES" "$drupal_default_settings"
      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status." >&2
        echo "-> Aborting (5)." >&2
        echo >&2
        exit 5
      fi

    # In case the file already exists, make sure it includes our override.
    # This is done by detecting the presence of the line doing the include
    # in order to avoid appending it more than once (idempotence).
    else
      local haystack
      f_fs_get_file_contents "$drupal_default_settings" 'haystack'
      if [[ -z "$haystack" ]] || [[ "$haystack" != *"/settings.local.php"* ]]; then
        # Avoid errors due to file permissions.
        chmod u+w "$drupal_default_settings"
        cat >> "$drupal_default_settings" <<'EOF'

// Load local development override configuration, if available.
if (file_exists($app_root . '/' . $site_path . '/settings.local.php')) {
  include $app_root . '/' . $site_path . '/settings.local.php';
}
EOF
      fi
    fi
  esac

  # Replace $drupal_settings file with the matching template and replace its
  # "token" values.
  if [[ -f "$drupal_settings" ]]; then
    rm -f "$drupal_settings"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to replace the file '$drupal_settings'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi

  # Avoid errors due to file permissions.
  chmod u+w "$SERVER_DOCROOT/sites/$site_dir"
  cp "$most_specific_match" "$drupal_settings"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: failed to copy template $most_specific_match to '$drupal_settings'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  # Start with read-only global vars (supports any global).
  if [[ "$(type -t f_global_list)" != function ]]; then
    # shellcheck disable=SC1091
    . asc/core/global.manual-inc.sh
  fi

  f_global_list

  # Names are stable for the batch. Values are resolved for this site only.
  f_db_set "$p_site"
  f_dwt_settings_db_names
  f_dwt_settings_collect_tokens "$most_specific_match"

  if [[ $? -ne 0 ]]; then
    exit 8
  fi

  if [[ ! -r "$drupal_settings" ]]; then
    echo >&2
    echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: cannot read '$drupal_settings'." >&2
    echo "-> Aborting (7)." >&2
    echo >&2
    exit 7
  fi

  content=''
  IFS= read -r -d '' content < "$drupal_settings" || true
  f_dwt_settings_apply_tokens "$content"

  # cp keeps the template mode. A 0444 template is not writable until this chmod.
  chmod u+w "$drupal_settings"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: cannot make '$drupal_settings' writable." >&2
    echo "-> Aborting (7)." >&2
    echo >&2
    exit 7
  fi

  printf '%s' "$dwt_settings_rendered" > "$drupal_settings"
  write_status=$?

  if [[ $write_status -ne 0 ]]; then
    echo >&2
    echo "Error in f_dwt_write_drupal_settings() - $BASH_SOURCE line $LINENO: cannot write '$drupal_settings' (status $write_status)." >&2
    echo "-> Aborting (7)." >&2
    echo >&2
    exit 7
  fi

  # Keep write-protection.
  f_instance_get_permissions
  chmod "$FS_P_FILES" "$drupal_settings"
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi

  echo "(Re)write Drupal local settings file ($drupal_settings) : done."
  echo
}

##
# Multi-site : gets sites configuration, optionally filtered by given site.
#
# If the following variable is defined in calling scope, it will be used to
# add lookup paths when loading the sites YAML definition file :
# @var dwt_remote_id
#
# This function writes its results to variables subject to collision in calling
# scope :
# @var dwt_sites_ids_arr
# @var dwt_sites_<SITE_ID>_domain
# @var dwt_sites_<SITE_ID>_dir
# @var dwt_sites_<SITE_ID>_install_profile
# @var dwt_sites_<SITE_ID>_config_sync_dir
# @var dwt_sites_<SITE_ID>_db_* (id, name, host, port, user, etc.)
#
# To list matches & check which one will be used (the most specific) :
# hook_ms 'dry-run' \
#   -s 'app' \
#   -a 'sites' \
#   -c 'yml' \
#   -v 'HOST_TYPE INSTANCE_TYPE' \
#   -t -r -d
# echo "match = $most_specific_match"
#
# Idem, but for a specific host remote ID :
# dwt_remote_id='preprod'
# hook_ms 'dry-run' \
#   -s 'app' \
#   -a 'sites' \
#   -c 'yml' \
#   -v 'HOST_TYPE INSTANCE_TYPE dwt_remote_id' \
#   -t -r -d
# echo "match = $most_specific_match"
#
# @example
#   # Get all sites config :
#   f_dwt_sites_yml_keys
#   f_dwt_sites
#   for site_id in "${dwt_sites_ids_arr[@]}"; do
#     for key in $dwt_sites_yml_keys; do
#       var="dwt_sites_${site_id}_${key}"
#       val="${!var}"
#       echo "${site_id}.${key} = '$val'"
#     done
#   done
#
#   # Get a single site config :
#   f_dwt_sites_yml_keys
#   f_dwt_sites 'my_site_id'
#   for key in $dwt_sites_yml_keys; do
#     var="dwt_sites_my_site_id_${key}"
#     val="${!var}"
#     echo "$key = '$val'"
#   done
#
#   # Get sites IDs only :
#   f_dwt_sites '*' 'ids_only'
#   echo "There are ${#dwt_sites_ids_arr[@]} sites defined in this local instance."
#   for site_id in "${dwt_sites_ids_arr[@]}"; do
#     echo "$site_id"
#   done
#
#   # Get all sites config for given remote ID :
#   dwt_remote_id='preprod'
#   f_dwt_sites
#
f_dwt_sites() {
  local p_site="$1"
  local p_want="$2"
  local dwt_vars_prefix='dwt_sites_'
  local sites_parsed_yaml_str=''
  local most_specific_match=''
  local hook_variants

  # Sites YAML definition variants must allow using separate files by remote ID.
  hook_variants='HOST_TYPE INSTANCE_TYPE'
  if [[ -n "$dwt_remote_id" ]]; then
    hook_variants='HOST_TYPE INSTANCE_TYPE dwt_remote_id'
  fi

  # Defaults to dealing with all sites.
  if [[ -z "$p_site" ]]; then
    p_site='*'
  fi

  hook_ms 'dry-run' \
    -s 'app' \
    -a 'sites' \
    -c 'yml' \
    -v "$hook_variants" \
    -t -r

  # Immediately empty the variable triggering remote sites lookups in case this
  # function gets called again without needing it.
  if [[ -n "$dwt_remote_id" ]]; then
    dwt_remote_id=''
  fi

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$most_specific_match" ]]; then
    echo >&2
    echo "Error in f_dwt_sites() - $BASH_SOURCE line $LINENO: no multi-sites declaration was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Use pseudo-memoization to reduce multiple calls impact.
  if [[ -n "$memoized_dwt_sites_parsed_yaml_str" ]] \
    && [[ -n "$memoized_dwt_sites_yaml_file" ]] \
    && [[ "$most_specific_match" == "$memoized_dwt_sites_yaml_file" ]]
  then
    sites_parsed_yaml_str="$memoized_dwt_sites_parsed_yaml_str"
  else
    f_yaml_parse "$most_specific_match" "$dwt_vars_prefix" 'sites_parsed_yaml_str'
    memoized_dwt_sites_parsed_yaml_str="$sites_parsed_yaml_str"
    memoized_dwt_sites_yaml_file="$most_specific_match"
  fi

  # Fetch only sites IDs (return early).
  case "$p_want" in 'ids_only')
    f_yaml_get_root_keys "$most_specific_match"
    dwt_sites_ids_arr=("${yaml_keys_arr[@]}")
    return
  esac

  case "$p_site" in

    # Deal with all sites.
    '*')
      eval "$sites_parsed_yaml_str"
      f_yaml_get_root_keys "$most_specific_match"
      dwt_sites_ids_arr=("${yaml_keys_arr[@]}")
      ;;

    # Deal with just one site (no point in getting site id in this case).
    *)
      local parsed_line
      local parsed_var
      local parsed_var_leaf
      while IFS= read -r parsed_line _; do
        parsed_var_leaf="=${parsed_line##*=}"
        parsed_var="${parsed_line%$parsed_var_leaf}"
        # Skip any line not matching prefix (by site).
        case "$parsed_line" in "${dwt_vars_prefix}${p_site}"*)
          eval "$parsed_line"
        esac
      done <<< "$sites_parsed_yaml_str"
      ;;

  esac
}

##
# Gets a single site data as an associative array (dictionary).
#
# This function writes its result to the following variable which MUST be preset
# in calling scope :
# @var dwt_site_data
#
# It will also attempt to use pre-existing dwt_sites_* variables if the site
# data was already loaded in current shell scope (i.e. avoids unnecessarily
# reloading sites.*.yml config files_arr).
#
# @example
#   declare -A dwt_site_data
#   f_dwt_site_data 'my_site_id'
#   echo "site dir = ${dwt_site_data[dir]}"
#
f_dwt_site_data() {
  local p_site="$1"
  local var
  local key
  local sub_key
  local domain_specificity
  local conflicting_domain_specificity
  local var_isset
  local data_keys

  dwt_site_data=()
  f_dwt_sites_yml_keys
  data_keys="$dwt_sites_yml_keys"

  # Avoid unnecessarily reloading sites.*.yml config files.
  # Considers the "dir" key as mandatory (this is the entry used to check if
  # that site's config was loaded already in current shell scope).
  var="dwt_sites_${p_site}_dir"
  f_str_sanitize_var_name "$var" 'var'
  eval "var_isset=\"\${$var+set}\"" # <- Variables may be set to empty strings.
  if [[ -z "$var_isset" ]]; then
    f_dwt_sites "$p_site"
  fi

  # Add DB vars.
  f_db_vars_list
  for var in $db_vars_list; do
    var="db_$var"
    f_str_sanitize_var_name "$var" 'var'
    f_str_lowercase "$var" 'var'
    data_keys+=" $var"
  done

  # Assemble.
  for key in $data_keys; do
    var="dwt_sites_${p_site}_${key}"
    f_str_sanitize_var_name "$var" 'var'
    eval "var_isset=\"\${$var+set}\"" # <- Variables may be set to empty strings.
    if [[ -n "$var_isset" ]]; then
      dwt_site_data[$key]="${!var}"
    else

      # Special case for 'domain' : when it's not found in YAML settings, we
      # look for a 'domains' key and its sub-items that match by the following
      # variants. This allows to conditionally apply different domains while
      # sharing the rest of the settings.
      # TODO generalize to all keys (singular / plural).
      # TODO conflict tipping : introduce sub-level to specify weight (e.g. "dev.2").
      case "$key" in 'domain')
        key='domains'
        f_str_subsequences "$HOST_TYPE $INSTANCE_TYPE" '_'

        for sub_key in $str_subsequences; do
          var="dwt_sites_${p_site}_${key}_${sub_key}"
          f_str_sanitize_var_name "$var" 'var'
          # echo "$var = '${!var}'"
          eval "var_isset=\"\${$var+set}\""
          if [[ -n "$var_isset" ]]; then
            # In case of multiple matching variants, take the most specific.
            if [[ -n "${dwt_site_data[domain]}" ]]; then
              f_str_split1 'domain_specificity' "$sub_key" '_'
              f_str_split1 'conflicting_domain_specificity' "${dwt_site_data[_domain_sub_key]}" '_'
              # echo "  conflict : [${dwt_site_data[_domain_sub_key]}] ${dwt_site_data[domain]} <- [$sub_key] ${!var}"
              if [[ ${#domain_specificity[@]} -gt ${#conflicting_domain_specificity[@]} ]]; then
                dwt_site_data[domain]="${!var}"
                dwt_site_data[_domain_sub_key]="$sub_key"
                # echo "    1set _domain_sub_key to $sub_key (${!var})"
              fi
            else
              dwt_site_data[domain]="${!var}"
              dwt_site_data[_domain_sub_key]="$sub_key"
              # echo "    2set _domain_sub_key to $sub_key (${!var})"
            fi
          fi
        done
      esac
    fi
  done
}

##
# (Re)writes the multi-site config file (i.e. sites/sites.php).
#
# @requires the variables from f_dwt_sites() in calling scope :
# @var dwt_sites_ids_arr
# @var dwt_sites_<SITE_ID>_*
#
# @param 1 [optional] String : base file to use. Gets copied before being
#   appended with the settings contents.
#   Defaults to "$SERVER_DOCROOT/sites/example.sites.php".
# @param 2 [optional] String : resulting file (output).
#   Defaults to "$SERVER_DOCROOT/sites/sites.php".
#
# @example
#   # Will use sites/example.sites.php as base, (re)writes sites/sites.php.
#   f_dwt_write_multisite_settings
#
#   # Customize base file
#   f_dwt_write_multisite_settings 'path/to/base/file'
#
#   # Customize resulting file.
#   f_dwt_write_multisite_settings '' "$SERVER_DOCROOT/sites/sites_local.php"
#
f_dwt_write_multisite_settings() {
  local base_file="$1"
  local target_file="$2"

  if [[ -z "$base_file" ]]; then
    base_file="$SERVER_DOCROOT/sites/example.sites.php"
  fi
  if [[ -z "$target_file" ]]; then
    target_file="$SERVER_DOCROOT/sites/sites.php"
  fi

  if [[ -f "$target_file" ]]; then
    rm -f "$target_file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_dwt_write_multisite_settings() - $BASH_SOURCE line $LINENO: unable to remove the multisite settings file to recreate '$target_file'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  if [[ -f "$base_file" ]]; then
    cp "$base_file" "$target_file"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_dwt_write_multisite_settings() - $BASH_SOURCE line $LINENO: unable to copy '$base_file' to '$target_file'." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
    echo "" >> "$target_file"
  else
    echo '<?php' > "$target_file"
    echo "" >> "$target_file"
  fi

  echo "(Re)write the multi-site settings file (i.e. $target_file) ..."

  local var
  local site_id
  local site_dir
  local site_domain

  for site_id in "${dwt_sites_ids_arr[@]}"; do
    # Sites' dir :
    var="dwt_sites_${site_id}_dir"
    f_str_sanitize_var_name "$var" 'var'
    site_dir="${!var}"
    # Sites' domain :
    var="dwt_sites_${site_id}_domain"
    f_str_sanitize_var_name "$var" 'var'
    site_domain="${!var}"
    if [[ -z "$site_domain" ]]; then
      site_domain="${site_id}.${INSTANCE_DOMAIN}"
    fi
    echo "\$sites['$site_domain'] = '$site_dir';" >> "$target_file"
  done

  echo "" >> "$target_file"

  echo "(Re)write the multi-site settings file (i.e. $target_file) : done."
  echo
}

##
# In a multi-site setup, given a singe site ID, returns writeable file paths.
#
# @param 1 String : the site ID.
# @param 2 [optional] String : wether or not to return the docker-compose
#   "aliases" of those vars. Any non-empty string can be passed. Defaults to
#   to an empty string, meaning : "I do not want the docker-compose version".
#   @see asc/extensions/drupalwt_d4d/app/global.compose.vars.sh
#
# This function writes its result to the following variable which MUST be preset
# in calling scope :
# @var dwt_sites_writeable_paths_arr
#
# Allows to get per-site values for the following globals :
# - DRUPAL_FILES_DIR
# - DRUPAL_TMP_DIR
# - DRUPAL_TRANSLATION_DIR # Update : this does not appear to be supported in settings file declaration -> commented out for now
# - DRUPAL_CONFIG_SYNC_DIR
# - DRUPAL_PRIVATE_DIR
# @see asc/extensions/drupalwt/app/global.vars.sh
#
# @example
#   # For local sites :
#   f_dwt_sites
#   for site_id in "${dwt_sites_ids_arr[@]}"; do
#     f_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths_arr=()
#     f_dwt_get_sites_writeable_paths "$site_id"
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths_arr[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
#   # For local sites, using the docker-compose version of the paths :
#   f_dwt_sites
#   for site_id in "${dwt_sites_ids_arr[@]}"; do
#     f_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths_arr=()
#     f_dwt_get_sites_writeable_paths "$site_id" 'dc'
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths_arr[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
#   # For remote sites - here, on the 'prod' remote instance :
#   dwt_remote_id='prod'
#   f_dwt_sites
#   for site_id in "${dwt_sites_ids_arr[@]}"; do
#     f_str_sanitize_var_name "$site_id" 'site_id'
#     dwt_sites_writeable_paths_arr=()
#     f_dwt_get_sites_writeable_paths "$site_id"
#     echo "Writeable_path for site '$site_id' :"
#     for writeable_path in "${dwt_sites_writeable_paths_arr[@]}"; do
#       echo "  $writeable_path"
#     done
#   done
#
f_dwt_get_sites_writeable_paths() {
  local p_site="$1"
  local p_dc_variants="$2"

  # local path_names='files_dir tmp_dir translation_dir config_sync_dir private_dir'
  local path_names='files_dir tmp_dir config_sync_dir private_dir'
  local path_val=''
  local site_dir=''
  local v=''

  for path_name in $path_names; do

    # In a multi-site setup, all of these paths may be set in the YAML sites
    # declarations, e.g. : sites.local.yml or sites.prod.yml in project docroot.
    v="dwt_sites_${p_site}_${path_name}"
    path_val="${!v}"

    if [[ -n "$path_val" ]]; then
      if [[ -n "$p_dc_variants" ]]; then
        # In the YAML sites declaration, for paths like the config sync dir,
        # it contains the APP_DOCROOT (otherwise the ensure_dirs_exist.hook.sh
        # would not be possible).
        # @see asc/extensions/drupalwt/app/ensure_dirs_exist.hook.sh
        # -> For docker-compose instances, we must convert it to a path relative
        # to APP_DOCROOT_C.
        # TODO limit this treatment to relative paths starting with APP_DOCROOT ?
        case "$path_name" in config_sync_dir)
          local to_remove="$APP_DOCROOT/"
          # echo "    to_remove = $to_remove (from path_val = $path_val)"
          path_val="${path_val/"$to_remove"/}"
          # echo "    -> result : path_val = $path_val"
        esac
      fi
      dwt_sites_writeable_paths_arr+=("$path_val")
    else
      # In the absence of specific paths defined in sites' YAML files_arr, fallback
      # to replace all 'sites/default' bits from the defaults.
      v="dwt_sites_${p_site}_dir"
      site_dir="${!v}"

      if [[ -z "$site_dir" ]]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: missing a site dir for '$p_site'." >&2
        echo "-> Aborting (1)." >&2
        echo >&2
        exit 1
      fi

      v="DRUPAL_${path_name}"
      if [[ -n "$p_dc_variants" ]]; then
        v="DRUPAL_${path_name}_C"
      fi
      f_str_uppercase "$v" 'v'
      path_val="${!v}"

      if [[ -n "$path_val" ]]; then
        # Drupal multi-site paths in the 'sites' dir all get the same treatment.
        # TODO exclude paths not matching 'sites/default/'.
        dwt_sites_writeable_paths_arr+=(${path_val/'sites/default/'/"sites/$site_dir/"})
      fi
    fi
  done
}

##
# TODO [minor] use readonly global constant instead.
#
# Single source of truth : get the list of multi-site config file keys.
#
# This funtion writes its result to a variable subject to collision in calling
# scope :
# @var dwt_sites_yml_keys
#
# @example
#   f_dwt_sites_yml_keys
#   echo "$dwt_sites_yml_keys"
#
f_dwt_sites_yml_keys() {
  dwt_sites_yml_keys='domain dir install_profile config_sync_dir config_split'
}
