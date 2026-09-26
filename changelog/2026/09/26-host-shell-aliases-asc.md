# Host shell alias file

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | plan. The map path is `$HOME/.bash_aliases_asc`. `make -C` and the instance-subject whitelist are still open. |
| **Scope** | `make host-shell-write-aliases` (`asc/host/shell/write_aliases.sh`), `ASC_HOST_SHELL_ALIASES` |

`$` here is a shell variable (`$HOME`, `$1`).

## Two files

The map and the plug are different files. Both live under `$HOME`. Neither lives under an instance `data/` directory. `$HOME` does not have to be an ASC project. You run the writer from an instance. The shell that later sources the plug does not.

| Role | Path | What it holds |
|------|------|----------------|
| Map | `$HOME/.bash_aliases_asc` | The alias lines. Always this path. |
| Plug | `$HOME/.bash_aliases` (default), or `$HOME/.bashrc`, or `$HOME/.profile` | One source line for the map. Every other line stays. |

The argument is the plug's basename: `.bash_aliases`, `.bashrc`, or `.profile`. Empty means `.bash_aliases`. The map path does not change with that argument.

## Decision

`make host-shell-write-aliases` regenerates `$HOME/.bash_aliases_asc`, then writes this line into the plug once:

```bash
[ -f ~/.bash_aliases_asc ] && . ~/.bash_aliases_asc
```

A later run rewrites the map. When that line is already in the plug, the plug stays as it is. A missing plug is created with that line only.

## Generated file

The file is generated. A hand edit is replaced on the next writer run.

It maps each whitelisted name through one function. The interactive shell does not source `asc/bootstrap.sh`. `make` bootstraps when the alias runs.

### Whitelist: `instance` subject only

A name is wired only when its entry point is the `instance` subject: the script is `asc/instance/<name>.sh`. `f_make_list_entry_points` publishes those without the `instance-` prefix, so the alias is `gacp`, not `instance-gacp`.

`ASC_HOST_SHELL_ALIASES` stays the opt-in list inside that subject. The default `ds gu gmp gacp ssk` already qualifies. A script that then sources another subject still qualifies: `asc/instance/gacp.sh` sources `asc/git/acp.sh`, and the alias stays `gacp`.

A name from any other subject is skipped (`core`, `git`, `host`, an extension). The list does not grow to every file under `asc/instance/`.

### Closest docroot, then `make -C`

At call time the function starts at the current directory and walks parents. The chosen directory is the closest one that has both `asc/bootstrap.sh` and a `Makefile`. It does not call `make host-instance-discover` and does not read the host registry.

When the current directory is outside `$HOME`, and no parent matched, `$HOME` is the candidate when it has both files. Under `$HOME`, the parent walk already visits `$HOME`.

When no directory qualifies, the function exits non-zero and runs no command.

The function does not store a script path. It runs:

```bash
make -C "$docroot" "$name" "$@"
```

`"$name"` is the alias. `"$@"` is whatever the person typed after it. Make in that docroot resolves the pivot, including an extend script that wins over `asc/instance/<name>.sh`.

Sketch of the generated file, for one whitelisted name:

```bash
closest_asc_docroot_exec() {
  local name="$1"
  shift
  # cwd, then each parent: first directory with asc/bootstrap.sh and a Makefile.
  # Outside $HOME, try $HOME when it has both. Otherwise exit non-zero.
  make -C "$docroot" "$name" "$@"
}

alias gacp='closest_asc_docroot_exec gacp'
```

One alias line per whitelisted name.

## Writer today

`asc/host/shell/write_aliases.sh` writes the map to `$HOME/.bash_aliases_asc` and the source line into `$HOME/<plug>`. `data/asc/aliases.<shell>.sh` is gone. The shell-type argument is gone. The alias lines are still `alias <name>=<script>`, with a TODO for the `make -C` call. The instance-subject whitelist is not applied yet. The plug write is untested.

[`25-wired-init-lists.md`](25-wired-init-lists.md) still describes init appending `alias <name>=<absolute-path>` into those same three plugs. The plugs here receive the source line only. Alias lines stay in `$HOME/.bash_aliases_asc`.

## Open

- [x] The map is `$HOME/.bash_aliases_asc`, not an instance `data/` file.
- [x] The plug is `.bash_aliases` (default), `.bashrc`, or `.profile`, under `$HOME`, and it receives one source line.
- [ ] Regenerate the map from `ASC_HOST_SHELL_ALIASES`, and only for names whose script is `asc/instance/<name>.sh`.
- [ ] In `closest_asc_docroot_exec`, choose the closest directory that has `asc/bootstrap.sh` and a `Makefile`, then run `make -C "$docroot" "$name"` and forward the alias arguments. Exit non-zero when none qualifies.
- [ ] Confirm the plug line is written once. Untested.
- [ ] `ASC_HOST_ALIASES_WIRED` is a separate decision. Empty still writes nothing on init.
