# Remove remote extension dependencies on entity abstractions

Status: draft

Restore the remote extension's own file loader and cleanup while retaining its
existing YAML discovery and generation. Existing project declarations must work
after installing ASC and running `make reinit`, including on repeated runs.
This plan describes proposed work; it does not claim implementation or runtime
acceptance.

The removed entity post-init hook is not needed to generate remote definitions:
the [remote post-init hook](../../../../asc/extensions/remote/instance/post_init.hook.sh)
calls `f_remote_instances_setup`. The break is that setup calls the deleted
entity purge helper, and remote consumers call the deleted entity load helper.
Before commit `08a42b57`, the remote extension checked and sourced a generated
shell file itself and removed its generated definitions itself.

## Design and migration

1. Generate remote instance files as `data/instance/remote/<id>.sh`. The
   directory may also contain human-maintained files and subdirectories: never
   delete or overwrite those as a side effect of cleanup. Define a safe,
   unambiguous way to identify the generated files before implementing purge;
   do not assume every `.sh` file in the directory is disposable. Keep the
   parsed intermediate and ID-list cache in an ASC-owned generated location,
   separate from remote IDs, so neither can be enumerated as a remote.
2. Update the generator, loader, `f_remote_get_instances`, directory setup,
   `remote-instance-remove`, purge, uninit and their path documentation together.
   Removal must invalidate the ID-list cache; enumeration must return only
   valid generated remote IDs. Preserve optional-ID loading, with a defined
   failure when no generated instance exists.
3. Keep the existing `hook_ms` YAML selection, variants and fallback,
   inheritance and precedence, defaults, and `REMOTE_INSTANCE_*` exports. On
   regeneration, remove obsolete generated IDs and invalidate the list cache.
   A missing declaration is a supported empty configuration, not a reason to
   retain previously generated remote definitions.
4. Define and implement a safe first-upgrade policy for the old
   `data/asc/cache/entities/remote_instance` directory and
   `data/asc/cache/remote_instance_ids.sh`: old metadata and stale IDs must not
   enter the new list, and unrelated files must be preserved. Repeated install
   and reinit must not require manual migration of project declarations. Do not
   use the legacy `data/asc/remote-instances` path as a fallback source of truth.
5. Ensure generated output is ignored by Git without hiding the directory's
   maintained documentation or unrelated files. Update the mother ignore rules
   and explicitly handle existing instances: `asc/core/install.sh` preserves an
   existing `.gitignore` and writes an upstream comparison copy. Specify and
   verify a repeatable, non-destructive instance policy before live acceptance;
   do not silently overwrite project-owned ignore rules or assume the upstream
   copy takes effect. Confirm generated configuration does not become an
   accidentally staged artifact.
6. Make a failed or missing load return nonzero, and ensure consumers stop on
   that failure even when a previous call loaded another remote in the same
   shell. Review core, contrib and relevant project consumers; do not rely only
   on checking whether a previously exported SSH variable is nonempty.
7. Propagate purge, parsing, generation and write failures through setup and
   its public entry points, including `remote-definitions-update`,
   `local-setup-remotes` and the post-init hook. Trace the hook dispatcher and
   init/reinit chain so failures reach the caller and no success message is
   printed for a failed operation. Define failure behavior so partial or stale
   output is not presented as a successful, current set.

Keeping the current `data/asc/cache/entities/remote_instance` path would avoid
some migration work, but this plan deliberately moves remote declarations to
`data/instance/remote`. Returning to the older `data/asc/remote-instances`
path is a separate alternative, not part of this plan. Reconcile the README's
example layout with the selected generated-file contract using the applicable
mother README proposal rules.

## Decisions required before implementation

The flat destination, generated-file ownership and Git exclusions need one
coherent design. The current commit `aee5a425` does not ignore a generated
`data/instance/remote/<id>.sh`, and the installer does not apply the mother's
ignore file over an existing instance's `.gitignore`.

- Decide how generated files are identified across process restarts, cache
  clearing and repeated installation. The proof of ownership must be available
  to generation, enumeration, removal and purge. If ownership cannot be proven,
  preserve the file and report the conflict; a filename or extension alone is
  insufficient in a shared directory.
- When a declared ID maps to a pre-existing file that is not proven to be
  generated by ASC, fail clearly without overwriting it. Define how an operator
  resolves that conflict, and how a failed generation affects other definitions
  and the ID list. Reserve or reject IDs that collide with internal metadata.
- Select a Git exclusion mechanism whose scope matches the ownership design.
  A blanket `*.sh` rule would also hide unrelated shell files in this directory;
  a tracked rule alone cannot be assumed to reach an existing instance. A
  generated dedicated subdirectory could simplify ownership and exclusion but
  would change the flat-path requirement and needs an explicit design decision.
- Specify what changes, if any, the installer or initialization may make to an
  existing instance's Git configuration, how that behaves for linked worktrees,
  and how it preserves user-managed rules. If a manual step is chosen instead,
  state that install plus reinit alone does not meet the automatic ignore
  requirement and report the remaining action explicitly. Ignore rules do not
  untrack files already in Git.

The separate [data ignore regression plan](24-restore-active-data-ignore-rules.md)
covers exclusions removed for other currently active data paths. Resolving it
does not by itself implement the remote path or its ownership policy.

## Acceptance

Use isolated fixtures and the existing ASC test entry points where practical.
Compare the resulting files and loaded values, not just command exit statuses:

- Generate twice and assert the exact ID set, shell syntax, effective values,
  includes, override precedence, defaults and exported variables. Exercise both
  host/instance-specific selection and unqualified fallback.
- Warm the ID-list cache, remove a declaration, regenerate and assert that the
  removed ID is absent from enumeration and cannot be loaded. Exercise the
  remove action, cache invalidation, uninit and subsequent regeneration.
- Test missing declarations, missing IDs, no-ID selection and an empty set.
  Load remote A, then attempt missing remote B in the same shell; assert that a
  representative consumer fails without using A's configuration or contacting
  a remote.
- Seed old entity metadata, stale remote IDs and unrelated files at both the old
  and new locations. Verify the documented migration and cleanup boundaries,
  including preservation of unrelated content and the maintained README.
- Inject representative purge, parse and write failures. Check the public
  actions and reinit return nonzero, do not print success, and do not expose a
  partial or stale set as a successful result.
- Verify ignore behavior in a fresh project and an existing instance with its
  own `.gitignore`; check both generated and maintained files with Git. Verify
  install and reinit do not overwrite instance-owned configuration.
- Create an unrelated shell file with the same name as a declared ID and verify
  generation reports the collision and fails without changing it; verify
  removal and purge also preserve it. Test that a different unrelated shell file
  and the README remain visible to Git while generated files are ignored. Repeat in a linked
  worktree if the selected exclusion mechanism can affect one.
- Record the selected ownership and instance-ignore mechanisms and their
  behavior after cache clearing, two installs, and two reinits. In an isolated
  fixture, check tracked-file behavior separately: an ignore rule must not be
  represented as removing an already tracked file from the index.

After implementation, check the effects of the real target instance's install
and reinit hooks, then run the requested `asc/core/install.sh <instance>` and
`make reinit` sequence there and repeat it. Record each command's result, the
selected declaration, the exact IDs compared with that declaration, syntax and
representative loaded values, and the Git-ignore result. Preserve existing
project changes. Report a permissions block separately from an implementation
failure. These local checks do not verify SSH connectivity or remote state.
