# Rename `asc/test/case.run.sh` to `asc/test/single_case.make.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-12 |
| **Status** | implemented |
| **Scope** | ASC repo `/home/paul/Documents/asc` — per-case test runner invoked by generated make targets. |
| **Related** | `f_make_generate_test_cases()` in `asc/make/make.inc.sh`; `asc/make/call_wrap.make.sh`; `asc/instance/fs_perms_set.hook.sh`. |

---

## Context

The runner is not a `$subject/$action` entry point. It is the real script behind generated per-case targets (`make test-browser-impersonation`, etc.). The `.make.sh` suffix matches other wrap-only scripts (`hook.make.sh`, `echo.make.sh`) and lets `fs_perms_set` pick it up via `*.make.sh` instead of a hardcoded extra path.

## What changed

- File renamed to `asc/test/single_case.make.sh`
- Generated `pivots.mk` / `cache/pivots.sh` now point at the new path
- Wrap still forwards the invoked make target as `$1` to this script
- Removed from the `fs_perms_set` extra exec list (`*.make.sh` covers it)

## Safety

After pull, run `make reinit` (or `make init`) so generated targets use the new path. Direct calls to `asc/test/case.run.sh` will 404.
