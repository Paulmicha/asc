#!/usr/bin/env bash

##
# Implements hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now).
# Expects exported: file, wav_file
# -vn drops video; 16 kHz mono PCM matches Whisper.
#
# @see asc/extensions/transcription/convert/to_wav.sh
#

ffmpeg -y -vn -i "$file" -acodec pcm_s16le -ar 16000 -ac 1 "$wav_file" > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - non-zero status returned by :" >&2
  echo "  ffmpeg -y -vn -i '$file' -acodec pcm_s16le -ar 16000 -ac 1 '$wav_file'" >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi
