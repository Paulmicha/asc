#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'uninit'.
#
# This implementation may optionally alter entries to the following var in
# calling scope :
#
# @var purge_list_arr
#
# Cleans up any generated compose.yml files (and legacy docker-compose.yml).
# @see asc/instance/uninit.sh
#
# @example
#   make uninit
#   # Or :
#   asc/instance/uninit.sh
#

purge_list_arr+=('compose.yml')
purge_list_arr+=('compose.override.yml')
purge_list_arr+=('docker-compose.yml')
purge_list_arr+=('docker-compose.override.yml')
