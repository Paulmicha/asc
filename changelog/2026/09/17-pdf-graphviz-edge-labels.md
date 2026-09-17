# PDF Graphviz edge-label pass (gvpr)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-17 |
| **Status** | implemented |
| **Scope** | `asc/doc/print_graphviz.py`, `asc/doc/improve_edge_labels.gvpr`, `asc/doc/asc/pdf.test.sh`, `asc/doc/pdf_export.sh`, `asc/doc/html_preview.sh` |
| **Host dep** | Graphviz CLI (`dot`, `gvpr`, `neato`) from `sudo apt install graphviz`. Missing `gvpr`/`neato` falls back to `dot -Tsvg`. Missing `dot` still never aborts export. |

After layout (`dot -K<engine> -Tdot`), run Steve Roush’s gvpr label repositioner, then `neato -n2 -Tsvg`. **Opt-in** via a fence info token: ```` ```dot labels ```` / ```` ```twopi labels ```` (aliases: `improve-labels`, `gvpr`). Default fences stay on `dot -Tsvg`. When opted in, inject `labelOverlay=true` and `label2node=true` (plaintext, no fill) unless the source already sets them. Improve-pass failure prints a stderr warning and falls back to `dot -Tsvg`.
