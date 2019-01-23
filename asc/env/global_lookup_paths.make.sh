#!/usr/bin/env bash

##
# ASC instance globals introspection for convenience 'make' task.
#
# Prints all globals lookup paths checked for aggregation during instance init
# for current project instance.
#
# @see Makefile
#
# @example
#   asc/env/global_lookup_paths.make.sh
#

. asc/bootstrap.sh

echo "asc/env/global.vars.sh"

hook -a 'global' -c 'vars.sh' -v 'PROVISION_USING' -t -d

# Allow extra lookup paths at the root of extensions.
if [ -n "$ASC_EXTENSIONS" ]; then
  for extension in $ASC_EXTENSIONS; do
    echo "asc/extensions/$extension/global.vars.sh"
    if [ -f "asc/extensions/$extension/global.vars.sh" ]; then
      echo "  exists"
    fi
  done
fi

# Allow extra lookup path at the root of project's scripts, *after* all
# dynamic lookups above.
global_lookup_project_scripts_path='scripts'
if [[ -n "$PROJECT_SCRIPTS" ]]; then
  global_lookup_project_scripts_path="$PROJECT_SCRIPTS"
fi

echo "$global_lookup_project_scripts_path/global.vars.sh"
if [ -f "$global_lookup_project_scripts_path/global.vars.sh" ]; then
  echo "  exists"
fi

echo
