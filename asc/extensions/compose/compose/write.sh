#!/usr/bin/env bash

##
# (Re)generate the git-ignored compose files.
#
# @example
#   make compose-write
#   # Or :
#   asc/extensions/compose/compose/write.sh
#

. asc/bootstrap.sh

case "$DC_MODE" in 'generate')
  # @see asc/extensions/compose/compose.inc.sh
  u_dc_write_yml
esac
