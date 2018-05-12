#!/usr/bin/env bash

##
# [abstract] ASC host provision action.
#
# This generic implementation provides entry points for installing some software
# on current host. It supports variants by :
# - HOST_OS
# - HOST_TYPE
# - PROVISION_USING
#
# @see hook()
#
# @example
#   asc/host/provision.sh
#

. asc/bootstrap.sh

hook -s 'host' -a 'provision' -v 'HOST_OS HOST_TYPE PROVISION_USING'
