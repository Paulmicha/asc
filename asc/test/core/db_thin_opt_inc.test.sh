#!/usr/bin/env bash

##
# Eager `db.inc.sh` keeps creds/flags. Dump/exec/setup cluster is lazy
# (`asc/extensions/db/db/db.opt-inc.sh`, pick A / caller-dir).
#
# This instance may ignore the db extension; the test sources the files
# directly.
#
# @requires asc/vendor/shunit2
# @see changelog/2026/09/19-db-thin-inc-and-opt-inc.md
#
# @example
#   asc/test/core/db_thin_opt_inc.test.sh
#

. asc/bootstrap.sh
. asc/extensions/db/db.inc.sh

##
# Creds stay on ASC_INC. Workflow functions do not.
#
test_f_db_workflow_absent_from_eager_inc() {
  assertEquals 'f_db_set stays eager' 'function' "$(type -t f_db_set)"
  assertEquals 'f_db_is_flagged stays eager' 'function' "$(type -t f_db_is_flagged)"
  assertEquals 'f_db_exists stays eager' 'function' "$(type -t f_db_exists)"
  assertEquals 'f_db_dump is not eager' '' "$(type -t f_db_dump)"
  assertEquals 'f_db_exec is not eager' '' "$(type -t f_db_exec)"
  assertEquals 'f_db_setup is not eager' '' "$(type -t f_db_setup)"
}

##
# Subject-wide caller-dir opt-inc defines the workflow cluster.
#
test_f_db_workflow_loads_from_caller_dir_opt_inc() {
  # shellcheck disable=SC1091
  . asc/extensions/db/db/db.opt-inc.sh
  assertEquals 'f_db_dump loads' 'function' "$(type -t f_db_dump)"
  assertEquals 'f_db_exec loads' 'function' "$(type -t f_db_exec)"
  assertEquals 'f_db_setup loads' 'function' "$(type -t f_db_setup)"
}

. asc/vendor/shunit2/shunit2
