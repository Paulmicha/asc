# Globals test: fixture-owned synonym

Status: completed

Unblock `make test-core` by giving the globals aggregation test a
fixture-owned `anti-pattern/code-smell` synonym. The synonym approach was
verified in a disposable checkout against `12d6a6b1` (all six globals tests
passed). The outcome is recorded below.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions; this plan owns steps and acceptance. Other ASC project
instance compatibility is out of scope.

## Context

`test_instance_init_aggregates_core_appends_once` in
`asc/test/core/global.test.sh` asserts that dry-run init output contains
`anti-pattern/code-smell` in `ASC_SYNONYMS`. The removed checker extension used
to declare that synonym. On the reviewed revision (`5dc602b`) both init
iterations fail and stop `make test-core`.

On `f00b7bc` the same six-test suite passed because checker still shipped the
synonym. That was a different extension set, not a weaker suite.

The suite already creates a temporary extension under
`asc/extensions/nftascgevdehnc/` in `oneTimeSetUp` (around line 78).

## Work

1. In the existing temporary extension’s `global.vars.sh` (or equivalent
   globals append the suite already sources), declare a fixture-owned
   `ASC_SYNONYMS` append of `anti-pattern/code-smell`.
2. Do not reintroduce the checker extension for this assertion.
3. Do not soft-delete or weaken the aggregation check.

## Acceptance

- Both iterations of `test_instance_init_aggregates_core_appends_once` pass.
- The rest of the globals suite still passes.
- `make test-core` no longer stops on the missing synonym (other failures may
  remain until sibling plans land).

## Order

Land first among the [review remediation items](../../../instance/review.md);
independent of remote, cron, and archive work.

## Implementation and verification (27 November)

The fixture now declares its own synonym. The six-test globals suite passes in an initialized disposable checkout.

The integrated `make test-core` passed in an initialized disposable checkout with the remote extension enabled. This was local fixture acceptance; no live remote, database, or host crontab operation was performed.
