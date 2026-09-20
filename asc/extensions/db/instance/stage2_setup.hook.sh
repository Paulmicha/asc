#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'stage2' -a 'setup' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Makes sure all DBs exist.
#
# @see asc/instance/setup.sh
# @see asc/extensions/db/db/db.opt-inc.sh
#

if ! type f_db_setup &>/dev/null; then
  # shellcheck disable=SC1091
  . asc/extensions/db/db/db.opt-inc.sh
fi

db_ids_arr=()
f_db_get_ids

for db_id in "${db_ids_arr[@]}"; do
  if ! f_db_is_flagged "$db_id"; then
    echo
    echo "[stage2-setup] setting up $db_id DB ..."

    f_db_setup "$db_id"

    echo "[stage2-setup] setting up $db_id DB : done."
  fi
done
