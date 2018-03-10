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
# Does the 'complement' extension mechanism work ?
#
test_asc_autoload_complement_works() {
  local complement_flag
  local complement_source='asc/test/self.sh'

  # Test without match.
  complement_flag=''
  u_autoload_get_complement "$complement_source"
  assertTrue 'Flag should be empty at this stage ("complement" autoload extension mechanism failed)' "[ -e $complement_flag ]"

  # Test with match (populates the local complement_flag variable).
  local base_dir='asc/custom'
  if [[ -n "$ASC_CUSTOM_DIR" ]]; then
    base_dir="$ASC_CUSTOM_DIR"
  fi
  mkdir -p "$base_dir/complements/test"
  cat > ${complement_source/asc/"$base_dir/complements"} <<'EOF'
#!/usr/bin/env bash
complement_flag='not-empty'
EOF
  u_autoload_get_complement "$complement_source"
  assertFalse 'Flag should not be empty at this stage ("complement" autoload extension mechanism failed)' "[ -e \"$complement_flag\" ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  local base_dir='asc/custom'
  if [[ -n "$ASC_CUSTOM_DIR" ]]; then
    base_dir="$ASC_CUSTOM_DIR"
  fi
  rm -rf "$base_dir/complements/test"
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
