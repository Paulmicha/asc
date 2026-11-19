#!/usr/bin/env bash

##
# ASC custom DSL utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
# @see docs/specs/asc/dsl.md
#
# Convention : functions names are all prefixed by "f".
#

##
# Eligible hardcoded Make names for DSL pivot dispatch (path-only).
#
# Compound or non-dispatch recipes (ds, debug, init-debug, hook-debug) are
# reserved but not eligible. Align paths with asc/make/default.mk.
#
# Writes calling-scope arrays :
#
# @var asc_dsl_hc_names_arr
# @var asc_dsl_hc_paths_arr
#
f_asc_dsl_list_hardcoded_eligible() {
  asc_dsl_hc_names_arr=(
    'init'
    'setup'
    'hook'
    'globals-lp'
  )
  asc_dsl_hc_paths_arr=(
    'asc/instance/init.sh'
    'asc/instance/setup.sh'
    'asc/make/hook.make.sh'
    'asc/core/global_lookup_paths.make.sh'
  )
}

##
# Print first-slice DSL usage to stderr.
#
f_asc_dsl_usage() {
  echo >&2
  echo "ASC DSL (first slice) :" >&2
  echo "  f_asc_dsl <expression> [-- <caller-arg>...]" >&2
  echo "  asc/dsl.sh <expression> [-- <caller-arg>...]" >&2
  echo >&2
  echo "Supported expression : one pivot call with literal or argv-bound args." >&2
  echo "  name" >&2
  echo "  name()" >&2
  echo "  name(arg[, arg...])" >&2
  echo >&2
  echo "Argument tokens : unquoted literals, 'quoted literals', pN, a, sN." >&2
  echo "Unquoted '%' becomes '*', '%%' becomes '**'." >&2
  echo "Unsupported in this slice : combinators, nesting, [functions], options," >&2
  echo "variable / YAML bindings, and loops." >&2
  echo >&2
}

##
# Diagnostic helper for f_asc_dsl (stderr + usage). Never exits.
#
# @param 1 String : short reason.
#
f_asc_dsl_err() {
  local p_reason="$1"

  echo >&2
  echo "Error in f_asc_dsl() - $BASH_SOURCE line ${BASH_LINENO[0]}: ${p_reason}" >&2
  f_asc_dsl_usage
}

##
# Resolve a pivot name to an executable script path.
#
# Hardcoded Make names are reserved before discovery. Only the eligible
# path-only set dispatches. Discovered names use f_make_list_entry_points.
#
# @param 1 String : pivot name.
#
# @var asc_dsl_script
#
# @return
#   0 : resolved
#   1 : unknown, ineligible, or non-executable
#
f_asc_dsl_resolve() {
  local p_name="$1"
  local pivots_arr=()
  local real_scripts_arr=()
  local asc_dsl_hc_names_arr=()
  local asc_dsl_hc_paths_arr=()
  local i
  local reserved=0

  asc_dsl_script=''

  f_make_list_hardcoded

  # Exact match : `case` and `[[ == ]]` honor nocasematch; POSIX `[` does not.
  for i in "${!pivots_arr[@]}"; do
    if [ "${pivots_arr[i]}" = "$p_name" ]; then
      reserved=1
      break
    fi
  done

  if [[ "$reserved" -eq 1 ]]; then
    f_asc_dsl_list_hardcoded_eligible

    for i in "${!asc_dsl_hc_names_arr[@]}"; do
      if [ "${asc_dsl_hc_names_arr[i]}" = "$p_name" ]; then
        asc_dsl_script="${asc_dsl_hc_paths_arr[i]}"

        if [[ -x "$asc_dsl_script" ]]; then
          return 0
        fi

        f_asc_dsl_err "hardcoded pivot '$p_name' script '$asc_dsl_script' is missing or not executable."

        return 1
      fi
    done

    f_asc_dsl_err "hardcoded Make name '$p_name' is reserved and not eligible for DSL dispatch."

    return 1
  fi

  pivots_arr=()
  real_scripts_arr=()
  f_make_list_entry_points

  for i in "${!pivots_arr[@]}"; do
    if [ "${pivots_arr[i]}" = "$p_name" ]; then
      asc_dsl_script="${real_scripts_arr[i]}"

      if [[ -x "$asc_dsl_script" ]]; then
        return 0
      fi

      f_asc_dsl_err "pivot '$p_name' script '$asc_dsl_script' is missing or not executable."

      return 1
    fi
  done

  f_asc_dsl_err "unknown pivot '$p_name'."

  return 1
}

