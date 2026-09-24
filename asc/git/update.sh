#!/usr/bin/env bash

##
# Runs git pull only if it will not produce any conflict.
#
# @param 1 [optional] String : the target branch name.
#   Defaults to current local branch name.
# @param 2 [optional] String : the git remote.
#   Defaults to 'origin'.
#
# @example
#   make git-update
#   # Or :
#   asc/git/update.sh
#
#   make git-update 'foobar-branch'
#   # Or :
#   asc/git/update.sh 'foobar-branch'
#
#   make git-update 'foobar-branch' 'custom-remote'
#   # Or :
#   asc/git/update.sh 'foobar-branch' 'custom-remote'
#

. asc/bootstrap.sh

p_branch="$1"
p_remote="$2"

if [[ -z "$p_branch" ]]; then
  p_branch="$(giw branch --show-current)"
fi

if [[ -z "$p_remote" ]]; then
  p_remote='origin'
fi

if \
  giw fetch "$p_remote" \
  && ! giw merge-tree "$(giw merge-base HEAD "$p_remote"/main)" HEAD "$p_remote"/main \
  | grep -q '^<<<<<<<'
then
  giw pull
fi
