#!/usr/bin/env bash

##
# Gets local instance database ID(s).
#
# Prints all databse ID(s) declared in this project instance.
#
# @example
#   make db-get-ids
#   # Or :
#   asc/extensions/db/db/get_ids.sh
#

. asc/bootstrap.sh
u_db_get_credentials $@

echo "ASC_DB_IDS = '$ASC_DB_IDS'"
