#!/usr/bin/env bash

##
# Compose stack utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# (re)Writes the compose.yml file to use in current project instance.
#
# Creates or override the compose.yml and compose.override.yml
# files for local project instance based on the most specific match found.
#
# @requires the DC_YML_VARIANTS global in calling scope.
# @see asc/extensions/compose/global.vars.sh
#
# To list all the possible paths that can be used, use :
# $ make hook-debug s:stack a:compose c:yml v:DC_YML_VARIANTS
# $ make hook-debug s:stack a:compose.override c:yml v:DC_YML_VARIANTS
#
# To check which YAML file will actually be selected, use :
# $ make hook-debug ms s:stack a:compose c:yml v:DC_YML_VARIANTS
# $ make hook-debug ms s:stack a:compose.override c:yml v:DC_YML_VARIANTS
#
# By default, Compose reads two files_arr, compose.yml and an optional
# compose.override.yml file. By convention, compose.yml
# contains your base configuration. The override file, as its name implies,
# can contain configuration overrides for existing services or entirely new
# services.
# If a service is defined in both files_arr, Compose merges the configurations
# using the following rules :
# - If a configuration option is defined in both the original service and the
#   local service, the local value replaces or extends the original value.
# - For single-value options like image, command or mem_limit, the new value
#   replaces the old value.
# - For the multi-value options ports, expose, external_links, dns, dns_search,
#   and tmpfs, Compose concatenates both sets of values.
# - In the case of environment, labels, volumes, and devices, Compose “merges”
#   entries together with locally-defined values taking precedence. For
#   environment and labels, the environment variable or label name determines
#   which value is used.
# - Entries for volumes and devices are merged using the mount path in the
#   container.
#
# @link https://docs.docker.com/compose/extends/#adding-and-overriding-configuration
#
f_dc_write_yml() {
  local f
  local most_specific_match=''

  local compose_file
  local compose_name
  local lookup='compose docker-compose compose.override docker-compose.override'

  if [[ -n "$DC_YML_LOOKUP" ]]; then
    lookup="$DC_YML_LOOKUP"
  fi

  # Do both compose + compose.override in one loop.
  for compose_name in $lookup; do
    compose_file="$compose_name.yml"
    most_specific_match=''

    # Remove existing files if previously generated.
    if [[ -f "$compose_file" ]]; then
      rm "$compose_file"
    fi

    hook_ms 'dry-run' -s 'stack' -a "$compose_name" -c "yml" -v 'DC_YML_VARIANTS' -t

    if [[ -n "$most_specific_match" ]]; then
      echo "Generating $compose_file file (from $most_specific_match) ..."

      cp "$most_specific_match" "$compose_file"

      echo "Generating $compose_file file (from $most_specific_match) : done."
    fi
  done
}
