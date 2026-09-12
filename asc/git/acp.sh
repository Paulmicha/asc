#!/usr/bin/env bash

##
# Convenience git shortcut : stage all, commit with given message, and push.
#
# @example
#   make git-acp "'Foobar commit message.'"
#   # Or :
#   asc/git/acp.sh "Foobar commit message."
#

. asc/bootstrap.sh

git add .
git commit -m "$@"
git push
