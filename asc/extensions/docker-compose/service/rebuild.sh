#!/usr/bin/env bash

##
# Docker-compose single service "rebuild" operation.
#
# @example
#   make service-rebuild 'arangodb'
#   # Or :
#   asc/extensions/docker-compose/service/rebuild.sh 'arangodb'
#

asc/extensions/docker-compose/service/rm.sh "$1" \
  && asc/extensions/docker-compose/service/build.sh "$1" \
  && asc/instance/start.sh
  # && asc/extensions/docker-compose/service/create.sh "$1" \
  # && asc/extensions/docker-compose/service/start.sh "$1"
