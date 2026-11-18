#!/usr/bin/env bash

##
# Command-line entry point for the ASC custom DSL.
#
# @example
#   asc/dsl.sh '[echo(v-PROJECT_DOCROOT)]'
#

. asc/bootstrap.sh

f_asc_dsl "$@"
