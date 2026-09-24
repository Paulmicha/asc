#!/usr/bin/env bash

##
# SSH-related Bash utilities.
#
# Convention : functions names are all prefixed by "f".
#

##
# Switches SSH keys (unloads all but the given subdir).
#
# When you work on the same host but some git remotes reject SSH keys when they
# all get loaded at the same time, you need to turn some on and off when
# switching projects.
#
# This utility makes possible to use subdirs inside ~/.ssh per "group" of keys
# to swap.
#
# @param 1 string : subdir.
#
f_ssh_switch_keys() {
  local subdir=''
  local subdir_name=''

  for subdir in "$HOME"/.ssh/*; do
    if [[ -d "$subdir" ]]; then
      subdir_name="${subdir##*/}"

      if [[ "$1" != "$subdir_name" ]]; then
        f_ssh_unload_keys "$subdir_name"
      fi
    fi
  done

  f_ssh_load_keys "$1"
}

##
# Loads SSH keys by subdir.
#
# @param 1 string : subdir.
#
f_ssh_load_keys() {
  f_ssh_manip_keys "$1" 'load'
}

##
# Unloads SSH keys by subdir.
#
# @param 1 string : subdir.
#
f_ssh_unload_keys() {
  f_ssh_manip_keys "$1" 'unload'
}

##
# Loads or Unloads SSH keys by subdir.
#
# @param 1 string : subdir.
# @param 2 string : load | unload.
#
f_ssh_manip_keys() {
  if [[ -z "$1" ]]; then
    echo >&2
    echo "Error in ssh_add_keys() - $BASH_SOURCE line $LINENO : missing subdir." >&2
    echo "Usage : ssh_add_keys 'foobar'" >&2
    echo >&2
    return 1
  fi

  local p_subdir="$1"

  if [[ ! -d "$HOME/.ssh/$p_subdir" ]]; then
    echo >&2
    echo "Error in ssh_add_keys() - $BASH_SOURCE line $LINENO : subdir $HOME/.ssh/$p_subdir does not exist." >&2
    echo "Aborting." >&2
    echo >&2
    return 2
  fi

  local p_op='load'

  if [[ -n "$2" ]]; then
    p_op="$2"
  fi

  local file=''

  # Prevents errors if no files match.
  shopt -s nullglob

  for file in "$HOME/.ssh/$p_subdir/"*; do
    if [[ ! -f "$file" || "$file" =~ \.pub ]]; then
      continue
    fi

    case "$p_op" in
      'load')
        echo "Loading $file ..."
        ssh-add "$file"
        ;;

      'unload')
        echo "Unloading $file ..."
        ssh-add -d "$file"
        ;;
    esac
  done

  # Restores default behavior.
  shopt -u nullglob

  ssh-add -L

  echo
}

##
# SSH-related files permissions (re)setter.
#
f_ssh_fix_perms() {
  chmod 700 ~/.ssh
  chmod 640 ~/.ssh/*
  chmod 600 ~/.ssh/id_* > /dev/null 2>&1

  # TODO [wip] deprecate hardcoded ~/Documents for this lookup ?
  find ~/Documents/* -iname \*.sshconfig -print0 | xargs -r0 chmod 640

  local file=''
  local subdir=''

  for subdir in "$HOME"/.ssh/*; do
    if [[ -d "$subdir" ]]; then
      chmod 700 "$subdir"

      for file in "$subdir"/*; do
        chmod 600 "$file"
      done
    fi
  done
}

##
# Generates a new key pair (ed25519).
#
# Uses the following env vars in calling scope :
# @var HOME : path to linux home dir, to point to the $HOME/.ssh dir.
# @var USERNAME : default value for ssh-keygen -C arg.
#
# @param 1 string : key pair files name suffix.
# @param 2 [optional] string : user (@). Defaults to "$USERNAME@linux".
#
# @example
#   # Generate ~/.ssh/id_ed25519_foobar + ~/.ssh/id_ed25519_foobar.pub :
#   f_ssh_key_generate 'foobar'
#
f_ssh_key_generate() {
  local user="$USERNAME@linux"
  local keys_base_name="$HOME/.ssh/id_ed25519"

  if [[ -z "$1" ]]; then
    echo >&2
    echo "Error: must pass key pair files name suffix as 1st argument." >&2
    echo "Usage : f_ssh_key_generate 'foobar'" >&2
    echo >&2
    return 1
  fi

  if [[ -n "$2" ]]; then
    user="$2"
  fi

  ssh-keygen -o -a 100 -t ed25519 -f "${keys_base_name}_$1" -C "$user"
}
