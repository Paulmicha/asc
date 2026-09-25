#!/usr/bin/env bash

##
# Filesystem (fs) related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/core/utils.manual-inc.sh
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Recursively gets the last N most recent file(s) in given path.
#
# @param 1 [optional] String : the dir where to look.
#   Defaults to '.' (PROJECT_DOCROOT).
# @param 2 [optional] String : file name filter pattern.
#   Defaults to '', meaning : don't filter.
# @param 3 [optional] Number : max depth (to look in subfolders too).
#   Defaults to 1.
# @param 4 [optional] Number : how many most recent files to get.
#   Defaults to 1.
# @param 5 [optional] String : output var name (default: fs_most_recent).
#
# @see https://stackoverflow.com/questions/4561895/how-to-recursively-find-the-latest-modified-file-in-a-directory
#
# @example
#   # Gets the last modified file in current dir (PROJECT_DOCROOT) :
#   f_fs_get_most_recent
#   echo "most_recent_file = $fs_most_recent"
#
#   # Gets the last modified file in path 'asc' :
#   f_fs_get_most_recent 'asc' '' '' '' 'most_recent'
#   echo "most_recent = $most_recent"
#
#   # Gets the last modified '*.yml' file in path 'scripts' :
#   f_fs_get_most_recent 'scripts' '*.yml' '' '' 'most_recent'
#   echo "most_recent = $most_recent"
#
#   # Gets the last 3 files modified in path 'asc' up to 5 dir deep :
#   f_fs_get_most_recent 'asc' '' 5 3 'recent_files'
#   while read -r file; do
#     echo "$file"
#   done <<< "$recent_files"
#
f_fs_get_most_recent() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_max_depth="$3"
  local p_n_files="$4"
  local p_output_var_name="${5:-fs_most_recent}"
  local result=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ -z "$p_max_depth" ]]; then
    p_max_depth=1
  fi

  if [[ -z "$p_n_files" ]]; then
    p_n_files=1
  fi

  if [[ -n "$p_filter_pattern" ]]; then
    result="$(find "$p_path" -maxdepth "$p_max_depth" -type f -name "$p_filter_pattern" -exec ls -1t '{}' + \
      | head -n"$p_n_files")"
  else
    result="$(find "$p_path" -maxdepth "$p_max_depth" -type f -exec ls -1t '{}' + \
      | head -n"$p_n_files")"
  fi

  printf -v "$p_output_var_name" '%s' "$result"
}

##
# Reads file contents (without using subshell).
#
# @see https://stackoverflow.com/questions/7427262/how-to-read-a-file-into-a-variable-in-shell
#
# @example
#   my_file_contents=''
#   f_fs_get_file_contents 'asc/.asc_subjects_ignore' 'my_file_contents'
#   echo "$my_file_contents"
#
f_fs_get_file_contents() {
  local p_file_path="$1"
  local p_var_name="$2"

  if [[ ! -f "$p_file_path" ]]; then
    echo >&2
    echo "Error in f_fs_get_file_contents() - $BASH_SOURCE line $LINENO: file '$p_file_path' was not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_str_sanitize_var_name "$p_var_name" 'p_var_name'

  # Whole-file read without fork. Avoid $(<file) / $(cat …): command substitution
  # strips trailing newlines. read -d '' stops at EOF for normal text files.
  local contents=''
  IFS= read -r -d '' contents < "$p_file_path" || true

  printf -v "$p_var_name" '%s' "$contents"
}

