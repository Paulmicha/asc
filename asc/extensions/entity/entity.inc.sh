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
  local cache="data/asc/cache/entities/${p_entity_type}/${p_entity_id}.sh"

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
# Appends spec field names for an entity type onto keys_arr.
#
# Always includes id. Other names come from the type YAML required.field /
# optional.field (type file only; no include merge). Callers initialize keys_arr.
# Hardcoded remote dump/file keys stay in f_remote_definition_get_keys.
#
# @var keys_arr
#
# @param 1 String : entity type.
#
# @example
#   keys_arr=()
#   f_entity_spec_get_keys host
#
#   for key in "${keys_arr[@]}"; do
#     echo "key = $key"
#   done
#
f_entity_spec_get_keys() {
  local p_type="$1"
  local type_file parsed key
  local yaml_prefix='esgk_'

  if [[ -z "$p_type" ]]; then
    echo >&2
    echo "Error in f_entity_spec_get_keys() - $BASH_SOURCE line $LINENO: missing entity type." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  entity_type_file=''
  f_entity_type_file "$p_type" || return 1
  type_file="$entity_type_file"

  f_array_add_once 'id' keys_arr

  parsed=''
  f_yaml_parse "$type_file" "$yaml_prefix" 'parsed'

  f_yaml_get_keys "$parsed" "${yaml_prefix}required_field_"
  for key in "${yaml_keys_arr[@]}"; do
    [[ -n "$key" ]] || continue
    f_array_add_once "$key" keys_arr
  done

  f_yaml_get_keys "$parsed" "${yaml_prefix}optional_field_"
  for key in "${yaml_keys_arr[@]}"; do
    [[ -n "$key" ]] || continue
    f_array_add_once "$key" keys_arr
  done
}

##
# Reads one cached entity field, optionally replacing tokens in the value.
#
# @param 1 String : entity type.
# @param 2 String : entity id.
# @param 3 String : field name (hostname, id, …).
# @param 4 [optional] String : output variable name. Defaults to param 3.
# @param 5 [optional] String : non-empty skips f_str_convert_tokens.
#
# @example
#   out=''
#   f_entity_spec_get_key host foobar.home.arpa hostname out
#   echo "out = $out"
#
f_entity_spec_get_key() {
  local p_type="$1"
  local p_id="$2"
  local p_key="$3"
  local p_out="$4"
  local p_skip_token_replacement="$5"
  local pfx='' KEY='' var='' val='' tokens_input=''

  if [[ -z "$p_out" ]]; then
    p_out="$p_key"
  fi

  if [[ -z "$p_type" || -z "$p_id" || -z "$p_key" ]]; then
    echo >&2
    echo "Error in f_entity_spec_get_key() - $BASH_SOURCE line $LINENO: missing entity type, id, or key." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_entity_load "$p_type" "$p_id" || return 1

  f_entity_type_prefix "$p_type" 'pfx'
  f_str_uppercase "$p_key" 'KEY'
  var="${pfx}_$KEY"
  val="${!var}"

  if [[ -z "$val" ]]; then
    printf -v "$p_out" '%s' ""
    return
  fi

  if [[ -z "$p_skip_token_replacement" ]]; then
    tokens_input="$val"
    f_str_convert_tokens tokens_input 'tokens_input'
    printf -v "$p_out" '%s' "$tokens_input"
  else
    printf -v "$p_out" '%s' "$val"
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
  local cache_dir="data/asc/cache/entities/${p_entity_type}"
  local file=''

  if [[ -z "$p_entity_type" ]]; then
    echo >&2
    echo "Error in f_entity_cache_purge() - $BASH_SOURCE line $LINENO: missing entity type." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  echo "Clearing '$p_entity_type' entity instances cache entries ..."

  if [[ ! -d "$cache_dir" ]]; then
    echo "Clearing '$p_entity_type' entity instances cache entries : done."
    echo
    return 0
  fi

  f_fs_file_list "$cache_dir"

  for file in $file_list; do
    rm "${cache_dir}/${file}"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in f_entity_cache_purge() - $BASH_SOURCE line $LINENO: failed to remove locally generated entity instance '$file' (in ${cache_dir})." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      return 1
    fi
  done

  echo "Clearing '$p_entity_type' entity instances cache entries : done."
  echo
}

