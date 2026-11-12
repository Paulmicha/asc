---
description: In most programming languages, line breaks must allow some breathing room to guide the reader's eyes and allow quick visual scanning of code blocks.
globs: '*.sh, *.yml, *.py, *.js, *.jsx, *.php, *.rust, *.go, *.java, *.c, *.cpp'
---

Regroup neighbouring lines in logical groups, always leaving at least 1 line break before new multiline blocks like conditions, loops, case enumerations, etc.

All functions, conditions and loops must not have their inner first and last lines be an empty line.

# Anti-pattern example (don't)

## Conditional blocks

Any multiline conditional block cannot be left without surrounding line breaks.

```sh
local p_file="$1"
local p_folder="$2"
if [[ ! -f "$p_file" ]]; then
  echo >&2
  echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: file '$p_file' was not found." >&2
  echo "Aborting (2)." >&2
  echo >&2
  return 2
fi
if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
  echo >&2
  echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
  echo "Aborting (3)." >&2
  echo >&2
  return 3
fi
```

## Case and switch blocks

Same as conditional blocks : surrounding line breaks must be placed befor and
after the entire block. If any "case" nested block has more than one line, then
a line break must also separate the next block after the end of the previous
block.

### Single line nested blocks

```sh
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o)
      p_project_docroot="$2"; shift 2
      ;;
    -s)
      p_stack_version="$2"; shift 2
      ;;
    -a)
      p_apps="$2"; shift 2
      ;;
    -h)
      p_host_type="$2"; shift 2
      ;;
    -t)
      p_instance_type="$2"; shift 2
      ;;
    -p)
      p_provision_using="$2"; shift 2
      ;;
    -y)
      p_yes=1; shift 1
      ;;
    -r)
      p_dry_run=1; shift 1
      ;;
    -*)
      echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return
      ;;
    *)
      echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1
      ;;
  esac
done
```

### Multiline nested blocks

```sh
case "$p_file" in
  *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
    untouched=0
    7z x "$p_file"
    ;;
  *.gz)
    untouched=0
    gunzip -k "$p_file"
    ;;
  *.cbz|*.epub|*.zip)
    untouched=0
    unzip "$p_file"
    ;;
esac
```

## Files and/or functions docblocks contents

Line breaks help reading the dockblock contents faster.

```sh
##
# Extracts given archive file(s). Supports various formats.
# This function uses a return value to indicate wether the file was uncompressed
# or not. It also sets the uncompressed file names to a variable
# subject to collision in calling scope :
# @var extracted_files
# If the archive contained a single file, it will set its name to the following
# variable subject to collision in calling scope :
# @var extracted_file
# @param 1 String : the archive file to extract.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
#   TODO [wip] Only tested with tar program. We need to check other programs
#   behaviors (if they uncompress files in place or inside current folder).
# See https://github.com/xvoland/Extract
# This function deliberately does nothing if it does not detect a file extension
# matching some archive format whitelisted below.
# @example
#   # Extract given archive files in current dir :
#   extracted_files=''
#   f_fs_extract path/to/file.zip
#   echo "$extracted_files" # <- Outputs list of extracted contents.
#   # Extract given archive containing a single file to folder 'path/to' :
#   extracted_file=''
#   f_fs_extract path/to/file.sql.tgz path/to
#   echo "$extracted_file" # <- Outputs e.g. path/to/file.sql
#   # Will leave the file untouched because it is not an archive file :
#   f_fs_extract path/to/file.txt
#   echo $? # Will print '1' (indicates that the file was untouched).
f_fs_extract() {
  # (snip)
}
```

## Return statement

Any return statement must be separated from the rest of the code by a line break
unless the function contains less than 5 lines.

```sh
f_fs_extract() {
  local p_file="$1"
  local p_folder="$2"
  # (snip)
  if [[ $untouched -eq 0 ]]; then
    f_fs_trim_compression_ext "$p_file"
    if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
      echo "File was uncompressed successfully to :"
      echo "  $uncompressed_file"
      extracted_file="$uncompressed_file"
    fi
  fi
  return $untouched
}
```

## Code comments and docblocks

When a portion of a function or script needs explanation, comments must be set
apart from the preceding content with a line break. No line break must stand
between the code they relate to and the comments themselves.

This also applies to docblocks.

```sh
f_fs_extract() {
  # (snip)
  local untouched=1
  local needs_copy='y'
  local original_file="$p_file"
  # If the uncompressed file already exists, consider it was uncompressed.

  local uncompressed_file=''
  f_fs_trim_compression_ext "$p_file"
  if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
    echo "Uncompressed file $uncompressed_file already exists."
    echo "  -> Skip uncompress (but still produce the same result as if archive was successfully uncompressed)."
    extracted_file="$uncompressed_file"
    return
  fi
  # In order to correctly handle the 2nd parameter (destination folder), we
  # process the 'tar' command separately.
  case "$p_file" in *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
    # (snip)
  esac
}
```

