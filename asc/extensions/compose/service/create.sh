#!/usr/bin/env bash

##
# Docker-compose single service "create" operation.
#
# TODO deprecated
#
# @example
#   make service-create 'arangodb'
#   # Or :
#   asc/extensions/compose/service/create.sh 'arangodb'
#

. asc/bootstrap.sh

a_service="$1"

if [[ -z "$a_service" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: service name is required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

echo "Creating the '$a_service' service container ..."

docker compose create "$a_service"

echo "Creating the '$a_service' service container : done."
echo
