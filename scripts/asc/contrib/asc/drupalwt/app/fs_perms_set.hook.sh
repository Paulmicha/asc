#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# Applies writeable permissions for multisite setups.
#
# This file is dynamically included when the "hook" is triggered.
# @see f_instance_set_permissions() in asc/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

case "$DWT_MULTISITE" in 'true')
  f_dwt_sites

  # Remember path|type|mode for this invocation only. A later run walks again.
  declare -A dwt_perms_seen_arr=()

  for site_id in "${dwt_sites_ids_arr[@]}"; do
    f_str_sanitize_var_name "$site_id" 'site_id'

    # The 'default' site should be done already (see WRITEABLE_DIRS and
    # PROTECTED_FILES globals).
    # @see asc/extensions/drupalwt/app/global.vars.sh
    case "$site_id" in 'default')
      continue
    esac

    dwt_sites_writeable_paths_arr=()
    f_dwt_get_sites_writeable_paths "$site_id"

    for writeable_dir in "${dwt_sites_writeable_paths_arr[@]}"; do
      # HACK : docker-compose projects may have subdirs where this returns many
      # errors we don't care about, so we prevent errors from polluting output.
      # (See docker-compose ownership issues).
      dwt_perms_seen_key="${writeable_dir}|f|${FS_W_FILES}"

      if [[ -z "${dwt_perms_seen_arr[$dwt_perms_seen_key]:-}" ]]; then
        dwt_perms_seen_arr["$dwt_perms_seen_key"]=1
        (\
          echo "Setting writeable file permissions $FS_W_FILES to files inside '$writeable_dir'" ; \
          find "$writeable_dir" -type f -exec chmod "$FS_W_FILES" {} + \
        ) 2> /dev/null
      fi

      dwt_perms_seen_key="${writeable_dir}|d|${FS_W_DIRS}"

      if [[ -z "${dwt_perms_seen_arr[$dwt_perms_seen_key]:-}" ]]; then
        dwt_perms_seen_arr["$dwt_perms_seen_key"]=1
        (\
          echo "Setting writeable dir permissions $FS_W_DIRS to '$writeable_dir'" ; \
          find "$writeable_dir" -type d -exec chmod "$FS_W_DIRS" {} + \
        ) 2> /dev/null
      fi
    done
  done

  for site_id in "${dwt_sites_ids_arr[@]}"; do
    dwt_perms_site_id="$site_id"
    f_str_sanitize_var_name "$site_id" 'site_id'

    case "$site_id" in 'default')
      continue
    esac

    # Same resolution as f_dwt_write_drupal_settings: sanitize the variable
    # name built from the original site id.
    site_dir='default'
    dwt_perms_site_dir_var="dwt_sites_${dwt_perms_site_id}_dir"
    f_str_sanitize_var_name "$dwt_perms_site_dir_var" 'dwt_perms_site_dir_var'

    if [[ -n "${!dwt_perms_site_dir_var}" ]]; then
      site_dir="${!dwt_perms_site_dir_var}"
    fi

    drupal_settings="$DRUPAL_SETTINGS_FILE"
    drupal_settings=${drupal_settings/'sites/default'/"sites/$site_dir"}

    if [[ -f "$drupal_settings" ]]; then
      protected_file="$drupal_settings"
      echo "Setting protected file permissions $FS_P_FILES to '$protected_file'"
      chmod "$FS_P_FILES" "$protected_file"
      check_chmod=$?

      if [ $check_chmod -ne 0 ]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      fi
    fi

    drupal_local_settings="$DRUPAL_SETTINGS_LOCAL_FILE"
    drupal_local_settings=${drupal_local_settings/'sites/default'/"sites/$site_dir"}

    if [[ -f "$drupal_local_settings" ]]; then
      protected_file="$drupal_local_settings"
      echo "Setting protected file permissions $FS_P_FILES to '$protected_file'"
      chmod "$FS_P_FILES" "$protected_file"
      check_chmod=$?

      if [ $check_chmod -ne 0 ]; then
        echo >&2
        echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
        echo "-> Aborting (3)." >&2
        echo >&2
        exit 3
      fi
    fi
  done

  unset dwt_perms_seen_arr dwt_perms_seen_key dwt_perms_site_id dwt_perms_site_dir_var
esac
