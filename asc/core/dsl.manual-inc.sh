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
# Print DSL usage to stderr.
#
f_asc_dsl_usage() {
  echo >&2
  echo "ASC DSL :" >&2
  echo "  f_asc_dsl <expression|*.dsl.txt> [-- <caller-arg>...]" >&2
  echo "  asc/dsl.sh <expression|*.dsl.txt> [-- <caller-arg>...]" >&2
  echo "  ASC_DS_EXPR='<expression|*.dsl.txt>' make ds" >&2
  echo >&2
  echo "Program : one or more pivot calls. A top-level newline sequences calls" >&2
  echo "(continue on nonzero; status is the last call). Blank lines are ignored." >&2
  echo "If the program argument ends with .dsl.txt, it is loaded as a file." >&2
  echo >&2
  echo "Call forms :" >&2
  echo "  name" >&2
  echo "  name()" >&2
  echo "  name(arg[, arg...])" >&2
  echo >&2
  echo "Argument tokens : unquoted literals, 'quoted literals', pN, a, sN." >&2
  echo "Unquoted '%' becomes '*', '%%' becomes '**'." >&2
  echo "Unsupported in this slice : ';' and other combinators, nesting," >&2
  echo "[functions], options, variable / YAML bindings, and loops." >&2
  echo >&2
}

##
# DSL diagnostics use throw() (instance throw hook + exit). See f_asc_dsl_usage
# for the CLI synopsis; call it before throw when a fuller help dump is wanted.
#

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
#
# On unknown, ineligible, or non-executable : throw() (does not return).
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

        throw "hardcoded pivot '$p_name' script '$asc_dsl_script' is missing or not executable."
      fi
    done

    throw "hardcoded Make name '$p_name' is reserved and not eligible for DSL dispatch."
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

      throw "pivot '$p_name' script '$asc_dsl_script' is missing or not executable."
    fi
  done

  throw "unknown pivot '$p_name'."
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
#
# On binding error : throw() (does not return).
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
    throw "argv binding token '$p_token' requires '--' before caller arguments."
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
      throw "positional binding '$p_token' is out of range (${bound_n} bound)."
    fi

    asc_dsl_argv_arr+=("${asc_dsl_bound_arr[idx - 1]}")

    return 0
  fi

  if [[ "$p_token" =~ ^s(0|[1-9][0-9]*)$ ]]; then
    drop="${BASH_REMATCH[1]}"
    bound_n="${#asc_dsl_bound_arr[@]}"

    if [[ "${#drop}" -gt "${#bound_n}" ]] \
      || { [[ "${#drop}" -eq "${#bound_n}" ]] && [[ "$drop" > "$bound_n" ]]; }; then
      throw "skip binding '$p_token' drops more than ${bound_n} bound argument(s)."
    fi

    for ((i = drop; i < bound_n; i++)); do
      asc_dsl_argv_arr+=("${asc_dsl_bound_arr[i]}")
    done

    return 0
  fi

  throw "unsupported binding token '$p_token'."
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
#
# On invalid or unsupported syntax / binding error : throw() (does not return).
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
    throw "expression is empty."
  fi

  # Bracket function forms like [echo(...)] are not in this slice.
  case "$expr" in
    '['*)
      throw "function / bracket forms are not supported in this DSL slice: '$p_expr'."
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
    throw "expected a pivot name in: '$p_expr'."
  fi

  asc_dsl_call_name="$name"

  if [[ "$i" -ge "$len" ]]; then
    return 0
  fi

  c="${expr:i:1}"

  if [[ "$c" != '(' ]]; then
    throw "unsupported syntax after pivot '$name' in: '$p_expr'."
  fi

  i=$((i + 1))

  # Optional whitespace / layout newlines before the first token or ')'.
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

  # Empty argument list (including whitespace-only layout inside parentheses).
  if [[ "$i" -lt "$len" && "${expr:i:1}" == ')' ]]; then
    i=$((i + 1))
    saw_close=1

    if [[ "$i" -ne "$len" ]]; then
      throw "unsupported trailing syntax in: '$p_expr'."
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
      throw "unclosed argument list in: '$p_expr'."
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
          throw "unclosed single-quoted argument in: '$p_expr'."
        fi
        ;;

      ',')
        throw "empty argument is written as '' in: '$p_expr'."
        ;;

      ')')
        throw "empty argument is written as '' in: '$p_expr'."
        ;;

      '(')
        throw "nested calls are not supported in this DSL slice: '$p_expr'."
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
          throw "invalid argument syntax near '${expr:i:1}' in: '$p_expr'."
        fi

        if [[ "$token" == 'a' ]] \
          || [[ "$token" =~ ^p[1-9][0-9]*$ ]] \
          || [[ "$token" =~ ^s(0|[1-9][0-9]*)$ ]]; then
          kind='binding'
        elif [[ "$token" =~ ^[ps][0-9]+$ ]]; then
          # Binding-shaped but invalid (leading zeroes, etc.) — never a literal.
          throw "unsupported binding token '$token' in: '$p_expr'."
        elif [[ "$token" =~ ^v-[A-Za-z_][A-Za-z0-9_]*$ ]] \
          || [[ "$token" =~ ^d[0-9]+$ ]] \
          || [[ "$token" =~ ^bb?-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^ooe-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^oo-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^oe-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^o-[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
          || [[ "$token" =~ ^(ba|bba|oa|ooa)$ ]]; then
          throw "unsupported reserved argument token '$token' in this DSL slice: '$p_expr'."
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

    f_asc_dsl_expand_token "$token" "$kind"

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
      throw "unclosed argument list in: '$p_expr'."
    fi

    c="${expr:i:1}"

    case "$c" in
      ',')
        i=$((i + 1))

        # Trailing comma with no further tokens must not exit the loop as success.
        if [[ "$i" -ge "$len" ]]; then
          throw "unclosed argument list in: '$p_expr'."
        fi
        ;;

      ')')
        i=$((i + 1))
        saw_close=1
        break
        ;;

      *)
        throw "expected ',' or ')' near '${expr:i}' in: '$p_expr'."
        ;;
    esac
  done

  if [[ "$saw_close" -ne 1 ]]; then
    throw "unclosed argument list in: '$p_expr'."
  fi

  if [[ "$i" -ne "$len" ]]; then
    throw "unsupported trailing syntax (combinators / extra calls are not in this slice): '$p_expr'."
  fi

  return 0
}

