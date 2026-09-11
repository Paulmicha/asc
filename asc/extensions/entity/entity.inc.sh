#!/usr/bin/env bash

##
# Entity-related functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#

##
# Loads cached entity values in current shell scope.
#
# @param 1 String : entity type.
# @param 2 String : entity id (short name, no space, _a-zA-Z0-9 only).
#
# @example
#   f_entity_load host foobar.home.arpa
#
f_entity_load() {
  local p_entity_type="$1"
  local p_entity_id="$2"
  local cache="asc/cache/entities/$p_entity_type/${p_entity_id}.sh"

  if [[ ! -f "$cache" ]]; then
    echo >&2
    echo "Error in f_entity_load() - $BASH_SOURCE line $LINENO: file '$cache' not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  . "$cache"
}

##
# Writes entity instance either to data/entities or in another storage like DB.
#
# f_entity_instanciate() {
#   # TODO @see README.md
# }

##
# Produces an array of keys for entity definitions.
#
# This function appends entries to an array which must be initialized in calling
# scope already :
#
# @var keys_arr
#
# @example
#   keys=()
#   f_entity_spec_get_keys
#
#   for key in "${keys_arr[@]}"; do
#     echo "key = $key"
#   done
#
f_entity_spec_get_keys() {
  # TODO adapt this.
  # @see README.md
  keys_arr+=('id')
  keys_arr+=('host')
  keys_arr+=('domain')
  keys_arr+=('docroot')
  keys_arr+=('prefix')
  keys_arr+=('ssh_user')
  keys_arr+=('ssh_port')
  keys_arr+=('ssh_exec_prefix')
  keys_arr+=('ssh_connect_cmd')
  keys_arr+=('dumps_datestamp')

  # Remote files are a dynamic list of names (suffixes) used to assign variables
  # to folders to sync to and from (anb between) entities. It's meant
  # for files that are not part of the versionned app sources, e.g. git-ignored
  # dirs like sites/default/files in Drupal, etc.
  if [[ -n "$ASC_REMOTE_FILES_SUFFIXES" ]]; then
    local suffix=''

    for suffix in $ASC_REMOTE_FILES_SUFFIXES; do
      f_str_sanitize_var_name "$suffix" 'suffix'
      keys_arr+=("files_${suffix}_remote")
      keys_arr+=("files_${suffix}_local")
    done
  fi

  # The DB-related config entries need dynamic var names.
  # Needs the 'db' ASC extension, which might be disabled, so we check if
  # function is defined.
  if type f_db_get_ids >/dev/null 2>&1 ; then
    local db_id
    local db_ids_arr=()

    f_db_get_ids

    for db_id in "${db_ids_arr[@]}"; do
      keys_arr+=("dumps_${db_id}_base_dir")
      keys_arr+=("dumps_${db_id}_file")
      keys_arr+=("dumps_${db_id}_latest_symlink")
      keys_arr+=("dumps_${db_id}_type")
      keys_arr+=("dumps_${db_id}_cmd")

      # TODO [evol] does it make sense to keep a trace of the latest datestamp ?
      # As an alternative to symlinks - because the download of the latest dump
      # will currently always result in the same file name locally...
      # keys_arr+=("dumps_${db_id}_datestamp")
    done

    # In order to generate remote commands like mysql dump, in some cases, there
    # are credentials available remotely as env vars (which can be loaded
    # through ssh_exec_prefix if necessary). Hence the use of a mapping
    # definition, so the command can be properly formed (to be able to use the
    # correct remote env vars).
    local var=''
    local vars_to_map='db_driver db_host db_port db_name db_user db_pass db_admin_user db_admin_pass'

    for var in $vars_to_map; do
      keys_arr+=("dumps_${db_id}_env_map_${var}")
    done
  fi

  # Allows other extensions to alter the list of keys.
  hook -s 'entity_spec_keys' -a 'alter' -v 'REMOTE_INSTANCE_ID'
}

##
# TODO adapt this.
# @see README.md
#
# For any given entity, get a single key value.
#
# @param 1 String : entity ID.
# @param 2 String : key of the value to read from its definition.
# @param 3 [optional] String : name of the variable in calling scope which holds
#   the result. Defaults to "$2".
# @param 4 [optional] String : flag to skip tokens replacement.
#   Defaults to an empty string, meaning : don't skip.
#
# @example
#   remote_dir=''
#   f_entity_spec_get_key 'prod' 'files_private_remote' 'remote_dir'
#   echo "remote_dir = $remote_dir"
#
f_entity_spec_get_key() {
  local p_remote_id="$1"
  local p_key="$2"
  local p_rdgk_var="$3"
  local p_skip_token_replacement="$4"

  if [[ -z "$p_rdgk_var" ]]; then
    p_rdgk_var="$p_key"
  fi

  # Only load the entity definition if not already loaded.
  if [[ -z "$REMOTE_INSTANCE_ID" || "$REMOTE_INSTANCE_ID" != "$p_remote_id" ]]; then
    f_entity_load "$p_remote_id"
  fi

  local var=''
  local val=''
  local KEY=''

  f_str_uppercase "$p_key" 'KEY'

  var="REMOTE_INSTANCE_$KEY"
  val="${!var}"

  # Skip tokens if empty.
  if [[ -z "$val" ]]; then
    printf -v "$p_rdgk_var" '%s' ""
    return
  fi

  # Replace tokens.
  if [[ -z "$p_skip_token_replacement" ]]; then
    local tokens_replaced=''
    f_str_convert_tokens "$p_remote_id" "$val"

    # Write result to var in calling scope.
    printf -v "$p_rdgk_var" '%s' "$tokens_replaced"
  else
    printf -v "$p_rdgk_var" '%s' "$val"
  fi
}

##
# Purges entity instances cache entries by type.
#
# @param 1 String : entity type.
#
# @example
#   f_entity_cache_purge host
#
f_entity_cache_purge() {
  local p_entity_type="$1"
  local file=''

  echo "Clearing '$p_entity_type' entity instances cache entries ..."

  f_fs_file_list "asc/cache/entities/$p_entity_type"

  for file in $file_list; do
    rm "asc/cache/entities/$file"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_entity_cache_purge() - $BASH_SOURCE line $LINENO: failed to remove locally generated entity instance '$file' (in asc/cache/entities/$p_entity_type)." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      return 1
    fi
  done

  echo "Clearing '$p_entity_type' entity instances cache entries : done."
  echo
}
