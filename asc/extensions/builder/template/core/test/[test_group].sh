#!/usr/bin/env bash

##
# Runs {{ test_group }} test suite(s).
#
# @example
#   make test-{{ test_group }}
#   Or :
#   scripts/cwt/extend/test/{{ test_group }}.sh
#

. asc/bootstrap.sh

if [[ "$(type -t f_test_batch_exec)" != function ]]; then
  # shellcheck disable=SC1091
  . asc/test/test.opt-inc.sh
fi

<asc-for each="test_suites as test_suite">
f_test_batch_exec '{{ path }}/test/{{ test_suite }}'
</asc-for>
