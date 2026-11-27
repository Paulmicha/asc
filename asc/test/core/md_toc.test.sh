#!/usr/bin/env bash

##
# md_toc leaves a README.md with no <nav> block unchanged.
#
# @requires asc/vendor/shunit2
# @see asc/doc/md/toc.sh
#
# @example
#   asc/test/core/md_toc.test.sh
#

. asc/bootstrap.sh

test_md_toc_readme_without_nav_is_unchanged() {
  local dir readme before rc out
  dir="$(mktemp -d)"
  mkdir -p "$dir/docs"
  readme="$dir/docs/README.md"
  printf '%s\n' '# Title' '' '## Hello' >"$readme"
  before="$(cat "$readme")"

  out="$(asc/doc/md/toc.sh "$readme" 2>&1)"
  rc=$?

  assertEquals 'README without nav exits 0' 0 "$rc"
  assertEquals 'README without nav is unchanged' "$before" "$(cat "$readme")"
  assertEquals 'README without nav prints nothing' '' "$out"

  rm -rf "$dir"
}

test_md_toc_readme_with_nav_is_updated() {
  local dir readme rc
  dir="$(mktemp -d)"
  readme="$dir/README.md"
  cat >"$readme" <<'EOF'
# Title

<nav>

- [Old](#old)

</nav>

## Hello
EOF

  asc/doc/md/toc.sh "$readme" >/dev/null
  rc=$?

  assertEquals 'README with nav exits 0' 0 "$rc"
  assertTrue 'nav lists the heading' "grep -q '^- \[Hello\](#hello)$' '$readme'"

  rm -rf "$dir"
}

test_md_toc_github_slug_keeps_underscore_and_double_hyphen() {
  local dir readme rc
  dir="$(mktemp -d)"
  readme="$dir/README.md"
  cat >"$readme" <<'EOF'
# Title

<nav>

- [Old](#old)

</nav>

## PLANS : Changes, Implementation Steps, Execution Plans

## NEXT_STEPS : Priorities

## Actions = (make) _Entry points_
EOF

  asc/doc/md/toc.sh "$readme" >/dev/null
  rc=$?

  assertEquals 'TOC regen exits 0' 0 "$rc"
  assertTrue 'plans slug keeps double hyphen' \
    "grep -Fq '[PLANS : Changes, Implementation Steps, Execution Plans](#plans--changes-implementation-steps-execution-plans)' '$readme'"
  assertTrue 'next_steps slug keeps underscore and double hyphen' \
    "grep -Fq '[NEXT_STEPS : Priorities](#next_steps--priorities)' '$readme'"
  assertTrue 'emphasis underscores stripped from slug' \
    "grep -Fq '[Actions = (make) _Entry points_](#actions--make-entry-points)' '$readme'"
  assertTrue 'emphasis markers not left in slug' \
    "! grep -Fq '(#actions--make-_entry-points_)' '$readme'"

  rm -rf "$dir"
}

test_md_toc_other_markdown_without_nav_errors() {
  local dir notes before rc out
  dir="$(mktemp -d)"
  notes="$dir/notes.md"
  printf '%s\n' '# Title' '' '## Hello' >"$notes"
  before="$(cat "$notes")"

  out="$(asc/doc/md/toc.sh "$notes" 2>&1)"
  rc=$?

  assertEquals 'other markdown without nav exits 1' 1 "$rc"
  assertEquals 'other markdown without nav is unchanged' "$before" "$(cat "$notes")"
  assertTrue 'error names the missing block' "printf '%s' '$out' | grep -q 'No <nav>'"

  rm -rf "$dir"
}

. asc/vendor/shunit2/shunit2
