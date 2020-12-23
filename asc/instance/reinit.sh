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
if [[ -f '.env' ]]; then
  # Can't have read-only variables here, so we need to extract just the
  # variables we need.
  # TODO support all globals for reinits ? For ex. as in :
  # @see u_traefik_generate_acme_conf() in asc/extensions/remote_traefik/remote_traefik.inc.sh
  # -> here, we could just pass a custom option that would instruct the
  # u_instance_init() function to dynamically get all existing values ?
  while IFS= read -r line _; do
    case "$line" in
      'INSTANCE_TYPE='*)
        eval "$line"
        ;;
      'INSTANCE_DOMAIN='*)
        eval "$line"
        ;;
      'DC_NS='*)
        eval "$line"
        ;;
      'HOST_TYPE='*)
        eval "$line"
        ;;
      'PROVISION_USING='*)
        eval "$line"
        ;;
    esac
  done < '.env'
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
    -c "$DC_NS" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
