#!/usr/bin/env bash

##
# [abstract] Installs required software on current host.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does.
#
# @example
#   asc/host/provision.sh
#

. asc/bootstrap.sh

hook -s 'host' -a 'provision' -v 'HOST_OS HOST_TYPE PROVISION_USING'
