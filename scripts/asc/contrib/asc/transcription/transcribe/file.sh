#!/usr/bin/env bash

##
# Transcribes given file (if possible).
#
# Converts to .wav, then transcribes .wav files to .txt using faster-whisper.
# Writes a transcript to "$filename.transcribed.txt" in the same directory as
# the input file.
#
# Parses CLI, converts non-wav input, exports the same a_* contract as
# abstract make transcribe, then dispatches to:
#   hook_ms -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Generic core default (tested on debian-13 only for now):
#   asc/extensions/transcription/transcribe/transcribe.hook.sh
#
# @see asc/extensions/transcription/transcribe/transcribe.hook.sh
# @see asc/extensions/transcription/instance/transcribe.sh
#
# @example
#   make transcribe-file -- path/to/file.mp4
#   # Or :
#   asc/extensions/transcription/transcribe/file.sh path/to/file.mp4
#
#   # Result :
#   # path/to/file.transcribed.txt
#

. asc/bootstrap.sh

a_input_dir=""
a_output_lang=""
a_skip_vscodium=1
a_targets=""
input_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--output-lang) a_output_lang="$2"; shift 2;;
    -s|--skip-vsc) a_skip_vscodium=1; shift 1;;
    -*)
      echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -n "$input_file" ]]; then
        echo "Error in $BASH_SOURCE line $LINENO: extra argument: $1" >&2
        exit 1
      fi
      input_file="$1"
      shift 1
      ;;
  esac
done

if [[ -z "$input_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - missing input file." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ ! -f "$input_file" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - file '$input_file' does not exist." >&2
  echo "Aborting (2)." >&2
  echo >&2
  exit 2
fi

a_input_dir="$(dirname -- "$input_file")"
stem_path="${input_file%.*}"

case "$input_file" in
  *.wav)
    wav_file="$input_file"
    ;;
  *)
    wav_file="${stem_path}.wav"
    if [[ ! -f "$wav_file" ]]; then
      export file="$input_file"
      export wav_file
      hook_ms -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
    fi
    if [[ ! -f "$wav_file" ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO - failed to convert '$input_file' to '$wav_file'." >&2
      echo "Aborting (3)." >&2
      echo >&2
      exit 3
    fi
    ;;
esac

agregated_txt="${stem_path}.transcribed.txt"

if [[ -f "$agregated_txt" ]]; then
  echo '' > "$agregated_txt"
else
  touch "$agregated_txt"
fi

a_targets="$wav_file"

export a_input_dir a_output_lang a_skip_vscodium a_targets agregated_txt

hook_ms -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
