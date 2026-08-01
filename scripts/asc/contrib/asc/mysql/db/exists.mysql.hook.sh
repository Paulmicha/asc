#!/usr/bin/env bash

##
# Implements hook_ms -s 'db' -a 'exists' -v 'DB_DRIVER HOST_TYPE INSTANCE_TYPE'.
#
# @requires the following var in calling scope :
# @var db_exists
#
# @see f_db_exists() in asc/extensions/db/db.inc.sh
#
# @example
#   if f_db_exists 'my_db_name'; then
#     echo "Ok, 'my_db_name' exists."
#   else
#     echo "Error : 'my_db_name' does not exist (or I do not have permission to access it)."
#   fi
#

# Debug.
# echo "MySQL DB Driver : Test if database '${a_db_name}' exists (user=$DB_USER, password="$DB_PASS", host="$DB_HOST", port="$DB_PORT")..."

# See https://stackoverflow.com/a/59708674
if mysql --user="$DB_USER" --password="$DB_PASS" --host="$DB_HOST" \
  --port="$DB_PORT" -e "use $a_db_name"
then
  db_exists='true'
else
  db_exists='false'
fi
