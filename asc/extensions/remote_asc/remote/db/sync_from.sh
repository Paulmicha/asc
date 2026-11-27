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
# @param 3 [optional] String : database ID. Defaults to 'default'.
# @param 4 [optional] String : force reload flag for database credentials.
#
# Make cannot preserve an empty second argument. Use the direct action when
# specifying a DB ID with the default dump selection.
#
# @example
#   make remote-db-sync-from prod
#   make remote-db-sync-from prod new
#   make remote-db-sync-from prod path/to/remote/dump/file.sql.tgz
#   # Or :
#   asc/extensions/remote_asc/remote/db/sync_from.sh fixture '' separate
#   asc/extensions/remote_asc/remote/db/sync_from.sh prod
#   asc/extensions/remote_asc/remote/db/sync_from.sh prod new
#   asc/extensions/remote_asc/remote/db/sync_from.sh prod path/to/remote/dump/file.sql.tgz
#

. asc/bootstrap.sh
. asc/extensions/remote_asc/remote/db/db.opt-inc.sh
f_remote_sync_db_from "$@"
