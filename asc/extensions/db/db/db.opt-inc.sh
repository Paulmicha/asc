#!/usr/bin/env bash

##
# DB dump/exec/restore/setup cluster — lazy, caller-dir.
# Loaded by caller opt-inc from `db/db/*.sh`. Not `asc/extensions/db/db.opt-inc.sh`
# (pick A: caller dir is `db/db/`).
# @see changelog/2026/09/19-db-thin-inc-and-opt-inc.md
# @see asc/extensions/db/db.inc.sh (creds/flags stay eager)
#

if ! type f_fs_extract_in_place &>/dev/null; then
  # shellcheck disable=SC1091
  . asc/core/utils/fs_compression.manual-inc.sh
fi

##
# [abstract] Creates (+ sets up) new database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:create v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_create
#
f_db_create() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_create $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    hook_ms -s 'db' -a 'create' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi

  f_db_ensure_creds "$p_db_id" "$p_force_reload_flag"
}

##
# [abstract] Destroys (deletes) a database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:destroy v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_destroy
#   f_db_destroy 'custom_db_id'
#
f_db_destroy() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_destroy $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    hook_ms -s 'db' -a 'destroy' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# [abstract] Executes given file (containing any query) in given DB ID.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# Important notes : implementations of the hook -s 'db' -a 'dump' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:exec v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_exec 'path/to/dump/file.sql.tgz'
#
f_db_exec() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  local db_dump_dir
  local db_dump_file
  local leaf

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in f_db_exec() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  f_db_set "$p_db_id" "$p_force_reload_flag"

  db_dump_file="$p_dump_file_path"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_exec $p_dump_file_path $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # Query file may or may not be an archive. If it is, uncompress it.
  local extracted_file=''
  local compressed_file=''

  f_fs_extract_in_place "$db_dump_file"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "  extracted_file = $extracted_file"
  fi

  # When input file is an archive, we assume the uncompressed file will be
  # named exactly like the archive without its extension, e.g. :
  # - my-dump.sql.tgz -> my-dump.sql
  # - my-dump.sql.tar.gz -> my-dump.sql
  if [[ -f "$extracted_file" ]]; then
    echo "  Input file was compressed -> using extracted file '$extracted_file' as input."
    compressed_file="$db_dump_file"
    db_dump_file="$extracted_file"

    # Debug.
    if [[ -n "$ASC_DB_DEBUG" ]]; then
      echo "  compressed_file = $compressed_file"
      echo "  db_dump_file = $db_dump_file"
    fi
  elif [[ -n "$ASC_DB_DEBUG" ]]; then
    # Debug.
    echo "  db_dump_file = $db_dump_file"
  fi

  if [[ ! -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in f_db_exec() - $BASH_SOURCE line $LINENO: missing uncompressed dump file :" >&2
    echo "  $db_dump_file" >&2
    echo "  -> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Implementations MUST use var $db_dump_file as input path (source file).
  if [[ -z "$ASC_DB_DEBUG" ]]; then
    hook_ms -s 'db' -a 'exec' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
  fi

  # Remove uncompressed version of the dump when we're done.
  if [[ -f "$extracted_file" ]]; then
    echo "  Removing uncompressed file '$extracted_file' (now that it's restored)."

    rm "$extracted_file"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_db_exec() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
      echo "-> Aborting (3)." >&2
      echo >&2
      exit 3
    fi
  fi
}

##
# Same as f_db_exec() but for running inline query.
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:query v:DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING
#
# @param 1 String : the query.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_query 'UPDATE users SET name = "foobar" WHERE email = "foo@bar.com";'
#
f_db_query() {
  local p_query="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  echo "Running query in $DB_DRIVER DB '$DB_NAME' ..."

  # Implementations MUST use var $p_query as input.
  if [[ -z "$ASC_DB_DEBUG" ]]; then
    hook_ms -s 'db' -a 'query' -v 'DB_DRIVER DB_ID INSTANCE_TYPE PROVISION_USING'
  else
    echo
    echo "[debug] would run query :"
    echo "$p_query"
    echo
  fi

  echo "Running query in $DB_DRIVER DB '$DB_NAME' : done."
  echo
}

##
# [abstract] Dumps database to a compressed (gz) dump file.
#
# This function does not implement the creation of the "raw" DB dump file, but
# it always compresses it after (appending ".gz" to given file path).
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# Important notes : implementations of the hook -s 'db' -a 'dump' MUST use the
# following variable in calling scope as output path (resulting file) :
#
# @var db_dump_file
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:dump v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:dump v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_dump 'path/to/dump/file.sql'
#
f_db_dump() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  if [[ -z "$ASC_DB_DUMPS_DIR" ]]; then
    echo >&2
    echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: the required global 'ASC_DB_DUMPS_DIR' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local db_dump_dir
  local db_dump_file
  local db_dump_file_name

  f_db_set "$p_db_id" "$p_force_reload_flag"

  db_dump_file="$p_dump_file_path"
  db_dump_dir="${db_dump_file%/${db_dump_file##*/}}"

  # The "backup" action should only have to create a new file. If it already
  # exists, we consider it an error. This case should be explicitly dealt with
  # beforehand (e.g. existing file deleted or moved).
  if [[ -f "$db_dump_file" ]]; then
    echo >&2
    echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: destination file '$db_dump_file' already exists." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ ! -d "$db_dump_dir" ]]; then
    mkdir -p "$db_dump_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: failed to create new backup dir '$db_dump_dir'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    fi
  fi

  # Implementations MUST use var $db_dump_file as output path (resulting file).
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_dump $p_dump_file_path $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    hook_ms -s 'db' -a 'dump' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi

  if [ ! -f "$db_dump_file" ]; then
    echo >&2
    echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: file '$db_dump_file' does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  # Compress & remove uncompressed dump file (gzip of the SQL file, not tar).
  db_dump_file_name="${db_dump_file##*/}"

  f_fs_compress "$db_dump_file" "$db_dump_dir" 'gz'

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: failed to compress dump file '$db_dump_file'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  if [[ ! -f "$db_dump_file" ]]; then
    return
  fi

  rm "$db_dump_file"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_db_dump() - $BASH_SOURCE line $LINENO: failed to remove uncompressed dump file '$db_dump_file'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
}

