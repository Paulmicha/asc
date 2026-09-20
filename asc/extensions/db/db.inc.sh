#!/usr/bin/env bash

##
# DB credentials, ids, and flags. Sourced on every bootstrap when db is enabled.
# Dump/exec/restore/setup: `.` or caller opt-inc `db/db/db.opt-inc.sh`.
# @see changelog/2026/09/19-db-thin-inc-and-opt-inc.md
# @see asc/bootstrap.sh
#

##
# Exports the complete set of DB info by ID, and (re)sets corresponding values.
#
# Some values may be generated and stored once on first call, e.g. passwords
# when ASC_DB_MODE is set to 'auto' (or prompted when set to 'manual').
#
# @exports DB_ID - defaults to the first entry in ASC_IDS or 'default'.
# @exports DB_DRIVER - defaults to 'mysql'.
# @exports DB_HOST - defaults to 'localhost'.
# @exports DB_PORT - defaults to '3306' or '5432' if DB_DRIVER is 'pgsql'.
# @exports DB_NAME - defaults to '*' (meaning all databases at once, or global).
# @exports DB_USER - defaults to first 16 characters of DB_ID.
# @exports DB_PASS - defaults to 14 random characters.
# @exports DB_ADMIN_USER - defaults to DB_USER.
# @exports DB_ADMIN_PASS - defaults to DB_PASS.
# @exports DB_TABLES_SKIP_DATA - defaults to an empty string.
# @exports DB_DUMP_FILE_EXTENSION - defaults to 'sql'.
# @exports DB_DUMPS_LOCAL_DIR - defaults to "$ASC_DB_DUMPS_DIR/$DB_ID/local".
# @exports DB_DUMPS_PATTERN - defaults to :
#   "{{ %Y-%m-%d.%H-%M-%S }}_${db_id}.${DB_DUMP_FILE_EXTENSION}"
#
# This function also exports a prefixed version of each variable with DB_ID.
# @exports <DB_ID>_DB_* (ex: if DB_ID='default', will export DEFAULT_DB_NAME, etc.)
#
# @requires the following globals in calling scope :
# - ASC_DB_IDS
# - ASC_DB_MODE
# - ASC_DB_DUMPS_DIR
# @see asc/extensions/db/global.vars.sh
#
# Uses the following env. var. if it is defined in current shell scope to select
# which database credentials to load :
# - ASC_DB_ID
# This allows to operate on different databases from the same project instance.
# See also the first parameter to this function documented below.
#
# If ASC_DB_MODE is set to 'auto' or 'manual', the first call to this function
# will generate or prompt once the values for these globals.
# Subsequent calls to this function will then read these values from registry.
# @see asc/instance/registry/set.sh
# @see asc/instance/registry/get.sh
#
# @param 1 [optional] String : unique DB identifier. Defaults to 'default'.
#   Important note : DB_ID values are restricted to alphanumerical characters
#   and underscores (i.e. like variable names).
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#
# @example
#   # Calling this funcion without arguments = use defaults mentionned above,
#   # depending on ASC_DB_MODE (see asc/extensions/db/global.vars.sh).
#   f_db_set
#   # Result :
#   # - all DB_* variables exported contain the 'default' DB values.
#   # - a copy of every variable prefixed with DB_ID is exported. E.g. :
#   echo "$DEFAULT_DB_NAME"
#   echo "$DEFAULT_DB_USER"
#   # Etc.
#
#   # Explicitly set DB_ID (TODO [wip] write tests for multi-db projects).
#   # Alternatively, a local variable $ASC_DB_ID may be used in calling scope.
#   f_db_set id_example
#   # Or :
#   ASC_DB_ID='id_example'
#   f_db_set
#   # Result :
#   echo "$ID_EXAMPLE_DB_NAME"
#   echo "$ID_EXAMPLE_DB_USER"
#   # Etc.
#
#   # If multiple consecutive calls to this function are made in current shell
#   # scope for the same DB_ID (or without - fallback to 'default'), previously
#   # exported values will not be re-loaded.
#   # The 2nd arg is a flag which can force re-loading these values. This allows
#   # to support cases where some stored values (e.g. registry) might be updated.
#   f_db_set id_example 1
#
f_db_set() {
  local p_db_id="$1"
  local p_force_reload="$2"
  local db_id
  local asc_db_id
  local reg_val

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_set $p_db_id"
  fi

  if [[ -z "$p_db_id" ]]; then
    # TODO deprecate fallback to probably unused ASC_DB_ID ?
    if [[ -n "$ASC_DB_ID" ]]; then
      db_id="$ASC_DB_ID"
    elif [[ -n "$ASC_DB_IDS" ]]; then
      for asc_db_id in $ASC_DB_IDS; do
        db_id="$asc_db_id"
        break
      done
    else
      # TODO @deprecated : check unused + remove.
      db_id='default'
    fi
  else
    db_id="$p_db_id"
  fi

  f_str_sanitize_var_name "$db_id" 'db_id'

  if [[ -n "$DB_ID" ]]; then
    # If DB credentials vars are already exported in current shell scope for given
    # db_id, no need to reload (unless explicitly asked).
    case "$DB_ID" in "$db_id")
      if [[ -z "$p_force_reload" ]]; then
        if [[ -n "$ASC_DB_DEBUG" ]]; then
          echo "DB_ID:$DB_ID == db_id:$db_id -> skip reload"
        fi
        return
      fi
    esac

    # When DB_ID was previously set in current shell scope AND it is different
    # (or the force reload is requested), then we first need to UNSET all the
    # unprefixed DB_* variables so that the default values are properly set
    # below.
    f_db_unset
  fi

  export DB_ID="$db_id"

  # Presetting unprefixed env vars for '$DB_ID' DB based on prefixed globals,
  # if they exist (and if their values aren't empty).
  local v=''
  local db_var=''
  local prefixed_db_var=''

  f_db_vars_list

  for v in $db_vars_list; do
    case "$v" in 'ID')
      continue
    esac

    db_var="DB_$v"
    prefixed_db_var="${db_id}_${db_var}"
    f_str_uppercase "$prefixed_db_var" 'prefixed_db_var'

    if [[ -z "${!prefixed_db_var}" ]]; then
      continue
    fi

    if [[ -n "$ASC_DB_DEBUG" ]]; then
      echo "preset $db_var from $prefixed_db_var = '${!prefixed_db_var}'"
    fi

    export "$db_var=${!prefixed_db_var}"
  done

  # Give a chance to other extensions to preset non-readonly env vars, including
  # per STACK_VERSION and DB_ID.
  # make hook-debug s:db a:env_preset v:INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID
  hook -s 'db' -a 'env_preset' -v 'INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID'

  # <Hardcoded defaults provided by ASC "core">
  export DB_DRIVER="${DB_DRIVER:-"mysql"}"
  # TODO @deprecated [evol] Remove wildcard support (leave empty instead).
  export DB_NAME="${DB_NAME:-""}"
  export DB_HOST="${DB_HOST:-"localhost"}"

  # TODO [evol] should ASC hardcode generic ports mapping or delegate to
  # extensions (more hooks...) ?
  case "$DB_DRIVER" in
    pgsql)  export DB_PORT="${DB_PORT:-"5432"}" ;;
    *)      export DB_PORT="${DB_PORT:-"3306"}" ;;
  esac

  export DB_TABLES_SKIP_DATA="${DB_TABLES_SKIP_DATA:-""}"
  export DB_DUMP_FILE_EXTENSION="${DB_TABLES_SKIP_DATA:-"sql"}"
  export DB_DUMPS_LOCAL_DIR="${DB_DUMPS_LOCAL_DIR:-"$ASC_DB_DUMPS_DIR/local/$DB_ID"}"
  export DB_DUMPS_PATTERN="${DB_DUMPS_PATTERN:-"{{ %Y-%m-%d.%H-%M-%S }}_${db_id}.${DB_DUMP_FILE_EXTENSION}"}"
  # </Hardcoded defaults provided by ASC "core">

  case "$ASC_DB_MODE" in
    # Some environments do not require ASC to handle DB credentials at all.
    # In these cases, the following global env vars should be provided in
    # calling scope - e.g. in the env preset hook (see above) :
    # - $DB_USER
    # - $DB_PASS
    none)
      case "$DB_DRIVER" in
        # Most MySQL tasks (create DB/user/grants) require an admin account.
        mysql)
          export DB_ADMIN_USER="${DB_ADMIN_USER:-"root"}"
          export DB_ADMIN_PASS="${DB_ADMIN_PASS:-"$DB_PASS"}"
          ;;
        *)
          export DB_ADMIN_USER="${DB_ADMIN_USER:-"$DB_USER"}"
          export DB_ADMIN_PASS="${DB_ADMIN_PASS:-"$DB_PASS"}"
          ;;
      esac
      return
      ;;

    # The 'auto' mode means we only store the password, which gets generated
    # once on first call (and read otherwise).
    # Other values will be assigned default values unless the following global
    # env vars are already set in calling scope :
    # - $DB_DRIVER defaults to mysql
    # - $DB_NAME defaults to $DB_ID
    # - $DB_USER defaults to $DB_ID
    # - $DB_HOST defaults to localhost
    # - $DB_PORT defaults to 3306 or 5432 if DB_DRIVER is 'pgsql'
    # - $DB_ADMIN_USER defaults to $DB_USER
    # - $DB_ADMIN_PASS defaults to $DB_PASS
    # - $DB_TABLES_SKIP_DATA defaults to an empty string
    auto)
      if [[ -z "$DB_USER" ]]; then
        export DB_USER="$DB_ID"
        # Limit automatically generated user name to 16 or 32 characters,
        # depending on the driver used by current database ID. Prevents errors
        # like "MySQL ERROR 1470 (HY000) String is too long for user name".
        # Warning : this creates naming collision risks (considered edge case).
        case "$DB_DRIVER" in
          pgsql) DB_USER="${DB_USER:0:32}" ;;
          mysql) DB_USER="${DB_USER:0:16}" ;;
        esac
      fi

      if [[ -z "$DB_PASS" ]]; then
        # Attempts to load password from registry (secrets store).
        # Warning : if asc/extensions/file_registry is used as registry storage
        # backend, no encryption will be used. This may be fine for local dev - e.g.
        # in temporary virtual machines inaccessible to the outside world, but
        # it is obviously a security risk.
        reg_val=''
        f_instance_registry_get "${db_id}.DB_PASS"

        # Generate random local instance DB password and store it for subsequent
        # calls.
        if [[ -z "$reg_val" ]]; then
          export DB_PASS="$(< /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)"
          f_instance_registry_set "${db_id}.DB_PASS" "$DB_PASS"
        else
          export DB_PASS="$reg_val"
        fi
      fi

      case "$DB_DRIVER" in
        # Most MySQL tasks (create DB/user/grants) require an admin account.
        mysql)
          export DB_ADMIN_USER="${DB_ADMIN_USER:-"root"}"
          export DB_ADMIN_PASS="${DB_ADMIN_PASS:-"$DB_PASS"}"
          ;;
        *)
          export DB_ADMIN_USER="${DB_ADMIN_USER:-$DB_USER}"
          export DB_ADMIN_PASS="${DB_ADMIN_PASS:-$DB_PASS}"
          ;;
      esac
    ;;
  esac

  # Finally, export prefixed DB_* vars.
  v=''
  db_var=''
  prefixed_db_var=''

  f_db_vars_list

  for v in $db_vars_list; do
    db_var="DB_$v"
    prefixed_db_var="${db_id}_${db_var}"
    f_str_uppercase "$prefixed_db_var" 'prefixed_db_var'
    export "$prefixed_db_var=${!db_var}"
  done

  # Allow bash aliases to be adapted to the currently active DB_ID.
  # @see asc/extensions/mysql/asc/alias.compose.hook.sh
  hook -s 'asc' -a 'alias' -v 'STACK_VERSION PROVISION_USING'

  # Failsafe.
  if [[ -z "$DB_NAME" ]]; then
    echo >&2
    echo "Error in f_db_set() - $BASH_SOURCE line $LINENO: DB_NAME is empty." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
}

