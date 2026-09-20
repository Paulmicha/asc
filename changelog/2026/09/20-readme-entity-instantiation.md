# README proposal: Instantiation function names

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | **applied** (2026-09-20). Agent applied to root `README.md` (uncommitted) for human review. |
| **Target** | [`README.md`](../../../README.md) — **Instanciation ("concrete" entity instances)** |

`$` in this file is the ASC docs placeholder (`$entity` / `$field`), not a shell variable.

---

## Why

Instance (re)init now discovers types, discovers instances, generates cache, and loads from cache; this heading still stubs `f_entity_load()` and still has the two TODOs.

## Exact edit

**Replace** the subsection body under `#### Instanciation ("concrete" entity instances)` (keep that heading; leave **Linking, adressing** as TODO) with:

During instance (re)init: `f_entity_types_discover`, then `f_entity_instances_discover`, then `f_entity_cache_generate_all`. Types that include the **sidecar.able** contract store each instance as YAML under `data/entities/<type>/`. **sidecar.able** is a contract, never a type name.

| Call | Result |
|------|--------|
| `f_entity_types_discover` | Index `*.entity.yml` in active dirs |
| `f_entity_instances_discover` | Index concrete instances of those types |
| `f_entity_cache_generate_all` | Write `data/asc/cache/entities/<type>/<id>.sh` |
| `f_entity_load <type> <id>` | Source that cache file |
| `f_remote_instance_load <id>` | Wrapper: `f_entity_load remote_instance <id>` |

Host fixture `data/entities/host/foobar.home.arpa.yml`: `HOST_HOSTNAME` from the filename map.

## Not this edit

Do not rewrite Contracts. Do not enable remote. Do not dump the whole entity plan.