##
# [abstract] Clears (empties) database.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:clear v:DB_DRIVER DB_ID INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:clear v:DB_DRIVER DB_ID INSTANCE_TYPE
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_clear
#
f_db_clear() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Only attempt to clear if DB exists.
  if ! f_db_exists "$DB_NAME" "$p_db_id"; then
    echo "Notice: DB name '$DB_NAME' does not appear to exist -> skip clearing."
    return;
  fi

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_clear $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    hook_ms -s 'db' -a 'clear' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# Empties database + imports given dump file.
#
# @param 1 String : the dump file path.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_restore 'path/to/dump/file.sql'
#   f_db_restore 'path/to/dump/file.sql' 'my_custom_db_id'
#
f_db_restore() {
  local p_dump_file_path="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  if [[ ! -f "$p_dump_file_path" ]]; then
    echo >&2
    echo "Error in f_db_restore() - $BASH_SOURCE line $LINENO: the DB dump file '$p_dump_file_path' is missing or inaccessible." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  f_db_clear "$p_db_id" "$p_force_reload_flag"
  f_db_exec "$p_dump_file_path" "$p_db_id" "$p_force_reload_flag"
}

##
# Empties database + imports the last (= most recent) dump file available.
#
# @see f_fs_get_most_recent()
# @requires globals ASC_DB_DUMPS_DIR in calling scope.
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_restore_last
#
f_db_restore_last() {
  local p_db_id="$1"
  local p_subdir="$2"
  local p_force_reload_flag="$3"

  if [[ -z "$ASC_DB_DUMPS_DIR" ]]; then
    echo >&2
    echo "Error in f_db_restore_last() - $BASH_SOURCE line $LINENO: the required global 'ASC_DB_DUMPS_DIR' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  if [[ ! -d "$ASC_DB_DUMPS_DIR" ]]; then
    echo >&2
    echo "Error in f_db_restore_last() - $BASH_SOURCE line $LINENO: the dir $ASC_DB_DUMPS_DIR does not exist." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -z "$p_subdir" ]]; then
    p_subdir='local'
  fi

  f_db_restore_last_dump=''
  f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/$p_subdir/$p_db_id" '' '' '' 'f_db_restore_last_dump'
  f_db_restore \
    "$f_db_restore_last_dump" \
    "$p_db_id" \
    "$p_force_reload_flag"
}
##
# Routine local DB dump (backup).
#
# The dump file path will be determined by the following globals :
#   - ASC_DB_DUMPS_DIR
#   - ASC_DB_DUMPS_LOCAL_PATTERN
#
# @see asc/extensions/db/global.vars.sh
#
# This function writes its result to a variable subject to collision in calling
# scope :
#
# @var routine_dump_file
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_routine_backup
#   echo "routine_dump_file = $routine_dump_file"
#
#   # Resulting dump file path example :
#   # data/db-dumps/local/default/2024-08-08.17-25-29_local-default.paul.sql
#
f_db_routine_backup() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  if [[ -z "$ASC_DB_DUMPS_DIR" ]]; then
    echo >&2
    echo "Error in f_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'ASC_DB_DUMPS_DIR' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  if [[ -z "$ASC_DB_DUMPS_LOCAL_PATTERN" ]]; then
    echo >&2
    echo "Error in f_db_routine_backup() - $BASH_SOURCE line $LINENO: the required global 'ASC_DB_DUMPS_LOCAL_PATTERN' is undefined." >&2
    echo "Current instance must be (re)initialized with the 'db' extension enabled." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi

  f_db_set "$p_db_id" "$p_force_reload_flag"

  local db_routine_new_backup_file
  local db_backup_file_middle
  local db_backup_file_ext

  db_backup_file_middle="$DB_NAME"
  case "$DB_NAME" in '*')
    db_backup_file_middle="all-databases"
  esac

  # TODO [wip] Allow setting dump file extension in DB settings ?
  # Using generic extension 'dump' for now, with hardcoded extension for mysql
  # and pgsql.
  db_backup_file_ext='dump'
  case "$DB_DRIVER" in mysql|pgsql)
    db_backup_file_ext='sql'
  esac

  # Init var used in the pattern.
  # @see asc/extensions/db/global.vars.sh
  # @see f_str_convert_tokens() in
  local DUMP_FILE_EXTENSION="$db_backup_file_ext"

  f_str_convert_tokens ASC_DB_DUMPS_LOCAL_PATTERN 'db_routine_new_backup_file'

  # Debug.
  # echo "db_routine_new_backup_file = '$db_routine_new_backup_file'"

  f_db_dump \
    "$ASC_DB_DUMPS_DIR/local/$DB_ID/$db_routine_new_backup_file" \
    "$p_db_id" \
    "$p_force_reload_flag"

  # Some tasks need the generated dump file path.
  routine_dump_file="${db_routine_new_backup_file}.gz"
}

