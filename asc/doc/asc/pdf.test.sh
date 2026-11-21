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
css = Path("asc/doc/pdf/styles.css").read_text(encoding="utf-8")
block = re.search(r"@page\s*\{([^}]+)\}", css)
assert block, "@page rule missing"
body = block.group(1)
assert "size: A4" in body
assert re.search(r"margin:\s*\.75cm\s+\.75cm\s*;", body), body
assert "margin: 0;" not in body
css_full = Path("asc/doc/pdf/styles.css").read_text(encoding="utf-8")
assert ".code-line" in css_full
assert ".code-line:empty::before" in css_full
assert ".asc-print-push" in css_full
assert ".asc-print-push + :is(h1, h2, h3, h4, h5, h6)" in css_full
assert ".asc-print-break" not in css_full
assert "--asc-font-size: 9pt" in css_full
assert "--asc-mermaid-font-size: 1em" in css_full
assert "font-size: var(--asc-mermaid-font-size)" in css_full
assert "flex-shrink: 0" in css_full
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
    A4_HEIGHT_PT,
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
    PAGE_A3_LANDSCAPE,
    PAGE_A4,
    mermaid_layout_px,
    em_to_px,
    MIN_FOLLOWING_LINES,
    MIN_TABLE_ROWS,
    PARA_LONG_MIN_LINES,
    BOTTOM_BAND_LINES,
    TOP_MAX_PX,
    content_box,
    content_height_px,
    content_width_px,
    select_page,
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
assert PAGE_A4.format == "A4" and PAGE_A4.orientation == "portrait"
assert PAGE_A4.width_mm == 210.0 and PAGE_A4.height_mm == 297.0
assert PAGE_A4.css_size == "A4"
assert PAGE_A3_LANDSCAPE.format == "A3"
assert PAGE_A3_LANDSCAPE.orientation == "landscape"
assert PAGE_A3_LANDSCAPE.width_mm == 420.0
assert PAGE_A3_LANDSCAPE.height_mm == 297.0
assert PAGE_A3_LANDSCAPE.css_size == "A3 landscape"
assert PAGE_A4.width_px == A4_WIDTH_PX
assert PAGE_A4.height_px == A4_HEIGHT_PX
assert PAGE_A4.height_pt == A4_HEIGHT_PT
assert PAGE_A3_LANDSCAPE.height_pt == A4_HEIGHT_PT
assert abs(
    content_width_px(PAGE_A4)
    - (210.0 * 96.0 / 25.4 - 2 * 0.75 * 96.0 / 2.54)
) < 1e-6
assert abs(
    content_width_px(PAGE_A3_LANDSCAPE)
    - (420.0 * 96.0 / 25.4 - 2 * 0.75 * 96.0 / 2.54)
) < 1e-6
assert abs(content_height_px(PAGE_A3_LANDSCAPE) - content_height_px(PAGE_A4)) < 1e-6
assert content_width_px() == content_width_px(PAGE_A4)
select_page(True)
assert content_width_px() == content_width_px(PAGE_A3_LANDSCAPE)
assert abs(content_height_px() - content_height_px(PAGE_A4)) < 1e-6
select_page(False)
assert content_width_px() == content_width_px(PAGE_A4)
print("ok")
PY
  assertEquals 'constants/content-box Python assertions failed' 0 $?
}

test_page_geometry() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
from print_paginate import (
    PAGE_A3_LANDSCAPE,
    PAGE_A4,
    css_with_page_size,
    select_page,
)

css = Path("asc/doc/pdf/styles.css").read_text(encoding="utf-8")
a4 = css_with_page_size(css, PAGE_A4)
a3 = css_with_page_size(css, PAGE_A3_LANDSCAPE)

def at_page(text: str) -> str:
    return text.split("@page", 1)[1].split("}", 1)[0]

assert "size: A4" in at_page(a4)
assert "A3" not in at_page(a4)
assert "size: A3 landscape" in at_page(a3)
assert "size: A4" not in at_page(a3)
assert "margin: .75cm .75cm" in at_page(a3)
assert "A4 (~196mm content)" in a3
select_page(True)
try:
    raised = False
    try:
        css_with_page_size("@page { margin: 1cm; }", PAGE_A3_LANDSCAPE)
    except RuntimeError as exc:
        raised = True
        assert "size: A4" in str(exc)
    assert raised
finally:
    select_page(False)
print("ok")
PY
  assertEquals 'page geometry CSS assertions failed' 0 $?
}

test_render_html_same_process_resets_to_a4() {
  "$PDF_PY" - <<'PY'
import shutil
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import md2pdf.html_renderer
from md2pdf_asc import main, render_html
from print_paginate import PAGE_A3_LANDSCAPE, PAGE_A4, selected_page

def at_page(html: str) -> str:
    return html.split("@page", 1)[1].split("}", 1)[0]

def assert_a4_after(src: Path) -> None:
    assert selected_page() == PAGE_A4, selected_page()
    page = at_page(render_html(src))
    assert "size: A4" in page, page
    assert "A3" not in page, page

src = Path("asc/doc/fixtures/para-gap.md")
work = Path(tempfile.mkdtemp(prefix="a3-main-reset-", dir=Path("data/tmp")))
out_pdf = work / "out.pdf"
argv = ["md2pdf_asc.py", "--a3-l", str(src), "-o", str(out_pdf)]
old_argv = sys.argv
try:
    def fake_ok(markdown, output, title, page_size, orientation, enable_mermaid):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        assert page_size == "A3" and orientation == "landscape", (page_size, orientation)
        Path(output).write_bytes(b"%PDF-1.4 mock\n")
        return {"success": True}

    def fake_boom(*_args, **_kwargs):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        raise RuntimeError("convert failed")

    def fake_fail(*_args, **_kwargs):
        assert selected_page() == PAGE_A3_LANDSCAPE, selected_page()
        return {"success": False, "error": "mocked"}

    sys.argv = argv
    with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_ok):
        assert main() == 0
    assert_a4_after(src)

    sys.argv = argv
    raised = False
    try:
        with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_boom):
            main()
    except RuntimeError as exc:
        raised = True
        assert str(exc) == "convert failed"
    assert raised
    assert_a4_after(src)

    sys.argv = argv
    with patch("md2pdf.html_renderer.convert_markdown_to_pdf_html", fake_fail):
        assert main() == 1
    assert_a4_after(src)
    print("ok")
