#!/usr/bin/env bash

##
# Convenience git shortcut : legacy shared-linux utility to merge push.
#
# Merges current branch into given target branch then push and go back to same
# branch.
#
# @param 1 [optional] String : the target branch name.
#   Defaults to 'preprod' or 'staging', whichever exists - first found is used.
# @param 2 [optional] String : the branch branch name to merge.
#   Defaults to current branch.
# @param 3 [optional] String : the git remote.
#   Defaults to 'origin'.
#
# @example
#   # Merge current branch into 'preprod' or 'staging' - whichever exists (first
#   # found is used) :
#   make git-mp
#   # Or :
#   asc/git/mp.sh
#
#   # Optionally, if we're not in the actual git dir :
#   # @see giw()
#   p_git_work_tree=/path/to/git/work-tree
#   make git-mp
#   # Or :
#   asc/git/mp.sh
#
#   # Merge current branch into 'prod' :
#   make git-mp 'prod'
#   # Or :
#   asc/git/mp.sh 'prod'
#
#   # Merge into 'dev' the branch 'JIRA-123-foobar' :
#   make git-mp 'dev' 'JIRA-123-foobar'
#   # Or :
#   asc/git/mp.sh 'dev' 'JIRA-123-foobar'
#

. asc/bootstrap.sh

p_branch_to="$1"
p_branch_from="$2"
p_remote="$3"

# Defaults to 'preprod' or 'staging', whichever exists - first found is used.
if [[ -z "$p_branch_to" ]]; then
  if f_git_branch_exists 'preprod' ; then
    p_branch_to='preprod'
  elif f_git_branch_exists 'staging' ; then
    p_branch_to='staging'
  fi
fi

# ... but if none of the above preset names exist, we can't carry on.
if [[ -z "$p_branch_to" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO in $FUNCNAME() : missing param 1 (the git branch name)." >&2
  echo "Usage example :" >&2
  echo "  $FUNCNAME 'dev'" >&2
  echo >&2
  return 1
fi

if [[ -z "$p_branch_from" ]]; then
  p_branch_from="$(giw branch --show-current)"
fi

if [[ -z "$p_branch_from" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO in $FUNCNAME() : missing param 2 (which git branch to merge)." >&2
  echo >&2
  return 2
fi

if [[ -z "$p_remote" ]]; then
  p_remote='origin'
fi

giw checkout "$p_branch_to"

if [[ $? -ne 0 ]]; then
  return
fi

giw pull

if [[ $? -ne 0 ]]; then
  return
fi

giw pull origin "$p_branch_from" --no-edit

if [[ $? -ne 0 ]]; then
  return
fi

# Only rewrite the commit log message if it starts with 'Merge branch '.
case "$(giw log -1 --pretty=%B)" in 'Merge branch '*)
  local commit_message_overwrite="Merge branch '$p_branch_from' into '$p_branch_to'"

  giw commit --amend -m "$commit_message_overwrite"

  if [[ $? -ne 0 ]]; then
    return
  fi
esac

giw push

if [[ $? -ne 0 ]]; then
  return
fi

giw checkout "$p_branch_from"
