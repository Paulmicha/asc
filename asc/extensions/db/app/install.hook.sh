#!/usr/bin/env bash

##
# Implements hook -s 'app' -a 'install' -v 'PROVISION_USING INSTANCE_TYPE'
#
# Setup new databases (create if it doesn't exist) + import initial dump.
#
# @see asc/app/install.sh
# @see asc/instance/setup.sh
#
# This file is dynamically included when the "hook" is triggered.
#
# Debug lookup paths (make sure this file gets picked up) :
# $ make hook-debug s:app a:install v:PROVISION_USING INSTANCE_TYPE
#
# @example
#   make app-install
#   # Or :
#   asc/app/install.sh
#

case "$ASC_DB_INITIAL_IMPORT" in true)
  db_ids=()
  u_db_get_ids

  for db_id in "${db_ids[@]}"; do
    u_db_setup "$db_id"
  done
esac
