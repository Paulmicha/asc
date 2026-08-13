#!/usr/bin/env bash

##
# Detect software profile and store SOFTWARE_VARIANT in the instance registry.
#
# @example
#   make software-discover
#   # Or :
#   asc/extensions/software/software/discover.sh
#

. asc/bootstrap.sh

a_variant='default'

# Optional hostname-based profiles (extend as needed).
case "$(hostname -s 2>/dev/null || hostname)" in
  *-laptop|laptop-*)
    a_variant='laptop'
    ;;
  *-desktop|desktop-*)
    a_variant='desktop'
    ;;
esac

f_instance_registry_set 'software_variant' "$a_variant"

echo "software_variant = '$a_variant'"
echo "Over."
