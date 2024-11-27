#!/usr/bin/env bash

##
# (Re)generate the git-ignored compose files.
#
# @example
#   make compose-write
#   # Or :
#   asc/extensions/docker-compose/compose/write.sh
#

. asc/bootstrap.sh

case "$DC_MODE" in 'generate')
  # @see asc/extensions/docker-compose/docker-compose.inc.sh
  u_dc_write_yml
esac
