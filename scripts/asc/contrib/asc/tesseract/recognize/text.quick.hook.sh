#!/usr/bin/env bash

##
# Implements hook -s 'recognize' -a 'text' -v 'STACK_VERSION HOST_OS PROVISION_USING'
#
# TODO [wip] Recognize text using tesseract (with auto rotate).
#
# @param 1 String : path to image file.
# @param 2 [optional] String : path to output (txt or md). <- TODO [wip]
#
# @see asc/extensions/cognition/recognize/text.sh
#
# @example
#   make ocr path/to/file.jpg
#   # Or :
#   make recognize-text path/to/file.jpg
#   # Or :
#   asc/extensions/cognition/recognize/text.sh path/to/file.jpg
#

# TODO [wip]
# 1. Ask Tesseract to detect only the orientation (--psm 0)
# 2. Extract the "Rotate" value (0, 90, 180, or 270) using grep and cut
# 3. Use ImageMagick to physically rotate the image by that angle
ANGLE=$(tesseract input.jpg stdout --psm 0 2>/dev/null | grep "Rotate:" | cut -d: -f2 | xargs) \
  && magick input.jpg -rotate "$ANGLE" output.jpg
