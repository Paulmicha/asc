#!/usr/bin/env bash

##
# Build an HTML preview of a markdown file using the same PDF pipeline
# (pdf_styles.css + Spectral + local Mermaid.js).
#
# @example
#   asc/doc/html_preview.sh 'data/ideas/2026/08/Agents of Redirection (Donella Meadows, Alexandre Monnin, Pierre Lévy).md'
#   asc/doc/html_preview.sh 'docs/asc/builder.md'
#

. asc/bootstrap.sh

if [[ $# -lt 1 ]]; then
  echo "Usage: asc/doc/html_preview.sh <path-under-data/ideas-or-docs>.md" >&2
  exit 1
fi

p_md="$1"
p_md="${p_md#./}"

if [[ ! -f "$p_md" ]]; then
  echo "File not found: $p_md" >&2
  exit 1
fi

case "$p_md" in
  data/ideas/*|docs/*) ;;
  *)
    abs="$(cd "$(dirname "$p_md")" && pwd)/$(basename "$p_md")"
    case "$abs" in
      "$PWD/data/ideas/"*|"$PWD/docs/"*) ;;
      *)
        echo "Expected a markdown file under data/ideas/ or docs/: $p_md" >&2
        exit 1
        ;;
    esac
    ;;
esac

if [[ "${p_md##*.}" != 'md' ]]; then
  echo "Expected a .md file: $p_md" >&2
  exit 1
fi

pdf_md2pdf_python() {
  local md2pdf_bin md2pdf_dir candidate
  md2pdf_bin="$(command -v md2pdf)" || true
  if [[ -n "$md2pdf_bin" ]]; then
    md2pdf_dir="$(dirname "$md2pdf_bin")"
    for candidate in "$md2pdf_dir/python" "$md2pdf_dir/python3"; do
      if [[ -x "$candidate" ]]; then
        echo "$candidate"
        return 0
      fi
    done
  fi
  if [[ -x "${HOME}/.local/share/pipx/venvs/md2pdf-mermaid/bin/python" ]]; then
    echo "${HOME}/.local/share/pipx/venvs/md2pdf-mermaid/bin/python"
    return 0
  fi
  command -v python3
}

PY="$(pdf_md2pdf_python)"
PDF_ASC_WRAPPER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/md2pdf_asc.py"

if [[ ! -f "$PDF_ASC_WRAPPER" ]]; then
  echo "ASC md2pdf wrapper not found: $PDF_ASC_WRAPPER" >&2
  exit 1
fi

if [[ ! -f "asc/vendor/mermaid.esm.min.mjs" ]]; then
  echo "Local Mermaid not found: asc/vendor/mermaid.esm.min.mjs" >&2
  exit 1
fi

"$PY" - "$p_md" "$PDF_ASC_WRAPPER" <<'PY'
import sys
from pathlib import Path

md_path = Path(sys.argv[1])
wrapper = Path(sys.argv[2]).resolve()

sys.path.insert(0, str(wrapper.parent))
import md2pdf_asc

root = md2pdf_asc.find_project_root(md_path.resolve())
out_path = md2pdf_asc.print_html_path_for(md_path.resolve(), root)
html = md2pdf_asc.render_html(md_path, project_root=root, enable_mermaid=True)
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(html, encoding="utf-8")
print(f"Wrote {out_path} ({len(html)} bytes)")
if 'class="mermaid"' in html:
    print("  Mermaid: local asc/vendor/mermaid.esm.min.mjs (relative import)")
print("  local images: rewritten relative to this HTML")
PY