##
# Adds *.entity.yml stems from one directory onto entity_types_arr.
#
# Type id = filename stem (host.entity.yml → host). Duplicate stems keep the
# first array slot; a later file of the same stem still "wins" as the same id.
# Does not glob *.able.yml (contracts are not types).
#
# @var entity_types_arr
#
# @param 1 String : directory to scan.
# @param 2 [optional] Integer max depth (defaults to 1).
#
f_entity_types_collect_dir() {
  local p_dir="$1"
  local p_depth="${2:-1}"
  local file stem

  f_fs_file_list "$p_dir" '*.entity.yml' "$p_depth"

  for file in $file_list; do
    stem="${file##*/}"
    stem="${stem%.entity.yml}"
    [[ -n "$stem" ]] || continue
    f_array_add_once "$stem" entity_types_arr
  done
}

##
# Discovers entity types from *.entity.yml in enabled dirs.
#
# Walk order is generic → specific (README Specificity). Later assignment wins
# for duplicate stems. Skips extension dirs not in $ASC_EXTENSIONS. YAML
# Overrides (`scripts/asc/override`) are skipped this slice.
#
# Writes data/asc/cache/entities/types.sh and sets calling-scope entity_types_arr.
#
# @var entity_types_arr
#
f_entity_types_discover() {
  entity_types_arr=()
  local dir extension ext_path depth

  f_entity_types_collect_dir 'asc'

  for dir in $ASC_SUBJECTS; do
    f_entity_types_collect_dir "asc/${dir}"
  done

  for extension in $ASC_EXTENSIONS; do
    ext_path=''
    f_asc_extension_path "$extension"
    depth=2
    case "$extension" in
      */*) depth=5 ;;
    esac
    f_entity_types_collect_dir "${ext_path}/${extension}" "$depth"
  done

  mkdir -p data/asc/cache/entities
  {
    echo '#!/usr/bin/env bash'
    echo
    echo 'entity_types_arr=()'
    for stem in "${entity_types_arr[@]}"; do
      printf "entity_types_arr+=('%s')\n" "$stem"
    done
  } > data/asc/cache/entities/types.sh
}

##
# Records the deepest *.entity.yml in one dir whose stem matches p_type.
#
# Later collect calls overwrite (generic → specific). Same-dir duplicates keep
# the path with more slashes (extension subject dir beats extension root).
#
# @var entity_type_file
#
# @param 1 String : directory to scan.
# @param 2 String : type stem (host.entity.yml → host).
# @param 3 [optional] Integer max depth (defaults to 1).
#
f_entity_type_file_collect() {
  local p_dir="$1"
  local p_type="$2"
  local p_depth="${3:-1}"
  local file stem n
  local best=''
  local best_n=-1

  f_fs_file_list "$p_dir" '*.entity.yml' "$p_depth"

  for file in $file_list; do
    stem="${file##*/}"
    stem="${stem%.entity.yml}"
    [[ "$stem" == "$p_type" ]] || continue
    n="${file//[^\/]}"
    n="${#n}"
    if [[ -z "$best" || "$n" -ge "$best_n" ]]; then
      best="${p_dir}/${file}"
      best_n="$n"
    fi
  done

  if [[ -n "$best" ]]; then
    entity_type_file="$best"
  fi
}

