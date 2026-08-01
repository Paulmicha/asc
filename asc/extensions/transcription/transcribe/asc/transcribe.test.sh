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

. asc/vendor/shunit2/shunit2
