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

  # Bootstrap only loads data/asc/global.vars.sh values. The GLOBALS metadata
  # array is filled during instance init / f_global_aggregate(). Direct script
  # runs need a dry-run aggregate so ${GLOBALS['.sorting']} is valid.
  # @see f_global_list()
  if [[ ${GLOBALS_COUNT:-0} -eq 0 ]]; then
    declare -A GLOBALS
    GLOBALS_COUNT=0
    GLOBALS_UNIQUE_NAMES=()
    GLOBALS_UNIQUE_KEYS=()
    GLOBALS_DEFERRED=()
    GLOBALS['.defer-max']=0
    GLOBALS_DRY_RUN=1
    . asc/env/global.vars.sh
    f_global_aggregate
  fi

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
