#!/usr/bin/env bash

##
# Software provision helpers (manifest → status diff → apply).
#
# Lazy include: seeded into hook.${key}.sh before host/provision.hook.sh (1a),
# and/or loaded via software/software/software.opt-inc.sh for software-* actions.
#
# @see asc/extensions/software/host/provision.hook.sh
# @see asc/utilities/hook.sh (f_hook_opt_inc_append_candidates)
# @see changelog/2026/07/16-asc-include-splitting-hook-mapped-deps.md
#
# Convention : function names are prefixed by "u".
#

##
# Strip surrounding quotes left by bash-yaml scalars.
#
# @param 1 String : scalar value.
# @param 2 [optional] String : output var name (default: software_scalar).
#
f_software_scalar() {
  local a_val="$1"
  local a_output_var_name="${2:-software_scalar}"

  a_val="${a_val#\"}"
  a_val="${a_val%\"}"
  a_val="${a_val#\'}"
  a_val="${a_val%\'}"

  printf -v "$a_output_var_name" '%s' "$a_val"
}

##
# Expand leading ~/ to $HOME.
#
# @param 1 String : path.
# @param 2 [optional] String : output var name (default: software_expand_path).
#
f_software_expand_path() {
  local a_path="$1"
  local a_output_var_name="${2:-software_expand_path}"

  local expanded

  f_software_scalar "$a_path" 'expanded'

  case "$expanded" in
    '~'|'~/'*)
      expanded="${HOME}${expanded:1}"
      ;;
  esac

  printf -v "$a_output_var_name" '%s' "$expanded"
}

##
# Resolve prune flag from env and optional CLI args in calling scope.
#
# Sets SOFTWARE_PRUNE=1 when --prune is present in "$@".
#
f_software_parse_args() {
  local arg

  for arg in "$@"; do
    case "$arg" in
      --prune)
        export SOFTWARE_PRUNE=1
        ;;
    esac
  done
}

##
# Paths to YAML manifests (default + optional local overlay).
#
# @var software_manifest_files_arr
#
f_software_manifest_paths() {
  software_manifest_files_arr=()

  if [[ -f scripts/asc/extend/software/apps.manifest.yml ]]; then
    software_manifest_files_arr+=('scripts/asc/extend/software/apps.manifest.yml')
  fi

  if [[ -f asc/extensions/software/apps.manifest.yml ]]; then
    software_manifest_files_arr+=('asc/extensions/software/apps.manifest.yml')
  fi

  if [[ -f data/asc/software/apps.manifest.local.yml ]]; then
    software_manifest_files_arr+=('data/asc/software/apps.manifest.local.yml')
  fi
}

