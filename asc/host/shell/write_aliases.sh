#!/usr/bin/env bash

##
# (over)Writes Shell aliases map to ASC entry points (ASC_HOST_SHELL_ALIASES).
#
# TODO [wip] untested.
#
# The map is $HOME/<plug>_asc. It is not under an instance data dir.
# $HOME does not have to be an ASC project.
#   .bash_aliases → $HOME/.bash_aliases_asc
#   .bashrc       → $HOME/.bashrc_asc
#   .profile      → $HOME/.profile_asc
#
# The argument is that plug under $HOME. It sources its own map, once.
# Default: .bash_aliases. Core does not choose among the three, and does
# not look at whether one startup file sources another.
#
# @example
#   # Plug defaults to $HOME/.bash_aliases :
#   make host-shell-write-aliases
#
#   # Its own map, $HOME/.bashrc_asc :
#   make host-shell-write-aliases '.bashrc'
#   make host-shell-write-aliases '.profile'
#   # Or :
#   asc/host/shell/write_aliases.sh '.bashrc'
#   asc/host/shell/write_aliases.sh '.profile'
#

. asc/bootstrap.sh

if [[ -z "$ASC_HOST_SHELL_ALIASES" ]]; then
  # TODO feedback
  exit
fi

p_shell_plug="$1"

if [[ -z "$p_shell_plug" ]]; then
  p_shell_plug='.bash_aliases'
fi

case "$p_shell_plug" in
  .bash_aliases|.bashrc|.profile)
    ;;
  *)
    echo "Plug must be .bash_aliases, .bashrc, or .profile (a file under \$HOME)." >&2
    exit 1
    ;;
esac

plug_path="$HOME/$p_shell_plug"

# The generated file containing the (mapped) aliases.
generated_aliases_path="$HOME/${p_shell_plug}_asc"

# One line, in the plug. The shell that sources the plug expands "~".
needle="[ -f ~/${p_shell_plug}_asc ] && . ~/${p_shell_plug}_asc"

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
      echo "Adding entry point $i to ~/${p_shell_plug}_asc :"
      echo "  task = $task"
      echo "  script = $script"

      # TODO run this relative script from the closest directory that contains it.
      aliases_sh_buf+="alias $task=$script"$'\n'
    esac
  done
done

printf '%s' "$aliases_sh_buf" > "$generated_aliases_path"

# Write the source line into the plug once. Other lines stay.
# f_str_append_once treats "[" as a pattern, so the search is a fixed string.
haystack=''

if [[ ! -f "$plug_path" ]]; then
  printf '%s\n' "$needle" > "$plug_path"
else
  f_fs_get_file_contents "$plug_path" 'haystack' || exit 1

  if ! grep -F -q -e "$needle" <<< "$haystack"; then
    if [[ -z "$haystack" ]]; then
      printf '%s\n' "$needle" > "$plug_path"
    else
      printf '%s\n%s\n' "$haystack" "$needle" > "$plug_path"
    fi
  fi
fi
