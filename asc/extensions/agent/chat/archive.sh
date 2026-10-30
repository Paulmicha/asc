#!/usr/bin/env bash

##
# [abstract] Archives a given chat ID.
#
# This action provides an entry point for triggering specific hooks. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this action to have any effect, it is necessary
# to use an extension that implements at least one of these hook calls.
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:chat p:pre a:archive v:STACK_VERSION HOST_TYPE chat_TYPE
# $ make hook-debug s:chat a:archive v:STACK_VERSION HOST_TYPE chat_TYPE
# $ make hook-debug s:chat p:post a:archive v:STACK_VERSION HOST_TYPE chat_TYPE
#
# @example
#   make chat-archive
#   # Or :
#   asc/extensions/agent/chat/archive.sh
#

. asc/bootstrap.sh

hook -s 'chat' -p 'pre' -a 'archive' -v 'STACK_VERSION HOST_TYPE chat_TYPE'
hook -s 'chat' -a 'archive' -v 'STACK_VERSION HOST_TYPE chat_TYPE'
hook -s 'chat' -p 'post' -a 'archive' -v 'STACK_VERSION HOST_TYPE chat_TYPE'
