
##
# Default ASC tasks.
#
# Uses a "call wrap" script as an entry point to any other ASC script.
#
# @see asc/make/make.wrap.sh
#
# It forwards escaped arguments to maintain the possibility to use values (in
# single quotes) with space, $, ", etc.
#
# Like :
# $ make drush ev '$test = "Hello Drupal php"; print $test;'
#
# @example
#   # Initialize current project instance = trigger "instance init" :
#   make
#   make init # <- Alternative call (the 'init' task is the default).
#
#   # Print lookup paths used for globals aggregation during instance init.
#   make globals-lp
#
#   # Print lookup paths for the ASC hook call :
#   # hook -s 'instance' -a 'stop' -v 'PROVISION_USING HOST_TYPE'
#   make hook-debug s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Print result of the "most specific" hook call variant :
#   make hook-debug ms s:instance a:stop v:PROVISION_USING HOST_TYPE
#
#   # Trigger "instance start" manually :
#   make hook s:instance a:start
#
#   # Print lookup paths for "instance start" using PROVISION_USING variant :
#   make hook-debug s:instance a:start v:PROVISION_USING
#   # Same but using more variants :
#   make hook-debug s:instance a:start v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#
#   # Run low-level ASC base-stack tests (core + enabled extensions) :
#   make test-asc
#

.PHONY: init init-debug setup hook hook-debug globals-lp debug

init:
	@ asc/make/make.wrap.sh asc/instance/init.sh $(MAKECMDGOALS)

init-debug:
	@ asc/make/make.wrap.sh asc/instance/init.sh $@ -d -r $(filter-out $@,$(MAKECMDGOALS))

setup:
	@ asc/make/make.wrap.sh asc/instance/setup.sh $(MAKECMDGOALS)

hook:
	@ asc/make/make.wrap.sh asc/instance/hook.make.sh $(MAKECMDGOALS)

hook-debug:
	@ asc/make/make.wrap.sh asc/instance/hook.make.sh $@ -d -t $(filter-out $@,$(MAKECMDGOALS))

globals-lp:
	@ asc/make/make.wrap.sh asc/env/global_lookup_paths.make.sh $(MAKECMDGOALS)

debug:
	@ echo "debug MAKECMDGOALS (escaped) = $(MAKECMDGOALS)";
	@ asc/make/make.wrap.sh asc/make/echo.make.sh $(MAKECMDGOALS)