finally:
    sys.argv = old_argv
    shutil.rmtree(work)
PY
  assertEquals 'same-process A4 reset assertions failed' 0 $?
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
# Failed pushes must remove the spacer (not restore minHeight on the
# source page — that printed as blank lines before the Gazit table).
assert "clearFailedPush" in PAGINATE_JS
assert "return clearFailedPush(el, sp)" in PAGINATE_JS
assert "sp.style.minHeight = cur + 'px'" not in PAGINATE_JS
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
assert "min(100%, '" in js
assert "svg.style.height = 'auto'" in js
assert "pageH / Math.max(bb.height, 1), 1)" in js
assert "svg.style.flexShrink = '0'" in js
assert "wrap: true" in js
assert "wrapPadding: 3" in js
print("ok")
PY
  assertEquals 'mermaid candidates Python assertions failed' 0 $?
}

test_pipeline_order_in_driver() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
from md2pdf_asc import PDF_DEST_NAME_MAX, shorten_html_ids

src = Path("asc/doc/md/md2pdf_asc.py").read_text(encoding="utf-8")
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
preview = Path("asc/doc/md/to_html.sh").read_text(encoding="utf-8")
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

test_graphviz_engine_and_fences() {
  "$PDF_PY" - <<'PY'
import re
import subprocess
from print_graphviz import (
    graphviz_engine_for,
    graphviz_improve_labels,
    iter_graphviz_fences,
    sanitize_graphviz_svg,
    render_graphviz_fences,
)

assert graphviz_engine_for("dot") == "dot"
assert graphviz_engine_for("DOT") == "dot"
assert graphviz_engine_for("graphviz") == "dot"
assert graphviz_engine_for("fdp extra") == "fdp"
assert graphviz_engine_for("mermaid") is None
assert graphviz_engine_for("python") is None
assert graphviz_improve_labels("dot") is False
assert graphviz_improve_labels("twopi labels") is True
assert graphviz_improve_labels("dot LABELS") is True
assert graphviz_improve_labels("fdp extra") is False

md = (
    "Intro\n\n"
    "```dot\n"
    "digraph G { a -> b }\n"
    "```\n\n"
    "```fdp\n"
    "graph H { x -- y }\n"
    "```\n\n"
    "```python\n"
    "print(1)\n"
    "```\n"
)
fences = iter_graphviz_fences(md)
assert len(fences) == 2
assert fences[0][2] == "dot" and "a -> b" in fences[0][3]
assert fences[1][2] == "fdp" and "x -- y" in fences[1][3]

svg = '''<?xml version="1.0"?>
<!DOCTYPE svg>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" width="72pt" height="72pt">
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="10">
      <path d="M0,0 L10,5 L0,10"/>
    </marker>
    <clipPath id="clip1"><rect width="10" height="10"/></clipPath>
  </defs>
  <style type="text/css">
    .node { stroke: none; }
    ellipse { fill: #ffffcc; }
  </style>
  <script>alert(1)</script>
  <g id="node1" class="node" clip-path="url(#clip1)">
    <polygon fill="url(#clip1)"/>
    <text font-family="Times,serif">Hi</text>
    <path marker-end="url(#arrowhead)" d="M0,0 L10,10"/>
  </g>
</svg>
'''
out = sanitize_graphviz_svg(svg, "gv0-")
assert out.startswith("<svg")
assert "<?xml" not in out
assert "<!DOCTYPE" not in out
assert "<script" not in out
assert 'id="gv0-node1"' in out
assert 'id="gv0-arrowhead"' in out
assert 'id="gv0-clip1"' in out
assert 'url(#gv0-arrowhead)' in out
assert 'url(#gv0-clip1)' in out
assert 'url(#arrowhead)' not in out
assert 'url(#clip1)' not in out
assert "Source Sans 3" in out
assert 'width="100%"' not in out
assert 'viewBox="0 0 10 10"' in out
assert "72pt" in out  # intrinsic Graphviz size kept
# Scoped CSS: substring checks would false-fail on `.graphviz-wrap .node {`.
assert ".graphviz-wrap .node" in out or ".graphviz-wrap ellipse" in out
assert re.search(r"(?<!graphviz-wrap )\.node\s*\{", out) is None
assert re.search(r"(?<!graphviz-wrap )ellipse\s*\{", out) is None

# Non-Graphviz fences stay fences. A ```dot fence without `dot` becomes
# graphviz-error (not a leftover fence).
plain = render_graphviz_fences("```python\nprint(1)\n```\n")
assert "```python" in plain

class _Proc:
    def __init__(self, returncode=0, stdout=b"", stderr=b""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr

def _no_dot(_name="dot"):
    return None

def _only_dot(name="dot"):
    return "/usr/bin/dot" if name == "dot" else None

missing = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=_no_dot,
)
assert "graphviz-error" in missing
assert "```dot" not in missing
assert "digraph G" in missing

def _bad_runner(argv, input, timeout):
    return _Proc(1, b"", b"syntax error")

nonzero = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=_only_dot,
    runner=_bad_runner,
)
assert "graphviz-error" in nonzero
assert "```dot" not in nonzero

def _timeout_runner(argv, input, timeout):
    raise subprocess.TimeoutExpired(cmd=argv, timeout=timeout)

timed = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=_only_dot,
    runner=_timeout_runner,
)
assert "graphviz-error" in timed
assert "```dot" not in timed

_FAKE_SVG = (
    b'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" width="72pt" height="72pt">'
    b'<g id="n1"><text>ok</text></g></svg>'
)

def _ok_runner(argv, input, timeout):
    assert "-Tsvg" in argv and any(a.startswith("-K") for a in argv)
    return _Proc(0, _FAKE_SVG, b"")

ok = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=_only_dot,
    runner=_ok_runner,
)
assert 'class="graphviz-wrap"' in ok
assert "<svg" in ok
assert "```dot" not in ok
assert "digraph" not in ok

import shutil
from print_graphviz import render_dot_svg, sanitize_graphviz_svg

