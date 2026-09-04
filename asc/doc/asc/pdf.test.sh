#!/usr/bin/env bash

. asc/bootstrap.sh

export PYTHONPATH="asc/doc${PYTHONPATH:+:$PYTHONPATH}"

PDF_PY=''
if command -v md2pdf >/dev/null 2>&1; then
  for candidate in \
    "$(dirname "$(command -v md2pdf)")/python" \
    "$(dirname "$(command -v md2pdf)")/python3"; do
    if [ -x "$candidate" ]; then
      PDF_PY="$candidate"
      break
    fi
  done
fi
if [ -z "$PDF_PY" ] &&
  [ -x "$HOME/.local/share/pipx/venvs/md2pdf-mermaid/bin/python" ]; then
  PDF_PY="$HOME/.local/share/pipx/venvs/md2pdf-mermaid/bin/python"
fi
PDF_PY="${PDF_PY:-$(command -v python3)}"

test_page_css_margins_match_pre_plan() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
import re
css = Path("asc/doc/pdf_styles.css").read_text(encoding="utf-8")
block = re.search(r"@page\s*\{([^}]+)\}", css)
assert block, "@page rule missing"
body = block.group(1)
assert "size: A4" in body
assert re.search(r"margin:\s*\.75cm\s+\.75cm\s*;", body), body
assert "margin: 0;" not in body
css_full = Path("asc/doc/pdf_styles.css").read_text(encoding="utf-8")
assert ".code-line" in css_full
assert ".code-line:empty::before" in css_full
assert ".asc-print-push" in css_full
assert ".asc-print-push + :is(h1, h2, h3, h4, h5, h6)" in css_full
assert ".asc-print-break" not in css_full
assert "--asc-font-size: 9pt" in css_full
assert "--asc-mermaid-font-size: 1em" in css_full
assert "font-size: var(--asc-mermaid-font-size)" in css_full
assert ".nodeLabel" in css_full
assert "--asc-font-size-h1: 1.625rem" in css_full
print("ok")
PY
  assertEquals 'page CSS margin regression assertions failed' 0 $?
}

test_constants_and_content_box() {
  "$PDF_PY" - <<'PY'
from print_paginate import (
    ASC_FONT_PT,
    A4_HEIGHT_PX,
    A4_WIDTH_PX,
    CSS_PAGE_MARGIN_CM,
    MARGIN_BOTTOM_CM,
    MARGIN_LEFT_CM,
    MARGIN_RIGHT_CM,
    MARGIN_TOP_CM,
    MAX_BR_PER_TARGET,
    MAX_WIDOW_LINE_EQUIV,
    MERMAID_FONT_PX,
    MERMAID_LABEL_WRAP_CHARS,
    MERMAID_MAX_CANDIDATES,
    MERMAID_MIN_FONT_PX,
    MERMAID_NATIVE_FONT_PX,
    MERMAID_SKIP_RETRY_SCALE,
    MERMAID_TIE_EPS,
    mermaid_layout_px,
    em_to_px,
    MIN_FOLLOWING_LINES,
    MIN_TABLE_ROWS,
    PARA_LONG_MIN_LINES,
    BOTTOM_BAND_LINES,
    TOP_MAX_PX,
    content_box,
    content_height_px,
)

assert MIN_FOLLOWING_LINES == 4
assert MIN_TABLE_ROWS == 3
assert MAX_WIDOW_LINE_EQUIV == 4.0
assert TOP_MAX_PX == em_to_px(0.75)
assert MAX_BR_PER_TARGET == 80
assert BOTTOM_BAND_LINES == 12.0
assert A4_WIDTH_PX == 210.0 * 96.0 / 25.4
assert A4_HEIGHT_PX == 297.0 * 96.0 / 25.4
assert MARGIN_TOP_CM == 0.6
assert MARGIN_RIGHT_CM == 0.7
assert MARGIN_BOTTOM_CM == 1.0
assert MARGIN_LEFT_CM == 0.7
assert CSS_PAGE_MARGIN_CM == 0.75
assert PARA_LONG_MIN_LINES == 3
assert ASC_FONT_PT == 9.0
assert MERMAID_MAX_CANDIDATES == 4
assert MERMAID_SKIP_RETRY_SCALE == 0.70
assert MERMAID_NATIVE_FONT_PX == 16
assert abs(MERMAID_FONT_PX - em_to_px(1.0)) < 1e-9
assert abs(MERMAID_MIN_FONT_PX - em_to_px(0.75)) < 1e-9
assert mermaid_layout_px(8) == 6
assert mermaid_layout_px(16) == 12
assert mermaid_layout_px(50) == 38
assert mermaid_layout_px(200) == 150
assert MERMAID_LABEL_WRAP_CHARS == 42
assert MERMAID_TIE_EPS == 5.0
assert content_box(1122.5, 22.5, 37.8) == 1062.2
assert abs(
    content_height_px()
    - (
        A4_HEIGHT_PX
        - CSS_PAGE_MARGIN_CM * 96.0 / 2.54
        - MARGIN_BOTTOM_CM * 96.0 / 2.54
    )
) < 1e-6
print("ok")
PY
  assertEquals 'constants/content-box Python assertions failed' 0 $?
}

