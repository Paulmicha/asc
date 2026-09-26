#!/usr/bin/env bash

##
# Implements hook -s 'git' -a 'pre-commit'.
#
# When README.md contains a <nav> block and has no unstaged edits, regenerates
# that table of contents and stages the result, including when the file was
# not already part of this commit.
#
# @see f_git_write_hooks() in asc/git/write_hooks.sh
# @see asc/doc/md_toc.sh
#

f_git_pre_commit_readme_toc() {
  local work_tree="${1:-$PROJECT_DOCROOT}"
  local readme="$work_tree/README.md"
  local asc_root staged

  [[ -f "$readme" ]] || return 0

  if ! grep -q '^<nav>[[:space:]]*$' "$readme"; then
    return 0
  fi

  # Unstaged edits are not part of this commit.
  if ! git -C "$work_tree" diff --quiet -- README.md; then
    return 0
  fi

  # A tracked file, or one already staged. An untracked README stays out.
  if ! git -C "$work_tree" ls-files --error-unmatch -- README.md >/dev/null 2>&1; then
    staged="$(git -C "$work_tree" diff --cached --name-only --diff-filter=A -- README.md)"
    [[ "$staged" == 'README.md' ]] || return 0
  fi

  asc_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  (
    cd "$asc_root" || exit 1
    "$asc_root/asc/doc/md_toc.sh" "$readme"
  ) || return 1

  git -C "$work_tree" add -- README.md
}

if [[ -n "${git_hook_args_nb+x}" ]]; then
  f_git_pre_commit_readme_toc || exit $?
fi