##
# Load a *.dsl.txt program from disk into calling-scope asc_dsl_program.
#
# Records the source byte size, copies one snapshot, then validates only that
# buffer (NUL strip, loaded length). Validation command failures are file
# errors — empty-equal counts are not success when wc/tr failed. If the
# snapshot byte size differs from the pre-copy source size, treat it as a
# concurrent in-place modification during capture (fail closed). Preferred
# writers replace via atomic rename; in-place truncate during read is not
# supported and is rejected when it shortens (or lengthens) the capture.
#
# Optional test hook: if f_asc_dsl_test_after_snap_copy is defined, it runs
# after the copy with (snap_path, source_path) before validation.
#
# @param 1 String : filesystem path ending in .dsl.txt.
#
# @var asc_dsl_program
#
# @return
#   0 : loaded
#
# On file error, embedded NUL, incomplete load, or concurrent modification :
# throw() (does not return).
#
f_asc_dsl_load_file() {
  local p_path="$1"
  local snap=''
  local before_size=''
  local snap_size=''
  local stripped_size=''
  local loaded_size=''
  local stripped_file=''

  asc_dsl_program=''

  if [[ ! -e "$p_path" ]]; then
    throw "DSL file not found: '$p_path'."
  fi

  if [[ ! -f "$p_path" ]]; then
    throw "DSL path is not a regular file: '$p_path'."
  fi

  if [[ ! -r "$p_path" ]]; then
    throw "DSL file is not readable: '$p_path'."
  fi

  if ! before_size="$(stat -c '%s' -- "$p_path")"; then
    throw "DSL file size could not be read: '$p_path'."
  fi

  # One snapshot of source bytes. Compare its size to before_size so an
  # in-place truncate/extend during cat cannot yield a partial program.
  snap="$(mktemp "${TMPDIR:-/tmp}/asc-dsl.XXXXXX")" || {
    throw "DSL file snapshot could not be created for: '$p_path'."
  }

  if ! cat -- "$p_path" > "$snap"; then
    rm -f "$snap"
    throw "DSL file could not be read completely: '$p_path'."
  fi

  # Test-only injection point (undefined in production).
  if declare -F f_asc_dsl_test_after_snap_copy >/dev/null 2>&1; then
    if ! f_asc_dsl_test_after_snap_copy "$snap" "$p_path"; then
      rm -f "$snap"
      throw "DSL file snapshot test hook failed: '$p_path'."
    fi
  fi

  if ! snap_size="$(stat -c '%s' -- "$snap")"; then
    rm -f "$snap"
    throw "DSL file snapshot size could not be read: '$p_path'."
  fi

  if [[ "$snap_size" != "$before_size" ]]; then
    rm -f "$snap"
    throw "DSL file changed during read (snapshot size mismatch): '$p_path'."
  fi

  if [[ ! -r "$snap" ]]; then
    rm -f "$snap"
    throw "DSL file snapshot could not be validated: '$p_path'."
  fi

  # NUL check without pipelines: each command status is checked alone. A failed
  # tr/stat must not be treated as success via empty-equal size comparison.
  stripped_file="$(mktemp "${TMPDIR:-/tmp}/asc-dsl-strip.XXXXXX")" || {
    rm -f "$snap"
    throw "DSL file snapshot could not be validated: '$p_path'."
  }

  if ! tr -d '\0' < "$snap" > "$stripped_file"; then
    rm -f "$snap" "$stripped_file"
    throw "DSL file snapshot could not be validated: '$p_path'."
  fi

  if ! stripped_size="$(stat -c '%s' -- "$stripped_file")"; then
    rm -f "$snap" "$stripped_file"
    throw "DSL file snapshot could not be validated: '$p_path'."
  fi

  rm -f "$stripped_file"

  if [[ "$snap_size" != "$stripped_size" ]]; then
    rm -f "$snap"
    throw "DSL file contains embedded NUL: '$p_path'."
  fi

  # No NUL in the snapshot : read -d '' takes the full buffer (EOF, no delim).
  IFS= read -r -d '' asc_dsl_program < "$snap" || true
  rm -f "$snap"

  # Measure loaded bytes via a checked write + stat (no wc pipeline).
  stripped_file="$(mktemp "${TMPDIR:-/tmp}/asc-dsl-strip.XXXXXX")" || {
    asc_dsl_program=''
    throw "DSL file snapshot could not be measured after load: '$p_path'."
  }

  if ! printf '%s' "$asc_dsl_program" > "$stripped_file"; then
    rm -f "$stripped_file"
    asc_dsl_program=''
    throw "DSL file snapshot could not be measured after load: '$p_path'."
  fi

  if ! loaded_size="$(stat -c '%s' -- "$stripped_file")"; then
    rm -f "$stripped_file"
    asc_dsl_program=''
    throw "DSL file snapshot could not be measured after load: '$p_path'."
  fi

  rm -f "$stripped_file"

  if [[ "$loaded_size" != "$snap_size" ]]; then
    asc_dsl_program=''
    throw "DSL file could not be loaded completely: '$p_path'."
  fi

  return 0
}