##
# Unsets all DB_* variables so that the correct values can then be (re)set.
#
# Required because the default values would not be correctly set if we switched
# between databases in the same shell scope - i.e. as in f_db_set_all()
#
# @see f_db_set()
#
f_db_unset() {
  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    echo "u_db_unset"
  fi

  local v

  f_db_vars_list

  for v in $db_vars_list; do
    eval "unset DB_$v"
  done

  # Also need to reset the variable allowing to target a specific docker-compose
  # service depending on the currently active DB_ID.
  # @see asc/extensions/mysql/asc/alias.compose.hook.sh
  if [[ -n "$dc_db_service_name" ]]; then
    unset dc_db_service_name
  fi
}

##
# Gets an array of all database IDs defined in current project instance.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var db_ids_arr
#
# @example
#   db_ids_arr=()
#   f_db_get_ids
#   echo "${db_ids_arr[@]}"
#
f_db_get_ids() {
  local db_id
  local multi_db_ids=''

  # Support multi-DB projects defined using the "append"-type global ASC_DB_IDS.
  # Defaults to ASC_APPS.
  if [[ -n "$ASC_DB_IDS" ]]; then
    for db_id in $ASC_DB_IDS; do
      f_array_add_once "$db_id" db_ids_arr
    done
  elif [[ -n "$ASC_APPS" ]]; then
    for asc_app in $ASC_APPS; do
      f_array_add_once "$asc_app" db_ids_arr
    done
  fi

  # Let extensions define their own additional DB_IDs.
  # They need to append values to the string :
  # @var multi_db_ids
  hook -s 'db' -a 'set_multi_db_ids' -v 'INSTANCE_TYPE'

  if [[ -n "$multi_db_ids" ]]; then
    for db_id in $multi_db_ids; do
      f_array_add_once "$db_id" db_ids_arr
    done
  fi
}

