#!/usr/bin/env bash

##
# Clears ASC cache.
#
# @see asc/bootstrap.sh
# @see asc/utilities/asc.sh
# @see asc/utilities/hook.sh
#
# @example
#   make cache-clear
#   # Or :
#   asc/cache/clear.sh
#

if [[ -d scripts/asc/local/cache ]]; then
  rm -rf scripts/asc/local/cache
fi
