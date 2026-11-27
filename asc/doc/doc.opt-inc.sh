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
#   Defaults to 'STACK_VERSION PROVISION_USING HOST_TYPE'.
#
# The 'doc' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:doc p:pre a:doc v:STACK_VERSION PROVISION_USING HOST_TYPE
# $ make hook-debug s:doc a:doc v:STACK_VERSION PROVISION_USING HOST_TYPE
# $ make hook-debug s:doc p:post a:doc v:STACK_VERSION PROVISION_USING HOST_TYPE
#
# @example
#   # Defaults to data/doc/txt/2026/11/21-doc.txt
#   make doc "Hello world"
#   # Or :
#   asc/doc/doc.sh "Hello world"
#
#   # Converts given markdown file to pdf
#   make doc path/to/foobar.md pdf
#   # Or :
#   asc/doc/doc.sh path/to/foobar.md pdf
#
doc() {
  export ARGS="$@"

  export EXT="${EXT:-txt}"
  export VARIANTS="${VARIANTS:-STACK_VERSION PROVISION_USING HOST_TYPE}"

  hook -s 'doc' -p 'pre' -a "$EXT" -v "$VARIANTS"
  hook_ms -s 'doc' -a "$EXT" -v "$VARIANTS"
  hook -s 'doc' -p 'post' -a "$EXT" -v "$VARIANTS"
}
