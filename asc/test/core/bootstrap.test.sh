#!/usr/bin/env bash

##
# ASC core bootstrap-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# @example
#   asc/test/asc/bootstrap.test.sh
#

. asc/bootstrap.sh

##
# Are all required ASC core globals successfully initialized ?
#
# @see f_asc_extend()
#
test_asc_has_essential_globals() {
  assertFalse 'Global ASC_SUBJECTS is empty (bootstrap test failed)' "[ -e $ASC_SUBJECTS ]"
  assertFalse 'Global ASC_ACTIONS is empty (bootstrap test failed)' "[ -e $ASC_ACTIONS ]"
  assertFalse 'Global ASC_INC is empty (bootstrap test failed)' "[ -e $ASC_INC ]"
}

##
# Does the 'override' alteration mechanism work ?
#
test_asc_autoload_override_works() {
  local override_flag
  local override_source='asc/test/self.sh'

  # Test without match.
  override_flag=''
  f_autoload_override "$override_source" 'override_flag="NOK"'
  eval "$inc_override_evaled_code"
  assertTrue 'Flag should be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"

  # Test with match (populates the local override_flag variable).
  local base_dir='scripts'
  mkdir -p "$base_dir/overrides/test"
  cat > ${override_source/asc/"$base_dir/overrides"} <<'EOF'
#!/usr/bin/env bash
override_flag='not-empty'
EOF
  f_autoload_override "$override_source" '# (we have to pass some inoperant code here to carry on with the test)'
  eval "$inc_override_evaled_code"
  assertFalse 'Flag should not be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"
}

##
# Stamp includes instance identity so a type change is a miss even if ignore
# mtimes are unchanged.
#
test_asc_cache_stamp_includes_instance_identity() {
  local stamp_a=''

  f_asc_cache_stamp_compute 'stamp_a'

  assertTrue 'stamp lists HOST_TYPE' "[[ \"\$stamp_a\" == *HOST_TYPE=${HOST_TYPE}* ]]"
  assertTrue 'stamp lists INSTANCE_TYPE' "[[ \"\$stamp_a\" == *INSTANCE_TYPE=${INSTANCE_TYPE}* ]]"
  assertTrue 'stamp lists STACK_VERSION' "[[ \"\$stamp_a\" == *STACK_VERSION=${STACK_VERSION}* ]]"
  assertTrue 'stamp lists selected extensions-ignore path' '[[ "$stamp_a" == *extensions_ignore=* ]]'
}

##
# Matching stamp must not rewrite primitives cache.
#
test_asc_primitives_cache_stamp_match_skips_extend() {
  local before
  local after

  f_asc_primitives_cache_ensure
  touch -d '2 seconds ago' data/asc/cache/core/active.sh
  before=$(stat -c '%Y' data/asc/cache/core/active.sh)

  f_asc_primitives_cache_ensure
  after=$(stat -c '%Y' data/asc/cache/core/active.sh)

  assertEquals 'warm stamp must not rewrite core/active.sh' "$before" "$after"
}

##
# Ignore-file mtime change must rebuild primitives and wipe hook lookup.
#
test_asc_primitives_cache_ignore_touch_rebuilds_and_wipes_hooks() {
  local before
  local after

  f_asc_primitives_cache_ensure
  mkdir -p data/asc/cache/hook
  echo 'dummy' > data/asc/cache/hook/nftascstmpwipe.sh
  touch -d '2 seconds ago' data/asc/cache/core/active.sh
  before=$(stat -c '%Y' data/asc/cache/core/active.sh)

  touch .asc_extensions_ignore
  f_asc_primitives_cache_ensure
  after=$(stat -c '%Y' data/asc/cache/core/active.sh)

  assertTrue 'ignore touch must rewrite core/active.sh' "[ '$after' -gt '$before' ]"
  assertFalse 'stamp mismatch must wipe cache/hook lookup files' '[ -f data/asc/cache/hook/nftascstmpwipe.sh ]'
}

##
# make cc / cache_clear wipes lookup only; next ensure recreates core cache.
#
test_asc_cache_clear_keeps_globals_and_rebuilds_core() {
  assertTrue 'global.vars.sh present before cc' '[ -f data/asc/global.vars.sh ]'
  assertTrue 'generated.mk present before cc' '[ -f data/asc/generated.mk ]'

  . asc/asc/cache_clear.sh

  assertTrue 'cc must keep global.vars.sh' '[ -f data/asc/global.vars.sh ]'
  assertTrue 'cc must keep generated.mk' '[ -f data/asc/generated.mk ]'
  assertFalse 'cc must remove data/asc/cache' '[ -e data/asc/cache ]'

  f_asc_primitives_cache_ensure

  assertTrue 'next ensure writes core/active.sh' '[ -f data/asc/cache/core/active.sh ]'
  assertTrue 'next ensure writes core/stamp' '[ -f data/asc/cache/core/stamp ]'
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local base_dir='scripts'
  rm -rf "$base_dir/complements/test"
  rm -rf "$base_dir/overrides/test"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
