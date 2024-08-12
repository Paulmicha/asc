#!/usr/bin/env bash

##
# ASC instance globals introspection for convenience 'make' task.
#
# Prints all globals lookup paths checked for aggregation during instance init
# for current project instance.
#
# @see Makefile
# @see asc/make/default.mk
#
# @example
#   make globals-lp
#   # Or :
#   asc/env/global_lookup_paths.make.sh
#

. asc/bootstrap.sh

echo ""
echo "List of globals' aggregation paths that would be loaded, in this order, during instance (re)init :"
echo ""

echo "asc/env/global.vars.sh"
echo "  exists"

# 1. Files named without variant (i.e. 'global.vars.sh')
hook -a 'global' -c 'vars.sh' -t -d
# ... including extra lookup paths at the root of extensions' folders.
if [ -n "$ASC_EXTENSIONS" ]; then
  for extension in $ASC_EXTENSIONS; do
    ext_path=''
    u_asc_extension_path "$extension"
    echo "$ext_path/$extension/global.vars.sh "
    if [ -f "$ext_path/$extension/global.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

# 2. Files using variant in their name (i.e. 'global.docker-compose.vars.sh')
if [[ -n "$PROVISION_USING" ]]; then
  hook -a 'global' -c "${PROVISION_USING}.vars.sh" -t -d
  if [ -n "$ASC_EXTENSIONS" ]; then
    for extension in $ASC_EXTENSIONS; do
      ext_path=''
      u_asc_extension_path "$extension"
      echo "$ext_path/$extension/global.${PROVISION_USING}.vars.sh "
      if [ -f "$ext_path/$extension/global.${PROVISION_USING}.vars.sh" ]; then
        echo "  exists"
      fi
    done
  fi
fi

# 3. Using the asc.yml method takes precedence.
echo
if [[ -n "$HOST_TYPE" ]] && [[ -n "$INSTANCE_TYPE" ]]; then
  hook -s 'instance' -a 'asc' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -d -t
  echo "asc.yml
asc.$HOST_TYPE.yml
asc.$INSTANCE_TYPE.yml
asc.$HOST_TYPE.$INSTANCE_TYPE.yml
.asc-local.yml
.asc-local.$HOST_TYPE.yml
.asc-local.$INSTANCE_TYPE.yml
.asc-local.$HOST_TYPE.$INSTANCE_TYPE.yml"
else
  echo "asc.yml
.asc-local.yml"
fi

echo
