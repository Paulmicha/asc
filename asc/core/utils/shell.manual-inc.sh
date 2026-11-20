#!/usr/bin/env bash

##
# Bash shell utilities.
#
# This file is sourced during core ASC bootstrap.
# @see asc/core/utils.manual-inc.sh
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# ASC "exceptions" handling. Exits immediately.
#
# Mutable scoped env vars :
#
# @var LV : String : log level.
#   Defaults to 'error'.
#
# @var CODE : Integer : exit code.
#   Defaults to 1.
#
# @var HANDLER : String : arbitrary hook variant variable to differenciate how
#   to record (or not) the "exception".
#   Defaults to 'echo'.
#
# @var VARIANTS : String : space-separated hooks variants' variable names.
#   Defaults to 'LV HANDLER HOST_TYPE'.
#
# @var ARGS : String : all arguments passed (as string).
#   Defaults to "$@".
#
# The 'throw' action triggers a 'pre'-prefixed hook before triggering the
# normal (unprefixed) hook. Same after ('post'-prefixed hook).
#
# To list all the possible paths that can be used among which existing files_arr
# will be sourced when the hook is triggered, run (in this order) :
# $ make hook-debug s:instance p:pre a:throw v:LV HANDLER HOST_TYPE
# $ make hook-debug s:instance a:throw v:LV HANDLER HOST_TYPE
# $ make hook-debug s:instance p:post a:throw v:LV HANDLER HOST_TYPE
#
# @example
#   # Defaults to : echo "Hello world" >&2 ; exit 1
#   # @see
#   throw "Hello world"
#
throw() {
  export LV='error'
  export CODE=1
  export HANDLER='echo'
  export VARIANTS='LV HANDLER HOST_TYPE'
  export ARGS="$@"

  hook -s 'instance' -p 'pre' -a 'throw' -v "$VARIANTS"
  hook -s 'instance' -a 'throw' -v "$VARIANTS"
  hook -s 'instance' -p 'post' -a 'throw' -v "$VARIANTS"

  exit $CODE
}

##
# Gets current user name even if sudoing.
#
# See https://stackoverflow.com/questions/1629605/getting-user-inside-shell-script-when-running-with-sudo
#
# @param 1 [optional] String : output var name (default: print_current_user).
#
f_print_current_user() {
  local p_output_var_name="${1:-print_current_user}"
  local result

  result="$(logname 2>/dev/null || echo "$SUDO_USER")"
  printf -v "$p_output_var_name" '%s' "$result"
}

##
# Checks if current user is root (super user).
#
# See https://askubuntu.com/a/836092
#
# @example
#   if i_am_su; then
#     echo "I am root"
#   else
#     echo "I am not root"
#   fi
#
i_am_su() {
  ! ((${EUID:-0} || "$(id -u)"))
}

##
# Keep trying to call given command until it returns something.
#
# This function is adapted from a script from wodby/alpine Docker image :
# See https://github.com/wodby/alpine/blob/master/bin/wait_for
#
# Useful for containers like databases to wait until their service(s) are ready
# and/or accept connections. Examples :
# See https://github.com/wodby/docker4drupal/blob/master/tests/8/run.sh
# See https://github.com/wodby/mariadb/blob/master/10/bin/actions.mk
#
# @param 1 String : service name to check.
# @param 2 String : command to eval.
# @param 3 [optional] Integer : maximum number of retries.
#   Defaults to 24.
# @param 4 [optional] Integer : time to wait in seconds between retries.
#   Defaults to 2.
# @param 5 [optional] Integer : delay in seconds before beginning the checks.
#   Defaults to 0.
#
# @example
#   f_db_set
#   cmd=$(cat <<'EOF'
#     mysqladmin \
#       --user="$DB_ADMIN_USER" \
#       --password="$DB_ADMIN_PASS" \
#       --host="$DB_HOST" \
#       --port="$DB_PORT" \
#       status &> /dev/null
#   EOF
#   )
#   wait_for "MySQL" "$cmd"
#
wait_for() {
  local p_service="$1"
  local p_command="$2"
  local p_max_try=$3
  local p_wait_seconds=$4
  local p_delay_seconds=$5

  local started=0

  # Temporarily set the flag to exit immediately if a command exits with a
  # non-zero status.
  set -e

  if [[ -z "$p_max_try" ]]; then
    p_max_try=10
  fi
  if [[ -z "$p_wait_seconds" ]]; then
    p_wait_seconds=2
  fi
  if [[ -z "$p_delay_seconds" ]]; then
    p_delay_seconds=0
  fi

  if [[ $p_delay_seconds -ge 1 ]]; then
    sleep "${p_delay_seconds}"
  fi

  for i in $(seq 1 "${p_max_try}"); do
    if eval "${p_command}"; then
      started=1
      break
    fi
    echo "Waiting for ${p_service} to start..."
    sleep "${p_wait_seconds}"
  done

  if [[ $started -eq 0 ]]; then
    echo
    echo "Notice : wait_for(${p_service}) has not responded after $p_max_try tries of ${p_wait_seconds}s."
    echo
  else
    echo "${p_service} has started!"
  fi

  # Unset temporary flag to exit immediately if a command exits with a non-zero
  # status.
  set +e
}