##
# Gets local instance DB dump filepath.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : Pass 'new' to create immediately a new routine
#   dump and return its file path. Pass 'last' to return the most recent dump
#   file. Any other value is a "find" file name filter that will return a single
#   matching dump (the most recent in case there are several matches).
#   Defaults to 'last'.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : subfolder in DB dumps dir.
#   Defaults to 'local'.
# @param 4 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   most_recent_dump_file="$(f_db_get_dump)"
#   echo "Result = '$most_recent_dump_file'"
#
#   new_routine_dump_file="$(f_db_get_dump 'new')"
#   echo "Result = '$new_routine_dump_file'"
#
#   initial_dump_file="$(f_db_get_dump 'initial')"
#   echo "Result = '$initial_dump_file'"
#
f_db_get_dump() {
  local p_option="$1"
  local p_db_id="$2"
  local p_subdir="$3"
  local p_force_reload_flag="$4"

  if [[ -z "$p_option" ]]; then
    p_option='last'
  fi

  if [[ -z "$p_db_id" ]]; then
    p_db_id='default'
  fi

  if [[ -z "$p_subdir" ]]; then
    p_subdir='local'
  fi

  local dump_to_return

  case "$p_option" in
    'last')
      f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/$p_subdir/$p_db_id" '' '' '' 'dump_to_return'
      ;;

    # The 'new' option means create immediately a new routine dump and return
    # its file path.
    'new')
      f_db_routine_backup "$p_db_id" "$p_force_reload_flag"
      dump_to_return="$routine_dump_file"
      ;;

    # Any other value is a "find" file name filter.
    *)
      f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/$p_subdir/$p_db_id" "$p_option" '' '' 'dump_to_return'
      ;;
  esac

  if [[ -f "$dump_to_return" ]]; then
    echo "$dump_to_return"
  fi
}

##
# Ensures the DB credentials are setup (DB user exists, has grants, etc).
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_ensure_creds
#   f_db_ensure_creds 'custom_db_id'
#
f_db_ensure_creds() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo
    echo "u_db_ensure_creds $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
    echo "  DB_USER = $DB_USER"
  else
    hook_ms -s 'db' -a 'ensure_creds' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi
}

