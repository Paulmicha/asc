#!/usr/bin/env bash

##
# Compatibility entry point for logged/pipe.sh (flat subject/action path).
#
# Make/action discovery only sees depth-1 $subject/$action.sh files. The
# implementation lives under instance/logged/; this wrapper keeps
# logged-pipe / make synonyms working.
#
# @see asc/instance/logged/pipe.sh
#

exec asc/instance/logged/pipe.sh "$@"
