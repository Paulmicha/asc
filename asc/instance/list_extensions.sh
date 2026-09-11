#!/usr/bin/env bash

##
# Lists ASC extensions.
#
# @param 1 [optional] String - either :
#   - 'all' | 'a' : list every single extensions,
#   - 'enabled' | 'e' : only enabled extensions,
#   - 'disabled' | 'd' : only disabled extensions.
#   Defaults to 'enabled'.
#
# When executed as a script, bootstraps ASC and prints one identity per line.
# When sourced, only defines f_asc_get_extensions() (expects bootstrap).
#
# @example
#   # List enabled extensions only (default) :
#   make list-extensions
#   # Or :
#   asc/instance/list_extensions.sh
#
#   # List all extensions (enabled + disabled) :
#   make list-extensions 'a'
#   make list-extensions 'all'
#   # Or :
#   asc/instance/list_extensions.sh 'a'
#   asc/instance/list_extensions.sh 'all'
#
#   # List disabled extensions only :
#   make list-extensions 'd'
#   make list-extensions 'disabled'
#   # Or :
#   asc/instance/list_extensions.sh 'd'
#   asc/instance/list_extensions.sh 'disabled'
#

##
# Collects discovered extension identities for the requested filter.
#
# Writes into calling scope:
# @var asc_extensions_list_arr
#
# @param 1 [optional] String : 'all'|'a', 'enabled'|'e', or 'disabled'|'d'.
#   Defaults to 'enabled'.
#
f_asc_get_extensions() {
  local p_filter="$1"
  local extension
  local ignored
  local extensions_ignore_arr
  local discovered_extensions

  case "$p_filter" in
    ''|e|enabled)
      p_filter='enabled'
      ;;
    a|all)
      p_filter='all'
      ;;
    d|disabled)
      p_filter='disabled'
      ;;
    *)
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: invalid extensions filter '$p_filter'." >&2
      echo "Use 'all' (a), 'enabled' (e), or 'disabled' (d)." >&2
      echo >&2
      return 1
      ;;
  esac

  asc_extensions_list_arr=()
  f_asc_extensions_ignore_load
  f_asc_extensions_discover

  for extension in $discovered_extensions; do
    ignored=0

    if f_asc_extension_ignored "$extension"; then
      ignored=1
    fi

    case "$p_filter" in
      all)
        asc_extensions_list_arr+=("$extension")
        ;;
      enabled)
        if [[ $ignored -eq 0 ]]; then
          asc_extensions_list_arr+=("$extension")
        fi
        ;;
      disabled)
        if [[ $ignored -eq 1 ]]; then
          asc_extensions_list_arr+=("$extension")
        fi
        ;;
    esac
  done
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh

  f_asc_get_extensions "$1" || exit $?
  f_array_qsort "${asc_extensions_list_arr[@]}"

  for val in "${sorted_arr[@]}"; do
    printf "%s\n" "$val"
  done
fi
