Thinking about builder / blueprints and a DSL for describing needs expressed in ASC primitives.

Earlier example :

a “cursor” extension provides the concrete agent (hook or override) implementation, an entry point like “make cursor-analyze” could be a slot (or wrap) of any local implementation of e.g. agent.

-> possible notation : `log-wrap.thread-wrap.agent-prompt.ollama-exec`
-> possible asc DSL syntax rules to represent any "controlled" entry point :

- wrappers : '.'
- nesters : '()'
- relations : '--' (key-val) or '--foobar--' (triple)
- same word separator : '_'
- arguments : comma-separated values in '[]' of either :
    - positional arguments like $1 : unprefixed ('$key-$value')
    - boolean option (= boolean argument) : prefix 'b-' ('b-$key')
    - options (= named arguments) : prefix 'o-' ('o-$key-$value')

Ex :

make giw log -- --oneline

could be noted :

`instance-giw[log,b-oneline]]`

Contrived example :

`log-wrap[retention-5m].thread-wrap.agent-prompt[role-prompt_analyst].hook-ms[o-s-agent,o-a-exec](ollama-exec[slot])`

Or :

```txt
log-wrap[retention-5m]
  .thread-wrap
  .agent-prompt[role-prompt_analyst]
  .hook-ms[o-s-agent, o-a-exec](
    ollama-exec[slot]
  )
```

this tells which wrappers are used, where the hook is declared, where it is implemented, and the wrap + nesting chain of the whole entry point = call.

--

Difference between calling and sourcing a shell script (same arguments, same options)  
Wrapper vs slot (vertical vs horizontal structure)

Could be a type of relation :

Relation.able.yml inheritance example :  
is:

- protocol.able  
- field.able

--

TODO make prefixed options uniformization (instead of "-a foobar" or "--a foobar" use "a:foobar" everywhere) // chantier e_foobar scope var, f_foobar functions, (local) p_foobar argument, (local) o_foobar option)

--

TODO overall args vs options uniformization

--

Owner.able ex : agent vs human wrappers !

Usable example : dl web using either curl or wget ("important" software entry points in core ?)

Ideal.able : game of go, get there in as few steps and using as few atoms templates etc

Need a field thing for plain string templates vs file templates

Make idea promptable

Git branching alternative models  
Semver.able

Builder soit refactor soit generator - gen only in asc scope !

TODO expressing need ?

TODO ASC core reserved keywords (DSL idea to express complex, nested chains)

a DSL for ASC control plane ?
