#!/usr/bin/env bash

##
# Gets local instance database ID(s).
#
# Prints all databse ID(s) declared in this project instance.
#
# @example
#   make db-list-ids
#   # Or :
#   asc/extensions/db/db/list_ids.sh
#

. asc/bootstrap.sh

db_ids_arr=()
f_db_get_ids

echo "Here are all the database IDs defined in this project instance :"

for db_id in "${db_ids_arr[@]}"; do
  echo " - $db_id"
done