test_fit_content_height_from_probe() {
  "$PDF_PY" - <<'PY'
from print_paginate import (
    PT_TO_PX,
    PdfLine,
    fit_content_height_px,
    locate_layout_on_pdf,
    text_match,
)

assert text_match("6. Shelf inventory with verdicts", "6. SHELF INVENTORY WITH VERDICTS")
assert not text_match("6.1 Research Papers AI", "6. SHELF INVENTORY WITH VERDICTS")

# Synthetic Chromium: contentH=1040px, content top=21pt.
content_h = 1040.0
top_pt = 21.0
hits = []
for page in (2, 3, 6, 7):
    pdf_y = 80.0
    layout_y = (page - 1) * content_h + (pdf_y - top_pt) * PT_TO_PX
    hits.append((layout_y, page, pdf_y))
fitted = fit_content_height_px(hits, top_pt, guess=1056.4)
assert abs(fitted - content_h) < 1.0, fitted
# No usable hits → keep the CSS guess.
assert fit_content_height_px([], 21.0, 1056.4) == 1056.4

# TOC repeats the heading on page 1; the real heading is on page 8.
layout_y = (8 - 1) * content_h + (40.0 - top_pt) * PT_TO_PX
lines = [
    PdfLine(1, 40, "TABLE OF CONTENTS"),
    PdfLine(1, 80, "00 — Map of the shelf"),
    PdfLine(8, 40, "00 — Map of the shelf"),
    PdfLine(8, 80, "body paragraph"),
]
dom = [{"text": "00 — Map of the shelf", "y": layout_y}]
located = locate_layout_on_pdf(dom, lines, content_h, top_pt)
assert located[0] is not None and located[0][1] == 8, located
print("ok")
PY
  assertEquals 'fit content height from probe PDF failed' 0 $?
}

