#!/usr/bin/env bash

##
# Implements hook -s 'asc' -a 'alias' -v 'STACK_VERSION PROVISION_USING'.
#
# Implement custom bash alias for the 'docker-compose' program given 'DC_MODE'
# value, which specifies if and how docker compose will choose a YAML
# declaration file for current project instance.
#
# @see asc/extensions/compose/global.vars.sh
# @see asc/bootstrap.sh
#

case "$DC_MODE" in

  # Automatically try to choose the most specific YAML file based on the
  # DC_YML_VARIANTS global (which provides hook variants for lookup paths).
  'auto')
    most_specific_match=''
    hook_ms 'dry-run' -s 'stack' -a 'compose' -c "yml" -v 'DC_YML_VARIANTS' -t

    if [[ -z "$most_specific_match" ]]; then
      hook_ms 'dry-run' -s 'stack' -a 'docker-compose' -c "yml" -v 'DC_YML_VARIANTS' -t
    fi

    if [[ -f "$most_specific_match" ]]; then
      alias docker-compose="docker compose -f $most_specific_match"
    fi
    ;;

  # Use the path provided in the DC_YML global.
  'manual')
    if [[ -f "$DC_YML" ]]; then
      alias docker-compose="docker compose -f $DC_YML"
    fi
    ;;
esac
