#!/usr/bin/env bash

##
# String-related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Converts tokens from given global (or any variable containing any token).
#
# This is used for things like file names patterns, as in the "db" extension :
# {{ %Y-%m-%d.%H-%M-%S }}_local-{{ DB_ID }}.{{ USER }}.{{ DUMP_FILE_EXTENSION }}
#
# Tokens can be any variable name available in calling scope, date formatters,
# or anything that can be evaled.
#
# By convention, this function writes its result to a variable named by default
# after the global name transformed to lowercase.
#
# @param 1 String : input var name.
# @param 2 [optional] String : output var name.
#   Defaults to param 1 in lowercase.
# @param 3 [optional] Int : recursive calls counter. Because there are tokens
#   that may point to values that also contain tokens, this function calls
#   itself at the end to traverse all the tokens. But we need to be able to
#   break out of the recursion if a token cannot get replaced due to missing
#   value.
#
# @example
#   # Given the following variables in calling scope :
#   USER='paul'
#   DB_ID='site'
#   DUMP_FILE_EXTENSION='sql'
#   ASC_DB_DUMPS_LOCAL_PATTERN='{{ %Y-%m-%d.%H-%M-%S }}_local-{{ DB_ID }}.{{ USER }}.{{ DUMP_FILE_EXTENSION }}'
#
#   # You can use the default output var naming convention (lowercase) :
#   f_str_convert_tokens ASC_DB_DUMPS_LOCAL_PATTERN
#   echo "asc_db_dumps_local_pattern = '$asc_db_dumps_local_pattern'"
#
#   # Or provide a specific var name for reading the result :
#   f_str_convert_tokens ASC_DB_DUMPS_LOCAL_PATTERN 'my_var_name'
#   echo "my_var_name = '$my_var_name'"
#
f_str_convert_tokens() {
  local a_input_var_name="$1"
  local a_output_var_name="$2"
  local a_circuit_breaker=0

  if [[ -z "$a_input_var_name" ]]; then
    echo >&2
    echo "Error in f_str_convert_tokens() - $BASH_SOURCE line $LINENO: param 1 (a_input_var_name) is required." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    return 1
  fi

  if [[ -z "$a_output_var_name" ]]; then
    f_str_lowercase "$a_input_var_name" 'a_output_var_name'
  fi

  if [[ $3 -gt $a_circuit_breaker ]]; then
    a_circuit_breaker=$3
  fi

  local tokens_replaced="${!a_input_var_name}"
  local regex="\{\{[[:space:]]*([^[:space:]]+)[[:space:]]*\}\}"
  local regex_loop_str="$tokens_replaced"
  local token=''
  local match=''
  local val=''
  local token_var_name_check=''

  while [[ "$regex_loop_str" =~ $regex ]]; do
    token="${BASH_REMATCH[0]}"
    match="${BASH_REMATCH[1]}"

    # For the while loop to get all tokens, it needs to be gradually pruned.
    regex_loop_str="${regex_loop_str#*$token}"

    val=''
    token_var_name_check=''

    # Anything with a '%' character is considered a date formatter.
    case "$match" in *'%'*)
      val="$(date +"$match")"

      # Debug.
      # echo "token = '$token'"
      # echo "  val = '$val'"

      tokens_replaced="${tokens_replaced//$token/$val}"
      continue
    esac

    f_str_sanitize_var_name "$match" 'token_var_name_check'

    if [[ "$token_var_name_check" == "$match" && -v $match ]]; then
      val="${!match}"
    fi

    # Debug.
    # echo "val.1 = '$val'"

    # If the attempt to convert to a variable name produces an empty string, we
    # move on to the eval (in a subshell).
    if [[ -z "$val" ]]; then
      # Debug.
      # echo "val=\"\$($match)\""

      eval "val=\"\$($match)\""
    fi

    # Debug.
    # echo "val.2 = '$val'"

    # TODO is it ok to require that all tokens not be empty ?
    if [[ -n "$val" ]]; then
      tokens_replaced="${tokens_replaced//$token/$val}"
    fi
  done

  # There are tokens that may point to values that also contain tokens.
  case "$tokens_replaced" in *'{{ '*)
    # Up to 9 recursions is probably more than enough.
    if [[ $a_circuit_breaker -lt 10 ]]; then
      a_circuit_breaker+=1
      f_str_convert_tokens "$a_input_var_name" "$a_output_var_name" $a_circuit_breaker
    else
      echo >&2
      echo "Error : breaking out of f_str_convert_tokens() recursion." >&2
      echo "This likely means that at least one token value is empty in :" >&2
      echo "  $tokens_replaced" >&2
      echo >&2
      exit 2
    fi
  esac

  # Write result to var in calling scope.
  printf -v "$a_output_var_name" '%s' "$tokens_replaced"
}

