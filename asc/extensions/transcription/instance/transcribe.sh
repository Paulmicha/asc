#!/usr/bin/env bash

##
# Abstract transcription entry: parse CLI → export p_* → most-specific hook.
#
# Generic core default (tested on debian-13 only for now):
#   asc/extensions/transcription/transcribe/transcribe.hook.sh
#
# Dispatch is subject-free so any subject may implement transcribe.<variants>.hook.sh.
#
# Host software (manual for now): pipx + faster-whisper — see future software-deps plan.
#
# @example
#   make transcribe
#   # Or :
#   asc/extensions/transcription/instance/transcribe.sh
#
#   # From custom dir, forcing output language in french :
#   make transcribe -- -i data/media/2026/07 -l fr
#   # Or :
#   asc/extensions/transcription/instance/transcribe.sh -i data/media/2026/07 -l fr
#

. asc/bootstrap.sh

a_input_dir=""
a_output_lang=""
a_skip_vscodium=0
a_targets=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input-dir) a_input_dir="$2"; shift 2;;
    -l|--output-lang) a_output_lang="$2"; shift 2;;
    -s|--skip-vsc) a_skip_vscodium=1; shift 1;;
    -*)
      echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2
      exit 1
      ;;
    *)
      a_targets+="${a_targets:+ }$1"
      shift 1
      ;;
  esac
done

if [[ ! -d "$a_input_dir" ]]; then
  a_input_dir="data/media/$(date +"%Y")/$(date +"%m")"
fi

if [[ ! -d "$a_input_dir" ]]; then
  mkdir -p "$a_input_dir"
fi

if [[ ! -d "$a_input_dir" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - folder '$a_input_dir' does not exist." >&2
  echo "Aborting (2)." >&2
  echo >&2
  exit 2
fi

if [[ "$a_skip_vscodium" != "1" ]]; then
  nohup \
    /usr/bin/codium data/media > /dev/null 2>&1 &
  disown
fi

agregated_txt="$a_input_dir/transcribed.txt"

if [[ -f "$agregated_txt" ]]; then
  echo '' > "$agregated_txt"
else
  touch "$agregated_txt"
fi

export a_input_dir a_output_lang a_skip_vscodium a_targets agregated_txt

hook_ms -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
