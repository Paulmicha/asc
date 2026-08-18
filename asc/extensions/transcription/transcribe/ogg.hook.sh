#!/usr/bin/env bash

##
# Implements hook_ms -a 'ogg' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now).
# Converts .ogg files in a_input_dir to .wav via convert/to_wav.
#
# @see asc/extensions/transcription/transcribe/all.sh
#

find "$a_input_dir" -maxdepth 1 -type f -name "*.ogg" -printf "%T@ %p\n" \
  | sort -n \
  | cut -d' ' -f2- \
  | while read -r file
do
  echo "Processing: '$file' ..."

  wav_file="${file%.ogg}.wav"
  existing_txt="${file%.ogg}.txt"

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
    continue
  fi

  if [[ ! -f "$wav_file" ]]; then
    export file
    export wav_file
    hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
  fi

  if [[ ! -f "$wav_file" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - failed to convert '$file' to '$wav_file'." >&2
    echo "Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  echo "Processing: '$file' : done."
done
