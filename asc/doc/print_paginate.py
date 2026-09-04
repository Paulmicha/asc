"""Print pagination: walk layout pages and insert ``<br>`` like a reviewer."""

from __future__ import annotations

import html
import os
import re
import shutil
import statistics
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


MIN_FOLLOWING_LINES = 4
MIN_TABLE_ROWS = 3
MAX_WIDOW_LINE_EQUIV = 4.0
MAX_BR_PER_TARGET = 80
BOTTOM_BAND_LINES = 12.0
A4_WIDTH_PX = 210.0 * 96.0 / 25.4
A4_HEIGHT_PX = 297.0 * 96.0 / 25.4
A4_HEIGHT_PT = 297.0 * 72.0 / 25.4
PT_TO_PX = 96.0 / 72.0
MARGIN_TOP_CM = 0.6
MARGIN_RIGHT_CM = 0.7
MARGIN_BOTTOM_CM = 1.0
MARGIN_LEFT_CM = 0.7
CSS_PAGE_MARGIN_CM = 0.75
PARA_LONG_MIN_LINES = 3
# Body type (CSS html font-size). 1em in print CSS and Mermaid layout.
ASC_FONT_PT = 9.0
MERMAID_MAX_CANDIDATES = 4
MERMAID_SKIP_RETRY_SCALE = 0.70
MERMAID_NATIVE_FONT_PX = 16
MERMAID_LABEL_WRAP_CHARS = 42
MERMAID_TIE_EPS = 5.0


def em_to_px(em: float) -> float:
    """CSS px for an em at ASC_FONT_PT (Chromium 96 CSS px / in)."""
    return em * ASC_FONT_PT * PT_TO_PX


TOP_MAX_PX = em_to_px(0.75)  # already at the top of this layout page
MERMAID_FONT_PX = em_to_px(1.0)
MERMAID_MIN_FONT_PX = em_to_px(0.75)


def mermaid_layout_px(native: float) -> int:
    """Scale a Mermaid 16px-layout length to 1em (ASC_FONT_PT)."""
    return max(1, round(native * MERMAID_FONT_PX / MERMAID_NATIVE_FONT_PX))


@dataclass(frozen=True)
class PageIssue:
    kind: str
    index: int


def content_box(page_h: float, margin_top: float, margin_bottom: float) -> float:
    return page_h - margin_top - margin_bottom


def content_height_px() -> float:
    """One layout-page height in CSS px (viewport / Y slice)."""
    top = CSS_PAGE_MARGIN_CM * 96.0 / 2.54
    bottom = MARGIN_BOTTOM_CM * 96.0 / 2.54
    return A4_HEIGHT_PX - top - bottom


def content_width_px() -> float:
    css = CSS_PAGE_MARGIN_CM * 96.0 / 2.54
    return A4_WIDTH_PX - 2 * css


_WORD_RE = re.compile(
    r'<word xMin="([0-9.]+)" yMin="([0-9.]+)" xMax="([0-9.]+)" '
    r'yMax="([0-9.]+)">(.*?)</word>'
)
_FOOTER_RE = re.compile(r"^\d+\s*/\s*\d+$")


@dataclass(frozen=True)
class PdfLine:
    page: int
    y: float
    text: str


def normalize_print_text(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(text)).strip().casefold()


def text_match(needle: str, haystack: str) -> bool:
    a = normalize_print_text(needle)
    b = normalize_print_text(haystack)
    if not a or not b:
        return False
    if a == b:
        return True
    n = min(48, len(a), len(b))
    if n >= 8 and (a[:n] == b[:n] or a in b or b in a):
        return True
    if len(a) < 8:
        return b.startswith(a)
    return False


def parse_pdf_lines(path: str | Path) -> list[PdfLine]:
    xml = subprocess.check_output(
        ["pdftotext", "-bbox-layout", str(path), "-"],
        text=True,
    )
    out: list[PdfLine] = []
    for page_i, chunk in enumerate(xml.split("<page ")[1:], start=1):
        by_y: dict[float, list[tuple[float, str]]] = {}
        for xmin, ymin, _xmax, _ymax, raw in _WORD_RE.findall(chunk):
            y = float(ymin)
            if y > A4_HEIGHT_PT - 25:
                continue
            by_y.setdefault(round(y, 1), []).append(
                (float(xmin), html.unescape(raw))
            )
        coalesced: list[PdfLine] = []
        for y, words in sorted(by_y.items()):
            text = re.sub(
                r"\s+", " ", " ".join(t for _, t in sorted(words))
            ).strip()
            if not text or _FOOTER_RE.match(text):
                continue
            if (
                coalesced
                and coalesced[-1].page == page_i
                and y - coalesced[-1].y < 3.5
            ):
                prev = coalesced[-1]
                coalesced[-1] = PdfLine(
                    page_i, prev.y, (prev.text + " " + text).strip()
                )
            else:
                coalesced.append(PdfLine(page_i, y, text))
        out.extend(coalesced)
    return out


