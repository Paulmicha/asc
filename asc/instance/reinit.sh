#!/usr/bin/env bash

##
# Reinitializes current project instance without changing existing settings.
#
# Rewrites locally generated ASC files based on the values initially set for the
# following global env. vars :
# - $INSTANCE_TYPE
# - $INSTANCE_DOMAIN
# - $HOST_TYPE
# - $PROVISION_USING
#
# @example
#   make reinit
#   # Or :
#   asc/instance/reinit.sh
#

# The only values we're using when re-initializing are ASC 'core' globals.
if [[ -f scripts/asc/local/global.vars.sh ]]; then
  . scripts/asc/local/global.vars.sh
fi

# Wipe out env vars to avoid pile-ups for 'append' type globals during reinit.
# See https://unix.stackexchange.com/a/49057
env -i \
  # Except individual public key path for ASC remote instances operations.
  # @see scripts/asc/extend/remote/post_init.hook.sh
  ASC_SSH_PUBKEY="$ASC_SSH_PUBKEY" \
  # Also except ASC_DB_ID for the db extension.
  # @see u_db_set() in asc/extensions/db/db.inc.sh
  ASC_DB_ID="$ASC_DB_ID" \
  # Also except common shell env vars some programs use.
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  # Now we're good.
  . asc/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -d "$INSTANCE_DOMAIN" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
