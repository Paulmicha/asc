#!/usr/bin/env bash

##
# [abstract] {{ title }}
#
# This action provides an entry point for triggering specific hooks. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this action to have any effect, it is necessary
# to use an extension that implements at least one of these hook calls.
#
# To list all the possible paths that are sourceable when the hook is triggered,
# run (in this order) :
# $ make hook-debug {{ hook_debug_call_args_pre }}
# $ make hook-debug {{ hook_debug_call_args }}
# $ make hook-debug {{ hook_debug_call_args_post }}
#
# @example
#   {{ make_example }}
#   # Or :
#   {{ script_example }}
#

. asc/bootstrap.sh

hook {{ hook_call_args_pre }}
hook {{ hook_call_args }}
hook {{ hook_call_args_post }}