##
# Split a DSL program string into top-level call expressions.
#
# Top-level LF sequences calls (CRLF works because the CR is trimmed as
# trailing whitespace from the preceding expression). Bare CR does not
# sequence. Blank lines are ignored. Newlines inside '(...)' are layout.
# Newlines and CR inside single quotes are literal data.
#
# @param 1 String : full DSL program (inline or file contents).
#
# @var asc_dsl_exprs_arr
#
# @return 0
#
f_asc_dsl_split_program() {
  local p_program="$1"
  local len="${#p_program}"
  local i=0
  local c
  local depth=0
  local in_quote=0
  local cur=''
  local trimmed=''

  asc_dsl_exprs_arr=()

  while [[ "$i" -lt "$len" ]]; do
    c="${p_program:i:1}"

    if [[ "$in_quote" -eq 1 ]]; then
      cur+="$c"

      if [[ "$c" == "'" ]]; then
        in_quote=0
      fi

      i=$((i + 1))
      continue
    fi

    case "$c" in
      "'")
        in_quote=1
        cur+="$c"
        i=$((i + 1))
        ;;

      '(')
        depth=$((depth + 1))
        cur+="$c"
        i=$((i + 1))
        ;;

      ')')
        if [[ "$depth" -gt 0 ]]; then
          depth=$((depth - 1))
        fi

        cur+="$c"
        i=$((i + 1))
        ;;

      $'\n')
        if [[ "$depth" -eq 0 ]]; then
          i=$((i + 1))
          trimmed="${cur#"${cur%%[![:space:]]*}"}"
          trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

          if [[ -n "$trimmed" ]]; then
            asc_dsl_exprs_arr+=("$trimmed")
          fi

          cur=''
        else
          cur+="$c"
          i=$((i + 1))
        fi
        ;;

      *)
        # Bare CR is ordinary data here (not a sequence operator). At top level
        # between calls it stays in the expression and fails closed at parse.
        cur+="$c"
        i=$((i + 1))
        ;;
    esac
  done

  trimmed="${cur#"${cur%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"

  if [[ -n "$trimmed" ]]; then
    asc_dsl_exprs_arr+=("$trimmed")
  fi

  return 0
}

