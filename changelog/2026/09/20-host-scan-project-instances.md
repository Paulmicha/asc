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

**Caller:** `asc/host/scan.sh` → `make host-scan`. Work stays in that script (write_globals shape). Do **not** add `host.opt-inc.sh` unless a second caller appears. Do **not** use `host/vitals.sh`.

**Storage:** existing host registry (`f_host_registry_*` → `file_registry` host hooks). Default path today is `FILE_REGISTRY_HOST_LEVEL_PATH` (`/opt/asc-registry` if unset) — may need sudo; prefer a writable host path already used on this machine, or document that `make host-scan` must see that global. One key (or a small key family) for the instance list, not a new loader.

`make setup` / `init` may upsert **this** `$PROJECT_DOCROOT` so a tree that never ran init is still findable only on a later `host-scan`.

---

## Tests

- Fixture: two fake docroots under a temp scan root, one with `asc/bootstrap.sh`, one without. `host-scan` limited to that root lists one path.
- Does not require `/opt`. Does not write into this git tree.
- `make list-extensions` unchanged (instance, not host).

---

## Open tasks

- [ ] Confirm writable host-registry path (no new global unless asked).
- [ ] Add `asc/host/scan.sh` + `make host-scan`; upsert this instance on init optional v1.
- [ ] After lazy-include: if `f_host_registry_*` left eager `host.inc.sh`, this script still works; if they moved, `.` the mirrored opt-inc (same path rule as the meadows file).
