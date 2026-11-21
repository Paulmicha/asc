#!/usr/bin/env bash

##
# ASC doc-pdf paging / page-geometry tests (orphans, widows, fit, print CSS).
#
# @requires asc/vendor/shunit2
# @see asc/doc/pdf.sh
# @see asc/doc/md/md2pdf_asc.py
#
# @example
#   asc/doc/pdf/tests/paging.test.sh
#   PDF_TEST_FILTER=test_name asc/doc/pdf/tests/paging.test.sh
#

. asc/bootstrap.sh
. asc/doc/pdf/tests/common.manual-inc.sh

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
from paginate import (
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
from paginate import (
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

test_fit_content_height_from_probe() {
  "$PDF_PY" - <<'PY'
from paginate import (
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
from paginate import PdfLine, heading_keep_from_pdf, is_heading_orphan

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
from paginate import (
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

. asc/vendor/shunit2/shunit2
