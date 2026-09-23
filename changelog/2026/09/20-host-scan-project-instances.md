# Catalog ASC project instances on the current host

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | proposed, **later**. No code. Not in the 2026-09-19 lazy-include order. Not in the [meadows review loop](./20-meadows-plan-review-feedback-loop.md). Prefer after fs/db (and host keep-vs-move) so this entry point does not fight Wave C. |
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

**Caller:** `asc/instance/discover.sh` → `make instance-discover` (amended 2026-09-22; earlier draft said `asc/host/scan.sh`). Work stays in that script (write_globals shape). Do **not** add `instance.opt-inc.sh` / `host.opt-inc.sh` unless a second caller appears. Do **not** use `host/vitals.sh`. Do **not** invent `asc/host/scan.sh` in parallel.

**Storage:** existing **host** registry (`f_host_registry_*` → `file_registry` host hooks), not instance registry. Catalog is host-scoped even though the pivot lives under `instance/` (this tree’s discover/list family). Default path today is `FILE_REGISTRY_HOST_LEVEL_PATH` (`/opt/asc-registry` if unset) — may need sudo; prefer a writable host path already used on this machine, or document that `make instance-discover` must see that global. One key (or a small key family) for the instance list, not a new loader.

`make setup` / `init` may upsert **this** `$PROJECT_DOCROOT` so a tree that never ran discover is still findable only on a later `instance-discover`.

---

## `asc/instance/discover.sh` (detail, no code)

**Exists today:** no. Plan only.

**Args (v1):** optional `--root <dir>` (repeatable). Default root: `$HOME`. Reject `/`. Skip dirnames: `node_modules`, `.git`, `vendor` (composer/php), `asc/vendor`.

**Algorithm:**

1. For each root, `find` depth-bounded (ask before raising; start depth 4 from `$HOME`) for `asc/bootstrap.sh`.
2. Candidate docroot = parent of that `asc/`.
3. For each hit, read identity without full bootstrap when possible: `HOST_TYPE` / `INSTANCE_TYPE` / `STACK_VERSION` from that tree’s `env.yml` via existing yaml helpers if cheap; else record path only and leave globals empty.
4. Upsert host registry key family `asc_project_instances` (exact slug TBD at implement time — one key with newline-separated paths is enough for v1).
5. Print paths one per line on stdout (scriptable). No start/sync/manage of siblings.

**LAN hardware:** v1 is local filesystem only. A later pass may accept extra roots that are already mounted (NFS/sshfs). Do not invent network discovery here.

**Tests (when implemented):** two fake docroots under a temp scan root; only the one with `asc/bootstrap.sh` is listed; no write into this git tree; no `/opt` required when `FILE_REGISTRY_HOST_LEVEL_PATH` points at a temp dir.

---

## Tests

- Fixture: two fake docroots under a temp scan root, one with `asc/bootstrap.sh`, one without. `instance-discover` limited to that root lists one path.
- Does not require `/opt`. Does not write into this git tree.
- `make list-extensions` unchanged (instance, not host).

---

## Open tasks

- [x] Detail plan for `asc/instance/discover.sh` (2026-09-22). No code. Amends earlier `host/scan.sh` name.
- [ ] Writable host-registry path is proposed in [22-xdg-state-store.md](./22-xdg-state-store.md) (`$HOME/.local/state/asc/registry`). Still open until that plan is accepted. No new global.
- [ ] Add `asc/instance/discover.sh` + `make instance-discover`; upsert this instance on init optional v1.
- [ ] After lazy-include: if `f_host_registry_*` left eager `host.inc.sh`, this script still works; if they moved, `.` the mirrored opt-inc (same path rule as the meadows file).
