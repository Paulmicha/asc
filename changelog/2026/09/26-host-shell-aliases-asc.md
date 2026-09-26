# Host shell alias file

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | plan. The map is `$HOME/<plug>_asc`. The closest-script run is still open. |
| **Scope** | `make host-shell-write-aliases` (`asc/host/shell/write_aliases.sh`), `ASC_HOST_SHELL_ALIASES` |

`$` here is a shell variable (`$HOME`, `$1`).

## Two files

The map and the plug are different files. Both live under `$HOME`. Neither lives under an instance `data/` directory. `$HOME` does not have to be an ASC project. You run the writer from an instance. The shell that later sources the plug does not.

| Role | Path | What it holds |
|------|------|----------------|
| Map | `$HOME/<plug>_asc` | The alias lines for that plug. |
| Plug | `$HOME/.bash_aliases` (default), or `$HOME/.bashrc`, or `$HOME/.profile` | One source line for its own map. Every other line stays. |

The argument is the plug's basename. Empty means `.bash_aliases`. The map is `$HOME` plus that basename plus `_asc`:

| Plug | Map |
|------|-----|
| `.bash_aliases` | `$HOME/.bash_aliases_asc` |
| `.bashrc` | `$HOME/.bashrc_asc` |
| `.profile` | `$HOME/.profile_asc` |

A second plug can hold a different map. The three basenames stay the allowlist, because the basename is part of the path.

Those three names exist because shells start in different ways. `.profile` is the login file, `.bashrc` is bash's interactive file, and `.bash_aliases` is a convention some `.bashrc` files source. Which of them a shell actually reads is that person's shell. Core does not choose a plug, and it does not look at whether one of these files sources another. One run writes one plug and that plug's map. The map body is the same whichever basename was given. Empty argument means `.bash_aliases`.

## Decision

`make host-shell-write-aliases` regenerates that plug's map, then writes this line into the plug once. For the default plug:

```bash
[ -f ~/.bash_aliases_asc ] && . ~/.bash_aliases_asc
```

For `.bashrc` the same line names `~/.bashrc_asc`. For `.profile`, `~/.profile_asc`.

A later run rewrites the map. When that line is already in the plug, the plug stays as it is. A missing plug is left absent. The map is still written.

## Generated file

The file is generated. A hand edit is replaced on the next writer run.

It maps each whitelisted name through one function. The alias runs that script. It is not a `make` wrapper. The interactive shell does not source `asc/bootstrap.sh`. The script bootstraps when it runs.

### Whitelist: `instance` subject only

A name is wired only when its entry point is the `instance` subject: the script is `asc/instance/<name>.sh`. `f_make_list_entry_points` publishes those without the `instance-` prefix, so the alias is `gacp`, not `instance-gacp`.

`ASC_HOST_SHELL_ALIASES` stays the opt-in list inside that subject. The default `ds gu gmp gacp ssk` already qualifies. A script that then sources another subject still qualifies: `asc/instance/gacp.sh` sources `asc/git/acp.sh`, and the alias stays `gacp`.

A name from any other subject is skipped (`core`, `git`, `host`, an extension). The list does not grow to every file under `asc/instance/`.

### Closest mapped script

The writer asks `f_make_list_entry_points` once, when it builds the map. That is the same name-to-script list Make uses. The map stores the relative path (`asc/instance/gacp.sh`). At call time nothing calls `make`, and nothing needs a `Makefile`.

The function uses the logical current directory (`$PWD`, not the physical path). A symlink is the location it pretends to be. From there:

1. If `$PWD/$rel` exists, run it.
2. Move to the logical parent and check again.
3. Repeat. `$HOME` is the last directory checked. Parents of `$HOME` are not checked.

When the start is already inside `$HOME`, step 3 ends on `$HOME`. When the start is outside `$HOME`, the parents are checked first, and `$HOME` is checked once after that, because the alias is for any place on the host and `$HOME` is the last check.

A directory that cannot be read counts as not containing the file. The walk continues. A nearer project that does not have the file is skipped. The function does not call `make host-instance-discover` and does not read the host registry. It does not ask that project which script Make would pick. An extend script that would win under `make` is not consulted. The stored path is the one that runs.

When no directory contains it, the function says so on stderr and exits non-zero. It runs no command.

The script is run in a subshell whose current directory is that chosen directory. The interactive shell's current directory stays. The subshell is what makes `. asc/git/acp.sh`, inside `asc/instance/gacp.sh`, resolve. Arguments after the alias are passed through as the script's arguments, with no Make assignment or extra-target rules.

```bash
( cd "$docroot" && "./$rel" "$@" )
```

Sketch of the generated file, for one whitelisted name:

```bash
closest_asc_docroot_exec() {
  local rel="$1"
  shift
  # Logical cwd, then each logical parent. $HOME is the last check.
  # Do not go above $HOME. None found: stderr, exit non-zero.
  ( cd "$docroot" && "./$rel" "$@" )
}

alias gacp='closest_asc_docroot_exec asc/instance/gacp.sh'
```

One alias line per whitelisted name.

## Writer today

`asc/host/shell/write_aliases.sh` writes the map to `$HOME/<plug>_asc` and the source line into `$HOME/<plug>`. `data/asc/aliases.<shell>.sh` is gone. The shell-type argument is gone. The alias lines are still `alias <name>=<script>`. The closest-script run is not written yet. A name that is not `asc/instance/<name>.sh` is skipped with a message. An empty result does not truncate the map. A missing plug is not created. The plug write is untested.

The alias-record half of [`25-wired-init-lists.md`](25-wired-init-lists.md) is withdrawn. This note is the one that counts. The plugs receive the source line only. Alias lines stay in that plug's map.

## Open

- [x] The map is `$HOME/<plug>_asc`, not an instance `data/` file.
- [x] The plug is `.bash_aliases` (default), `.bashrc`, or `.profile`, under `$HOME`, and it receives one source line.
- [x] Skip a name that is not `asc/instance/<name>.sh`, say so, and do not truncate the map when nothing qualifies.
- [x] Do not create a missing plug.
- [ ] In `closest_asc_docroot_exec`, run the stored relative script in the closest directory that contains it, in a subshell. Exit non-zero when none qualifies. Do not call `make`.
- [ ] Confirm the plug line is written once. Untested.
- [x] `ASC_HOST_ALIASES_WIRED` alias records are withdrawn. Init does not write alias lines.
