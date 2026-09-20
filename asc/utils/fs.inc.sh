#!/usr/bin/env bash

##
# Filesystem (fs) related utility functions sourced on every heavy bootstrap.
# List / path / contents / most-recent / change-line only.
# Archive helpers: `. asc/utils/fs.opt-inc.sh`
# @see changelog/2026/09/19-fs-archive-lazy-include.md
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
#
# @see https://stackoverflow.com/questions/4561895/how-to-recursively-find-the-latest-modified-file-in-a-directory
#
# @example
#   # Gets the last modified file in current dir (PROJECT_DOCROOT) :
#   most_recent_file="$(f_fs_get_most_recent)"
#   echo "most_recent_file = $most_recent_file"
#
#   # Gets the last modified file in path 'asc' :
#   most_recent="$(f_fs_get_most_recent 'asc')"
#   echo "most_recent = $most_recent"
#
#   # Gets the last modified '*.yml' file in path 'scripts' :
#   most_recent="$(f_fs_get_most_recent 'scripts' '*.yml')"
#   echo "most_recent = $most_recent"
#
#   # Gets the last 3 files modified in path 'asc' up to 5 dir deep :
#   while read -r file; do
#     echo "$file"
#   done <<< "$(f_fs_get_most_recent 'asc' '' 5 3)"
#
f_fs_get_most_recent() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_max_depth="$3"
  local p_n_files="$4"

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
    find "$p_path" -maxdepth "$p_max_depth" -type f -name "$p_filter_pattern" -exec ls -1t '{}' + \
      | head -n$p_n_files
  else
    find "$p_path" -maxdepth "$p_max_depth" -type f -exec ls -1t '{}' + \
      | head -n$p_n_files
  fi
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
# Lists folders (shorter naming choice : we use 'dir' for directories).
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var dir_list
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String dir name filter pattern (defaults to none / not filtering).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   # List all dirs in current folder.
#   f_fs_dir_list
#   echo "$dir_list"
#
#   # List all dirs whose name starts with '_' in current folder.
#   f_fs_dir_list . '_*'
#   echo "$dir_list"
#
#   # List all dirs in the "/path/to/dir" folder up to 3 levels deep.
#   f_fs_dir_list /path/to/dir '' 3
#   echo "$dir_list"
#
#   # Looping example :
#   for dir in $dir_list; do
#     echo "$dir"
#   done
#
f_fs_dir_list() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_maxdepth=$3

  dir_list=''

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ ! -d "$p_path" ]]; then
    return
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  local i

  # If we need to look for dirs in deeper levels, use 'find' (subshell).
  # TODO remove depth argument and make a separate function ? #YAGNI
  if [[ $p_maxdepth -gt 1 ]]; then
    if [[ -z "$p_filter_pattern" ]]; then
      dir_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type d -printf '%P\n')"
    else
      dir_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type d -name "$p_filter_pattern" -printf '%P\n')"
    fi

  # Otherwise, just use the less expensive bash loop.
  else
    if [[ "$p_path" != '.' ]]; then
      pushd "$p_path" >/dev/null
    fi

    # The default globbing in bash does not include dirnames starting with a .
    shopt -s dotglob

    if [[ -z "$p_filter_pattern" ]]; then
      for i in * ; do
        if [ -d "$i" ]; then
          dir_list+="${i}
"
        fi
      done
    else
      for i in * ; do
        if [ -d "$i" ]; then
          case "$i" in
            $p_filter_pattern)
              dir_list+="${i}
"
            ;;
          esac
        fi
      done
    fi

    if [[ "$p_path" != '.' ]]; then
      popd >/dev/null
    fi

    shopt -u dotglob
  fi
}

##
# Gets a list of files in given folder.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to variables subject to collision in calling scope.
#
# @var file_list
# @var file_list_arr
#
# @param 1 [optional] String base path (defaults to '.').
# @param 2 [optional] String file name filter pattern (defaults to '*' / not filtering).
# @param 3 [optional] Integer max depth (defaults to 1).
#
# @example
#   # List all files in current folder.
#   f_fs_file_list
#   echo "$file_list"
#
#   # List '*.sh' files in current folder.
#   f_fs_file_list . '*.sh'
#   echo "$file_list"
#
#   # List all files in the "/path/to/dir" folder up to 3 levels deep.
#   f_fs_file_list /path/to/dir '' 3
#   echo "$file_list"
#
#   # Looping example :
#   f_fs_file_list 'data/asc/cache/entities/remote_instance'
#   while read -r file; do
#     echo "$file"
#   done <<< "$file_list"
#
#   # TODO [evol] deprecate the string variable to avoid issues with file names
#   # containing space(s) and the last empty line :
#   file_list_arr=()
#   f_fs_file_list "$dir"
#   for file in "${file_list_arr[@]}"; do
#     echo "file = $file"
#   done
#
f_fs_file_list() {
  local p_path="$1"
  local p_filter_pattern="$2"
  local p_maxdepth=$3

  file_list=''
  file_list_arr=()

  if [[ -z "$p_path" ]]; then
    p_path='.'
  fi

  if [[ ! -d "$p_path" ]]; then
    return
  fi

  if [[ -z "$p_maxdepth" ]]; then
    p_maxdepth=1
  fi

  local i

  # If we need to look for files in deeper levels, use 'find' (subshell).
  # TODO remove depth argument and make a separate function ? #YAGNI
  if [[ $p_maxdepth -gt 1 ]]; then
    if [[ -z "$p_filter_pattern" ]]; then
      file_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type f -printf '%P\n')"
    else
      file_list="$(find "$p_path" -maxdepth "$p_maxdepth" -type f -name "$p_filter_pattern" -printf '%P\n')"
    fi

  # Otherwise, just use the less expensive bash globbing.
  else
    if [[ "$p_path" != '.' ]]; then
      pushd "$p_path" >/dev/null
    fi

    # The default globbing in bash does not include filenames starting with a .
    shopt -s dotglob

    if [[ -z "$p_filter_pattern" ]]; then
      for i in * ; do
        if [[ -f "$i" ]]; then
          file_list_arr+=("$i")
          file_list+="${i}
"
        fi
      done
    else
      for i in * ; do
        if [[ -f "$i" ]]; then
          case "$i" in
            $p_filter_pattern)
              file_list_arr+=("$i")
              file_list+="${i}
"
            ;;
          esac
        fi
      done
    fi

    if [[ "$p_path" != '.' ]]; then
      popd >/dev/null
    fi

    shopt -u dotglob
  fi
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

