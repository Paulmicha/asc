
##
# ASC main Makefile.
#
# Make is used not as a compiling tool here. It provides memorable shortcuts.
# A wrapper script is used to forward arguments to ASC action scripts.
#
# By default, ASC will attempt to load the following includes if they exist, and
# silently fail if they don't.
#

# The default task will be "instance init", shortened to just "init".
# @see asc/make/default.mk
.DEFAULT_GOAL := init

# These files are automatically generated during instance init.
-include .env
-include data/asc/pivots.mk

# Project-specific tasks.
ifdef ASC_MAKE_INC
-include $(ASC_MAKE_INC)
endif
-include scripts/asc/extend/custom.mk

# Default ASC tasks.
-include asc/make/default.mk

# Automatically append arguments to tasks calls.
# @see https://stackoverflow.com/a/6273809/1826109
%:
	@:
