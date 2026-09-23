#!/usr/bin/env bash

##
# Refresh ./NEXT_STEPS.agent.md from changelog status rows.
#
# The agent file and ./NEXT_STEPS.md are hook_ms data files on the project-docroot
# rung (same model as env.yml: -c md -r). Dry-run selects one path. They are not
# sourced.
#
#   next_steps_actor=agent
#   hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor' -r
#   # → NEXT_STEPS.agent.md (more dot-parts, same rung, so it wins)
#
#   hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -r
#   # → NEXT_STEPS.md
#
# This entry point rewrites only the agent file. Discussion stays in
# NEXT_STEPS.md. Go-ahead for a listed task is the gates file (env.yml lookup,
# -c yml -r). This script writes neither of those.
#
# @example
#   make doc-next-steps
#   # Or :
#   asc/doc/next_steps.sh
#

##
# Classify one changelog status cell.
#
# Writes $lane in the calling scope: skip, held, discuss, parallel, sequential.
#
# @param 1 String : status cell, markdown bold already removed.
# @param 2 Int : count of unchecked task lines.
#
f_doc_next_steps_lane() {
  local plain="$1"
  local nopen="$2"
  local low="${plain,,}"

  lane='skip'
  if [[ "$nopen" -eq 0 ]]; then
    return
  fi

  case "$low" in
    implemented*|done*|shipped*)
      lane='held'
      return
      ;;
  esac

  if [[ "$low" == *skipped* ]]; then
    lane='held'
    return
  fi

  # "later" only when the status defers the whole note ("proposed, later", "no code").
  # A live note that says a follow-up is "still later" stays on the sequential chain.
  if [[ "$low" == *"no code"* || "$low" == *"docs only"* \
    || "$low" == *"plan / review"* || "$low" == *inventory* \
    || "$low" == *"go-ahead"* || "$low" == *"open conflict"* \
    || "$low" == plan* || "$low" == *unstarted* || "$low" == *"not in the"* \
    || "$low" == *"proposed, later"* || "$low" == *", later"* ]]; then
    lane='discuss'
    return
  fi

  if [[ "$low" == *partial* ]]; then
    lane='parallel'
    return
  fi

  lane='sequential'
}

##
# Keep, delay, or drop one unchecked task line.
#
# Writes $task_bucket in the calling scope: now, after, drop.
#
# @param 1 String : checkbox line.
#
f_doc_next_steps_task_bucket() {
  local line="$1"
  local low="${line,,}"

  task_bucket='now'
  case "$low" in
    *'](./'*|*'](../'*)
      task_bucket='drop'
      return
      ;;
  esac

  if [[ "$low" == *commit* || "$low" == *"do not"* || "$low" == *"don't"* ]]; then
    task_bucket='drop'
    return
  fi

  case "$line" in
    *'After '*|*'Optional:'*|*'Optional '*)
      task_bucket='after'
      ;;
  esac
}

##
# Append one lane's file groups to $next_steps_buf.
#
# @param 1 String : heading.
# @param 2 String : lane (sequential, parallel) or bucket name after.
# @param 3 String : intro paragraph.
#
f_doc_next_steps_emit_tasks() {
  local heading="$1"
  local which="$2"
  local intro="$3"
  local rel
  local tasks
  local n=0
  local any=0

  next_steps_buf+=$'\n'"## $heading"$'\n\n'"$intro"$'\n'

  # Pass 2 is only the "Optional" rows, so they sort after hard "After" rows.
  local pass=1
  local passes=1
  if [[ "$which" == 'after' ]]; then
    passes=2
  fi

  for ((pass = 1; pass <= passes; pass++)); do
  for rel in "${next_steps_order[@]}"; do
    if [[ "$which" == 'after' ]]; then
      if [[ "${next_steps_lane[$rel]}" == 'sequential' ]]; then
        tasks="${next_steps_after[$rel]:-}"
      else
        tasks=''
      fi
      if [[ "$pass" -eq 1 && "$tasks" == *Optional* ]]; then
        tasks=''
      fi
      if [[ "$pass" -eq 2 && "$tasks" != *Optional* ]]; then
        tasks=''
      fi
    elif [[ "${next_steps_lane[$rel]}" == "$which" ]]; then
      tasks="${next_steps_now[$rel]:-}"
    else
      tasks=''
    fi

    if [[ -z "$tasks" ]]; then
      continue
    fi

    any=1
    n=$((n + 1))
    next_steps_buf+=$'\n'"### ${n}. \`${rel}\`"$'\n\n'
    next_steps_buf+="Status: ${next_steps_status[$rel]}"$'\n\n'
    next_steps_buf+="$tasks"$'\n'
  done
  done

  if [[ "$any" -eq 0 ]]; then
    next_steps_buf+=$'\n'"_None this hour._"$'\n'
  fi
}

