# Stub / gap inventory (garage note)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | garage note. Survey only. No deletes. No runtime. No README.md patch. |
| **Scope** | Misleading **enabled pivots that no-op**. Not a 200-row dump. Not a `gap` entity. |
| **Survey** | ~62 `bootstrap` + `#TODO` entry points; ~236 empty YAML. No `gap.entity.yml` / `gap.able.yml`. |
| **Related** | [20-gap-entity-not-core.md](./20-gap-entity-not-core.md); [20-two-include-kinds.md](./20-two-include-kinds.md); [20-host-scan-project-instances.md](./20-host-scan-project-instances.md); [10-begin-entity-system-with-remote-instances.md](./10-begin-entity-system-with-remote-instances.md) |

`$` in this file is the ASC docs placeholder (`$subject` / `$action` / `$extension`), not a shell variable.

---

Deprecate-first is **not** “every empty file.” It is a make `$subject-$action` that discovery already lists, that looks real, and that does nothing.

## Deprecate first (later — not this file)

| Path | Why | Risk |
|------|-----|------|
| `asc/host/vitals.sh` | Bootstrap + `#TODO`. Not host-scan. | `make host-vitals` boots the instance and exits. |
| `asc/yml/parse.sh`, `merge.sh`, `extend.sh` | Zero-byte. Parse already lives in eager `yml.inc.sh`. | `make yml-parse` / `yml-merge` / `yml-extend` look like YAML tools. |
| `asc/git/untrack.sh` | Zero-byte git action. | `make git-untrack` looks like it drops tracking. |
| `asc/host/dependency/{install,list,status,uninstall,update}.sh` | Zero-byte host `$object` pivots. Apt/software are the real surface. | `make host-dependency-*` looks like a package manager. |
| `asc/core/remote_extensions_download.sh` | Zero-byte download. | `make core-remote-extensions-download` looks like it fetches `$extension` trees. |

Do not fill these “for completeness.” Do not delete them in this note.

## Keep

- **Builder TODOs** — hydrate/build stay unfinished on purpose ([20-builder-kernel-subject.md](./20-builder-kernel-subject.md)).
- **host-scan** — `asc/host/scan.sh` is **absent**; that is the later plan, not a no-op pivot.
- **Entity Tasks 2+** — type/instance discover and cache generate stay in [10-begin-entity-system-with-remote-instances.md](./10-begin-entity-system-with-remote-instances.md). Task 1 load path is `data/asc/cache/entities/<type>/<id>.sh`.
- **Honest abstract hooks** — `db`, interaction, memory, rules as named placeholders (README already says so).
- **Ignored garage forests** — do not mass-delete ignored interaction / memory / rules trees or empty `*.able.yml` / `*.entity.yml` forests.

## Discovery workflow

1. Persist a survey in **changelog** (this file). Optional later **one-off** re-count. No inventory harness.
2. **Ask** before a loader, hook, wrapper, or global.
3. No `gap` entity in this tree ([20-gap-entity-not-core.md](./20-gap-entity-not-core.md)).
4. Two include kinds only: `*.inc.sh` (eager) and `*.opt-inc.sh` (lazy). No third suffix.
