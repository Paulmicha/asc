#!/usr/bin/env bash

##
# [abstract] Setup a new database (create + import initial dump).
#
# "Abstract" means that this extension doesn't provide any actual implementation
# for this functionality. It is necessary to use an extension that does. E.g. :
#
# @see asc/extensions/mysql
# @see asc/extensions/pgsql
#
# @param 1 [optional] String : the database ID ($DB_ID), see u_db_set().
#   Defaults to 'default'.
# @param 2 [optional] String : force reload flag (bypasses optimization) if the
#   DB credentials vars are already exported in current shell scope.
#   TODO deprecate this argument and export a specific variable instead.
#
# @example
#   make db-setup
#   make db-setup 'custom_db_id'
#   # Or :
#   asc/extensions/db/db/setup.sh
#   asc/extensions/db/db/setup.sh 'custom_db_id'
#

. asc/bootstrap.sh

# @see asc/extensions/db/db.inc.sh
u_db_setup $@
