#!/usr/bin/env bash

##
# Filesystem-related utilities.
#
# This file contains functions dedicated to operations like copying,
# synchronizing, merging, etc.
#
# Convention : functions names are all prefixed by "f".
#

##
# Recursively merges 2 folders together.
#
# @param 1 String : the source dir.
# @param 2 String : the destination dir.
# @param 3 [optional] String : 'no' to prevent existing files from being
#   overwritten. Default value : 'yes' (overwrite in case of conflict).
# @param 4 [optional] String : 'no' to prevent the source dir from being deleted
#   after the merging is done. Default value : 'yes'.
#
# @example
#   # Overwriting existing destination files in target dir :
#   f_fs_merge_dirs my/src/dir the/target/dir
#
#   # Preserving existing destination files in target dir :
#   f_fs_merge_dirs my/src/dir the/target/dir 'no'
#
#   # Overwriting existing destination files in target dir + not deleting the
#   # source dir :
#   f_fs_merge_dirs my/src/dir the/target/dir 'yes' 'no'
#
#   # Preserving existing destination files in target dir + not deleting the
#   # source dir :
#   f_fs_merge_dirs my/src/dir the/target/dir 'no' 'no'
#
f_fs_merge_dirs() {
  local p_src="$1"
  local p_target="$2"
  local p_overwriting="$3"
  local p_remove_merged_src="$4"

  # Prerequisites checks.
  if [[ -z "$p_src" ]] || [[ ! -d "$p_src" ]] \
    || [[ -z "$p_target" ]] || [[ ! -d "$p_target" ]]
  then
    echo >&2
    echo "Error in f_fs_merge_dirs() - $BASH_SOURCE line $LINENO: invalid arguments." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # Default value for $3 : to overwrite existing files.
  if [[ -z "$p_overwriting" ]]; then
    p_overwriting='yes'
  fi

  # Default value for $4 : to delete the source dir afterwards.
  if [[ -z "$p_remove_merged_src" ]]; then
    p_remove_merged_src='yes'
  fi

  case "$p_overwriting" in
    # When overwriting existing files_arr, we can use the 'tar' program to create an
    # exact copy of the source tree with the owner and permissions intact, and
    # if the target folder exists, only files that are already existing will be
    # overwritten.
    # See https://unix.stackexchange.com/a/373475 (adapted to avoid subshell)
    y*|Y*)

      tar -C "$p_src" -cBf - . | tar -C "$p_target" -xBf -

      if [[ $? -ne 0 ]]; then
        echo >&2
        echo "Error in f_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to merge with file overwrite." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        return 2
      fi
      ;;

    # When not overwriting existing files_arr, we need to proceed file by file.
    *)
      local file_list=''
      local f=''
      local leaf=''
      local base_path=''

      f_fs_file_list "$p_src" '' '99'

      for f in $file_list; do
        # Skip corresponding file in target dir if it already exists.
        if [[ -f "$p_target/$f" ]]; then
          continue
        fi

        # Ensure destination dir exists.
        case "$f" in *'/'*)
          leaf="${f##*/}"
          base_path="${f%/$leaf}"

          mkdir -p "$p_target/$base_path"

          if [[ $? -ne 0 ]]; then
            echo >&2
            echo "Error in f_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to create target subdir '$p_target/$base_path'." >&2
            echo "-> Aborting (3)." >&2
            echo >&2
            return 3
          fi
        esac

        mv "$p_src/$f" "$p_target/$f"

        if [[ $? -ne 0 ]]; then
          echo >&2
          echo "Error in f_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to move file '$p_src/$f' to '$p_target/$f'." >&2
          echo "-> Aborting (4)." >&2
          echo >&2
          return 4
        fi
      done
      ;;
  esac

  # Finally, remove the merged source dir if requested ('yes' by default).
  case "$p_remove_merged_src" in y*|Y*)
    rm -rf "$p_src"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_fs_merge_dirs() - $BASH_SOURCE line $LINENO: unable to delete source dir '$p_src'." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      return 5
    fi
  esac
}
