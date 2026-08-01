#!/usr/bin/env bash

##
# Deletes any traces of previous init in current project instance.
#
# The following hook is provided for letting extensions clean up their own
# generated files and/or alter the purge_list_arr :
#
# $ make hook-debug s:instance a:uninit v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
# These implementations may optionally alter entries to the following var in
# calling scope :
#
# @var purge_list_arr
#
# @example
#   make uninit
#   # Or :
#   asc/instance/uninit.sh
#

. asc/bootstrap.sh

purge_list_arr=()

# Manual cleanup of ASC global env vars.
purge_list_arr+=('.env')
purge_list_arr+=('data/asc/global.vars.sh')

# ASC make shortcuts too.
purge_list_arr+=('data/asc/generated.mk')

# Let extensions clean up their own generated files and/or alter the purge_list_arr.
hook -s 'instance' -a 'uninit' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'

# Process the purge_list_arr.
for entry in "${purge_list_arr[@]}"; do
  if [[ -z "$entry" ]]; then
    continue
  fi

  if [[ -d "$entry" ]]; then
    echo
    echo "Notice : entire folders are not purged in 'uninit' (only files_arr)."
    echo "  -> skipped dir : $entry"
    echo

    continue
  fi

  if [[ -f "$entry" ]]; then
    rm "$entry"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: unable to delete file '$entry'." >&2
      echo "-> Aborting (1)." >&2
      echo >&2
      exit 1
    else
      echo "Successfully removed file '$entry'."
    fi
  fi
done

# Clear all ASC cache entries.
. asc/asc/cache_clear.sh
