#!/usr/bin/env bash

##
# Render one skill entity through every enabled product extension.
#
# @example
#   asc/extensions/agent/skill/render.sh author-dev-task
#

. asc/bootstrap.sh

f_skill_render "$@"
