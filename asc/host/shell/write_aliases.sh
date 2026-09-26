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

if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
  echo "HOME is unset or not a directory. No map written." >&2
  exit 1
fi

if [[ -z "$ASC_HOST_SHELL_ALIASES" ]]; then
  echo "ASC_HOST_SHELL_ALIASES is empty. No map written." >&2
  exit 1
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
  case "$short_alias" in
    ''|*[!a-zA-Z0-9_-]*)
      echo "Skipping '$short_alias': not a pivot name." >&2
      continue
      ;;
  esac

  matched=''
  for i in "${!real_scripts_arr[@]}"; do
    task="${pivots_arr[i]}"
    script="${real_scripts_arr[i]}"

    [[ "$task" == "$short_alias" ]] || continue
    matched=1

    if [[ "$script" == "asc/instance/${short_alias}.sh" ]]; then
      echo "Adding $short_alias ($script) to ~/${p_shell_plug}_asc"
      # TODO run this relative script from the closest directory that contains it.
      aliases_sh_buf+="alias $task=$script"$'\n'
    else
      echo "Skipping $short_alias: script is $script, not asc/instance/${short_alias}.sh." >&2
    fi
    break
  done

  if [[ -z "$matched" ]]; then
    echo "Skipping $short_alias: no entry point with that name." >&2
  fi
done

if [[ -z "$aliases_sh_buf" ]]; then
  echo "No instance alias to write. Map left unchanged." >&2
  exit 1
fi

if ! printf '%s' "$aliases_sh_buf" > "$generated_aliases_path"; then
  echo "Could not write $generated_aliases_path." >&2
  exit 1
fi

# Write the source line into an existing plug, once. Never create the plug.
# f_str_append_once treats "[" as a pattern, so the search is a fixed string.
haystack=''

if [[ ! -f "$plug_path" ]]; then
  echo "Plug $plug_path does not exist. Map written. Plug left unchanged." >&2
else
  f_fs_get_file_contents "$plug_path" 'haystack' || exit 1

  if ! grep -F -q -e "$needle" <<< "$haystack"; then
    if [[ -z "$haystack" ]]; then
      if ! printf '%s\n' "$needle" > "$plug_path"; then
        echo "Could not write $plug_path." >&2
        exit 1
      fi
    else
      if ! printf '%s\n%s\n' "$haystack" "$needle" > "$plug_path"; then
        echo "Could not write $plug_path." >&2
        exit 1
      fi
    fi
  fi
fi
