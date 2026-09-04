"""Mermaid candidates (Python) and browser run (pipeline stage 8)."""

from __future__ import annotations

import html as html_lib
import json
import re

from print_paginate import (
    MERMAID_FONT_PX,
    MERMAID_LABEL_WRAP_CHARS,
    MERMAID_MAX_CANDIDATES,
    MERMAID_MIN_FONT_PX,
    MERMAID_SKIP_RETRY_SCALE,
    MERMAID_TIE_EPS,
    mermaid_layout_px,
)

RANK_FLIP = {"LR": "TD", "RL": "BT", "TD": "LR", "TB": "LR", "BT": "RL"}
_HEADER_RANK = re.compile(
    r"^(flowchart(?:-elk)?|graph)\s+(LR|RL|TB|TD|BT)\b",
    re.MULTILINE,
)
_QUOTED = re.compile(r'"([^"]*)"')
_PRE_MERMAID = re.compile(
    r'(<pre\b[^>]*\bclass="[^"]*\bmermaid\b[^"]*"[^>]*)(>)(.*?)(</pre>)',
    re.IGNORECASE | re.DOTALL,
)
def _gantt_init() -> str:
    return (
        "%%{init: {'gantt': {'leftPadding': %d, 'barHeight': %d, "
        "'barGap': %d, 'topPadding': %d}}}%%\n"
        % (
            mermaid_layout_px(90),
            mermaid_layout_px(22),
            mermaid_layout_px(8),
            mermaid_layout_px(50),
        )
    )


def mermaid_kind(src: str) -> str:
    """flowchart | state | gantt | sequence | other — first real diagram line."""
    for line in src.splitlines():
        s = line.strip()
        if not s or s.startswith("%%"):
            continue
        low = s.lower()
        if low.startswith("flowchart") or low.startswith("graph "):
            return "flowchart"
        if low.startswith("statediagram"):
            return "state"
        if low.startswith("gantt"):
            return "gantt"
        if low.startswith("sequencediagram"):
            return "sequence"
        return "other"
    return "other"


# Longest first so ``-->>`` wins over ``->>`` at the same ``-``.
_SEQ_ARROWS = (
    "<<->>",
    "-->>",
    "->>",
    "--x",
    "-x",
    "--)",
    "-)",
    "-->",
    "->",
)
_NOTE_MSG_RE = re.compile(
    r"^(?P<pre>\s*Note\b[^:]*:\s*)(?P<msg>.*)$",
    re.IGNORECASE,
)


def _sanitize_seq_msg(msg: str) -> str:
    """Neutralize sequence-lexer traps; wrap the result in double quotes."""
    text = msg.strip()
    if len(text) >= 2 and text[0] == '"' and text[-1] == '"':
        text = text[1:-1]
    text = (
        re.sub(r"\s*;\s*", " — ", text)
        .replace(":", "∶")
        .replace("<", "‹")
        .replace(">", "›")
        .replace('"', "”")
    )
    return f'"{text}"'


def quote_sequence_messages(src: str) -> str:
    """Quote sequence messages so ``;``, ``--``, and extra ``:`` stay literal."""
    out: list[str] = []
    for line in src.splitlines(keepends=True):
        nl = "\n" if line.endswith("\n") else ""
        body = line[:-1] if nl else line
        if body.endswith("\r"):
            body = body[:-1]
            nl = "\r" + nl if nl else "\r"
        note = _NOTE_MSG_RE.match(body)
        if note:
            out.append(note.group("pre") + _sanitize_seq_msg(note.group("msg")) + nl)
            continue
        best: tuple[int, int, str] | None = None
        for arrow in _SEQ_ARROWS:
            pos = body.find(arrow)
            if pos == -1:
                continue
            if best is None or pos < best[0] or (pos == best[0] and len(arrow) > best[1]):
                best = (pos, len(arrow), arrow)
        if best is None:
            out.append(line)
            continue
        pos, alen, _arrow = best
        colon = body.find(":", pos + alen)
        if colon == -1:
            out.append(line)
            continue
        prefix = body[: colon + 1]
        msg = body[colon + 1 :]
        if not msg.strip():
            out.append(line)
            continue
        space = " " if msg[:1].isspace() else ""
        out.append(prefix + space + _sanitize_seq_msg(msg) + nl)
    return "".join(out)


