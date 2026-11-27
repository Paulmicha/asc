#!/usr/bin/env bash

##
# Contains utilities for remote instances using ASC.
#
# Loaded explicitly by the remote DB actions; not on ASC_INC.
#
# Complements the 'db' extension (if enabled).
# @see asc/extensions/db
# @see asc/bootstrap.sh (caller opt-inc)
#
# Convention : functions names are all prefixed by "f".
#

if ! type f_db_routine_backup &>/dev/null; then
  # shellcheck disable=SC1091
  . asc/extensions/db/db/db.opt-inc.sh
fi


##
# Sends local instance DB dump to given remote.
#
# Optionally creates a new dump before sending it over, or uses most recent
# local instance DB dump (default). Always wipes out and restores the dump on
# remote DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
# @param 3 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @examples
#   # Using the default database :
#   f_remote_sync_db_to my_remote_id
#   f_remote_sync_db_to my_remote_id new
#   f_remote_sync_db_to my_remote_id path/to/local/dump/file.sql.tgz
#
#   # Specifying the database (by DB_ID) :
#   f_remote_sync_db_to my_remote_id '' my_db_id
#   f_remote_sync_db_to my_remote_id new my_db_id
#   f_remote_sync_db_to my_remote_id path/to/local/dump/file.sql.tgz my_db_id
#
f_remote_sync_db_to() {
  local p_id="$1"
  local p_option="$2"

  local rst_dump_file
  local rst_dump_file_relative_path
  local rst_dump_remote_base_path
  local rst_leaf
  local rst_dump_dir_on_remote
  local rst_dump_file_on_remote

  f_remote_instance_load "$p_id" || return $?

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_to() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_db_set "$3" "$4" || return $?

  # Handle variants given 1st argument.
  if [[ -n "$p_option" ]]; then
    if [[ -f "$p_option" ]]; then
      rst_dump_file="$p_option"
    else
      case "$p_option" in new)
        f_db_routine_backup "$DB_ID" "$4" || return $?
        rst_dump_file="$routine_dump_file"
      esac
    fi
  else
    rst_dump_file="$(f_db_get_dump last "$DB_ID")" || return $?
  fi

  if [[ ! -f "$rst_dump_file" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_to() - $BASH_SOURCE line $LINENO: no dump file to send." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  fi

  # The dump file path on the remote will be placed inside an 'manually-uploaded-sync'
  # subfolder in order to avoid collisions risks while limiting fragmentation.

  # 1. Get the dump file relative path.
  relative_path=''
  f_fs_relative_path "$rst_dump_file"
  rst_dump_file_relative_path="$relative_path"

  # 2. Transform its path for use on the remote.
  relative_path=''
  f_fs_relative_path "$ASC_DB_DUMPS_DIR"
  rst_dump_remote_base_path="$relative_path/manually-uploaded-sync/$DB_ID"
  rst_leaf="${rst_dump_file##*/}"
  rst_dump_file_on_remote="$rst_dump_remote_base_path/$rst_leaf"

  # 3. Create the containing folder on the remote (if it doesn't exist yet).
  rst_dir_on_remote="${rst_dump_file_on_remote%/$rst_leaf}"
  echo "Ensure dir '$rst_dir_on_remote' exists on remote '$p_id' ..."
  f_remote_exec_wrapper "$p_id" \
    mkdir -p "$rst_dir_on_remote" || return $?
  echo "Ensure dir '$rst_dir_on_remote' exists on remote '$p_id' : done."

  # 4. Send the file.
  echo "Sending dump file '$rst_dump_file_relative_path' to remote '$p_id' ..."
  f_remote_upload "$p_id" "$rst_dump_file_relative_path" "$rst_dump_file_on_remote" || return $?
  echo "Sending dump file '$rst_dump_file_relative_path' to remote '$p_id' : done."

  # 5. Restore it on the remote.
  echo "Restoring '$rst_dump_file_on_remote' on remote '$p_id' ..."
  f_remote_exec_wrapper "$p_id" \
    make db-restore "$rst_dump_file_on_remote" "$DB_ID" || return $?
  echo "Restoring '$rst_dump_file_on_remote' on remote '$p_id' : done."
  echo
}

##
# Fetches DB dump from given remote and restores it locally.
#
# TODO avoid duplicated code
# @see f_remote_download_db_from
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Always wipes out and restores the dump on
# local DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
# @param 3 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @examples
#   # Using the default database :
#   f_remote_sync_db_from my_remote_id
#   f_remote_sync_db_from my_remote_id new
#   f_remote_sync_db_from my_remote_id path/to/remote/dump/file.sql.tgz
#
#   # Specifying the database by DB_ID (e.g. 'my_db_id') :
#   f_remote_sync_db_from my_remote_id '' my_db_id
#   f_remote_sync_db_from my_remote_id new my_db_id
#   f_remote_sync_db_from my_remote_id path/to/remote/dump/file.sql.tgz my_db_id
#
f_remote_sync_db_from() {
  local p_id="$1"
  local p_option="$2"

  local rsf_remote_dump_file
  local rsf_dump_local_base_path
  local rsf_leaf
  local rsf_local_dump_file
  local rsf_get_dump_cmd

  f_remote_instance_load "$p_id" || return $?

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_db_set "$3" "$4" || return $?

  # Handle variants given 1st argument.
  if [[ -n "$p_option" ]]; then
    # No check if file exists on the remote instance (perf).
    rsf_remote_dump_file="$p_option"
    case "$p_option" in new)
      printf -v rsf_get_dump_cmd 'asc/extensions/db/db/get_dump.sh new %q' "$DB_ID"
      rsf_remote_dump_file="$(asc/extensions/remote/remote/exec.sh "$p_id" "$rsf_get_dump_cmd")" || return $?
      rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_DOCROOT/}"
    esac
  else
    printf -v rsf_get_dump_cmd 'asc/extensions/db/db/get_dump.sh last %q' "$DB_ID"
    rsf_remote_dump_file="$(asc/extensions/remote/remote/exec.sh "$p_id" "$rsf_get_dump_cmd")" || return $?
    rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_DOCROOT/}"
  fi

  if [[ -z "$rsf_remote_dump_file" ]]; then
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: no remote dump file found for '$DB_ID'." >&2
    return 2
  fi

  # The local dump file path must be placed inside a subfolder named
  # after the remote instance id in order to avoid any risks of collision.
  rsf_leaf="${rsf_remote_dump_file##*/}"

  case "$rsf_leaf" in ''|.|..)
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: invalid remote dump filename." >&2
    return 2
  esac

  relative_path=''
  f_fs_relative_path "$ASC_DB_DUMPS_DIR"
  rsf_dump_local_base_path="$relative_path/$p_id/$DB_ID"
  rsf_local_dump_file="$rsf_dump_local_base_path/$rsf_leaf"

  echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' ..."
  f_remote_download "$p_id" "$rsf_remote_dump_file" "$rsf_local_dump_file" || return $?

  if [[ ! -f "$rsf_local_dump_file" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: failed to fetch remote dump file." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  else
    echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' : done."
  fi

  echo "Restoring it locally ..."
  f_db_restore "$rsf_local_dump_file" "$DB_ID" "$4" || return $?
  echo "Restoring it locally : done."
  echo
}

##
# Just fetches DB dump from given remote (without restoring it locally).
#
# TODO avoid duplicated code
# @see f_remote_sync_db_from
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Does not restore the dump locally.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
# @param 3 [optional] String : unique DB identifier. Defaults to 'default'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @examples
#   # Using the default database :
#   f_remote_download_db_from my_remote_id
#   f_remote_download_db_from my_remote_id new
#   f_remote_download_db_from my_remote_id path/to/remote/dump/file.sql.tgz
#
#   # Specifying the database by DB_ID (e.g. 'my_db_id') :
#   f_remote_download_db_from my_remote_id '' my_db_id
#   f_remote_download_db_from my_remote_id new my_db_id
#   f_remote_download_db_from my_remote_id path/to/remote/dump/file.sql.tgz my_db_id
#
f_remote_download_db_from() {
  local p_id="$1"
  local p_option="$2"

  local rsf_remote_dump_file
  local rsf_dump_local_base_path
  local rsf_leaf
  local rsf_local_dump_file
  local rsf_get_dump_cmd

  f_remote_instance_load "$p_id" || return $?

  if [[ -z "$REMOTE_INSTANCE_SSH_CONNECT_CMD" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: no conf found for remote id '$p_id'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_db_set "$3" "$4" || return $?

  # Handle variants given 1st argument.
  if [[ -n "$p_option" ]]; then
    # No check if file exists on the remote instance (perf).
    rsf_remote_dump_file="$p_option"
    case "$p_option" in new)
      printf -v rsf_get_dump_cmd 'asc/extensions/db/db/get_dump.sh new %q' "$DB_ID"
      rsf_remote_dump_file="$(asc/extensions/remote/remote/exec.sh "$p_id" "$rsf_get_dump_cmd")" || return $?
      rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_DOCROOT/}"
    esac
  else
    printf -v rsf_get_dump_cmd 'asc/extensions/db/db/get_dump.sh last %q' "$DB_ID"
    rsf_remote_dump_file="$(asc/extensions/remote/remote/exec.sh "$p_id" "$rsf_get_dump_cmd")" || return $?
    rsf_remote_dump_file="${rsf_remote_dump_file#$REMOTE_INSTANCE_DOCROOT/}"
  fi

  if [[ -z "$rsf_remote_dump_file" ]]; then
    echo "Error in f_remote_download_db_from() - $BASH_SOURCE line $LINENO: no remote dump file found for '$DB_ID'." >&2
    return 2
  fi

  # The local dump file path must be placed inside a subfolder named
  # after the remote instance id in order to avoid any risks of collision.
  rsf_leaf="${rsf_remote_dump_file##*/}"

  case "$rsf_leaf" in ''|.|..)
    echo "Error in f_remote_download_db_from() - $BASH_SOURCE line $LINENO: invalid remote dump filename." >&2
    return 2
  esac

  relative_path=''
  f_fs_relative_path "$ASC_DB_DUMPS_DIR"
  rsf_dump_local_base_path="$relative_path/$p_id/$DB_ID"
  rsf_local_dump_file="$rsf_dump_local_base_path/$rsf_leaf"

  echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' ..."
  f_remote_download "$p_id" "$rsf_remote_dump_file" "$rsf_local_dump_file" || return $?

  if [[ ! -f "$rsf_local_dump_file" ]]; then
    echo >&2
    echo "Error in f_remote_sync_db_from() - $BASH_SOURCE line $LINENO: failed to fetch remote dump file." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    return 2
  else
    echo "Fetching dump file '$rsf_remote_dump_file' from remote '$p_id' : done."
  fi

  echo
}