##
# Expand one parsed argument token into calling-scope asc_dsl_argv_arr.
#
# @param 1 String : token (literal value, or pN / a / sN spelling).
# @param 2 String : kind — 'literal' or 'binding'.
#
# @var asc_dsl_argv_arr
# @var asc_dsl_bound_arr
# @var asc_dsl_bound_set
#
# @return
#   0 : ok
#   1 : binding error
#
f_asc_dsl_expand_token() {
  local p_token="$1"
  local p_kind="$2"
  local idx
  local drop
  local bound_n
  local i

  case "$p_kind" in literal)
    asc_dsl_argv_arr+=("$p_token")

    return 0
  esac

  if [[ "$asc_dsl_bound_set" -ne 1 ]]; then
    f_asc_dsl_err "argv binding token '$p_token' requires '--' before caller arguments."

    return 1
  fi

  case "$p_token" in
    a)
      for i in "${!asc_dsl_bound_arr[@]}"; do
        asc_dsl_argv_arr+=("${asc_dsl_bound_arr[i]}")
      done

      return 0
      ;;
  esac

  # Entire token must be pN / sN without leading zeroes (except s0). Compare the
  # decimal spelling to the bound length before any Bash arithmetic so oversized
  # or octal-looking suffixes cannot wrap or emit arithmetic errors.
  if [[ "$p_token" =~ ^p([1-9][0-9]*)$ ]]; then
    idx="${BASH_REMATCH[1]}"
    bound_n="${#asc_dsl_bound_arr[@]}"

    if [[ "${#idx}" -gt "${#bound_n}" ]] \
      || { [[ "${#idx}" -eq "${#bound_n}" ]] && [[ "$idx" > "$bound_n" ]]; }; then
      f_asc_dsl_err "positional binding '$p_token' is out of range (${bound_n} bound)."

      return 1
    fi

    asc_dsl_argv_arr+=("${asc_dsl_bound_arr[idx - 1]}")

    return 0
  fi

  if [[ "$p_token" =~ ^s(0|[1-9][0-9]*)$ ]]; then
    drop="${BASH_REMATCH[1]}"
    bound_n="${#asc_dsl_bound_arr[@]}"

    if [[ "${#drop}" -gt "${#bound_n}" ]] \
      || { [[ "${#drop}" -eq "${#bound_n}" ]] && [[ "$drop" > "$bound_n" ]]; }; then
      f_asc_dsl_err "skip binding '$p_token' drops more than ${bound_n} bound argument(s)."

      return 1
    fi

    for ((i = drop; i < bound_n; i++)); do
      asc_dsl_argv_arr+=("${asc_dsl_bound_arr[i]}")
    done

    return 0
  fi

  f_asc_dsl_err "unsupported binding token '$p_token'."

  return 1
}

