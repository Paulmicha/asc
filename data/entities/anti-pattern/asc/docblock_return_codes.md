---
description: ASC docblocks must use the @return syntax to document all the return codes of a script or a function.
globs: '*.sh'
---

# Anti-pattern example (don't)

```sh
##
# Same as f_fs_compress() but presetting folder to compress in place.
#
# @see f_fs_compress()
#
# @param 1 String : the input (file or dir) path to compress.
#
# @example
#   # Will compress given path to arhive file inside dir 'path/to' :
#   f_fs_compress_in_place path/to/file.ext
#   # -> Result : path/to/file.ext.tgz
#   f_fs_compress_in_place path/to/folder
#   # -> Result : path/to/folder.tgz
#
f_fs_compress_in_place() {
  # (snip)
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
  # (snip)
}
```
