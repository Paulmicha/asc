#!/usr/bin/env bash

##
# Crontab backend utilities.
#
# Optionally sourced during core ASC bootstrap for cron actions.
#
# Convention : function names are prefixed by "f".
#

##
# Returns 0 if $1 is a whitelisted schedule preset token.
#
f_crontab_preset_is_valid() {
  local p_preset="$1"

  local n
  local unit
  local hh
  local mm

  # Whitelisted N values for every-* / Nx-per-* presets.
  local cron_preset_ns='1 2 3 4 5 10 15 20 30 45'

  if [[ "$p_preset" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    case " $cron_preset_ns " in *" $n "*) return 0;; esac
    return 1
  fi

  if [[ "$p_preset" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    if [[ "$hh" -ge 0 && "$hh" -le 23 ]]; then
      return 0
    fi
    return 1
  fi

  if [[ "$p_preset" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case " $cron_preset_ns " in *" $n "*) ;; *) return 1;; esac

    # Cron ticks once a minute. Only intervals that divide that minute can run
    # at the advertised count.
    if [[ "$unit" == m ]] && [[ $((60 % n)) -ne 0 ]]; then
      return 1
    fi

    return 0
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
f_crontab_preset_compile() {
  local p_preset_token="$1"
  local p_entry="${2:-}"
  local p_idx="${3:-0}"
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

  if [[ "$p_preset_token" =~ ^every-([0-9]+)([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    phase=$((p_idx % n))
    case "$unit" in
      m)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules_arr+=("*/${n} * * * *")
        else
          # Stagger same-cadence peers within the every-N window when possible.
          phase=$((p_idx % n))
          cron_schedules_arr+=("${phase}-59/${n} * * * *")
        fi
        ;;
      h)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules_arr+=("0 */${n} * * *")
        else
          phase=$((p_idx % 60))
          cron_schedules_arr+=("${phase} */${n} * * *")
        fi
        ;;
      d)
        if [[ $p_idx -eq 0 ]]; then
          cron_schedules_arr+=("0 0 */${n} * *")
        else
          phase=$((p_idx % 24))
          cron_schedules_arr+=("0 ${phase} */${n} * *")
        fi
        ;;
    esac
    return 0
  fi

  if [[ "$p_preset_token" =~ ^at-([0-9]{2})h(00|15|30|45)$ ]]; then
    hh="${BASH_REMATCH[1]}"
    mm="${BASH_REMATCH[2]}"
    # Strip leading zeros for cron hour (keep numeric).
    hh=$((10#$hh))
    mm=$((10#$mm))
    cron_schedules_arr+=("${mm} ${hh} * * *")
    return 0
  fi

  if [[ "$p_preset_token" =~ ^([0-9]+)x-per-([mhd])$ ]]; then
    n="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
    case "$unit" in
      m)
        if [[ "$n" -eq 0 ]] || [[ $((60 % n)) -ne 0 ]]; then
          return 1
        fi

        # Seconds between runs. The host crontab still ticks once a minute.
        cron_subminute=$((60 / n))
        cron_schedules_arr+=("* * * * *")
        ;;

      h)
        span=$((60 / n))
        if [[ $span -lt 1 ]]; then
          span=1
        fi
        phase=$((p_idx % span))
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
        phase=$((p_idx % span))
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
f_crontab_scalar() {
  local p_value="$1"
  local p_output_var_name="${2:-cron_scalar}"

  p_value="${p_value#\"}"
  p_value="${p_value%\"}"
  p_value="${p_value#\'}"
  p_value="${p_value%\'}"
  p_value="${p_value%"${p_value##*[![:space:]]}"}"
  p_value="${p_value#"${p_value%%[![:space:]]*}"}"

  printf -v "$p_output_var_name" '%s' "$p_value"
}

##
# Parse `{action}.{preset}` from a cron.yml basename (no path, no suffix).
#
# Outputs : cron_action, cron_preset
#
f_crontab_parse_filename() {
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
    if f_crontab_preset_is_valid "$preset_cand"; then
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
f_crontab_load_base_templates() {
  local base_file='scripts/asc/contrib/asc/crontab/base_settings.cron.yml'
  local k
  local parsed=''

  unset cron_tpl_defaults_enabled cron_tpl_defaults_wrap cron_tpl_defaults_lock \
    cron_tpl_defaults_user cron_tpl_scheduled_job_retry_max \
    cron_tpl_scheduled_job_retry_delay

  if [[ ! -f "$base_file" ]]; then
    echo >&2 "Error: missing $base_file"
    return 1
  fi

  # shellcheck disable=SC2034
  f_yaml_parse "$base_file" 'cronbase_' 'parsed' || return $?
  eval "$parsed"

  f_crontab_scalar "${cronbase_includes_defaults_enabled:-true}" 'cron_tpl_defaults_enabled'
  f_crontab_scalar "${cronbase_includes_defaults_wrap:-lt}" 'cron_tpl_defaults_wrap'
  f_crontab_scalar "${cronbase_includes_defaults_lock:-skip}" 'cron_tpl_defaults_lock'
  f_crontab_scalar "${cronbase_includes_defaults_user:-}" 'cron_tpl_defaults_user'
  f_crontab_scalar "${cronbase_includes_scheduled_job_retry_max:-0}" 'cron_tpl_scheduled_job_retry_max'
  f_crontab_scalar "${cronbase_includes_scheduled_job_retry_delay:-10s}" 'cron_tpl_scheduled_job_retry_delay'
}

##
# Apply includes: crontab.defaults | crontab.scheduled_job onto dict vars.
#
f_crontab_apply_includes() {
  local inc
  f_crontab_scalar "${1:-}" 'inc'

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
# Discover enabled *.cron.yml jobs, validate, then replace generated scripts.
#
# Mirrors f_remote_instances_setup() lifecycle (files only; host sync separate).
#
f_crontab_settings_setup() (
  local f
  local base
  local subject
  local entry
  local files_arr=()
  local extension ext_path extension_namespace subjects_var subject_dir
  local staging preserve_staging=0 swap_in_progress=0
  local peer_idx
  local parsed=''
  declare -A peer_seen_dict=()
  declare -A entry_files=()

  f_crontab_load_base_templates || return 1

  # Each namespace's enabled subjects are its active directories.
  for extension in $ASC_EXTENSIONS; do
    ext_path=''
    f_asc_extension_path "$extension"
    ext_path="$ext_path/$extension"
    f_asc_extension_namespace "$extension" 'extension_namespace'
    subjects_var="${extension_namespace}_SUBJECTS"
    for subject in ${!subjects_var}; do
      subject_dir="$ext_path/$subject"
      for f in "$subject_dir"/*.cron.yml; do
        [[ -f "$f" ]] && files_arr+=("$f")
      done
    done
  done

  # Core subjects are also active, independent of extensions.
  for subject in $ASC_SUBJECTS; do
    for f in "asc/$subject"/*.cron.yml; do
      [[ -f "$f" ]] && files_arr+=("$f")
    done
  done

  for f in "${files_arr[@]}"; do
    base="$(basename "$f" .cron.yml)"
    if ! f_crontab_parse_filename "$base"; then
      echo >&2 "Error in f_crontab_settings_setup(): invalid cron filename (bad preset): $f"
      return 1
    fi
    subject="$(basename "$(dirname "$f")")"
    entry="${subject}-${cron_action}"
    entry="${entry//_/-}"
    if [[ -n "${entry_files[$entry]:-}" ]]; then
      echo >&2 "Error in f_crontab_settings_setup(): duplicate cron entry '$entry': ${entry_files[$entry]} and $f"
      return 1
    fi
    entry_files[$entry]="$f"
  done

  mkdir -p data/asc || return 1
  if ! mkdir data/asc/.crontab-refresh.lock 2>/dev/null; then
    echo "Error in f_crontab_settings_setup(): refresh lock exists; check for another refresh or interrupted recovery." >&2
    return 1
  fi
  staging="$(mktemp -d data/asc/.crontab-staging.XXXXXXXX)" || { rmdir data/asc/.crontab-refresh.lock; return 1; }
  trap 'if [[ $swap_in_progress -eq 1 || $preserve_staging -ne 0 ]]; then echo "Error in f_crontab_settings_setup(): inspect preserved files in $staging before removing data/asc/.crontab-refresh.lock." >&2; else rm -rf "$staging"; rmdir data/asc/.crontab-refresh.lock; fi' EXIT
  mkdir -p "$staging/cron" || return 1

  cat > "$staging/cron.sh" <<'EOF' || return $?
#!/usr/bin/env bash

##
# Generated crontab definitions aggregate.
#
# Rewritten by f_crontab_settings_setup() during instance (re)init.
# @see scripts/asc/contrib/asc/crontab/cron/cron.opt-inc.sh
#

ASC_CRON_ENTRIES=''
EOF

  for f in "${files_arr[@]}"; do
    base="$(basename "$f" .cron.yml)"
    subject="$(basename "$(dirname "$f")")"
    if ! f_crontab_parse_filename "$base"; then
      echo >&2 "Error: cannot parse cron filename: $f"
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
    parsed=''
    f_yaml_parse "$f" 'croncj_' 'parsed' || return 1
    eval "$parsed"

    f_crontab_apply_includes "${croncj_includes:-}"

    local enabled wrap lock user retry_max retry_delay args make_task run_id
    local monitor_mark_stale monitor_reclaim_lock monitor_outer_retry

    f_crontab_scalar "${croncj_enabled:-$cron_def_enabled}" 'enabled'
    f_crontab_scalar "${croncj_wrap:-$cron_def_wrap}" 'wrap'
    f_crontab_scalar "${croncj_lock:-$cron_def_lock}" 'lock'
    f_crontab_scalar "${croncj_user:-$cron_def_user}" 'user'
    f_crontab_scalar "${croncj_retry_max:-$cron_def_retry_max}" 'retry_max'
    f_crontab_scalar "${croncj_retry_delay:-$cron_def_retry_delay}" 'retry_delay'
    f_crontab_scalar "${croncj_args:-}" 'args'
    f_crontab_scalar "${croncj_make:-}" 'make_task'
    f_crontab_scalar "${croncj_run:-}" 'run_id'
    f_crontab_scalar "${croncj_monitor_mark_stale:-}" 'monitor_mark_stale'
    f_crontab_scalar "${croncj_monitor_reclaim_lock:-}" 'monitor_reclaim_lock'
    f_crontab_scalar "${croncj_monitor_outer_retry:-}" 'monitor_outer_retry'

    if ! f_crontab_preset_compile "$cron_preset" "$entry" "$peer_idx"; then
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

    local out="$staging/cron/${entry}.sh"

    cat > "$out" <<EOF || return $?
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

    echo "ASC_CRON_ENTRIES+=\"${entry} \"" >> "$staging/cron.sh" || return $?
  done

  # Keep the old generation until both new paths have been installed. All
  # paths are on the same filesystem so the renames do not copy job content.
  local had_index=0 had_jobs=0 installed_jobs=0 install_status=0
  swap_in_progress=1

  if [[ -e data/asc/crontab.sh || -L data/asc/crontab.sh ]]; then
    if ! mv data/asc/crontab.sh "$staging/previous-cron.sh"; then
      swap_in_progress=0
      return 1
    fi
    had_index=1
  fi

  if [[ -e data/asc/crontab || -L data/asc/crontab ]]; then
    if mv data/asc/crontab "$staging/previous-cron"; then
      had_jobs=1
    else
      install_status=$?
    fi
  fi

  if [[ $install_status -eq 0 ]]; then
    if mv "$staging/cron" data/asc/crontab; then
      installed_jobs=1
    else
      install_status=$?
    fi
  fi

  if [[ $install_status -eq 0 ]]; then
    mv "$staging/cron.sh" data/asc/crontab.sh || install_status=$?
  fi

  if [[ $install_status -ne 0 ]]; then
    if [[ $installed_jobs -eq 1 ]]; then
      rm -rf data/asc/crontab || preserve_staging=1
    fi
    if [[ $had_jobs -eq 1 && $preserve_staging -eq 0 ]]; then
      mv "$staging/previous-cron" data/asc/crontab || preserve_staging=1
    fi
    if [[ $had_index -eq 1 ]]; then
      mv "$staging/previous-cron.sh" data/asc/crontab.sh || preserve_staging=1
    fi
    if [[ $preserve_staging -ne 0 ]]; then
      echo "Error in f_crontab_settings_setup(): restore failed; previous files remain in '$staging'." >&2
    fi
    swap_in_progress=0
    return "$install_status"
  fi

  swap_in_progress=0
  echo "Crontab definitions written under data/asc/crontab/ (${#files_arr[@]} entries)."
)

##
# Load one generated cron entry script into the environment.
#
f_crontab_entry_load() {
  local p_entry="$1"
  local f="data/asc/crontab/${p_entry}.sh"

  if [[ ! -f "$f" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  . "$f"
}

##
# Project docstring root for crontab markers.
#
# @param 1 [optional] String : output var name (default: cron_project_marker).
#
f_crontab_project_marker() {
  local p_output_var_name="${1:-cron_project_marker}"
  printf -v "$p_output_var_name" '%s' "${PROJECT_DOCROOT:-$PWD}"
}

##
# Ensure crontab binary exists.
#
f_crontab_require_crontab() {
  if ! command -v crontab >/dev/null 2>&1; then
    echo >&2 "Error: crontab program not found on this host."
    return 1
  fi
}

##
# Read the current user crontab.
#
# A missing crontab is an empty result. Any other read failure is returned so
# a later write cannot replace the host crontab.
#
# @return
#   0 : crontab printed, or no crontab exists
#   1 : temporary file could not be created
#   $? : crontab -l status when the read failed
#
f_crontab_list() {
  local status=0
  local errfile

  errfile="$(mktemp)" || return 1
  crontab -l 2>"$errfile"
  status=$?

  if [[ "$status" -ne 0 ]]; then
    if grep -q 'no crontab for ' "$errfile"; then
      rm -f "$errfile"

      return 0
    fi

    echo >&2
    echo "Error in f_crontab_list() - $BASH_SOURCE line $LINENO: failed to read the user crontab." >&2
    cat "$errfile" >&2
    echo "-> Aborting ($status)." >&2
    echo >&2
    rm -f "$errfile"

    return "$status"
  fi

  rm -f "$errfile"
}

##
# Rewrite managed ASC-CRON block for this project.
#
# @param 1 String : block body (lines without markers); empty removes block.
#
f_crontab_write_block() {
  local body="$1"
  local marker
  local begin
  local end
  local tmp
  local current
  local filtered
  local list_status=0

  f_crontab_require_crontab || return 1
  f_crontab_project_marker 'marker'

  begin="# ASC-CRON-BEGIN ${marker}"
  end="# ASC-CRON-END ${marker}"
  tmp="$(mktemp)" || return 1
  current="$(f_crontab_list)" || list_status=$?

  if [[ "$list_status" -ne 0 ]]; then
    rm -f "$tmp"

    return "$list_status"
  fi

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

  local status=0
  crontab "$tmp" || status=$?
  rm -f "$tmp"
  return "$status"
}

##
# Build crontab lines for one loaded entry (ASC_CRON_* must be set).
#
f_crontab_entry_lines() {
  local sched
  local marker
  local IFS=';'
  local lines_arr=()

  if [[ "${ASC_CRON_ENABLED}" != 'true' ]]; then
    return 0
  fi

  f_crontab_project_marker 'marker'

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
f_crontab_sync() {
  local f
  local body=''
  local chunk

  f_crontab_require_crontab || return 1

  if [[ ! -d data/asc/crontab ]]; then
    echo >&2 "No generated cron definitions. Run make reinit first."
    return 1
  fi

  body=''
  for f in data/asc/crontab/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${ASC_CRON_ENABLED}" == 'true' ]] || continue
    chunk="$(f_crontab_entry_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'
'
  done

  f_crontab_write_block "$(printf '%s' "$body")" || return $?
  local marker
  f_crontab_project_marker 'marker'
  echo "Host crontab synced for ${marker}."
}

##
# Remove one entry's lines from managed block (keep others).
#
f_crontab_stop_entry() {
  local p_entry="${1#e:}"
  local f
  local body=''
  local chunk

  f_crontab_require_crontab || return 1

  for f in data/asc/crontab/*.sh; do
    [[ -f "$f" ]] || continue
    # shellcheck disable=SC1090
    . "$f"
    [[ "${ASC_CRON_ENABLED}" == 'true' ]] || continue
    [[ "$ASC_CRON_ENTRY" == "$p_entry" ]] && continue
    chunk="$(f_crontab_entry_lines)"
    [[ -n "$chunk" ]] && body+="${chunk}"$'\n'
  done

  f_crontab_write_block "$(printf '%s' "$body")" || return $?
  echo "Stopped cron host lines for '$p_entry'."
}

##
# Ensure one entry's lines are installed (full rewrite of enabled set including it).
#
f_crontab_start_entry() {
  local p_entry="${1#e:}"

  if ! f_crontab_entry_load "$p_entry"; then
    echo >&2 "Unknown cron entry: $p_entry"
    return 1
  fi

  f_crontab_sync || return $?
  echo "Started/synced cron including '$p_entry'."
}
