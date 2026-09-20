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

. asc/vendor/shunit2/shunit2
