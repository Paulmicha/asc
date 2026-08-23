#!/usr/bin/env bash

##
# Implements hook_ms -a 'wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now).
# Transcribes .wav files in a_input_dir to .txt using faster-whisper.
#
# TODO setup (prereqs) doc — pipx + faster-whisper (software-deps future plan).
# TODO [evol] automatically copy files from the $HOME/Downloads dir if the input
# dir is empty.
#
# @see asc/extensions/transcription/transcribe/transcribe.py
# @see asc/extensions/transcription/transcribe/all.sh
#
# @example
#   # Defaults to :
#   #   -l|--output-lang : auto-detect
#   #   -i|--input-dir : "data/media/$(date +"%Y")/$(date +"%m")"
#   make transcribe-all
#

find "$a_input_dir" -maxdepth 1 -type f -name "*.wav" -printf "%T@ %p\n" \
  | sort -n \
  | cut -d' ' -f2- \
  | while read -r file
do
  echo "Processing: '$file' ..."

  existing_txt="${file%.wav}.txt"

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
    continue
  fi

  most_specific_match=''
  hook_ms 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  if [[ ! -f "$most_specific_match" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - no implementation match :" >&2
    echo >&2
    echo "  hook_ms 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t" >&2
    echo >&2
    echo "    HOST_OS = '$HOST_OS'" >&2
    echo "    HOST_TYPE = '$HOST_TYPE'" >&2
    echo "    INSTANCE_TYPE = '$INSTANCE_TYPE'" >&2
    echo >&2
    echo "Aborting (4)." >&2
    echo >&2
    exit 4
  fi

  if [[ -z "$a_output_lang" ]]; then
    python "$most_specific_match" "$file"
  else
    python "$most_specific_match" "$file" --output-lang "$a_output_lang"
  fi

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO - non-zero status returned by :" >&2
    echo "  python '$most_specific_match' '$file'" >&2
    echo "Aborting (5)." >&2
    echo >&2
    exit 5
  fi

  if [[ -f "$existing_txt" ]]; then
    cat "$existing_txt" >> "$agregated_txt"
    echo >> "$agregated_txt"
  fi

  echo "Processing: '$file' : done."
done
