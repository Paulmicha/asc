# Conventions

See [flexibility](flexibility.html) for mecanisms and use cases - this documentation exemplifies syntax.

## Naming things

In the "*Folders & files naming*" section, a principle is mentionned : **file structure** should indicate `subject` + `intent`.

This is informal (not to follow strictly, see *Flexibility and recursion* section), though ASC does use an extensible whitelisting mecanism to produce tree-like naming possibilities sometimes called "hooks".

```sh
# From asc/env/vars.sh :
global ASC_SUBJECTS 'app env git provision remote stack service task worker logger asc'
global ASC_ACTIONS 'bootstrap init load reload unload install reinstall uninstall build rebuild start restart stop add remove process trigger watch compile test plan delay deploy destroy'
global ASC_VARIANTS 'pre post'
```

Given these arbitrary global variables (and values) - `ASC_SUBJECTS`, `ASC_ACTIONS` and `ASC_VARIANTS` (all space-separated strings) - we can attempt some formalism in the method of determining "possibilities". For instance :

1. Pick any combination of ASC_SUBJECTS, ASC_ACTIONS and/or ASC_VARIANTS.
1. Pick a differenciation syntax using prefix/suffix and/or delimiters like : `(space) -_,;:|=!?#&/*+.--` and/or enclosures such as : `____()[]{}""''`
1. Pick a generative mecanism

## Logical operators

Given ASC's minimalist ambition, it's delicate to mention yet another complexifying possibility.

TODO (missing documentation) evaluate relevance of pointing towards syntactic representations of condition, exclusion, alternative, union, ambivalence, equality, inversion (positive/negative)...

## Bash syntax

- Sourcing : prefer the shorter notation - single dot, ex: `. asc/aliases.sh`
- UPPERCASE / lowercase differenciates global variables from `local` variables (only used in function scopes)
- Parameters : variables storing values coming from arguments are prefixed with `P_` or `p_` (for *parameter*), ex: `$P_PROJECT_STACK`. See `asc/stack/init.sh`
- Function names for utilities in `asc/utilities` are all prefixed by `u_` (for *utility*), ex: `u_autoload_override`
- Separator for a single name having multiple words : use underscores `_` in variables, functions, and script/include names. Use dashes `-` in folder names.
- Dashes `-` in stack names are used to dynamically match env settings "dist" files (includes) - 1 dash = 1 dir level, ex: stack name `my_stack_name-3` would trigger lookups in `asc/env/dist/my-stack-name/app.vars.sh.dist`, `asc/env/dist/my-stack-name/3/app.vars.sh.dist`, etc. See `asc/env/README.md`.

TODO double file extension pattern
