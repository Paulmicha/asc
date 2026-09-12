# Rename `data/asc/generated.mk` to `data/asc/pivots.mk`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-12 |
| **Status** | implemented |
| **Scope** | ASC repo `/home/paul/Documents/asc` — generated Make include path and every reference to it. Same directory; not moved under `data/asc/cache/`. |
| **Related** | Root `Makefile`; `f_make_generate()` in `asc/make/make.inc.sh`; `asc/instance/setup.sh` / `uninit.sh`; `asc/test/core/bootstrap.test.sh`. Prior layout: [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md). |

---

## Context

The generated Make include is the list of discovered `$subject-$action` (and per-case test) targets. Calling it `generated.mk` only said it was generated. `pivots.mk` matches the ASC name for those entry points.

`make cc` still wipes lookup cache only. `pivots.mk` stays beside `global.vars.sh` under `data/asc/` and is rewritten by `make reinit`, wiped by `make uninit`.

## What changed

- Root Makefile `-include data/asc/pivots.mk`
- `f_make_generate()` writes `data/asc/pivots.mk` and removes a leftover `generated.mk`
- Setup / uninit purge lists include both names so an old file does not block setup
- Tests, README, and `data/asc/README.md` use the new name

## Safety

Gitignored instance file. After pull, run `make reinit` (or `make init`) so targets exist under the new include. `make cc` is unchanged.
