# Rename generated Make artifacts to `pivots.mk` / `pivots.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-12 |
| **Status** | implemented |
| **Scope** | ASC repo `/home/paul/Documents/asc` — generated Make include and wrap lookup cache. `pivots.mk` stays beside `global.vars.sh` (not under `cache/`). `pivots.sh` stays under `data/asc/cache/` (lookup; `make cc` wipes it). |
| **Related** | Root `Makefile`; `f_make_generate()` in `asc/make/make.inc.sh`; `asc/make/call_wrap.make.sh`; `asc/thread/thread.inc.sh`; `asc/instance/setup.sh` / `uninit.sh`; `asc/test/core/bootstrap.test.sh`. Prior layout: [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md). |

---

## Context

The generated Make include and wrap lookup list are the discovered `$subject-$action` (and per-case test) entry points. `generated.mk` / `cache/make.sh` only said they were generated. `pivots.mk` / `pivots.sh` match the ASC name for those entry points.

`make cc` still wipes lookup cache only. `pivots.mk` stays beside `global.vars.sh` under `data/asc/` and is rewritten by `make reinit`, wiped by `make uninit`. `pivots.sh` is rewritten at init and deleted by `cc`.

## What changed

- Root Makefile `-include data/asc/pivots.mk`
- `f_make_generate()` writes `data/asc/pivots.mk` and `data/asc/cache/pivots.sh`, and removes leftover `generated.mk` / `cache/make.sh`
- Wrap and thread runners source `data/asc/cache/pivots.sh`
- Setup / uninit purge lists include both old and new names so an old file does not block setup
- Tests, README, and `data/asc/README.md` use the new names

## Safety

Gitignored instance files. After pull, run `make reinit` (or `make init`) so targets and wrap lookup exist under the new names. `make cc` is unchanged (`pivots.sh` is lookup cache).
