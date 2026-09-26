# Wired lists during instance init

> **2026-09-26.** The alias-record half of this note is withdrawn. Plugs and maps are [`26-host-shell-aliases-asc.md`](26-host-shell-aliases-asc.md). The git-hooks half below still stands.

- **Date:** 2026-09-25
- **Status:** git list implemented. Alias records withdrawn.
- **Scope:** `asc/git/init.hook.sh`, `asc/core/global.vars.sh`. `asc/host/shell/write_aliases.sh` is no longer this note.

## Decision

`ASC_GIT_HOOKS_WIRED` is the git hooks init may pass to `f_git_write_hooks`. Empty: do not call the writer. Non-empty: call it with that list only. The writer's built-in six are not implied. `APP_GIT_INIT_HOOK` is not the name.

`ASC_HOST_ALIASES_WIRED` is not a list init writes. Alias lines do not go into `.bash_aliases`, `.bashrc`, or `.profile`. That decision is withdrawn.

The skill sentence that names `APP_GIT_INIT_HOOK`, and the test that greps it, use `ASC_GIT_HOOKS_WIRED` when this lands.

## Open

- [x] `ASC_GIT_HOOKS_WIRED` is empty in `asc/core/global.vars.sh`. `asc/git/init.hook.sh` writes only that list. The generated wrapper keeps the git hook arguments.
- [x] Alias records are withdrawn. Init does not write them.
- [x] The skill test greps `ASC_GIT_HOOKS_WIRED`.