# Correct example (do)

## Conditional blocks

Any multiline conditional block cannot be left without surrounding line breaks.

```sh
local p_file="$1"
local p_folder="$2"

if [[ ! -f "$p_file" ]]; then
  echo >&2
  echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: file '$p_file' was not found." >&2
  echo "Aborting (2)." >&2
  echo >&2
  return 2
fi

if [[ -n "$p_folder" ]] && [[ ! -d "$p_folder" ]]; then
  echo >&2
  echo "Notice in f_fs_extract() - $BASH_SOURCE line $LINENO: directory '$p_folder' was not found." >&2
  echo "Aborting (3)." >&2
  echo >&2
  return 3
fi
```

## Case and switch blocks

Same as conditional blocks : surrounding line breaks must be placed befor and
after the entire block. If any "case" nested block has more than one line, then
a line break must also separate the next block after the end of the previous
block.

### Single line nested blocks

```sh
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) p_project_docroot="$2"; shift 2;;
    -s) p_stack_version="$2"; shift 2;;
    -a) p_apps="$2"; shift 2;;
    -h) p_host_type="$2"; shift 2;;
    -t) p_instance_type="$2"; shift 2;;
    -p) p_provision_using="$2"; shift 2;;
    -y) p_yes=1; shift 1;;
    -r) p_dry_run=1; shift 1;;
    -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return;;
    *) echo "Notice in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; shift 1;;
  esac
done
```

### Multiline nested blocks

```sh
case "$p_file" in
  *.7z|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
    untouched=0
    7z x "$p_file"
    ;;

  *.gz)
    untouched=0
    gunzip -k "$p_file"
    ;;

  *.cbz|*.epub|*.zip)
    untouched=0
    unzip "$p_file"
    ;;
esac
```

## Files and/or functions docblocks contents

Line breaks help reading the dockblock contents faster.

```sh
##
# Extracts given archive file(s). Supports various formats.
#
# This function uses a return value to indicate wether the file was uncompressed
# or not. It also sets the uncompressed file names to a variable
# subject to collision in calling scope :
#
# @var extracted_files
#
# If the archive contained a single file, it will set its name to the following
# variable subject to collision in calling scope :
#
# @var extracted_file
#
# @param 1 String : the archive file to extract.
# @param 2 [optional] String : the destination folder. Defaults to current dir.
#   TODO [wip] Only tested with tar program. We need to check other programs
#   behaviors (if they uncompress files in place or inside current folder).
#
# See https://github.com/xvoland/Extract
#
# This function deliberately does nothing if it does not detect a file extension
# matching some archive format whitelisted below.
#
# @example
#   # Extract given archive files in current dir :
#   extracted_files=''
#   f_fs_extract path/to/file.zip
#   echo "$extracted_files" # <- Outputs list of extracted contents.
#
#   # Extract given archive containing a single file to folder 'path/to' :
#   extracted_file=''
#   f_fs_extract path/to/file.sql.tgz path/to
#   echo "$extracted_file" # <- Outputs e.g. path/to/file.sql
#
#   # Will leave the file untouched because it is not an archive file :
#   f_fs_extract path/to/file.txt
#   echo $? # Will print '1' (indicates that the file was untouched).
#
f_fs_extract() {
  # (snip)
}
```

## Return statement

Any return statement must be separated from the rest of the code by a line break
unless the function contains less than 5 lines.

```sh
f_fs_extract() {
  local p_file="$1"
  local p_folder="$2"

  # (snip)

  if [[ $untouched -eq 0 ]]; then
    f_fs_trim_compression_ext "$p_file"

    if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
      echo "File was uncompressed successfully to :"
      echo "  $uncompressed_file"
      extracted_file="$uncompressed_file"
    fi
  fi

  return $untouched
}
```

## Code comments and docblocks

When a portion of a function or script needs explanation, comments must be set
apart from the preceding content with a line break. No line break must stand
between the code they relate to and the comments themselves.

This also applies to docblocks.

```sh
f_fs_extract() {
  # (snip)
  local untouched=1
  local needs_copy='y'
  local original_file="$p_file"

  # If the uncompressed file already exists, consider it was uncompressed.
  local uncompressed_file=''

  f_fs_trim_compression_ext "$p_file"

  if [[ -n "$uncompressed_file" && -f "$uncompressed_file" ]]; then
    echo "Uncompressed file $uncompressed_file already exists."
    echo "  -> Skip uncompress (but still produce the same result as if archive was successfully uncompressed)."
    extracted_file="$uncompressed_file"
    return
  fi
  
  # In order to correctly handle the 2nd parameter (destination folder), we
  # process the 'tar' command separately.
  case "$p_file" in *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
    # (snip)
  esac
}
```
