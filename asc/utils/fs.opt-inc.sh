#!/usr/bin/env bash

##
# Archive / merge helpers — not derived by bootstrap.
# Callers must `.` this file. `asc/utils/` is not a caller dir.
# @see changelog/2026/09/19-fs-archive-lazy-include.md
# @see asc/utils/fs.inc.sh
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

##
# Compresses given path to a *.tgz archive file (customizable).
#
# Inside the archive, the path is relative to the input path - i.e. if I
# request path/to/folder the resulting archive will contain the contents of that
# folder (and NOT path/to/folder).
#
# @param 1 String : the path to compress.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
# @param 3 [optional] String : preferred extension. Defaults to 'tgz'.
#
# @example
#   # Will compress given path to arhive file in current dir :
#   f_fs_compress path/to/file.ext
#   # -> Result : ./file.ext.tgz
#   f_fs_compress path/to/folder
#   # -> Result : ./folder.tgz
#
#   # Will compress given path to arhive file inside dir 'path/to' :
#   f_fs_compress path/to/file.ext path/to
#   # -> Result : path/to/file.ext.tgz
#   f_fs_compress path/to/folder path/to
#   # -> Result : path/to/folder.tgz
#
#   # Custom extension.
#   f_fs_compress path/to/folder path/to tar.gz
#   # -> Result : path/to/folder.tar.gz
#
#   # Single file + gz = gzip of that file (not tar.gz bytes).
#   f_fs_compress path/to/dump.sql path/to gz
#   # -> Result : path/to/dump.sql.gz
#
f_fs_compress() {
  local p_path="$1"
  local p_folder="$2"
  local p_preferred_extension="$3"

  if [[ ! -f "$p_path" ]] && [[ ! -d "$p_path" ]]; then
    echo >&2
    echo "Notice in f_fs_compress() - $BASH_SOURCE line $LINENO: directory or file '$p_path' was not found." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
    echo >&2
    echo "Notice in f_fs_compress() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
    echo "Aborting (2)." >&2
    echo >&2
    return 2
  fi

  local extension='tgz'
  if [[ -n "$p_preferred_extension" ]]; then
    extension="$p_preferred_extension"
  fi

  local src="$p_path"
  local dest="$p_path.$extension"
  local leaf="${p_path##*/}"
  if [[ -n "$p_folder" ]]; then
    src="$p_folder/$leaf"
    dest="$p_folder/$leaf.$extension"
  fi

  # Preferred `gz` on a file: gzip of that file (SQL dumps). Directories still tar.
  if [[ "$extension" == 'gz' && -f "$src" ]]; then
    gzip -c "$src" > "$dest"
    return $?
  fi

  if [[ -n "$p_folder" ]]; then
    tar -C "$p_folder" -czf "$dest" "$leaf"
  else
    tar -czf "$dest" "$p_path"
  fi

  return $?
}

##
# Same as f_fs_compress() but presetting folder to compress in place.
#
# @param 1 String : the path to compress.
#
# @see f_fs_compress()
#
# @example
#   # Will compress given path to arhive file inside dir 'path/to' :
#   f_fs_compress_in_place path/to/file.ext
#   # -> Result : path/to/file.ext.tgz
#   f_fs_compress_in_place path/to/folder
#   # -> Result : path/to/folder.tgz
#
f_fs_compress_in_place() {
  local p_path_to_compress_in_place="$1"
  local leaf="${p_path_to_compress_in_place##*/}"
  local base_path="${p_path_to_compress_in_place%/$leaf}"

  f_fs_compress \
    "$p_path_to_compress_in_place" \
    "$base_path"

  return $?
}

##
# Utility to trim any coopression extension from a file name or file path.
#
# @example
#   uncompressed_file=''
#   f_fs_trim_compression_ext 'data/db-dumps/prod/default/2024-08-07.16-41-31_site_foobar.com.sql.gz'
#   echo "uncompressed_file = $uncompressed_file"
#   # Yields 'data/db-dumps/prod/default/2024-08-07.16-41-31_site_foobar.com.sql'
#
f_fs_trim_compression_ext() {
  local p_filepath="$1"
  local p_output_var="$2"

  if [[ -z "$p_output_var" ]]; then
    p_output_var='uncompressed_file'
  fi

  local ext
  local result
  local compressed_extensions='.tar.gz .tar.bz2 .tar.xz .gz .zip .tgz .7z .cbt .tbz2 .txz .tar .bz2 .z'

  for ext in $compressed_extensions; do
    result="${p_filepath%$ext}"

    # Any result of this replace that changes the input file path means that
    # the extension matched (we can stop here).
    if [[ "$result" != "$p_filepath" ]]; then
      # Write result to var in calling scope.
      printf -v "$p_output_var" '%s' "$result"
      return
    fi
  done
}

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

##
# Same as f_fs_extract() but presetting folder to extract in place.
#
# @param 1 String : the archive file to extract.
#
# @see f_fs_extract()
#
# @var extracted_file
# @var extracted_files
#
# @example
#   # Will extract given archive file in its folder :
#   f_fs_extract_in_place path/to/file.ext.tgz
#   echo "extracted_file = $extracted_file"
#
f_fs_extract_in_place() {
  local p_file_to_extract_in_place="$1"

  local leaf="${p_file_to_extract_in_place##*/}"
  local base_path="${p_file_to_extract_in_place%/$leaf}"

  # Reset calling scope vars receiving the result.
  extracted_file=''
  extracted_files=''

  f_fs_extract \
    "$p_file_to_extract_in_place" \
    "$base_path"

  return $?
}
