#!/usr/bin/env bash

##
# Checks remote definitions in an isolated working directory.
#

. asc/bootstrap.sh
. asc/extensions/remote/remote.inc.sh

test_remote_purge_preserves_unrelated_files() {
  local fixture
  fixture="$(mktemp -d)"
  (
    cd "$fixture" || exit 1
    mkdir -p data/instance/remote
    printf 'maintained\n' > data/instance/remote/README.md
    printf '# ASC generated remote instance\n' > data/instance/remote/old.sh
    f_remote_purge_instances
    [[ -f data/instance/remote/README.md && ! -f data/instance/remote/old.sh ]]
  )
  local result=$?
  rm -rf "$fixture"
  assertEquals 'purge removes generated files and preserves maintained files' 0 "$result"
}

test_remote_refresh_rejects_collision_and_replaces_loaded_values() {
  local fixture
  fixture="$(mktemp -d)"
  (
    cd "$fixture" || exit 1
    mkdir -p data/instance/remote
    cat > remotes.yml <<'YAML'
includes:
  common:
    domain: common.example.invalid
alpha:
  includes: common
  host: alpha.example.invalid
  docroot: /srv/alpha
beta:
  includes: common
  host: beta.example.invalid
  domain: beta.example.invalid
parsed:
  host: parsed.example.invalid
YAML
    hook_ms() { most_specific_match=remotes.yml; }
    hook() { :; }
    f_remote_instances_setup || exit 1
    if ( parse_yaml() { return 7; }; f_remote_instances_setup ); then exit 18; fi
    [[ -f data/instance/remote/alpha.sh && -f data/instance/remote_refresh_failed ]] || exit 19
    f_remote_instances_setup || exit 20
    f_remote_instance_load alpha || exit 2
    [[ "$REMOTE_INSTANCE_DOCROOT" == /srv/alpha ]] || exit 3
    [[ "$REMOTE_INSTANCE_DOMAIN" == common.example.invalid ]] || exit 21
    f_remote_instance_load beta || exit 4
    [[ -z "${REMOTE_INSTANCE_DOCROOT-}" ]] || exit 5
    [[ "$REMOTE_INSTANCE_DOMAIN" == beta.example.invalid && "$REMOTE_INSTANCE_SSH_CONNECT_CMD" == 'ssh -T -A beta.example.invalid' ]] || exit 22
    bash -n data/instance/remote/alpha.sh data/instance/remote/beta.sh data/instance/remote/parsed.sh || exit 23
    local instance_ids_arr=()
    f_remote_get_instances || exit 10
    [[ " ${instance_ids_arr[*]} " == *' alpha '* && " ${instance_ids_arr[*]} " == *' beta '* && " ${instance_ids_arr[*]} " == *' parsed '* ]] || exit 11
    printf 'maintained\n' > data/instance/remote/unowned.sh
    if f_remote_instance_load unowned; then exit 12; fi
    f_remote_instance_load alpha || exit 13
    if f_remote_exec_wrapper missing true; then exit 14; fi
    f_remote_instance_load alpha || exit 15
    if f_remote_definition_get_key missing host result; then exit 16; fi
    printf 'maintained\n' > data/instance/remote/collision.sh
    cat >> remotes.yml <<'YAML'
collision:
  host: collision.example.invalid
YAML
    if f_remote_instances_setup; then exit 6; fi
    [[ "$(cat data/instance/remote/collision.sh)" == maintained ]] || exit 7
    instance_ids_arr=()
    if f_remote_get_instances; then exit 17; fi
    if f_remote_instance_load collision; then exit 8; fi
    if f_remote_definition_get_key missing host result; then exit 9; fi
  )
  local result=$?
  rm -rf "$fixture"
  assertEquals 'refresh preserves collisions and loads replace values' 0 "$result"
}

##
# Refresh re-evaluates YAML variants even when the hook lookup was cached.
#
test_remote_refresh_discovers_fallback_after_variant_removed() {
  local fixture
  fixture="$(mktemp -d)"
  (
    cd "$fixture" || exit 1
    [[ -n "$HOST_TYPE" ]] || exit 9
    printf 'alpha:\n  host: fallback.example.invalid\n' > remote_instances.yml
    printf 'alpha:\n  host: variant.example.invalid\n' > "remote_instances.$HOST_TYPE.yml"
    f_remote_instances_setup || exit 2
    f_remote_instance_load alpha || exit 3
    [[ "$REMOTE_INSTANCE_HOST" == variant.example.invalid ]] || exit 4
    rm "remote_instances.$HOST_TYPE.yml" || exit 5
    f_remote_instances_setup || exit 6
    f_remote_instance_load alpha || exit 7
    [[ "$REMOTE_INSTANCE_HOST" == fallback.example.invalid ]] || exit 8
  )
  local result=$?
  rm -rf "$fixture"
  assertEquals 'refresh uses current YAML fallback' 0 "$result"
}

. asc/vendor/shunit2/shunit2