##
# Parse one first-slice pivot call from an expression string.
#
# @param 1 String : full DSL expression.
#
# @var asc_dsl_call_name
# @var asc_dsl_argv_arr
# @var asc_dsl_bound_arr
# @var asc_dsl_bound_set
#
# @return
#   0 : parsed and argv expanded
#   1 : invalid or unsupported syntax / binding error
#
f_asc_dsl_parse_call() {
  local p_expr="$1"
  local expr="${p_expr#"${p_expr%%[![:space:]]*}"}"
  expr="${expr%"${expr##*[![:space:]]}"}"
  local len="${#expr}"
  local i=0
  local c
  local name=''
  local token=''
  local lit=''
  local kind=''
  local depth=0
  local saw_close=0

  # Token classification uses [[ == ]] / =~ / case, which honor nocasematch.
  # Keep parsing case-sensitive regardless of the caller's shell options.
  if shopt -q nocasematch; then
    shopt -u nocasematch
    trap 'shopt -s nocasematch; trap - RETURN' RETURN
  fi

  asc_dsl_call_name=''
  asc_dsl_argv_arr=()

  if [[ -z "$expr" ]]; then
    f_asc_dsl_err "expression is empty."

    return 1
  fi

  # Bracket function forms like [echo(...)] are not in this slice.
  case "$expr" in
    '['*)
      f_asc_dsl_err "function / bracket forms are not supported in this DSL slice: '$p_expr'."

      return 1
      ;;
  esac

  while [[ "$i" -lt "$len" ]]; do
    c="${expr:i:1}"

    case "$c" in
      [A-Za-z0-9_-])
        name+="$c"
        i=$((i + 1))
        ;;

      *)
        break
        ;;
    esac
  done

  if [[ -z "$name" ]]; then
    f_asc_dsl_err "expected a pivot name in: '$p_expr'."

    return 1
  fi

  asc_dsl_call_name="$name"

  if [[ "$i" -ge "$len" ]]; then
    return 0
  fi

  c="${expr:i:1}"

  if [[ "$c" != '(' ]]; then
    f_asc_dsl_err "unsupported syntax after pivot '$name' in: '$p_expr'."

    return 1
  fi

  i=$((i + 1))

  # Empty argument list.
  if [[ "$i" -lt "$len" && "${expr:i:1}" == ')' ]]; then
    i=$((i + 1))
    saw_close=1

    if [[ "$i" -ne "$len" ]]; then
      f_asc_dsl_err "unsupported trailing syntax in: '$p_expr'."

      return 1
    fi

    return 0
  fi

  while [[ "$i" -lt "$len" ]]; do
    # Optional whitespace before a token.
    while [[ "$i" -lt "$len" ]]; do
      c="${expr:i:1}"

      case "$c" in
        [[:space:]])
          i=$((i + 1))
          ;;

        *)
          break
          ;;
      esac
    done

    if [[ "$i" -ge "$len" ]]; then
      f_asc_dsl_err "unclosed argument list in: '$p_expr'."

      return 1
    fi

    c="${expr:i:1}"
    token=''
    kind=''

    case "$c" in
      "'")
        i=$((i + 1))
        lit=''

        while [[ "$i" -lt "$len" ]]; do
          c="${expr:i:1}"

          if [[ "$c" == "'" ]]; then
            i=$((i + 1))
            token="$lit"
            kind='literal'
            break
          fi

          lit+="$c"
          i=$((i + 1))
        done

        if [[ "$kind" != 'literal' ]]; then
          f_asc_dsl_err "unclosed single-quoted argument in: '$p_expr'."

          return 1
        fi
        ;;

      ',')
        f_asc_dsl_err "empty argument is written as '' in: '$p_expr'."

        return 1
        ;;

      ')')
        f_asc_dsl_err "empty argument is written as '' in: '$p_expr'."

        return 1
        ;;

      '(')
        f_asc_dsl_err "nested calls are not supported in this DSL slice: '$p_expr'."

        return 1
        ;;

      *)
        token=''

        while [[ "$i" -lt "$len" ]]; do
          c="${expr:i:1}"

          case "$c" in
            [A-Za-z0-9./_%-])
              token+="$c"
              i=$((i + 1))
              ;;

            *)
              break
              ;;
          esac
        done

        if [[ -z "$token" ]]; then
          f_asc_dsl_err "invalid argument syntax near '${expr:i:1}' in: '$p_expr'."

          return 1
        fi

        if [[ "$token" == 'a' ]] \
          || [[ "$token" =~ ^p[1-9][0-9]*$ ]] \
          || [[ "$token" =~ ^s(0|[1-9][0-9]*)$ ]]; then
          kind='binding'
        elif [[ "$token" =~ ^[ps][0-9]+$ ]]; then
          # Binding-shaped but invalid (leading zeroes, etc.) — never a literal.
          f_asc_dsl_err "unsupported binding token '$token' in: '$p_expr'."

          return 1
        elif [[ "$token" =~ ^v-[A-Za-z_][A-Za-z0-9_]*$ ]] \
          || [[ "$token" =~ ^d[0-9]+$ ]] \
          || [[ "$token" =~ ^bb?-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^ooe-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^oo-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^oe-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^o-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^(ba|bba|oa|ooa)$ ]]; then
          f_asc_dsl_err "unsupported reserved argument token '$token' in this DSL slice: '$p_expr'."

          return 1
        else
          # Unquoted literal : apply % / %% substitutions.
          lit=''
          depth=0

          while [[ "$depth" -lt "${#token}" ]]; do
            case "${token:depth:2}" in
              '%%')
                lit+='**'
                depth=$((depth + 2))
                ;;

              *)
                case "${token:depth:1}" in
                  '%')
                    lit+='*'
                    depth=$((depth + 1))
                    ;;

                  *)
                    lit+="${token:depth:1}"
                    depth=$((depth + 1))
                    ;;
                esac
                ;;
            esac
          done

          token="$lit"
          kind='literal'
        fi
        ;;
    esac

    if ! f_asc_dsl_expand_token "$token" "$kind"; then
      return 1
    fi

    # Optional whitespace before comma or close-paren.
    while [[ "$i" -lt "$len" ]]; do
      c="${expr:i:1}"

      case "$c" in
        [[:space:]])
          i=$((i + 1))
          ;;

        *)
          break
          ;;
      esac
    done

    if [[ "$i" -ge "$len" ]]; then
      f_asc_dsl_err "unclosed argument list in: '$p_expr'."

      return 1
    fi

    c="${expr:i:1}"

    case "$c" in
      ',')
        i=$((i + 1))

        # Trailing comma with no further tokens must not exit the loop as success.
        if [[ "$i" -ge "$len" ]]; then
          f_asc_dsl_err "unclosed argument list in: '$p_expr'."

          return 1
        fi
        ;;

      ')')
        i=$((i + 1))
        saw_close=1
        break
        ;;

      *)
        f_asc_dsl_err "expected ',' or ')' near '${expr:i}' in: '$p_expr'."

        return 1
        ;;
    esac
  done

  if [[ "$saw_close" -ne 1 ]]; then
    f_asc_dsl_err "unclosed argument list in: '$p_expr'."

    return 1
  fi

  if [[ "$i" -ne "$len" ]]; then
    f_asc_dsl_err "unsupported trailing syntax (combinators / extra calls are not in this slice): '$p_expr'."

    return 1
  fi

  return 0
}

