---
description: In most programming languages, line breaks must allow some breathing room to guide the reader's eyes and allow quick scanning of code blocks.
globs: '*.sh, *.yml, *.py, *.js, *.jsx, *.php, *.rust, *.go, *.java, *.c, *.cpp'
---

Regroup neighbouring lines in logical groups, always leaving at least 1 line break before new multiline blocks like conditions, loops, case enumerations, etc.

All functions, conditions and loops must not have their inner first and last lines be an empty line.

# Anti-pattern example (don't)

```sh
##
# Extracts given archive file(s). Supports various formats.
# This function uses a return value to indicate wether the file was uncompressed
# or not. It also sets the uncompressed file names to a variable
# subject to collision in calling scope :
# @var extracted_files
# If the archive contained a single file, it will set its name to the following
# variable subject to collision in calling scope :
# @var extracted_file
# @param 1 String : the archive file to extract.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
#   TODO [wip] Only tested with tar program. We need to check other programs
#   behaviors (if they uncompress files in place or inside current folder).
# See https://github.com/xvoland/Extract
# This function deliberately does nothing if it does not detect a file extension
# matching some archive format whitelisted below.
# @example
#   # Extract given archive files in current dir :
#   extracted_files=''
#   f_fs_extract path/to/file.zip
#   echo "$extracted_files" # <- Outputs list of extracted contents.
#   # Extract given archive containing a single file to folder 'path/to' :
#   extracted_file=''
#   f_fs_extract path/to/file.sql.tgz path/to
#   echo "$extracted_file" # <- Outputs e.g. path/to/file.sql
#   # Will leave the file untouched because it is not an archive file :
#   f_fs_extract path/to/file.txt
#   echo $? # Will print '1' (indicates that the file was untouched).
f_fs_extract() {
  local p_file="$1"
  local p_folder="$2"
  if [[ ! -f "$p_file" ]]; then
    echo >&2
    echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: file '$p_file' was not found." >&2
    echo "Aborting (2)." >&2
    echo >&2
    return 2
  fi
  if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
    echo >&2
    echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
    echo "Aborting (3)." >&2
    echo >&2
    return 3
  fi
  # Reset calling scope vars receiving the result.
  extracted_file=''
  extracted_files=''
  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_fs_extract $p_file $p_folder"
  fi
  local untouched=1
  local needs_copy='y'
  local original_file="$p_file"
  # If the uncompressed file already exists, consider it was uncompressed.
  local uncompressed_file=''
  f_fs_trim_compression_ext "$p_file"
  if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
    echo "Uncompressed file $uncompressed_file already exists."
    echo "  -> Skip uncompress (but still produce the same result as if archive was successfully uncompressed)."
    extracted_file="$uncompressed_file"
    return
  fi
  # In order to correctly handle the 2nd parameter (destination folder), we
  # process the 'tar' command separately.
  case "$p_file" in *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
    needs_copy='n'
    uncompressed_file="${p_file%$ext}"
    # Get archive contents.
    # TODO Untested : *.tar.bz2 archives may need the '-j' flag.
    # TODO Check relative paths are correct.
    # TODO Too slow for big archives -> make optional ?
    local contents_list_str=$(tar -tf "$p_file")
    local contents_list_arr=($contents_list_str)
    if [[ ${#contents_list_arr[@]} -gt 1 ]]; then
      extracted_files="$contents_list_str"
      if [[ -n "$p_folder" ]]; then
        extracted_files=''
        local i
        for i in "${contents_list_arr[@]}"; do
          extracted_files+="$p_folder/$i
"
        done
      fi
    else
      extracted_file="$contents_list_str"
      if [[ -n "$p_folder" ]]; then
        extracted_file="$p_folder/$contents_list_str"
      fi
    fi
    if [[ -n "$p_folder" ]]; then
      # Debug.
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  tar -xf $p_file -C $p_folder"
      fi
      untouched=0
      tar -xf "$p_file" -C "$p_folder"
    else
      # Debug.
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  tar -xf $p_file"
      fi
      untouched=0
      tar -xf "$p_file"
    fi
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_fs_extract() - $BASH_SOURCE line $LINENO: the tar command exited with non-zero code." >&2
      echo "Aborting (4)." >&2
      echo >&2
      exit 4
    fi
    return $untouched
  esac
  untouched=1
  # TODO [wip] not all formats and programs were tested from this list.
  # See https://github.com/xvoland/Extract
  case "$p_file" in
    *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  7z x $p_file"
      fi
      untouched=0
      7z x "$p_file"
      ;;
    *.gz)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  gunzip -k $p_file"
      fi
      untouched=0
      gunzip -k "$p_file"
      ;;
    *.cbz|*.epub|*.zip)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unzip $p_file"
      fi
      untouched=0
      unzip "$p_file"
      ;;
    *.bz2)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  bunzip2 $p_file"
      fi
      untouched=0
      bunzip2 "$p_file"
      ;;
    *.cbr|*.rar)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unrar $p_file"
      fi
      untouched=0
      unrar x -ad "$p_file"
      ;;
    *.z)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  uncompress $p_file"
      fi
      untouched=0
      uncompress "$p_file"
      ;;
    *.lzma)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  uncompress $p_file"
      fi
      untouched=0
      unlzma "$p_file"
      ;;
    *.xz)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unxz $p_file"
      fi
      untouched=0
      unxz "$p_file"
      ;;
    *.exe)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  cabextract $p_file"
      fi
      untouched=0
      cabextract "$p_file"
      ;;
    *.cpio)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  cpio $p_file"
      fi
      untouched=0
      cpio -id < "$p_file"
      ;;
    *.cba|*.ace)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unace $p_file"
      fi
      untouched=0
      unace x "$p_file"
      ;;
  esac
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_fs_extract() - $BASH_SOURCE line $LINENO: the extract command exited with non-zero code." >&2
    echo "Aborting (5)." >&2
    echo >&2
    exit 5
  fi
  if [[ $untouched -eq 0 ]]; then
    f_fs_trim_compression_ext "$p_file"
    if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
      echo "File was uncompressed successfully to :"
      echo "  $uncompressed_file"
      extracted_file="$uncompressed_file"
    fi
  fi
  return $untouched
}
```

