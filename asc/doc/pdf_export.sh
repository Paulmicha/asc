#!/usr/bin/env bash

##
# Export markdown under data/ideas and docs to PDF (beside each source .md).
#
# Ex : 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).md'
#   -> 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).pdf'
#
# @requires https://github.com/rbutinar/md2pdf-mermaid
# Styled via asc/doc/md2pdf_asc.py + pdf_styles.css (Spectral, compact 8pt).
# Mermaid: local asc/vendor/mermaid.esm.min.mjs (offline).
# KaTeX: local asc/vendor/katex/ (CSS + JS + auto-render, offline).
#
# @param n [optional] String : any additional named option.
#   --force (flag) : Force re-compiling already compiled pdfs. By default, only
#   missing or outdated files are compiled.
#
# @example
#   # All *.md files found in ./data/ideas and ./docs :
#   asc/doc/pdf_export.sh
#
#   # Force re-compiling already compiled pdfs :
#   asc/doc/pdf_export.sh --force
#
#   # Single file :
#   asc/doc/pdf_export.sh 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).md'
#   asc/doc/pdf_export.sh --force 'docs/asc/builder.md'
#
#   # All *.md files under a folder (recursive) :
#   asc/doc/pdf_export.sh 'data/ideas/2026/08'
#   asc/doc/pdf_export.sh --force docs/asc
#

. asc/bootstrap.sh

# md2pdf uses Playwright/Chromium. Agent sandboxes often pre-set PLAYWRIGHT_BROWSERS_PATH
# to an empty temp dir; when the user has browsers under ~/.cache/ms-playwright, use that.
pdf_playwright_prepare() {
  if [[ -d "${HOME}/.cache/ms-playwright" ]]; then
    export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"
    return 0
  fi
  local md2pdf_bin pw_bin
  md2pdf_bin="$(command -v md2pdf)" || return 0
  pw_bin="$(dirname "$md2pdf_bin")/playwright"
  [[ -x "$pw_bin" ]] || return 0
  export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"
  echo "Installing Playwright Chromium for md2pdf (one-time)…"
  "$pw_bin" install chromium
}

pdf_playwright_prepare

p_target=''
p_all=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      p_all=1
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      if [[ -n "$p_target" ]]; then
        echo "Unexpected extra argument: $1"
        exit 1
      fi
      p_target="$1"
      shift
      ;;
  esac
done

if ! command -v md2pdf >/dev/null 2>&1; then
  echo "md2pdf is not installed or not on PATH."
  echo "See https://github.com/rbutinar/md2pdf-mermaid"
  exit 1
fi

# Prefer the pipx venv Python so md2pdf imports resolve; fall back to PATH python3.
pdf_md2pdf_python() {
  local md2pdf_bin md2pdf_dir candidate
  md2pdf_bin="$(command -v md2pdf)" || return 1
  md2pdf_dir="$(dirname "$md2pdf_bin")"
  for candidate in "$md2pdf_dir/python" "$md2pdf_dir/python3"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  if [[ -x "${HOME}/.local/share/pipx/venvs/md2pdf-mermaid/bin/python" ]]; then
    echo "${HOME}/.local/share/pipx/venvs/md2pdf-mermaid/bin/python"
    return 0
  fi
  command -v python3
}

PDF_MD2PDF_PY="$(pdf_md2pdf_python)"
PDF_ASC_WRAPPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/md2pdf_asc.py"
if [[ ! -f "$PDF_ASC_WRAPPER" ]]; then
  echo "ASC md2pdf wrapper not found: $PDF_ASC_WRAPPER"
  exit 1
fi

if [[ ! -f "asc/vendor/mermaid.esm.min.mjs" ]]; then
  echo "Local Mermaid not found: asc/vendor/mermaid.esm.min.mjs"
  exit 1
fi

if [[ ! -f "asc/vendor/katex/katex.min.js" ]]; then
  echo "Local KaTeX not found: asc/vendor/katex/"
  exit 1
fi

# True if path is under data/ideas or docs (relative or absolute).
doc_under_export_roots() {
  local p="$1" abs
  p="${p#./}"
  p="${p%/}"
  case "$p" in
    data/ideas|data/ideas/*|docs|docs/*) return 0 ;;
  esac
  if [[ -e "$p" ]]; then
    if [[ -d "$p" ]]; then
      abs="$(cd "$p" && pwd)"
    else
      abs="$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
    fi
    case "$abs" in
      "$PWD/data/ideas"|"$PWD/data/ideas/"*|"$PWD/docs"|"$PWD/docs/"*) return 0 ;;
    esac
  fi
  return 1
}

doc_is_exportable_md() {
  local p_md="$1"
  [[ -f "$p_md" ]] || return 1
  [[ "${p_md##*.}" == 'md' ]] || return 1
  doc_under_export_roots "$p_md"
}

doc_md_to_pdf() {
  local p_md="$1"
  echo "${p_md%.md}.pdf"
}

doc_pdf_needs_export() {
  local p_md="$1"
  local pdf
  pdf="$(doc_md_to_pdf "$p_md")"
  [[ ! -f "$pdf" ]] || [[ "$p_md" -nt "$pdf" ]]
}

doc_pdf_export_one() {
  local p_md="$1"
  local pdf
  pdf="$(doc_md_to_pdf "$p_md")"
  if [[ "$p_all" -eq 0 ]] && ! doc_pdf_needs_export "$p_md"; then
    echo "skip (up to date): $p_md"
    return 0
  fi
  mkdir -p "$(dirname "$pdf")"
  echo "$p_md -> $pdf"
  "$PDF_MD2PDF_PY" "$PDF_ASC_WRAPPER" "$p_md" -o "$pdf"
}

doc_pdf_export_tree() {
  local root="$1"
  local found=0
  while IFS= read -r -d '' md; do
    md="${md#./}"
    found=1
    doc_pdf_export_one "$md"
  done < <(find "$root" -type f -name '*.md' -print0 | sort -z)
  if [[ "$found" -eq 0 ]]; then
    echo "No *.md files under: $root"
    return 1
  fi
  return 0
}

if [[ -n "$p_target" ]]; then
  p_target="${p_target#./}"
  p_target="${p_target%/}"
  if [[ -d "$p_target" ]]; then
    if ! doc_under_export_roots "$p_target"; then
      echo "Expected a folder under data/ideas/ or docs/: $p_target"
      exit 1
    fi
    doc_pdf_export_tree "$p_target" || exit $?
  elif [[ -f "$p_target" ]]; then
    if ! doc_is_exportable_md "$p_target"; then
      echo "Expected a markdown file under data/ideas/ or docs/: $p_target"
      exit 1
    fi
    doc_pdf_export_one "$p_target"
  else
    echo "Path not found: $p_target"
    exit 1
  fi
else
  local_found=0
  if [[ -d data/ideas ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md"
    done < <(find data/ideas -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ -d docs ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md"
    done < <(find docs -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ "$local_found" -eq 0 ]]; then
    echo "No *.md files found under data/ideas or docs"
    exit 1
  fi
fi
