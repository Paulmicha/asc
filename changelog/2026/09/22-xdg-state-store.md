# XDG state directory as a store

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | plan / review (**not** an implementation go-ahead) |
| **Scope** | Name the XDG state directory as one `store`, and use `$HOME/.local/state/asc/registry` as the shared host file-registry root. |
| **Not this plan** | Enabling `memory`. Filling `store-locate` or any other memory entry point. A new global. Growing `host-reg-set`. `instance-discover` (that stays [20-host-scan-project-instances.md](./20-host-scan-project-instances.md)). A sidecar under `data/entities/`. A README rewrite. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, which is the shell home directory.

No other changelog covers this. [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) still has the open question of a writable host-registry path. This file is that answer, still unaccepted.

---

## Pick

Two tokens already sit under `asc/extensions/memory`:

| Token | Role | On disk |
|-------|------|---------|
| `storage` | the kind of backend | `storage/storage.entity.yml`, `storage-detect`, `storage-list` |
| `store` | one named place of that kind, with a path | `store/store.entity.yml`, `store/store.able.yml`, `store-locate` and the other `store-*` entry points |

The XDG state directory is one `store`:

| Field | Value |
|-------|--------|
| kind | directory |
| path | `$HOME/.local/state` |

The ASC host registry is the narrower store inside it:

| Field | Value |
|-------|--------|
| kind | `file_registry` (the writer that is enabled today) |
| path | `$HOME/.local/state/asc/registry` |
| files | `$HOME/.local/state/asc/registry/host/.<key>.reg` |

That is the same layout as `/opt/asc-registry/host/.<key>.reg`. `f_host_registry_set` stays a one-string writer. `file_registry` keeps doing the write. The path is `FILE_REGISTRY_HOST_LEVEL_PATH`.

The path is a default on that host store, expanded to an absolute path when an instance inits. It is not a row in `data/entities/`. README defines `data/entities/` as concrete instances of **this** project instance. The state directory belongs to the user on this machine, and every instance under that user must share one path.

`$HOME/.local/state` is the XDG state directory (`$XDG_STATE_HOME` when unset). It already exists on this machine. The home git repo does not sync it. `mkdir` there needs no root.

---

## What exists

`memory` is listed in `.asc_extensions_ignore`, so discovery skips it. `store.entity.yml`, `store.able.yml`, and `storage.entity.yml` are empty. The same empty contract is also at `asc/data/store.able.yml`. Each memory script is `asc/bootstrap.sh` and a `# TODO`. There is no `*.hook.sh` in that extension.

When `memory` is enabled, entity discovery walks two levels under the extension, so those two `*.entity.yml` files would register as the types `store` and `storage`.

`file_registry` is enabled. Its default and the `:=` fallback in `f_file_registry_get_path` are still `/opt/asc-registry`. That directory is absent here. Home’s generated `data/asc/global.vars.sh` has the `/opt` value baked in until the next init.

README already says a field’s `storage` key references a specific store, and that `asc/extensions/memory/store/store.able.yml` holds the criteria for choosing a storage. The criteria file is 0 bytes.

---

## README gaps (recorded here, not edited)

Root `README.md` is the source of truth. These lines disagree with the tree:

- The memory blurb calls that extension hook placeholders. On disk the files are entry points.
- `store.able.yml` is cited as the assignment criteria. Both copies are empty.
- “All default extensions are disabled except `file_registry`” misses `builder` and `entity`, which are not in `.asc_extensions_ignore`.
- The `data/entities` section is still `TODO`, so README has no place for a directory that is shared by every instance on the machine.

A later README proposal can sit next to those lines. This plan does not add one.

---

## Later code, only after `go`

1. Change the `FILE_REGISTRY_HOST_LEVEL_PATH` default and the `:=` fallback in `f_file_registry_get_path` to `$HOME/.local/state/asc/registry`.
2. Reinit each instance that still has `/opt/asc-registry` baked in.

Leave the memory YAML and scripts empty. Leave `memory` disabled. Leave [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) as its own plan: it may upsert into this path once both notes are accepted.

---

## Open tasks

- [ ] Accept `store` / `storage` and the host-registry path `$HOME/.local/state/asc/registry`.
- [ ] After accept: change the `file_registry` default and fallback, then reinit instances that still point at `/opt/asc-registry`.
