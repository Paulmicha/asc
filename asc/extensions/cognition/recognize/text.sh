#!/usr/bin/env bash

##
# Perform OCR on given file (path).
#
# @param 1 String : path to image file.
# @param 2 [optional] String : path to output (txt or md). <- TODO [wip]
#
# @example
#   make ocr path/to/file.jpg
#   # Or :
#   make recognize-text path/to/file.jpg
#   # Or :
#   asc/extensions/cognition/recognize/text.sh path/to/file.jpg
#

. asc/bootstrap.sh

p_file="$1"

if [[ -z "$p_file" || ! -f "$p_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: missing or inexisting file : '$p_file'" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

hook_variants='STACK_VERSION HOST_OS PROVISION_USING'

hook -s 'recognize' -a 'text' -v "$hook_variants" -p 'pre'
hook -s 'recognize' -a 'text' -v "$hook_variants"
hook -s 'recognize' -a 'text' -v "$hook_variants" -p 'post'
