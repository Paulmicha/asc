#!/usr/bin/env bash

##
# Clears the local ASC cache.
#
# @see asc/bootstrap.sh
# @see asc/utilities/asc.sh
# @see asc/utilities/hook.sh
#
# @example
#   make asc-cache-clear
#   # Or :
#   asc/instance/asc_cache_clear.sh
#

if [[ -d scripts/asc/local/cache ]]; then
  rm -rf scripts/asc/local/cache
  echo "Cleared local scripts/asc/local/cache dir."
fi