# Correct example (do)

```sh
##
# Extracts given archive file(s). Supports various formats.
#
# This function uses a return value to indicate wether the file was uncompressed
# or not. It also sets the uncompressed file names to a variable
# subject to collision in calling scope :
#
# @var extracted_files
#
# If the archive contained a single file, it will set its name to the following
# variable subject to collision in calling scope :
#
# @var extracted_file
#
# @param 1 String : the archive file to extract.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
#   TODO [wip] Only tested with tar program. We need to check other programs
#   behaviors (if they uncompress files in place or inside current folder).
#
# See https://github.com/xvoland/Extract
#
# This function deliberately does nothing if it does not detect a file extension
# matching some archive format whitelisted below.
#
# @example
#   # Extract given archive files in current dir :
#   extracted_files=''
#   f_fs_extract path/to/file.zip
#   echo "$extracted_files" # <- Outputs list of extracted contents.
#
#   # Extract given archive containing a single file to folder 'path/to' :
#   extracted_file=''
#   f_fs_extract path/to/file.sql.tgz path/to
#   echo "$extracted_file" # <- Outputs e.g. path/to/file.sql
#
#   # Will leave the file untouched because it is not an archive file :
#   f_fs_extract path/to/file.txt
#   echo $? # Will print '1' (indicates that the file was untouched).
#
f_fs_extract() {
  local p_file="$1"
  local p_folder="$2"

  if [[ ! -f "$p_file" ]]; then
    echo >&2
    echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: file '$p_file' was not found." >&2
    echo "Aborting (2)." >&2
    echo >&2
    return 2
  fi

  if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
    echo >&2
    echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
    echo "Aborting (3)." >&2
    echo >&2
    return 3
  fi

  # Reset calling scope vars receiving the result.
  extracted_file=''
  extracted_files=''

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_fs_extract $p_file $p_folder"
  fi

  local untouched=1
  local needs_copy='y'
  local original_file="$p_file"

  # If the uncompressed file already exists, consider it was uncompressed.
  local uncompressed_file=''

  f_fs_trim_compression_ext "$p_file"

  if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
    echo "Uncompressed file $uncompressed_file already exists."
    echo "  -> Skip uncompress (but still produce the same result as if archive was successfully uncompressed)."

    extracted_file="$uncompressed_file"

    return
  fi

  # In order to correctly handle the 2nd parameter (destination folder), we
  # process the 'tar' command separately.
  case "$p_file" in *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
    needs_copy='n'
    uncompressed_file="${p_file%$ext}"

    # Get archive contents.
    # TODO Untested : *.tar.bz2 archives may need the '-j' flag.
    # TODO Check relative paths are correct.
    # TODO Too slow for big archives -> make optional ?
    local contents_list_str=$(tar -tf "$p_file")
    local contents_list_arr=($contents_list_str)

    if [[ ${#contents_list_arr[@]} -gt 1 ]]; then
      extracted_files="$contents_list_str"

      if [[ -n "$p_folder" ]]; then
        extracted_files=''
        local i

        for i in "${contents_list_arr[@]}"; do
          extracted_files+="$p_folder/$i
"
        done
      fi
    else
      extracted_file="$contents_list_str"

      if [[ -n "$p_folder" ]]; then
        extracted_file="$p_folder/$contents_list_str"
      fi
    fi

    if [[ -n "$p_folder" ]]; then
      # Debug.
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  tar -xf $p_file -C $p_folder"
      fi

      untouched=0
      tar -xf "$p_file" -C "$p_folder"
    else
      # Debug.
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  tar -xf $p_file"
      fi

      untouched=0
      tar -xf "$p_file"
    fi

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_fs_extract() - $BASH_SOURCE line $LINENO: the tar command exited with non-zero code." >&2
      echo "Aborting (4)." >&2
      echo >&2
      exit 4
    fi

    return $untouched
  esac

  untouched=1

  # TODO [wip] not all formats and programs were tested from this list.
  # See https://github.com/xvoland/Extract
  case "$p_file" in
    *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  7z x $p_file"
      fi
      untouched=0
      7z x "$p_file"
      ;;

    *.gz)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  gunzip -k $p_file"
      fi
      untouched=0
      gunzip -k "$p_file"
      ;;

    *.cbz|*.epub|*.zip)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unzip $p_file"
      fi
      untouched=0
      unzip "$p_file"
      ;;

    *.bz2)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  bunzip2 $p_file"
      fi
      untouched=0
      bunzip2 "$p_file"
      ;;

    *.cbr|*.rar)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unrar $p_file"
      fi
      untouched=0
      unrar x -ad "$p_file"
      ;;

    *.z)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  uncompress $p_file"
      fi
      untouched=0
      uncompress "$p_file"
      ;;

    *.lzma)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  uncompress $p_file"
      fi
      untouched=0
      unlzma "$p_file"
      ;;

    *.xz)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unxz $p_file"
      fi
      untouched=0
      unxz "$p_file"
      ;;

    *.exe)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  cabextract $p_file"
      fi
      untouched=0
      cabextract "$p_file"
      ;;

    *.cpio)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  cpio $p_file"
      fi
      untouched=0
      cpio -id < "$p_file"
      ;;

    *.cba|*.ace)
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  unace $p_file"
      fi
      untouched=0
      unace x "$p_file"
      ;;
  esac

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_fs_extract() - $BASH_SOURCE line $LINENO: the extract command exited with non-zero code." >&2
    echo "Aborting (5)." >&2
    echo >&2
    exit 5
  fi

  if [[ $untouched -eq 0 ]]; then
    f_fs_trim_compression_ext "$p_file"

    if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
      echo "File was uncompressed successfully to :"
      echo "  $uncompressed_file"

      extracted_file="$uncompressed_file"
    fi
  fi

  return $untouched
}
```
