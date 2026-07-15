#!/usr/bin/env bash

##
# Pipe composition alias → asc/thread/pipe.sh (shell operator: |).
#
# @example
#   make pipe 'ls -lah' 'grep foobar'
#   make pipe e:transcribe-ogg e:transcribe-ocr
#   # Or :
#   asc/instance/pipe.sh 'ls -lah' 'grep foobar'
#

. asc/thread/pipe.sh "$@"
