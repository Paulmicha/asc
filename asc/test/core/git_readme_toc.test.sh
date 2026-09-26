#!/usr/bin/env bash

##
# pre-commit refreshes README.md's table of contents and stages it.
#
# @requires asc/vendor/shunit2
# @see f_git_pre_commit_readme_toc() in asc/git/pre-commit.hook.sh
#
# @example
#   asc/test/core/git_readme_toc.test.sh
#

. asc/bootstrap.sh

unset git_hook_args
unset git_hook_args_nb
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

test_git_readme_toc_updates_clean_tracked_readme() {
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
  git -C "$dir" -c user.email='test@example.com' -c user.name='test' \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null \
    commit -q -m 'init'

  f_git_pre_commit_readme_toc "$dir"
  rc=$?
  assertEquals 'clean README refresh exits 0' 0 "$rc"
  assertTrue 'nav lists the heading' "grep -q '^- \[Hello\](#hello)$' '$readme'"
  assertTrue 'TOC fix is staged' \
    "git -C '$dir' diff --quiet -- README.md && git -C '$dir' diff --cached --name-only -- README.md | grep -qx README.md"

  rm -rf "$dir"
}

test_git_readme_toc_skips_unstaged_edits() {
  local dir readme before
  dir="$(f_git_readme_toc_repo)"
  readme="$dir/README.md"

  printf '%s\n' '# Title' '' '<nav>' '' '</nav>' '' '## Hello' >"$readme"
  git -C "$dir" add -- README.md
  git -C "$dir" -c user.email='test@example.com' -c user.name='test' \
    -c commit.gpgsign=false -c core.hooksPath=/dev/null \
    commit -q -m 'init'
  printf '%s\n' 'local note' >>"$readme"
  before="$(cat "$readme")"

  f_git_pre_commit_readme_toc "$dir"
  assertEquals 'unstaged README edits are left alone' "$before" "$(cat "$readme")"

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

test_git_write_hooks_zero_args_set_a_count() {
  local dir script rc
  dir="$(mktemp -d)"
  # shellcheck disable=SC1091
  . asc/git/write_hooks.sh
  f_git_write_hooks 'pre-commit' "$dir" >/dev/null
  script="$dir/pre-commit"

  local needle rc
  needle='git_hook_args_nb="$#"'
  grep -F -q -- "$needle" "$script"
  rc=$?
  assertEquals 'wrapper records the argument count' 0 "$rc"

  bash -c 'git_hook_args_nb="$#"; git_hook_args=("$@"); [[ -n "${git_hook_args_nb+x}" && "$git_hook_args_nb" == 0 ]]'
  rc=$?
  assertEquals 'zero git arguments still set the count' 0 "$rc"

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
