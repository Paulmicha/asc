# ASC core concept : Performance optimization

Table of contents :

1. status and scope
1. measure first
1. file-tree growth (builder and make entry points)
1. RAM-backed filesystems (tmpfs / ramfs)
1. syncing RAM workspaces to durable disk
1. content and path search (ripgrep, fd, find)
1. nested instances on one host
1. preferred leverage order
1. open tasks

Working notes compiled from design discussion (2026-08). **Not implemented as product features** unless code or changelogs say otherwise. This page is living guidance for humans and agents when an instance tree, builder codegen, or multi-instance host becomes large.

Related living pages: [builder.md](builder.md), [organization.md](organization.md) (hooks, reinit, registry, nested layout), [wrappers.md](wrappers.md) § nested, [shell-usage.md](shell-usage.md).

---

## status and scope

| Fact | Detail |
|------|--------|
| Status | Design / guidance living doc |
| Runtime SoT | Behavior still comes from code + dated changelogs; this file does not invent entry points |
| Audience | Operators, agents, and implementers choosing scale levers |
| Out of scope here | App-level app benchmarks (PHP, Node, DB, Docker image layers), network bandwidth to remotes |

Two scale pressures recur in ASC design:

1. **One fat instance** — builder / extend / wrap / nest / agents materialize many files and dirs (including make-facing entry points).
2. **Many nested instances on one host** — e.g. under `Documents/`, each with its own bootstrap, caches, and discovery surface.

Levers fall into three families: **architecture** (fewer materializations, better caches), **storage placement** (where hot dirs live), and **search tools** (how humans/agents find things in big trees).

---

## measure first

Do not adopt RAM mounts or swap search tools for hot-path speed without evidence. Wall time for bootstrap, `$` entry points, and builder regen is often **CPU / process** bound (bash, subshells, fork) rather than disk.

Useful checks:

| Approach | Use for |
|----------|---------|
| `hyperfine 'make …'` / wall clocks | Before/after any change |
| `strace -c` on a representative `$` or regen | Whether `open`/`stat`/`getdents` dominate vs `clone`/`exec` |
| Sample under real load | Cold vs warm page cache; HDD / NFS vs local NVMe |

**Rule of thumb:** if process startup and script interpretation already consume most of the run, faster listing or RAM FS for the whole tree will not move the needle much.

---

## file-tree growth (builder and make entry points)

Builder (templates / blueprints / prototypes) and nestable agent workflows can **extend, wrap, and nest**, producing many discoverable paths. That grows:

1. **Directory walks** (make surfaces, autoload-style discovery, recursive listings).
2. **Create/delete churn** during codegen and cleanup.
3. **Stat storms** as tools and agents poke many paths.

### What already helps in ASC

| Mechanism | Role |
|-----------|------|
| Hook cache under `data/asc/cache/hook.*.sh` | Avoids re-resolving hook graphs every run when cache is warm |
| Explicit autoload / lookup path construction | Structured discovery vs grepping the whole tree for every hook |
| File registry / instance registry surfaces | Known paths instead of ad-hoc full-tree search |
| Nested list constrained by layout | e.g. nested ASC list under Documents at limited depth — not a host-wide recursive content search |

See [organization.md](organization.md) § hooks / (re)init / cache, and nested-instance / nested_asc entry points for layout listing vs virgin-env exec into a child docroot.

### Architectural wins that beat “faster FS search”

Prefer, in order, before throwing iron at the problem:

1. **Do not materialize every wrap/nest as a physical leaf** if runtime can resolve chain/nest via registry, DSL, or generated consolidated includes.
2. **Codegen into a dedicated generated root** (possibly ephemeral), not into the primary tracked source tree.
3. **Keep durability on the source of truth** (blueprints, templates, DSL, git) rather than every expanded make entry leaf.
4. **Ignore / prune generated paths** in human and agent searches (`.gitignore`, `rg` globs, find `-path` prune).

Fewer dentries reduce I/O, make discovery cost, and accidental full-tree tools—independent of tmpfs or ripgrep.

---

## RAM-backed filesystems (tmpfs / ramfs)

### tmpfs vs ramfs

| | **tmpfs** (preferred for experiments) | **ramfs** |
|--|----------------------------------------|-----------|
| Storage | RAM; may swap under pressure | RAM only; no swap |
| Size | Configurable limit | Grows until memory is exhausted (OOM risk) |
| Persistence | None across unmount/reboot | Same |
| Ops | Common for scratch, containers, `/dev/shm` | Rarely needed over tmpfs |

