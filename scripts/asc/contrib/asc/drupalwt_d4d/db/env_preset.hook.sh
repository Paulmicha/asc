#!/usr/bin/env bash

##
# Implements hook -s 'db' -a 'env_preset' -v 'INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID'.
#
# make hook-debug s:db a:env_preset v:INSTANCE_TYPE PROVISION_USING STACK_VERSION DB_ID
#
# Generic DB credentials for a normal (non-multisite) Drupal setup.
# Applies to DB_ID 'default' and to the first ASC_DB_IDS entry. ASC_DB_IDS
# defaults to ASC_APPS, so that id is the app name rather than 'default'.
#
# A filename variant ".default." would only match when some variant value is
# the string default, which skips app-named database ids.
#
# For multi-site setups :
# @see scripts/asc/contrib/asc/drupalwt/db/env_preset.hook.sh
#

case "$DWT_MULTISITE" in false)
  primary_db_id="${ASC_DB_IDS%% *}"

  case "$DB_ID" in
    default|"$primary_db_id")
      if [[ -n "$DB_ID" ]]; then
        DB_HOST='mariadb'
        DB_NAME='drupal'
        DB_USER='drupal'
        DB_TABLES_SKIP_DATA='cache,cache_*,history,search_*,sessions,watchdog'
      fi
      ;;
  esac
esac
