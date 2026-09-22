#!/usr/bin/env bash

##
# doc next-steps writer: lanes, human-file refusal, docroot hook_ms rung.
#
# @requires asc/vendor/shunit2
#
# @example
#   asc/test/core/next_steps.test.sh
#

. asc/bootstrap.sh
# shellcheck disable=SC1091
. asc/doc/next_steps.sh

##
# Text of one generated section, without the following heading.
#
f_doc_next_steps_test_section() {
  local file="$1"
  local heading="$2"
  awk -v heading="$heading" '
    $0 == heading { p = 1; next }
    p && /^## / { exit }
    p { print }
  ' "$file"
}

test_doc_next_steps_lanes_from_fixture() {
  local dir
  local out
  local status
  local sequential
  local after
  local parallel

  dir="$(mktemp -d)"
  out="$dir/NEXT_STEPS.agent.md"
  mkdir -p "$dir/changelog/2026/09" "$dir/changelog/2026/07"

  cat > "$dir/changelog/2026/09/19-live.md" <<'EOF'
| **Status** | live next |
| **Scope** | fixture |

- [ ] do the git shrink
- [ ] After the shrink, update the case table
EOF

  cat > "$dir/changelog/2026/09/11-optional.md" <<'EOF'
| **Status** | split — parent |
| **Scope** | fixture |

- [ ] Optional: measure wrap cost
- [ ] Pointer only: [child](./19-live.md)
EOF

  cat > "$dir/changelog/2026/07/31-partial.md" <<'EOF'
| **Status** | partial implementation — waves 1–3 done |
| **Scope** | fixture |

- [ ] wave 4 focused pass
EOF

  cat > "$dir/changelog/2026/09/20-later.md" <<'EOF'
| **Status** | proposed, later. No code. |
| **Scope** | fixture |

- [ ] do not start this
EOF

  cat > "$dir/changelog/2026/09/04-old.md" <<'EOF'
| **Status** | implemented (`abc`) |
| **Scope** | fixture |

- [ ] historical checkbox about orphan headings
EOF

  (
    next_steps_changelog_dir="$dir/changelog"
    next_steps_agent_path="$out"
    f_doc_next_steps_write
  )
  status=$?
  assertEquals 'fixture write failed.' 0 "$status"
  assertTrue 'human path must not be created by the writer.' "[ ! -f '$dir/NEXT_STEPS.md' ]"

  sequential="$(f_doc_next_steps_test_section "$out" '## Sequential')"
  after="$(f_doc_next_steps_test_section "$out" '## Sequential, after the row above')"
  parallel="$(f_doc_next_steps_test_section "$out" '## Parallel')"

  grep -q 'do the git shrink' <<< "$sequential"
  assertEquals 'sequential keeps the open git task.' 0 "$?"
  grep -q 'orphan headings' <<< "$sequential"
  assertEquals 'historical checkbox stays out of sequential.' 1 "$?"
  grep -q 'update the case table' <<< "$after"
  assertEquals 'after-chain keeps the After line.' 0 "$?"
  grep -q 'measure wrap cost' <<< "$after"
  assertEquals 'optional row is in the after section.' 0 "$?"

  local after_line optional_line
  after_line="$(grep -n 'update the case table' <<< "$after" | head -n 1 | cut -d: -f1)"
  optional_line="$(grep -n 'measure wrap cost' <<< "$after" | head -n 1 | cut -d: -f1)"
  assertTrue 'After sorts ahead of Optional.' "[ -n '$after_line' ] && [ -n '$optional_line' ] && [ '$after_line' -lt '$optional_line' ]"

  grep -q 'wave 4 focused pass' <<< "$parallel"
  assertEquals 'parallel keeps the partial wave.' 0 "$?"
  grep -q '20-later.md' "$out"
  assertEquals 'deferred note is awaiting approval.' 0 "$?"
  grep -q 'do not start this' "$out"
  assertEquals 'deferred task text is not an agent task.' 1 "$?"
  grep -q '04-old.md' "$out"
  assertEquals 'shipped note is do-not-re-run.' 0 "$?"
  grep -q 'orphan headings' "$out"
  assertEquals 'shipped checkbox text is omitted.' 1 "$?"

  rm -rf "$dir"
}

test_doc_next_steps_refuses_human_file() {
  local dir
  local status

  dir="$(mktemp -d)"
  mkdir -p "$dir/changelog"
  printf '| **Status** | live |\n\n- [ ] something\n' > "$dir/changelog/a.md"

  (
    next_steps_changelog_dir="$dir/changelog"
    next_steps_agent_path="$dir/NEXT_STEPS.md"
    f_doc_next_steps_write
  ) 2>/dev/null
  status=$?
  assertEquals 'writer must refuse NEXT_STEPS.md.' 1 "$status"
  assertTrue 'refused path must not exist.' "[ ! -e '$dir/NEXT_STEPS.md' ]"
  rm -rf "$dir"
}

test_doc_next_steps_docroot_rung() {
  local before
  local after
  local human

  assertTrue 'human approval file is present.' "[ -f NEXT_STEPS.md ]"
  before="$(md5sum NEXT_STEPS.md)"
  f_doc_next_steps_write
  assertEquals 'docroot write failed.' 0 "$?"
  after="$(md5sum NEXT_STEPS.md)"
  assertEquals 'writer must not modify NEXT_STEPS.md.' "$before" "$after"

  human="$(f_doc_next_steps_test_section NEXT_STEPS.agent.md '## Sequential, after the row above')"
  grep -q 'Optional: measure wrap vs action bootstrap cost' <<< "$human"
  assertEquals 'optional after-chain row is still listed.' 0 "$?"
  grep -q 'orphan headings' NEXT_STEPS.agent.md
  assertEquals 'pdf historical text is not copied.' 1 "$?"

  next_steps_actor='agent'
  rm -f data/asc/cache/hook/*a-NEXT_STEPS*
  hook_dry_run_matches=''
  most_specific_match=''
  hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor' -r
  assertEquals 'agent variant wins rung 4.' 'NEXT_STEPS.agent.md' "$most_specific_match"

  rm -f data/asc/cache/hook/*a-NEXT_STEPS*
  hook_dry_run_matches=''
  most_specific_match=''
  hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -r
  assertEquals 'human file wins without the agent variant.' 'NEXT_STEPS.md' "$most_specific_match"
}

test_gates_yml_docroot_rung() {
  local parsed=''

  assertTrue 'gates.yml is present.' "[ -f gates.yml ]"
  rm -f data/asc/cache/hook/*a-gates*
  hook_dry_run_matches=''
  most_specific_match=''
  hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r
  assertEquals 'gates.yml wins rung 4.' 'gates.yml' "$most_specific_match"

  f_yaml_parse 'gates.yml' 'gate_' 'parsed'
  grep -q 'subshell-printf-v-candidates' <<< "$parsed"
  assertEquals 'gates.yml parses and names the printf -v changelog.' 0 "$?"
  grep -q 'gates__go' <<< "$parsed"
  assertEquals 'gates.yml exposes a go field.' 0 "$?"
  grep -q 'gates__summary' <<< "$parsed"
  assertEquals 'gates.yml exposes a summary field.' 0 "$?"
  grep -q 'Continue waves' <<< "$parsed"
  assertEquals 'waves 5-8 row is folded out of gates.yml.' 1 "$?"
}

. asc/vendor/shunit2/shunit2