Neither provides durable POSIX journaling to disk by itself. Crashes or reboots lose unflushed state.

### When RAM-backed paths help

| Workload | Expected help |
|----------|----------------|
| Thousands of small creates/unlinks, readdir, `stat`, recursive walks | **Yes** — largest gains on HDD, NFS, busy shared disks |
| Aggressive regen (reinit-style, builder bulk stubs every session) | **Yes** if that phase is I/O-bound today |
| Parallel agents writing many small files on slow backing | **Yes** for the write-heavy phase |
| Cold tree, occasional `$`, files already in page cache | **Small / none** |
| Bootstrap dominated by sourcing, hooks, subshell fan-out | **Little** — wrong bottleneck |
| Git on a large tracked tree | **Mixed** — `.git` and index still want a durable home unless the whole worktree durability story is explicit |

### Rough magnitude (heuristic, not a guarantee)

- Many small-file writes on **slow disk**: often **2–10×** for that *phase* alone.
- Same workload on **good local NVMe**: often **~10–40%** or less for full reinit/make-style runs once CPU bounds appear.
- If shell/startup is **> ~70%** of wall time: RAM FS alone is usually **not user-visible**.

### What to put on tmpfs (scoped) vs whole instance

| Prefer | Avoid as default |
|--------|------------------|
| `data/asc/cache/` (or equivalent hot caches) | Entire project + `.git` only in RAM without a flush design |
| Builder **output / generated** stubs root | Mounting every nested instance root on ramfs “for free speed” |
| Agent sandbox / temporary override trees | Unbounded ramfs under multi-agent fan-out (memory blow-up) |

Full-instance RAM mounts raise: OOM under agent fan-out, silent loss on crash, awkward multi-process git, and sync storms that can cost more than they save under heavy writes.

### Builder-specific framing

Gains are **plausible for codegen + discovery** of many entry points, and **not automatic** for “more make targets forever.” Measure builder regen and post-regen `$` separately; optimize the phase that actually dominates.

---

## syncing RAM workspaces to durable disk

There is no widely used product that makes true tmpfs/ramfs **transparent durable storage** with full “every op to disk” semantics. Durable designs are composed.

### 1. Overlay: disk lower + RAM upper

```text
lowerdir = permanent tree on disk (typically read-only base)
upperdir = tmpfs (writes land here)
merged  = path agents and tools see
```

Flush / promote = copy upper into durable lower, or rebuild lower and remount. Same idea as live systems and container write layers.

- Kernel **overlayfs**
- Ubuntu **overlayroot** (root-focused variant of the idea)

### 2. Work on tmpfs, continuous or event sync

