#!/usr/bin/env bash

##
# Implements hook -s 'asc' -a 'alias' -v 'STACK_VERSION PROVISION_USING'.
#
# Declares default bash aliases for current project instance.
#
# This file is dynamically included when the "hook" is triggered.
# @see asc/bootstrap.sh
#
# Uses the docker exec interactive flag from 'compose' extension.
# @see asc/extensions/compose/asc/pre_bootstrap.compose.hook.sh
#

php_sname="${PHP_SNAME:=php}"

alias php="docker compose exec $DC_TTY $php_sname php"
