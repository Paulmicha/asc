#!/usr/bin/env bash

##
# Docker-compose single service "rebuild" operation.
#
# @example
#   make service-rebuild 'arangodb'
#   # Or :
#   asc/extensions/compose/service/rebuild.sh 'arangodb'
#

asc/extensions/compose/service/rm.sh "$1" \
  && asc/extensions/compose/service/build.sh "$1" \
  && asc/instance/start.sh
  # && asc/extensions/compose/service/create.sh "$1" \
  # && asc/extensions/compose/service/start.sh "$1"
