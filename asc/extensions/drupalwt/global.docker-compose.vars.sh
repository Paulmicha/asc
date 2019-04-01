#!/usr/bin/env bash

##
# Global (env) vars for drupalwt extension provisionned using docker-compose.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see u_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# Default aliases need container names for php and database containers.
# @see asc/extensions/drupalwt/asc/bootstrap.docker-compose.hook.sh
# Redis container name is also necessary for default Drupal settings.
# @see asc/extensions/drupalwt/app/drupal_settings.7.tpl.php
global DWT_PHP_SNAME "[default]=php"
global DWT_DB_SNAME "[default]=mariadb"
global DWT_REDIS_SNAME "[default]=redis"
