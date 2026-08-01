#!/usr/bin/env bash

##
# Compatibility entry point for logged/chain.sh (flat subject/action path).
#
# Make/action discovery only sees depth-1 $subject/$action.sh files. The
# implementation lives under instance/logged/; this wrapper keeps
# logged-chain / make synonyms working.
#
# @see asc/instance/logged/chain.sh
#

exec asc/instance/logged/chain.sh "$@"
