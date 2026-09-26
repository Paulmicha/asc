#!/usr/bin/env bash

##
# Implements hook -s 'git' -a 'pre-commit'.
#
# When README.md is part of the commit and contains a <nav> block, regenerates
# that table of contents and stages the result.
#
# The generated git hook sets asc_git_hook_args before calling hook. Sourcing
# this file otherwise only defines f_git_pre_commit_readme_toc().
#
# @see asc/doc/md_toc.sh
# @see f_git_write_hooks() in asc/git/write_hooks.sh
#

f_git_pre_commit_readme_toc() {
  local work_tree="${1:-$PROJECT_DOCROOT}"
  local readme="$work_tree/README.md"
  local asc_root staged

  [[ -f "$readme" ]] || return 0

  staged="$(git -C "$work_tree" diff --cached --name-only --diff-filter=ACMR -- README.md)"
  [[ "$staged" == 'README.md' ]] || return 0

  if ! grep -q '^<nav>[[:space:]]*$' "$readme"; then
    return 0
  fi

  asc_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  (
    cd "$asc_root" || exit 1
    "$asc_root/asc/doc/md_toc.sh" "$readme"
  ) || return 1

  git -C "$work_tree" add -- README.md
}

if [[ -n "${asc_git_hook_args+x}" ]]; then
  f_git_pre_commit_readme_toc || exit $?
fi
