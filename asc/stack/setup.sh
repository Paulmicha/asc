#!/bin/bash

##
# Setup host-level dependencies.
#
# Run as root or sudo.
#
# Usage :
# $ . asc/stack/setup.sh
#

. asc/env/load.sh

. asc/git/apply_config.sh

# . asc/app/drupal_setup.sh
# . asc/stack/lamp_deb/cron_drupal_setup.sh
# . asc/stack/lamp_deb/vhost_create.sh $INSTANCE_DOMAIN $INSTANCE_ALIAS
# . asc/stack/lamp_deb/cron_apache_https_setup.sh


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