##
# Setup a new database (create + import initial dump).
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_setup
#   f_db_setup 'custom_db_id'
#
f_db_setup() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo
    echo "u_db_setup $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # Only create the database if it does not already exist.
  if f_db_exists "$DB_NAME" "$p_db_id"; then
    echo "The $DB_ID database ('$DB_NAME') exists already."
  else
    f_db_create "$DB_ID" "$p_force_reload_flag"
  fi

  # Only move on to the initial DB import if configured to do so.
  case "$ASC_DB_INITIAL_IMPORT" in true)
    f_db_restore_any "$DB_ID"
  esac

  # Flag the DB as already setup.
  if f_db_exists "$DB_NAME" "$p_db_id"; then
    f_db_flag "$DB_ID"
  else
    f_db_unflag "$DB_ID"

    echo >&2
    echo "Error in f_db_setup() - $BASH_SOURCE line $LINENO: the $DB_ID database '$DB_NAME' was not created." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
}

##
# Restores any dump found that matches given DB ID.
#
# Attempts to download a remote dump corresponding to DB ID if none is found.
#
# The dump file can be in any subfolder, as long as it corresponds to the
# corrrect DB ID.
#
# @param 1 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   f_db_restore_any
#   f_db_restore_any 'custom_db_id'
#
f_db_restore_any() {
  local p_db_id="$1"
  local p_force_reload_flag="$2"

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_restore_any $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  fi

  # The initial dump file can be in any subfolder, as long as it corresponds to
  # the corrrect DB ID. We'll try the following folders, and use the first dump
  # file found.
  local initial_dump_file=''
  local lookup_subdir
  local lookup_subdirs_arr=()

  # If the "remote" ASC extension is enabled, look for dumps previously
  # downloaded. We can check if extension is enabled by verifying that the
  # function f_remote_get_instances() is defined.
  # @see asc/extensions/remote/remote.inc.sh
  local instance_id
  local instance_ids_arr=()

  if type f_remote_get_instances >/dev/null 2>&1 ; then
    f_remote_get_instances
  fi

  if [[ -n "${instance_ids_arr[@]}" ]]; then
    for instance_id in "${instance_ids_arr[@]}"; do
      lookup_subdirs_arr+=("$instance_id")
    done
  fi

  # Also look into local dumps.
  lookup_subdirs_arr+=('local')

  # The 'prod' remote (if it exists) dumps take priority.
  if [[ -d "$ASC_DB_DUMPS_DIR/prod/$DB_ID" ]]; then
    f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/prod/$DB_ID" '*.gz' '' '' 'initial_dump_file'
  fi

  if [[ ! -f "$initial_dump_file" ]]; then
    for lookup_subdir in "${lookup_subdirs_arr[@]}"; do
      if [[ ! -d "$ASC_DB_DUMPS_DIR/$lookup_subdir/$DB_ID" ]]; then
        continue
      fi

      f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/$lookup_subdir/$DB_ID" '*.gz' '' '' 'initial_dump_file'

      if [[ -f "$initial_dump_file" ]]; then
        break
      fi
    done
  fi

  # If there is no local DB dump found, and if the "remote_db" extension exists,
  # attempt to fetch latest remote dump file for given DB ID.
  if [[ ! -f "$initial_dump_file" ]] && [[ -n "${instance_ids_arr[@]}" ]]; then
    for instance_id in "${instance_ids_arr[@]}"; do

      # TODO [evol] do not attempt to download dump from remotes that do not
      # host given DB_ID.

      # Also this implies dependency on the remote_db extension, not always
      # enabled.

      # Debug.
      if [[ -n "$ASC_DB_DEBUG" ]]; then
        echo "  [debug] would download $DB_ID DB from $instance_id"
      else
        asc/extensions/remote_db/remote/db_download.sh "$instance_id" "$DB_ID"
      fi

      if [[ ! -d "$ASC_DB_DUMPS_DIR/$instance_id/$DB_ID" ]]; then
        continue
      fi

      f_fs_get_most_recent "$ASC_DB_DUMPS_DIR/$instance_id/$DB_ID" '*.gz' '' '' 'initial_dump_file'

      if [[ -f "$initial_dump_file" ]]; then
        break
      fi
    done
  fi

  if [[ ! -f "$initial_dump_file" ]]; then
    echo >&2
    echo "Error in f_db_restore_any() - $BASH_SOURCE line $LINENO: no dump file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  echo "Importing $DB_ID DB dump file '$initial_dump_file' ..."

  f_db_restore "$initial_dump_file" "$DB_ID"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to import initial DB dump file '$initial_dump_file'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  echo "Importing $DB_ID DB dump file '$initial_dump_file' : done."
}
