#!/usr/bin/env bash

##
# [abstract] {{ title }}
#
# This action provides an entry point for triggering specific hooks. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this action to have any effect, it is necessary
# to use an extension that implements this hook call.
#
# To list all the possible paths that are sourceable when the hook is triggered,
# run :
# $ make hook-debug {{ hook_debug_call_args }}
#
# @example
#   {{ make_example }}
#   # Or :
#   {{ script_example }}
#

. asc/bootstrap.sh

hook {{ hook_call_args }}
