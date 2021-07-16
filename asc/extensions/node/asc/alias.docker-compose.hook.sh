#!/usr/bin/env bash

##
# Implements hook -s 'asc' -a 'alias' -v 'PROVISION_USING'.
#
# This file is dynamically included when the "hook" is triggered.
# @see asc/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see asc/extensions/docker-compose/asc/pre_bootstrap.docker-compose.hook.sh
#

alias node="docker-compose run $DC_TTY ${NODE_SNAME:=node} node"
alias npm="docker-compose run $DC_TTY ${NODE_SNAME:=node} npm"
alias yarn="docker-compose run $DC_TTY ${NODE_SNAME:=node} yarn"
alias npx="docker-compose run $DC_TTY ${NODE_SNAME:=node} npx"
