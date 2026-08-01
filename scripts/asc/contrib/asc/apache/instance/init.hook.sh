#!/usr/bin/env bash

##
# Implements hook -a 'init' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
#

case "$ASC_APACHE_INIT_VHOST" in true)
  if i_am_su; then
    f_apache_write_vhost_conf
  else
    # TODO [evol] non-interactive shell environments need sudoers config in
    # place, as password prompts won't work.
    # See https://askubuntu.com/a/192062
    sudo f_apache_write_vhost_conf
  fi
  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to write Apache VHost for '$INSTANCE_DOMAIN'." >&2
    echo "Is $USER properly configured for sudo ?" >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
esac
