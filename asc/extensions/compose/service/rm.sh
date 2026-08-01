#!/usr/bin/env bash

##
# Docker-compose single service "rm" operation.
#
# @example
#   make service-rm 'arangodb'
#   # Or :
#   asc/extensions/compose/service/rm.sh 'arangodb'
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

echo "Removing the '$a_service' service ..."

docker compose rm -fsv "$a_service"

echo "Removing the '$a_service' service : done."
echo
