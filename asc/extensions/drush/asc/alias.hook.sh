#!/usr/bin/env bash

##
# Implements hook -s 'asc' -a 'alias' -v 'STACK_VERSION PROVISION_USING'.
#
# Declares default bash aliases for current project instance using drush, but
# *not* using docker-compose. In that case, the other implementation will be
# loaded instead :
#
# @see asc/extensions/drush/asc/alias.compose.hook.sh
#
# This file is dynamically included when the "hook" is triggered.
# @see asc/bootstrap.sh
#
# Uses the docker exec interactive flag from 'compose' extension.
# @see asc/extensions/compose/asc/pre_bootstrap.compose.hook.sh
#
# This hook will be called once during bootstrap, then once more during "db set"
# where a local variable may be used to overwrite those aliases in order to
# target the correct service.
#
# @see asc/extensions/drush/asc/global.compose.vars.sh
# @see u_db_set() in asc/extensions/db/db.inc.sh
#

if [[ -d "$SERVER_DOCROOT" ]]; then
  alias drush="drush --root='$SERVER_DOCROOT'"

  # Debug.
  # echo "$BASH_SOURCE line $LINENO"
  # echo "  aliases set or updated :"
  # echo "    drush --root='$SERVER_DOCROOT'"
  # echo
fi
