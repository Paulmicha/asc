#!/usr/bin/env bash

##
# Command-line entry point for the ASC custom DSL.
#
# @example
#   asc/dsl.sh 'slug(foobar)'
#   asc/dsl.sh 'slug(p1)' -- 'Foo Bar'
#   asc/dsl.sh path/to/prog.dsl.txt
#   ASC_DS_EXPR='slug(foobar)' make ds
#   ASC_DS_EXPR='path/to/prog.dsl.txt' make ds
#

. asc/bootstrap.sh

f_asc_dsl "$@"
