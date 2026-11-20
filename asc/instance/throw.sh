#!/usr/bin/env bash

##
# ASC "exceptions" handling. Exits immediately.
#
# Mutable scoped env vars :
#
# @var LV : String : log level.
#   Defaults to 'error'.
#
# @var CODE : Integer : exit code.
#   Defaults to 1.
#
# @var HANDLER : String : arbitrary hook variant variable to differenciate how
#   to record (or not) the "exception".
#   Defaults to 'echo'.
#
# @var VARIANTS : String : space-separated hooks variants' variable names.
#   Defaults to 'LV HANDLER HOST_TYPE'.
#
# @var ARGS : String : all arguments passed (as string).
#   Defaults to "$@".
#
# The 'throw' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:instance p:pre a:throw v:LV HANDLER HOST_TYPE
# $ make hook-debug s:instance a:throw v:LV HANDLER HOST_TYPE
# $ make hook-debug s:instance p:post a:throw v:LV HANDLER HOST_TYPE
#
# @example
#   make throw "Hello world"
#   # Or :
#   asc/instance/throw.sh "Hello world"
#

. asc/bootstrap.sh

# @see asc/core/utils/shell.manual-inc.sh
throw "$@"
