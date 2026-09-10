#!/usr/bin/env bash

##
# (re)Generates a table of contents in the given markdown file.
#
# Replaces the markdown list inside the first <nav> ... </nav> block.
# ATX headings are collected fence-aware (same as asc/doc/md_merge.sh).
# Skips the document H1 and a "Table of contents" heading.
#
# @param 1 String: path to the markdown file.
#
# @example
#   make doc-md-toc 'path/to/file.md'
#   # Or :
#   asc/doc/md_toc.sh 'path/to/file.md'
#

. asc/bootstrap.sh

p_md=''

u_md_toc_usage() {
  echo "Usage: asc/doc/md_toc.sh <file.md>" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -*)
      echo "Unknown option: $1" >&2
      u_md_toc_usage
      exit 1
      ;;
    *)
      if [[ -z "$p_md" ]]; then
        p_md="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        u_md_toc_usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$p_md" ]]; then
  u_md_toc_usage
  exit 1
fi

p_md="${p_md#./}"

if [[ ! -f "$p_md" ]]; then
  echo "File not found: $p_md" >&2
  exit 1
fi

if [[ "${p_md##*.}" != 'md' ]]; then
  echo "Expected a .md file: $p_md" >&2
  exit 1
fi

# Emit "level<TAB>title" for each ATX heading outside fences and <nav>.
# Same fence rules as asc/doc/md_merge.sh. Skip H1 and "Table of contents".
u_md_list_headings() {
  awk '
    BEGIN { in_fence = 0; in_nav = 0 }
    {
      if ($0 ~ /^[ \t]{0,3}(```|~~~)/) {
        in_fence = !in_fence
        next
      }
      if (in_fence) {
        next
      }
      if (!in_nav && $0 ~ /^<nav>[[:space:]]*$/) {
        in_nav = 1
        next
      }
      if (in_nav && $0 ~ /^<\/nav>[[:space:]]*$/) {
        in_nav = 0
        next
      }
      if (in_nav) {
        next
      }
      if ($0 ~ /^#+([ \t]|$)/) {
        level = 0
        rest = $0
        while (substr(rest, 1, 1) == "#") {
          level++
          rest = substr(rest, 2)
        }
        sub(/^[ \t]+/, "", rest)
        sub(/[ \t]+#*[ \t]*$/, "", rest)
        if (level < 2 || rest == "" || rest == "Table of contents") {
          next
        }
        print level "\t" rest
      }
    }
  '
}

# GitHub-ish slug for markdown TOC anchors (same as asc/doc/md_merge.sh).
u_md_slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^[:alnum:][:space:]-]//g' -e 's/[[:space:]]\+/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//'
}

u_md_write_toc() {
  local level title slug indent i base_slug
  declare -A slug_count=()

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
    indent=$((level > 2 ? level - 2 : 0))
    for ((i = 0; i < indent; i++)); do
      printf '  '
    done
    printf -- '- [%s](#%s)\n' "$title" "$slug"
  done
}

out_dir="$(dirname -- "$p_md")"
out_base="$(basename -- "$p_md")"
tmp_toc="$(mktemp --tmpdir="$out_dir" ".${out_base}.toc.XXXXXX")"
tmp_out="$(mktemp --tmpdir="$out_dir" ".${out_base}.XXXXXX")"
trap 'rm -f -- "$tmp_toc" "$tmp_out"' EXIT

u_md_list_headings <"$p_md" | u_md_write_toc >"$tmp_toc"

awk -v toc_file="$tmp_toc" '
  BEGIN { in_nav = 0; seen_nav = 0; closed_nav = 0 }
  {
    if (!in_nav && $0 ~ /^<nav>[[:space:]]*$/) {
      if (seen_nav) {
        print
        next
      }
      seen_nav = 1
      in_nav = 1
      print
      print ""
      while ((getline line < toc_file) > 0) {
        print line
      }
      print ""
      close(toc_file)
      next
    }
    if (in_nav && $0 ~ /^<\/nav>[[:space:]]*$/) {
      in_nav = 0
      closed_nav = 1
      print
      next
    }
    if (in_nav) {
      next
    }
    print
  }
  END {
    if (!seen_nav || !closed_nav) {
      exit 2
    }
  }
' "$p_md" >"$tmp_out"
awk_rc=$?

if [[ "$awk_rc" -ne 0 ]]; then
  echo "No <nav> ... </nav> block found in: $p_md" >&2
  exit 1
fi

mv -f -- "$tmp_out" "$p_md"
trap - EXIT
rm -f -- "$tmp_toc"

echo "Updated TOC in $p_md"
