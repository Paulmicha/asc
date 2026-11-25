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

. asc/vendor/shunit2/shunit2
