#!/usr/bin/env bash

##
# Entity type / instance discovery and load-cache tests.
#
# @requires asc/vendor/shunit2
#
. asc/bootstrap.sh

oneTimeSetUp() {
  mkdir -p data/asc/cache/entities/_probe
  cat > data/asc/cache/entities/_probe/alpha.sh <<'EOF'
export _PROBE_ID='alpha'
export _PROBE_OS='debian'
EOF
}

oneTimeTearDown() {
  rm -rf data/asc/cache/entities/_probe
}

test_entity_load_is_defined() {
  assertEquals 'function' "$(type -t f_entity_load)"
}

test_entity_load_requires_type_and_id() {
  f_entity_load >/dev/null 2>&1
  assertNotEquals 'must fail without args' '0' "$?"
  f_entity_load _probe >/dev/null 2>&1
  assertNotEquals 'must fail without id' '0' "$?"
}

test_entity_load_missing_cache_fails() {
  f_entity_load _probe 'missing' >/dev/null 2>&1
  assertNotEquals 'missing cache must fail' '0' "$?"
}

test_entity_load_sources_data_asc_cache() {
  f_entity_load _probe 'alpha' || fail 'load failed'
  assertEquals 'alpha' "$_PROBE_ID"
  assertEquals 'debian' "$_PROBE_OS"
}

test_entity_cache_purge_removes_type_dir_files() {
  mkdir -p data/asc/cache/entities/_probe
  echo 'export _PROBE_ID=x' > data/asc/cache/entities/_probe/z.sh
  f_entity_cache_purge _probe || fail 'purge failed'
  assertFalse 'cache file still there' "[ -f data/asc/cache/entities/_probe/z.sh ]"
}

test_entity_cache_purge_empty_type_fails() {
  f_entity_cache_purge >/dev/null 2>&1
  assertNotEquals 'must fail without type' '0' "$?"
}

test_entity_types_discover_includes_host() {
  entity_types_arr=()
  f_entity_types_discover || fail 'discover types failed'
  . data/asc/cache/entities/types.sh
  local found=1
  local t
  for t in "${entity_types_arr[@]}"; do
    case "$t" in host) found=0 ;; esac
  done
  assertEquals 'type host (host.entity.yml) not discovered' '0' "$found"
}

test_entity_types_discover_does_not_index_able_files() {
  f_entity_types_discover || fail 'discover types failed'
  assertFalse 'must not cache sidecar.able as a type file' \
    "grep -q 'sidecar.able' data/asc/cache/entities/types.sh 2>/dev/null"
}

test_entity_type_includes_able_host_sidecar() {
  f_entity_type_includes_able host 'sidecar.able' \
    || fail 'host.entity.yml includes sidecar.able'
  if f_entity_type_includes_able file 'sidecar.able'; then
    fail 'empty file.entity.yml must not include sidecar.able'
  fi
}

test_entity_instances_discover_finds_host_fixture() {
  entity_types_arr=()
  entity_instance_types_arr=()
  entity_instance_ids_arr=()
  f_entity_types_discover
  f_entity_instances_discover || fail 'discover instances failed'
  local i found=1
  for i in "${!entity_instance_ids_arr[@]}"; do
    if [[ "${entity_instance_types_arr[$i]}" == 'host' \
       && "${entity_instance_ids_arr[$i]}" == 'foobar.home.arpa' ]]; then
      found=0
    fi
  done
  assertEquals 'data/entities/host/foobar.home.arpa.yml not discovered' '0' "$found"
}

test_entity_cache_generate_host_fixture() {
  f_entity_cache_purge host
  f_entity_cache_generate host 'foobar.home.arpa' || fail 'generate failed'
  assertTrue 'cache missing' "[ -f data/asc/cache/entities/host/foobar.home.arpa.sh ]"
  f_entity_load host 'foobar.home.arpa' || fail 'load failed'
  assertEquals 'foobar.home.arpa' "$HOST_ID"
  assertEquals 'foobar.home.arpa' "$HOST_HOSTNAME"
}

test_entity_cache_generate_skips_include_field() {
  f_entity_cache_generate host 'foobar.home.arpa' || fail 'generate failed'
  f_entity_load host 'foobar.home.arpa'
  assertEquals 'include is reserved' '' "${HOST_INCLUDE:-}"
}

test_entity_cache_generate_all_purges_stale_sidecar_cache() {
  mkdir -p data/asc/cache/entities/host
  echo "export HOST_ID='stale'" > data/asc/cache/entities/host/stale.sh
  f_entity_cache_generate_all || fail 'generate_all failed'
  assertFalse 'stale sidecar cache must be purged' \
    "[ -f data/asc/cache/entities/host/stale.sh ]"
  assertTrue 'host fixture cache missing' \
    "[ -f data/asc/cache/entities/host/foobar.home.arpa.sh ]"
}

test_entity_post_init_hook_file_exists() {
  assertTrue 'entity post_init hook missing' \
    "[ -f asc/extensions/entity/instance/post_init.hook.sh ]"
}

test_entity_spec_get_keys_host_includes_id_and_hostname() {
  keys_arr=()
  f_entity_spec_get_keys host || fail 'get_keys failed'
  local k found_id=1 found_hostname=1
  for k in "${keys_arr[@]}"; do
    case "$k" in
      id) found_id=0 ;;
      hostname) found_hostname=0 ;;
    esac
  done
  assertEquals 'id must appear for type host' '0' "$found_id"
  assertEquals 'hostname must appear from host.entity.yml required.field' \
    '0' "$found_hostname"
}

test_entity_spec_get_key_host_hostname() {
  if [[ ! -f data/asc/cache/entities/host/foobar.home.arpa.sh ]]; then
    f_entity_cache_generate host 'foobar.home.arpa' \
      || fail 'generate cache for load'
  fi
  local out=''
  f_entity_spec_get_key host 'foobar.home.arpa' hostname out \
    || fail 'get_key failed'
  assertEquals 'foobar.home.arpa' "$out"
}

test_remote_instance_load_wraps_entity_load() {
  . asc/extensions/remote/remote.inc.sh
  mkdir -p data/asc/cache/entities/remote_instance
  cat > data/asc/cache/entities/remote_instance/wraptest.sh <<'EOF'
export REMOTE_INSTANCE_ID='wraptest'
export REMOTE_INSTANCE_HOST='1.2.3.4'
EOF
  f_remote_instance_load 'wraptest' || fail 'wrapper failed'
  assertEquals 'wraptest' "$REMOTE_INSTANCE_ID"
  assertEquals '1.2.3.4' "$REMOTE_INSTANCE_HOST"
  assertFalse 'must not require legacy path' \
    "[ -f data/asc/remote-instances/wraptest.sh ]"
  rm -f data/asc/cache/entities/remote_instance/wraptest.sh
}

. asc/vendor/shunit2/shunit2
