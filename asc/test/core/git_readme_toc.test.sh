#!/usr/bin/env bash

##
# pre-commit refreshes a staged README.md table of contents.
#
# @requires asc/vendor/shunit2
# @see f_git_pre_commit_readme_toc() in asc/git/pre-commit.hook.sh
#
# @example
#   asc/test/core/git_readme_toc.test.sh
#

. asc/bootstrap.sh

unset asc_git_hook_args
# shellcheck disable=SC1091
. asc/git/pre-commit.hook.sh

f_git_readme_toc_repo() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  printf '%s\n' "$dir"
}

test_git_readme_toc_updates_staged_nav() {
  local dir readme rc
  dir="$(f_git_readme_toc_repo)"
  readme="$dir/README.md"

  cat >"$readme" <<'EOF'
# Title

## Table of contents

<nav>

- [Old](#old)

</nav>

## Hello
EOF

  git -C "$dir" add -- README.md
  f_git_pre_commit_readme_toc "$dir"
  rc=$?
  assertEquals 'toc refresh exits 0' 0 "$rc"
  assertTrue 'nav lists the heading' "grep -q '^- \[Hello\](#hello)$' '$readme'"
  assertTrue 'updated README is staged' \
    "git -C '$dir' diff --quiet -- README.md && git -C '$dir' diff --cached --name-only -- README.md | grep -qx README.md"

  rm -rf "$dir"
}

test_git_readme_toc_skips_when_readme_is_not_staged() {
  local dir readme before
  dir="$(f_git_readme_toc_repo)"
  readme="$dir/README.md"

  cat >"$readme" <<'EOF'
# Title

<nav>

</nav>

## Hello
EOF
  before="$(cat "$readme")"
  f_git_pre_commit_readme_toc "$dir"
  assertEquals 'unstaged README is left alone' "$before" "$(cat "$readme")"

  rm -rf "$dir"
}

test_git_readme_toc_skips_when_nav_is_missing() {
  local dir readme before
  dir="$(f_git_readme_toc_repo)"
  readme="$dir/README.md"

  printf '%s\n' '# Title' '' '## Hello' >"$readme"
  before="$(cat "$readme")"
  git -C "$dir" add -- README.md
  f_git_pre_commit_readme_toc "$dir"
  assertEquals 'README without nav is left alone' "$before" "$(cat "$readme")"

  rm -rf "$dir"
}

. asc/vendor/shunit2/shunit2