##
# Appends relative file or directory names to an array in the calling scope.
#
# Depth 1 globs in-process. A greater depth uses find and mapfile. Each
# element is one path, so names may contain spaces. Does not clear the array.
#
# @param 1 String 'f' or 'd'.
# @param 2 String array name in the calling scope.
# @param 3 [optional] String base path (defaults to '.').
# @param 4 [optional] String name filter pattern (defaults to no filter).
# @param 5 [optional] Integer max depth (defaults to 1).
#
f_fs_list_append() {
  local p_kind="$1"
  local p_array_name="$2"
  local p_path="$3"
  local p_filter_pattern="$4"
  local p_maxdepth="$5"
  local -n _fs_out="$p_array_name"
  local find_type='f'
  local prefix glob
  local dotglob=0
  local nullglob=0
  local i

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ ! -d "$p_path" ]]; then
    return 0
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  if [[ "$p_kind" == 'd' ]]; then
    find_type='d'
  fi

  if [[ "$p_maxdepth" -gt 1 ]]; then
    if [[ -n "$p_filter_pattern" ]]; then
      mapfile -d '' -O "${#_fs_out[@]}" _fs_out < <(find "$p_path" -mindepth 1 -maxdepth "$p_maxdepth" -type "$find_type" -name "$p_filter_pattern" -printf '%P\0')
    else
      mapfile -d '' -O "${#_fs_out[@]}" _fs_out < <(find "$p_path" -mindepth 1 -maxdepth "$p_maxdepth" -type "$find_type" -printf '%P\0')
    fi
    return 0
  fi

  shopt -q dotglob && dotglob=1
  shopt -q nullglob && nullglob=1
  shopt -s dotglob nullglob

  prefix="${p_path%/}"
  glob='*'

  if [[ -n "$p_filter_pattern" ]]; then
    glob="$p_filter_pattern"
  fi

  for i in "$prefix"/$glob; do
    if [[ "$find_type" == 'f' ]]; then
      [[ -f "$i" ]] || continue
    else
      [[ -d "$i" ]] || continue
    fi

    _fs_out+=("${i#"$prefix"/}")
  done

  if [[ "$dotglob" -eq 0 ]]; then
    shopt -u dotglob
  fi

  if [[ "$nullglob" -eq 0 ]]; then
    shopt -u nullglob
  fi
}

##
# Lists directories under a path. Replaces dir_list_arr.
#
# @var dir_list_arr
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String dir name filter pattern (defaults to no filter).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   f_fs_dir_list . '_*'
#   for dir in "${dir_list_arr[@]}"; do
#     echo "$dir"
#   done
#
f_fs_dir_list() {
  dir_list_arr=()
  f_fs_list_append d dir_list_arr "$@"
}

##
# Lists files under a path. Replaces file_list_arr.
#
# @var file_list_arr
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String file name filter pattern (defaults to no filter).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   f_fs_file_list . '*.sh'
#   for file in "${file_list_arr[@]}"; do
#     echo "$file"
#   done
#
#   # A second pattern replaces the array. To keep both, use
#   # f_fs_file_list_append.
#
f_fs_file_list() {
  file_list_arr=()
  f_fs_file_list_append "$@"
}

##
# Appends matching file paths to file_list_arr in the calling scope.
#
# Does not clear file_list_arr. Clear it before the first call. Arguments
# match f_fs_file_list.
#
# @var file_list_arr
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String file name filter pattern (defaults to no filter).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   file_list_arr=()
#   f_fs_file_list_append "$p_path" '*.pdf'
#   f_fs_file_list_append "$p_path" '*.md'
#   for file in "${file_list_arr[@]}"; do
#     echo "$file"
#   done
#
f_fs_file_list_append() {
  f_fs_list_append f file_list_arr "$@"
}