if shutil.which("dot"):
    raw = render_dot_svg('digraph G { a [label="Article"]; a -> b; }', "dot")
    svg = sanitize_graphviz_svg(raw, "gv0-")
    assert "Article" in svg
    assert 'width="100%"' not in svg
    html = render_graphviz_fences("```dot\ndigraph G { x -> y }\n```\n")
    assert 'class="graphviz-wrap"' in html
    assert "<svg" in html
    assert "```dot" not in html
else:
    print("skip live dot")
print("ok")
PY
  assertEquals 'graphviz engine/fence Python assertions failed' 0 $?
}

test_graphviz_gvpr_edge_labels() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
from print_graphviz import (
    GVPR_SCRIPT,
    inject_edge_label_attrs,
    render_dot_svg,
    render_graphviz_fences,
)

src = "digraph G {\n  a -> b [label=\"Auteur\"];\n}\n"
out = inject_edge_label_attrs(src)
assert "labelOverlay=true" in out
assert "label2node=true" in out
assert inject_edge_label_attrs(out) == out  # already present

assert GVPR_SCRIPT.is_file(), GVPR_SCRIPT
assert 'fillcolor="white"' not in GVPR_SCRIPT.read_text(encoding="utf-8")

class _Proc:
    def __init__(self, returncode=0, stdout=b"", stderr=b""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr

_FAKE_SVG = (
    b'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
    b'<g id="n1"><text>ok</text></g></svg>'
)
_FAKE_DOT = b'digraph G { a [pos="0,0"]; a -> b [lp="1,1", label="Auteur"]; }\n'

calls = []

def which_all(name="dot"):
    return {
        "dot": "/usr/bin/dot",
        "gvpr": "/usr/bin/gvpr",
        "neato": "/usr/bin/neato",
    }.get(name)

def runner(argv, input, timeout):
    calls.append(argv)
    names = [Path(a).name for a in argv]
    joined = " ".join(argv)
    data = input if isinstance(input, (bytes, bytearray)) else (input or b"")
    if "-Tdot" in argv:
        assert any(a.startswith("-K") for a in argv)
        assert b"labelOverlay=true" in data
        assert b"label2node=true" in data
        return _Proc(0, _FAKE_DOT, b"")
    if "gvpr" in names:
        assert "-cf" in argv
        assert any("improve_edge_labels.gvpr" in a for a in argv)
        return _Proc(0, data + b"\n// gvpr-ok\n", b"")
    if "-Tsvg" in argv and "-n2" in argv:
        assert names[0] == "neato"
        return _Proc(0, _FAKE_SVG, b"")
    raise AssertionError(joined)

html = render_graphviz_fences(
    "```dot labels\ndigraph G { a -> b [label=\"Auteur\"]; }\n```\n",
    which_dot=which_all,
    runner=runner,
)
assert 'class="graphviz-wrap"' in html
assert "<svg" in html
assert len(calls) == 3
assert "-Tdot" in calls[0]
assert any(Path(a).name == "gvpr" for a in calls[1])
assert "-n2" in calls[2] and "-Tsvg" in calls[2]

# Default fence (no `labels` token) stays on dot -Tsvg.
calls.clear()

def runner_direct(argv, input, timeout):
    calls.append(argv)
    data = input if isinstance(input, (bytes, bytearray)) else (input or b"")
    assert b"labelOverlay" not in data
    if "-Tsvg" in argv and any(a.startswith("-K") for a in argv):
        return _Proc(0, _FAKE_SVG, b"")
    raise AssertionError(argv)

plain = render_graphviz_fences(
    "```dot\ndigraph G { a -> b [label=\"Auteur\"]; }\n```\n",
    which_dot=which_all,
    runner=runner_direct,
)
assert 'class="graphviz-wrap"' in plain
assert len(calls) == 1

# gvpr failure falls back to dot -Tsvg
calls.clear()

def runner_gvpr_fail(argv, input, timeout):
    calls.append(argv)
    if "-Tdot" in argv:
        return _Proc(0, _FAKE_DOT, b"")
    if any(Path(a).name == "gvpr" for a in argv):
        return _Proc(1, b"", b"gvpr boom")
    if "-Tsvg" in argv:
        return _Proc(0, _FAKE_SVG, b"")
    raise AssertionError(argv)

fb = render_graphviz_fences(
    "```dot labels\ndigraph G { a -> b }\n```\n",
    which_dot=which_all,
    runner=runner_gvpr_fail,
)
assert 'class="graphviz-wrap"' in fb
assert any("-Tsvg" in c and "-K" in "".join(c) for c in calls)

import shutil
if shutil.which("dot") and shutil.which("gvpr") and shutil.which("neato"):
    raw = render_dot_svg(
        'digraph G { a -> b [label="Auteur"]; }',
        "dot",
        improve_labels=True,
    )
    assert "Auteur" in raw
print("ok")
PY
  assertEquals 'graphviz gvpr edge-label pipeline failed' 0 $?
}

