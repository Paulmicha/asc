#!/usr/bin/env bash

##
# Bootstrap phase: load locally generated global env vars (if present).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
# Opt out with ASC_BS_SKIP_GLOBALS=1.
#
# @see asc/bootstrap.sh
# @see asc/instance/init.sh
#

# If instance init was run at least once, automatically load locally generated
# global env vars.
# This can be opted-out by setting the flag ASC_BS_SKIP_GLOBALS to 1.
# @see asc/instance/init.sh
if [[ $ASC_BS_SKIP_GLOBALS -ne 1 ]]; then
  if [[ -f scripts/asc/local/global.vars.sh ]]; then
    . scripts/asc/local/global.vars.sh
  fi
fi
