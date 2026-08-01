#!/usr/bin/env bash

##
# Bootstrap phase: initialize ASC primitives (cache or f_asc_extend).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Initializes "primitives" for hooks and lookups (ASC extension mecanisms).
# These are : subjects, actions, prefixes, variants and extensions.
# Update 2024-06 cache results.
if [[ -f data/asc/cache/asc.sh ]]; then
  . data/asc/cache/asc.sh
else
  export asc_primitives_cache_str=''
  ASC_INC=''
  f_asc_extend
  mkdir -p data/asc/cache
  cat > data/asc/cache/asc.sh <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for ASC primitives.
#
# @see asc/bootstrap.sh
#

$asc_primitives_cache_str

CACHE
fi
