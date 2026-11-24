# Restore ignore coverage for active ASC data paths

Status: draft

Commit `aee5a425` changed the mother `.gitignore` to use several new data paths
without moving all current producers. This plan records the resulting gap and
the proposed correction. It is not evidence that any generated data was staged
or exposed, and no remediation has been implemented by this document.

## Evidence

| Current path | Current producer or contract | Regression |
| --- | --- | --- |
| `data/logs/` | `asc/log/storage.hook.sh` and `asc/thread/thread.wrap.sh` | The new rule covers `data/log/`, not `data/logs/`. |
| `data/threads/` | `asc/thread/thread.inc.sh` and `asc/thread/thread.wrap.sh` | The new rule covers `data/thread/`, not `data/threads/`. |
| `data/db-dumps/` | `ASC_DB_DUMPS_DIR` in `asc/extensions/db/global.vars.sh` | The new rule covers `data/db/`; compressed dumps under the active default no longer match the removed directory rule. |
| `data/private/` | README private-files section and the Drupal contrib default | The previous directory exclusion was removed. |
| `data/files/` | Moodle contrib data defaults | The previous directory exclusion was removed. |

The same commit removed prior exclusions for `data/loops/`, `data/cronjobs/`
and the structured `data/changes/` tree. Inventory their remaining producers,
maintained README exceptions and intended tracking before choosing their final
rules; removal from `.gitignore` alone does not establish that a path is unused.
The pattern `*.sql` remains, but it does not cover compressed dumps or all
other files in these directories.

## Proposed work

1. Restore appropriate exclusions for the still-active paths above while
   preserving intentional tracked documentation and existing new-path rules.
   Retire an old-path exclusion only after every relevant producer and consumer
   has migrated and the tracking policy has been verified.
2. Review the other removed exclusions against current ASC and contrib usage,
   rather than treating either the old or new inventory as automatically
   authoritative. Document which paths are intended to be tracked, ignored or
   retained for compatibility.
3. Account for installation into an existing project: `asc/core/install.sh`
   preserves its `.gitignore` and writes a comparison copy. Specify a
   non-destructive and repeatable way to apply any required policy there; do not
   claim that the copied comparison file changes Git behavior.
4. Coordinate generated remote definitions with the separate
   [remote migration plan](24-deprecate-entity-related-abstractions.md), which
   must decide its own file ownership and instance-ignore mechanism.

## Acceptance

- In an isolated Git fixture, use `git check-ignore -v` against representative
  log, thread, compressed dump, private-file and contrib data paths. Verify each
  intended exclusion and confirm maintained README files and other explicitly
  trackable files remain visible.
- Check current and proposed paths separately, including representative files
  for the other removed exclusions once their policy is determined. Verify both
  positive and negative cases; an ignored parent can defeat a later exception.
- Test fresh installation and a project with its own `.gitignore` using the
  chosen instance policy, twice. Verify user-managed rules and project files are
  preserved, and inspect the actual Git decision rather than the comparison
  copy. Exercise linked worktrees if the policy changes repository-local Git
  exclusions.
- Check tracked files separately: ignore rules do not remove existing entries
  from Git's index. Do not delete or untrack data as part of this acceptance
  without a separately authorized, evidence-qualified scope.
- Record commands, results and any environment limitations. Configuration
  inspection and `git check-ignore` are evidence about matching rules, not
  evidence that no previously staged or committed data exists.
