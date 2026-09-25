# Catalog ASC project instances on the current host

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | Path amended 2026-09-25. Stub is on disk at `asc/host/instance/discover.sh`. Body is still `# TODO`. Not a go to fill it. |
| **Scope** | From **this** `$PROJECT_DOCROOT`, list every ASC project instance on **this host** (sibling trees). Bounded find + upsert into the existing **host** `file_registry`. |
| **Not this plan** | Lazy `*.opt-inc.sh` / entry-point extraction. `host/vitals.sh` (empty TODO — do not fill). `remote_instance` (other hosts). Inventing `nested_instance` (README name, **not in this tree**). Cursor-memory / `asc-lightweight.mdc`. README matrix. Third loader. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

## Two axes (do not merge)

| Axis | Meaning | This plan |
|------|---------|-----------|
| Genealogy | This git repo is the source; instances copy or vendor `asc/` | **No.** Remotes already know that. Do not write the catalog into this repo. |
| Runtime on one host | N independent `$PROJECT_DOCROOT`, each with `asc/bootstrap.sh` | **Yes.** Any instance may list siblings. Catalog is **host-scoped**. |

`HOST_TYPE` stays a setup parameter. `f_host_os` / `f_host_ip` already exist; they are not this scan. `make list-extensions` sees only **this** instance.

Stay off the README non-goal “self-organizing all-orchestrating platform”: print/store paths and identity globals. Do not start, sync, or “manage” the other instances.

---

## Pick

**Bounded find + upsert.** Default root: `$HOME`. Extra roots only if already declared (reuse `FILE_REGISTRY_HOST_LEVEL_PATH` / `env.yml` — **ask before adding a global**).

A hit is `$dir/asc/bootstrap.sh` where `$dir` is the candidate `$PROJECT_DOCROOT`. Skip `node_modules`, `.git` objects, and other vendor dirnames. Do not `find /`.

**Caller:** `asc/host/instance/discover.sh` → `make host-instance-discover`. The 2026-09-22 amendment to `asc/instance/discover.sh` is withdrawn. `f_make_list_entry_points` strips a leading `instance-`, so that older path would be published as `make discover`. That name is too generic. `host/instance/discover` does not match the strip, so the pivot stays `host-instance-discover`. The stub on disk already names that pivot. Do **not** add `asc/instance/discover.sh` beside it. Do **not** add `instance.opt-inc.sh` / `host.opt-inc.sh` unless a second caller appears. Do **not** use `host/vitals.sh`. Do **not** invent `asc/host/scan.sh` in parallel.

**Storage:** existing **host** registry (`f_host_registry_*` → `file_registry` host hooks), not instance registry, and not a sidecar. Default path is `FILE_REGISTRY_HOST_LEVEL_PATH` (`$HOME/.local/state/asc/registry` since 2026-09-24). One key, newline-separated paths, is enough for v1.

`make setup` / `init` may upsert **this** `$PROJECT_DOCROOT` later, so a tree that never ran discover is still findable. Not part of filling the stub.

The README proposal under Workflow still names `asc/instance/discover.sh`. That sentence is stale. A human edits it. This plan does not.

---

## `asc/host/instance/discover.sh`

**Exists today:** stub. Bootstrap plus `# TODO`. The header example is already `make host-instance-discover`.

**Args (v1):** optional `--root <dir>` (repeatable). Default root: `$HOME`. Reject `/`.

**Walk (chosen 2026-09-25):** `find -P` (do not follow symlinks), `-maxdepth 6`, prune on hit.

A single depth from `$HOME` is an accident of folder count. Depth 4 reaches `Documents/<project>/asc/bootstrap.sh` (four names below `$HOME`) and misses `Documents/<group>/<stack>/asc/bootstrap.sh` (five names). Raising the number without stopping at a hit walks into every project’s `app/` and `vendor/`. Hardcoding client paths in the script is worse. Globs of `Documents/*` miss the instance whose docroot is `$HOME` itself. `-maxdepth 6` covers the five-name nest and one spare level.

1. For each root, `find -P` with `-maxdepth 6`. Never `-L`. A symlink to a large mount must not be walked.
2. Prune these directory names before descending: `node_modules`, `.git`, `vendor`, `.cache`, `.local`, `.npm`, `.cargo`, `.rustup`, `.cursor`.
3. Prune on hit: when a directory contains `asc/bootstrap.sh`, print that directory and do not descend into it. The printed path is the docroot. A second `asc/bootstrap.sh` inside that project is not a second instance.
4. `--root` is the escape hatch for a test fixture, a docroot deeper than 6, or a tree that is not under `$HOME`. It is not a list of client paths kept in the script.
5. Upsert host registry key `asc_project_instances` (one key, newline-separated paths).
6. Print those paths one per line on stdout. No start, sync, or manage of siblings.

Identity fields (`HOST_TYPE`, `INSTANCE_TYPE`, `STACK_VERSION`) may be read from that tree’s `env.yml` when the read is cheap. v1 may print the path only and leave them empty. Do not bootstrap the other tree.

**LAN hardware:** v1 is local filesystem only. A later pass may accept extra roots that are already mounted (NFS/sshfs). Do not invent network discovery here. No write into this git tree. No `/opt` required when `FILE_REGISTRY_HOST_LEVEL_PATH` points at a temp dir.

---

## Tests

- Fixture under a temp `--root`: one docroot at `<root>/shallow/asc/bootstrap.sh`, one at `<root>/group/stack/asc/bootstrap.sh`, one decoy at `<root>/shallow/app/asc/bootstrap.sh` (must not be listed; prune-on-hit), one decoy under `node_modules` (must not be listed). No symlink followed.
- Does not require `/opt`. Does not write into this git tree.
- `make list-extensions` unchanged (instance, not host).

---

## Open tasks

- [x] Detail plan for `asc/instance/discover.sh` (2026-09-22). Withdrawn 2026-09-25. That path would be `make discover`.
- [x] Writable host-registry path accepted in [22-xdg-state-store.md](./22-xdg-state-store.md): `$HOME/.local/state/asc/registry` (2026-09-24). No new global.
- [x] Path is `asc/host/instance/discover.sh`, pivot `host-instance-discover`. Stub is on disk. Walk is `find -P`, `-maxdepth 6`, prune on hit, repeatable `--root` (2026-09-25).
- [ ] Fill the stub body. Do not add `asc/instance/discover.sh`. Upsert on init stays optional and later.
- [ ] After lazy-include: if `f_host_registry_*` left eager `host.inc.sh`, this script still works; if they moved, `.` the mirrored opt-inc (same path rule as the meadows file).
