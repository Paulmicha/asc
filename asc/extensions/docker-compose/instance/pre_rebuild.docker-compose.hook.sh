#!/usr/bin/env bash

##
# Implements hook -s 'instance' -p 'pre' -a 'rebuild' -v 'PROVISION_USING HOST_TYPE INSTANCE_TYPE'
#
# Rewrites locally generated ASC files - among which docker-compose.yml and
# docker-compose.override.yml based on the values previously set for the
# following global env. vars :
# - $INSTANCE_TYPE
# - $INSTANCE_DOMAIN
# - $HOST_TYPE
# - $PROVISION_USING
#
# @see asc/instance/reinit.sh
# @see asc/instance/rebuild.sh
#

env -i \
  ASC_SSH_PUBKEY="$ASC_SSH_PUBKEY" \
  ASC_DB_ID="$ASC_DB_ID" \
  HOME="$HOME" LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" PATH="$PATH" USER="$USER" \
  asc/instance/reinit.sh
