#!/usr/bin/env bash

##
# Bootstraps ASC.
#
# Loads includes containing bash functions along with readonly global vars if
# available, initializes "primitives" for hooks and lookups (ASC extension
# mecanisms), and call 'bootstrap' hook (i.e. to load bash aliases).
#
# @example
#   . asc/bootstrap.sh
#

# Make sure bootstrap runs only once in current shell scope.
if [[ $ASC_BS_FLAG -ne 1 ]]; then
  ASC_BS_FLAG=1

  # Include ASC core utilities.
  . asc/utilities/array.sh
  . asc/utilities/autoload.sh
  . asc/utilities/asc.sh
  . asc/utilities/fs.sh
  . asc/utilities/global.sh
  . asc/utilities/hook.sh
  . asc/utilities/once.sh # TODO remove or make opt-in.
  . asc/utilities/registry.sh # TODO remove or make opt-in.
  . asc/utilities/string.sh

  # If stack init was run at least once, automatically load global env vars.
  # NB : this must happen before u_asc_extend() gets called because it uses the
  # customizable global var PROJECT_SCRIPTS to populate primitive values.
  if [ -f "asc/env/current/global.vars.sh" ]; then
    . asc/env/current/global.vars.sh
  fi

  # Initializes "primitives" for hooks and lookups (ASC extension mecanisms).
  # These are : subjects, actions, prefixes, variants and extensions.
  u_asc_extend

  # Load additional includes (including extensions').
  if [[ -n "$ASC_INC" ]]; then
    for file in $ASC_INC; do
      # Any additional include may be overridden.
      u_autoload_override "$file" 'continue'
      eval "$inc_override_evaled_code"

      . "$file"

      # Any additional include may be altered using the 'complement' pattern.
      u_autoload_get_complement "$file"
    done
  fi

  # Bash aliases should be loaded by implementing the 'bootstrap' action hook.
  # NB: aliases are not expanded when the shell is not interactive, unless the
  # expand_aliases shell option is set using shopt.
  # See https://unix.stackexchange.com/a/1498
  shopt -s expand_aliases
  hook -a 'bootstrap'
fi
