# Test archive: summary paths, readers, distinct batch keys

Status: draft

Make full and partial test result archives consistent: one summary contract for
every reader, create batch directories before writing `output.txt`, give batches
distinct keys, and keep archive self-tests inside their fixture directory. This
plan describes proposed work; it does not claim implementation or authorize
commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) is the
source of truth.

**Out of scope:** other ASC project instance compatibility.

## Observed breaks (reviewed revision `5dc602b`)

In `asc/test/test.opt-inc.sh` and `asc/test/core/test_results.test.sh`:

| Issue | Evidence |
| --- | --- |
| `output.txt` before parent dir | `f_test_results_batch_begin` opens `data/test/result/${slug}/output.txt` before creating that batch subdirectory |
| Summary path mismatch | Partial begin reads `…/${slug}/summary.yml` (and `.txt`); `f_test_results_batch_end` writes `data/test/result/${slug}.yml` |
| Status lookup stale path | `f_test_results_case_status` also reads `data/test/result/${slug}.yml` (then frozen fallback) |
| Dropped earlier cases | Full run then partial run never reloads the written summary |
| Colliding batch keys | `test_results_slug="${p_dir##*/}"` — ASC core and extension batches both named `core` share one archive |
| Self-test escapes fixture | Suite creates `test_results_self_tmp`, but archive helpers bypass it. `_u_archived_status` builds a path from an unset local `batch_dir`, so the test attempts to create `/plain-ok` and similar directories at the filesystem root |

## Work

1. Choose one summary location; update writer, partial loader, **and**
   `f_test_results_case_status` together.
2. Create the batch directory before opening `output.txt`.
3. Give batches **distinct keys** (not only the directory basename) so ASC core
   and extension `core` suites do not clobber each other.
4. Update the archive self-test helper include and path assertions to match.
5. **Fixture isolation:** route all archive self-test writes through
   `test_results_self_tmp` (or an equivalent temp root). Fix `_u_archived_status`
   so it does not rely on an unset outer `batch_dir` and never creates paths
   like `/plain-ok`.

## Acceptance

- Full run followed by partial run keeps earlier cases in the merged summary.
- Two batches with the same basename get distinct archives.
- `f_test_results_case_status` reads the same summary the writer produces.
- Archive self-test passes under the new contract **and** creates no directories
  outside the suite fixture temp root.

## Order

Independent of remote and cron plans; useful before trusting archived suite
results as a gate.
