# Wired lists during instance init

> **2026-09-26.** Alias lines no longer land in the plug. The plug (`.bash_aliases`, `.bashrc`, or `.profile` under `$HOME`) receives one source line for `$HOME/.bash_aliases_asc`. See [`26-host-shell-aliases-asc.md`](26-host-shell-aliases-asc.md).

- **Date:** 2026-09-25
- **Status:** git list implemented. Alias records are still planned.
- **Scope:** `asc/git/init.hook.sh`, `asc/core/global.vars.sh`, `asc/host/shell/write_aliases.sh`.

## Decision

Two append-lists. Empty means instance init does not write.

`ASC_GIT_HOOKS_WIRED` is the git hooks init may pass to `f_git_write_hooks`. Empty: do not call the writer. Non-empty: call it with that list only. The writer's built-in six are not implied. `APP_GIT_INIT_HOOK` is not the name.

`ASC_HOST_ALIASES_WIRED` is empty, or an append-list of alias records for that instance's `PROJECT_DOCROOT`. Any instance may set it. Empty: init writes no alias. Each record is one append value, and an append value cannot contain a space. `|` separates the three fields. `,` separates targets. `/` cannot, because the absolute path contains slashes.

1. The alias.
2. The absolute path of the entry point under that `PROJECT_DOCROOT`.
3. One or more targets, relative to `$HOME`: `.bash_aliases`, `.bashrc`, `.profile`. No `~/` prefix.

```text
ds|$PROJECT_DOCROOT/asc/instance/ds.sh|.bashrc,.bash_aliases
```

Init writes that alias, once, into `$HOME` plus each named target. A later init does not append the same line again. Another instance's line stays.

`ASC_HOST_SHELL_ALIASES` stays the names the current writer emits. Its default is `ds gu gmp gacp ssk`. It has no path and no target. Init must not treat it as `ASC_HOST_ALIASES_WIRED`.

The skill sentence that names `APP_GIT_INIT_HOOK`, and the test that greps it, use `ASC_GIT_HOOKS_WIRED` when this lands.

## Open

- [x] `ASC_GIT_HOOKS_WIRED` is empty in `asc/core/global.vars.sh`. `asc/git/init.hook.sh` writes only that list. The generated wrapper keeps the git hook arguments.
- [ ] `ASC_HOST_ALIASES_WIRED` is not declared yet.
- [ ] A non-empty record writes `alias <name>=<absolute-path>` once into each target after the second `|`.
- [x] The skill test greps `ASC_GIT_HOOKS_WIRED`.
