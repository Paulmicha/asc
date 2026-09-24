# Registry alternative for `gates.yml`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | plan / review (**not** an implementation go-ahead) |
| **Scope** | A possible later store for the same human approval records that [`gates.yml`](../../../gates.yml) holds today. |
| **Not this plan** | Implementing `reg-get` / `reg-set` for gates. Changing `file_registry` hooks. A new global. Loading `gates.yml` from `f_instance_yaml_config_load`. An agent extension. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

No other changelog covers this. [`22-doc-next-steps.md`](./22-doc-next-steps.md) is the list writer. This file is only the other storage idea.

---

## What exists

`gates.yml` in the project docroot is the approval registry. Lookup matches `env.yml`: dry-run, suffix `yml`, `-r`, variants `STACK_VERSION` / `HOST_TYPE` / `INSTANCE_TYPE`. Rung 4 wins. The file is not sourced.

Each row maps one changelog task from `NEXT_STEPS.agent.md`. `summary` is one sentence for that row. `lane` is `sequential`, `parallel`, `discuss`, or `held`. `approved` is the human mark. `go` is whether that task may start. `discuss` and `held` stay `go: "no"`. A sequential row stays `go: "no"` until every lower `order` in that lane is already `go: "yes"`.

`make reg-get` / `make reg-set` are separate. They call `f_instance_registry_get` / `f_instance_registry_set`, which `hook_ms` to `registry_get` / `registry_set`. The enabled `file_registry` extension writes one string per key:

- instance: `data/asc/registry/.<slug>.reg` (`f_file_registry_get_path`)
- host: `$FILE_REGISTRY_HOST_LEVEL_PATH/<namespace>/.<slug>.reg` (default `$HOME/.local/state/asc/registry` since 2026-09-24; previously `/opt/asc-registry`)

`data/asc/*` is gitignored. An empty `reg-set` value is stored as `1`. The hook body is `echo "$reg_val" > "$reg_file_path"`. There is no YAML parse on read.

---

## Alternative (not started)

Keep the row shape in `gates.yml`. If this plan is accepted later, mirror those rows through the instance registry instead of editing only the docroot file.

Two shapes, one pick when someone asks to build it:

1. **One key.** `make reg-set gates` stores the YAML document as the value of key `gates`. `make reg-get gates` prints it. The hook implementation may write that one value as `data/asc/registry/.gates.yml` instead of `.gates.reg`. Other keys stay `.reg`.
2. **One key per task.** `reg-set` key `gates--<changelog-slug>--<order>` value `no` or `yes`. Matches today's one-string files. Drops the YAML document. Harder to review as one list.

Prefer (1) if the point of the alternative is "YAML files". Prefer (2) if the point is to stay on the current `.reg` hook with no hook change.

Host `reg-set` is the wrong scope: changelog approval belongs to this project instance, not every project on the machine.

Either shape is local runtime state. It does not replace a pushed `gates.yml` unless someone decides the registry is the source and the docroot file is only a dump. That decision is not made here.

---

## Leave it

Do not add a loader, a global, or a second entity. Do not teach `f_instance_yaml_config_load` to read `gates.yml` (that path fills `.env`). Revisit this file only after an explicit go-ahead in `gates.yml`.
