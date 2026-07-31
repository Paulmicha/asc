#!/usr/bin/env bash

##
# Runs a command in a nested ASC PROJECT_DOCROOT with a virgin environment.
#
# Uses env -i with the same core allowlist spirit as reinit.sh so parent
# PROJECT_DOCROOT / ASC instance globals do not leak.
#
# First arg is a nested instance ref — directory basename (unique), a
# parent-qualified id on collision (e.g. client/my-project), or a path.
#
# By default the next token is a nested make entry point (optional e: prefix
# is stripped like logged-thread — use e: only when calling via make, to
# avoid parent MAKECMDGOALS double-matching). Path-like tokens (contain /,
# end with .sh, start with ./ ../ or /, or exist as a file) run raw in the
# child — no make wrap. Prefix with "--" for other raw commands.
#
# Find/resolve come from subject-wide nested_asc.opt-inc.sh via bootstrap
# phase 90 (caller opt-inc auto-load). Exec helper stays in this file.
# Optional exec.opt-inc.sh would load after that if present.
#
# To map nested instance layouts, see:
#   asc/extensions/nested_asc/nested_asc/list.sh
#
# @param 1 String : nested instance ref (short id, qualified id, or path).
# @param ... : <make-entry> [args...] | e:<make-entry> [args...] | <path-like> [args...] | -- <command> [args...]
#
# @example
#   make nested-asc-exec my-project e:reinit
#   # Or :
#   asc/extensions/nested_asc/nested_asc/exec.sh my-project reinit
#
#   make nested-asc-exec my-project e:git-write-hooks
#   # Or :
#   asc/extensions/nested_asc/nested_asc/exec.sh my-project git-write-hooks
#
#   make nested-asc-exec my-project -- ls -la
#   # Or :
#   asc/extensions/nested_asc/nested_asc/exec.sh my-project -- ls -la
#
#   # Path-like script : raw in child (no make wrap)
#   asc/extensions/nested_asc/nested_asc/exec.sh my-project \
#     asc/instance/reinit.sh
#
#   # Raw commands : use "--"
#   make nested-asc-exec my-project -- git status
#   # Or :
#   asc/extensions/nested_asc/nested_asc/exec.sh my-project -- git status
#
#   # Collision : qualify with a parent folder name.
#   make nested-asc-exec client/my-project e:reinit
#   # Or :
#   asc/extensions/nested_asc/nested_asc/exec.sh client/my-project reinit
#

. asc/bootstrap.sh

##
# Runs a command in a nested ASC PROJECT_DOCROOT with a virgin environment.
#
# @param 1 String : absolute nested docroot.
# @param ... : command and args to run after cd.
#
# @example
#   u_nested_asc_exec /abs/path/to/my-project make reinit
#
u_nested_asc_exec() {
  local p_docroot="$1"
  shift

  if [[ -z "$p_docroot" || ! -d "$p_docroot" ]]; then
    echo "Error in u_nested_asc_exec() - $BASH_SOURCE line $LINENO: invalid docroot '$p_docroot'." >&2
    return 1
  fi

  if [[ ! -f "$p_docroot/asc/bootstrap.sh" ]]; then
    echo "Error in u_nested_asc_exec() - $BASH_SOURCE line $LINENO: not a ASC instance ('$p_docroot')." >&2
    return 2
  fi

  if [[ $# -eq 0 ]]; then
    echo "Error in u_nested_asc_exec() - $BASH_SOURCE line $LINENO: command required." >&2
    echo "Usage: u_nested_asc_exec <docroot> <command> [args...]" >&2
    return 3
  fi

  p_docroot="$(cd "$p_docroot" && pwd)"

  env -i \
    HOME="$HOME" \
    USER="$USER" \
    PATH="$PATH" \
    LANG="${LANG:-}" \
    LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" \
    TERM="${TERM:-}" \
    bash -c 'cd "$1" && shift && exec "$@"' bash "$p_docroot" "$@"
}

##
# Map a nested make entry (optional e: prefix) to: make <entry> [args...]
#
# Strips a leading e: when present (make-caller form). Bare names are the
# direct entry-point form. Does not validate that the entry exists in the child.
#
u_nested_asc_expand_entry() {
  local entry="${1#e:}"

  if [[ -z "$entry" ]]; then
    echo "Error in u_nested_asc_expand_entry() - $BASH_SOURCE line $LINENO: empty make entry." >&2
    return 1
  fi

  shift
  nested_asc_cmd=(make "$entry" "$@")
}

if [[ -z "$1" ]]; then
  echo "Usage:" >&2
  echo "  make nested-asc-exec <ref> e:<make-entry> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> <make-entry> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> <path-like> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> -- <command> [args...]" >&2
  echo "Ref = short id (folder name), parent/id on collision, or path." >&2
  echo "Use e: only with make (avoids MAKECMDGOALS double-match)." >&2
  echo "Path-like tokens (/, ./, ../, *.sh, or existing file) run raw." >&2
  exit 1
fi

_nested_ref="$1"
shift

if ! u_nested_asc_resolve "$_nested_ref"; then
  exit $?
fi

# "--" → raw command in the child (skip make-entry expansion).
_nested_raw=0
if [[ "${1:-}" == '--' ]]; then
  _nested_raw=1
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "Usage:" >&2
  echo "  make nested-asc-exec <ref> e:<make-entry> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> <make-entry> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> <path-like> [args...]" >&2
  echo "  asc/extensions/nested_asc/nested_asc/exec.sh <ref> -- <command> [args...]" >&2
  exit 1
fi

# Path-like first token → raw (no make wrap). First match wins.
if [[ $_nested_raw -eq 0 ]]; then
  case "$1" in
    /*|./*|../*|*/*)
      _nested_raw=1
      ;;
    *.sh)
      _nested_raw=1
      ;;
    *)
      if [[ -f "$1" ]]; then
        _nested_raw=1
      fi
      ;;
  esac
fi

nested_asc_cmd=()
if [[ $_nested_raw -eq 1 ]]; then
  nested_asc_cmd=("$@")
else
  u_nested_asc_expand_entry "$@" || exit $?
fi
set -- "${nested_asc_cmd[@]}"

u_nested_asc_exec "$nested_asc_resolved" "$@"
exit $?
