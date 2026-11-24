---
description: Every ASC shell script and function must use the @param syntax to specify all named options supported.
globs: '*.sh'
---

ASC uses a DocBlock convention originating from the classic Javadoc blueprint, but tailored for eventual static analysis.

# Anti-pattern example (don't)

The details cannot be missing.

## Named options only

```sh
##
# Batch-downloads remote files.
#
# @param n [optional] : named options.
#
# @example
#   make file-download-all foo_bar
#   # Or :
#   scripts/asc/extend/foobar/file_download_all.sh foo_bar
#
f_file_download_all() {
  # (snip)
}
```

## Mixed positional arguments + named options

```sh
##
# Batch-downloads remote files.
#
# @param 1 String : remote ID.
# @param n : additional named options (starting from $2).
#
# @example
#   make file-download-all foo_bar
#   # Or :
#   scripts/asc/extend/foobar/file_download_all.sh foo_bar
#
f_file_download_all() {
  # (snip)
}
```

# Correct example (do)

- Kind of arg (e.g. `[optional]`, `[repeatable]`) before data type (`String`, `Boolean (flag)`)
- 1 semicolon surrounded by space before prose description
- Indenting matters
- The default (fallback) values are on their own lines

## Named options only

```sh
##
# Batch-downloads remote files.
#
# @param -p|--path String : remote directory to list files from.
#   Defaults to 'json'.
# @param -f|--filter [repeatable] String : grep filter preset (files name match).
#   Defaults to ('foo' 'bar').
# @param -t|--to [repeatable] String : local download dir(s). One value applies
#   to all filters; multiple values pair by index with -f.
#   Defaults to absolute mirror under : data/download/{env}/{container}
# @param -a|--all Boolean (flag) : download all matching files.
#   Defaults to downloading just the latest per filter.
# @param -o|--overwrite Boolean (flag) : re-download existing local files.
#   Defaults to skipping.
#
# @example
#   make file-download-all foo_bar
#   # Or :
#   scripts/asc/extend/foobar/file_download_all.sh foo_bar
#
f_file_download_all() {
  # (snip)
}
```

## Mixed positional arguments + named options

If the order of named options and positional arguments do not matter :

```sh
##
# Batch-downloads remote files.
#
# @param n String : 1 or more remote IDs.
# @param -p|--path String : remote directory to list files from.
#   Defaults to 'json'.
# @param -f|--filter [repeatable] String : grep filter preset (files name match).
#   Defaults to ('foo' 'bar').
# @param -t|--to [repeatable] String : local download dir(s). One value applies
#   to all filters; multiple values pair by index with -f.
#   Defaults to absolute mirror under : data/download/{env}/{container}
# @param -a|--all Boolean (flag) : download all matching files.
#   Defaults to downloading just the latest per filter.
# @param -o|--overwrite Boolean (flag) : re-download existing local files.
#   Defaults to skipping.
#
# @example
#   make file-download-all foo_bar
#   # Or :
#   scripts/asc/extend/foobar/file_download_all.sh foo_bar
#
f_file_download_all() {
  # (snip)
}
```

If the named options are expected to begin after 1 or more positional arguments, use the form (ex: from 2nd arg): `@param n [optional] $2+ : additional named options.`, e.g. :

```sh
##
# Batch-downloads remote files.
#
# @param 1 String : remote ID.
# @param n [optional] $2+ : additional named options.
#   -p|--path String : remote directory to list files from.
#     Defaults to 'json'.
#   -f|--filter [repeatable] String : grep filter preset (files name match).
#     Defaults to ('foo' 'bar').
#   -t|--to [repeatable] String : local download dir(s). One value applies to
#     all filters; multiple values pair by index with -f.
#     Defaults to absolute mirror under : data/download/{env}/{container}
#   -a|--all Boolean (flag) : download all matching files.
#     Defaults to downloading just the latest per filter.
#   -o|--overwrite Boolean (flag) : re-download existing local files.
#     Defaults to skipping.
#
# @example
#   make file-download-all foo_bar
#   # Or :
#   scripts/asc/extend/foobar/file_download_all.sh foo_bar
#
f_file_download_all() {
  # (snip)
}
```
