# Git-ignored local environment files

The files contained in this directory are automatically generated and git-ignored. They should not be edited manually.

ASC generates by default the following files during **instance init**:

- `global.vars.sh` — readonly global values for the current local instance (sourced on every bootstrap)
- `pivots.mk` — make shortcuts for discovered subject/action entry points (and per-case test targets)
- `cache/` — lookup only (`core/active.sh` + stamp, `hook/`, `pivots.sh`, `test-cases.sh`, `entities/`). Not `global.vars.sh` / `pivots.mk`.

Extensions may also use this folder for instance-specific generated code (e.g. registry files under `registry/`).

See `u_instance_init()` in `asc/instance/instance.inc.sh` and [docs/asc/globals.md](../../docs/asc/globals.md).
