#!/usr/bin/env bash

##
# Switches current project stack version.
#
# @see asc/instance/reinit.sh
# @see asc/instance/switch_type.sh
#
# @param 1 String : the new stack version.
#
# @example
#   make switch-stack-version 'project-2025'
#   make rebuild
#   # Or :
#   asc/instance/switch_stack_version.sh 'project-2025'
#   asc/instance/rebuild.sh
#

# Force the new instance type value alone.
STACK_VERSION="$1"

# Update 2024-06 cache results.
. asc/instance/asc_cache_clear.sh

# Can't have read-only variables here, so we need to extract just the
# variables we need.
# TODO support all globals for reinits ? For ex. as in :
# @see u_traefik_generate_acme_conf() in asc/extensions/remote_traefik/remote_traefik.inc.sh
# -> here, we could just pass a custom option that would instruct the
# u_instance_init() function to dynamically get all existing values ?
if [[ -f '.env' ]]; then
  while IFS= read -r line _; do
    case "$line" in
      'ASC_APPS='*)
        eval "$line"
        ;;
      'INSTANCE_TYPE='*)
        eval "$line"
        ;;
      'HOST_TYPE='*)
        eval "$line"
        ;;
      'PROVISION_USING='*)
        eval "$line"
        ;;
      'ASC_SSH_PUBKEY='*)
        eval "$line"
        ;;
    esac

    if [[ -n "$ASC_APPS" ]]; then
      for app in $ASC_APPS; do
        case "$line" in "${app}_DOMAIN="*|"${app}_GIT_ORIGIN="*|"${app}_SERVER_DOCROOT="*)
          eval "$line"
        esac
      done
    fi
  done < '.env'
fi

# Wipe out env vars to avoid pile-ups for 'append' type globals during reinit.
# See https://unix.stackexchange.com/a/49057
# Except individual public key path for ASC remote instances operations.
# @see scripts/asc/extend/remote/post_init.hook.sh
# Also except ASC_DB_ID for the db extension.
# @see u_db_set() in asc/extensions/db/db.inc.sh
# Also except common shell env vars some programs use.
env -i \
  ASC_SSH_PUBKEY="$ASC_SSH_PUBKEY" \
  ASC_DB_ID="$ASC_DB_ID" \
  ASC_APPS="$ASC_APPS" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  asc/instance/init.sh \
    -t "$INSTANCE_TYPE" \
    -s "$STACK_VERSION" \
    -h "$HOST_TYPE" \
    -p "$PROVISION_USING" \
    -y
