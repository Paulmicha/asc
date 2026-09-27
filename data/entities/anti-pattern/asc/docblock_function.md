---
description: Every ASC shell function must have a preceding docblock describing what it does, how (when deemed not self-explanatory), and follows a Javadoc-like syntax to list eventual arguments, return codes, and references.
globs: '*.sh'
---

ASC uses unconventional Bash coding styleguides. In particular, it uses a DocBlock convention originating from the classic Javadoc blueprint, but tailored for eventual static analysis.

# Anti-pattern example (don't)

```sh
# Compresses a file in its own folder.
# Returns the exit code of f_fs_compress().
f_fs_compress_in_place() {
  local p_path_to_compress_in_place="$1"
  local leaf="${p_path_to_compress_in_place##*/}"
  local base_path="${p_path_to_compress_in_place%/$leaf}"
  f_fs_compress "$p_path_to_compress_in_place" "$base_path"
  return $?
}
```

# Correct example (do)

```sh
##
# Same as f_fs_compress() but presetting folder to compress in place.
#
# @see f_fs_compress()
#
# @param 1 String : the input (file or dir) path to compress.
#
# @return
#   0 : success
#   1 : input (file or dir) path does not exist
#   2 : destination folder does not exist
#   $? : return code of the tar command
#
# @example
#   # Will compress given path to arhive file inside dir 'path/to' :
#   f_fs_compress_in_place path/to/file.ext
#   # -> Result : path/to/file.ext.tgz
#   f_fs_compress_in_place path/to/folder
#   # -> Result : path/to/folder.tgz
#
f_fs_compress_in_place() {
  local p_path_to_compress_in_place="$1"
  local leaf="${p_path_to_compress_in_place##*/}"
  local base_path="${p_path_to_compress_in_place%/$leaf}"

  f_fs_compress \
    "$p_path_to_compress_in_place" \
    "$base_path"

  return $?
}
```
