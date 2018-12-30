#!/usr/bin/env bash

##
# [abstract] Sets instance-level registry value.
#
# Writes to an abstract instance-level storage by given key.
#
# This script provides an entry point for triggering a specific hook. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this script to have any effect, it is necessary
# to use an extension that does. E.g. :
# @see asc/extensions/file_registry
#
# @example
#   asc/instance/registry_set.sh my_key 'my value'
#

. asc/bootstrap.sh
u_instance_registry_set "$@"
