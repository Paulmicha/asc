#!/usr/bin/env bash

##
# ASC test self_test action.
#
# This generic implementation is meant for providing self-checking tests
# concerning current project instance whose services may not necessarily be
# running.
#
# @see hook()
#
# @example
#   asc/test/self_test.sh
#

. asc/bootstrap.sh

hook -s 'test' -a 'self_test' -v 'HOST_TYPE PROVISION_USING'
