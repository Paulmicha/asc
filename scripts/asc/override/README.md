# Overrides

If the "counterpart" of a given script exists in the folder `scripts/asc/override`, it will be used *instead* of the original file.

This allows to replace any includes or hook implementations.

Example : if we want to override `asc/git/init.hook.sh` - effectively bypassing the existing implementation, we'll create the following file :

```txt
scripts/asc/override/git/init.hook.sh
```

The matching is done by by replacing the leading `asc/` in filepaths with `scripts/asc/override/`. It works for extensions too. Here's an example using an include instead of a hook implementation for a change :

```txt
asc/extensions/docker-compose/docker-compose.inc.sh
-> scripts/asc/override/extensions/docker-compose/docker-compose.inc.sh
```
