---
description: Tests must follow the expected filesystem structure and handle exit codes properly.
globs: '*.sh'
---

# Anti-pattern example (don't)

## Non-standard test scripts and paths

Never create tests outside of ASC extension points, e.g. :

- ❌ `toto/test/foo.sh`
- ❌ `scripts/tests/foobar.test.sh`

## Omit exit codes

Never omit exit codes in tests entry points, e.g. :

```sh
#!/usr/bin/env bash

##
# Foobar test-foobar suite.
#
# @example
#   make test-foobar
#   Or :
#   scripts/asc/extend/test/foobar.sh
#

. asc/bootstrap.sh

f_test_batch_exec 'scripts/asc/extend/test/foobar'
```

# Correct example (do)

## Low-level ("kernel") tests are plugged in `make test-core` using hook implementations

Instead of creating new test entry points, we can choose the ASC core hook implementation. These test suites are reserved for quick low-level tests, e.g. :

- `scripts/asc/contrib/foo/bar/test/core.hook.sh`
- `scripts/asc/contrib/foo/bar/test/core/bar.test.sh`
- `scripts/asc/contrib/foo/bar/test/core/foo.test.sh`
- etc.

## Extension-specific tests

Any extension, including ASC core's, declares tests like for example `scripts/asc/contrib/foo/bar` :

- `scripts/asc/contrib/foo/bar/test/toto.sh`
- `scripts/asc/contrib/foo/bar/test/toto/foobar.test.sh`
- etc.

## Project-specific custom tests

- `scripts/asc/extend/test/toto.sh`
- `scripts/asc/extend/test/toto/foobar.test.sh`
- etc.

## Exit codes forwarding

```sh
#!/usr/bin/env bash

##
# Foobar test-foobar suite.
#
# @example
#   make test-foobar
#   Or :
#   scripts/asc/extend/test/foobar.sh
#

. asc/bootstrap.sh

f_test_batch_exec 'scripts/asc/extend/test/foobar' || exit $?
```
