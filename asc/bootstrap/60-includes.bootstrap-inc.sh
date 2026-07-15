#!/usr/bin/env bash

##
# Bootstrap phase: source ASC_INC (eager *.inc.sh includes, override-aware).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Load additional includes (including extensions').
if [[ -n "$ASC_INC" ]]; then
  for file in $ASC_INC; do
    # Any additional include may be overridden.
    u_autoload_override "$file" 'continue'
    if [[ -n "$inc_override_evaled_code" ]]; then
      eval "$inc_override_evaled_code"
    fi
    if [[ -f "$file" ]]; then
      . "$file"
    fi
  done
fi
