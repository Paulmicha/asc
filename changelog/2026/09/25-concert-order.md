# Concert — sidecar, catalog, git

| Field | Value |
|-------|--------|
| **Date** | 2026-09-25 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | One order for the open mother plans that keep being re-fused: sidecar contract, host catalog, registry, rule drift, and the branch contract. |
| **Out of this plan** | New scripts. Filling `sidecar.able.yml`. Rewriting `file_registry`. Enabling `memory`. A README edit. Copying `.cursor/rules`. Creating branches. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME` and `$FILE_REGISTRY_HOST_LEVEL_PATH`.

`gates.core.yml` and the other gates files are a later agent approval surface. They are not the queue for this design. Do not add a row for this note. Do not reorder work to satisfy a lane.

Mother `main` was level with `origin/main` when this note was written. The work tree has since been edited in place.

---

## Git, as other projects actually use it

Six patterns cover what large public projects run. The name “gitflow” is one of them, and it is the wrong one here.

| Pattern | What it is | Where it shows up | Fits a solo toolbox | Breaks here |
|---------|------------|-------------------|---------------------|-------------|
| GitHub Flow | `main` plus a short branch and a review merge. Delete the branch. | Default on most GitHub-hosted projects. | Yes, when a human asked for the branch. | No multi-machine buffer. |
| Trunk-based | Commit to one trunk, or branches that live less than a day. `main` stays green. | Google, Meta; DORA treats it as the high-throughput default. Kubernetes adds a merge queue and release branches. | The mother already works this way when commits land on `main`. | Needs CI to mean what the slogan means. This repo has no merge queue. |
| Gitflow (Driessen, 2010) | Long-lived `main` and `develop`, plus feature, release, and hotfix branches. | Versioned products that patch an old release. The author narrowed it in 2020: continuously delivered software should use a simpler flow. | No. | Two long-lived branches. Agents will commit to the wrong one. ASC is not shipping N supported versions. |
| GitLab Flow | GitHub Flow plus environment branches (`production`) or release branches. Merge to promote. | Teams that promote the same repo through deploy stages. | No. | An ASC instance is not an environment of the mother. |
| Release Flow | Trunk plus one branch per supported release. Cherry-pick fixes back. | Microsoft-style multi-version products. | No. | Same reason as Gitflow. |
| Merge upward | Private topic branches. A public integration branch is not rebased. Changes move up; they are not developed on the branch other people pull. | `gitworkflows(7)` (`maint` / `master` / `next` / `seen`). Linux kernel topic branches and maintainer pulls. | Yes, for one repo shared by several machines. | Too many integration branches (`next`, `seen`, `linux-next`) for one person. |

Stacked diffs (Graphite, `ghstack`) are a review tool for dependent commits. They multiply branches. They are not a policy.

---

## What ASC should call the branch contract

The filename [`22-gitflow.md`](./22-gitflow.md) says Gitflow. Driessen’s `develop` / release / hotfix set is still the wrong default. Do not add `develop`. Feature branches on an ASC project repo are fine. The hard branch problems live in client repositories. ASC sits one level above those sub-repos and does not rename their branches.

The buffer shape is for one repo shared by several machines, not for every ASC project. The linux home-directory instance is that repo: buffer `debian-<major>`, child `debian-<major>-<machine>`, pull the buffer before push. That instance is for laptop work (provisioning, backup sync). It is not a template to impose on client projects. No helper script.

Three transports stay three. They do not become one workflow.

| Transport | What moves | Branch shape |
|-----------|------------|--------------|
| Mother trunk | Generic bytes in `asc/` and `scripts/asc/contrib/asc/` | `main`, or a feature branch when the work wants one. |
| One repo, several machines | Commits those machines share | One buffer (`debian-<major>` on the home-directory repo). A machine branch is a child. Pull the buffer before pushing the child. |
| A client repository | That project’s own branches | ASC does not choose them. A generic fix is copied up by a human after that instance’s search. |

`make git-acp` adds the whole work tree and pushes the current branch. It does not pull a buffer. Leave that script alone.

`make core-upgrade` replaces two directories from the public remote. It is not a branch relationship. [`23-host-asc-core-sync.md`](./23-host-asc-core-sync.md) is a report and a forward mirror. It never writes into the mother. Upward copy stays a human promotion.

---

## Sidecar path template, registry left as it is

The registry stays one string per key. Host scope stays `$HOME/.local/state/asc/registry`. Do not rewrite `file_registry` as entities.

`sidecar.able` is the sibling mechanism. It names a path, as a string template, instead of a single `.reg` file. Presets, not one directory baked into the contract:

| Preset | When | Shape |
|--------|------|--------|
| Many files | Logs and other high-volume files | `data/foobar/YYYY/MM/DD/HH-II-SS-<file_name>.txt` |
| Occasional files | Changelogs and similar | `changelog/YYYY/MM/DD-<file_name>.md` |
| Entity instance | One record per id | `data/entities/host/foobar.home.arpa.yml` |

The entity-instance preset is what `host.entity.yml` already uses. It is not the only preset, and it is not where the host catalog goes. The catalog stays the registry key.

`asc/sidecar/sidecar.able.yml` is 0 bytes. `asc/sidecar/sidecar.sh` is a TODO. `asc/sidecar/sidecar.wrap.sh` is a different job already sketched in comments: a history file beside an existing file, including rolling windows. The rewrite should keep that distinct from the path template. The README datestamp uses `HH.MM.SS.MS`. The preset above uses `HH-II-SS`. Pick the spelling in the rewrite. This note does not fill the files. That rewrite is the next design.

Discovery today only checks that a type includes `sidecar.able`, then reads `data/entities/<type>/`. A path template will change that assumption. Do not treat the current `data/entities/` walk as the finished contract.

---

## Host catalog

[`20-host-scan-project-instances.md`](./20-host-scan-project-instances.md) is the catalog. The script is `asc/host/instance/discover.sh`, pivot `make host-instance-discover`. The stub is on disk. `asc/instance/discover.sh` is withdrawn: `f_make_list_entry_points` would publish it as `make discover`.

Walk, when the stub is filled: `find -P`, `-maxdepth 6`, prune on hit, repeatable `--root`, never `/`, never `-L`. One host-registry key, newline-separated paths. No second finder. Not a sidecar. Filling that stub is not this note’s next task.

---

## Shared Cursor how-tos

Instances differ in purpose and share a large set of how-tos for Cursor agents working on the common ASC codebase. Those shared clauses are what deserves streamlining. Instance-only rules stay in the instance. A rule written `alwaysApply` for a workspace whose root is the mother does not belong on another workspace unchanged.

`make host-cursor-rules-sync` compares filenames and copies nothing. That report is the current tool. A later pass can maintain the shared how-tos. It does not copy every `.mdc`, and it does not wait on the sidecar rewrite to be worth thinking about.

---

## Bad ideas, stated flat

- Using `gates.core.yml` as the design queue at this stage.
- Driessen’s long-lived `develop`, and imposing the home buffer on client repos.
- Rewriting `file_registry` as sidecar entities.
- Storing the host catalog under `data/entities/host/`.
- `asc/instance/discover.sh` (`make discover`).
- A blind copy of every Cursor rule across docroots.
- Ending a workflow lap in `git-acp`.
- `apply` of core sync onto an instance whose bootstrap and generated globals file disagree on the name. Current mother bootstrap sources `data/asc/globals.sh`. Confirm the target before a mirror.

---

## Order

1. Rewrite `asc/sidecar/` around the path template. Human. Not this note.
2. Leave the registry writer as it is.
3. Fill `asc/host/instance/discover.sh` later, using the walk in the host-scan plan.
4. Streamline shared Cursor how-tos as their own pass. The filename report already exists.

---

## Tasks

- [ ] Human: sidecar path template in `asc/sidecar/`. Keep `sidecar.wrap.sh` distinct. Settle `HH-II-SS` versus `HH.MM.SS.MS`.
- [ ] Do not rewrite `file_registry`. Do not add `asc/instance/discover.sh`.
- [ ] Fill `host-instance-discover` only after the sidecar rewrite, per the host-scan walk.
- [ ] Shared Cursor how-tos: identify the clauses, do not copy instance-only rules.
