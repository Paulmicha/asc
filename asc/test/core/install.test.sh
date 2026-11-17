#!/usr/bin/env bash

##
# Verifies installation into project paths using a local upstream fixture.
#
# @requires asc/vendor/shunit2
# @see asc/test/core.sh
#

. asc/bootstrap.sh

##
# Absolute and relative instance paths must receive the upstream directories.
#
test_install_copies_upstream_to_instance_paths() {
  local test_dir fixture target relative_target dir status
  test_dir="$(mktemp -d "$PWD/data/tmp/install-test.XXXXXX")"
  fixture="$test_dir/fixture"
  mkdir -p "$test_dir/bin" "$fixture" "$test_dir/absolute target" "$test_dir/relative target"

  for dir in asc docs/specs/asc scripts/asc/contrib/asc \
    .agents/skills/asc-actions-priority .agents/skills/asc-author-code \
    .agents/skills/asc-author-docs .agents/skills/asc-mother-guard; do
    mkdir -p "$fixture/$dir"
    printf 'upstream\n' > "$fixture/$dir/marker"
  done

  touch "$fixture/AGENTS.asc.md" "$fixture/AGENTS.md" "$fixture/.gitignore"
  printf 'upstream defaults\n' > "$fixture/.asc_extensions_ignore"
  printf '#!/usr/bin/env bash\ncp -r "$INSTALL_TEST_FIXTURE" "${@: -1}"\n' > "$test_dir/bin/git"
  chmod +x "$test_dir/bin/git"
  relative_target="${test_dir#"$PWD/"}/relative target"
  printf 'local settings\n' > "$relative_target/.asc_extensions_ignore"

  for target in "$test_dir/absolute target" "$relative_target"; do
    mkdir -p "$target/asc"
    printf 'old\n' > "$target/asc/old"
    printf 'local\n' > "$target/AGENTS.md"
    PATH="$test_dir/bin:$PATH" INSTALL_TEST_FIXTURE="$fixture" bash asc/core/install.sh "$target" > "$test_dir/output" 2>&1
    status=$?
    assertEquals "installation succeeds for $target: $(cat "$test_dir/output")" 0 "$status"

    for dir in asc docs/specs/asc scripts/asc/contrib/asc \
      .agents/skills/asc-actions-priority .agents/skills/asc-author-code \
      .agents/skills/asc-author-docs .agents/skills/asc-mother-guard; do
      assertTrue "upstream copied to $target/$dir" "[ -f '$target/$dir/marker' ]"
    done

    assertFalse 'old core is replaced' "[ -f '$target/asc/old' ]"
    assertEquals 'instance instructions are preserved' 'local' "$(cat "$target/AGENTS.md")"

    if [[ "$target" == "$relative_target" ]]; then
      assertEquals 'existing extension settings are preserved' 'local settings' "$(cat "$target/.asc_extensions_ignore")"
    else
      assertEquals 'default extension settings are installed' 'upstream defaults' "$(cat "$target/.asc_extensions_ignore" 2>/dev/null)"
    fi
  done

  rm -rf "$test_dir"
}

. asc/vendor/shunit2/shunit2