test_page_review_heading_orphan() {
  "$PDF_PY" - <<'PY'
from print_paginate import PdfLine, heading_keep_from_pdf, is_heading_orphan

# ## 6: two lines then the page ends; section continues.
assert is_heading_orphan(y_on_page=900, following_lines=2, continues=True)
# Already at the top of the next page: do not keep pushing.
assert not is_heading_orphan(y_on_page=6, following_lines=2, continues=True)
# ## 13 mid-page with a full section on the same page.
assert not is_heading_orphan(y_on_page=40, following_lines=20, continues=True)
# Last heading of the document: nothing to keep together on a later page.
assert not is_heading_orphan(y_on_page=900, following_lines=2, continues=False)

# Probe PDF: ## 6 already has h3 + a 4-row table on the same page → do not push.
shelf = [
    PdfLine(6, 648, "6. SHELF INVENTORY WITH VERDICTS"),
    PdfLine(6, 667, "One line per item."),
    PdfLine(6, 678, "so it is not rediscovered"),
    PdfLine(6, 701, "6.1 Research Papers AI"),
    PdfLine(6, 729, "Item What it is Verdict"),
    PdfLine(6, 747, "Moslem Kelleher survey"),
    PdfLine(6, 766, "Dupoux LeCun Malik"),
    PdfLine(6, 777, "arXiv killswitch"),
    PdfLine(7, 24, "later"),
]
table_rows = (
    "Item What it is Verdict",
    "Moslem Kelleher survey",
    "Dupoux LeCun Malik",
    "arXiv killswitch",
    "Long AI-Supervisor",
)
assert heading_keep_from_pdf(shelf, 6, 648, table_rows, next_heading_page=6) is True

# Heading 3: two intro lines + a 2-row table stub → still an orphan.
jargon = [
    PdfLine(2, 691, "3. JARGON (MASTER TABLE FOR THE FOLDER)"),
    PdfLine(2, 709, "Merged from v5 table"),
    PdfLine(2, 721, "anonymization spectrum"),
    PdfLine(2, 748, "Term Synonyms Definition"),
    PdfLine(2, 766, "ASC Agnostic Shell Controller"),
    PdfLine(3, 24, "Pivot entry point"),
]
jargon_rows = (
    "Term Synonyms Definition",
    "ASC Agnostic Shell Controller",
    "Pivot entry point",
    "Hook pre_llm",
)
assert heading_keep_from_pdf(jargon, 2, 691, jargon_rows, next_heading_page=5) is False

# Wide multi-column table: PDF lines do not match full DOM row strings,
# but the section already continues on this page (do not push).
wide = [
    PdfLine(11, 565, "B. Retrieval, memory, data"),
    PdfLine(11, 595, "Source Interesting / original For Projet Complexe Read"),
    PdfLine(11, 614, "Norman, Agentic Production RAG that admits failure"),
    PdfLine(11, 627, "RAG Systems (2026) pipelines fail in production"),
    PdfLine(11, 639, "embeddings have a semantic gap"),
    PdfLine(11, 651, "lexical / semantic / structural similarity"),
    PdfLine(11, 663, "are different families. Then the useful Implementation"),
    PdfLine(12, 24, "later"),
]
wide_rows = (
    "Source Interesting / original For Projet Complexe Read",
    "Norman, Agentic RAG Systems (2026) Production RAG that admits failure: naive pipelines fail in production",
    "Labaschin & Wallace Managing Memory for AI Agents Memory is data with types",
)
assert heading_keep_from_pdf(wide, 11, 565, wide_rows, next_heading_page=13) is True
print("ok")
PY
  assertEquals 'heading-orphan page-review assertions failed' 0 $?
}

