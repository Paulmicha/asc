#!/usr/bin/env bash

##
# Sends local instance DB dump to given remote.
#
# Optionally creates a new dump before sending it over, or uses most recent
# local instance DB dump (default). Always wipes out and restores the dump on
# remote DB.
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
#   make remote-db-sync-to dev
#   make remote-db-sync-to dev new
#   make remote-db-sync-to dev path/to/local/dump/file.sql.tgz
#   # Or :
#   asc/extensions/remote_asc/remote/db/sync_to.sh fixture '' separate
#   asc/extensions/remote_asc/remote/db/sync_to.sh dev
#   asc/extensions/remote_asc/remote/db/sync_to.sh dev new
#   asc/extensions/remote_asc/remote/db/sync_to.sh dev path/to/local/dump/file.sql.tgz
#

. asc/bootstrap.sh
. asc/extensions/remote_asc/remote/db/db.opt-inc.sh
f_remote_sync_db_to "$@"
