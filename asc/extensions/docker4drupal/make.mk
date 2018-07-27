
##
# Custom Makefile include.
#
# This file is included in the Makefile from project docroot once instance init
# has generated an .env file.
#
# @see asc/extensions/docker4drupal/global.vars.sh
# @see Makefile
# @see .env
#

.PHONY: drush
drush:
	@ asc/extensions/docker4drupal/cli/drush.make.sh $(filter-out $@,$(MAKECMDGOALS))

.PHONY: drupal
drupal:
	@ asc/extensions/docker4drupal/cli/drupal.make.sh $(filter-out $@,$(MAKECMDGOALS))