test_page_review_table_then_heading() {
  "$PDF_PY" - <<'PY'
from print_paginate import (
    HEADING_TAGS,
    PAGINATE_JS,
    PageIssue,
    choose_bottom_issue,
    is_table_widow,
    section_owns_table,
    trim_overshoot_spacer,
    _DOM_Y_JS,
    _MARK_KEEP_JS,
)

# Header + one data row at the bottom; rest of the table continues.
assert is_table_widow(
    y_on_page=900, n_fit=2, n_rows=6, remaining_px=80, line_h=15.5
)
# Plenty of room left on the page: not a bottom-of-page widow.
assert not is_table_widow(
    y_on_page=200, n_fit=2, n_rows=6, remaining_px=800, line_h=15.5
)
# Three rows already fit.
assert not is_table_widow(
    y_on_page=900, n_fit=3, n_rows=6, remaining_px=80, line_h=15.5
)

heading = PageIssue("heading", 0)
table = PageIssue("table", 1)
assert choose_bottom_issue(table, heading) == heading
assert choose_bottom_issue(table, None) == table
assert choose_bottom_issue(None, heading) == heading
assert choose_bottom_issue(None, None) is None

# Do not insert a table spacer between a heading and its table
# (## 2.3 then one intro line then the table).
assert section_owns_table(["H2"], 0.0) is True
assert section_owns_table(["P", "H2"], 1.0) is True
assert section_owns_table(["P", "H3"], 3.0) is True
assert section_owns_table(["P", "H2"], 4.0) is False
assert section_owns_table(["P"], 1.0) is False
assert section_owns_table(["H1"], 0.0) is True
assert section_owns_table(["P", "H1"], 1.0) is True
assert "H1" in HEADING_TAGS
assert "/^H[1-6]$/" in PAGINATE_JS
assert "h1,h2,h3,h4,h5,h6,table" in PAGINATE_JS
assert "h1,h2,h3,h4,h5,h6,table" in _DOM_Y_JS
assert "h1,h2,h3,h4,h5,h6" in _MARK_KEEP_JS
assert "sectionHeadForTable" in PAGINATE_JS
assert "tableFragmentLines" in PAGINATE_JS
assert "trimOvershoot" in PAGINATE_JS

# After a push, leftover spacer must not floor at one <br> (that is a
# blank line at the top of the next page).
h, n = trim_overshoot_spacer(
    y_on_next=20.0, min_height=20.0, n_br=2, br_h=16.0, top_eps=9.0
)
assert h == 0.0 and n == 0
h, n = trim_overshoot_spacer(
    y_on_next=6.0, min_height=180.0, n_br=4, br_h=16.0, top_eps=9.0
)
assert abs(h - 164.0) < 1e-9 and n == 4
print("ok")
PY
  assertEquals 'table-then-heading page-review assertions failed' 0 $?
}

test_explode_pre_code_lines() {
  "$PDF_PY" - <<'PY'
from print_code import explode_pre_code_lines

html = '<pre class="codehilite"><code>a\nb\nc</code></pre>'
out = explode_pre_code_lines(html)
assert out.count('class="code-line"') == 3
assert '<span class="code-line">a</span>' in out
# Block .code-line plus a leftover newline is a blank line in pre-wrap.
assert "\n<span class=\"code-line\">" not in out
assert "</span><span class=\"code-line\">" in out

blank = '<pre class="codehilite"><code>a\n\nb</code></pre>'
blank_out = explode_pre_code_lines(blank)
assert blank_out.count('class="code-line"') == 3

mm = '<pre class="mermaid">flowchart LR\nA-->B</pre>'
assert explode_pre_code_lines(mm) == mm
print("ok")
PY
  assertEquals 'code-line explosion Python assertions failed' 0 $?
}

test_protect_katex_delimiters() {
  "$PDF_PY" - <<'PY'
from print_katex import protect_katex_math, restore_katex_math, html_has_katex

md = r"Let \(\ell\) and \[ \frac{a}{b} \] and $x_1$ and $$y_2$$."
protected, placeholders = protect_katex_math(md)
assert len(placeholders) == 4
assert "@@ASC_MATH_0@@" in protected
assert r"\ell" not in protected
assert r"\frac" not in protected
assert html_has_katex(r"\(\ell\)") is True
assert html_has_katex(r"\[ a \]") is True
assert html_has_katex("no math here") is False
restored = restore_katex_math(protected, placeholders)
assert restored.replace("\n", "") == md.replace("\n", "") or all(
    tok in restored for tok in (r"\(\ell\)", r"\frac{a}{b}", "$x_1$", "$$y_2$$")
)

fenced = "```bash\nnvidia-smi > /tmp/gpu_w.$$ &\nrm -f /tmp/gpu_w.$$\n```\n"
protected_fenced, ph_fenced = protect_katex_math(fenced)
assert ph_fenced == []
assert "/tmp/gpu_w.$$" in protected_fenced
print("ok")
PY
  assertEquals 'katex protect Python assertions failed' 0 $?
}

