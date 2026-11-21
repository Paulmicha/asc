#!/usr/bin/env bash

##
# ASC doc-pdf diagram tests (Mermaid, Graphviz).
#
# @requires asc/vendor/shunit2
# @see asc/doc/pdf.sh
# @see asc/doc/md/md2pdf_asc.py
#
# @example
#   asc/doc/pdf/tests/diagram.test.sh
#   PDF_TEST_FILTER=test_name asc/doc/pdf/tests/diagram.test.sh
#

. asc/bootstrap.sh
. asc/doc/pdf/tests/common.manual-inc.sh

test_mermaid_candidates() {
  "$PDF_PY" - <<'PY'
from mermaid import (
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
from mermaid import mermaid_run_js
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
# Conversion banner is in main(), not render_html() / md/to_html.sh.
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
  cp data/doc/fixtures/graphviz-er.md "$tmp/graphviz-er.md"
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

. asc/vendor/shunit2/shunit2
