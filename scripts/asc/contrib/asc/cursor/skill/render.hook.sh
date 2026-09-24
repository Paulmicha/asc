#!/usr/bin/env bash

##
# Cursor projection of a skill entity.
#
# @see asc/extensions/agent/skill/render.able.yml
#

if [[ -z "${SKILL_ID:-}" || -z "${SKILL_DESCRIPTION:-}" || -z "${SKILL_TASK:-}" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: SKILL_ID, SKILL_DESCRIPTION, and SKILL_TASK are required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

root="${SKILL_RENDER_ROOT:-${PROJECT_DOCROOT:-}}"
if [[ -z "$root" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: PROJECT_DOCROOT is empty." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

dest="${root}/.cursor/skills/${SKILL_ID}/SKILL.md"
mkdir -p "${dest%/*}"

{
  printf '%s\n' '---'
  printf 'name: %s\n' "$SKILL_ID"
  printf 'description: %s\n' "$SKILL_DESCRIPTION"
  printf '%s\n' '---' ''
  printf '# %s\n\n' "$SKILL_ID"
  printf '%s\n' "$SKILL_TASK"
  if [[ -n "${SKILL_BODY:-}" ]]; then
    printf '\n%s\n' "$SKILL_BODY"
  fi
} > "$dest"
