#!/usr/bin/env bash

##
# Gets local instance DB dump filepaths.
#
# Optionally creates a new routine dump first.
#
# @param 1 [optional] String : pass 'new' to create new dump instead of
#   returning most recent among existing local DB dump files.
#   Pass 'initial' to get a dump file whose name matches 'initial.*'.
#
# @example
#   make db-get-dump
#   make db-get-dump new
#   make db-get-dump initial
#   # Or :
#   asc/extensions/db/db/get_dump.sh
#   asc/extensions/db/db/get_dump.sh new
#   asc/extensions/db/db/get_dump.sh initial
#

. asc/bootstrap.sh
u_db_get_dump $@
