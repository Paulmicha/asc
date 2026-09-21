#!/usr/bin/env bash

##
# Slug / snake helpers.
#
# Callers must source this file.
#
# Convention : functions names are all prefixed by "f".
#

##
# Maps one input character to a lowercase ASCII slug letter (or empty).
#
# Pure bash — no fork, no pipe. Drops ~ and ^ (iconv//TRANSLIT parity).
# Latin-1 accents fold to ASCII; unmapped non-ASCII yields empty (separator).
#
# @sets transliterated_char folded letter, or empty when the char should not appear in output.
#
f_transliterate_char() {
  local c="$1"

  transliterated_char=''

  case "$c" in
    ~|^) return 0 ;;
    [0-9] | [a-z]) transliterated_char="$c" ;;
    [A-Z]) transliterated_char="${c,,}" ;;
    é | è | ê | ë | É | È | Ê | Ë) transliterated_char='e' ;;
    à | á | â | ã | ä | å | À | Á | Â | Ã | Ä | Å) transliterated_char='a' ;;
    ù | ú | û | ü | Ù | Ú | Û | Ü) transliterated_char='u' ;;
    ì | í | î | ï | Ì | Í | Î | Ï) transliterated_char='i' ;;
    ò | ó | ô | ö | Ò | Ó | Ô | Ö) transliterated_char='o' ;;
    ñ | Ñ) transliterated_char='n' ;;
    ç | Ç) transliterated_char='c' ;;
    ý | ÿ | Ý) transliterated_char='y' ;;
    æ) transliterated_char='ae' ;;
    Æ) transliterated_char='ae' ;;
    œ) transliterated_char='oe' ;;
    Œ) transliterated_char='oe' ;;
    ß) transliterated_char='ss' ;;
  esac
}

##
# Generates a slug from string.
#
# Lightweight pure-bash implementation: one char loop, no pipe, no subshell.
# Optional separator (default '-'). Writes result via printf -v.
#
# See https://gist.github.com/oneohthree/f528c7ae1e701ad990e6 (original pipeline).
#
# @param 1 String : the string to convert.
# @param 2 [optional] String : separator inserted between alphanumeric runs.
#   Defaults to '-' (dash).
# @param 3 [optional] String : output variable name in calling scope.
#   Defaults to 'slug_val'.
#
# @example
#   f_str_slug "A string with non-standard characters and accents. éàù!îôï. Test out!"
#   echo "$slug_val" # "a-string-with-non-standard-characters-and-accents-eau-ioi-test-out"
#
# @example with different custom separator :
#   f_str_slug "second test .. 456.2" '.' 'slug_dot'
#   echo "$slug_dot" # "second.test.456.2"
#
f_str_slug() {
  local p_str="$1"
  local p_sep="${2:--}"
  local p_output_var_name="${3:-slug_val}"
  local result=''
  local pending_sep=0
  local i c

  f_str_sanitize_var_name "$p_output_var_name" 'p_output_var_name'

  for ((i = 0; i < ${#p_str}; i++)); do
    c="${p_str:i:1}"

    case "$c" in
      '~' | '^') continue ;;
    esac

    f_transliterate_char "$c"

    if [[ -n "$transliterated_char" ]]; then
      result+="$transliterated_char"
      pending_sep=0
    elif [[ -n "$p_sep" && -n "$result" && pending_sep -eq 0 ]]; then
      result+="$p_sep"
      pending_sep=1
    fi
  done

  if [[ -n "$p_sep" && -n "$result" ]]; then
    while [[ "$result" == "$p_sep"* ]]; do
      result="${result#"$p_sep"}"
    done
    while [[ "$result" == *"$p_sep" ]]; do
      result="${result%"$p_sep"}"
    done
  fi

  printf -v "$p_output_var_name" '%s' "$result"
}

##
# Generates a "snake case" slug from string.
#
# f_str_slug() variant using underscores instead of dashes.
#
# @see f_str_slug()
#
f_str_snake() {
  f_str_slug "$1" '_' "${2:-snake_val}"
}
