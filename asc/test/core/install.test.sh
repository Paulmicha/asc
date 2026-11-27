#!/usr/bin/env bash

##
# Verifies installation into project paths from the current ASC tree.
#
# @requires asc/vendor/shunit2
# @see asc/test/core.sh
#

. asc/bootstrap.sh

##
# Absolute and relative instance paths must receive the upstream directories.
#
test_install_copies_upstream_to_instance_paths() {
  local test_dir target relative_target dir status
  test_dir="$(mktemp -d "$PWD/data/tmp/install-test.XXXXXX")"
  mkdir -p "$test_dir/absolute target" "$test_dir/relative target"
  relative_target="${test_dir#"$PWD/"}/relative target"
  printf 'local settings\n' > "$relative_target/.asc_extensions_ignore"

  for target in "$test_dir/absolute target" "$relative_target"; do
    mkdir -p "$target/asc"
    printf 'old\n' > "$target/asc/old"
    printf 'local\n' > "$target/AGENTS.md"
    bash asc/core/install.sh "$target" > "$test_dir/output" 2>&1
    status=$?
    assertEquals "installation succeeds for $target: $(cat "$test_dir/output")" 0 "$status"

    for dir in asc docs/specs/asc scripts/asc/contrib/asc \
      .agents/skills/asc-actions-priority .agents/skills/asc-author-code \
      .agents/skills/asc-author-docs .agents/skills/asc-mother-guard; do
      diff -qr "$dir" "$target/$dir" > /dev/null
      assertEquals "source copied to $target/$dir" 0 "$?"
    done

    assertFalse 'old core is replaced' "[ -f '$target/asc/old' ]"
    assertEquals 'instance instructions are preserved' 'local' "$(cat "$target/AGENTS.md")"

    if [[ "$target" == "$relative_target" ]]; then
      assertEquals 'existing extension settings are preserved' 'local settings' "$(cat "$target/.asc_extensions_ignore")"
    else
      assertEquals 'default extension settings are installed' "$(cat .asc_extensions_ignore)" "$(cat "$target/.asc_extensions_ignore" 2>/dev/null)"
    fi
  done

  rm -rf "$test_dir"
}

. asc/vendor/shunit2/shunit2
