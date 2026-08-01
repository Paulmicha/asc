#!/usr/bin/env bash

##
# Remote Traefik utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Generates local Acme config file for Let's Encrypt.
#
# To list matches & check which one will be used (the most specific) :
# $ a_site='my_site_id'
#   hook_ms 'dry-run' \
#     -s 'stack' \
#     -a 'traefik' \
#     -c 'tpl.yml' \
#     -v 'INSTANCE_TYPE' \
#     -t -d
#   echo "match = $most_specific_match"
#
f_traefik_generate_acme_conf() {
  local var_val
  local var_name
  local token_prefix='{{ '
  local token_suffix=' }}'
  local traefik_conf="$PROJECT_DOCROOT/data/asc/traefik.yml"
  local most_specific_match=''

  hook_ms 'dry-run' \
    -s 'stack' \
    -a 'traefik' \
    -c 'tpl.yml' \
    -v 'INSTANCE_TYPE' \
    -t

  # No declaration file found ? Can't carry on, there's nothing to do.
  if [[ ! -f "$most_specific_match" ]]; then
    echo >&2
    echo "Error in f_traefik_generate_acme_conf() - $BASH_SOURCE line $LINENO: no settings template file was found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  # (Over)write config file in its final destination.
  if [[ -f "$traefik_conf" ]]; then
    rm -f "$traefik_conf"
  fi
  cp "$most_specific_match" "$traefik_conf"

  # Replace read-only global vars (supports any global) placeholders.
  f_global_list
  for var_name in "${asc_globals_var_names_arr[@]}"; do
    if grep -Fq "${token_prefix}${var_name}${token_suffix}" "$traefik_conf"; then
      var_val="${!var_name}"
      sed -e "s,${token_prefix}${var_name}${token_suffix},${var_val},g" -i "$traefik_conf"
      # Debug.
      # echo "replaced '${token_prefix}${var_name}${token_suffix}' by '${var_val}'"
    fi
  done

  # Special extra step : need to generate once data/asc/acme.json
  if [[ ! -f "$PROJECT_DOCROOT/data/asc/acme.json" ]]; then
    touch "$PROJECT_DOCROOT/data/asc/acme.json"
  fi
}
