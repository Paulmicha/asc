#!/usr/bin/env bash

##
# Git init from existing dir, add all its contents, then push first commit.
#
# @param 1 String : the git remote.
# @param 2 [optional] String : the git working dir (path to work tree).
#   Defaults to current dir (empty string).
# @param 3 [optional] String : the git dir.
#   Defaults to "$2/.git".
#
# @example
#   # In current dir (default) :
#   make git-initial git@github.com:Paulmicha/redirection-fresk.git
#   # Or :
#   asc/git/initial.sh git@github.com:Paulmicha/redirection-fresk.git
#
#   # In another dir :
#   make git-initial git@github.com:Paulmicha/redirection-fresk.git path/to/git/work-tree
#   # Or :
#   asc/git/initial.sh git@github.com:Paulmicha/redirection-fresk.git path/to/git/work-tree
#

. asc/bootstrap.sh

p_git_remote="$1"
p_git_work_tree="$2"
p_git_dir="$3"

if [[ -z "$p_git_remote" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO : missing param 1 (the git remote)." >&2
  echo "Usage example :" >&2
  echo "  $FUNCNAME git@github.com:Paulmicha/redirection-fresk.git" >&2
  echo >&2
  return 1
fi

if [[ -z "$p_git_dir" ]]; then
  if [[ -z "$p_git_work_tree" ]]; then
    p_git_dir=".git"
  else
    p_git_dir="$p_git_work_tree/.git"
  fi
fi

if [[ -d "$p_git_dir" ]]; then
  echo >&2
  echo "The dir '$p_git_dir' already exists." >&2
  echo "Aborting." >&2
  echo >&2
  return 2
fi

giw init --initial-branch=main
giw remote add origin "$p_git_remote"
giw add .
giw commit -m "Initial commit"
giw push --set-upstream origin main
