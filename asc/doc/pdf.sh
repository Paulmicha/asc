#!/usr/bin/env bash

##
# Export markdown under data/ideas and docs to PDF (beside each source .md).
#
# Ex : 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).md'
#   -> 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).pdf'
#
# @requires https://github.com/rbutinar/md2pdf-mermaid
# Styled via asc/doc/md/md2pdf_asc.py + asc/doc/pdf/styles.css (Spectral, 9pt body).
# Mermaid: local asc/vendor/mermaid.esm.min.mjs (offline).
# KaTeX: local asc/vendor/katex/ (CSS + JS + auto-render, offline).
# Graphviz: ```dot / ```graphviz / ```fdp / …  (user host dep: sudo apt install graphviz)
# Optional edge-label pass: ```dot labels  →  dot -Tdot | gvpr | neato -n2 -Tsvg
# (falls back to dot -Tsvg if gvpr/neato missing or the improve pass fails).
# Default fences stay on dot -K<engine> -Tsvg.
# Missing `dot` never aborts export. Each Graphviz fence becomes pre.graphviz-error
# plus a stderr warning (including when every fence failed).
#
# Print pipeline (do not reorder; heading/table pagination is last):
#   protect math → Graphviz fences→SVG → markdown → restore math → explode code
#   → inject CSS/boot → fonts → Mermaid → KaTeX flatten → emulate print
#   → mark long paragraphs → paginate orphans/widows → page.pdf
#
# Page size is chosen before that pipeline. --a3-l selects A3 landscape.
# The default is A4 portrait. Page size is not a pipeline stage.
#
# @param n [optional] String : markdown file or directory to export.
#   Defaults to every *.md under data/ideas and under docs.
#
# @param --force Boolean (flag) : rebuild each PDF even when it is newer than
#   its markdown source.
#   Defaults to compiling a missing PDF or a PDF older than the source.
#
# @param --a3-l Boolean (flag) : write A3 landscape (420 mm wide, 297 mm tall).
#   Defaults to A4 portrait (210 mm wide, 297 mm tall).
#   Also rebuilds when the PDF is already newer than the source.
#
# @example
#   make doc-pdf "'data/ideas/2026/08/Agents of Redirection.md'"
#   # Or :
#   asc/doc/pdf.sh 'data/ideas/2026/08/Agents of Redirection.md'
#
#   # All *.md files under a folder (recursive) :
#   make doc-pdf 'data/ideas/2026/08'
#   # Or :
#   asc/doc/pdf.sh 'data/ideas/2026/08'
#
#   # Rewrite existing :
#   make doc-pdf -- --force docs/foobar
#   # Or :
#   asc/doc/pdf.sh --force docs/foobar
#
#   # A3 landscape for one file (rebuilds a current PDF too) :
#   make doc-pdf -- --a3-l 'docs/foobar.md'
#   # Or :
#   asc/doc/pdf.sh --a3-l 'docs/foobar.md'
#
#   # A3 landscape for every markdown file under a directory :
#   make doc-pdf -- --a3-l docs/foobar
#   # Or :
#   asc/doc/pdf.sh --a3-l docs/foobar
#
#   # A3 landscape for data/ideas and docs :
#   make doc-pdf -- --a3-l
#   # Or :
#   asc/doc/pdf.sh --a3-l
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
p_a3_l=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      p_all=1
      shift
      ;;

    --a3-l)
      p_a3_l=1
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
PDF_ASC_WRAPPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/md/md2pdf_asc.py"
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

doc_is_exportable_md() {
  local p_md="$1"
  [[ -f "$p_md" ]] || return 1
  [[ "${p_md##*.}" == 'md' ]] || return 1
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
  local pdf cmd
  pdf="$(doc_md_to_pdf "$p_md")"

  # The sibling PDF does not record its paper, so --a3-l rebuilds a current file.
  if [[ "$p_all" -eq 0 && "$p_a3_l" -eq 0 ]] && ! doc_pdf_needs_export "$p_md"; then
    echo "skip (up to date): $p_md"
    return 0
  fi

  mkdir -p "$(dirname "$pdf")"
  echo "$p_md -> $pdf"
  cmd=("$PDF_MD2PDF_PY" "$PDF_ASC_WRAPPER" "$p_md" -o "$pdf")

  if [[ "$p_a3_l" -eq 1 ]]; then
    cmd+=(--a3-l)
  fi

  "${cmd[@]}"
}

doc_pdf_export_tree() {
  local root="$1"
  local found=0
  local rc=0
  while IFS= read -r -d '' md; do
    md="${md#./}"
    found=1
    doc_pdf_export_one "$md" || rc=1
  done < <(find "$root" -type f -name '*.md' -print0 | sort -z)
  if [[ "$found" -eq 0 ]]; then
    echo "No *.md files under: $root"
    return 1
  fi
  return "$rc"
}

if [[ -n "$p_target" ]]; then
  p_target="${p_target#./}"
  p_target="${p_target%/}"
  if [[ -d "$p_target" ]]; then
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
  rc=0
  if [[ -d data/ideas ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md" || rc=1
    done < <(find data/ideas -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ -d docs ]]; then
    while IFS= read -r -d '' md; do
      md="${md#./}"
      local_found=1
      doc_pdf_export_one "$md" || rc=1
    done < <(find docs -type f -name '*.md' -print0 | sort -z)
  fi
  if [[ "$local_found" -eq 0 ]]; then
    echo "No *.md files found under data/ideas or docs"
    exit 1
  fi
  exit "$rc"
fi
