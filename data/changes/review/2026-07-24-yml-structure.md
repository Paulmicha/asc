# Plan stub: Structuring ASC YAML files

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (draft for iterative amendment; not implementation go-ahead) |
| **Tracked SoT** | [`changelog/2026/07/24-yml-structure.md`](../../../changelog/2026/07/24-yml-structure.md) |
| **Living docs** | [`docs/asc/yml-structure.md`](../../../docs/asc/yml-structure.md) |
| **Note** | `data/plans/review/*` is gitignored except `README.md`. Full plan + decision record lives in the changelog (same convention as `24-filename-dsl.md`). Keep this stub here for lifecycle lane only; update status / move folder when review → iterate → accepted / rejected. |

## Scope (see changelog)

- **Inside** YAML conventions (`*.able.yml`, `*.entity.yml`, later `*.hook.yml` / includes) — complementary to filename-DSL (paths / stems).
- Anchor draft @ `71b4f71`: `asc/git/git.able.yml` + `state.able.yml` + `repo.entity.yml` (initial `af31aca`).
- Subject inventory (`entities:`) vs per-entity `default.state` + `states` enum vs entity `depends_on` / field refs.
- Living page: `docs/asc/yml-structure.md`.

## Quick card (see changelog for full plan)

```text
# THIS PLAN = YAML bodies; filename-DSL = path stems / $action.able.yml mapping

asc/git/git.able.yml     → subject inventory (entities: folder, file)
asc/git/state.able.yml   → $action=state; per entity:
  <$entity>:
    default: { state: <id> }
    states: [ gitignored, versionned, modified, deleted, conflicted, (folder: unclean) ]
asc/git/repo.entity.yml → entity body:
  depends_on.entity: [file, folder, relation]
  url.field: str.url

# Doc notation: $git.$state ; on-disk: git/state.able.yml
# Do not conflate with filename wrap/nest/args punctuation SoT
```