def pdf_content_top_pt(lines: list[PdfLine]) -> float:
    firsts: dict[int, float] = {}
    for ln in lines:
        firsts.setdefault(ln.page, ln.y)
    if not firsts:
        return CSS_PAGE_MARGIN_CM * 72.0 / 2.54
    return float(statistics.median(firsts.values()))


def locate_layout_on_pdf(
    dom: list[dict],
    lines: list[PdfLine],
    guess: float | None = None,
    content_top_pt: float | None = None,
) -> list[tuple[float, int, float] | None]:
    """Map DOM headings to PDF lines: (layout_y, pdf_page, pdf_y_pt) or None.

    A table of contents repeats heading text on early pages. When ``guess``
    is set, pick the PDF line whose implied layout Y is closest to the DOM Y
    instead of the first sequential match.
    """
    if not guess or guess <= 0:
        hits: list[tuple[float, int, float] | None] = []
        cursor = 0
        for item in dom:
            needle = str(item.get("text") or "")
            layout_y = float(item.get("y") or 0)
            found = None
            for i in range(cursor, len(lines)):
                if text_match(needle, lines[i].text):
                    found = (layout_y, lines[i].page, lines[i].y)
                    cursor = i + 1
                    break
            hits.append(found)
        return hits

    top = (
        content_top_pt
        if content_top_pt is not None
        else pdf_content_top_pt(lines)
    )
    used: set[int] = set()
    hits: list[tuple[float, int, float] | None] = []
    for item in dom:
        needle = str(item.get("text") or "")
        layout_y = float(item.get("y") or 0)
        best: tuple[float, int, PdfLine] | None = None
        for i, ln in enumerate(lines):
            if i in used or not text_match(needle, ln.text):
                continue
            expected_y = (ln.page - 1) * guess + (ln.y - top) * PT_TO_PX
            score = abs(expected_y - layout_y)
            if best is None or score < best[0]:
                best = (score, i, ln)
        if best is None:
            hits.append(None)
            continue
        _score, idx, ln = best
        used.add(idx)
        hits.append((layout_y, ln.page, ln.y))
    return hits


def heading_keep_from_pdf(
    lines: list[PdfLine],
    page: int,
    heading_y: float,
    table_rows: tuple[str, ...] | None,
    next_heading_page: int | None = None,
) -> bool:
    """True when the probe PDF already has a full section on this page.

    A table stub (< 3 rows on this page) does not count. A later heading
    already on this page with four+ following lines is ## 6, not a
    stacked orphan at the page end.
    """
    following = [
        ln for ln in lines if ln.page == page and ln.y > heading_y + 2
    ]
    if next_heading_page == page and len(following) >= MIN_FOLLOWING_LINES:
        return True
    if table_rows:
        n_table = 0
        used = 0
        for row in table_rows:
            matched = False
            for i, ln in enumerate(following[used:], start=used):
                if text_match(row, ln.text):
                    n_table += 1
                    used = i + 1
                    matched = True
                    break
            if not matched:
                break
        if n_table >= MIN_TABLE_ROWS:
            return True
        table_start = None
        if table_rows:
            for ln in following:
                if text_match(table_rows[0], ln.text):
                    table_start = ln.y
                    break
        if table_start is not None:
            body = sum(1 for ln in following if ln.y < table_start)
            if body >= MIN_FOLLOWING_LINES:
                return True
            # Wide cells split across PDF lines, so DOM row strings often
            # fail to match. Lines after the header still count as body.
            table_lines = sum(1 for ln in following if ln.y >= table_start)
            return table_lines >= MIN_FOLLOWING_LINES
    return len(following) >= MIN_FOLLOWING_LINES