##
# Exports all locally-defined DB credentials (multi-DB support).
#
# There are 2 ways to declare the different databases that the local project
# instance will use :
#   1. Using the read-only "append-type" global ASC_DB_IDS
#   2. Implementing hook -s 'db' -a 'set_multi_db_ids' -v 'INSTANCE_TYPE'
#     (adding space-separated values to scoped variable multi_db_ids).
# @see f_db_set()
#
# @example
#   f_db_set_all
#   # Result (given 2 ids : 'default' + 'example') :
#   echo "$DB_ID" # <- Prints 'default'
#   echo "$DB_USER" # <- Prints the user name for 'default' database.
#   echo "$EXAMPLE_DB_USER" # <- Prints the user name for 'example' database.
#   # etc.
#
f_db_set_all() {
  local db_id
  local db_ids_arr=()

  f_db_get_ids

  if [[ -n "${db_ids_arr[@]}" ]]; then
    for db_id in "${db_ids_arr[@]}"; do
      # Default DB will be loaded last, see below.
      case "$db_id" in 'default')
        continue
      esac
      f_db_set "$db_id"
    done
  fi

  # Default DB is loaded last. This allows for the DB "selected" by default
  # after ASC bootstrap is done to be DB_ID='default'.
  f_db_set
}

##
# Single source of truth : get the list of DB vars.
#
# This funtion writes its result to a variable subject to collision in calling
# scope :
#
# @var db_vars_list
#
# @example
#   f_db_vars_list
#   echo "$db_vars_list"
#
f_db_vars_list() {
  db_vars_list='ID DRIVER HOST PORT NAME USER PASS ADMIN_USER ADMIN_PASS TABLES_SKIP_DATA DUMP_FILE_EXTENSION DUMPS_LOCAL_DIR DUMPS_PATTERN'
}