test_mermaid_candidates() {
  "$PDF_PY" - <<'PY'
from print_mermaid import (
    flowchart_set_rank,
    mermaid_candidates,
    mermaid_kind,
    quote_sequence_messages,
    wrap_long_labels,
)

src = "flowchart LR\n  A[\"hello world this is a long node label here\"] --> B\n"
assert mermaid_kind(src) == "flowchart"
td = flowchart_set_rank(src, "TD")
assert td.startswith("flowchart TD")
assert "A[" in td and "--> B" in td
wrapped = wrap_long_labels(src, max_chars=20)
assert "<br>" in wrapped
assert "hello" in wrapped and "world" in wrapped
cands = mermaid_candidates(src)
assert cands[0][1] is True
assert 'A["hello world this is a long node label here"]' in cands[0][0]
assert "@{ shape: rounded" not in cands[0][0]
assert any(c[0].startswith("flowchart TD") for c in cands)
assert len(cands) <= 4

inner = "flowchart LR\n  subgraph house[\"The house\"]\n    direction TB\n    A-->B\n  end\n"
flipped = flowchart_set_rank(inner, "TD")
assert "direction TB" in flipped
assert flipped.splitlines()[0].startswith("flowchart TD")

seq = (
    "sequenceDiagram\n"
    "  H->>D: pc drill rebuild --scope brain\n"
    "  D->>F: scan; compute body_sha\n"
    "  D-->>H: report: durations\n"
)
assert mermaid_kind(seq) == "sequence"
quoted = quote_sequence_messages(seq)
assert 'H->>D: "pc drill rebuild --scope brain"' in quoted
assert "scan — compute body_sha" in quoted
assert ";" not in quoted.split("H->>D:", 1)[1]
assert "report∶ durations" in quoted
seq_cands = mermaid_candidates(seq)
assert any("scan — compute" in c[0] for c in seq_cands)
from print_mermaid import mermaid_run_js
js = mermaid_run_js(800, 1000)
assert "error-text" in js
assert "dascMmd" in js
assert "layout(8)" in js
assert "getComputedStyle(document.documentElement)" in js
assert "htmlLabels: true" in js
assert "ascCenterMermaidLabels" in js
assert "ascMermaidMeasureCss" in js
assert "nodeLabel" in js
assert "shape: rounded" not in js
assert "radius: 3" not in js
print("ok")
PY
  assertEquals 'mermaid candidates Python assertions failed' 0 $?
}

test_pipeline_order_in_driver() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
from md2pdf_asc import PDF_DEST_NAME_MAX, shorten_html_ids

src = Path("asc/doc/md2pdf_asc.py").read_text(encoding="utf-8")
fn = src.split("async def html_to_pdf_playwright", 1)[1].split("hr.html_to_pdf_playwright", 1)[0]
for a, b in [
    ("__ascLayoutReady", "emulate_media"),
    ("emulate_media", "MARK_LONG_PARAS_JS"),
    ("MARK_LONG_PARAS_JS", "apply_print_pushes"),
    ("apply_print_pushes", "page.pdf"),
]:
    assert fn.index(a) < fn.index(b), (a, b)
boot = src.split("async function ascLayoutBoot", 1)[1]
assert boot.index("await ascRunMermaid()") < boot.index("await ascRunKatex()")
preview = Path("asc/doc/html_preview.sh").read_text(encoding="utf-8")
assert "apply_print_pushes" not in preview

long_id = "201-" + ("a" * 140)
html = (
    f'<h4 id="{long_id}">Heading</h4>'
    f'<a href="#{long_id}">link</a>'
    '<h2 id="short">OK</h2>'
)
out = shorten_html_ids(html)
assert long_id not in out
assert 'id="short"' in out
assert f'href="#{long_id}"' not in out
assert 'href="#' in out
from md2pdf_asc import PROJECT_ROOT_DEFAULT, MERMAID_VENDOR, display_path
outside = Path("/tmp/unrelated-project")
shown = display_path(MERMAID_VENDOR, outside, PROJECT_ROOT_DEFAULT)
assert shown.endswith("asc/vendor/mermaid.esm.min.mjs"), shown
assert not shown.startswith("/tmp/")
print("ok")
PY
  assertEquals 'pipeline order assertions failed' 0 $?
}

. asc/vendor/shunit2/shunit2
