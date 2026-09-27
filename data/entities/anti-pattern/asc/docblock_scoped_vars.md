---
description: ASC docblocks must use the @var syntax to indicate variables read and/or written in current shell scope.
globs: '*.sh'
---

# Anti-pattern example (don't)

```sh
##
# Gets all unique unordered combinations of given string values.
#
# @link https://codereview.stackexchange.com/questions/7001/generating-all-combinations-of-an-array_dict
# @link https://stackoverflow.com/a/23653825
#
# @param 1 String : space-separated values.
# @param 2 [optional] String : concatenation separator. Defaults to '' (empty).
# @param 3 [optional] String : separator between items. Defaults to space.
#
# @example
#   f_str_subsequences "a b c d"
#   echo "$str_subsequences" # a ab abc abcd abd ac acd ad b bc bcd bd c cd d
#
#   # Custom concatenation character.
#   f_str_subsequences "a b c d" '.'
#   for i in $str_subsequences; do
#     echo "$i" # Ex: a.b.c.d
#   done
#
f_transliterate_char() {
  # (snip)
}
```

# Correct example (do)

```sh
##
# Gets all unique unordered combinations of given string values.
#
# @link https://codereview.stackexchange.com/questions/7001/generating-all-combinations-of-an-array_dict
# @link https://stackoverflow.com/a/23653825
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var str_subsequences
#
# @param 1 String : space-separated values.
# @param 2 [optional] String : concatenation separator. Defaults to '' (empty).
# @param 3 [optional] String : separator between items. Defaults to space.
#
# @example
#   f_str_subsequences "a b c d"
#   echo "$str_subsequences" # a ab abc abcd abd ac acd ad b bc bcd bd c cd d
#
#   # Custom concatenation character.
#   f_str_subsequences "a b c d" '.'
#   for i in $str_subsequences; do
#     echo "$i" # Ex: a.b.c.d
#   done
#
f_transliterate_char() {
  # (snip)
}
```
