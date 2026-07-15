#!/usr/bin/env bash

##
# Implements hook -s 'app instance' -a 'ensure_dirs_exist'
#
# @see u_instance_init()
#

if [ -n "$ASC_DB_DUMPS_DIR" ] && [ ! -d "$ASC_DB_DUMPS_DIR" ]; then
  echo "Creating missing dir '$ASC_DB_DUMPS_DIR'."
  mkdir -p "$ASC_DB_DUMPS_DIR"
fi
