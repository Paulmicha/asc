#!/usr/bin/env bash

##
# Harmless probe for DSL interpreter tests.
#
# Records argv (NUL-separated) and/or touches a marker path, then exits with a
# configurable status. Used by asc/test/core/dsl.test.sh.
#
# Environment :
#   ASC_DSL_PROBE_ARGV    : file path that receives NUL-separated argv bytes
#   ASC_DSL_PROBE_MARKER  : file path created/truncated when this script runs
#   ASC_DSL_PROBE_STATUS  : exit status (default 0)
#
# @example
#   ASC_DSL_PROBE_ARGV=/tmp/argv ASC_DSL_PROBE_MARKER=/tmp/m \
#     ASC_DSL_PROBE_STATUS=3 asc/test/dsl_probe.sh one 'two three'
#

if [[ -n "${ASC_DSL_PROBE_MARKER:-}" ]]; then
  # Append a line so repeated runs remain detectable.
  printf '%s\n' "ran" >> "$ASC_DSL_PROBE_MARKER"
fi

if [[ -n "${ASC_DSL_PROBE_ARGV:-}" ]]; then
  : > "$ASC_DSL_PROBE_ARGV"

  if [[ $# -gt 0 ]]; then
    printf '%s\0' "$@" >> "$ASC_DSL_PROBE_ARGV"
  fi
fi

exit "${ASC_DSL_PROBE_STATUS:-0}"
