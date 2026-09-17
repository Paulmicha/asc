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

test_graphviz_engine_and_fences() {
  "$PDF_PY" - <<'PY'
import re
import subprocess
from print_graphviz import (
    graphviz_engine_for,
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
    which_dot=lambda name="dot": "/usr/bin/dot",
    runner=_bad_runner,
)
assert "graphviz-error" in nonzero
assert "```dot" not in nonzero

def _timeout_runner(argv, input, timeout):
    raise subprocess.TimeoutExpired(cmd=argv, timeout=timeout)

timed = render_graphviz_fences(
    "```dot\ndigraph G { a -> b }\n```\n",
    which_dot=lambda name="dot": "/usr/bin/dot",
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
    which_dot=lambda name="dot": "/usr/bin/dot",
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
    which_dot=lambda name="dot": "/usr/bin/dot",
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
src = Path("asc/doc/md2pdf_asc.py").read_text(encoding="utf-8")
assert "render_graphviz_fences" in src
# protect → graphviz → orig (markdown/mermaid)
fn = src.split("def markdown_to_html", 1)[1].split("hr.markdown_to_html", 1)[0]
assert fn.index("protect_katex_math") < fn.index("render_graphviz_fences")
assert fn.index("render_graphviz_fences") < fn.index("orig(")
# Conversion banner is in main(), not render_html() / html_preview.sh.
main = src.split("def main", 1)[1]
assert "Graphviz" in main
css = Path("asc/doc/pdf_styles.css").read_text(encoding="utf-8")
assert ".graphviz-wrap" in css
assert "pre.graphviz-error" in css
gv_svg = css.split(".graphviz-wrap svg", 1)[1].split("}", 1)[0]
assert "max-width: 100%" in gv_svg
assert re.search(r"(?<!max-)width:\s*100%", gv_svg) is None
pag = Path("asc/doc/print_paginate.py").read_text(encoding="utf-8")
assert "graphviz-wrap" in pag
katex = Path("asc/doc/print_katex.py").read_text(encoding="utf-8")
assert "graphviz-wrap" in katex and "graphviz-error" in katex
sh = Path("asc/doc/pdf_export.sh").read_text(encoding="utf-8")
assert "graphviz" in sh.lower() and "dot" in sh.lower()
assert "fatal only" not in sh.lower()
preview = Path("asc/doc/html_preview.sh").read_text(encoding="utf-8")
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
    which_dot=lambda name="dot": "/usr/bin/dot",
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

test_graphviz_er_fixture_pdf() {
  if ! command -v dot >/dev/null 2>&1; then
    echo "skip graphviz fixture (dot not on PATH)"
    return 0
  fi
  ./asc/doc/pdf_export.sh --force 'asc/doc/fixtures/graphviz-er.md' || return 1
  html="$(ls -1 data/tmp/doc-print/*graphviz-er.html \
    "$HOME/data/tmp/doc-print/"*graphviz-er.html 2>/dev/null | head -1)"
  [ -n "$html" ] || return 1
  grep -q 'class="graphviz-wrap"' "$html" || return 1
  grep -q '<svg' "$html" || return 1
  grep -q 'fill="#ffffcc"' "$html" || true  # optional; Graphviz may emit rgb()
  grep -q 'digraph' "$html" && return 1
  grep -q 'fillcolor' "$html" && return 1
  grep -q '```dot' "$html" && return 1
  text="$(pdftotext -layout asc/doc/fixtures/graphviz-er.pdf -)"
  echo "$text" | grep -q 'Article' || return 1
  echo "$text" | grep -q 'Article category' || return 1
  echo "$text" | grep -q 'Author' || return 1
  echo "$text" | grep -q 'digraph' && return 1
  echo "$text" | grep -q 'fillcolor' && return 1
  echo "$text" | grep -q '```dot' && return 1
  return 0
}

. asc/vendor/shunit2/shunit2
