#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'rebuild' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrites locally generated ASC files - e.g. compose.yml, settings
# files, etc. based on the values previously set for the following global global
# env. vars :
# - $ASC_APPS
# - $ASC_DB_ID
# - $INSTANCE_TYPE
# - $HOST_TYPE
# - $PROVISION_USING
#
# TODO check if we can safely remove these hardcoded globals' values to persist.
# In principle yes, as it gets re-initialized using the env.yml files.
# @see u_instance_init() in asc/instance/instance.inc.sh
#
# @see asc/instance/reinit.sh
# @see asc/instance/rebuild.sh
#

env -i \
  ASC_SSH_PUBKEY="$ASC_SSH_PUBKEY" \
  ASC_APPS="$ASC_APPS" \
  ASC_DB_ID="$ASC_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  asc/instance/reinit.sh