##
# Resolves the most-specific *.entity.yml path for a type stem.
#
# Same walk as f_entity_types_discover. Writes calling-scope entity_type_file.
#
# @var entity_type_file
#
# @param 1 String : entity type (filename stem).
# @param 2 [optional] String : output variable name. Defaults to entity_type_file.
#
f_entity_type_file() {
  local p_type="$1"
  local p_out="${2:-entity_type_file}"
  local dir extension ext_path depth

  entity_type_file=''

  if [[ -z "$p_type" ]]; then
    printf -v "$p_out" '%s' ''
    return 1
  fi

  f_entity_type_file_collect 'asc' "$p_type"

  for dir in $ASC_SUBJECTS; do
    f_entity_type_file_collect "asc/${dir}" "$p_type"
  done

  for extension in $ASC_EXTENSIONS; do
    ext_path=''
    f_asc_extension_path "$extension"
    depth=2
    case "$extension" in
      */*) depth=5 ;;
    esac
    f_entity_type_file_collect "${ext_path}/${extension}" "$p_type" "$depth"
  done

  printf -v "$p_out" '%s' "$entity_type_file"

  if [[ -n "$entity_type_file" && -f "$entity_type_file" ]]; then
    return 0
  fi
  return 1
}

##
# Return 0 if type YAML include chain contains the contract stem.
#
# Walks include: on *.entity.yml only (no override/alter/append). Stops on
# cycles. Contract files (*.able) are matched, not opened.
#
# @param 1 String : entity type stem (host).
# @param 2 String : contract stem (sidecar.able).
# @param 3 [optional] String : non-empty when already walking (do not reset).
#
f_entity_type_includes_able() {
  local p_type="$1"
  local p_able="$2"
  local p_walking="$3"
  local type_file parsed line inc next_type
  local -a einc_include=()

  if [[ -z "$p_type" || -z "$p_able" ]]; then
    return 1
  fi

  if [[ -z "$p_walking" ]]; then
    unset _entity_able_seen_dict
    declare -gA _entity_able_seen_dict
  fi

  if [[ -n "${_entity_able_seen_dict[$p_type]:-}" ]]; then
    return 1
  fi
  _entity_able_seen_dict[$p_type]=1

  entity_type_file=''
  f_entity_type_file "$p_type" || return 1
  type_file="$entity_type_file"

  parsed=''
  f_yaml_parse "$type_file" 'einc_' 'parsed'
  while IFS= read -r line; do
    case "$line" in
      einc_include+=*|einc_include=*)
        eval "$line"
        ;;
    esac
  done <<< "$parsed"

  for inc in "${einc_include[@]}"; do
    inc="${inc%.yml}"
    if [[ "$inc" == "$p_able" ]]; then
      return 0
    fi
    case "$inc" in
      *.able)
        continue
        ;;
      *.entity)
        next_type="${inc%.entity}"
        if f_entity_type_includes_able "$next_type" "$p_able" walking; then
          return 0
        fi
        ;;
    esac
  done

  return 1
}

##
# Discovers concrete instances of sidecar.able types under data/entities/<type>/.
#
# Instance id is the YAML filename stem (foobar.home.arpa.yml → foobar.home.arpa).
# Missing data/entities/<type>/ means zero file instances (OK). Types that do
# not include sidecar.able are skipped. Parallel arrays avoid splitting ids on /.
#
# @var entity_instance_types_arr
# @var entity_instance_ids_arr
# @var entity_types_arr
#
f_entity_instances_discover() {
  entity_instance_types_arr=()
  entity_instance_ids_arr=()
  local type file id

  if [[ ${#entity_types_arr[@]} -eq 0 ]]; then
    f_entity_types_discover
  fi

  for type in "${entity_types_arr[@]}"; do
    if ! f_entity_type_includes_able "$type" 'sidecar.able'; then
      continue
    fi
    [[ -d "data/entities/${type}" ]] || continue
    f_fs_file_list "data/entities/${type}" '*.yml'
    for file in $file_list; do
      id="${file%.yml}"
      [[ -n "$id" ]] || continue
      entity_instance_types_arr+=("$type")
      entity_instance_ids_arr+=("$id")
    done
  done
}

##
# Uppercased sanitized prefix for entity cache exports (host → HOST).
#
# @param 1 String : entity type.
# @param 2 [optional] String : output variable name. Defaults to entity_type_prefix.
#
f_entity_type_prefix() {
  local p_type="$1"
  local p_out="${2:-entity_type_prefix}"
  local sanitized=''

  f_str_sanitize_var_name "$p_type" 'sanitized'
  f_str_uppercase "$sanitized" "$p_out"
}

##
# Return 0 if a flattened YAML key’s root is reserved (not an instance field).
#
# @param 1 String : flattened key (include, ssh_user, required_field_hostname).
#
f_entity_key_is_reserved() {
  local root="${1%%_*}"

  case "$root" in
    synonym|include|includes|required|optional|append|alter|override|map) return 0 ;;
  esac
  return 1
}

##
# Writes data/asc/cache/entities/<type>/<id>.sh from a sidecar.able instance YAML.
#
# Flattens nested keys (ssh.user → ssh_user → HOST_SSH_USER). Skips reserved
# roots, empty values, and type (no HOST_TYPE / INSTANCE_TYPE). Does not merge
# the type file into the instance. For host / remote_host, filename fills
# hostname when missing. Always exports PREFIX_ID from the instance id.
#
# @param 1 String : entity type.
# @param 2 String : entity id (YAML filename stem).
#
f_entity_cache_generate() {
  local p_type="$1"
  local p_id="$2"
  local sidecar="data/entities/${p_type}/${p_id}.yml"
  local cache="data/asc/cache/entities/${p_type}/${p_id}.sh"
  local parsed=''
  local yaml_prefix='eicg_'
  local line lhs key raw val prefix sorted_keys var
  local -A eicg_dict

  if [[ -z "$p_type" || -z "$p_id" ]]; then
    echo >&2
    echo "Error in f_entity_cache_generate() - $BASH_SOURCE line $LINENO: missing entity type or id." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ ! -f "$sidecar" ]]; then
    echo >&2
    echo "Error in f_entity_cache_generate() - $BASH_SOURCE line $LINENO: file '$sidecar' not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  eicg_dict=()
  eicg_dict[id]="$p_id"

  f_yaml_parse "$sidecar" "$yaml_prefix" 'parsed'

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    case "$line" in
      eicg_*) ;;
      *) continue ;;
    esac

    lhs="${line%%=*}"
    lhs="${lhs%+}"
    key="${lhs#eicg_}"
    [[ -n "$key" ]] || continue

    if f_entity_key_is_reserved "$key"; then
      continue
    fi

    case "$key" in
      type|id) continue ;;
    esac

    raw="${line#*=}"
    raw="${raw#(}"
    raw="${raw%)}"
    val="$raw"
    val="${val%\'}"
    val="${val#\'}"
    val="${val%\"}"
    val="${val#\"}"
    [[ -n "$val" ]] || continue

    eicg_dict["$key"]="$val"
  done <<< "$parsed"

  case "$p_type" in
    host|remote_host)
      if [[ -z "${eicg_dict[hostname]:-}" ]]; then
        eicg_dict[hostname]="$p_id"
      fi
      ;;
  esac

  mkdir -p "data/asc/cache/entities/${p_type}"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in f_entity_cache_generate() - $BASH_SOURCE line $LINENO: failed to create missing required dir data/asc/cache/entities/${p_type}." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  prefix=''
  f_entity_type_prefix "$p_type" 'prefix'
  sorted_keys="$(for key in "${!eicg_dict[@]}"; do printf '%s\n' "$key"; done | sort)"

  {
    echo '#!/usr/bin/env bash'
    echo
    while IFS= read -r key; do
      [[ -n "$key" ]] || continue
      var="${prefix}_${key}"
      f_str_uppercase "$var" 'var'
      val="${eicg_dict[$key]}"
      val="${val//\'/\'\"\'\"\'}"
      printf "%s\n" "export ${var}='${val}'"
    done <<< "$sorted_keys"
  } > "$cache"
}

##
# Generates load cache files for every discovered sidecar.able instance.
#
# Purges each sidecar.able type dir first (stale ids from data/entities). Does
# not wipe data/asc/cache/entities wholesale (other compilers may write there).
#
# @var entity_instance_types_arr
# @var entity_instance_ids_arr
# @var entity_types_arr
#
f_entity_cache_generate_all() {
  local i type
  local -A sidecar_purged

  f_entity_instances_discover

  sidecar_purged=()
  for type in "${entity_types_arr[@]}"; do
    [[ -n "${sidecar_purged[$type]:-}" ]] && continue
    if f_entity_type_includes_able "$type" 'sidecar.able'; then
      f_entity_cache_purge "$type" || return 1
      sidecar_purged["$type"]=1
    fi
  done

  for i in "${!entity_instance_ids_arr[@]}"; do
    f_entity_cache_generate \
      "${entity_instance_types_arr[$i]}" \
      "${entity_instance_ids_arr[$i]}" || return 1
  done
}
