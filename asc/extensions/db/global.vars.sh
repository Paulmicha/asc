#!/usr/bin/env bash

##
# Global (env) vars for the 'db' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# TODO document defaulting to ASC_APPS.
global ASC_DB_IDS "[default]='$ASC_APPS' [help]='Allows project instances to use several databases. By default, a single database ID is used : ’default’. These are used to differenciate DB settings and credentials and for automatic routine backup dump file paths - see u_db_routine_backup(). For declaring more database(s), use only space-separated strings, ex: ’default mig_buffer’.'"

global ASC_DB_DUMPS_DIR "[default]=data/db-dumps [help]='Project-relative path (from PROJECT_DOCROOT) for DB dump files from the local instance; may also hold dumps from remote instances (sync operations, see remote extension). Recommended layout by instance and database ID, e.g. data/db-dumps/local/default (automatic routine backups — see u_db_routine_backup()). Bind-mounted in compose as ./$ASC_DB_DUMPS_DIR.'"

global ASC_DB_INITIAL_IMPORT "[default]=true [help]='Set to true to import the first dump file whose name matches « initial.* » found in ASC_DB_DUMPS_DIR (i.e. $ASC_DB_DUMPS_DIR) during app install / instance setup. See asc/app/install.sh and asc/instance/setup.sh'"

global ASC_DB_MODE "[default]=auto [help]='Specifies if ASC should handle DB credentials, and how. Possible values are none = credentials are already available i.e. as local env vars or provided via hook env preset, or auto = local instance DB credentials are automatically generated (using random password).'"

global ASC_DB_DUMPS_LOCAL_PATTERN "[default]='{{ %Y-%m-%d.%H-%M-%S }}_local-{{ DB_ID }}.{{ USER }}.{{ DUMP_FILE_EXTENSION }}' [help]='Default pattern for DB dumps file names created locally. All DB_* vars are available as tokens, and any global + DUMP_FILE_EXTENSION; in fact pretty much anything goes - if no variable matching the token name is set in calling scope, it will eval its contents.'"