##
# Makes given absolute path relative to another, or $PROJECT_DOCROOT (default).
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var relative_path
#
# @param 1 String absolute path to convert to relative path (must start with '/').
# @param 2 [optional] String absolute reference path (must start with '/').
#   Defaults to "$PROJECT_DOCROOT" or "$PWD".
#
# @example
#   f_fs_relative_path "$PROJECT_DOCROOT/yetetets/testtset/fdsf.fd"
#   echo "$relative_path" # <- Prints : yetetets/testtset/fdsf.fd
#
#   f_fs_relative_path / /var/www/html
#   echo "$relative_path" # <- Prints : ../../../
#
#   f_fs_relative_path /var/www/yetetets/testtset/fdsf.fd /opt/app
#   echo "$relative_path" # <- Prints : ../../var/www/yetetets/testtset/fdsf.fd
#
f_fs_relative_path() {
  local p_target="$1"
  local p_source="$2"

  if [[ -z "$p_source" ]]; then
    p_source="${PROJECT_DOCROOT:=$PWD}"
  fi

  # Project-relative paths (e.g. data/db-dumps) are resolved against docroot first.
  if [[ "$p_target" != /* ]]; then
    p_target="$p_source/${p_target#./}"
  fi

  local result=""
  local common_part="$p_source"
  local parent_part
  local forward_part

  while [[ "${p_target#$common_part}" == "${p_target}" ]]; do
    # no match, means that candidate common part is not correct
    # go up one level (reduce common part) — pure bash, no dirname subshell
    parent_part="${common_part%/*}"

    if [[ -z "$parent_part" ]]; then
      common_part='/'
    else
      common_part="$parent_part"
    fi

    # and record that we went back, with correct / handling
    if [[ -z $result ]]; then
      result=".."
    else
      result="../$result"
    fi
  done

  if [[ $common_part == "/" ]]; then
    # special case for root (no common path)
    result="$result/"
  fi

  # since we now have identified the common part,
  # compute the non-common part
  forward_part="${p_target#$common_part}"

  # and now stick all parts together
  if [[ -n $result ]] && [[ -n $forward_part ]]; then
    result="$result$forward_part"
  elif [[ -n $forward_part ]]; then
    # extra slash removal
    result="${forward_part:1}"
  fi

  relative_path="$result"
}

##
# Update 2026-09 : comment out for now, unused but still might change our minds.
# Adds or updates a single line in given file.
#
# NB : hasn't been tested when pattern matches several lines.
#
# @param 1 String : the matching pattern (recognizes which line to update).
# @param 2 String : the entire new line to write.
# @param 3 String : (writeable) file path.
#
# @example
#   f_fs_update_or_append_line 'MY_VAR=' 'MY_VAR="new-val"' path/to/writeable/file
#
# f_fs_update_or_append_line() {
#   local p_pattern="$1"
#   local p_new_line="$2"
#   local p_file_path="$3"

#   if [[ ! -f "$p_file_path" ]]; then
#     echo >&2
#     echo "Error in f_fs_update_or_append_line() - $BASH_SOURCE line $LINENO: file $p_file_path was not found." >&2
#     echo "Aborting (1)." >&2
#     echo >&2
#     return 1
#   fi

#   local haystack
#   f_fs_get_file_contents "$p_file_path" 'haystack'
#   if [[ -z "$haystack" ]]; then
#     echo "$p_new_line" > "$p_file_path"
#     return
#   fi

#   # Escape backslash, forward slash and ampersand for use as a sed replacement.
#   # See https://stackoverflow.com/a/42727904
#   p_new_line=$(echo "$p_new_line" | sed -e 's/[\/&]/\\&/g')

#   sed -e "s,${p_pattern}.*,${p_new_line},g" -i "$p_file_path"
# }

##
# Update 2026-09 : comment out for now, unused but still might change our minds.
# Writes given string to a file only once.
#
# @param 1 String : the string to append to the file.
# @param 2 String : (writeable) file path.
#
# @example
#   f_fs_write_once '--test A' path/to/writeable/file # File contents appended.
#   f_fs_write_once '--test A' path/to/writeable/file # (unchanged)
#   f_fs_write_once '--test B' path/to/writeable/file # File contents appended.
#
# f_fs_write_once() {
#   local p_needle="$1"
#   local p_file_path="$2"

#   local haystack
#   f_fs_get_file_contents "$p_file_path" 'haystack'

#   if [[ -z "$haystack" ]]; then
#     echo "$p_needle" > "$p_file_path"
#     return
#   fi

#   local new_str
#   f_str_append_once $'\n'"$p_needle" "$haystack" 'new_str'

#   if [[ "$new_str" != "$haystack" ]]; then
#     echo "$new_str" > "$p_file_path"
#   fi
# }

##
# Replaces an entire line in given file.
#
# See https://stackoverflow.com/questions/11245144/replace-whole-line-containing-a-string-using-sed
#
# @example
#   f_fs_change_line "The existing line matching pattern" "The replacement text" path/to/file.ext
#
f_fs_change_line() {
  local p_existing_line_match="$1"
  local p_replacement="$2"
  local p_file="$3"

  local new
  f_str_sed_escape "${p_replacement}" 'new'

  sed "/$p_existing_line_match/c $new" -i "$p_file"
}

