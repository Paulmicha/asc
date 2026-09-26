#!/usr/bin/env bash

##
# md_toc leaves a README.md with no <nav> block unchanged.
#
# @requires asc/vendor/shunit2
# @see asc/doc/md_toc.sh
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

  out="$(asc/doc/md_toc.sh "$readme" 2>&1)"
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

  asc/doc/md_toc.sh "$readme" >/dev/null
  rc=$?

  assertEquals 'README with nav exits 0' 0 "$rc"
  assertTrue 'nav lists the heading' "grep -q '^- \[Hello\](#hello)$' '$readme'"

  rm -rf "$dir"
}

test_md_toc_other_markdown_without_nav_errors() {
  local dir notes before rc out
  dir="$(mktemp -d)"
  notes="$dir/notes.md"
  printf '%s\n' '# Title' '' '## Hello' >"$notes"
  before="$(cat "$notes")"

  out="$(asc/doc/md_toc.sh "$notes" 2>&1)"
  rc=$?

  assertEquals 'other markdown without nav exits 1' 1 "$rc"
  assertEquals 'other markdown without nav is unchanged' "$before" "$(cat "$notes")"
  assertTrue 'error names the missing block' "printf '%s' '$out' | grep -q 'No <nav>'"

  rm -rf "$dir"
}

. asc/vendor/shunit2/shunit2
