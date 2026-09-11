#!/usr/bin/env bash

##
# Lists Makefile includes provided by enabled ASC extensions.
#
# Default location per extension: make.mk inside the extension folder.
# Only paths that exist are listed (space-separated).
#
# When executed as a script, bootstraps ASC and prints the list.
# When sourced, only defines f_asc_extensions_get_makefiles() (expects bootstrap).
#
# @see asc/env/global.vars.sh (ASC_MAKE_INC)
# @see f_make_generate()
#
# @example
#   make list-makefiles
#   # Or :
#   asc/instance/list_makefiles.sh
#
#   # Or after bootstrap :
#   . asc/instance/list_makefiles.sh
#   f_asc_extensions_get_makefiles 'mk_includes'
#   echo "$mk_includes"
#

##
# Collects existing extension make.mk paths into a caller variable (or stdout).
#
# @param 1 [optional] String : output var name. Defaults to printing on stdout.
#
f_asc_extensions_get_makefiles() {
  local p_output_var_name="$1"
  local mk_includes_lp=''
  local asc_gm_ext=''
  local ext_path=''
  local mk_file=''

  for asc_gm_ext in $ASC_EXTENSIONS; do
    ext_path=''
    f_asc_extension_path "$asc_gm_ext"
    mk_file="$ext_path/$asc_gm_ext/make.mk"

    if [[ -f "$mk_file" ]]; then
      mk_includes_lp+="$mk_file "
    fi
  done

  if [[ -n "$p_output_var_name" ]]; then
    printf -v "$p_output_var_name" '%s' "$mk_includes_lp"
  else
    printf '%s' "$mk_includes_lp"
  fi
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_asc_extensions_get_makefiles
  printf '\n'
fi