def flowchart_set_rank(src: str, rank: str) -> str:
    """Replace only the diagram header rank. Leave subgraph direction lines."""

    def repl(match: re.Match[str]) -> str:
        return f"{match.group(1)} {rank}"

    new, n = _HEADER_RANK.subn(repl, src, count=1)
    return new if n else src


def _wrap_segment(text: str, max_chars: int) -> str:
    rest = text
    parts: list[str] = []
    while max_chars > 0 and len(rest) > max_chars:
        chunk = rest[:max_chars]
        sp = chunk.rfind(" ")
        if sp <= 0:
            break
        parts.append(rest[:sp])
        rest = rest[sp + 1 :]
    parts.append(rest)
    return "<br>".join(parts)


def wrap_long_labels(src: str, max_chars: int = MERMAID_LABEL_WRAP_CHARS) -> str:
    """Insert <br> at the last space before max_chars in quoted / state labels."""

    def quoted(match: re.Match[str]) -> str:
        inner = match.group(1)
        wrapped = "<br>".join(_wrap_segment(seg, max_chars) for seg in inner.split("<br>"))
        return f'"{wrapped}"'

    out = _QUOTED.sub(quoted, src)
    lines: list[str] = []
    for line in out.splitlines(keepends=True):
        m = re.match(r"(^(?:[^\"\n]*-->[^\"\n]*:\s*))(.+?)(\n?)$", line)
        if m and '"' not in m.group(2):
            label = "<br>".join(
                _wrap_segment(seg, max_chars) for seg in m.group(2).split("<br>")
            )
            lines.append(m.group(1) + label + m.group(3))
        else:
            lines.append(line)
    return "".join(lines)


def mermaid_candidates(src: str) -> list[tuple[str, bool]]:
    """Up to MERMAID_MAX_CANDIDATES items: (code, is_original). Original first."""
    seen: set[str] = set()
    items: list[tuple[str, bool]] = []

    def add(code: str, original: bool) -> None:
        if code in seen or len(items) >= MERMAID_MAX_CANDIDATES:
            return
        seen.add(code)
        items.append((code, original))

    add(src, True)
    kind = mermaid_kind(src)
    wrapped = wrap_long_labels(src)
    if kind == "flowchart":
        header = _HEADER_RANK.search(src)
        if header:
            flipped = flowchart_set_rank(src, RANK_FLIP[header.group(2)])
            add(flipped, False)
            add(wrapped, False)
            add(flowchart_set_rank(wrapped, RANK_FLIP[header.group(2)]), False)
        else:
            add(wrapped, False)
    elif kind == "sequence":
        add(quote_sequence_messages(src), False)
    elif kind in {"state", "gantt"}:
        add(wrapped, False)
        if kind == "gantt" and "%%{init" not in src:
            add(_gantt_init() + src, False)
    return items


def inject_mermaid_candidates(html: str) -> str:
    """Attach JSON candidate lists on each ``pre.mermaid``."""

    def repl(match: re.Match[str]) -> str:
        start, gt, inner, end = match.group(1), match.group(2), match.group(3), match.group(4)
        if "data-asc-cands=" in start:
            return match.group(0)
        raw = html_lib.unescape(inner)
        payload = html_lib.escape(json.dumps(mermaid_candidates(raw)), quote=True)
        return f'{start} data-asc-cands="{payload}"{gt}{inner}{end}'

    return _PRE_MERMAID.sub(repl, html)


def mermaid_vendor_tag(mermaid_rel: str) -> str:
    return f'<script src="{mermaid_rel}"></script>\n'


