#!/usr/bin/env bash

##
# Hardcoded `make ds` carrier.
#
# The DSL expression is read from ASC_DS_EXPR in the process environment so it
# is never a Make goal. That keeps colliding recipes (for example `debug`) from
# interpolating the expression as unquoted shell. Bound argv is not carried by
# Make in this slice — use asc/dsl.sh / f_asc_dsl with `--`.
#
# Does not run f_make_unescape : literal ∓, =, and \$ stay as supplied.
#
# @see asc/make/default.mk
# @see docs/specs/asc/dsl.md
#
# @example
#   ASC_DS_EXPR='slug(foobar)' make ds
#   ASC_DS_EXPR="slug('a b')" make ds
#

if [[ ! -v ASC_DS_EXPR ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: ASC_DS_EXPR is unset." >&2
  echo "Pass the DSL expression through the environment, not as a Make goal :" >&2
  echo >&2
  echo "  ASC_DS_EXPR='slug(foobar)' make ds" >&2
  echo >&2
  echo "For caller argv bindings, use the direct script :" >&2
  echo "  asc/dsl.sh 'slug(p1)' -- 'Foo Bar'" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

asc/dsl.sh "$ASC_DS_EXPR"
exit $?
