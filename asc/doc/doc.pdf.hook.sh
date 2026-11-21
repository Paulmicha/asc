#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'throw' -v 'LV HANDLER HOST_TYPE'.
#
# @see asc/core/utils/shell.manual-inc.sh
#
# @example
#   make doc path/to/foobar.md pdf
#   # Or :
#   asc/instance/doc.sh path/to/foobar.md pdf
#

asc/doc/pdf.sh "$ARGS"
