#!/usr/bin/env bash

##
# Merges all markdown files inside given folder into a single markdown file.
#
# Direct children only (non-recursive). Natural sort (sort -V).
# The result gets written by default to the parent dir.
# It also rewrites ATX heading levels to increase them (fence-aware), e.g. :
#
# - "# main subfile title" becomes "## main subfile title"
# - "## secondary subfile title" becomes "### secondary subfile title"
# - etc.
#
# The resulting markdown file contents also get prepended with a main title
# which is the name of the folder. Ex : folder "path/to/The Title of the Folder"
# -> main title prepended : "# The Title of the Folder"
#
# Right after that title, a "## Table of contents" lists every ATX heading from
# the merged body (fence-aware), as markdown links with GitHub-style anchors.
#
# Between source files: blank line, thematic break (---), blank line.
#
# @param n [optional] String : named options.
#   --force (flag) : overwrite an existing output file.
# @param 1 String: path to folder containing the markdown files to merge.
# @param 2 [optional] String: resulting file path.
#
# @example
#   # Merges all *.md files in folder 'path/to/foobar' :
#   make doc-md-merge path/to/foobar
#   # Or :
#   asc/doc/md_merge.sh path/to/foobar
#   # -> Result : path/foobar.md
#
#   asc/doc/md_merge.sh --force path/to/foobar path/custom.md
#

. asc/bootstrap.sh

p_force=0
p_folder=''
p_out=''

u_md_merge_usage() {
  echo "Usage: asc/doc/md_merge.sh [--force] <folder> [output.md]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      p_force=1
      shift
      ;;
    -*)
      echo "Unknown option: $1" >&2
      u_md_merge_usage
      exit 1
      ;;
    *)
      if [[ -z "$p_folder" ]]; then
        p_folder="$1"
      elif [[ -z "$p_out" ]]; then
        p_out="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        u_md_merge_usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$p_folder" ]]; then
  u_md_merge_usage
  exit 1
fi

p_folder="${p_folder#./}"
p_folder="${p_folder%/}"

if [[ ! -d "$p_folder" ]]; then
  echo "Not a directory: $p_folder" >&2
  exit 1
fi

folder_base="$(basename -- "$p_folder")"
folder_parent="$(dirname -- "$p_folder")"

if [[ -z "$p_out" ]]; then
  if [[ "$folder_parent" == '.' ]]; then
    p_out="${folder_base}.md"
  else
    p_out="${folder_parent}/${folder_base}.md"
  fi
fi
p_out="${p_out#./}"

# Resolve absolute paths for exclude / exists checks.
folder_abs="$(cd -- "$p_folder" && pwd)"
out_dir="$(dirname -- "$p_out")"
out_base="$(basename -- "$p_out")"
mkdir -p -- "$out_dir"
out_abs="$(cd -- "$out_dir" && pwd)/${out_base}"

if [[ -e "$p_out" ]] && [[ "$p_force" -eq 0 ]]; then
  echo "Output exists (pass --force to overwrite): $p_out" >&2
  exit 1
fi

mapfile -t src_files < <(
  find "$p_folder" -maxdepth 1 -type f -name '*.md' -printf '%f\n' \
    | sort -V \
    | while IFS= read -r name; do
        src="${p_folder}/${name}"
        src_abs="$(cd -- "$(dirname -- "$src")" && pwd)/$(basename -- "$src")"
        if [[ "$src_abs" == "$out_abs" ]]; then
          continue
        fi
        printf '%s\n' "$src"
      done
)

if [[ ${#src_files[@]} -eq 0 ]]; then
  echo "No *.md files to merge in: $p_folder" >&2
  exit 1
fi

# Fence-aware ATX heading bump (+1, no clamp). Portable awk (mawk/gawk).
u_md_bump_headings() {
  awk '
    BEGIN { in_fence = 0 }
    {
      if ($0 ~ /^[ \t]{0,3}(```|~~~)/) {
        in_fence = !in_fence
        print
        next
      }
      if (!in_fence && $0 ~ /^#{1,6}([ \t]|$)/) {
        print "#" $0
        next
      }
      print
    }
  '
}

# Emit "level<TAB>title" for each ATX heading outside fences (already-bumped body).
u_md_list_headings() {
  awk '
    BEGIN { in_fence = 0 }
    {
      if ($0 ~ /^[ \t]{0,3}(```|~~~)/) {
        in_fence = !in_fence
        next
      }
      if (!in_fence && $0 ~ /^#+([ \t]|$)/) {
        level = 0
        rest = $0
        while (substr(rest, 1, 1) == "#") {
          level++
          rest = substr(rest, 2)
        }
        sub(/^[ \t]+/, "", rest)
        sub(/[ \t]+#*[ \t]*$/, "", rest)
        if (rest != "") {
          print level "\t" rest
        }
      }
    }
  '
}

# GitHub-ish slug for markdown TOC anchors.
u_md_slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^[:alnum:][:space:]-]//g' -e 's/[[:space:]]\+/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//'
}

u_md_write_toc() {
  local level title slug indent i base_slug
  declare -A slug_count=()

  printf '## Table of contents\n\n'

  while IFS=$'\t' read -r level title; do
    [[ -n "$level" && -n "$title" ]] || continue
    base_slug="$(u_md_slug "$title")"
    [[ -n "$base_slug" ]] || continue
    if [[ -n "${slug_count[$base_slug]+x}" ]]; then
      slug_count[$base_slug]=$((slug_count[$base_slug] + 1))
      slug="${base_slug}-${slug_count[$base_slug]}"
    else
      slug_count[$base_slug]=0
      slug="$base_slug"
    fi
    # Body headings are typically ##+ under the folder H1.
    indent=$((level > 2 ? level - 2 : 0))
    for ((i = 0; i < indent; i++)); do
      printf '  '
    done
    printf -- '- [%s](#%s)\n' "$title" "$slug"
  done

  printf '\n'
}

tmp_body="$(mktemp --tmpdir="$out_dir" ".${out_base}.body.XXXXXX")"
tmp_out="$(mktemp --tmpdir="$out_dir" ".${out_base}.XXXXXX")"
trap 'rm -f -- "$tmp_body" "$tmp_out"' EXIT

{
  n=${#src_files[@]}
  for ((i = 0; i < n; i++)); do
    u_md_bump_headings < "${src_files[$i]}"
    if ((i < n - 1)); then
      printf '\n---\n\n'
    fi
  done
} >"$tmp_body"

{
  printf '# %s\n\n' "$folder_base"
  u_md_list_headings <"$tmp_body" | u_md_write_toc
  cat -- "$tmp_body"
} >"$tmp_out"

mv -f -- "$tmp_out" "$p_out"
trap - EXIT
rm -f -- "$tmp_body"

echo "Merged ${#src_files[@]} file(s) -> $p_out"
