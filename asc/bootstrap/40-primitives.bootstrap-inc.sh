#!/usr/bin/env bash

##
# Bootstrap phase: initialize ASC primitives (cache or u_asc_extend).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Initializes "primitives" for hooks and lookups (ASC extension mecanisms).
# These are : subjects, actions, prefixes, variants and extensions.
# Update 2024-06 cache results.
if [[ -f scripts/asc/local/cache/asc.sh ]]; then
  . scripts/asc/local/cache/asc.sh
else
  export asc_primitives_cache_str=''
  ASC_INC=''
  u_asc_extend
  mkdir -p scripts/asc/local/cache
  cat > scripts/asc/local/cache/asc.sh <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for ASC primitives.
#
# @see asc/bootstrap.sh
#

$asc_primitives_cache_str

CACHE
fi
