#!/usr/bin/env bash

##
# Searches log messages and list files changed in matching commits.
#
# When executed as a script, bootstraps ASC then prints `git_changed_files_arr`.
# When sourced, only defines f_git_find_changed_files().
#
# @see f_git_find_commits() in asc/git/git.opt-inc.sh
#
# @example
#   # After bootstrap :
#   . asc/git/find_changed_files.sh
#   f_git_find_changed_files 'JRA-224'
#
#   # Search log messages in all branches and list all files changed in all
#   # matching commits :
#   asc/git/find_changed_files.sh 'JRA-224'
#   # Or :
#   make git-find-changed-files 'JRA-224'
#
#   # Same, by only search in a specific branch only :
#   asc/git/find_changed_files.sh 'JRA-224' 'my-branch-name'
#   # Or :
#   make git-find-changed-files 'JRA-224' 'my-branch-name'
#

##
# Searches log messages and gets all files changed in all matching commits.
#
# This function writes its result to a variable subject to collision in calling
# scope :
# @var git_changed_files_arr
#
# @param 1 String : The (grep) search pattern.
# @param 2 [optional] String : A branch name to restrict the search.
#   Defaults to all branches.
#
# @example
#   # Search log messages in all branches and get all files changed in all
#   # matching commits :
#   f_git_find_changed_files 'JRA-224'
#   for f in "${git_changed_files_arr[@]}"; do
#     echo "$f"
#   done
#
#   # Same, by only search in a specific branch only :
#   f_git_find_changed_files 'JRA-224' 'my-branch-name'
#   for f in "${git_changed_files_arr[@]}"; do
#     echo "$f"
#   done
#
f_git_find_changed_files() {
  local p_search="$1"
  local p_source_branch="$2"

  if [[ "$(type -t f_git_find_commits)" != function ]]; then
    # shellcheck disable=SC1091
    . asc/git/git.opt-inc.sh
  fi

  # By default, search in all branches.
  if [[ -z "$p_source_branch" ]]; then
    p_source_branch='--all'
  fi

  f_git_find_commits \
    -m "$p_search" \
    -f '<have-changed>' \
    -b "$p_source_branch" \
    -v
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_git_find_changed_files "$@"
  for f in "${git_changed_files_arr[@]}"; do
    echo "$f"
  done
fi
