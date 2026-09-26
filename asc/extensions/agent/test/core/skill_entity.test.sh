#!/usr/bin/env bash

##
# Skill entity is product-neutral. Contrib hooks project it.
#
. asc/bootstrap.sh

oneTimeSetUp() {
  skill_render_root="$(mktemp -d)"
}

oneTimeTearDown() {
  rm -rf "$skill_render_root"
}

test_skill_type_is_discovered() {
  entity_types_arr=()
  f_entity_types_discover || fail 'discover types failed'
  local found=1
  local t
  for t in "${entity_types_arr[@]}"; do
    case "$t" in skill) found=0 ;; esac
  done
  assertEquals 'skill.entity.yml not discovered' '0' "$found"
}

test_skill_type_includes_sidecar_and_render() {
  f_entity_type_includes_able skill 'sidecar.able' \
    || fail 'skill.entity.yml includes sidecar.able'
  f_entity_type_includes_able skill 'render.able' \
    || fail 'skill.entity.yml includes render.able'
}

test_skill_spec_keys() {
  keys_arr=()
  f_entity_spec_get_keys skill || fail 'get_keys failed'
  local k found_description=1 found_task=1 found_body=1
  for k in "${keys_arr[@]}"; do
    case "$k" in
      description) found_description=0 ;;
      task) found_task=0 ;;
      body) found_body=0 ;;
    esac
  done
  assertEquals 'description' '0' "$found_description"
  assertEquals 'task' '0' "$found_task"
  assertEquals 'body' '0' "$found_body"
}

test_core_skill_files_do_not_name_products() {
  local f
  for f in \
    asc/extensions/agent/skill/skill.entity.yml \
    asc/extensions/agent/skill/skill.inc.sh \
    asc/extensions/agent/skill/render.sh \
    asc/extensions/agent/skill/render.able.yml
  do
    if grep -E -i -q 'cursor|codex|claude|\.cursor/|\.codex/|\.claude/' "$f"; then
      fail "product name in $f"
    fi
  done
}

test_skill_render_writes_one_file_per_product() {
  export SKILL_RENDER_ROOT="$skill_render_root"
  f_skill_render author-dev-task || fail 'render failed'
  assertTrue 'cursor projection' \
    "[ -f ${skill_render_root}/.cursor/skills/author-dev-task/SKILL.md ]"
  assertTrue 'codex projection' \
    "[ -f ${skill_render_root}/.codex/skills/author-dev-task/SKILL.md ]"
  assertTrue 'claude projection' \
    "[ -f ${skill_render_root}/.claude/skills/author-dev-task/SKILL.md ]"
  grep -q 'ASC_GIT_HOOKS_WIRED' \
    "${skill_render_root}/.cursor/skills/author-dev-task/SKILL.md" \
    || fail 'task text missing from cursor projection'
  unset SKILL_RENDER_ROOT
}

. asc/vendor/shunit2/shunit2
