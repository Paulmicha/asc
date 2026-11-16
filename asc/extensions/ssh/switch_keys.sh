#!/usr/bin/env bash

##
# Switches SSH keys (unloads all but the given subdir).
#
# When you work on the same host but some git remotes reject SSH keys when they
# all get loaded at the same time, you need to turn some on and off when
# switching projects.
#
# This utility makes possible to use subdirs inside ~/.ssh per "group" of keys
# to swap.
#
# @param 1 string : subdir.
#
# @example
#   make ssh-switch-keys 'foobar'
#   # Or :
#   asc/ssh/switch_keys.sh 'foobar'
#

. asc/bootstrap.sh

f_ssh_switch_keys "$@"
