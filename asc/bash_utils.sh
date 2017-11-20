#!/bin/bash

##
# Bash scripts utilities.
#
# This will dynamically source all files found inside asc/utilities folder.
# They should contain only function declarations, using the following
# Convention : fonctions names are all prefixed by "u" (for "utility").
#
# For each file, it will also attempt to load a corresponding custom script to
# allow overriding functions.
# See complements documentation at asc/custom/complements/README.md.
#
# Load from project root dir :
# $ . asc/bash_utils.sh
#

for file in $( find asc/utilities/* -type f -print0 | xargs -0 ); do
  . "$file"
  u_autoload_get_complement "$file"
done
