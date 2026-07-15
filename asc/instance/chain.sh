#!/usr/bin/env bash

##
# TODO chaining is "&&" or ";" between raw shell in joined subshells or entry points (asc actions).
#
# @example
#   # Defaults to "and" (stops in case of error)
#   make chain e:transcribe-ogg e:transcribe-ocr
#
#   # Can be "or" like :
#   make chain or e:transcribe-ogg e:transcribe-ocr
#

# TODO new arg to switch between mode ?
# This is just an alias for :
. asc/thread/sequence.sh $@
