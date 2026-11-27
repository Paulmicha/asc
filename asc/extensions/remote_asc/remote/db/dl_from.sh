#!/usr/bin/env bash

##
# Just fetches DB dump from given remote (without restoring it locally).
#
# Optionally creates a new dump before fetching it, or uses most recent
# remote instance DB dump (default). Does not restore the dump locally.
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
#   make remote-db-dl-from my_remote_id
#   make remote-db-dl-from my_remote_id new
#   make remote-db-dl-from my_remote_id path/to/remote/dump/file.sql.tgz
#   # Or :
#   asc/extensions/remote_asc/remote/db/dl_from.sh fixture '' separate
#   asc/extensions/remote_asc/remote/db/dl_from.sh my_remote_id
#   asc/extensions/remote_asc/remote/db/dl_from.sh my_remote_id new
#   asc/extensions/remote_asc/remote/db/dl_from.sh my_remote_id path/to/remote/dump/file.sql.tgz
#

. asc/bootstrap.sh
. asc/extensions/remote_asc/remote/db/db.opt-inc.sh
f_remote_download_db_from "$@"
