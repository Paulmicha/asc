#!/usr/bin/env bash

##
# In order to convert "real" local DB dumps path to container bind mount volumes
# paths, we need the "in container" base path.
#
# @example
#   @see asc/extensions/drush/db/exec.drush.docker-compose.hook.sh
#

global ASC_DB_DUMPS_BASE_PATH_C "[default]=$APP_DOCROOT_C/data/db-dumps [help]='Same as ASC_DB_DUMPS_BASE_PATH but within containers.'"
