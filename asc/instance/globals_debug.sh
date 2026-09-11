#!/usr/bin/env bash

##
# Prints aggregated globals and their metadata (debug).
#
# When executed as a script, bootstraps ASC and prints (dry-run aggregate if
# needed via normal bootstrap globals load).
# When sourced, only defines f_global_debug().
#
# @see f_instance_init() dry-run path
# @see global()
#
# @example
#   asc/instance/globals_debug.sh
#

##
# [debug] Prints current environment globals and their associated data.
#
f_global_debug() {
  local global_name
  local globals_arr
  local key
  local val

  echo
  echo "Defined globals :"
  echo

  for global_name in ${GLOBALS['.sorting']}; do
    f_str_split1 'globals_arr' "$global_name" '|'
    global_name="${globals_arr[1]}"

    if [[ -z "${!global_name}" ]]; then
      echo "$global_name (empty)"
    else
      echo "$global_name = ${!global_name}"
    fi

    for key in "${GLOBALS_UNIQUE_KEYS[@]}"; do
      val="${GLOBALS[$global_name|$key]}"
      if [[ -n "$val" ]]; then
        echo "  - ${key} = ${val}"
      fi
    done
  done

  echo
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_global_debug
fi
