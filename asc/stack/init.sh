#!/usr/bin/env bash

##
# (Re)inits environment settings for this project intance.
#
# @see asc/env/README.md
#
# Usage examples :
# $ . asc/stack/init.sh                 # Will prompt to confirm/edit every default value
# $ . asc/stack/init.sh -s drupal-7     # Short name/value argument syntax
# $ . asc/stack/init.sh -s nodejs -y    # "-y" will use default values, no prompts
#

# TODO [wip] refacto/simplify globals aggregation.
