#!/usr/bin/env bash

##
# TODO [wip] entry point stub for inline DSL interpreter.
#
# TODO Duplicates the following entry point -> only keep 1 :
# @see asc/instance/replay.sh
#
# TODO but keep the possibility of filepath arg support,
# and/or hook_ms() that could match implementations like 'path/to/foobar.dsl.txt'
#
# @example
#   make ds '[echo(v-baz)]---v-output_file_path'
#
#   # Or :
#   asc/instance/ds.sh '[echo(v-baz)]---v-output_file_path'
#
#   # Or even (after opt-in shell alias wiring) :
#   # @see asc/host/shell/write_hooks.sh
#   ds '[echo(v-baz)]---v-output_file_path'
#

. asc/bootstrap.sh

# TODO