HEADING_TAGS = {"H1", "H2", "H3", "H4", "H5", "H6"}


def section_owns_table(
    prev_tags: list[str], intro_line_equiv: float
) -> bool:
    """True when a table spacer would split a heading from its table.

    ``prev_tags`` is nearest previous real sibling first. A short intro
    (one paragraph, < 4 line-equivalents) still belongs to the heading.
    """
    if not prev_tags:
        return False
    if prev_tags[0] in HEADING_TAGS:
        return True
    if intro_line_equiv >= MIN_FOLLOWING_LINES:
        return False
    return any(tag in HEADING_TAGS for tag in prev_tags)


def fit_content_height_px(
    hits: list[tuple[float, int, float]],
    content_top_pt: float,
    guess: float,
) -> float:
    """Infer Chromium's print page height from one probe PDF.

    layout_y ≈ (pdf_page - 1) * contentH + (pdf_y_pt - content_top_pt) * 96/72
    """
    hs: list[float] = []
    for layout_y, pdf_page, pdf_y_pt in hits:
        if pdf_page < 2:
            continue
        pdf_y_px = (pdf_y_pt - content_top_pt) * PT_TO_PX
        h = (layout_y - pdf_y_px) / (pdf_page - 1)
        if guess * 0.75 < h < guess * 1.25:
            hs.append(h)
    if not hs:
        return guess
    hs.sort()
    fitted = hs[len(hs) // 2]
    return min(guess + 80.0, max(guess - 80.0, fitted))


def trim_overshoot_spacer(
    y_on_next: float,
    min_height: float,
    n_br: int,
    br_h: float,
    top_eps: float,
) -> tuple[float, int]:
    """Shrink a spacer that landed past the top of the next layout page.

    ``minHeight`` may go to 0. Extra ``<br>`` tags still occupy space
    after minHeight is reduced, so they are dropped too.
    """
    if y_on_next <= top_eps:
        new_min = min_height
    else:
        new_min = max(0.0, min_height - y_on_next)
    # One line short of the layout remaining: Chromium otherwise splits a
    # leftover <br> onto the next page (blank line above the heading).
    new_min = max(0.0, new_min - br_h)
    while n_br > 0 and n_br * br_h > new_min + top_eps:
        n_br -= 1
    return new_min, n_br


def is_heading_orphan(
    y_on_page: float,
    following_lines: float,
    continues: bool,
    top_max: float = TOP_MAX_PX,
) -> bool:
    if y_on_page <= top_max:
        return False
    if following_lines >= MIN_FOLLOWING_LINES:
        return False
    return continues


def is_table_widow(
    y_on_page: float,
    n_fit: int,
    n_rows: int,
    remaining_px: float,
    line_h: float,
    top_max: float = TOP_MAX_PX,
    bottom_band_lines: float = BOTTOM_BAND_LINES,
) -> bool:
    if y_on_page <= top_max:
        return False
    if remaining_px > bottom_band_lines * line_h:
        return False
    if n_fit < 1 or n_fit >= MIN_TABLE_ROWS:
        return False
    return n_fit < n_rows


def choose_bottom_issue(
    table: PageIssue | None, heading: PageIssue | None
) -> PageIssue | None:
    """Orphan table row first; heading wins when it sits above that table."""
    if table and heading and heading.index < table.index:
        return heading
    if table:
        return table
    return heading


_MARK_BODY = """
  const lineH = parseFloat(getComputedStyle(document.body).lineHeight) || 16;
  document.querySelectorAll('p').forEach((p) => {
    if (p.closest('table, pre, .mermaid, .mermaid-wrap')) return;
    const lines = p.getBoundingClientRect().height / lineH;
    if (lines >= 3) p.classList.add('asc-para-long');
  });
  window.__ascParaMarked = true;
"""

MARK_LONG_PARAS_JS = "() => {" + _MARK_BODY + "}"

ASC_MARK_LONG_PARAS_FN = "function ascMarkLongParagraphs() {" + _MARK_BODY + "}"

# One layout pass after a single probe PDF has calibrated contentH.
PAGINATE_JS = r"""
({ contentH, lineH, minFollow, minRows, maxBr, topEps, bottomBandLines }) => {
  const brH = (() => {
    const d = document.createElement('div');
    d.className = 'asc-print-push';
    d.innerHTML = '<br>';
    document.body.appendChild(d);
    const h = d.getBoundingClientRect().height || lineH;
    d.remove();
    return h;
  })();
  const isHeading = (el) => el && /^H[1-6]$/.test(el.tagName);
  const isPush = (el) => el && el.classList && el.classList.contains('asc-print-push');
  const yOf = (el) => el.getBoundingClientRect().top + window.scrollY;
  const pageOf = (y) => Math.floor(y / contentH);
  const yOn = (y) => y - pageOf(y) * contentH;

  const nextReal = (el) => {
    let n = el.nextElementSibling;
    while (n && (isPush(n) || n.getBoundingClientRect().height === 0)) {
      n = n.nextElementSibling;
    }
    return n;
  };

  const targets = () => [...document.querySelectorAll('h1,h2,h3,h4,h5,h6,table')];

  const clearPush = (el) => {
    const sp = el.previousElementSibling;
    if (isPush(sp)) sp.remove();
  };

  const addBr = (el) => {
    let sp = el.previousElementSibling;
    if (!isPush(sp)) {
      sp = document.createElement('div');
      sp.className = 'asc-print-push';
      sp.setAttribute(
        'data-asc-push',
        el.tagName === 'TABLE' ? 'table' : 'heading'
      );
      sp.setAttribute('aria-hidden', 'true');
      el.parentNode.insertBefore(sp, el);
    }
    sp.appendChild(document.createElement('br'));
    return sp;
  };

  const fillRemaining = (el, remaining) => {
    const sp = addBr(el);
    const nBr = Math.max(1, Math.ceil(Math.max(remaining, brH) / brH));
    while (sp.querySelectorAll('br').length < nBr) {
      sp.appendChild(document.createElement('br'));
    }
    sp.style.minHeight = Math.max(remaining, 0) + 'px';
    return sp;
  };

  const nFit = (t) => {
    const remaining = contentH - yOn(yOf(t));
    let used = 0;
    let n = 0;
    for (const tr of t.querySelectorAll('tr')) {
      const h = tr.getBoundingClientRect().height;
      if (n > 0 && used + h > remaining + 0.5) break;
      used += h;
      n += 1;
      if (used > remaining + 0.5 && n === 1) break;
    }
    return n;
  };

  const tableFragmentLines = (t, page) => {
    let usedH = 0;
    for (const tr of t.querySelectorAll('tr')) {
      const top = yOf(tr);
      if (pageOf(top) !== page) break;
      usedH += tr.getBoundingClientRect().height;
    }
    return usedH / lineH;
  };

  const sectionHeadForTable = (t) => {
    let n = t.previousElementSibling;
    let intro = 0;
    while (n) {
      if (isPush(n) || n.getBoundingClientRect().height === 0) {
        n = n.previousElementSibling;
        continue;
      }
      if (n.tagName === 'TABLE' || (n.classList && n.classList.contains('mermaid-wrap'))) {
        break;
      }
      if (isHeading(n)) {
        return n;
      }
      intro += n.getBoundingClientRect().height / lineH;
      if (intro >= minFollow) return null;
      n = n.previousElementSibling;
    }
    return null;
  };

  const followingOnPage = (el, page) => {
    let acc = 0;
    let n = nextReal(el);
    let hasLater = false;
    while (n) {
      const top = yOf(n);
      if (pageOf(top) !== page) {
        hasLater = true;
        break;
      }
      if (isHeading(n)) {
        n = nextReal(n);
        continue;
      }
      if (n.tagName === 'TABLE') {
        const nf = nFit(n);
        acc += tableFragmentLines(n, page);
        if (nf < minRows) {
          const rows = n.querySelectorAll('tr');
          const last = rows[rows.length - 1];
          if (last && pageOf(yOf(last)) !== page) hasLater = true;
          break;
        }
        acc = Math.max(acc, minFollow);
        break;
      }
      acc += n.getBoundingClientRect().height / lineH;
      if (acc >= minFollow) break;
      n = nextReal(n);
    }
    return { lines: acc, hasLater };
  };

  const tableWidow = (t, page) => {
    const head = sectionHeadForTable(t);
    if (head) {
      if (head.getAttribute('data-asc-keep') === '1') return false;
      if (pageOf(yOf(head)) === page) return false;
    }
    const y = yOf(t);
    if (pageOf(y) !== page) return false;
    if (yOn(y) <= topEps) return false;
    const remaining = contentH - yOn(y);
    if (remaining > bottomBandLines * lineH) return false;
    const nf = nFit(t);
    const nRows = t.querySelectorAll('tr').length;
    if (nf < 1 || nf >= minRows) return false;
    return nf < nRows;
  };

  const headingOrphan = (h, page) => {
    if (h.getAttribute('data-asc-keep') === '1') return false;
    const y = yOf(h);
    if (pageOf(y) !== page) return false;
    if (yOn(y) <= topEps) return false;
    const { lines, hasLater } = followingOnPage(h, page);
    if (!hasLater) return false;
    return lines < minFollow;
  };

  const bottomIssue = (page) => {
    const els = targets().filter((el) => pageOf(yOf(el)) === page);
    let tableEl = null;
    let headingEl = null;
    for (const el of els) {
      if (!tableEl && el.tagName === 'TABLE' && tableWidow(el, page)) {
        tableEl = el;
      }
      if (!headingEl && isHeading(el) && headingOrphan(el, page)) {
        headingEl = el;
      }
    }
    if (tableEl && headingEl) {
      const pos = headingEl.compareDocumentPosition(tableEl);
      if (pos & Node.DOCUMENT_POSITION_FOLLOWING) {
        clearPush(tableEl);
        return headingEl;
      }
    }
    return tableEl || headingEl;
  };

  const trimOvershoot = (el, sp, fromPage) => {
    let n = sp.querySelectorAll('br').length;
    if (pageOf(yOf(el)) <= fromPage) return n;
    const cur = parseFloat(sp.style.minHeight) || 0;
    let yon = yOn(yOf(el));
    let next = yon > topEps ? Math.max(0, cur - yon) : cur;
    next = Math.max(0, next - brH);
    sp.style.minHeight = next + 'px';
    while (pageOf(yOf(el)) > fromPage && yOn(yOf(el)) > topEps) {
      const last = sp.querySelector('br:last-child');
      if (!last) break;
      last.remove();
      n -= 1;
    }
    if (pageOf(yOf(el)) === fromPage) {
      addBr(el);
      n += 1;
      sp.style.minHeight = cur + 'px';
    }
    const h = parseFloat(sp.style.minHeight) || 0;
    sp.style.height = h + 'px';
    sp.style.overflow = 'hidden';
    return n;
  };

  const pushUntilNextTop = (el, fromPage) => {
    const remaining = contentH - yOn(yOf(el));
    const sp = fillRemaining(el, remaining);
    let n = sp.querySelectorAll('br').length;
    while (pageOf(yOf(el)) === fromPage && n < maxBr) {
      addBr(el);
      n += 1;
    }
    return trimOvershoot(el, sp, fromPage);
  };

  const debug = [];
  let page = 0;
  let inserted = 0;
  let guard = 0;
  while (guard < 5000) {
    guard += 1;
    const nPages = Math.max(
      1,
      Math.ceil((document.body.scrollHeight || contentH) / contentH)
    );
    if (page >= nPages) break;
    const el = bottomIssue(page);
    if (!el) {
      page += 1;
      continue;
    }
    const before = pageOf(yOf(el));
    const n = pushUntilNextTop(el, page);
    inserted += n;
    debug.push({
      page: page + 1,
      kind: el.tagName === 'TABLE' ? 'table' : 'heading',
      br: n,
      text: (el.innerText || '').replace(/\s+/g, ' ').slice(0, 64),
    });
    if (pageOf(yOf(el)) === before) {
      page += 1;
    }
  }
  window.__ascPaginateLog = debug;
  return inserted;
}
"""


_DOM_Y_JS = """() => {
  const norm = (s) => (s || '').replace(/\\s+/g, ' ').trim();
  const nodes = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6,table')];
  const heads = [];
  for (let i = 0; i < nodes.length; i++) {
    const el = nodes[i];
    if (el.tagName === 'TABLE') continue;
    let rows = [];
    for (let j = i + 1; j < nodes.length; j++) {
      if (nodes[j].tagName === 'TABLE') {
        rows = [...nodes[j].querySelectorAll('tr')].map((tr) =>
          norm([...tr.querySelectorAll('th,td')].map((c) => c.innerText).join(' '))
        );
        break;
      }
    }
    heads.push({
      text: norm(el.innerText),
      y: el.getBoundingClientRect().top + window.scrollY,
      rows,
    });
  }
  return heads;
}"""

_MARK_KEEP_JS = """(idxs) => {
  const hs = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')];
  for (const i of idxs) {
    if (hs[i]) hs[i].setAttribute('data-asc-keep', '1');
  }
}"""


async def _measure_content_height(page, pdf_options: dict) -> float:
    """One probe PDF. Fit layout page height to Chromium's real pages."""
    guess = content_height_px()
    if not shutil.which("pdftotext"):
        return guess
    tmp_dir = Path(tempfile.mkdtemp(prefix="asc-paginate-"))
    tmp = tmp_dir / "probe.pdf"
    try:
        await page.evaluate(
            """() => {
              document.querySelectorAll('[data-asc-keep],[data-asc-remain]').forEach((el) => {
                el.removeAttribute('data-asc-keep');
                el.removeAttribute('data-asc-remain');
              });
            }"""
        )
        await page.pdf(**{**pdf_options, "path": str(tmp)})
        lines = parse_pdf_lines(tmp)
        if not lines:
            return guess
        dom = await page.evaluate(_DOM_Y_JS)
        top_pt = pdf_content_top_pt(lines)
        hits = locate_layout_on_pdf(dom or [], lines, guess, top_pt)
        fitted = fit_content_height_px(
            [h for h in hits if h is not None], top_pt, guess
        )
        keep: list[int] = []
        for i, (item, hit) in enumerate(zip(dom or [], hits)):
            if hit is None:
                continue
            _layout_y, pdf_page, pdf_y = hit
            next_page = None
            for later in hits[i + 1 :]:
                if later is not None:
                    next_page = later[1]
                    break
            rows = tuple(item.get("rows") or ())
            if heading_keep_from_pdf(
                lines, pdf_page, pdf_y, rows or None, next_page
            ):
                keep.append(i)
        if keep:
            await page.evaluate(_MARK_KEEP_JS, keep)
        if os.environ.get("ASC_PAGINATE_DEBUG"):
            keep_txt = [
                (dom[i].get("text") or "")[:40] for i in keep[:12]
            ]
            print(
                f"  print page height: guess={guess:.1f}px "
                f"fitted={fitted:.1f}px top={top_pt:.1f}pt "
                f"hits={len(hits)} keep={len(keep)} {keep_txt}"
            )
        return fitted
    except (OSError, subprocess.CalledProcessError):
        return guess
    finally:
        try:
            tmp.unlink(missing_ok=True)
            tmp_dir.rmdir()
        except OSError:
            pass


async def apply_print_pushes(page, pdf_options: dict | None = None) -> int:
    """Stage 12: insert ``<br>`` in layout. Last DOM mutation before page.pdf()."""
    line_h = await page.evaluate(
        "() => parseFloat(getComputedStyle(document.body).lineHeight) || 16"
    )
    if pdf_options is None:
        content_h = content_height_px()
    else:
        content_h = await _measure_content_height(page, pdf_options)
    inserted = await page.evaluate(
        PAGINATE_JS,
        {
            "contentH": content_h,
            "lineH": line_h,
            "minFollow": MIN_FOLLOWING_LINES,
            "minRows": MIN_TABLE_ROWS,
            "maxBr": MAX_BR_PER_TARGET,
            "topEps": TOP_MAX_PX,
            "bottomBandLines": BOTTOM_BAND_LINES,
        },
    )
    if os.environ.get("ASC_PAGINATE_DEBUG"):
        log = await page.evaluate("() => window.__ascPaginateLog || []")
        dump = await page.evaluate(
            """() => [...document.querySelectorAll('.asc-print-push')].map((sp) => {
              const n = sp.nextElementSibling;
              const text = n ? (n.innerText || '').replace(/\\s+/g, ' ').slice(0, 72) : '';
              const brs = sp.querySelectorAll('br').length;
              return (sp.getAttribute('data-asc-push') || '') + ' ' + brs + 'br → ' +
                (n ? n.tagName : '?') + ' ' + text;
            })"""
        )
        print("  page review:")
        for row in log or []:
            print(
                f"    p{row.get('page')} {row.get('kind')} "
                f"{row.get('br')}br {row.get('text')!r}"
            )
        print("  spacers:")
        for row in dump or []:
            print(f"    {row}")
    return int(inserted or 0)
