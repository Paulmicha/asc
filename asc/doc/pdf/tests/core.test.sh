#!/usr/bin/env bash

##
# ASC doc-pdf core requirements tests (pipeline, export, A3, code explode).
#
# @requires asc/vendor/shunit2
# @see asc/doc/pdf.sh
# @see asc/doc/md/md2pdf_asc.py
#
# @example
#   asc/doc/pdf/tests/core.test.sh
#   PDF_TEST_FILTER=test_name asc/doc/pdf/tests/core.test.sh
#

. asc/bootstrap.sh
. asc/doc/pdf/tests/common.manual-inc.sh

test_render_html_same_process_resets_to_a4() {
  "$PDF_PY" - <<'PY'
import shutil
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import md2pdf.html_renderer
from md2pdf_asc import main, render_html
from paginate import PAGE_A3_LANDSCAPE, PAGE_A4, selected_page

def at_page(html: str) -> str:
    return html.split("@page", 1)[1].split("}", 1)[0]

def assert_a4_after(src: Path) -> None:
    assert selected_page() == PAGE_A4, selected_page()
    page = at_page(render_html(src))
    assert "size: A4" in page, page
    assert "A3" not in page, page

src = Path("data/doc/fixtures/para-gap.md")
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
    [[ "$base" == md || "$base" == pdf.sh ]] && continue
    ln -s "$item" "$tmp/asc/doc/$base"
  done
  mkdir -p "$tmp/asc/doc/md"
  for item in "$root/asc/doc/md"/*; do
    base="$(basename "$item")"
    [[ "$base" == md2pdf_asc.py ]] && continue
    ln -s "$item" "$tmp/asc/doc/md/$base"
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

from paginate import (
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
    shutil.copy("data/doc/fixtures/mermaid-dense.md", tmp / "wide" / "diagram.md")
    shutil.copy("data/doc/fixtures/widow-table.md", tmp / "flow" / "table.md")
    shutil.copy("data/doc/fixtures/graphviz-er.md", tmp / "gv" / "graphviz-er.md")

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
                f"pdf.sh {' '.join(args)} failed "
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

    preview_md = ROOT / "data" / "doc" / "fixtures" / f"a3-preview-{tmp.name}.md"
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

. asc/vendor/shunit2/shunit2