##
# Load and merge manifests into sw_* arrays (bash-yaml).
#
f_software_load_manifests() {
  local f
  local parsed

  unset sw_apt_arr sw_pipx_arr \
    sw_tarball__id_arr sw_tarball__version_arr sw_tarball__url_arr \
    sw_tarball__install_dir_arr sw_tarball__binary_arr \
    sw_appimage__id_arr sw_appimage__url_arr sw_appimage__sha256_arr sw_appimage__path_arr \
    sw_ensure__id_arr sw_ensure__command_arr sw_ensure__method_arr \
    sw_units__id_arr sw_units__kind sw_units__template_arr sw_units__enable_arr \
    sw_units__requires 2>/dev/null || true

  sw_apt_arr=()
  sw_pipx_arr=()
  sw_tarball__id_arr=()
  sw_tarball__version_arr=()
  sw_tarball__url_arr=()
  sw_tarball__install_dir_arr=()
  sw_tarball__binary_arr=()
  sw_appimage__id_arr=()
  sw_appimage__url_arr=()
  sw_appimage__sha256_arr=()
  sw_appimage__path_arr=()
  sw_ensure__id_arr=()
  sw_ensure__command_arr=()
  sw_ensure__method_arr=()
  sw_units__id_arr=()
  sw_units__kind=()
  sw_units__template_arr=()
  sw_units__enable_arr=()
  sw_units__requires=()

  f_software_manifest_paths

  if [[ ${#software_manifest_files_arr[@]} -eq 0 ]]; then
    echo >&2
    echo "Error: no software manifests found." >&2
    echo "Expected scripts/asc/extend/software/apps.manifest.yml" >&2
    echo >&2

    return 1
  fi

  for f in "${software_manifest_files_arr[@]}"; do
    parsed="$(f_yaml_parse "$f" 'sw_')"
    eval "$parsed"
  done

  return 0
}

##
# Managed-state file path (gitignored under data/asc).
#
# @param 1 [optional] String : output var name (default: software_managed_path).
#
f_software_managed_path() {
  local a_output_var_name="${1:-software_managed_path}"
  printf -v "$a_output_var_name" '%s' 'data/asc/software/managed.list'
}

##
# Ensure local software state dir exists.
#
f_software_ensure_state_dir() {
  mkdir -p data/asc/software
}

##
# Record a managed install id (kind:name).
#
f_software_managed_add() {
  local a_id="$1"
  local path
  local line

  f_software_ensure_state_dir
  f_software_managed_path 'path'

  if [[ -f "$path" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "$a_id" ]]; then
        return 0
      fi
    done < "$path"
  fi

  echo "$a_id" >> "$path"
}

##
# Load managed ids into software_managed_ids_arr array.
#
# @var software_managed_ids_arr
#
f_software_managed_load() {
  local path
  local line

  software_managed_ids_arr=()
  f_software_managed_path 'path'

  if [[ ! -f "$path" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    software_managed_ids_arr+=("$line")
  done < "$path"
}

##
# Rewrite managed.list from software_managed_ids_arr.
#
f_software_managed_save() {
  local path
  local id

  f_software_ensure_state_dir
  f_software_managed_path 'path'

  : > "$path"

  for id in "${software_managed_ids_arr[@]}"; do
    echo "$id" >> "$path"
  done
}

##
# Remove one id from the managed list.
#
f_software_managed_remove() {
  local a_id="$1"
  local kept_arr=()
  local id

  f_software_managed_load

  for id in "${software_managed_ids_arr[@]}"; do
    if [[ "$id" != "$a_id" ]]; then
      kept_arr+=("$id")
    fi
  done

  software_managed_ids_arr=("${kept_arr[@]}")
  f_software_managed_save
}

##
# Desired-state ids currently declared in loaded manifests.
#
# @var software_desired_ids_arr
#
f_software_desired_ids() {
  local i
  local pkg
  local name

  software_desired_ids_arr=()

  for pkg in "${sw_apt_arr[@]}"; do
    f_software_scalar "$pkg" 'pkg'
    [[ -n "$pkg" ]] && software_desired_ids_arr+=("apt:$pkg")
  done

  for pkg in "${sw_pipx_arr[@]}"; do
    f_software_scalar "$pkg" 'pkg'
    name="${pkg%%==*}"
    [[ -n "$name" ]] && software_desired_ids_arr+=("pipx:$name")
  done

  for ((i = 0; i < ${#sw_tarball__id_arr[@]}; i++)); do
    f_software_scalar "${sw_tarball__id_arr[$i]}" 'name'
    [[ -n "$name" ]] && software_desired_ids_arr+=("tarball:$name")
  done

  for ((i = 0; i < ${#sw_appimage__id_arr[@]}; i++)); do
    f_software_scalar "${sw_appimage__id_arr[$i]}" 'name'
    [[ -n "$name" ]] && software_desired_ids_arr+=("appimage:$name")
  done

  for ((i = 0; i < ${#sw_ensure__id_arr[@]}; i++)); do
    f_software_scalar "${sw_ensure__id_arr[$i]}" 'name'
    [[ -n "$name" ]] && software_desired_ids_arr+=("ensure:$name")
  done

  for ((i = 0; i < ${#sw_units__id_arr[@]}; i++)); do
    f_software_scalar "${sw_units__id_arr[$i]}" 'name'
    [[ -n "$name" ]] && software_desired_ids_arr+=("unit:$name")
  done
}

##
# Return 0 if id is in the desired set.
#
f_software_is_desired() {
  local a_id="$1"
  local id

  for id in "${software_desired_ids_arr[@]}"; do
    if [[ "$id" == "$a_id" ]]; then
      return 0
    fi
  done

  return 1
}

##
# Apt package status: missing | ok
#
f_software_apt_status() {
  local a_pkg="$1"

  if dpkg-query -W -f='${Status}' "$a_pkg" 2>/dev/null | grep -q 'install ok installed'; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# pipx package status: missing | outdated | ok
#
# Spec is name or name==version.
#
f_software_pipx_status() {
  local a_spec="$1"
  local name
  local want_ver
  local have
  local have_ver

  name="${a_spec%%==*}"
  want_ver=''

  if [[ "$a_spec" == *==* ]]; then
    want_ver="${a_spec#*==}"
  fi

  if ! command -v pipx >/dev/null 2>&1; then
    echo 'missing'
    return 0
  fi

  have="$(pipx list --short 2>/dev/null | awk -v n="$name" '$1 == n { print $2; exit }')"

  if [[ -z "$have" ]]; then
    echo 'missing'
    return 0
  fi

  have_ver="${have# }"

  if [[ -n "$want_ver" && "$have_ver" != "$want_ver" ]]; then
    echo 'outdated'
    return 0
  fi

  echo 'ok'
}

##
# Tarball app status via install_dir/.asc-software-version
#
f_software_tarball_status() {
  local a_dir="$1"
  local a_version="$2"
  local a_binary="$3"
  local marker
  local have
  local bin_path

  marker="${a_dir}/.asc-software-version"
  bin_path="${a_dir}/${a_binary}"

  if [[ ! -x "$bin_path" && ! -f "$bin_path" ]]; then
    echo 'missing'
    return 0
  fi

  if [[ -f "$marker" ]]; then
    have="$(tr -d '[:space:]' < "$marker")"

    if [[ "$have" == "$a_version" ]]; then
      echo 'ok'
      return 0
    fi

    echo 'outdated'
    return 0
  fi

  # Present without marker: treat as ok if binary exists (adopt on next apply).
  echo 'ok'
}

##
# AppImage status: missing | outdated | ok
#
f_software_appimage_status() {
  local a_path="$1"
  local a_sha="$2"
  local have

  if [[ ! -f "$a_path" ]]; then
    echo 'missing'
    return 0
  fi

  if [[ -n "$a_sha" ]]; then
    have="$(sha256sum "$a_path" | awk '{ print $1 }')"

    if [[ "$have" != "$a_sha" ]]; then
      echo 'outdated'
      return 0
    fi
  fi

  echo 'ok'
}

##
# Ensure-command status: missing | ok
#
f_software_ensure_status() {
  local a_cmd="$1"

  if command -v "$a_cmd" >/dev/null 2>&1; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# systemd --user unit status: missing | ok
#
f_software_unit_status() {
  local a_id="$1"

  if [[ -f "${HOME}/.config/systemd/user/${a_id}.service" ]]; then
    echo 'ok'
  else
    echo 'missing'
  fi
}

##
# Diff result arrays (parallel: software_diff_ids_arr / software_diff_status_arr).
#
# @var software_diff_ids_arr
# @var software_diff_status_arr
# @var software_diff_extra_arr
#
f_software_build_diff() {
  local i
  local pkg
  local name
  local st
  local path
  local ver
  local url
  local sha
  local bin
  local dir
  local method
  local cmd
  local id

  software_diff_ids_arr=()
  software_diff_status_arr=()
  software_diff_extra_arr=()

  f_software_desired_ids
  f_software_managed_load

  for pkg in "${sw_apt_arr[@]}"; do
    f_software_scalar "$pkg" 'pkg'
    [[ -z "$pkg" ]] && continue
    st="$(f_software_apt_status "$pkg")"
    software_diff_ids_arr+=("apt:$pkg")
    software_diff_status_arr+=("$st")
  done

  for pkg in "${sw_pipx_arr[@]}"; do
    f_software_scalar "$pkg" 'pkg'
    [[ -z "$pkg" ]] && continue
    name="${pkg%%==*}"
    st="$(f_software_pipx_status "$pkg")"
    software_diff_ids_arr+=("pipx:$name")
    software_diff_status_arr+=("$st")
  done

  for ((i = 0; i < ${#sw_tarball__id_arr[@]}; i++)); do
    f_software_scalar "${sw_tarball__id_arr[$i]}" 'name'
    f_software_scalar "${sw_tarball__version_arr[$i]}" 'ver'
    f_software_expand_path "${sw_tarball__install_dir_arr[$i]}" 'dir'
    f_software_scalar "${sw_tarball__binary_arr[$i]}" 'bin'
    [[ -z "$name" ]] && continue
    st="$(f_software_tarball_status "$dir" "$ver" "$bin")"
    software_diff_ids_arr+=("tarball:$name")
    software_diff_status_arr+=("$st")
  done

  for ((i = 0; i < ${#sw_appimage__id_arr[@]}; i++)); do
    f_software_scalar "${sw_appimage__id_arr[$i]}" 'name'
    f_software_expand_path "${sw_appimage__path_arr[$i]}" 'path'
    f_software_scalar "${sw_appimage__sha256_arr[$i]:-}" 'sha'
    [[ -z "$name" ]] && continue
    st="$(f_software_appimage_status "$path" "$sha")"
    software_diff_ids_arr+=("appimage:$name")
    software_diff_status_arr+=("$st")
  done

  for ((i = 0; i < ${#sw_ensure__id_arr[@]}; i++)); do
    f_software_scalar "${sw_ensure__id_arr[$i]}" 'name'
    f_software_scalar "${sw_ensure__command_arr[$i]}" 'cmd'
    [[ -z "$name" ]] && continue
    st="$(f_software_ensure_status "$cmd")"
    software_diff_ids_arr+=("ensure:$name")
    software_diff_status_arr+=("$st")
  done

  for ((i = 0; i < ${#sw_units__id_arr[@]}; i++)); do
    f_software_scalar "${sw_units__id_arr[$i]}" 'name'
    [[ -z "$name" ]] && continue
    st="$(f_software_unit_status "$name")"
    software_diff_ids_arr+=("unit:$name")
    software_diff_status_arr+=("$st")
  done

  for id in "${software_managed_ids_arr[@]}"; do
    if ! f_software_is_desired "$id"; then
      software_diff_extra_arr+=("$id")
    fi
  done
}

##
# Print status diff summary.
#
f_software_print_diff() {
  local i
  local id
  local st
  local n_ok=0
  local n_missing=0
  local n_outdated=0

  echo
  echo "Software status (desired vs actual)"
  echo "------------------------------------"

  for ((i = 0; i < ${#software_diff_ids_arr[@]}; i++)); do
    id="${software_diff_ids_arr[$i]}"
    st="${software_diff_status_arr[$i]}"
    printf '  %-28s %s\n' "$id" "$st"

    case "$st" in
      ok) n_ok=$((n_ok + 1)) ;;
      missing) n_missing=$((n_missing + 1)) ;;
      outdated) n_outdated=$((n_outdated + 1)) ;;
    esac
  done

  if [[ ${#software_diff_extra_arr[@]} -gt 0 ]]; then
    echo
    echo "Extras (managed, not in manifest) — uninstall only with --prune:"

    for id in "${software_diff_extra_arr[@]}"; do
      echo "  $id"
    done
  fi

  echo
  echo "Summary: ok=$n_ok missing=$n_missing outdated=$n_outdated extras=${#software_diff_extra_arr[@]}"
  echo
}

##
# Run apt-get install for one package (sudo if needed).
#
f_software_apt_install() {
  local a_pkg="$1"

  if [[ "$(id -u)" -eq 0 ]]; then
    apt-get install -y "$a_pkg"
  else
    sudo apt-get install -y "$a_pkg"
  fi
}

##
# Install or upgrade a pipx package from name==version or name.
#
f_software_pipx_install() {
  local a_spec="$1"
  local name
  local st

  if ! command -v pipx >/dev/null 2>&1; then
    echo >&2 "Error: pipx not in PATH (install apt:pipx first)."
    return 1
  fi

  name="${a_spec%%==*}"
  st="$(f_software_pipx_status "$a_spec")"

  case "$st" in
    missing)
      pipx install "$a_spec"
      ;;
    outdated)
      pipx install --force "$a_spec"
      ;;
    *)
      return 0
      ;;
  esac
}

##
# Download + unpack a versioned tarball into install_dir.
#
f_software_tarball_install() {
  local a_id="$1"
  local a_version="$2"
  local a_url="$3"
  local a_dir="$4"
  local a_binary="$5"
  local url
  local tmp
  local archive
  local extracted

  url="${a_url//\{version\}/$a_version}"
  tmp="$(mktemp -d)"
  archive="${tmp}/${a_id}.tar.gz"

  echo "Downloading $a_id v$a_version ..."

  if ! curl -fsSL "$url" -o "$archive"; then
    rm -rf "$tmp"
    echo >&2 "Error: download failed for $url"
    return 1
  fi

  mkdir -p "$a_dir"
  tar -xzf "$archive" -C "$tmp"

  extracted="$(find "$tmp" -type f -name "$a_binary" | head -1)"

  if [[ -z "$extracted" || ! -f "$extracted" ]]; then
    rm -rf "$tmp"
    echo >&2 "Error: binary '$a_binary' not found in archive."
    return 1
  fi

  cp -a "$extracted" "${a_dir}/${a_binary}"
  chmod +x "${a_dir}/${a_binary}"
  echo "$a_version" > "${a_dir}/.asc-software-version"
  rm -rf "$tmp"
}

##
# Download AppImage when URL is set.
#
f_software_appimage_install() {
  local a_id="$1"
  local a_url="$2"
  local a_sha="$3"
  local a_path="$4"
  local have
  local dir

  if [[ -z "$a_url" ]]; then
    echo >&2 "Skip appimage:$a_id — no url in manifest (file missing at $a_path)."
    return 1
  fi

  dir="$(dirname "$a_path")"
  mkdir -p "$dir"

  echo "Downloading appimage:$a_id ..."

  if ! curl -fsSL "$a_url" -o "$a_path"; then
    echo >&2 "Error: download failed for $a_url"
    return 1
  fi

  chmod +x "$a_path"

  if [[ -n "$a_sha" ]]; then
    have="$(sha256sum "$a_path" | awk '{ print $1 }')"

    if [[ "$have" != "$a_sha" ]]; then
      echo >&2 "Error: sha256 mismatch for $a_path"
      echo >&2 "  expected: $a_sha"
      echo >&2 "  got:      $have"
      return 1
    fi
  fi
}

##
# Ensure a command via a known install method.
#
f_software_ensure_install() {
  local a_id="$1"
  local a_cmd="$2"
  local a_method="$3"

  if command -v "$a_cmd" >/dev/null 2>&1; then
    return 0
  fi

  case "$a_method" in
    ollama_install_sh)
      echo "Installing ollama via official install script ..."
      curl -fsSL https://ollama.com/install.sh | sh
      ;;
    *)
      echo >&2 "Error: unknown ensure method '$a_method' for $a_id"
      return 1
      ;;
  esac

  if ! command -v "$a_cmd" >/dev/null 2>&1; then
    echo >&2 "Error: $a_cmd still missing after install."
    return 1
  fi
}

##
# Install a systemd --user unit from a template path.
#
f_software_unit_install() {
  local a_id="$1"
  local a_template="$2"
  local a_enable="$3"
  local dest
  local src

  src="$a_template"

  if [[ ! -f "$src" ]]; then
    if [[ -f "scripts/asc/extend/software/${a_template}" ]]; then
      src="scripts/asc/extend/software/${a_template}"
    elif [[ -f "asc/extensions/software/${a_template}" ]]; then
      src="asc/extensions/software/${a_template}"
    fi
  fi

  if [[ ! -f "$src" ]]; then
    echo >&2 "Error: unit template not found: $a_template"
    return 1
  fi

  dest="${HOME}/.config/systemd/user/${a_id}.service"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  systemctl --user daemon-reload

  local enable_scalar
  f_software_scalar "$a_enable" 'enable_scalar'
  case "$enable_scalar" in
    true|yes|1)
      systemctl --user enable --now "${a_id}.service" || \
        systemctl --user enable "${a_id}.service"
      ;;
  esac
}

##
# Apply install/upgrade for missing and outdated items.
#
f_software_apply_installs() {
  local i
  local id
  local st
  local kind
  local name
  local pkg
  local ver
  local url
  local dir
  local bin
  local path
  local sha
  local cmd
  local method
  local tpl
  local en
  local idx
  local j
  local scalar
  local rc=0

  for ((i = 0; i < ${#software_diff_ids_arr[@]}; i++)); do
    id="${software_diff_ids_arr[$i]}"
    st="${software_diff_status_arr[$i]}"

    case "$st" in
      missing|outdated) ;;
      *) continue ;;
    esac

    kind="${id%%:*}"
    name="${id#*:}"

    echo "Apply $st → $id"

    case "$kind" in
      apt)
        if ! f_software_apt_install "$name"; then
          rc=1
          continue
        fi
        ;;
      pipx)
        pkg=''
        for pkg in "${sw_pipx_arr[@]}"; do
          f_software_scalar "$pkg" 'pkg'
          if [[ "${pkg%%==*}" == "$name" ]]; then
            break
          fi
          pkg=''
        done
        if [[ -z "$pkg" ]]; then
          rc=1
          continue
        fi
        if ! f_software_pipx_install "$pkg"; then
          rc=1
          continue
        fi
        ;;
      tarball)
        idx=-1
        for ((j = 0; j < ${#sw_tarball__id_arr[@]}; j++)); do
          f_software_scalar "${sw_tarball__id_arr[$j]}" 'scalar'

          if [[ "$scalar" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        f_software_scalar "${sw_tarball__version_arr[$idx]}" 'ver'
        f_software_scalar "${sw_tarball__url_arr[$idx]}" 'url'
        f_software_expand_path "${sw_tarball__install_dir_arr[$idx]}" 'dir'
        f_software_scalar "${sw_tarball__binary_arr[$idx]}" 'bin'
        if ! f_software_tarball_install "$name" "$ver" "$url" "$dir" "$bin"; then
          rc=1
          continue
        fi
        ;;
      appimage)
        idx=-1
        for ((j = 0; j < ${#sw_appimage__id_arr[@]}; j++)); do
          f_software_scalar "${sw_appimage__id_arr[$j]}" 'scalar'

          if [[ "$scalar" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        f_software_scalar "${sw_appimage__url_arr[$idx]:-}" 'url'
        f_software_scalar "${sw_appimage__sha256_arr[$idx]:-}" 'sha'
        f_software_expand_path "${sw_appimage__path_arr[$idx]}" 'path'
        if ! f_software_appimage_install "$name" "$url" "$sha" "$path"; then
          rc=1
          continue
        fi
        ;;
      ensure)
        idx=-1
        for ((j = 0; j < ${#sw_ensure__id_arr[@]}; j++)); do
          f_software_scalar "${sw_ensure__id_arr[$j]}" 'scalar'

          if [[ "$scalar" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        f_software_scalar "${sw_ensure__command_arr[$idx]}" 'cmd'
        f_software_scalar "${sw_ensure__method_arr[$idx]}" 'method'
        if ! f_software_ensure_install "$name" "$cmd" "$method"; then
          rc=1
          continue
        fi
        ;;
      unit)
        idx=-1
        for ((j = 0; j < ${#sw_units__id_arr[@]}; j++)); do
          f_software_scalar "${sw_units__id_arr[$j]}" 'scalar'

          if [[ "$scalar" == "$name" ]]; then
            idx=$j
            break
          fi
        done
        if [[ "$idx" -lt 0 ]]; then
          rc=1
          continue
        fi
        f_software_scalar "${sw_units__template_arr[$idx]}" 'tpl'
        f_software_scalar "${sw_units__enable_arr[$idx]:-false}" 'en'
        if ! f_software_unit_install "$name" "$tpl" "$en"; then
          rc=1
          continue
        fi
        ;;
      *)
        echo >&2 "Unknown kind: $kind"
        rc=1
        continue
        ;;
    esac

    f_software_managed_add "$id"
  done

  # Adopt already-satisfied desired items so prune can track them later.
  for ((i = 0; i < ${#software_diff_ids_arr[@]}; i++)); do
    if [[ "${software_diff_status_arr[$i]}" == 'ok' ]]; then
      f_software_managed_add "${software_diff_ids_arr[$i]}"
    fi
  done

  return $rc
}

##
# Opt-in uninstall of managed extras not in the manifest.
#
f_software_apply_prune() {
  local id
  local kind
  local name
  local i
  local dir
  local path
  local bin

  if [[ "${SOFTWARE_PRUNE:-}" != '1' ]]; then
    if [[ ${#software_diff_extra_arr[@]} -gt 0 ]]; then
      echo "Extras left in place (set SOFTWARE_PRUNE=1 or pass --prune to uninstall)."
    fi

    return 0
  fi

  for id in "${software_diff_extra_arr[@]}"; do
    kind="${id%%:*}"
    name="${id#*:}"
    echo "Prune $id"

    case "$kind" in
      apt)
        if [[ "$(id -u)" -eq 0 ]]; then
          apt-get remove -y "$name" || true
        else
          sudo apt-get remove -y "$name" || true
        fi
        ;;
      pipx)
        pipx uninstall "$name" || true
        ;;
      tarball)
        # Extra not in current manifest — conventional install dir only.
        dir="${HOME}/Software/${name}"
        if [[ -d "$dir" ]]; then
          rm -rf "$dir"
        fi
        ;;
      appimage)
        path="${HOME}/Software/${name}-x86_64.AppImage"
        [[ -f "$path" ]] && rm -f "$path"
        ;;
      unit)
        systemctl --user disable --now "${name}.service" 2>/dev/null || true
        rm -f "${HOME}/.config/systemd/user/${name}.service"
        systemctl --user daemon-reload 2>/dev/null || true
        ;;
      ensure)
        echo >&2 "Skip prune ensure:$name (no safe uninstall)."
        continue
        ;;
      *)
        echo >&2 "Skip prune of unknown kind: $id"
        continue
        ;;
    esac

    f_software_managed_remove "$id"
  done
}

##
# Main entry: status | apply
#
# @param 1 String : status | apply
#
f_software_provision() {
  local a_mode="${1:-apply}"
  local rc=0

  if ! f_software_load_manifests; then
    return 1
  fi

  f_software_build_diff
  f_software_print_diff

  case "$a_mode" in
    status)
      return 0
      ;;
    apply)
      f_software_apply_installs || rc=$?
      f_software_build_diff
      f_software_apply_prune || rc=$?
      echo "Software provision finished (exit=$rc)."
      return $rc
      ;;
    *)
      echo >&2 "Error: unknown mode '$a_mode' (use status|apply)."
      return 2
      ;;
  esac
}
