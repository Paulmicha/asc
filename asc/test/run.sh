#!/usr/bin/env bash

##
# [wip] Run tests.
#
# Usage :
# $ asc/test/run.sh
#

# [wip] debug.
for file in $(find asc/test/asc -maxdepth 1 -type f -print0 | xargs -0); do
  bats "$file"
done
