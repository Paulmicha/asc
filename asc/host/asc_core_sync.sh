#!/usr/bin/env bash

##
# Synchronizes every ASC project instances core files on this host.
#
# The idea is to have the mother repo changes applied to other ASC projects,
# and the contrary : check wether diffs are actual improvements.
#
# @param 1 [optional] String : path to a single ASC project instance (docroot).
#   Defaults to '', meaning : all discovered ASC project instances get synced.
#
# @example
#   # Default behavior = 1. backports any improvements to the mother repo, then
#   # 2. Apply improvements to every ASC project instances on this host.
#   make host-asc-core-sync
#   # Or :
#   asc/host/asc_core_sync.sh
#
#   # The first argument allows to restrict that to a single project instance.
#   make host-asc-core-sync path/to/foobar
#   # Or :
#   asc/host/asc_core_sync.sh path/to/foobar
#

. asc/bootstrap.sh

# TODO