##
# [abstract] Detects if a database already exists.
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:db a:exists v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# To check the most specific match (if any is found) :
# $ make hook-debug ms s:db a:exists v:DB_DRIVER HOST_TYPE INSTANCE_TYPE
#
# @param 1 String : the database name to check.
# @param 2 [optional] String : the database ID ($DB_ID), see f_db_set().
#   Defaults to 'default'.
# @param 3 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   if f_db_exists 'my_db_name'; then
#     echo "Ok, 'my_db_name' exists."
#   else
#     echo "Error : 'my_db_name' does not exist (or I do not have permission to access it)."
#   fi
#
f_db_exists() {
  local p_db_name="$1"
  local p_db_id="$2"
  local p_force_reload_flag="$3"

  local db_exists=''

  f_db_set "$p_db_id" "$p_force_reload_flag"

  # Debug.
  if [[ -n "$ASC_DB_DEBUG" ]]; then
    db_exists=true
    echo "u_db_exists $p_db_name $p_db_id"
    echo "  DB_HOST = $DB_HOST"
    echo "  DB_NAME = $DB_NAME"
  else
    hook_ms -s 'db' -a 'exists' -v 'DB_DRIVER DB_ID INSTANCE_TYPE'
  fi

  case "$db_exists" in true)
    return 0
  esac

  return 1
}

