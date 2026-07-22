# ASC core concept : Entities (synonym : node ?)

Table of contents :

1. represents ? (why it exists)
1. definition (scope ?)
1. capabilities
1. relationships
1. compatibility, applicability ? (protocols, etc)
1. yml includes

Entities are the shared vocabulary for “things” ASC can name, wrap, nest, and relate. Most of the `entity` extension is still design/stub; this page records the contract so living docs and ideas stay aligned.

---

## represents ? (why it exists)

ASC’s ambition is self-explanatory filenames and paths. **Entities** give a common shape to anything that can be talked about in that vocabulary — jobs, hosts, instances, sidecars, plans, dependencies — without inventing a new ad-hoc YAML dialect per feature.

Useful analogy from ideas:

| Term | Meaning |
|------|---------|
| **thing** | Actual / external (software, hardware, network) |
| **entity** | Virtual model inside ASC (YAML + predicates) |

**Primordial** entity = most generic empty object = `entity.entity.yml` (mother of all entities). Upstream ASC core aims at **primitive-level** contracts and implementations — not every domain ontology.

Open: whether the public synonym stays **node** or only **entity**.

---

## definition (scope ?)

| Piece | Location | Status |
|-------|----------|--------|
| Extension | `asc/extensions/entity/` | Core-ignored by default |
| Predicates | `entity/is/*`, `entity/has/*`, `entity/field/` | Mostly TODO stubs |
| Markers | `*.entity.yml`, `*.able.yml` beside subjects | Partial examples (`thread.entity.yml`, `sidecar.able.yml`, …) |

Abstract nesting scale (most → least generic):

1. primordial  
1. primitive ancestor ?  
1. ancestor  
1. parent  
1. self  
1. child  
1. descendants  

Inheritance is intended to follow remote-instance style YAML **`includes`** (parent ≈ genericity).

Minimal “hello, this depends on …” YAML shapes (planned): dependency sources (pipx, git, deb, appimage, apt), optional `.asc-extension.yml`, hardware/software/state variants.

---

## capabilities

Capabilities are expressed as **`*.able.yml`** (and matching `is/able` / `has/*` scripts when implemented).

| Able | Intent |
|------|--------|
| `$wrap.able` | log, process, thread, `lt`, … |
| `$action.able` | subject entry points (rotate, recognize, …) |
| `$sidecar.able` | changelog / accesslog / time windows |
| `$field.able` | fieldable attributes |
| `contract.able` | original “able” |
| `hook.able` / `implement.able` | emitter / receiver (SKOS-style implement → ontology/taxonomy?) |
| `$nest.able` | nested-git, nested-asc, nested-host / VM / piloting, … |
| `crud.able` | vs hardcoded default entity actions |
| `forget.able` | **lifetime for all durable data** (logrotate-like for any `data/*`) |
| `depend.able` | contrib / remote deps |
| `build.able` / `combine.able` | blueprints + composition (partially out of scope for core) |
| `$use.able` | e.g. `entity/uses/global.sh` |
| `plan.able` | (auto) planified work |
| `break.able` | will it ever end? / circuit breaker / emergency kill |
| `crypt.able` | encryption opt-in |
| `protocol.able` | protocol / argument parser contracts |

Working notes also list near-synonyms to reconcile (not all need distinct files): chainable, pipeable, observable, linkable, slotable, sortable, evaluable, viewable, repeatable, sidecarable, wrappable, discoverable.

**Pattern:** capabilities ≈ `*.able.yml`. **State markers:** `is.*.yml` (able / auto / …) as synonyms of “current state”, distinct from `has/*` attributes.

Agents ideas also list `wrapper.able`, `bridge.able`, `taxonomy.able`, … — **naming must be reconciled** with the `$….able` catalog above (`contract-able` idea).

---

## relationships

| Kind | Working meaning |
|------|-----------------|
| **Link** (edge?) | Virtual relation between entities |
| **Bridge** (association?) | Actual I/O or runtime coupling |
| Software / hardware | Dependency / inventory relations |

Examples of **bridges** (actual I/O coupling):

- [Pipe](wrappers.md#pipe) between stages
- stdout / stderr redirection wrappers
- Sidecars (durable companions beside a primary file)
- Discoverability “through wrappers × bridges” (how an agent finds the next hop)

**Emitter / receiver** labels wrap traces (differentiator). Do not confuse with a **comparator** in rules/conditions (include/exclude logic).

Extension `link` ships `linkable.entity.yml` (stub); sidecar helpers `bridge.sh` / `link.sh` are empty placeholders.

Other relation sketches from notes (open):

| Sketch | Idea |
|--------|------|
| Specimen as sidecar pattern | `SPECIMEN.*` files are companion templates beside the real config — same mental model as `*.sidecar.txt` |
| Git branch as sidecar | Branch metadata / worktree state as a sidecar of a nested-git entity |
| USB / removable store | Hardware-addressable memory: same disk, different mount/host — `$nest.able` + memory store |
| Users / ACL / permission | Compatibility predicates — see § compatibility (ideas still empty) |

Open: connectivity in a broader sense (ssh, curl, dns tooling) as first-class relations vs leaving that to [wrappers.md](wrappers.md) § remote.

---

## compatibility, applicability ? (protocols, etc)

Applicability is sketched as **`is/*`** predicates (mostly TODO):

- Visibility: `public` / `private`
- Event source: manual, agent, cronjob, interaction, timestamp, …
- Graph role: `root` / `sibling` / `leaf`, `relation`
- Contracts: `able` (cognition.able, …)

Attributes as **`has/*`** (mostly TODO): label, type, bundle, plan, log, changelog, idea, sidecar, wrapper, nested, permission, field, origin, author, license, version, state, created, changed, …

Auth pack ideas (`auth`, `acl`, `roles`, `permissions,cascading`, `sudo,human-supervising,control`) are still empty or one-line TODOs — e.g. `role.able.yml?`, `cascade.able` ≈ `nest.able?`. Do not treat them as implemented.

Also open from notes: congestion / decongestion / **circuit breaker** (pair with `break.able`); “is-book-bindable” as a tongue-in-cheek applicability joke — keep real predicates boring and explicit.

---

## yml includes

- Entity inheritance and remote-instance config both use YAML **`includes`**.
- Dependency declarations should stay declarative (`*.dependency.yml` shapes) and feed provision / nest / build flows later.
- Runtime durable entities (planned memory store): `data/<memory_store>/<entity>.yml` plus sidecar — see [organization.md](organization.md) memory/globals discussion and the `memory` extension stubs.

Until `entity` is enabled and predicates exist, prefer documenting concrete subjects (`thread`, `loop`, `sidecar`) via their live `*.entity.yml` / wrap contracts rather than inventing new YAML dialects.
