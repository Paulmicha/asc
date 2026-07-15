#!/usr/bin/env bash

##
# ASC test : run a single test case from a registered batch.
#
# Invoked by generated make targets (e.g. make test-browser-impersonation).
#
# @param 1 String $p_entry : make entry point name.
# @param 2 [optional] String $p_filter : filter for subdir batches.
#   Defaults to $HOST_TYPE global. Could be a remote ID.
#
# @example
#   asc/test/case.run.sh test-browser-impersonation
#   asc/test/case.run.sh browser-lighthouse-homepage local
#

. asc/bootstrap.sh

p_entry="$1"
p_filter="${2:-$HOST_TYPE}"

if [[ -z "$p_entry" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE - missing test-case p_entry name." >&2
  echo "Usage: asc/test/case.run.sh <entry_point> [filter]" >&2
  echo >&2
  exit 1
fi

u_test_run_case_by_target "$p_entry" "$p_filter"

exit $?