##
# Checks if given DB has already been flagged using local registry.
#
# It checks by default the flag to know if the DB is already setup (created).
# This allows to skip wait_for() calls for DB services started but with DBs not
# created yet.
#
# @see asc/instance/setup.sh
# @see asc/extensions/drush/instance/wait_for.compose.hook.sh
# @see f_instance_registry_get() in asc/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   # Checks the default flag - to know if the DB is already setup (created).
#   if f_db_is_flagged 'my_db_id'; then
#     echo "Yes, 'my_db_id' was already setup."
#   else
#     echo "No."
#   fi
#
#   # Works for any flag. Negative check example :
#   if ! f_db_is_flagged 'my_db_id' 'is_locked'; then
#     echo "No, 'my_db_id' is not locked."
#   fi
#
f_db_is_flagged() {
  local reg_val

  f_db_get_flag_key $@
  f_instance_registry_get "$key"

  if [[ -n "$reg_val" ]]; then
    return 0
  fi

  return 1
}

##
# Flags given DB as already setup (created) using local registry.
#
# @see f_db_is_already_setup()
# @see asc/instance/setup.sh
# @see asc/extensions/drush/instance/wait_for.compose.hook.sh
# @see f_instance_registry_set() in asc/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   f_db_mark_as_already_setup 'site'
#
f_db_flag() {
  f_db_get_flag_key $@
  f_instance_registry_set "$key" true
}

##
# Flags all defined DB_IDs using local registry.
#
# @see f_db_unflag()
#
# @param 1 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   f_db_flag_all
#
f_db_flag_all() {
  local db_id
  local db_ids_arr=()

  f_db_get_ids

  if [[ -n "${db_ids_arr[@]}" ]]; then
    for db_id in "${db_ids_arr[@]}"; do
      f_db_flag "$db_id" "$1"
    done
  fi
}

##
# Unflags given DB as already setup (created) using local registry.
#
# @see f_db_is_already_setup()
# @see asc/instance/setup.sh
# @see asc/extensions/drush/instance/wait_for.compose.hook.sh
# @see f_instance_registry_del() in asc/instance/instance.inc.sh
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   f_db_mark_as_already_setup 'site'
#
f_db_unflag() {
  f_db_get_flag_key $@
  f_instance_registry_del "$key"
}

##
# Unflags all defined DB_IDs using local registry.
#
# @see f_db_unflag()
#
# @param 1 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   f_db_unflag_all
#
f_db_unflag_all() {
  local db_id
  local db_ids_arr=()

  f_db_get_ids

  if [[ -n "${db_ids_arr[@]}" ]]; then
    for db_id in "${db_ids_arr[@]}"; do
      f_db_unflag "$db_id" "$1"
    done
  fi
}

##
# Single source of truth for DB flags registry keys.
#
# Uses STACK_VERSION if set.
# This funtion writes its result to a variable subject to collision in calling
# scope :
#
# @var key
#
# @param 1 String : the database ID ($DB_ID).
# @param 2 [optional] String : the flag. Defaults to 'is_already_setup'.
#
# @example
#   f_db_get_flag_key 'site' 'is_already_setup'
#   echo "key = $key"
#
f_db_get_flag_key() {
  local p_db_id="$1"
  local p_flag="$2"

  if [[ -z "$p_flag" ]]; then
    p_flag='is_already_setup'
  fi

  key="db_${p_db_id}_flag_${p_flag}"

  if [[ -n "$STACK_VERSION" ]]; then
    key="db_${STACK_VERSION}_${p_db_id}_flag_${p_flag}"
  fi
}