##
# Single quotes escaping trick.
#
# The escaping is done in a way compatible with the way shell concatenates
# input strings.
#
# I.e. :
#   'test with 'single' quotes.'
# becomes :
#   'test with '"'"'single'"'"' quotes.'
#
# @link https://stackoverflow.com/a/1250279
#
# @see asc/escape.sh
# @see asc/make/call_wrap.make.sh
#
f_str_escape_single_quotes() {
  local a_arg="$1"
  local a_var_name="$2"

  if [[ -z "$a_var_name" ]]; then
    a_var_name='escaped_arg'
  fi

  escaped_arg="$a_arg"

  case "$a_arg" in
    *' '*|*'$'*|*'#'*|*'['*|*']'*|*'*|*'*|*'&'*|*'*'*|*'"'*|*"'"*|*'='*)
      a_arg="${a_arg//\'/"'\"'\"'"}"
      escaped_arg="'${a_arg}'"
      ;;
  esac

  # Debug
  # echo "escape $a_var_name = $escaped_arg"

  printf -v "$a_var_name" '%s' "$escaped_arg"
}

##
# Encodes a single HTTP BasicAuth login/pass pair.
#
# Uses htpasswd encryption, which is also used for docker-compose Traefik labels.
#
# @param 1 [optional] String : reg key. Defaults to 'basic_auth_creds'.
# @param 2 [optional] String : login. Defaults to 'admin'.
# @param 3 [optional] String : password. Defaults to generated random string.
#
# NB : This function writes its result to a variable subject to collision in
# calling scope.
#
# @var basic_auth_credentials
#
# @example
#   # Defaults to key 'basic_auth_creds' + login: admin, pass: (a randomly
#   # generated string) :
#   encoded_credentials="$(f_str_basic_auth_credentials)"
#   echo "$encoded_credentials"
#   # To read the randomly generated password, use :
#   f_instance_registry_get 'basic_auth_creds' # <- or whatever key was passed in 3rd arg.
#
#   # Specify key :
#   encoded_credentials="$(f_str_basic_auth_credentials 'custom_reg_namespace')"
#   echo "$encoded_credentials"
#
#   # Specify credentials :
#   encoded_credentials="$(f_str_basic_auth_credentials 'custom_reg_namespace' 'foo' 'bar')"
#   echo "$encoded_credentials"
#
f_str_basic_auth_credentials() {
  local a_key="$1"
  local a_user="$2"
  local a_pass="$3"

  if [[ -z "$a_key" ]]; then
    a_key='basic_auth_creds'
  fi
  if [[ -z "$a_user" ]]; then
    a_user='admin'
  fi

  # When no password is passed as argument, if there was no random password
  # already generated in current instance for given key, generate one.
  f_instance_registry_get "$a_key"
  if [[ -z "$a_pass" ]] && [[ -z "$reg_val" ]]; then
    a_pass=`< /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo`
    f_instance_registry_set "$a_key" "$a_user:$a_pass"
  else
    f_str_split1 'split_arr' "$reg_val" ':'
    a_user="${split_arr[0]}"
    a_pass="${split_arr[1]}"
  fi

  # Update : because we're using an env. variable for credentials, we don't
  # actually need to escape dollar signs here.
  # echo "$a_user:$(openssl passwd -apr1 "$a_pass")" | sed -e s/\\$/\\$\\$/g
  echo "$a_user:$(openssl passwd -apr1 "$a_pass")"
}