##
# Interpret one ASC DSL expression (first slice).
#
# Parses and resolves before running. Returns the call status to the caller;
# never exits the shell on DSL or dispatched-script failure.
#
# @param 1 String : DSL expression.
# @param ... optional '--' then caller argv for pN / a / sN bindings.
#
# @return
#   0 : success
#   1 : invalid / unsupported / unknown call (no execution)
#   $? : status of the dispatched pivot script
#
# @example
#   f_asc_dsl 'slug(foobar)'
#   f_asc_dsl 'slug(p1)' -- 'Foo Bar'
#   f_asc_dsl 'slug(a)' -- one 'two three'
#
f_asc_dsl() {
  local p_expr="${1-}"
  local asc_dsl_bound_arr=()
  local asc_dsl_bound_set=0
  local asc_dsl_call_name=''
  local asc_dsl_argv_arr=()
  local asc_dsl_script=''
  local rc=0

  if [[ $# -lt 1 ]]; then
    f_asc_dsl_err "missing expression."

    return 1
  fi

  shift

  if [[ $# -gt 0 ]]; then
    case "$1" in
      '--')
        asc_dsl_bound_set=1
        shift
        asc_dsl_bound_arr=("$@")
        ;;

      *)
        f_asc_dsl_err "unexpected argument '$1' (use '--' before caller argv, or pass only the expression)."

        return 1
        ;;
    esac
  fi

  if ! f_asc_dsl_parse_call "$p_expr"; then
    return 1
  fi

  if ! f_asc_dsl_resolve "$asc_dsl_call_name"; then
    return 1
  fi

  "$asc_dsl_script" "${asc_dsl_argv_arr[@]}"
  rc=$?

  return "$rc"
}