test_graphviz_survives_markdown_nl2br() {
  "$PDF_PY" - <<'PY'
# md2pdf markdown_to_html enables nl2br. Graphviz SVG is inserted before orig();
# newlines inside <svg> must not become <br>.
import re
from md2pdf.html_renderer import markdown_to_html as orig
from print_graphviz import render_graphviz_fences

class _Proc:
    def __init__(self, returncode=0, stdout=b"", stderr=b""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr

_FAKE_SVG = b'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" width="72pt" height="72pt">
  <g id="n1">
    <text>ok</text>
  </g>
</svg>'''

def _ok_runner(argv, input, timeout):
    return _Proc(0, _FAKE_SVG, b"")

md = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=lambda name="dot": "/usr/bin/dot" if name == "dot" else None,
    runner=_ok_runner,
)
html = orig(md, title="t", enable_mermaid=False)
assert "<svg" in html
m = re.search(r"<svg\b[^>]*>.*?</svg>", html, re.I | re.S)
assert m, "svg missing after orig()"
assert "<br" not in m.group(0).lower()
print("ok")
PY
  assertEquals 'graphviz nl2br round-trip failed' 0 $?
}

test_explode_skips_graphviz() {
  "$PDF_PY" - <<'PY'
from print_code import explode_pre_code_lines

# Success path has no <pre> inside .graphviz-wrap (only <svg>), so explode is a
# no-op. That is NOT a skip test — explode only mutates <pre>.
wrap = '<div class="graphviz-wrap"><svg><text>a\nb</text></svg></div>'
assert explode_pre_code_lines(wrap) == wrap

# Real skip: error fences are <pre class="graphviz-error">.
err = '<pre class="graphviz-error">digraph G {\na -> b\n}</pre>'
assert explode_pre_code_lines(err) == err
assert "code-line" not in explode_pre_code_lines(err)

# Ancestor skip is unused on the success path. Keep it as defense in depth;
# this nested <pre> is synthetic (the pipeline never emits it):
nested = '<div class="graphviz-wrap"><pre>a\nb</pre></div>'
assert "code-line" not in explode_pre_code_lines(nested)
print("ok")
PY
  assertEquals 'explode skip graphviz failed' 0 $?
}

test_pipeline_mentions_graphviz() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
import re
src = Path("asc/doc/md/md2pdf_asc.py").read_text(encoding="utf-8")
assert "render_graphviz_fences" in src
# protect → graphviz → orig (markdown/mermaid)
fn = src.split("def markdown_to_html", 1)[1].split("hr.markdown_to_html", 1)[0]
assert fn.index("protect_katex_math") < fn.index("render_graphviz_fences")
assert fn.index("render_graphviz_fences") < fn.index("orig(")
# Conversion banner is in main(), not render_html() / html_preview.sh.
main = src.split("def main", 1)[1]
assert "Graphviz" in main
css = Path("asc/doc/pdf/styles.css").read_text(encoding="utf-8")
assert ".graphviz-wrap" in css
assert "pre.graphviz-error" in css
gv_svg = css.split(".graphviz-wrap svg", 1)[1].split("}", 1)[0]
assert "max-width: 100%" in gv_svg
assert re.search(r"(?<!max-)width:\s*100%", gv_svg) is None
pag = Path("asc/doc/pdf/paginate.py").read_text(encoding="utf-8")
assert "graphviz-wrap" in pag
katex = Path("asc/doc/formula/katex.py").read_text(encoding="utf-8")
assert "graphviz-wrap" in katex and "graphviz-error" in katex
sh = Path("asc/doc/pdf.sh").read_text(encoding="utf-8")
assert "graphviz" in sh.lower() and "dot" in sh.lower()
assert "fatal only" not in sh.lower()
preview = Path("asc/doc/md/to_html.sh").read_text(encoding="utf-8")
assert "graphviz" in preview.lower()
print("ok")
PY
  assertEquals 'pipeline graphviz wiring assertions failed' 0 $?
}

test_graphviz_does_not_restyle_mermaid() {
  "$PDF_PY" - <<'PY'
import re
from md2pdf.html_renderer import markdown_to_html as orig
from print_graphviz import render_graphviz_fences

class _Proc:
    def __init__(self, returncode=0, stdout=b"", stderr=b""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr

_FAKE_SVG = b'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">
  <style>.node { fill: red !important; }</style>
  <g class="node" id="n1"/>
</svg>'''

def _ok_runner(argv, input, timeout):
    return _Proc(0, _FAKE_SVG, b"")

md = (
    "```mermaid\nflowchart LR\n  A-->B\n```\n\n"
    "```dot\ndigraph G { a -> b }\n```\n"
)
out = render_graphviz_fences(
    md,
    which_dot=lambda name="dot": "/usr/bin/dot" if name == "dot" else None,
    runner=_ok_runner,
)
assert "```mermaid" in out
assert 'class="graphviz-wrap"' in out
assert "```dot" not in out
assert re.search(r"(?<!graphviz-wrap )\.node\s*\{", out) is None
html = orig(out, title="t", enable_mermaid=False)
assert "```mermaid" in html or 'class="mermaid"' in html or "flowchart LR" in html
print("ok")
PY
  assertEquals 'graphviz must not restyle mermaid' 0 $?
}

test_a3_l_option() {
  local out status
  out="$(./asc/doc/pdf.sh --a3 'docs/foobar.md' 2>&1)"
  status=$?
  assertEquals 'short flag stays unknown' 1 "$status"
  assertTrue 'unknown --a3' "echo \"$out\" | grep -q 'Unknown option: --a3'"

  if command -v md2pdf >/dev/null 2>&1 &&
    [[ -f asc/vendor/mermaid.esm.min.mjs && -f asc/vendor/katex/katex.min.js ]]; then
    out="$(./asc/doc/pdf.sh --a3-l 'docs/no-such-a3-flag.md' 2>&1)"
    status=$?
    assertEquals 'known flag reaches path check' 1 "$status"
    assertTrue 'missing path' "echo \"$out\" | grep -q 'Path not found: docs/no-such-a3-flag.md'"
  else
    echo "skip --a3-l path check (md2pdf or asc/vendor mermaid/katex missing)"
  fi

  "$PDF_PY" - <<'PY'
from pathlib import Path
sh = Path("asc/doc/pdf.sh").read_text(encoding="utf-8")
preview = Path("asc/doc/md/to_html.sh").read_text(encoding="utf-8")
# pdf_playwright_prepare contains an earlier "command -v md2pdf".
after_loop_start = sh.split("while [[ $# -gt 0 ]]; do", 1)[1]
parser = after_loop_start.split("\ndone\n", 1)[0]
after_loop = after_loop_start.split("\ndone\n", 1)[1]
assert "--a3-l)" in parser
assert "-*)" in parser
assert after_loop.index("command -v md2pdf") < after_loop.index("Path not found:")
after_vendors = sh.split("asc/vendor/katex/katex.min.js", 1)[1]
assert "Path not found:" in after_vendors
force = sh.split("--force)", 1)[1].split(";;", 1)[0]
a3 = sh.split("--a3-l)", 1)[1].split(";;", 1)[0]
assert "p_all=1" in force
assert "p_a3_l" not in force
assert "p_a3_l=1" in a3
assert "p_all" not in a3
assert 'p_all" -eq 0 && "$p_a3_l" -eq 0' in sh
assert "${p_md%.md}.pdf" in sh
assert sh.count("doc_pdf_export_one ") >= 4
assert "--a3-l" in sh.split("doc_pdf_export_one()", 1)[1]
assert "--a3-l" not in preview
assert "select_page" not in preview
assert "render_html" in preview
print("ok")
PY
  assertEquals 'A3 flag wiring assertions failed' 0 $?
}

test_export_tree_propagates_failure() {
  if ! command -v md2pdf >/dev/null 2>&1; then
    echo "skip tree failure propagation (md2pdf not on PATH)"
    return 0
  fi
  if [[ ! -f asc/vendor/mermaid.esm.min.mjs || ! -f asc/vendor/katex/katex.min.js ]]; then
    echo "skip tree failure propagation (asc/vendor mermaid/katex missing)"
    return 0
  fi
  local tmp status html_bad html_ok
  tmp="$(mktemp -d --tmpdir="${PWD}/data/tmp" tree-fail-XXXXXX)"
  html_bad="$("$PDF_PY" - <<PY
from pathlib import Path
from md2pdf_asc import find_project_root, print_html_path_for
md = Path("$tmp/a-bad.md")
root = find_project_root(md.resolve())
print(print_html_path_for(md, root))
PY
)"
  html_ok="$("$PDF_PY" - <<PY
from pathlib import Path
from md2pdf_asc import find_project_root, print_html_path_for
md = Path("$tmp/b-ok.md")
root = find_project_root(md.resolve())
print(print_html_path_for(md, root))
PY
)"
  trap 'rm -rf "$tmp"; rm -f "$html_bad" "$html_ok"' RETURN
  printf '# Bad\n\nHello.\n' >"$tmp/a-bad.md"
  printf '# Ok\n\nHello.\n' >"$tmp/b-ok.md"
  mkdir "$tmp/a-bad.pdf"
  ./asc/doc/pdf.sh --force "$tmp" >/dev/null 2>&1
  status=$?
  assertNotEquals 'tree export must fail when one conversion fails' 0 "$status"
  assertTrue 'successful sibling still exported' "[ -f \"$tmp/b-ok.pdf\" ]"
}

