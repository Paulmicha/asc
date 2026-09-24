#!/usr/bin/env bash

##
# Renames current git branch both locally an remotely.
#
# @link https://stackoverflow.com/a/30590238/2592338
#
# @param 1 String : the new branch name.
# @param 2 [optional] String : the git remote.
#   Defaults to 'origin'.
# @param 3 [optional] String : the old branch name.
#   Defaults to current branch.
#
# @example
#   make git-branch-rename 'new-branch-name'
#   make git-branch-rename 'new-branch-name' 'origin' 'old-branch-name'
#   # Or :
#   asc/git/branch/rename.sh 'new-branch-name'
#   asc/git/branch/rename.sh 'new-branch-name' 'origin' 'old-branch-name'
#
#   # Optionally, if we're not in the actual git dir :
#   # @see giw()
#   p_git_work_tree=/path/to/git/work-tree
#   make git-branch-rename 'new-branch-name'
#   # Or :
#   asc/git/branch/rename.sh 'new-branch-name'

. asc/bootstrap.sh

f_git_branch_rename "$@"
