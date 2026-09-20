#!/usr/bin/env bash

##
# Implements hook -p 'post' -a 'init'.
#
# Discovers entity types and sidecar.able instances, then writes load cache.
# @see asc/extensions/entity/entity.inc.sh
#
# @example
#   # This gets executed during normal init :
#   scripts/init.sh
#
#   # Can also be run separately - here, in a subshell :
#   (. asc/bootstrap.sh && . asc/extensions/entity/instance/post_init.hook.sh)
#

echo "Discovering entity types and instances ..."
f_entity_types_discover
f_entity_instances_discover
f_entity_cache_generate_all
echo "Discovering entity types and instances : done."
echo
