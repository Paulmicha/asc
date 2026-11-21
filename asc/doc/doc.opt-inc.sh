#!/usr/bin/env bash

##
# Doc shell opt-in utilities.
#
# Convention : functions names are all prefixed by "f".
# Except doc(), by design.
#

##
# ASC doc action : document something.
#
# Mutable scoped env vars :
#
# @var ARGS : String : all arguments passed (as string).
#   Defaults to "$@".
#
# @var EXT : String : file extension.
#   Defaults to 'txt'.
#
# @var VARIANTS : String : space-separated hooks variants' variable names.
#   Defaults to 'STACK_VERSION EXT HOST_TYPE'.
#
# The 'doc' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:instance p:pre a:doc v:STACK_VERSION EXT HOST_TYPE
# $ make hook-debug s:instance a:doc v:STACK_VERSION EXT HOST_TYPE
# $ make hook-debug s:instance p:post a:doc v:STACK_VERSION EXT HOST_TYPE
#
# @example
#   make doc "Hello world"
#   # Or :
#   asc/instance/doc.sh "Hello world"
#
doc() {
  export ARGS="$@"

  export EXT="${EXT:-txt}"
  export VARIANTS="${VARIANTS:-STACK_VERSION EXT HOST_TYPE}"

  hook -s 'instance' -p 'pre' -a 'doc' -v "$VARIANTS"
  hook -s 'instance' -a 'doc' -v "$VARIANTS"
  hook -s 'instance' -p 'post' -a 'doc' -v "$VARIANTS"
}
