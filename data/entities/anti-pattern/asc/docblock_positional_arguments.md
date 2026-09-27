---
description: Every ASC shell script and function must use the @param syntax to specify all positional arguments supported.
globs: '*.sh'
---

ASC uses a DocBlock convention originating from the classic Javadoc blueprint, but tailored for eventual static analysis.

# Anti-pattern example (don't)

- non-standard position syntax,
- inconsistent "optional" mentions,
- no default values,
- no ending dots.

```sh
# @param $1 dir where to look
# @param 2 file name filter pattern
# @param 3 Optional - Max depth
```

# Correct example (do)

```sh
# @param 1 [optional] String : the dir where to look.
#   Defaults to '.' (PROJECT_DOCROOT).
# @param 2 [optional] String : file name filter pattern.
#   Defaults to '', meaning : don't filter.
# @param 3 [optional] Number : max depth (to look in subfolders too).
#   Defaults to 1.
# @param 4 [optional] Number : how many most recent files to get.
#   Defaults to 1.
# @param 5 [optional] String : output var name (default: fs_most_recent).
#
```
