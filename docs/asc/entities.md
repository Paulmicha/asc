# ASC core concept : Entities (synonym : node ?)

TODO rewrite below contents with sections :

1. represents ? (why it exists)
1. definition (scope ?)
1. capabilities
1. relationships
1. compatibility, applicability ? (protocols, etc)
1. yml includes

--

## General idea (the shape of contracts for defining entities)

TODO *.yml minimal structure to say "hello, this entity depends on :"
  - foobar.dependency.yml (pipx, git repo, generic source, deb package, appimage, apt-related ...)
  - foobar.asc-extension.yml ?
  - foobar.hardware.yml ? version ? version.able ?
  - foobar.software.yml ? version ? version.able ?
  - foobar.state.yml

TODO asc/extensions/entity/is/able.sh (entity contracts : cognition.able, etc)
TODO asc/extensions/entity/is/event.sh (source : manual, agent, cronjob, interaction, timestamp...)
TODO asc/extensions/entity/is/public.sh
TODO asc/extensions/entity/is/private.sh
TODO asc/extensions/entity/is/relation.sh (for fieldable relationships)
TODO asc/extensions/entity/is/root.sh (synonyms : primordial, prime, original)
TODO asc/extensions/entity/is/sibling.sh (synonyms : neighbor, sister, brother)
TODO asc/extensions/entity/is/leaf.sh

TODO asc/extensions/entity/has/label.sh (synonyms : title, name)
TODO asc/extensions/entity/has/type.sh (synonyms : category)
TODO asc/extensions/entity/has/bundle.sh (synonyms : subtype)
TODO asc/extensions/entity/has/plan.sh
TODO asc/extensions/entity/has/log.sh
TODO asc/extensions/entity/has/changelog.sh
TODO asc/extensions/entity/has/idea.sh
TODO asc/extensions/entity/has/sidecar.sh
TODO asc/extensions/entity/has/wrapper.sh
TODO asc/extensions/entity/has/nested.sh (synonyms : children, child)
TODO asc/extensions/entity/has/sibling.sh (synonyms : neighbor, sister, brother)
TODO asc/extensions/entity/has/parent.sh (synonyms : genitor, mother, father)
TODO asc/extensions/entity/has/ancestor.sh
TODO asc/extensions/entity/has/descendants.sh
TODO asc/extensions/entity/has/primitive.sh
TODO asc/extensions/entity/has/primordial.sh
TODO asc/extensions/entity/has/relation.sh (of type foobar, matching emitters / recievers, etc)
TODO asc/extensions/entity/has/permission.sh
TODO asc/extensions/entity/has/restriction.sh
TODO asc/extensions/entity/has/field.sh
TODO asc/extensions/entity/has/origin.sh
TODO asc/extensions/entity/has/author.sh
TODO asc/extensions/entity/has/license.sh
TODO asc/extensions/entity/has/version.sh
TODO asc/extensions/entity/has/state.sh (synonym : status ? Close to : health, vitals)
TODO asc/extensions/entity/has/created.sh (synonyms : written, creation (<date,datestamp,timestamp>))
TODO asc/extensions/entity/has/changed.sh (synonyms : touched, modification (<date,datestamp,timestamp>))

TODO asc/extensions/entity/implements/hook.sh
TODO asc/extensions/entity/uses/global.sh

## Dependencies

- ASC
- Core extension : entity

## Capabilities

TODO recap all *.able.yml known to date :

- "$wrap.able" (asc log, host process, asc thread, logged-thread = lt, etc)
- "$action.able" (asc entry points by subject - ex: rotate, recognize, protocol, asc/extensions/entity/has/cognition.sh, etc - TODO categorize could be synonym of taxonomy.able ?)
- "$sidecar.able" (changelog, accesslog ?, timestamp (ms precision, last 5min...), datestamp (daily, monthly, yearly))
- "$field.able"

Other (unelaborated) *.able.yml :
- contract.able : the original "able"
- break.able : will it ever end ?
- hook.able : or implement.able or both ? (emitter / reciever ~ directional thing ?)
- nest.able : nested-git, nested-asc, nested-host (vm ?), nested-cmd ?, nested-process ?, nested-thread ?, nested-protocol ? nested-crypt ? etc.
- crud.able : TODO or just hardcoded default actions in entities instead ?
- forget.able : All (forget.able ?) data must have a lifetime (logrotate-like but for any data/* structure)
- depend.able : TODO contrib extensions (remote git repos ?)
- build.able : TODO blueprints (delegated pattern extractors ? partially out of scope)
- "$use.able" (TODO asc/extensions/entity/uses/global.sh ?)

## Entities

- Primordial = most generic = empty object = the entity.entity.yml definition (mother of all entities)
- Inheriting is done like remote instances yml "includes"
- Inheriting from Parent(s) entities could be synonym of "genericity".

Scale of entities "nesting", descending order of most to least :

1. primordial = most abstract
1. primitive ancestor ?
1. ancestor = up to level n - 2
1. parent = level n - 1
1. self = level n
1. child = level n + 1
1. descendants = from level n + 2

In ASC, the "core" (upstream repo) represents up to "primitive-level" contracts and implementations.

## Subjects x Actions

- TODO entity types (type is a field)
- TODO taxonomy : patternify ?

## Hooks

- TODO
