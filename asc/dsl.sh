#!/usr/bin/env bash

##
# Custom DSL interpreter.
#
# TODO [wip]
#
# @example
#   asc/dsl.sh '[echo(v-PROJECT_DOCROOT)]'
#

. asc/bootstrap.sh

f_asc_dsl "$@"
