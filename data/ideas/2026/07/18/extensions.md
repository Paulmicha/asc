# ASC core concept : Extensions

TODO important note : any nested extension MUST have their hook implementations to have exact same specificity (weight) as their non-nested extension point closest to project docroot.

Example :

Implementing some `u_hook_most_specific()` contract in a submodule (child extension) :

`asc/extensions/entity/field`

Must have the exact same specificity as if it was implemented in :

`asc/extensions/entity`

## ASC data types

- globals (readonly or mutable, may be secret + TODO encrypted ?)
- cache or sidecars (ex: logs) or media or test artifacts in data/* dirs
- other yml (ex: remote instances or any entity)
- encrypted (git) versionned files (cf. `data/crypted`)

## ASC extension points

- ./asc
- ./asc/extensions/$extension
- ./asc/extensions/$extension/**/$nested_extension (via .asc_subjects_ignore)
- ./scripts/asc/contrib/$extension
- ./scripts/asc/contrib/$extension/**/$nested_extension (via .asc_subjects_ignore)
- ./scripts/asc/extend
- ./scripts/asc/extend/**/$nested_extension (via .asc_subjects_ignore)

## ASC Generic -> Specific scale of actions (entry points)

Goal :
The bottom of this list wins when implementing the same `u_hook_most_specific()` :

1. asc/$subject/$action
1. asc/extensions/$extension/$subject/$action
1. asc/extensions/$extension//**/$nested_extension (via .asc_subjects_ignore)
1. scripts/asc/contrib/$extension/$subject/$action
1. scripts/asc/contrib/$extension/**/$nested_extension (via .asc_subjects_ignore)
1. scripts/asc/extend/$subject/$action
1. scripts/asc/extend/**/$nested_extension (via .asc_subjects_ignore)
