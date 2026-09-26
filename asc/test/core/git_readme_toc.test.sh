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

ASC_BS_SKIP_GLOBALS=1
. asc/bootstrap.sh
PROJECT_DOCROOT="$PWD"

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


# Each writer case runs in a subshell: writer failures intentionally exit.
f_git_wire_fixture() {
  cd "$wire_tmp" || exit 1
  PROJECT_DOCROOT="$wire_tmp/instance"
  SITE_DOCROOT="$wire_tmp/instance/site"
  APP_DOCROOT="$wire_tmp/legacy"
  git init -q "$PROJECT_DOCROOT"
  git init -q "$SITE_DOCROOT"
  git init -q "$APP_DOCROOT"
  mkdir -p "$PROJECT_DOCROOT/asc"
  # Run the actual listener through the generated wrapper, in an isolated ASC
  # bootstrap. No dependency on the host instance's cached hook lookup.
  printf 'hook() { . %q; }\n' "$wire_source/asc/git/pre-commit.hook.sh" \
    > "$PROJECT_DOCROOT/asc/bootstrap.sh"
  printf '%s\n' '# Title' '<nav>' 'old' '</nav>' '## New' > "$PROJECT_DOCROOT/README.md"
  git -C "$PROJECT_DOCROOT" add README.md
  . "$wire_source/asc/git/write_hooks.sh"
}

f_git_wire_case() (
  f_git_wire_fixture
  case "$1" in
    invalid) f_git_write_hooks 'pre-commit my-site:pre-commit' ;;
    explicit) f_git_write_hooks 'pre-commit site:pre-commit' "$PROJECT_DOCROOT/.git/hooks" ;;
    missing) SITE_DOCROOT=''; f_git_write_hooks 'pre-commit site:pre-commit' ;;
    collision)
      ln -s "$SITE_DOCROOT" alias
      APP_DOCROOT=alias
      f_git_write_hooks 'site:pre-commit app:pre-commit'
      ;;
    instance_collision)
      SITE_DOCROOT="$PROJECT_DOCROOT/."
      f_git_write_hooks 'pre-commit site:pre-commit'
      ;;
    alias)
      cd "$PROJECT_DOCROOT" || exit 1
      APP_DOCROOT=site
      f_git_write_hooks 'site:pre-commit'
      test -x "$SITE_DOCROOT/.git/hooks/pre-commit"
      ;;
    context)
      f_git_write_hooks 'site:pre-commit'
      cp "$PROJECT_DOCROOT/README.md" before_readme
      cp "$PROJECT_DOCROOT/.git/index" before_index
      (cd "$SITE_DOCROOT" && bash .git/hooks/pre-commit) || exit $?
      cmp before_readme "$PROJECT_DOCROOT/README.md" || exit 1
      cmp before_index "$PROJECT_DOCROOT/.git/index"
      ;;
    merge)
      f_git_write_hooks 'pre-commit asc:pre-commit'
      grep -qx "git_hook_context='asc'" "$PROJECT_DOCROOT/.git/hooks/pre-commit" || exit 1
      f_git_write_hooks 'asc:pre-commit pre-commit'
      grep -qx "git_hook_context='asc'" "$PROJECT_DOCROOT/.git/hooks/pre-commit"
      ;;
    bare)
      f_git_write_hooks 'pre-commit' "$SITE_DOCROOT/.git/hooks"
      grep -qx "git_hook_context=''" "$SITE_DOCROOT/.git/hooks/pre-commit"
      ;;
    cleanup|unmarked|write_failure|chmod_failure)
      printf '%s\n' '# automatically generated during "instance init"' '# edited body' \
        > "$APP_DOCROOT/.git/hooks/pre-commit"
      case "$1" in
        unmarked) printf '%s\n' '# custom' > "$APP_DOCROOT/.git/hooks/pre-commit" ;;
        write_failure) mkdir "$PROJECT_DOCROOT/.git/hooks/pre-commit" ;;
        chmod_failure) chmod() { return 1; } ;;
      esac
      f_git_write_hooks 'pre-commit'
      ;;
  esac
)

test_git_wire_validation_precedes_writes() {
  local wire_source="$PWD" wire_tmp mode rc
  for mode in invalid explicit missing collision instance_collision; do
    wire_tmp="$(mktemp -d)"
    f_git_wire_case "$mode" >/dev/null 2>&1
    rc=$?
    case "$mode" in invalid|explicit) assertEquals "$mode" 2 "$rc" ;; *) assertEquals "$mode" 1 "$rc" ;; esac
    assertFalse 'no instance hook written' "test -e '$wire_tmp/instance/.git/hooks/pre-commit'"
    assertFalse 'no app hook written' "test -e '$wire_tmp/instance/site/.git/hooks/pre-commit'"
    rm -rf -- "$wire_tmp"
  done
}

test_git_wire_contexts_and_path_alias() {
  local wire_source="$PWD" wire_tmp mode
  for mode in alias context merge bare; do
    wire_tmp="$(mktemp -d)"
    f_git_wire_case "$mode" >/dev/null
    assertEquals "$mode" 0 "$?"
    rm -rf -- "$wire_tmp"
  done
}

test_git_wire_legacy_cleanup_requires_success() {
  local wire_source="$PWD" wire_tmp mode rc
  for mode in cleanup unmarked write_failure chmod_failure; do
    wire_tmp="$(mktemp -d)"
    f_git_wire_case "$mode" >/dev/null 2>&1
    rc=$?
    case "$mode" in
      write_failure|chmod_failure) assertEquals "$mode fails" 1 "$rc" ;;
      *) assertEquals "$mode succeeds" 0 "$rc" ;;
    esac
    if [[ "$mode" == cleanup ]]; then
      assertFalse 'marked edited legacy hook removed' "test -e '$wire_tmp/legacy/.git/hooks/pre-commit'"
    else
      assertTrue 'legacy hook preserved' "test -f '$wire_tmp/legacy/.git/hooks/pre-commit'"
    fi
    rm -rf -- "$wire_tmp"
  done
}

. asc/vendor/shunit2/shunit2
