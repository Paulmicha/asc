#!/usr/bin/env bash

##
# Routine local DB dump (backup).
#
# The dump file path will be determined by the following globals :
#   - ASC_DB_DUMPS_DIR
#   - ASC_DB_DUMPS_LOCAL_PATTERN
#
# @see asc/extensions/db/global.vars.sh
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-routine-backup
#   make db-routine-backup 'custom_db_id'
#   # Or :
#   asc/extensions/db/db/routine_backup.sh
#   asc/extensions/db/db/routine_backup.sh 'custom_db_id'
#
#   # Resulting dump file path example :
#   # data/db-dumps/local/default/2024-08-08.17-25-29_local-default.paul.sql
#

. asc/bootstrap.sh

# @see asc/extensions/db/db.inc.sh
u_db_routine_backup $@
