#!/usr/bin/env bash

##
# Convenience 'make' shortcut : composer.
#
# Depends on composer (or an alias) being operational on current instance.
#
# @see asc/extensions/drupalwt/make.mk
#
# @example
#   make composer update nothing
#   # Or :
#   asc/extensions/drupalwt/instance/composer.sh update nothing
#

. asc/bootstrap.sh

composer $@
