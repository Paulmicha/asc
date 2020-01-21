#!/usr/bin/env bash

##
# Implements hook -s 'asc' -a 'alias' -v 'PROVISION_USING'.
#
# Declares default bash aliases for current project instance using dwt.
#
# This file is dynamically included when the "hook" is triggered.
# @see asc/bootstrap.sh
#
# Uses the docker exec interactive flag from 'docker-compose' extension.
# @see asc/extensions/docker-compose/asc/pre_bootstrap.docker-compose.hook.sh
#

php_sname="${PHP_SNAME:=php}"
drupal_docroot="${SERVER_DOCROOT_C:=/var/www/html/web}"

alias php="docker-compose exec $DC_TTY $php_sname php"
alias composer="docker-compose exec $DC_TTY $php_sname composer"
alias drush="docker-compose exec $DC_TTY $php_sname drush --root=$drupal_docroot"
alias drupal="docker-compose exec $DC_TTY $php_sname ./vendor/drupal/console/bin/drupal --root=$drupal_docroot"
