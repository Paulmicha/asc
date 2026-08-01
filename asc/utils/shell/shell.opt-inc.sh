#!/usr/bin/env bash

##
# Bash shell utilities.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#

##
# Gets current user name even if sudoing.
#
# See https://stackoverflow.com/questions/1629605/getting-user-inside-shell-script-when-running-with-sudo
#
f_print_current_user() {
  logname 2>/dev/null || echo "$SUDO_USER"
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
  local a_service="$1"
  local a_command="$2"
  local a_max_try=$3
  local a_wait_seconds=$4
  local a_delay_seconds=$5

  local started=0

  # Temporarily set the flag to exit immediately if a command exits with a
  # non-zero status.
  set -e

  if [[ -z "$a_max_try" ]]; then
    a_max_try=10
  fi
  if [[ -z "$a_wait_seconds" ]]; then
    a_wait_seconds=2
  fi
  if [[ -z "$a_delay_seconds" ]]; then
    a_delay_seconds=0
  fi

  if [[ $a_delay_seconds -ge 1 ]]; then
    sleep "${a_delay_seconds}"
  fi

  for i in $(seq 1 "${a_max_try}"); do
    if eval "${a_command}"; then
      started=1
      break
    fi
    echo "Waiting for ${a_service} to start..."
    sleep "${a_wait_seconds}"
  done

  if [[ $started -eq 0 ]]; then
    echo
    echo "Notice : wait_for(${a_service}) has not responded after $a_max_try tries of ${a_wait_seconds}s."
    echo
  else
    echo "${a_service} has started!"
  fi

  # Unset temporary flag to exit immediately if a command exits with a non-zero
  # status.
  set +e
}
