#!/usr/bin/env bash

##
# Lists available actions in the current project instance (and defines the
# helper used by other instance hooks).
#
# When executed as a script, prints sorted action names (subject/action).
# When sourced, only defines f_asc_get_actions() (expects ASC bootstrap already).
#
# @see Makefile
# @see asc/make/default.mk
# @see asc/instance/fs_perms_set.hook.sh
#
# @example
#   make list-actions
#   # Or :
#   asc/instance/list_actions.sh
#

##
# Aggregates subject/action scripts across ASC core and enabled extensions.
#
# Writes into calling scope:
# @var asc_action_names_arr
# @var asc_action_scripts_arr
#
# Optimized: walks each namespace's own ACTIONS under that namespace's base path
# only (no subjects × bases × actions cross-product).
#
f_asc_get_actions() {
  local extension
  local uppercase
  local actions_var
  local ext_path
  local a
  local lookup_path
  local -A seen_dict=()

  asc_action_names_arr=()
  asc_action_scripts_arr=()

  for a in $ASC_ACTIONS; do
    lookup_path="asc/${a}.sh"
    if [[ -f "$lookup_path" && -z "${seen_dict[$lookup_path]+x}" ]]; then
      seen_dict["$lookup_path"]=1
      asc_action_names_arr+=("$a")
      asc_action_scripts_arr+=("$lookup_path")
    fi
  done

  for extension in $ASC_EXTENSIONS; do
    uppercase="$extension"
    f_str_sanitize_var_name "$uppercase" 'uppercase'
    f_str_uppercase "$uppercase"
    actions_var="${uppercase}_ACTIONS"
    ext_path=''
    f_asc_extension_path "$extension"

    for a in ${!actions_var}; do
      lookup_path="$ext_path/$extension/${a}.sh"
      if [[ -f "$lookup_path" && -z "${seen_dict[$lookup_path]+x}" ]]; then
        seen_dict["$lookup_path"]=1
        asc_action_names_arr+=("$a")
        asc_action_scripts_arr+=("$lookup_path")
      fi
    done
  done
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh

  f_asc_get_actions
  f_array_qsort "${asc_action_names_arr[@]}"

  for val in "${sorted_arr[@]}"; do
    printf "%s\n" "$val"
  done
fi
