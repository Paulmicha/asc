#!/usr/bin/env bash

##
# Skill entity helpers. Product projections are contrib hooks.
#
# @see asc/extensions/agent/skill/skill.entity.yml
# @see asc/extensions/agent/skill/render.able.yml
#

##
# Load one skill instance and run every skill/render hook.
#
# @param 1 String : skill id (data/entities/skill/<id>.yml stem).
#
# @example
#   f_skill_render author-dev-task
#
f_skill_render() {
  local p_id="$1"
  local sidecar="data/entities/skill/${p_id}.yml"

  if [[ -z "$p_id" ]]; then
    echo >&2
    echo "Error in f_skill_render() - $BASH_SOURCE line $LINENO: missing skill id." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ ! -f "$sidecar" ]]; then
    echo >&2
    echo "Error in f_skill_render() - $BASH_SOURCE line $LINENO: file '$sidecar' not found." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  f_entity_cache_generate skill "$p_id" || return 1
  f_entity_load skill "$p_id" || return 1
  hook -s 'skill' -a 'render'
}
