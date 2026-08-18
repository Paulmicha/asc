#!/usr/bin/env bash

##
# Smoke tests for transcribe / convert hook resolution.
#
# @requires asc/vendor/shunit2
#
# @example
#   asc/extensions/transcription/transcribe/asc/transcribe.test.sh
#

. asc/bootstrap.sh

oneTimeSetUp() {
  rm -f data/asc/cache/hook.*transcribe* \
    data/asc/cache/hook.*ogg* \
    data/asc/cache/hook.*wav* \
    data/asc/cache/hook.*to_wav* \
    data/asc/cache/hook.*convert*
}

test_transcribe_ogg_hook_resolves() {
  hook_ms 'dry-run' -a 'ogg' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'ogg hook must resolve on this host' "[[ -f '$most_specific_match' ]]"
}

test_transcribe_wav_hook_resolves() {
  hook_ms 'dry-run' -a 'wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'wav hook must resolve on this host' "[[ -f '$most_specific_match' ]]"
}

test_transcribe_action_hook_resolves() {
  hook_ms 'dry-run' -a 'transcribe' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'transcribe hook must resolve on this host' "[[ -f '$most_specific_match' ]]"
}

test_convert_to_wav_hook_resolves() {
  hook_ms 'dry-run' -s 'convert' -a 'to_wav' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'to_wav hook must resolve on this host' "[[ -f '$most_specific_match' ]]"
}

test_transcribe_py_hook_resolves() {
  hook_ms 'dry-run' -a 'transcribe' -c 'py' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE' -t

  assertTrue 'transcribe.py hook must resolve on this host' "[[ -f '$most_specific_match' ]]"
}

test_convert_to_wav_entry_requires_file() {
  local status

  bash asc/extensions/transcription/convert/to_wav.sh >/dev/null 2>&1
  status=$?

  assertEquals 'missing convert input must abort (1)' 1 "$status"
}

test_transcribe_file_requires_input() {
  local status

  bash asc/extensions/transcription/transcribe/file.sh >/dev/null 2>&1
  status=$?

  assertEquals 'missing input file must abort (1)' 1 "$status"
}

test_transcribe_file_missing_file() {
  local status

  bash asc/extensions/transcription/transcribe/file.sh /no/such/clip.mp4 >/dev/null 2>&1
  status=$?

  assertEquals 'missing file must abort (2)' 2 "$status"
}

test_transcribe_file_unknown_option() {
  local status

  bash asc/extensions/transcription/transcribe/file.sh -x >/dev/null 2>&1
  status=$?

  assertEquals 'unknown option must abort (1)' 1 "$status"
}

. asc/vendor/shunit2/shunit2
