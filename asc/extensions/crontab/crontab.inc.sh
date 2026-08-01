#!/usr/bin/env bash

##
# Crontab extension utilities.
#
# Sourced during core ASC bootstrap via f_asc_extensions() when the crontab
# extension is enabled (not listed in .asc_extensions_ignore).
#
# Convention : function names are prefixed by "u".
#

##
# Returns 0 if $1 is a whitelisted schedule preset token.
#
f_cron_preset_is_valid() {
  local a_preset="$1"

  local n
  local unit
  local hh
  local mm

  # Whitelisted N values for every-* / Nx-per-* presets.
  local cron_preset_ns='1 2 3 4 5 10 15 20 30 45'

  if [[ "$a_preset" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case " $cron_preset_ns " in *" $n "*) return 0;; esac
    return 1
  fi

  if [[ "$a_preset" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    if [[ "$hh" -ge 0 && "$hh" -le 23 ]]; then
      return 0
    fi
    return 1
  fi

  if [[ "$a_preset" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case " $cron_preset_ns " in *" $n "*) return 0;; esac
    return 1
  fi

  return 1
}

##
# Compiles a preset into crontab schedule expression(s).
#
# Outputs in calling scope :
#   cron_schedules_arr — bash array of 5-field expressions (one or more)
#   cron_subminute — empty or seconds interval hint for run hook
#
# @param 1 String : preset token
# @param 2 [optional] String : make entry (for stable phase)
# @param 3 [optional] Number : index among peers sharing cadence (for spacing)
#
f_cron_preset_compile() {
  local a_preset_token="$1"
  local a_entry="${2:-}"
  local a_idx="${3:-0}"
  local n
  local unit
  local hh
  local mm
  local i
  local slot
  local phase
  local span

  cron_schedules_arr=()
  cron_subminute=''

  if [[ "$a_preset_token" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    phase=$((a_idx % n))
    case "$unit" in
      m)
        if [[ $a_idx -eq 0 ]]; then
          cron_schedules_arr+=("*/${n} * * * *")
        else
          # Stagger same-cadence peers within the every-N window when possible.
          phase=$((a_idx % n))
          cron_schedules_arr+=("${phase}-59/${n} * * * *")
        fi
        ;;
      h)
        if [[ $a_idx -eq 0 ]]; then
          cron_schedules_arr+=("0 */${n} * * *")
        else
          phase=$((a_idx % 60))
          cron_schedules_arr+=("${phase} */${n} * * *")
        fi
        ;;
      d)
        if [[ $a_idx -eq 0 ]]; then
          cron_schedules_arr+=("0 0 */${n} * *")
        else
          phase=$((a_idx % 24))
          cron_schedules_arr+=("0 ${phase} */${n} * *")
        fi
        ;;
    esac
    return 0
  fi

  if [[ "$a_preset_token" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    mm="${BASH_REMATCH[2]}"
    # Strip leading zeros for cron hour (keep numeric).
    hh=$((10#$hh))
    mm=$((10#$mm))
    cron_schedules_arr+=("${mm} ${hh} * * *")
    return 0
  fi

  if [[ "$a_preset_token" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case "$unit" in
      m)
        cron_subminute=$((60 / n))
        if [[ $cron_subminute -lt 1 ]]; then
          cron_subminute=1
        fi
        # Host ticks every minute; run hook handles second slots.
        cron_schedules_arr+=("* * * * *")
        ;;
      h)
        span=$((60 / n))
        if [[ $span -lt 1 ]]; then
          span=1
        fi
        phase=$((a_idx % span))
        for ((i = 0; i < n; i++)); do
          slot=$((i * span + phase))
          if [[ $slot -ge 60 ]]; then
            slot=$((slot % 60))
          fi
          cron_schedules_arr+=("${slot} * * * *")
        done
        ;;
      d)
        span=$((24 / n))
        if [[ $span -lt 1 ]]; then
          span=1
        fi
        phase=$((a_idx % span))
        for ((i = 0; i < n; i++)); do
          slot=$((i * span + phase))
          if [[ $slot -ge 24 ]]; then
            slot=$((slot % 24))
          fi
          cron_schedules_arr+=("0 ${slot} * * *")
        done
        ;;
    esac
    return 0
  fi

  return 1
}

##
# Strip yaml scalar artifacts (quotes / trailing spaces / array form).
#
# @param 1 String : scalar value.
# @param 2 [optional] String : output var name (default: cron_scalar).
#
f_cron_scalar() {
  local a_value="$1"
  local a_output_var_name="${2:-cron_scalar}"

  a_value="${a_value#\"}"
  a_value="${a_value%\"}"
  a_value="${a_value#\'}"
  a_value="${a_value%\'}"
  a_value="${a_value%"${a_value##*[![:space:]]}"}"
  a_value="${a_value#"${a_value%%[![:space:]]*}"}"

  printf -v "$a_output_var_name" '%s' "$a_value"
}

##
# Parse `{action}.{preset}` from a crontab.yml basename (no path, no suffix).
#
# Outputs : cron_action, cron_preset
#
f_cron_parse_filename() {
  local base="$1"
  local preset_cand
  local action_cand

  cron_action=''
  cron_preset=''

  # Prefer longest valid preset suffix after the last-but matching patterns.
  if [[ "$base" =~ ^(.+)\.(every-[0-9]+[mhd])$ ]] \
    || [[ "$base" =~ ^(.+)\.(at-[0-9]{2}h(00|15|30|45))$ ]] \
    || [[ "$base" =~ ^(.+)\.([0-9]+x-per-[mhd])$ ]]; then
    action_cand="${BASH_REMATCH[1]}"
    preset_cand="${BASH_REMATCH[2]}"
    if f_cron_preset_is_valid "$preset_cand"; then
      cron_action="$action_cand"
      cron_preset="$preset_cand"
      return 0
    fi
  fi

  return 1
}

##
# Load base_settings templates into calling scope as associative keys.
#
# Sets :
#   cron_tpl_<name>_<field> scalars for defaults / scheduled_job
#
f_cron_load_base_templates() {
  local base_file='asc/extensions/crontab/base_settings.crontab.yml'
  local k

  unset cron_tpl_defaults_enabled cron_tpl_defaults_wrap cron_tpl_defaults_lock \
    cron_tpl_defaults_user cron_tpl_scheduled_job_retry_max \
    cron_tpl_scheduled_job_retry_delay

  if [[ ! -f "$base_file" ]]; then
    echo >&2 "Error: missing $base_file"
    return 1
  fi

  # shellcheck disable=SC2034
  eval "$(f_yaml_parse "$base_file" 'cronbase_')"

  f_cron_scalar "${cronbase_includes_defaults_enabled:-true}" 'cron_tpl_defaults_enabled'
  f_cron_scalar "${cronbase_includes_defaults_wrap:-lt}" 'cron_tpl_defaults_wrap'
  f_cron_scalar "${cronbase_includes_defaults_lock:-skip}" 'cron_tpl_defaults_lock'
  f_cron_scalar "${cronbase_includes_defaults_user:-}" 'cron_tpl_defaults_user'
  f_cron_scalar "${cronbase_includes_scheduled_job_retry_max:-0}" 'cron_tpl_scheduled_job_retry_max'
  f_cron_scalar "${cronbase_includes_scheduled_job_retry_delay:-10s}" 'cron_tpl_scheduled_job_retry_delay'
}

##
# Apply includes: crontab.defaults | crontab.scheduled_job onto dict vars.
#
f_cron_apply_includes() {
  local inc
  f_cron_scalar "${1:-}" 'inc'

  cron_def_enabled="$cron_tpl_defaults_enabled"
  cron_def_wrap="$cron_tpl_defaults_wrap"
  cron_def_lock="$cron_tpl_defaults_lock"
  cron_def_user="$cron_tpl_defaults_user"
  cron_def_retry_max='0'
  cron_def_retry_delay='10s'

  case "$inc" in
    crontab.scheduled_job|scheduled_job)
      cron_def_retry_max="$cron_tpl_scheduled_job_retry_max"
      cron_def_retry_delay="$cron_tpl_scheduled_job_retry_delay"
      ;;
    crontab.defaults|defaults|'')
      ;;
  esac
}

##
# Purge generated cron scripts.
#
f_cron_purge_generated() {
  rm -rf data/asc/cron
  rm -f data/asc/cron.sh
  mkdir -p data/asc/cron
}

##
# Discover *.crontab.yml, merge, compile presets, write generated scripts.
#
# Mirrors f_remote_instances_setup() lifecycle (files only; host sync separate).
#
f_cron_settings_setup() {
  local f
  local base
  local subject
  local entry
  local files_arr=()
  local peer_idx
  declare -A peer_count_dict=()
  declare -A peer_seen_dict=()

  f_cron_load_base_templates || return 1
  f_cron_purge_generated

  shopt -s nullglob globstar
  for f in scripts/asc/extend/**/*.crontab.yml asc/extensions/**/*.crontab.yml; do
    case "$f" in
      */base_settings.crontab.yml) continue;;
    esac
    if [[ -f "$f" ]]; then
      files_arr+=("$f")
    fi
  done
  shopt -u nullglob globstar

  # First pass: count peers per preset class for spacing.
  for f in "${files_arr[@]}"; do
    base="$(basename "$f" .crontab.yml)"
    if ! f_cron_parse_filename "$base"; then
      echo >&2 "Error: invalid crontab filename (bad preset): $f"
      return 1
    fi
    peer_count_dict["$cron_preset"]=$(( ${peer_count_dict[$cron_preset]:-0} + 1 ))
  done

  cat > data/asc/cron.sh <<'EOF'
#!/usr/bin/env bash

##
# Generated crontab definitions aggregate.
#
# Rewritten by f_cron_settings_setup() during instance (re)init.
# @see asc/extensions/crontab/crontab.inc.sh
#

ASC_CRON_ENTRIES=''
EOF

  for f in "${files_arr[@]}"; do
    base="$(basename "$f" .crontab.yml)"
    subject="$(basename "$(dirname "$f")")"
    # scripts/asc/extend/<subject>/… — subject is directory name.
    # Skip when file lives oddly under extensions/crontab without action sibling.
    if ! f_cron_parse_filename "$base"; then
      echo >&2 "Error: cannot parse crontab filename: $f"
      return 1
    fi

    entry="${subject}-${cron_action}"
    # Sanitize like make tasks (underscores → already hyphenated subjects).
    entry="${entry//_/-}"

    peer_idx=${peer_seen_dict[$cron_preset]:-0}
    peer_seen_dict[$cron_preset]=$((peer_idx + 1))

    unset croncj_includes croncj_enabled croncj_args croncj_lock croncj_wrap \
      croncj_user croncj_retry_max croncj_retry_delay croncj_make croncj_run \
      croncj_monitor_mark_stale croncj_monitor_reclaim_lock \
      croncj_monitor_outer_retry
    eval "$(f_yaml_parse "$f" 'croncj_')"

    f_cron_apply_includes "${croncj_includes:-}"

    local enabled wrap lock user retry_max retry_delay args make_task run_id
    local monitor_mark_stale monitor_reclaim_lock monitor_outer_retry

    f_cron_scalar "${croncj_enabled:-$cron_def_enabled}" 'enabled'
    f_cron_scalar "${croncj_wrap:-$cron_def_wrap}" 'wrap'
    f_cron_scalar "${croncj_lock:-$cron_def_lock}" 'lock'
    f_cron_scalar "${croncj_user:-$cron_def_user}" 'user'
    f_cron_scalar "${croncj_retry_max:-$cron_def_retry_max}" 'retry_max'
    f_cron_scalar "${croncj_retry_delay:-$cron_def_retry_delay}" 'retry_delay'
    f_cron_scalar "${croncj_args:-}" 'args'
    f_cron_scalar "${croncj_make:-}" 'make_task'
    f_cron_scalar "${croncj_run:-}" 'run_id'
    f_cron_scalar "${croncj_monitor_mark_stale:-}" 'monitor_mark_stale'
    f_cron_scalar "${croncj_monitor_reclaim_lock:-}" 'monitor_reclaim_lock'
    f_cron_scalar "${croncj_monitor_outer_retry:-}" 'monitor_outer_retry'

    if ! f_cron_preset_compile "$cron_preset" "$entry" "$peer_idx"; then
      echo >&2 "Error: cannot compile preset '$cron_preset' for $f"
      return 1
    fi

    local schedule_joined=''
    local s
    for s in "${cron_schedules_arr[@]}"; do
      schedule_joined+="${s};"
    done
    schedule_joined="${schedule_joined%;}"

    local cmd
    case "$wrap" in
      lt)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make lt e:${entry}"
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      thread)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make thread-wrap e:${entry}"
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      direct)
        if [[ -n "$make_task" ]]; then
          cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make ${make_task}"
        else
          cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make ${entry}"
        fi
        [[ -n "$args" ]] && cmd+=" $args"
        ;;
      *)
        cmd="cd ${PROJECT_DOCROOT:-$(pwd)} && make lt e:${entry}"
        ;;
    esac

    local out="data/asc/cron/${entry}.sh"

    cat > "$out" <<EOF
#!/usr/bin/env bash
# Generated from ${f} — do not edit.
export ASC_CRON_ENTRY='${entry}'
export ASC_CRON_PRESET='${cron_preset}'
export ASC_CRON_SOURCE='${f}'
export ASC_CRON_ENABLED='${enabled}'
export ASC_CRON_SCHEDULE='${schedule_joined}'
export ASC_CRON_SUBMINUTE='${cron_subminute}'
export ASC_CRON_WRAP='${wrap}'
export ASC_CRON_LOCK='${lock}'
export ASC_CRON_USER='${user}'
export ASC_CRON_RETRY_MAX='${retry_max}'
export ASC_CRON_RETRY_DELAY='${retry_delay}'
export ASC_CRON_ARGS='${args}'
export ASC_CRON_MAKE='${make_task}'
export ASC_CRON_RUN='${run_id}'
export ASC_CRON_MONITOR_MARK_STALE='${monitor_mark_stale}'
export ASC_CRON_MONITOR_RECLAIM_LOCK='${monitor_reclaim_lock}'
export ASC_CRON_MONITOR_OUTER_RETRY='${monitor_outer_retry}'
export ASC_CRON_CMD='${cmd}'
EOF

    echo "ASC_CRON_ENTRIES+=\"${entry} \"" >> data/asc/cron.sh
  done

  echo "Crontab definitions written under data/asc/cron/ (${#files_arr[@]} entries)."
}

##
# Load one generated cron entry script into the environment.
#
f_cron_entry_load() {
  local a_entry="$1"
  local f="data/asc/cron/${a_entry}.sh"

  if [[ ! -f "$f" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$f"
}

##
# Human duration (10s / 2m) → seconds.
#
f_cron_delay_seconds() {
  local a_duration="$1"

  if [[ "$a_duration" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$a_duration" =~ ^([0-9]+)m$ ]]; then
    echo $((BASH_REMATCH[1] * 60))
  elif [[ "$a_duration" =~ ^([0-9]+)h$ ]]; then
    echo $((BASH_REMATCH[1] * 3600))
  elif [[ "$a_duration" =~ ^[0-9]+$ ]]; then
    echo "$a_duration"
  else
    echo 10
  fi
}

##
# Project docstring root for crontab markers.
#
# @param 1 [optional] String : output var name (default: cron_project_marker).
#
f_cron_project_marker() {
  local a_output_var_name="${1:-cron_project_marker}"
  printf -v "$a_output_var_name" '%s' "${PROJECT_DOCROOT:-$PWD}"
}

##
# Ensure crontab binary exists.
#
f_cron_require_crontab() {
  if ! command -v crontab >/dev/null 2>&1; then
    echo >&2 "Error: crontab program not found on this host."
    return 1
  fi
}

##
# Read current user crontab or empty.
#
f_cron_crontab_list() {
  crontab -l 2>/dev/null || true
}

##
# Rewrite managed ASC-CRON block for this project.
#
# @param 1 String : block body (lines without markers); empty removes block.
#
f_cron_crontab_write_block() {
  local body="$1"
  local marker
  local begin
  local end
  local tmp
  local current
  local filtered

  f_cron_require_crontab || return 1
  f_cron_project_marker 'marker'

  begin="# ASC-CRON-BEGIN ${marker}"
  end="# ASC-CRON-END ${marker}"
  tmp="$(mktemp)"
  current="$(f_cron_crontab_list)"

  filtered="$(printf '%s\n' "$current" | awk -v b="$begin" -v e="$end" '
    $0 == b {skip=1; next}
    $0 == e {skip=0; next}
    !skip {print}
  ')"

  {
    printf '%s\n' "$filtered"

    if [[ -n "$body" ]]; then
      printf '%s\n' "$begin"
      printf '%s\n' "$body"
      printf '%s\n' "$end"
    fi
  } | sed '/^$/N;/^\n$/D' > "$tmp"

  crontab "$tmp"
  rm -f "$tmp"
}

##
# Build crontab lines for one loaded entry (ASC_CRON_* must be set).
#
f_cron_entry_crontab_lines() {
  local sched
  local marker
  local IFS=';'
  local lines_arr=()

  if [[ "${ASC_CRON_ENABLED}" != 'true' ]]; then
    return 0
  fi

  f_cron_project_marker 'marker'

  for sched in ${ASC_CRON_SCHEDULE}; do
    [[ -z "$sched" ]] && continue
    lines_arr+=("${sched} cd ${marker} && make cron-run e:${ASC_CRON_ENTRY}")
  done

  printf '%s\n' "${lines_arr[@]}"
}

##
# Sync host crontab for all enabled generated entries.
#
# Optional arg e:<entry> is accepted for API symmetry; always rewrites the full
# enabled set (use cron-stop / cron-start for single-entry host edits).
#
f_cron_sync() {
  local f
  local body=''
  local chunk

  f_cron_require_crontab || return 1

  if [[ ! -d data/asc/cron ]]; then
    echo >&2 "No generated cron definitions. Run make reinit first."
    return 1
  fi

  body=''
  for f in data/asc/cron/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${ASC_CRON_ENABLED}" == 'true' ]] || continue
    chunk="$(f_cron_entry_crontab_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'
'
  done

  f_cron_crontab_write_block "$(printf '%s' "$body")"
  local marker
  f_cron_project_marker 'marker'
  echo "Host crontab synced for ${marker}."
}

##
# Remove one entry's lines from managed block (keep others).
#
f_cron_stop_entry() {
  local a_entry="${1#e:}"
  local f
  local body=''
  local chunk

  f_cron_require_crontab || return 1

  for f in data/asc/cron/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${ASC_CRON_ENABLED}" == 'true' ]] || continue
    [[ "$ASC_CRON_ENTRY" == "$a_entry" ]] && continue
    chunk="$(f_cron_entry_crontab_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'\n'
  done

  f_cron_crontab_write_block "$(printf '%s' "$body")"
  echo "Stopped cron host lines for '$a_entry'."
}

##
# Ensure one entry's lines are installed (full rewrite of enabled set including it).
#
f_cron_start_entry() {
  local a_entry="${1#e:}"

  if ! f_cron_entry_load "$a_entry"; then
    echo >&2 "Unknown cron entry: $a_entry"
    return 1
  fi

  f_cron_sync
  echo "Started/synced cron including '$a_entry'."
}
