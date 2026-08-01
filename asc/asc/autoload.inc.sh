#!/usr/bin/env bash

##
# Autoloading-related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Allows to optionally replace or bypass a default script include (sourcing).
#
# Checks if its counterpart exists in scripts/overrides, and if it does,
# return the code that will source it and return early in main shell.
#
# This function works by populating a variable named inc_override_evaled_code
# with code to be evaluated (see examples below).
#
# Using 'eval' allows this function to act in main shell scope, which we need
# in order to have "return" executed in current shell (to prevent running the
# rest of the calling script).
#
# @var inc_override_evaled_code
#
# @param 1 String the original file include path relative to PROJECT_DOCROOT.
# @param 2 [optional] String the statement to use when an override is found.
# @param 3 [optional] String custom statement allowing to react differently.
#
# @see f_asc_extensions()
# @see asc/bootstrap.sh
#
# @example
#   # Default behavior : source override match (if exists) and return early.
#   f_autoload_override "$BASH_SOURCE"
#   eval "$inc_override_evaled_code"
#
#   # Break a lookup loop if an override is found.
#   for prov_model in "${PROV_INCLUDES_LOOKUP_PATHS[@]}"; do
#     if [[ -f "$prov_model" ]]; then
#       f_autoload_override "$prov_model" 'continue'
#       eval "$inc_override_evaled_code"
#       # (snip) rest goes here - only executed if no matching override is found.
#     fi
#   done
#
#   # Only get the override filepath to customize reaction.
#   local override_file=''
#   local extensions_declaration="asc/asc_extensions.txt"
#   f_autoload_override "$extensions_declaration" '' 'override_file="$override"'
#   eval "$inc_override_evaled_code"
#   if [[ -n "$override_file" ]]; then
#     echo "An override has been found : $override_file"
#   fi
#
f_autoload_override() {
  local a_script_path="$1"
  local a_operand="$2"
  local a_reaction="$3"

  local operand='return'
  local base_dir='scripts'
  local override=${a_script_path/asc/"$base_dir/overrides"}

  if [[ -n "$a_operand" ]]; then
    operand="$a_operand"
  fi

  inc_override_evaled_code=''

  if [[ -f "$override" ]]; then
    # Allows to react to the presence of an override differently.
    if [[ -n "$a_reaction" ]]; then
      inc_override_evaled_code="$a_reaction"
    # Normal behavior (see examples in function docblock).
    else
      inc_override_evaled_code=". $override ; $operand"
    fi
  fi
}

##
# [debug] Prints aggregated lookup paths.
#
# @see asc/stack/init/aggregate_env_vars.sh
#
# @example
#   f_autoload_print_lookup_paths DEPS_LOOKUP_PATHS "App dependencies"
#   f_autoload_print_lookup_paths GLOBALS_INCLUDES_PATHS "Env includes"
#
f_autoload_print_lookup_paths() {
  local a_arr=${1}[@]
  local a_title="$2"

  echo
  echo "$a_title lookup paths :"
  echo

  local path
  for path in ${!a_arr}; do
    echo "$path"
    if [[ -f "$path" ]]; then
      echo "  exists"
    fi
  done
  echo
}

##
# Adds dynamic lookup paths with or without version suffix.
#
# TODO remove or document numerical suffix handling, e.g. :
#   name-2.3 -> [name, name-2, name-2.3]
#
# @see f_hook_build_lookup_by_subject()
# @see f_hook_build_project_root_dir_lookup()
#
# @example
#   # Add entries in the 'lookup_paths_arr' array as in hooks' lookups,
#   # e.g. : pre_bootstrap.compose.hook.sh
#   for x_val in $prefixes; do
#     for v_val in $str_subsequences; do
#       f_autoload_add_lookup_level "${x_val}_${a}." "$suffix" "$v_val" lookup_paths_arr
#     done
#   done
#
f_autoload_add_lookup_level() {
  local a_prefix="$1"
  local a_suffix="$2"
  local a_name="$3"
  local a_lookups_var_name="$4"
  local a_extra_level_name="$5"
  local a_sep="$6"

  local sep="."
  if [[ -n "$a_sep" ]]; then
    sep="$a_sep"
  fi

  local name_version_arr=()
  f_autoload_item_split_version name_version_arr "$a_name"

  if [[ -n "${name_version_arr[1]}" ]]; then
    f_array_add_once "${a_prefix}${name_version_arr[0]}.${a_suffix}" $a_lookups_var_name

    if [[ -n "$a_extra_level_name" ]]; then
      f_autoload_add_lookup_level "${a_prefix}${name_version_arr[0]}." $a_suffix $a_extra_level_name $a_lookups_var_name
    fi

    local v
    local path="${a_prefix}${name_version_arr[0]}-"
    local version_arr=()

    f_str_split1 'version_arr' "${name_version_arr[1]}" '.'

    for v in "${version_arr[@]}"; do
      path+="${v}${sep}"
      f_array_add_once "${path}${a_suffix}" $a_lookups_var_name

      if [[ -n "$a_extra_level_name" ]]; then
        f_autoload_add_lookup_level "${path}" $a_suffix $a_extra_level_name $a_lookups_var_name
      fi
    done

  else
    f_array_add_once "${a_prefix}${a_name}${sep}${a_suffix}" $a_lookups_var_name

    if [[ -n "$a_extra_level_name" ]]; then
      f_autoload_add_lookup_level "${a_prefix}${a_name}${sep}" $a_suffix $a_extra_level_name $a_lookups_var_name
    fi
  fi
}

##
# Separates an env item name from its version number.
#
# Follows a simplistic syntax : inputting 'app_test_a-name-test-1.2'
# -> output ['app_test_a-name-test', '1.2']
#
# @param 1 The variable name that will contain the array (in calling scope).
# @param 2 String to separate.
#
# @example
#   f_autoload_item_split_version env_item_arr 'app_test_a-name-test-1.2'
#   for item_part in "${env_item_arr[@]}"; do
#     echo "$item_part"
#   done
#
f_autoload_item_split_version() {
  local a_var_name="$1"
  local a_str="$2"

  eval "${a_var_name}=()"

  local version_part="${a_str##*-}"

  # If last part doesn't match only numbers and dots, just return [$a_str].
  if [[ ! "$version_part" =~ [0-9.]+$ ]]; then
    eval "${a_var_name}+=(\"$a_str\")"
    return
  fi

  local name_part="${a_str%-*}"

  if [[ -n "$name_part" ]]; then
    eval "${a_var_name}+=(\"$name_part\")"
  fi

  if [[ -n "$version_part" ]] && [[ "$version_part" != "$name_part" ]]; then
    eval "${a_var_name}+=(\"$version_part\")"
  fi
}