| Tool / pattern | Role |
|----------------|------|
| **[lsyncd](https://github.com/lsyncd/lsyncd)** | inotify (or platform watchers) → delayed **rsync**; classic “fast dir → durable dir” |
| **rsync** + systemd path/timer or **inotifywait** | Thinner DIY |
| **Unison** | Bidirectional; less “scratch → archive” |
| **csync2** / **Syncthing** | Multi-host; usually overkill for local scratch |

**Caveats:** crash window for unsynced writes; deletes propagate if configured that way; syncing into a live git worktree needs discipline (dirty races, partial trees). Prefer flush on lifecycle events when possible: end of reinit, blueprint “commit,” agent session end—not necessarily every `creat`.

### 3. Related but different technologies

| Tech | Why it is not the default answer |
|------|----------------------------------|
| FS-Cache / cachefilesd | Cache of networked FS, not local project design |
| bcache / bcachefs | Block-level cache layers |
| pmem / DAX research FS | Hardware path, not typical ASC host scratch |
| Docker `type=tmpfs` | Same as scoped tmpfs with orchestration |

### Practical ASC recommendation for RAM + durability

1. Prototype **only** builder output / cache paths on tmpfs.
2. Flush on explicit materialize/commit (and optional lsyncd if near-continuous disk mirrors are required).
3. Keep source-of-truth trees and git on durable disk unless a full overlay story is designed and tested for crashes and multi-process writers.

---

## content and path search (ripgrep, fd, find)

### What [ripgrep](https://github.com/BurntSushi/ripgrep) is

A fast **file-content** searcher (regex) with solid ignore/filtering, and optional file listing (`rg --files`). It is the right default for “search this pattern in many files” and is already used in ASC maintenance audits (nameref / subshell greps in changelogs).

It is **not**:

- A replacement for structured autoload / hook lookup.
- A general replacement for `find` metadata queries (`-newermt`, complex predicates, “sort by mtime”).
- A speed-up for hook cache hits or known-path `$` entry points.

### ASC hot path vs search tools

| Path | Tool that helps |
|------|-----------------|
| Hook resolve when `data/asc/cache/hook.*.sh` is warm | Cache hit — not rg |
| Constructed lookup levels (autoload) | Path construction — not rg |
| `utils/fs` list files/dirs, recent files (current `find`) | `find` / **[fd](https://github.com/sharkdp/fd)**; rg only loosely via `--files` |
| Nested instance **layout list** (bounded depth under Documents) | Structural discovery — not host-wide content search |
| Human/agent “where is this string / symbol?” | **rg** (significant vs `grep -r`) |
| Content audits across fat generated trees | **rg** with ignores for noise |

### Expected gains

| Job | Gain |
|-----|------|
| Content search vs recursive `grep -r` on large trees | **Large** (often many×) |
| Filenames only | **Some** vs naive walk+grep; **fd** or tight `find` often equal or better |
| Normal `$` / bootstrap / hook cache | **None** unless the call already greps contents |
| Host with many nested instances each doing normal make/hooks | **No free win** from installing rg alone |

### One fat instance vs many nested instances

**Fat instance (many generated files):**

- Full-tree content searches and naive walks get expensive.
- **rg helps** agent and human content search and inventories.
- **rg does little** for make surface size, bash sourcing, known-path stats, or leaf regeneration—those need fewer files, generated roots, and caches.

**Many nested instances:**

- Per-instance work stays local → rg is not an automatic boost.
- Win appears only when something runs **cross-instance or host-wide content search**.
- Discovering instances should stay a **shallow structural probe** (markers, known layouts), not recursive body search of every tree under `$HOME`.
- Parallel many instances already contend for CPU/disk; efficient search does not remove that if every session walks everything.

### Tool comparison (listing vs content)

| Tool | Best fit |
|------|----------|
| **rg** | Content regex; content audits; respect `.gitignore` |
| **fd** | Fast filename/dir listing with sensible defaults |
| **find** (as in `utils/fs` today) | Metadata, mtime windows, portable scripts without extra deps |

Installing rg on the host is still valuable for agents and developers; treating it as the main scale strategy for bootstrap or nested layout is mistaken.

---

## nested instances on one host

Design targets (see nested ASC / wrappers nested living notes):

| Concern | Guidance |
|---------|----------|
| List / map | Bounded structural discovery (depth, known parents), layout maps; avoid scanning entire file bodies |
| Exec into child | Virgin or controlled env in **child** `PROJECT_DOCROOT` — cost is that instance’s bootstrap, not host-wide rg |
| Host-wide agent tools | Always prune: vendor, data dumps, generated roots, multi-instance path lists from a registry when available |
| Scale of N instances | Prefer an **index/registry of instances** over repeated full `$HOME` walks |

RAM on a single nested docroot helps only that instance’s hot dirs. Host-level “everything in ramfs” is usually wrong for durability and memory.

---

## preferred leverage order

When performance or scale becomes a problem, apply in roughly this order:

1. **Measure** (which phase is I/O vs CPU).
2. **Materialize less** (builder resolution via registry/DSL/cache; consolidated generated includes).
3. **Cache what is already cached** (warm hook cache; avoid needless full reinit / cache bust).
4. **Scope worktrees** (generated root; ignore generated noise in tools).
5. **Bounded discovery** for nested instances (depth, registry), never host-wide content grep for layout.
6. **Scoped tmpfs** for cache / builder output if create/walk phases dominate on slow disks.
7. **Flush design** (overlay promote or lsyncd/rsync on events) if RAM layers are used.
8. **rg / fd for search UX and audits**, not as a substitute for (2)–(5).

---

## open tasks

- [ ] If builder lands multi-leaf codegen: define generated root convention + ignore rules for rg/fd/git.
- [ ] Optional: document host packaging for `rg` / `fd` as agent conveniences (software extension / provision), without baking them into core hot path.
- [ ] Optional experiment: tmpfs for `data/asc/cache/` only; measure reinit + representative `$` before/after on target media (NVMe vs HDD).
- [ ] Optional experiment: overlay (disk lower + tmpfs upper) for builder sandbox with explicit commit flush.
- [ ] Nested-instance list: keep depth-bounded structural find; consider registry index if host instance count grows large.
- [ ] No product requirement yet to put whole instances on ramfs/tmpfs.

Status of ideas above remains **proposal / ops guidance** until implemented and recorded in a dated changelog.
