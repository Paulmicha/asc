#!/usr/bin/env bash

##
# Deprecated: use asc/thread/batch.sh (make parallel / lb / thread-batch).
#
# This file is generated from template :
# @see asc/extensions/preset/preset/parallel/wrap.tpl.sh
#
# Kept as a thin redirect so old call sites do not diverge from batch.
#

. asc/thread/batch.sh "$@"
