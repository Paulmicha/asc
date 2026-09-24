#!/usr/bin/env bash

##
# (over)Writes Shell aliases map to ASC entry points (ASC_HOST_SHELL_ALIASES).
#
# TODO [wip] must write once the one line where generated aliases are sourced :
# @see data/asc/aliases.sh
# @see data/asc/aliases.bash.sh
# @see data/asc/aliases.dash.sh
#
# TODO untested. Wip.
#
# @example
#   make host-shell-write-aliases '~/.bashrc'
#   make host-shell-write-aliases '~/.profile'
#   make host-shell-write-aliases '~/.bash_aliases'
#   # Or :
#   asc/host/shell/write_aliases.sh '~/.bashrc'
#   asc/host/shell/write_aliases.sh '~/.profile'
#   asc/host/shell/write_aliases.sh '~/.bash_aliases'
#

. asc/bootstrap.sh

if [[ -z "$ASC_HOST_SHELL_ALIASES" ]]; then
  # TODO feedback
  exit
fi

p_shell_plug="$1"
p_shell_type="$2"

if [[ -z "$p_shell_plug" ]]; then
  # TODO feedback
  p_shell_plug='~/.bash_aliases'
  # else
  # TODO input sanitizing
fi

if [[ -z "$p_shell_type" ]]; then
  # TODO feedback
  p_shell_type='bash'
  # else
  # TODO input sanitizing
fi

# Read entry points mapping to scripts.
pivots_arr=()
real_scripts_arr=()

f_make_list_entry_points

# Maps global shell aliases to real scripts paths.
pivot=''
short_alias=''
aliases_sh_buf=''

# ASC_HOST_SHELL_ALIASES defaults to 'ds gu gmp gacp ssk'.
# @see asc/core/global.vars.sh
for short_alias in $ASC_HOST_SHELL_ALIASES; do
  for i in "${!real_scripts_arr[@]}"; do
    task="${pivots_arr[i]}"
    script="${real_scripts_arr[i]}"

    case "$task" in "$short_alias")
      echo "Adding entry point $i to data/asc/aliases.${p_shell_type}.sh :"
      echo "  task = $task"
      echo "  script = $script"

      aliases_sh_buf+="alias $task=$script"$'\n'
    esac
  done
done

printf '%s' "$aliases_sh_buf" > "data/asc/aliases.${p_shell_type}.sh"

# TODO [wip] must write once the line where generated aliases are sourced inside
# either .bashrc or .profile.

needle="[ -f data/asc/aliases.${p_shell_type}.sh ] && \. data/asc/aliases.${p_shell_type}.sh"
file_path="$p_shell_plug"
haystack=''
new_str=''

f_fs_get_file_contents "$p_file_path" 'haystack'

if [[ -z "$haystack" ]]; then
  echo "$p_needle" > "$p_file_path"
else
  f_str_append_once $'\n'"$p_needle" "$haystack" 'new_str'

  if [[ "$new_str" != "$haystack" ]]; then
    echo "$new_str" > "$p_file_path"
  fi
fi