##
# Sanitizes a string to be used as a variable name (for 'eval').
#
# This function is a "preset" of the more generic string sanitizing utility.
# @see f_str_sanitize()
#
# @param 1 String : variable name to be sanitized.
# @param 2 String : name of the variable in calling scope which holds the
#   variable name to be sanitized (acronym : notvicswhtvntbs).
#
# @see https://stackoverflow.com/a/41059855 (why use 'eval' in the first place).
#
# @example
#   # Typical use case : see f_str_split1().
#   local a_var_name="$1"
#   f_str_sanitize_var_name "$a_var_name" 'a_var_name'
#   echo "$a_var_name" # <- Prints sanitized variable name.
#
f_str_sanitize_var_name() {
  local a_input="$1"
  local a_notvicswhtvntbs="$2"

  # The variable a_notvicswhtvntbs must not collide in calling scope. Hopefully
  # the acronym used here is enough to make it sufficiently unlikely.
  printf -v "$a_notvicswhtvntbs" '%s' "${a_notvicswhtvntbs//[^a-zA-Z0-9_]/_}"

  f_str_sanitize "$a_input" '_' "$a_notvicswhtvntbs" '[^a-zA-Z0-9_]'
}

##
# Sanitizes strings (basic search/replace using regex).
#
# @param 1 String : the value to sanitize.
# @param 2 [optional] String : with what to replace filtered out characters.
#   Defaults to : '-'.
# @param 3 [optional] String : the variable name in calling scope which will
#   hold the result for performance reasons (to avoid using a subshell).
#   Defaults to : 'sanitized_str'.
# @param 4 [optional] String : characters to filter (regex). Defaults to :
#   '[^a-zA-Z0-9_\-\.]'
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
# The default variable name is overridable : see arg 3.
#
# @var [default(3)] sanitized_str
#
# @see asc/test/asc/utilities.test.sh
#
# @example
#   f_str_sanitize "a b c d"
#   echo "$sanitized_str" # <- Prints 'a-b-c-d'
#   f_str_sanitize "a b c d" '_'
#   echo "$sanitized_str" # <- Prints 'a_b_c_d'
#
f_str_sanitize() {
  local a_ussvfhnc_str="$1"
  local a_ussvfhnc_replace="$2"
  local a_ussvfhnc_var_name="$3"
  local a_ussvfhnc_filter="$4"

  if [[ -z "$a_ussvfhnc_filter" ]]; then
    a_ussvfhnc_filter='[^a-zA-Z0-9_\-\.]'
  fi

  # Allows empty strings.
  if [[ $# -lt 2 ]] && [[ -z "$a_ussvfhnc_replace" ]]; then
    a_ussvfhnc_replace='-'
  fi

  if [[ -z "$a_ussvfhnc_var_name" ]]; then
    a_ussvfhnc_var_name='sanitized_str'
  fi

  # ${!a_ussvfhnc_var_name}="${a_ussvfhnc_str//$a_ussvfhnc_filter/$a_ussvfhnc_replace}"
  printf -v "$a_ussvfhnc_var_name" '%s' "${a_ussvfhnc_str//$a_ussvfhnc_filter/$a_ussvfhnc_replace}"
}

##
# Gets all unique unordered combinations of given string values.
#
# See https://codereview.stackexchange.com/questions/7001/generating-all-combinations-of-an-array_dict
# + https://stackoverflow.com/a/23653825
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var str_subsequences
#
# @param 1 String : space-separated values.
# @param 2 [optional] String : concatenation separator. Defaults to '' (empty).
# @param 3 [optional] String : separator between items. Defaults to space.
#
# @example
#   f_str_subsequences "a b c d"
#   echo "$str_subsequences" # a ab abc abcd abd ac acd ad b bc bcd bd c cd d
#
#   # Custom concatenation character.
#   f_str_subsequences "a b c d" '.'
#   for i in $str_subsequences; do
#     echo "$i" # Ex: a.b.c.d
#   done
#
f_str_subsequences() {
  local a_values="$1"
  local a_concatenation="$2"
  local a_separator="$3"

  if [[ -z "$a_separator" ]]; then
    a_separator=' '
  fi

  str_subsequences=''

  _u_str_subsequences_inner_recursion() {
    local a_prefix="$1"
    local a_inner_values="$2"

    local i
    local concat="$a_concatenation"

    if [[ -z "$a_prefix" ]]; then
      concat=""
    fi

    for i in $a_inner_values; do
      str_subsequences+="${a_prefix}${concat}${i}${a_separator}"
      _u_str_subsequences_inner_recursion "${a_prefix}${concat}${i}" "${a_inner_values#*$i}"
    done
  }

  _u_str_subsequences_inner_recursion '' "$a_values"

  unset -f _u_str_subsequences_inner_recursion
}

##
# Transforms an existing variable named $lowercase in calling scope to lowercase.
#
# @requires Bash 4+ (MacOS needs manual update).
# See https://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash
#
# @example
#   lowercase=''
#   f_str_lowercase 'MY_STRING'
#   echo "$lowercase" # Outputs 'my_string'
#
#   # Using custom variable name :
#   my_custom_var_name=''
#   f_str_lowercase 'MY_STRING' my_custom_var_name
#   echo "$my_custom_var_name" # Outputs 'my_string'
#
f_str_lowercase() {
  local a_input="$1"
  local a_str_lowercase_var_name="$2"

  if [[ -z "$a_str_lowercase_var_name" ]]; then
    a_str_lowercase_var_name='lowercase'
  fi

  printf -v "$a_str_lowercase_var_name" '%s' "${a_input,,}"
}

##
# Transforms an existing variable named $uppercase in calling scope to uppercase.
#
# @requires Bash 4+ (MacOS needs manual update).
# See https://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash
#
# @example
#   uppercase=''
#   f_str_uppercase 'my_string'
#   echo "$uppercase" # Outputs 'MY_STRING'
#
#   # Using custom variable name :
#   my_custom_var_name=''
#   f_str_uppercase 'my_string' my_custom_var_name
#   echo "$my_custom_var_name" # Outputs 'MY_STRING'
#
f_str_uppercase() {
  local a_input="$1"
  local a_str_uppercase_var_name="$2"

  if [[ -z "$a_str_uppercase_var_name" ]]; then
    a_str_uppercase_var_name='uppercase'
  fi

  printf -v "$a_str_uppercase_var_name" '%s' "${a_input^^}"
}

##
# Joins space-separated items by given separator.
#
# This function writes its result in the following variable in calling scope :
# @var joined_str
#
# @param 1 String : separator.
# @param ... String : values to join.
#
# @see https://stackoverflow.com/a/23673883
# @see https://stackoverflow.com/a/17841619
#
# @example
#   # Do not use quotes around the string argument
#   joined_str=''
#   input_str='one two three four five'
#   f_str_join ', and ' $input_str
#   echo "$joined_str" # <- outputs 'one, and two, and three, and four, and five'
#
#   # Works with arrays too :
#   joined_str=''
#   a=( one two "three three" four five )
#   f_str_join '|' "${a[@]}"
#   echo "$joined_str" # <- outputs 'one|two|three three|four|five'
#
#   # Update Debian 12 : need to escape characters like '&' in separator :
#   joined_str=''
#   input_str='one two three four five'
#   f_str_join ' \&\& ' $input_str
#   echo "$joined_str" # <- outputs 'one && two && three && four && five'
#
f_str_join() {
  local a_sep=$1
  local IFS=
  if [[ -z "$a_sep" ]]; then
    a_sep='|'
  fi
  joined_str=$2
  shift 2 || shift $(($#))
  joined_str+="${*/#/$a_sep}"
}

##
# Escapes all slashes for use in 'sed' calls.
#
# @param 1 String : value to escape.
# @param 2 [optional] String : output var name (default: sed_escaped).
#
# @see f_fs_change_line()
#
# @example
#   f_str_sed_escape "A string with commas, and dots... !" 'my_var'
#   echo "$my_var" # Outputs "A string with commas\, and dots\.\.\. !"
#
f_str_sed_escape() {
  local a_str="$1"
  local a_output_var_name="${2:-sed_escaped}"

  a_str="${a_str//,/\\,}"
  a_str="${a_str//\./\\\.}"
  a_str="${a_str//\*/\\\*}"
  a_str="${a_str//\//\\\/}"

  printf -v "$a_output_var_name" '%s' "$a_str"
}

##
# Appends a given value to a string only once.
#
# @param 1 String : the value to append.
# @param 2 String : to which str to append that value to.
# @param 3 [optional] String : output var name (default: str_append_once).
#
# @example
#   str='Foo bar'
#   f_str_append_once '--test A' "$str" 'str' # str='Foo bar--test A'
#   f_str_append_once '--test A' "$str" 'str' # (unchanged)
#   f_str_append_once '--test B' "$str" 'str' # str='Foo bar--test A--test B'
#
f_str_append_once() {
  local a_needle="$1"
  local a_haystack="$2"
  local a_output_var_name="${3:-str_append_once}"

  local result

  if [[ -z "$a_haystack" ]]; then
    result="$a_needle"
  elif [[ "$a_haystack" != *"$a_needle"* ]]; then
    result="${a_haystack}${a_needle}"
  else
    result="$a_haystack"
  fi

  printf -v "$a_output_var_name" '%s' "$result"
}

##
# Splits a string given a 1-character long separator.
#
# @param 1 The variable name that will contain the array of substrings (in calling scope).
# @param 2 String to split.
# @param 3 String : separator that must be 1 character long.
#
# @example
#   f_str_split1 'MY_VAR_NAME' "the,string" ','
#   for substr in "${MY_VAR_NAME[@]}"; do
#     echo "$substr"
#   done
#
f_str_split1() {
  local a_str_split1_var_name="$1"
  local a_str="$2"
  local a_sep="$3"

  f_str_sanitize_var_name "$a_str_split1_var_name" 'a_str_split1_var_name'

  # See https://stackoverflow.com/a/41059855
  eval "${a_str_split1_var_name}=()"

  # See https://stackoverflow.com/a/45201229 (#7)
  while read -rd"$a_sep"; do
    eval "${a_str_split1_var_name}+=(\"$REPLY\")"
  done <<<"${a_str}${a_sep}"
}

##
# Generates a random string.
#
# TODO [evol] optimize this.
#
# @param 1 [optional] Integer : string length - default : 16.
#
# @example
#   RANDOM_STR=$(f_str_random)
#
f_str_random() {
  local l="16"

  if [[ -n "${1}" ]]; then
    l="${1}"
  fi

  < /dev/urandom tr -dc A-Za-z0-9 | head -c$l; echo
}

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
  local a_str="$1"
  local a_sep="${2:--}"
  local a_output_var_name="${3:-slug_val}"
  local result=''
  local pending_sep=0
  local i c

  f_str_sanitize_var_name "$a_output_var_name" 'a_output_var_name'

  for ((i = 0; i < ${#a_str}; i++)); do
    c="${a_str:i:1}"

    case "$c" in
      '~' | '^') continue ;;
    esac

    f_transliterate_char "$c"

    if [[ -n "$transliterated_char" ]]; then
      result+="$transliterated_char"
      pending_sep=0
    elif [[ -n "$a_sep" && -n "$result" && pending_sep -eq 0 ]]; then
      result+="$a_sep"
      pending_sep=1
    fi
  done

  if [[ -n "$a_sep" && -n "$result" ]]; then
    while [[ "$result" == "$a_sep"* ]]; do
      result="${result#"$a_sep"}"
    done
    while [[ "$result" == *"$a_sep" ]]; do
      result="${result%"$a_sep"}"
    done
  fi

  printf -v "$a_output_var_name" '%s' "$result"
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

##
# Removes leading and trailing white space.
#
# See https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
#
# @param 1 String : the string to trim.
# @param 2 [optional] String : output var name (default: str_trimmed).
#
# @example
#   f_str_trim " testing space trim " 'str_trimmed'
#   echo "str_trimmed = '$str_trimmed'"
#
f_str_trim() {
  local result="$1"
  local a_output_var_name="${2:-str_trimmed}"

  result="${result%"${result##*[![:space:]]}"}"
  result="${result#"${result%%[![:space:]]*}"}"

  printf -v "$a_output_var_name" '%s' "$result"
}
