#!/usr/bin/env bash

##
# TODO
#

. asc/bootstrap.sh

# TODO requires a preprocess step where a tree is built so that we can spot
# any places where dependencies are unnecessarily loaded in the global scope
# (everywhere asc bootstraps).
# Such tree could be a yml file, like :
# For each make entry point :
# Which subjects-actions paths use which functions VS no function among all the ones asc bootstrap loads.
# This represents an amont that can be keyed per tree path, which than can later be analyzed to only
# keep the minimum bash sourcing and readonly / .env vars necessary for like 80% of our current real use cases.

# This test file is for bash sourcing only.
# For the readonly / .env vars :
# @see asc/extensions/principle/test/asc/env_vars.test.sh
