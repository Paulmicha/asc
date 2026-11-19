#!/usr/bin/env bash

##
# Harmless probe for DSL interpreter tests.
#
# Records argv (NUL-separated) and/or appends to a sequencing log / marker,
# then exits with a configurable status. Used by asc/test/core/dsl.test.sh.
#
# Environment :
#   ASC_DSL_PROBE_ARGV         : file path that receives NUL-separated argv bytes
#   ASC_DSL_PROBE_MARKER       : file path; each run appends a "ran" line
#   ASC_DSL_PROBE_LOG          : append-only sequencing log; each run appends
#                                the first argv (call ID), or "ran" if none
#   ASC_DSL_PROBE_STATUS       : exit status (default 0)
#   ASC_DSL_PROBE_STATUS_ARGV  : 1-based argv index used as exit status
#                                (overrides ASC_DSL_PROBE_STATUS when set)
#
# Not a discoverable action (second extension). dsl.test.sh installs a copy under
# a disposable instance path for the suite.
#
# @example
#   ASC_DSL_PROBE_ARGV=/tmp/argv ASC_DSL_PROBE_MARKER=/tmp/m \
#     ASC_DSL_PROBE_STATUS=3 asc/test/core/dsl_probe.fixture.sh one 'two three'
#   ASC_DSL_PROBE_LOG=/tmp/log ASC_DSL_PROBE_STATUS_ARGV=2 \
#     asc/test/core/dsl_probe.fixture.sh call-a 7
#

if [[ -n "${ASC_DSL_PROBE_MARKER:-}" ]]; then
  # Append a line so repeated runs remain detectable.
  printf '%s\n' "ran" >> "$ASC_DSL_PROBE_MARKER"
fi

if [[ -n "${ASC_DSL_PROBE_LOG:-}" ]]; then
  printf '%s\n' "${1:-ran}" >> "$ASC_DSL_PROBE_LOG"
fi

if [[ -n "${ASC_DSL_PROBE_ARGV:-}" ]]; then
  : > "$ASC_DSL_PROBE_ARGV"

  if [[ $# -gt 0 ]]; then
    printf '%s\0' "$@" >> "$ASC_DSL_PROBE_ARGV"
  fi
fi

if [[ -n "${ASC_DSL_PROBE_STATUS_ARGV:-}" ]]; then
  idx="${ASC_DSL_PROBE_STATUS_ARGV}"

  if [[ ! "$idx" =~ ^[1-9][0-9]*$ ]] || [[ "$idx" -gt $# ]]; then
    echo >&2
    echo "Error in dsl_probe: ASC_DSL_PROBE_STATUS_ARGV='$idx' is out of range ($# argv)." >&2
    echo >&2
    exit 1
  fi

  exit "${!idx}"
fi

exit "${ASC_DSL_PROBE_STATUS:-0}"
