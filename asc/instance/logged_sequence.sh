#!/usr/bin/env bash

##
# Logged sequence composition: log/wrap → thread/sequence.
#
# @example
#   # Manually hardcoded shortcut :
#   # @see ASC_SYNONYMS in asc/env/global.vars.sh
#   make ls e:1:transcribe-ogg e:2:transcribe-ocr
#   # Equivalent to :
#   make logged-sequence e:1:transcribe-ogg e:2:transcribe-ocr
#   # Or :
#   asc/instance/logged_sequence.sh e:1:transcribe-ogg e:2:transcribe-ocr
#

. asc/bootstrap.sh

logged_sequence_variants='STACK_VERSION PROVISION_USING HOST_OS'

hook -s 'log' -p 'pre' -a 'logged_sequence' -v "$logged_sequence_variants"
hook -s 'sequence' -p 'pre' -a 'logged_sequence' -v "$logged_sequence_variants"

asc/log/wrap.sh asc/thread/sequence.sh "$@"

hook -s 'log' -p 'post' -a 'logged_sequence' -v "$logged_sequence_variants"
hook -s 'sequence' -p 'post' -a 'logged_sequence' -v "$logged_sequence_variants"
