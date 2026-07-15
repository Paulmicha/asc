#!/usr/bin/env bash

##
# Docker-compose reinit operation.
#
# Only regenerates the docker-compose.yml file(s).
#
# @see asc/extensions/compose/global.vars.sh
# @see u_dc_write_yml() in asc/extensions/compose/compose.inc.sh
#
# @example
#   # To apply changes made to local dev stack :
#   make stack-reinit
#   make restart
#   # Or :
#   asc/extensions/compose/stack/reinit.sh
#   asc/instance/restart.sh
#

. asc/bootstrap.sh

echo "Reinit docker-compose stack ..."

case "$DC_MODE" in 'generate')
  u_dc_write_yml
esac

echo "Reinit docker-compose stack : done."
echo
