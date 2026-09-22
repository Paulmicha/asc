#!/usr/bin/env bash

##
# Convenience git shortcut : stage all, commit with given message, and push.
#
# @example
#   # Default commit message is 'wip: backup progress' for emergency backups.
#   make git-acp
#   # Or :
#   asc/git/acp.sh
#
#   # Custom commit message :
#   make git-acp "'Foobar commit message.'"
#   # Or :
#   asc/git/acp.sh "Foobar commit message."
#

. asc/bootstrap.sh

p_message="$@"

if [[ -z "$p_message" ]]; then
  p_message='wip: backup progress'
fi

git add .
git commit -m "$p_message"
git push
