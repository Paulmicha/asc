#!/usr/bin/env bash

##
# Checker extension global env vars.
#
# This file is used during "instance init" to generate data/asc/globals.sh which
# declares readonly constants, and get sourced in every ASC bootstraped context.
#
# @see asc/bootstrap.sh
#

# This is used to regroup lists of anti-patterns to look for in git diffs.
# This ASC core extension only defines the "asc" group, meaning : it provides
# only the list of anti-patterns to look for in "dev stack" repo work trees
# (= ASC project instances repos).
global ASC_ANTI_PATTERN_TYPES "[append]='asc'"

# Convenience equivalent "make" entry points shortcuts.
global ASC_SYNONYMS "[append]='anti-pattern/code-smell'"
