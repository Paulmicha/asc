#!/usr/bin/env bash

##
# [abstract] ASC host registry_set action.
#
# Allows extensions to implement storing values by key "scoped" to the entire
# local host.
#
# @see hook()
#
# @example
#   asc/host/registry_set.sh my_key 'my value'
#

. asc/bootstrap.sh

# It's easier to set variables in current scope than sending and parsing args to
# any potentially matching lookup paths' sourced files.
# @see hook()
P_REG_KEY="$1"
P_REG_VAL=$2

hook -s 'host' -a 'registry_set' -v 'HOST_TYPE'
