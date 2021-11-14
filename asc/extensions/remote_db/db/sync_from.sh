#!/usr/bin/env bash

##
# Fetches DB dump from given remote and restores it locally.
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Always wipes out and restores the dump on
# local DB.
#
# @param 1 String : the remote id.
# @param 2 [optional] String : path to dump file override or 'new' to create one.
#
# @example
#   make db-sync-from prod
#   make db-sync-from prod new
#   make db-sync-from prod path/to/remote/dump/file.sql.tgz
#   # Or :
#   asc/extensions/remote_db/db/sync_from.sh prod
#   asc/extensions/remote_db/db/sync_from.sh prod new
#   asc/extensions/remote_db/db/sync_from.sh prod path/to/remote/dump/file.sql.tgz
#

. asc/bootstrap.sh
u_remote_sync_db_from $@
