#!/usr/bin/env bash

##
# [abstract] Gets ASC project instance(s) on this host.
#
# TODO [wip]
#
# @example
#   # Lists all discovered instances by default ?
#   make host-instance-get
#   # Or :
#   asc/host/instance/get.sh
#
#   # Only the "mother" (ASC core repo) instance.
#   make host-instance-get mother
#   # Or :
#   asc/host/instance/get.sh mother
#
#   # Only other "normal" project instances.
#   make host-instance-get path/to/foobar/project-docroot
#   # Or :
#   asc/host/instance/get.sh path/to/foobar/project-docroot
#

. asc/bootstrap.sh

# TODO
