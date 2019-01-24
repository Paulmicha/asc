#!/usr/bin/env bash

##
# ASC core bootstrap-related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/asc.sh
#
# @example
#   asc/test/asc/bootstrap.test.sh
#

. asc/bootstrap.sh

##
# Are all required ASC core globals successfully initialized ?
#
# @see u_asc_extend()
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
  u_autoload_override "$override_source" 'override_flag="NOK"'
  eval "$inc_override_evaled_code"
  assertTrue 'Flag should be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"

  # Test with match (populates the local override_flag variable).
  local base_dir='scripts'
  mkdir -p "$base_dir/overrides/test"
  cat > ${override_source/asc/"$base_dir/overrides"} <<'EOF'
#!/usr/bin/env bash
override_flag='not-empty'
EOF
  u_autoload_override "$override_source" '# (we have to pass some inoperant code here to carry on with the test)'
  eval "$inc_override_evaled_code"
  assertFalse 'Flag should not be empty at this stage ("override" alteration mechanism failed)' "[ -e $override_flag ]"
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