##
# Interpret an ASC DSL program (inline expression or *.dsl.txt path).
#
# File versus inline is decided by a .dsl.txt suffix on the program argument.
# The full program is split, parsed, binding-expanded, and pivot-resolved
# before any call dispatches. Top-level newlines sequence calls
# (continue-on-nonzero; last status). Diagnostics use throw() (exit). After a
# successful preparse, returns the last dispatched pivot status to the caller.
#
# @param 1 String : DSL expression or path ending in .dsl.txt.
# @param ... optional '--' then caller argv for pN / a / sN bindings.
#
# @return
#   0 : success (or last call status 0)
#   $? : status of the last dispatched pivot script
#
# On invalid / unsupported / unknown / file error (no execution) : throw().
#
# @example
#   f_asc_dsl 'slug(foobar)'
#   f_asc_dsl 'slug(p1)' -- 'Foo Bar'
#   f_asc_dsl path/to/prog.dsl.txt -- 'bound'
#
f_asc_dsl() {
  local p_arg="${1-}"
  local asc_dsl_bound_arr=()
  local asc_dsl_bound_set=0
  local asc_dsl_call_name=''
  local asc_dsl_argv_arr=()
  local asc_dsl_script=''
  local asc_dsl_program=''
  local asc_dsl_exprs_arr=()
  local asc_dsl_pre_scripts_arr=()
  local asc_dsl_pre_argv_flat_arr=()
  local asc_dsl_pre_argv_start_arr=()
  local asc_dsl_pre_argv_len_arr=()
  local rc=0
  local i
  local start
  local len
  local call_rc=0
  local asc_dsl_suffix='.dsl.txt'
  local asc_dsl_arg_len=0
  local asc_dsl_suf_len=0

  if [[ $# -lt 1 ]]; then
    throw "missing expression."
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
        throw "unexpected argument '$1' (use '--' before caller argv, or pass only the expression)."
        ;;
    esac
  fi

  # Exact suffix '.dsl.txt' only. POSIX [ = ] ignores nocasematch; [[ == ]] and
  # case do not.
  asc_dsl_arg_len="${#p_arg}"
  asc_dsl_suf_len="${#asc_dsl_suffix}"

  if [[ "$asc_dsl_arg_len" -ge "$asc_dsl_suf_len" ]] \
    && [ "${p_arg:asc_dsl_arg_len - asc_dsl_suf_len}" = "$asc_dsl_suffix" ]; then
    f_asc_dsl_load_file "$p_arg"
  else
    asc_dsl_program="$p_arg"
  fi

  f_asc_dsl_split_program "$asc_dsl_program"

  if [[ "${#asc_dsl_exprs_arr[@]}" -eq 0 ]]; then
    throw "expression is empty."
  fi

  # Preparse-all : syntax, bindings, and pivot resolve before any dispatch.
  for i in "${!asc_dsl_exprs_arr[@]}"; do
    asc_dsl_call_name=''
    asc_dsl_argv_arr=()
    asc_dsl_script=''

    f_asc_dsl_parse_call "${asc_dsl_exprs_arr[i]}"
    f_asc_dsl_resolve "$asc_dsl_call_name"

    asc_dsl_pre_argv_start_arr+=("${#asc_dsl_pre_argv_flat_arr[@]}")
    asc_dsl_pre_argv_len_arr+=("${#asc_dsl_argv_arr[@]}")
    asc_dsl_pre_argv_flat_arr+=("${asc_dsl_argv_arr[@]}")
    asc_dsl_pre_scripts_arr+=("$asc_dsl_script")
  done

  rc=0

  # Continue after nonzero under caller errexit : left-hand side of || does not
  # abort the shell; capture the status for last-status sequencing.
  for i in "${!asc_dsl_pre_scripts_arr[@]}"; do
    start="${asc_dsl_pre_argv_start_arr[i]}"
    len="${asc_dsl_pre_argv_len_arr[i]}"
    call_rc=0

    if [[ "$len" -gt 0 ]]; then
      "${asc_dsl_pre_scripts_arr[i]}" "${asc_dsl_pre_argv_flat_arr[@]:start:len}" \
        || call_rc=$?
    else
      "${asc_dsl_pre_scripts_arr[i]}" || call_rc=$?
    fi

    rc="$call_rc"
  done

  return "$rc"
}
