# Extensions

Any folder in `asc/extensions/` is a ASC extension (not their subfolders). Project-specific code uses the same shape under `scripts/asc/extend/`.

## Enable / disable

Core ships [`asc/extensions/.asc_extensions_ignore`](../../asc/extensions/.asc_extensions_ignore) (default exclusions). Override by copying to `scripts/asc/override/.asc_extensions_ignore` and editing (one folder name per line to disable; delete the line to enable). An empty override file means “enable all extensions”.

If present, these take precedence (in order):

1. `scripts/asc/override/.${PROVISION_USING}.asc_extensions_ignore`
2. `scripts/asc/override/.${INSTANCE_DOMAIN}.asc_extensions_ignore`
3. `scripts/asc/override/.asc_extensions_ignore`

With the stock core ignore list, **`file_registry`** is typically the only bundled extension left enabled (everything else is listed). Confirm on your instance after `make reinit`.

## Overrides

If a counterpart exists under `scripts/asc/override/`, it replaces the original (`asc/` → `scripts/asc/override/`). Convenience: ignore file at `scripts/asc/override/.asc_extensions_ignore` (not under `override/extensions/`).

See [`scripts/asc/override/README.md`](../../scripts/asc/override/README.md) and [`scripts/asc/extend/README.md`](../../scripts/asc/extend/README.md).

## Extension conventions

- After init, any `make.mk` inside an enabled extension folder is included via `ASC_MAKE_INC`.
- Any `global.vars.sh` is aggregated during instance init.
- Includes: eager `*.inc.sh` vs lazy `*.opt-inc.sh` — see [bootstrap.md](bootstrap.md) and [`asc/extensions/README.md`](../../asc/extensions/README.md).

## Optional extension families (brief)

| Extension(s) | Role |
|--------------|------|
| `compose` | Docker Compose stack ops (renamed from `docker-compose`; hook dual-compat still accepts both tokens) |
| `db` / `mysql` / `pgsql` | Abstract DB + drivers |
| `drupalwt` / `drupalwt_d4d` / `drush` | Drupal tooling |
| `builder` / `memory` | Stub template / storage APIs — [builder.md](builder.md) |
| `cognition` / `transcription` | observe/recognize stubs; ASR `transcribe` |
| `agent` / `ollama` | LLM abstracts + Ollama hooks |
| `nested_asc` | Virgin-env nested instances — [nested-asc.md](nested-asc.md) |
| `remote*` / `remote_traefik` | SSH sync, DB dumps, Traefik |
| `crontab` / `hosts_file` / `software` | Host jobs, `/etc/hosts`, packages |
| `file_registry` | Default registry backend (usually enabled) |
| `git_crypt` | Opt-in encryption hooks (stub / ignored by default) |

Per-extension notes: [`asc/extensions/README.md`](../../asc/extensions/README.md). Drupal getting started: [`asc/extensions/drupalwt/README.md`](../../asc/extensions/drupalwt/README.md).
