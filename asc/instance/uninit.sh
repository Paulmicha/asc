#!/usr/bin/env bash

##
# Deletes any traces of previous init in current project instance.
#
# TODO introduce hook for letting extensions clean up their own generated files.
#
# @example
#   make uninit
#   # Or :
#   asc/instance/uninit.sh
#

asc_instance_uninit_purge_list=".env
scripts/asc/local/global.vars.sh
scripts/asc/local/default.mk
docker-compose.yml
docker-compose.override.yml"

for f in $asc_instance_uninit_purge_list; do
  if [[ -f "$f" ]]; then
    rm "$f"
    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to delete file '$f'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    else
      echo "Successfully removed file '$f'."
    fi
  fi
done

# Update 2024-06 cache results.
. asc/cache/clear.sh
