#!/usr/bin/env bash

##
# [abstract] Reads given chat's last read.
#
# @param 1 String : The chat id.
#
# This action provides an entry point for triggering specific hooks. "Abstract"
# means that ASC core itself doesn't provide any actual implementation for this
# functionality. In order for this action to have any effect, it is necessary
# to use an extension that implements at least one of these hook calls.
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:chat p:pre a:read v:STACK_VERSION HOST_TYPE CHAT_PROVIDER
# $ make hook-debug s:chat a:read v:STACK_VERSION HOST_TYPE CHAT_PROVIDER
# $ make hook-debug s:chat p:post a:read v:STACK_VERSION HOST_TYPE CHAT_PROVIDER
#
# @example
#   make chat-read
#   # Or :
#   asc/extensions/agent/chat/read.sh
#

. asc/bootstrap.sh

if [[ -z "$CHAT_PROVIDER" ]]; then
  CHAT_PROVIDER='dummy'
fi

hook -s 'chat' -p 'pre' -a 'read' -v 'STACK_VERSION HOST_TYPE CHAT_PROVIDER'
hook -s 'chat' -a 'read' -v 'STACK_VERSION HOST_TYPE CHAT_PROVIDER'
hook -s 'chat' -p 'post' -a 'read' -v 'STACK_VERSION HOST_TYPE CHAT_PROVIDER'
