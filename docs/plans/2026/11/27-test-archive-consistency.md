# Test archive: summary paths, readers, distinct batch keys

Status: draft

Make full and partial test result archives consistent: one summary contract for
every reader, create batch directories before writing `output.txt`, give batches
distinct keys, keep archive self-tests inside their fixture directory, and
record **per-case statuses** that match case-level evidence (not aggregate
failure assigned to the last case). This plan describes proposed work; it does
not claim implementation or authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions (what and why). This plan owns steps and acceptance for
the archive work.

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
| Wrong per-case statuses | The real batch runner archived a failing first shUnit2 case as PASS and a passing second case as FAIL; the parser assigned the aggregate failure to the last case |
| Shared summary risk | A shared summary path would preserve those incorrect values across partial runs |
| Skip evidence insufficient | Two shUnit2 runs that skipped different cases produced identical capture, including `OK (skipped=1)`; aggregate skip counts do not identify which case skipped |

## Work

1. Choose one summary location; update writer, partial loader, **and**
   `f_test_results_case_status` together.
2. Create the batch directory before opening `output.txt`.
3. Give batches **distinct keys** (not only the directory basename) so ASC core
   and extension `core` suites do not clobber each other.
4. Fix status parsing so each archived case status is derived from **that
   case’s evidence**, not from a suite-level aggregate applied to the last
   case. A failing first case and a passing second case must archive as FAIL
   then PASS (and the reverse).
5. **Skipped cases — evidence contract (decision):** the current capture cannot
   always prove which case skipped. Prefer **recording an explicit unknown /
   insufficient status** when case-level evidence cannot attribute PASS, FAIL,
   or SKIP, rather than inventing a status from suite aggregates. Optionally
   add richer per-case capture later; do not claim SKIP for a specific case
   unless the capture identifies that case. Implement that decision in the
   writer and readers together.
6. Update the archive self-test helper include and path assertions to match.
7. **Fixture isolation:** route all archive self-test writes through
   `test_results_self_tmp` (or an equivalent temp root). Fix `_u_archived_status`
   so it does not rely on an unset outer `batch_dir` and never creates paths
   like `/plain-ok`.
8. **Frozen fallback decision:** the writer currently removes
   `data/test/frozen/${slug}.txt` when regenerating results. Decide explicitly
   whether regenerated results should keep removing that frozen fallback, keep
   it, or only remove it when the new summary is complete — and assert the
   chosen behavior so partial runs cannot resurrect stale frozen PASS/FAIL
   values that contradict the new summary.
9. **Legacy summary first-run policy (decision):** summaries written by the old
   parser can carry falsely attributed PASS/FAIL into a partial merge. On first
   load of a summary that lacks new-rules provenance (or that was produced by
   the old attribution logic), **do not trust those statuses as PASS/FAIL/SKIP**:
   discard the legacy tree for that batch **or** import each legacy entry as
   unknown/insufficient. Prefer discard-or-unknown over preserving a false
   PASS. After that first-run policy runs, partial merges must preserve
   **valid** results written under the new evidence rules.

## Acceptance

- Full run followed by partial run keeps earlier cases in the merged summary
  when those cases were written under the new rules.
- Two batches with the same basename get distinct archives.
- `f_test_results_case_status` reads the same summary the writer produces.
- **Mixed fail/pass suite:** at least one acceptance case with a failing first
  shUnit2 test and a passing second (and preferably the reverse) where each
  **recorded** status is supported by case-level evidence in the capture /
  archive (not merely the batch exit code).
- **Mixed skip/pass suite:** alongside fail/pass, exercise a suite where one
  case skips and another passes. Where the capture cannot identify which case
  skipped, recorded statuses follow the unknown/insufficient contract from
  Work item 5 (do not assign SKIP to the wrong case from `skipped=1` alone).
- **Legacy summary seed:** acceptance seeds a generated summary with an old,
  falsely attributed PASS; a partial run under the new rules must apply the
  first-run policy (discard or unknown) and must **not** keep that false PASS
  as a trusted result. A later partial merge of valid new-rules results still
  preserves those valid entries.
- Shared or reused summary paths must not preserve incorrect statuses across
  partial runs.
- Frozen-fallback behavior matches the decision in Work item 8 and is covered
  by a fixture when regeneration interacts with an existing frozen file.
- Archive self-test passes under the new contract **and** creates no directories
  outside the suite fixture temp root.

## Order

Independent of remote and cron plans; useful before trusting archived suite
results as a gate.
