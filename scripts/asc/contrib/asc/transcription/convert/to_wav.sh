#!/usr/bin/env bash

##
# Converts given audio or video file to wav format.
#
# Generic core default (tested on debian-13 only for now).
# Stem is ${file%.*}.wav so .ogg, .mp4, and other ffmpeg-readable inputs work.
#
# @example
#   make convert-to-wav path/to/my/file.mp4
#   # Or :
#   asc/extensions/transcription/convert/to_wav.sh path/to/my/file.mp4
#   # Yields :
#   path/to/my/file.wav
#

. asc/bootstrap.sh

a_file="$1"

if [[ ! -f "$a_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - missing file :" >&2
  echo "  '$a_file'" >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

echo "Processing: '$a_file' ..."

export file="$a_file"
export wav_file="${a_file%.*}.wav"

if [[ -f "$wav_file" ]]; then
  echo "Already exists: '$wav_file'"
  echo "Processing: '$a_file' : done."

  exit 0
fi

echo "Converting to '$wav_file' ..."

hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'

if [[ ! -f "$wav_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - failed to convert '$a_file' to '$wav_file'." >&2
  echo "Aborting (2)." >&2
  echo >&2
  exit 2
fi

echo "Converting to '$wav_file' : done."
echo "Processing: '$a_file' : done."
