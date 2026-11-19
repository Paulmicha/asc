
##
# Default ASC tasks.
#
# Uses a "call wrap" script as an entry point to any other ASC script.
#
# @see asc/make/call_wrap.make.sh
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
#   make test-core
#
#   # DSL (expression is never a Make goal — see ASC_DS_EXPR) :
#   ASC_DS_EXPR='slug(foobar)' make ds
#

.PHONY: init init-debug setup hook hook-debug globals-lp debug ds

# `make ds` must be the only goal. Companion goals (including `debug`) still run
# their own recipes and would see `ds` as a reserved MAKECMDGOALS value. Stray
# expression goals are refused here so they cannot be interpolated as shell.
# @see docs/specs/asc/dsl.md
# @see docs/plans/2026/09/22-make-ds.md
ifneq ($(filter ds,$(MAKECMDGOALS)),)
  asc_ds_other_goals := $(filter-out ds,$(MAKECMDGOALS))
  ifneq ($(asc_ds_other_goals),)
    $(error make ds: do not combine with other Make goals (refusing: $(asc_ds_other_goals)). Use: ASC_DS_EXPR='<expression>' make ds)
  endif
endif

init:
	@ asc/make/call_wrap.make.sh asc/instance/init.sh $(MAKECMDGOALS)

init-debug:
	@ asc/make/call_wrap.make.sh asc/instance/init.sh $@ -d -r $(filter-out $@,$(MAKECMDGOALS))

setup:
	@ asc/make/call_wrap.make.sh asc/instance/setup.sh $(MAKECMDGOALS)

# Expression from ASC_DS_EXPR only (not MAKECMDGOALS). @see asc/make/ds.make.sh
ds:
	@ asc/make/ds.make.sh

hook:
	@ asc/make/call_wrap.make.sh asc/make/hook.make.sh $(MAKECMDGOALS)

hook-debug:
	@ asc/make/call_wrap.make.sh asc/make/hook.make.sh $@ -d -t $(filter-out $@,$(MAKECMDGOALS))

globals-lp:
	@ asc/make/call_wrap.make.sh asc/core/global_lookup_paths.make.sh $(MAKECMDGOALS)

debug:
	@ echo "debug MAKECMDGOALS (escaped) = $(MAKECMDGOALS)";
	@ asc/make/call_wrap.make.sh asc/make/echo.make.sh $(MAKECMDGOALS)