test_export_failure_aggregation_source() {
  "$PDF_PY" - <<'PY'
from pathlib import Path
sh = Path("asc/doc/pdf.sh").read_text(encoding="utf-8")
tree = sh.split("doc_pdf_export_tree()", 1)[1].split("\n}\n", 1)[0]
assert 'doc_pdf_export_one "$md" || rc=1' in tree
assert 'return "$rc"' in tree
# Keep the delimiter in the extracted text; splitting it away drops local_found=0.
marker = "else\n  local_found=0\n"
assert marker in sh
no_target = marker + sh.split(marker, 1)[1]
assert no_target.count('doc_pdf_export_one "$md" || rc=1') == 2
assert 'exit "$rc"' in no_target
# One rc for the whole no-target branch: must not reset between the two trees.
ideas, docs = no_target.split("if [[ -d docs ]];", 1)
assert "rc=0" in ideas
assert ideas.index("local_found=0") < ideas.index("rc=0")
assert "rc=0" not in docs.split("done", 1)[0]
print("ok")
PY
  assertEquals 'export failure aggregation source assertions failed' 0 $?
}

test_no_target_loops_propagate_failure() {
  local root tmp item base status call_log
  root="$(pwd -P)"
  tmp="$(mktemp -d --tmpdir="${root}/data/tmp" no-target-fail-XXXXXX)"
  call_log="$tmp/calls"
  trap 'rm -rf "$tmp"' RETURN

  mkdir -p "$tmp/data/ideas" "$tmp/docs" "$tmp/bin" "$tmp/asc/doc"
  for item in "$root/asc"/*; do
    base="$(basename "$item")"
    [[ "$base" == doc ]] && continue
    ln -s "$item" "$tmp/asc/$base"
  done
  for item in "$root/asc/doc"/*; do
    base="$(basename "$item")"
    [[ "$base" == md2pdf_asc.py || "$base" == pdf_export.sh ]] && continue
    ln -s "$item" "$tmp/asc/doc/$base"
  done
  cp "$root/asc/doc/pdf.sh" "$tmp/asc/doc/pdf.sh"
  cat >"$tmp/asc/doc/md/md2pdf_asc.py" <<'PY'
import os
import sys
from pathlib import Path

md = Path(sys.argv[1])
out = Path(sys.argv[sys.argv.index("-o") + 1])
with Path(os.environ["EXPORT_CALL_LOG"]).open("a", encoding="utf-8") as fh:
    fh.write(f"{md.as_posix()}\n")
if "fail" in md.name:
    sys.exit(1)
out.write_text("%PDF-stub\n", encoding="utf-8")
PY
  printf '#!/bin/bash\nexit 0\n' >"$tmp/bin/md2pdf"
  chmod +x "$tmp/bin/md2pdf"
  ln -s "$(command -v python3)" "$tmp/bin/python"

  # ideas fails once then succeeds; every docs file succeeds.
  printf '# fail\n' >"$tmp/data/ideas/a-fail.md"
  printf '# ok\n' >"$tmp/data/ideas/b-ok.md"
  printf '# ok\n' >"$tmp/docs/a-ok.md"
  printf '# ok\n' >"$tmp/docs/b-ok.md"
  : >"$call_log"

  (
    cd "$tmp" || exit 1
    export EXPORT_CALL_LOG="$call_log"
    export PATH="$tmp/bin:$PATH"
    ./asc/doc/pdf.sh --force
  )
  status=$?

  assertNotEquals 'ideas failure must keep no-target exit non-zero' 0 "$status"
  assertTrue 'ideas failure attempted' "grep -qx 'data/ideas/a-fail.md' \"$call_log\""
  assertTrue 'ideas success after failure' "grep -qx 'data/ideas/b-ok.md' \"$call_log\""
  assertTrue 'docs first success ran' "grep -qx 'docs/a-ok.md' \"$call_log\""
  assertTrue 'docs second success ran' "grep -qx 'docs/b-ok.md' \"$call_log\""
  assertEquals 'four converter calls' 4 "$(wc -l <"$call_log")"
  assertTrue 'ideas success PDF written' "[ -f \"$tmp/data/ideas/b-ok.pdf\" ]"
  assertTrue 'docs a-ok PDF written' "[ -f \"$tmp/docs/a-ok.pdf\" ]"
  assertTrue 'docs b-ok PDF written' "[ -f \"$tmp/docs/b-ok.pdf\" ]"
  assertFalse 'ideas failure PDF must not appear' "[ -f \"$tmp/data/ideas/a-fail.pdf\" ]"
}

test_graphviz_er_fixture_pdf() {
  if ! command -v dot >/dev/null 2>&1; then
    echo "skip graphviz fixture (dot not on PATH)"
    return 0
  fi
  local tmp html text status
  tmp="$(mktemp -d --tmpdir="${PWD}/data/tmp" graphviz-er-XXXXXX)"
  html="$("$PDF_PY" - <<PY
from pathlib import Path
from md2pdf_asc import find_project_root, print_html_path_for
md = Path("$tmp/graphviz-er.md")
root = find_project_root(md.resolve())
print(print_html_path_for(md, root))
PY
)"
  trap 'rm -rf "$tmp"; rm -f "$html"' RETURN
  cp asc/doc/fixtures/graphviz-er.md "$tmp/graphviz-er.md"
  ./asc/doc/pdf.sh --force "$tmp/graphviz-er.md"
  status=$?
  assertEquals 'graphviz temp export failed' 0 "$status"
  assertTrue "print HTML missing: $html" "[ -f \"$html\" ]"
  assertTrue 'graphviz-wrap missing' "grep -q 'class=\"graphviz-wrap\"' \"$html\""
  assertTrue 'svg missing' "grep -q '<svg' \"$html\""
  grep -q 'fill="#ffffcc"' "$html" || true
  assertFalse 'raw digraph in HTML' "grep -q 'digraph' \"$html\""
  assertFalse 'raw fillcolor in HTML' "grep -q 'fillcolor' \"$html\""
  assertFalse 'raw fence in HTML' "grep -q '\`\`\`dot' \"$html\""
  text="$(pdftotext -layout "$tmp/graphviz-er.pdf" -)"
  assertTrue 'Article label missing' "echo \"$text\" | grep -q 'Article'"
  assertTrue 'Article category missing' "echo \"$text\" | grep -q 'Article category'"
  assertTrue 'Author label missing' "echo \"$text\" | grep -q 'Author'"
  assertFalse 'raw digraph in PDF text' "echo \"$text\" | grep -q 'digraph'"
  assertFalse 'raw fillcolor in PDF text' "echo \"$text\" | grep -q 'fillcolor'"
  assertFalse 'raw fence in PDF text' "echo \"$text\" | grep -q '\`\`\`dot'"
}

test_diagrams_fit_print_page() {
  "$PDF_PY" - <<'PYTEST'
import asyncio
from playwright.async_api import async_playwright
from md2pdf_asc import FIT_DIAGRAMS_JS

async def check():
    async with async_playwright() as playwright:
        browser = await playwright.chromium.launch()
        page = await browser.new_page(viewport={"width": 800, "height": 1000})
        await page.set_content("""<style>
          .mermaid-wrap, .graphviz-wrap { margin: 6px 0; }
          .mermaid-wrap { display: flex; }
          svg { max-width: 100%; height: auto; }
        </style>
        <div class="mermaid-wrap"><svg width="500" height="2000" viewBox="0 0 500 2000"></svg></div>
        <div class="graphviz-wrap"><svg width="500" height="2000" viewBox="0 0 500 2000"></svg></div>
        <div class="graphviz-wrap"><svg width="300" height="100" viewBox="0 0 300 100"></svg></div>""")
        await page.evaluate(FIT_DIAGRAMS_JS, 900)
        sizes = await page.locator("svg").evaluate_all("els => els.map(e => { const r = e.getBoundingClientRect(); return [r.width, r.height]; })")
        assert all(h <= 888.1 for w, h in sizes[:2]), sizes
        assert all(abs(w / h - 0.25) < 0.001 for w, h in sizes[:2]), sizes
        assert abs(sizes[2][0] - 300) < 0.1, sizes
        await browser.close()

asyncio.run(check())
PYTEST
  assertEquals 'diagram page fitting failed' 0 $?
}

test_a3_landscape_page_and_rebuild() {
  if ! command -v pdfinfo >/dev/null 2>&1; then
    echo "skip A3 page size (pdfinfo not on PATH)"
    return 0
  fi
  if ! command -v pdftotext >/dev/null 2>&1; then
    echo "skip A3 page size (pdftotext not on PATH)"
    return 0
  fi
    if ! command -v md2pdf >/dev/null 2>&1; then
    echo "skip A3 page size (md2pdf not on PATH)"
    return 0
  fi
  "$PDF_PY" - <<'PY'
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

from print_paginate import (
    MIN_TABLE_ROWS,
    PAGE_A3_LANDSCAPE,
    content_height_px,
    content_width_px,
    parse_pdf_lines,
)

ROOT = Path(".").resolve()
A4_MEDIA_WIDTH_PT = 210.0 * 72.0 / 25.4
# Playwright's bottom margin is 1.0cm (about 28 pt). 36 pt clears the footer.
FOOTER_BAND_PT = 36.0
_WORD_RE = re.compile(
    r'<word xMin="([0-9.]+)" yMin="([0-9.]+)" xMax="([0-9.]+)" '
    r'yMax="([0-9.]+)">(.*?)</word>'
)

tmp = Path(tempfile.mkdtemp(prefix="a3-page-size-", dir=ROOT / "data" / "tmp"))
written_html: list[Path] = []
extra_paths: list[Path] = []
try:
    (tmp / "dir").mkdir()
    (tmp / "wide").mkdir()
    (tmp / "flow").mkdir()
    (tmp / "gv").mkdir()
    (tmp / "dir" / "one.md").write_text("# One\n\nHello one.\n", encoding="utf-8")
    (tmp / "dir" / "two.md").write_text("# Two\n\nHello two.\n", encoding="utf-8")
    shutil.copy("asc/doc/fixtures/mermaid-dense.md", tmp / "wide" / "diagram.md")
    shutil.copy("asc/doc/fixtures/widow-table.md", tmp / "flow" / "table.md")
    shutil.copy("asc/doc/fixtures/graphviz-er.md", tmp / "gv" / "graphviz-er.md")

    def export(*args: str) -> str:
        proc = subprocess.run(
            ["./asc/doc/pdf.sh", *args],
            check=False,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        if proc.returncode != 0:
            raise AssertionError(
                f"pdf_export.sh {' '.join(args)} failed "
                f"(exit {proc.returncode}):\n{proc.stdout}"
            )
        return proc.stdout

    def pdfinfo_text(pdf: Path) -> str:
        proc = subprocess.run(
            ["pdfinfo", str(pdf)],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        return proc.stdout

    def page_mm(pdf: Path) -> str:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Page size:")
        )
        parts = line.split()
        width = round(float(parts[2]) * 25.4 / 72)
        height = round(float(parts[4]) * 25.4 / 72)
        return f"{width} x {height}"

    def page_pts(pdf: Path) -> tuple[float, float]:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Page size:")
        )
        parts = line.split()
        return float(parts[2]), float(parts[4])

    def page_count(pdf: Path) -> int:
        line = next(
            row for row in pdfinfo_text(pdf).splitlines() if row.startswith("Pages:")
        )
        return int(line.split()[1])

    def print_html_for(md: Path) -> Path:
        rel = md.resolve().relative_to(ROOT).as_posix()
        safe = rel.replace("/", "__").replace(" ", "_")
        if safe.endswith(".md"):
            safe = safe[: -len(".md")]
        path = ROOT / "data" / "tmp" / "doc-print" / f"{safe}.html"
        written_html.append(path)
        return path

    def word_boxes(pdf: Path) -> list[tuple[float, float, float, float, str]]:
        xml = subprocess.check_output(
            ["pdftotext", "-bbox-layout", str(pdf), "-"],
            text=True,
        )
        boxes = [
            (float(xmin), float(ymin), float(xmax), float(ymax), raw)
            for xmin, ymin, xmax, ymax, raw in _WORD_RE.findall(xml)
        ]
        assert boxes, pdf
        return boxes

    def assert_inside_media_box(pdf: Path) -> None:
        # Words pdftotext omitted cannot fail this loop. Survival of a
        # clipped-away label is checked by requiring that label's text.
        width_pt, height_pt = page_pts(pdf)
        for xmin, ymin, xmax, ymax, _raw in word_boxes(pdf):
            assert -1.0 <= xmin <= xmax <= width_pt + 1.0, (pdf, xmin, xmax, width_pt)
            assert -1.0 <= ymin <= ymax <= height_pt + 1.0, (pdf, ymin, ymax, height_pt)

    def word_named(pdf: Path, label: str) -> tuple[float, float, float, float]:
        hits = [
            (xmin, ymin, xmax, ymax)
            for xmin, ymin, xmax, ymax, raw in word_boxes(pdf)
            if raw.strip() == label
        ]
        assert len(hits) == 1, (label, hits)
        return hits[0]

    def content_max_xmax(pdf: Path) -> float:
        _width_pt, height_pt = page_pts(pdf)
        xs = [
            xmax
            for _xmin, ymin, xmax, _ymax, _raw in word_boxes(pdf)
            if ymin <= height_pt - FOOTER_BAND_PT
        ]
        assert xs, pdf
        return max(xs)

    one = tmp / "dir" / "one.md"
    one_pdf = tmp / "dir" / "one.pdf"
    two = tmp / "dir" / "two.md"
    two_pdf = tmp / "dir" / "two.pdf"
    rel_one = str(one.relative_to(ROOT))
    rel_dir = str((tmp / "dir").relative_to(ROOT))
    print_html_for(one)
    print_html_for(two)

    out = export("--force", rel_one)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "210 x 297"
    assert one_pdf.is_file()
    assert not (tmp / "dir" / "one-a3.pdf").exists()

    out = export(rel_one)
    assert f"skip (up to date): {rel_one}" in out, out
    assert page_mm(one_pdf) == "210 x 297"

    out = export("--a3-l", rel_one)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "420 x 297"

    out = export(rel_one)
    assert f"skip (up to date): {rel_one}" in out, out
    assert page_mm(one_pdf) == "420 x 297"

    out = export("--force", rel_one)
    assert page_mm(one_pdf) == "210 x 297", out

    out = export("--a3-l", rel_dir)
    assert "skip (up to date)" not in out, out
    assert page_mm(one_pdf) == "420 x 297"
    assert page_mm(two_pdf) == "420 x 297"

    out = export("--force", rel_dir)
    assert page_mm(one_pdf) == "210 x 297"
    assert page_mm(two_pdf) == "210 x 297"

    diagram = tmp / "wide" / "diagram.md"
    diagram_pdf = tmp / "wide" / "diagram.pdf"
    rel_diagram = str(diagram.relative_to(ROOT))
    diagram_html = print_html_for(diagram)
    a4_diagram_out = export("--force", rel_diagram)
    assert "left as source" not in a4_diagram_out, a4_diagram_out
    assert page_mm(diagram_pdf) == "210 x 297"
    a4_content_xmax = content_max_xmax(diagram_pdf)
    diagram_out = export("--a3-l", rel_diagram)
    assert "left as source" not in diagram_out, diagram_out
    assert "Syntax error" not in diagram_out, diagram_out
    assert page_mm(diagram_pdf) == "420 x 297"
    diagram_text = subprocess.check_output(
        ["pdftotext", "-layout", str(diagram_pdf), "-"],
        text=True,
    )
    assert "The house" in diagram_text
    assert "extract-once" in diagram_text
    assert "the world" in diagram_text
    folded = diagram_text.casefold()
    assert "flowchart" not in folded, diagram_text
    assert "subgraph" not in folded, diagram_text
    assert_inside_media_box(diagram_pdf)
    a3_content_xmax = content_max_xmax(diagram_pdf)
    assert a3_content_xmax > a4_content_xmax, (a3_content_xmax, a4_content_xmax)
    assert a3_content_xmax > A4_MEDIA_WIDTH_PT, (a3_content_xmax, A4_MEDIA_WIDTH_PT)
    diagram_body = diagram_html.read_text(encoding="utf-8")
    assert "size: A3 landscape" in diagram_body.split("@page", 1)[1].split("}", 1)[0]
    assert f"const pageW = {content_width_px(PAGE_A3_LANDSCAPE)};" in diagram_body
    assert f"const pageH = {content_height_px(PAGE_A3_LANDSCAPE)};" in diagram_body

    clip = tmp / "wide" / "clip.md"
    clip_pdf = tmp / "wide" / "clip.pdf"
    clip.write_text(
        "# Clip probe\n\n```mermaid\nflowchart LR\n"
        '  L["CLIPLEFT"] --> R["CLIPRIGHT"]\n```\n',
        encoding="utf-8",
    )
    print_html_for(clip)
    clip_out = export("--a3-l", str(clip.relative_to(ROOT)))
    assert "left as source" not in clip_out, clip_out
    assert "Syntax error" not in clip_out, clip_out
    clip_text = subprocess.check_output(
        ["pdftotext", "-layout", str(clip_pdf), "-"],
        text=True,
    )
    assert "CLIPLEFT" in clip_text
    assert "CLIPRIGHT" in clip_text
    assert "flowchart" not in clip_text.casefold(), clip_text
    left = word_named(clip_pdf, "CLIPLEFT")
    right = word_named(clip_pdf, "CLIPRIGHT")
    clip_width, clip_height = page_pts(clip_pdf)
    for xmin, ymin, xmax, ymax in (left, right):
        assert -1.0 <= xmin <= xmax <= clip_width + 1.0, (xmin, xmax, clip_width)
        assert -1.0 <= ymin <= ymax <= clip_height + 1.0, (ymin, ymax, clip_height)
    assert right[0] > left[2], (left, right)

    table = tmp / "flow" / "table.md"
    table_pdf = tmp / "flow" / "table.pdf"
    rel_table = str(table.relative_to(ROOT))
    print_html_for(table)
    export("--force", rel_table)
    assert page_mm(table_pdf) == "210 x 297"
    assert page_count(table_pdf) >= 2
    export("--a3-l", rel_table)
    assert page_mm(table_pdf) == "420 x 297"
    assert page_count(table_pdf) >= 2
    assert_inside_media_box(table_pdf)
    table_lines = parse_pdf_lines(table_pdf)
    alpha_names = ("Alpha", "Bravo", "Charlie", "Delta", "Echo")
    expected_rows = [f"Observation for {name}" for name in alpha_names]
    expected_rows += [f"Observation for R{number:02d}" for number in range(1, 46)]
    joined = "\n".join(line.text for line in table_lines)
    missing = [label for label in expected_rows if label not in joined]
    assert not missing, missing
    alpha = [
        line for line in table_lines
        if any(f"Observation for {name}" in line.text for name in alpha_names)
    ]
    assert len(alpha) >= 5, [line.text for line in alpha]
    assert {line.page for line in alpha} == {alpha[0].page}, alpha
    r_lines = [line for line in table_lines if "Observation for R" in line.text]
    first_page = min(line.page for line in r_lines)
    on_first = [line for line in r_lines if line.page == first_page]
    later = [line for line in r_lines if line.page > first_page]
    assert later, "tall table should continue past its first page"
    assert len(on_first) >= MIN_TABLE_ROWS, [line.text for line in on_first]
    r01 = next(line for line in r_lines if "Observation for R01" in line.text)
    assert any(
        line.page == r01.page and line.y <= r01.y and "Source" in line.text
        for line in table_lines
    ), r01

    if shutil.which("dot") is None:
        print("skip A3 Graphviz (dot not on PATH)")
    else:
        gv = tmp / "gv" / "graphviz-er.md"
        gv_pdf = tmp / "gv" / "graphviz-er.pdf"
        rel_gv = str(gv.relative_to(ROOT))
        gv_html = print_html_for(gv)
        gv_out = export("--a3-l", rel_gv)
        assert page_mm(gv_pdf) == "420 x 297", gv_out
        gv_body = gv_html.read_text(encoding="utf-8")
        assert 'class="graphviz-wrap"' in gv_body
        assert "<svg" in gv_body
        assert "digraph" not in gv_body
        assert "```dot" not in gv_body
        gv_text = subprocess.check_output(
            ["pdftotext", "-layout", str(gv_pdf), "-"],
            text=True,
        )
        assert "Article" in gv_text
        assert "Article category" in gv_text
        assert "Author" in gv_text
        folded_gv = gv_text.casefold()
        assert "digraph" not in folded_gv, gv_text
        assert "fillcolor" not in folded_gv, gv_text
        assert "```dot" not in gv_text
        assert_inside_media_box(gv_pdf)

    preview_md = ROOT / "asc" / "doc" / "fixtures" / f"a3-preview-{tmp.name}.md"
    extra_paths.append(preview_md)
    preview_md.write_text("# Preview probe\n\nOne paragraph.\n", encoding="utf-8")
    preview_html = print_html_for(preview_md)
    subprocess.run(
        ["./asc/doc/md/to_html.sh", str(preview_md.relative_to(ROOT))],
        check=True,
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    preview_page = preview_html.read_text(encoding="utf-8").split("@page", 1)[1].split("}", 1)[0]
    assert "size: A4" in preview_page
    assert "A3" not in preview_page
    assert page_mm(diagram_pdf) == "420 x 297"
    print("ok")
finally:
    shutil.rmtree(tmp)
    for html_path in written_html:
        html_path.unlink(missing_ok=True)
    for path in extra_paths:
        path.unlink(missing_ok=True)
PY
  assertEquals 'A3 landscape export assertions failed' 0 $?
}

suite() {
  if [ -n "${PDF_TEST_FILTER:-}" ]; then
    for _pdf_test in $PDF_TEST_FILTER; do
      if ! declare -F "$_pdf_test" >/dev/null 2>&1; then
        echo "PDF_TEST_FILTER: unknown test function: $_pdf_test" >&2
        exit 1
      fi
      suite_addTest "$_pdf_test"
    done
  fi
}

. asc/vendor/shunit2/shunit2