def mermaid_run_js(page_w: float, page_h: float) -> str:
    pad = mermaid_layout_px(8)
    wrap = mermaid_layout_px(200)
    spacing = mermaid_layout_px(50)
    gantt_left = mermaid_layout_px(75)
    gantt_bar = mermaid_layout_px(20)
    gantt_gap = mermaid_layout_px(4)
    gantt_top = mermaid_layout_px(50)
    seq_actor = mermaid_layout_px(50)
    seq_box = mermaid_layout_px(10)
    seq_msg = mermaid_layout_px(35)
    return f"""
async function ascRunMermaid() {{
  const pres = [...document.querySelectorAll('pre.mermaid')];
  if (!pres.length) return;
  const m = (typeof mermaid !== 'undefined' && mermaid.default) ? mermaid.default : mermaid;
  if (!m) return;
  const pageW = {page_w};
  const pageH = {page_h};
  const skipScale = {MERMAID_SKIP_RETRY_SCALE};
  const minFont = {MERMAID_MIN_FONT_PX};
  const mermaidFont = {MERMAID_FONT_PX};
  const tieEps = {MERMAID_TIE_EPS};
  const ff = 'Source Sans 3, system-ui, sans-serif';
  document.documentElement.style.setProperty(
    '--asc-mermaid-font-size', mermaidFont + 'px'
  );
  if (!document.getElementById('ascMermaidMeasureCss')) {{
    const st = document.createElement('style');
    st.id = 'ascMermaidMeasureCss';
    st.textContent =
      '.nodeLabel,.edgeLabel,foreignObject,foreignObject div,foreignObject span,foreignObject p{{' +
      'font-size:' + mermaidFont + 'px !important;' +
      'font-family:"Source Sans 3",system-ui,sans-serif !important;' +
      'line-height:1.25 !important}}';
    document.head.appendChild(st);
  }}
  m.initialize({{
    startOnLoad: false,
    theme: 'base',
    securityLevel: 'loose',
    fontFamily: ff,
    fontSize: mermaidFont,
    themeVariables: {{ fontSize: mermaidFont + 'px', fontFamily: ff }},
    flowchart: {{
      useMaxWidth: false,
      htmlLabels: true,
      padding: {pad},
      wrappingWidth: {wrap},
      nodeSpacing: {spacing},
      rankSpacing: {spacing}
    }},
    sequence: {{
      useMaxWidth: false,
      actorMargin: {seq_actor},
      boxMargin: {seq_box},
      messageMargin: {seq_msg},
      actorFontSize: mermaidFont,
      messageFontSize: mermaidFont,
      noteFontSize: mermaidFont
    }},
    gantt: {{
      useMaxWidth: false,
      leftPadding: {gantt_left},
      barHeight: {gantt_bar},
      barGap: {gantt_gap},
      topPadding: {gantt_top},
      fontSize: mermaidFont
    }},
    er: {{ useMaxWidth: false }},
    journey: {{ useMaxWidth: false }}
  }});

  function boxesOf(svg) {{
    return [...svg.querySelectorAll('text, .edgeLabel, .nodeLabel, foreignObject')];
  }}
  function rect(el) {{
    const r = el.getBoundingClientRect();
    return {{ x: r.left, y: r.top, w: r.width, h: r.height }};
  }}
  function overlapArea(a, b) {{
    const x = Math.max(0, Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x));
    const y = Math.max(0, Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y));
    return x * y;
  }}
  function bbox(svg) {{
    try {{ return svg.getBBox(); }} catch (e) {{
      return {{ x: 0, y: 0, width: svg.clientWidth || 1, height: svg.clientHeight || 1 }};
    }}
  }}
  function scaleToPage(bb) {{
    return Math.min(pageW / Math.max(bb.width, 1), pageH / Math.max(bb.height, 1), 1);
  }}
  function ascScoreMermaid(svg) {{
    const nodes = boxesOf(svg);
    const rs = nodes.map(rect);
    let overlaps = 0;
    for (let i = 0; i < rs.length; i++) {{
      for (let j = i + 1; j < rs.length; j++) {{
        if (overlapArea(rs[i], rs[j]) > 2) overlaps += 1;
      }}
    }}
    const bb = bbox(svg);
    const vb = svg.viewBox && svg.viewBox.baseVal;
    let clipped = 0;
    nodes.forEach(function (el) {{
      const r = el.getBoundingClientRect();
      const sr = svg.getBoundingClientRect();
      if (r.right > sr.right + 2 || r.bottom > sr.bottom + 2 || r.left < sr.left - 2 || r.top < sr.top - 2) {{
        clipped += 1;
      }}
    }});
    let overflowing = 0;
    svg.querySelectorAll('.node').forEach(function (node) {{
      const nr = node.getBoundingClientRect();
      node.querySelectorAll('.nodeLabel, foreignObject, text').forEach(function (lab) {{
        const lr = lab.getBoundingClientRect();
        if (lr.width > nr.width + 2 || lr.height > nr.height + 2) overflowing += 1;
      }});
    }});
    const scale = scaleToPage(bb);
    let minPx = mermaidFont;
    nodes.forEach(function (el) {{
      const fs = parseFloat(getComputedStyle(el).fontSize) || mermaidFont;
      if (fs < minPx) minPx = fs;
    }});
    const minAfter = minPx * scale;
    const penalty =
      100 * overlaps +
      80 * clipped +
      40 * overflowing +
      50 * (1 - scale) +
      20 * Math.max(0, mermaidFont - minAfter) +
      15 * Math.max(0, minAfter - (mermaidFont + 1));
    return {{ penalty, overlaps, scale, minAfter }};
  }}
  function ascFitViewBox(svg) {{
    const bb = bbox(svg);
    const pad = 4;
    const x = bb.x - pad, y = bb.y - pad;
    const w = Math.max(bb.width + 2 * pad, 1);
    const h = Math.max(bb.height + 2 * pad, 1);
    svg.setAttribute('viewBox', x + ' ' + y + ' ' + w + ' ' + h);
    const scale = Math.min(pageW / w, pageH / h, 1);
    svg.style.width = (w * scale) + 'px';
    svg.style.height = (h * scale) + 'px';
    svg.style.maxWidth = '100%';
  }}
  function ascCenterMermaidLabels(svg) {{
    svg.querySelectorAll('.node').forEach(function (node) {{
      const shape = node.querySelector(
        ':scope > .label-container, :scope > rect, :scope > polygon, :scope > circle, :scope > ellipse, :scope > path'
      );
      const label = node.querySelector(':scope > g.label');
      if (!shape || !label) return;
      const sb = shape.getBoundingClientRect();
      const lb = label.getBoundingClientRect();
      if (sb.width < 2 || sb.height < 2 || lb.width < 1 || lb.height < 1) return;
      const dx = (sb.left + sb.right) / 2 - (lb.left + lb.right) / 2;
      const dy = (sb.top + sb.bottom) / 2 - (lb.top + lb.bottom) / 2;
      if (Math.abs(dx) < 0.75 && Math.abs(dy) < 0.75) return;
      const ctm = node.getScreenCTM();
      if (!ctm || Math.abs(ctm.a) < 1e-6 || Math.abs(ctm.d) < 1e-6) return;
      const ux = dx / ctm.a;
      const uy = dy / ctm.d;
      const prev = label.getAttribute('transform') || '';
      label.setAttribute('transform', (prev + ' translate(' + ux + ', ' + uy + ')').trim());
    }});
  }}
  async function renderOne(code) {{
    const id = 'ascMmd' + (ascRunMermaid._n = (ascRunMermaid._n || 0) + 1);
    try {{
      const {{ svg }} = await m.render(id, code);
      const host = document.createElement('div');
      host.style.position = 'absolute';
      host.style.left = '-9999px';
      host.innerHTML = svg;
      document.body.appendChild(host);
      const svgEl = host.querySelector('svg');
      if (
        !svgEl ||
        svgEl.querySelector('.error-text, .error-icon') ||
        /Syntax error in text/i.test(svgEl.textContent || '')
      ) {{
        host.remove();
        throw new Error('mermaid error svg');
      }}
      return {{ host, svgEl }};
    }} finally {{
      const stray = document.getElementById('d' + id);
      if (stray && stray.parentNode === document.body) stray.remove();
      const straySvg = document.getElementById(id);
      if (straySvg && straySvg.parentNode === document.body) straySvg.remove();
    }}
  }}

  window.__ascMermaidFailed = [];
  for (let i = 0; i < pres.length; i++) {{
    const pre = pres[i];
    let cands;
    try {{
      cands = JSON.parse(pre.getAttribute('data-asc-cands') || 'null');
    }} catch (e) {{
      cands = null;
    }}
    if (!Array.isArray(cands) || !cands.length) {{
      cands = [[pre.textContent, true]];
    }}
    const scored = [];
    try {{
      for (let c = 0; c < cands.length; c++) {{
        try {{
          const rendered = await renderOne(cands[c][0]);
          const s = ascScoreMermaid(rendered.svgEl);
          scored.push({{
            host: rendered.host,
            svgEl: rendered.svgEl,
            penalty: s.penalty + (cands[c][1] ? 0 : 0.1),
            raw: s.penalty,
            overlaps: s.overlaps,
            scale: s.scale,
            minAfter: s.minAfter,
            original: !!cands[c][1],
            code: cands[c][0]
          }});
          if (c === 0 && s.overlaps === 0 && s.scale >= skipScale && s.minAfter >= minFont) {{
            break;
          }}
        }} catch (err) {{
          console.error('Mermaid candidate failed', err);
        }}
      }}
      if (!scored.length) {{
        window.__ascMermaidFailed.push(i + 1);
        continue;
      }}
      const orig = scored.find(function (x) {{ return x.original; }}) || scored[0];
      const skip = orig.overlaps === 0 && orig.scale >= skipScale && orig.minAfter >= minFont;
      let best = orig;
      if (!skip) {{
        for (let s = 0; s < scored.length; s++) {{
          if (scored[s].penalty < best.penalty) best = scored[s];
        }}
        if (!best.original && (orig.penalty - best.penalty) <= tieEps) best = orig;
      }}
      if (!best.original) {{
        console.log('mermaid[' + (i + 1) + ']: retry pick (' + orig.raw.toFixed(1) + ' → ' + best.raw.toFixed(1) + ')');
      }}
      const svgEl = best.svgEl;
      svgEl.remove();
      pre.replaceChildren(svgEl);
      scored.forEach(function (item) {{ item.host.remove(); }});
      ascFitViewBox(svgEl);
      ascCenterMermaidLabels(svgEl);
    }} catch (err) {{
      console.error('Mermaid render failed', err);
      scored.forEach(function (item) {{ try {{ item.host.remove(); }} catch (e) {{}} }});
    }}
  }}
  document.querySelectorAll('[id^="dascMmd"]').forEach(function (el) {{ el.remove(); }});
}}
"""


def patch_mermaid_as_html() -> None:
    """Turn ```mermaid fences into live HTML for in-page Mermaid.js (not PNG)."""
    import md2pdf.html_renderer as hr

    def _process_mermaid_diagrams(markdown_text: str):
        temp_images: list[str] = []
        pattern = r"```mermaid\n(.*?)\n```"
        matches = list(re.finditer(pattern, markdown_text, re.DOTALL))
        for match in reversed(matches):
            code = match.group(1).strip("\n")
            safe = html_lib.escape(code)
            block = (
                '<div class="mermaid-wrap">\n'
                f'<pre class="mermaid">{safe}</pre>\n'
                "</div>\n"
            )
            markdown_text = (
                markdown_text[: match.start()] + block + markdown_text[match.end() :]
            )
        return markdown_text, temp_images

    hr._process_mermaid_diagrams = _process_mermaid_diagrams