##
# Rewrite the agent list. Never writes NEXT_STEPS.md.
#
# Calling-scope overrides (optional):
# @var next_steps_changelog_dir
# @var next_steps_agent_path
#
f_doc_next_steps_write() {
  local changelog_dir="${next_steps_changelog_dir:-changelog}"
  local agent_path="${next_steps_agent_path:-NEXT_STEPS.agent.md}"
  local rel
  local path
  local status
  local plain
  local line
  local low
  local nopen
  local now
  local after
  local generated
  local tmp
  local -A next_steps_lane=()
  local -A next_steps_status=()
  local -A next_steps_now=()
  local -A next_steps_after=()
  local next_steps_order=()
  local next_steps_buf=''
  local any=0

  if [[ "$(basename "$agent_path")" == 'NEXT_STEPS.md' ]]; then
    echo >&2
    echo "Error in f_doc_next_steps_write() - $BASH_SOURCE line $LINENO: refusing to write the human approval file." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ ! -d "$changelog_dir" ]]; then
    echo >&2
    echo "Error in f_doc_next_steps_write() - $BASH_SOURCE line $LINENO: missing changelog dir: $changelog_dir" >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  while IFS= read -r rel; do
    case "$rel" in
      README.md|*/README.md) continue ;;
    esac

    path="$changelog_dir/$rel"
    status="$(sed -n 's/^| \*\*Status\*\* | //p' "$path" | head -n 1)"
    status="${status%|}"
    status="${status#"${status%%[![:space:]]*}"}"
    status="${status%"${status##*[![:space:]]}"}"
    plain="${status//\*\*/}"

    nopen=0
    now=''
    after=''
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      nopen=$((nopen + 1))
      f_doc_next_steps_task_bucket "$line"
      if [[ "$task_bucket" == 'drop' ]]; then
        continue
      fi
      if [[ "$task_bucket" == 'after' ]]; then
        after+="$line"$'\n'
      else
        now+="$line"$'\n'
      fi
    done < <(grep -E '^[[:space:]]*- \[ \]' "$path" || true)

    f_doc_next_steps_lane "$plain" "$nopen"
    if [[ "$lane" == 'skip' ]]; then
      continue
    fi

    if [[ ${#plain} -gt 160 ]]; then
      plain="${plain:0:160}"
      plain="${plain% *}..."
    fi

    next_steps_order+=("$changelog_dir/$rel")
    next_steps_lane["$changelog_dir/$rel"]="$lane"
    next_steps_status["$changelog_dir/$rel"]="$plain"
    next_steps_now["$changelog_dir/$rel"]="$now"
    next_steps_after["$changelog_dir/$rel"]="$after"
  done < <(cd "$changelog_dir" && find . -name '*.md' -printf '%P\n' | sort)

  generated="$(date -I)"
  next_steps_buf="# NEXT_STEPS.agent

Generated ${generated} by \`asc/doc/next_steps.sh\`. Project-docroot hook data, rung 4, same lookup model as \`env.yml\`. Dry-run returns this path; the file is not sourced.

\`\`\`sh
next_steps_actor=agent
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor' -r
\`\`\`

Discussion is \`NEXT_STEPS.md\`. Go-ahead is the gates file \`hook_ms\` returns (\`hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r\`). A row here may start only when that file sets its \`go\` to yes. This entry point writes neither file.

Lanes: **sequential** waits on the row above; **parallel** does not wait on the sequential chain or on other parallel rows.
"

  f_doc_next_steps_emit_tasks 'Sequential' 'sequential' 'Start at row 1. Leave the next row until this one is done.'
  f_doc_next_steps_emit_tasks 'Sequential, after the row above' 'after' 'Same chain, later. An "After" or "Optional" line waits.'
  f_doc_next_steps_emit_tasks 'Parallel' 'parallel' 'Independent of the sequential chain. Still wait for approval in NEXT_STEPS.md.'

  next_steps_buf+=$'\n'"## Awaiting human approval"$'\n\n'
  next_steps_buf+="Open changelog notes that are not an implementation go-ahead. Discussion belongs in \`NEXT_STEPS.md\`."$'\n'
  any=0
  for rel in "${next_steps_order[@]}"; do
    if [[ "${next_steps_lane[$rel]}" != 'discuss' ]]; then
      continue
    fi
    any=1
    next_steps_buf+=$'\n'"- \`${rel}\` — ${next_steps_status[$rel]}"
  done
  if [[ "$any" -eq 0 ]]; then
    next_steps_buf+=$'\n'"_None._"
  fi
  next_steps_buf+=$'\n'

  next_steps_buf+=$'\n'"## Do not re-run"$'\n\n'
  next_steps_buf+="Status is implemented, done, shipped, or skipped. Open checkboxes in these files are historical."$'\n'
  any=0
  for rel in "${next_steps_order[@]}"; do
    if [[ "${next_steps_lane[$rel]}" != 'held' ]]; then
      continue
    fi
    any=1
    next_steps_buf+=$'\n'"- \`${rel}\`"
  done
  if [[ "$any" -eq 0 ]]; then
    next_steps_buf+=$'\n'"_None._"
  fi
  next_steps_buf+=$'\n'

  tmp="$(mktemp)"
  printf '%s\n' "$next_steps_buf" > "$tmp"
  mv "$tmp" "$agent_path"

  if [[ "$agent_path" == 'NEXT_STEPS.agent.md' || "$agent_path" == './NEXT_STEPS.agent.md' ]]; then
    f_doc_next_steps_confirm_rung || return $?
  fi
}

##
# Dry-run the two docroot paths and check which file wins.
#
f_doc_next_steps_confirm_rung() {
  local next_steps_actor='agent'

  if [[ ! -f 'NEXT_STEPS.agent.md' || ! -f 'NEXT_STEPS.md' ]]; then
    echo >&2
    echo "Error in f_doc_next_steps_confirm_rung() - $BASH_SOURCE line $LINENO: both docroot files must exist." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  rm -f data/asc/cache/hook/*a-NEXT_STEPS*
  hook_dry_run_matches=''
  most_specific_match=''
  hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor' -r
  if [[ "$most_specific_match" != 'NEXT_STEPS.agent.md' ]]; then
    echo >&2
    echo "Error in f_doc_next_steps_confirm_rung() - $BASH_SOURCE line $LINENO: agent variant winner is '$most_specific_match'." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi

  rm -f data/asc/cache/hook/*a-NEXT_STEPS*
  hook_dry_run_matches=''
  most_specific_match=''
  hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -r
  if [[ "$most_specific_match" != 'NEXT_STEPS.md' ]]; then
    echo >&2
    echo "Error in f_doc_next_steps_confirm_rung() - $BASH_SOURCE line $LINENO: human winner is '$most_specific_match'." >&2
    echo "Aborting (1)." >&2
    echo >&2
    return 1
  fi
}

# Entry point (skipped when this file is sourced).
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_doc_next_steps_write
fi
