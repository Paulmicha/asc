#!/usr/bin/env bash

##
# List local instance DB dump files.
#
# For listing remote DB dumps,
# @see asc/extensions/remote_db/remote/db_list_dumps.sh
#
# @param 1 [optional] String : the subfolder in the DB dumps dir.
#   Defaults to an empty string, meaning : all subfolders will be listed.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to an empty string, meaning : list dumps of all defined DB IDs.
#
# @example
#   make db-list-dumps
#   # Or :
#   asc/extensions/db/db/list_dumps.sh
#

. asc/bootstrap.sh

a_subdir="$1"
a_db_id="$2"

if [[ -z "$ASC_DB_DUMPS_DIR" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: the required global 'ASC_DB_DUMPS_DIR' is undefined." >&2
  echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

subdir=''
db_ids_arr=()

f_db_get_ids
f_fs_dir_list "$ASC_DB_DUMPS_DIR"

echo "Listing dumps in :"

for subdir in $dir_list; do
  if [[ -n "$a_subdir" ]]; then
    case "$subdir" in
      "$a_subdir")
        echo "  $subdir :"
        ;;
      *)
        continue
        ;;
    esac
  else
    echo "  $subdir :"
  fi

  for db_id in "${db_ids_arr[@]}"; do
    dir="$ASC_DB_DUMPS_DIR/$subdir/$db_id"

    f_fs_relative_path "$dir"

    if [[ -n "$a_db_id" ]]; then
      case "$db_id" in
        "$a_db_id")
          echo "    $db_id ($relative_path) :"
          ;;
        *)
          continue
          ;;
      esac
    else
      echo "    $db_id ($relative_path) :"
    fi

    file_list_arr=()
    f_fs_file_list "$dir"

    for file in "${file_list_arr[@]}"; do
      echo "      $file"
    done
  done
done
