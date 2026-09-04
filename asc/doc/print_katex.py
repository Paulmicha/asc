"""KaTeX protect/restore and browser run (pipeline stages 1, 3, 9)."""

from __future__ import annotations

import html as html_lib
import re

_FENCED_CODE_RE = re.compile(r"(```[\s\S]*?```)")
_KATEX_DISPLAY_DOLLAR = re.compile(r"\$\$[\s\S]+?\$\$")
_KATEX_DISPLAY_LATEX = re.compile(r"\\\[[\s\S]+?\\\]")
_KATEX_INLINE_DOLLAR = re.compile(r"(?<!\$)\$(?!\$)(?:\\.|[^$\n])+?\$(?!\$)")
_KATEX_INLINE_LATEX = re.compile(r"\\\([\s\S]+?\\\)")
_KATEX_ANY = re.compile(
    r"\$\$[\s\S]+?\$\$"
    r"|(?<!\$)\$(?!\$)(?:\\.|[^$\n])+?\$(?!\$)"
    r"|\\\[[\s\S]+?\\\]"
    r"|\\\([\s\S]+?\\\)"
)
_KATEX_PLACEHOLDER_FMT = "@@ASC_MATH_{i}@@"
_KATEX_PLACEHOLDER_RE = re.compile(r"@@ASC_MATH_(\d+)@@")


def html_has_katex(html: str) -> bool:
    """True when HTML/markdown still contains dollar or LaTeX math delimiters."""
    return bool(_KATEX_ANY.search(html))


def protect_katex_math(markdown_text: str) -> tuple[str, list[str]]:
    """Stash math so Markdown emphasis cannot eat TeX underscores.

    Order: ``$$``, ``\\[``, ``$``, ``\\(``. Display math is wrapped in a
    ``<div class="asc-math-display">`` so it is not left inside a ``<p>``.
    """
    placeholders: list[str] = []

    def stash_inline(match: re.Match[str]) -> str:
        placeholders.append(match.group(0))
        return _KATEX_PLACEHOLDER_FMT.format(i=len(placeholders) - 1)

    def stash_display(match: re.Match[str]) -> str:
        placeholders.append(match.group(0))
        tok = _KATEX_PLACEHOLDER_FMT.format(i=len(placeholders) - 1)
        return f'\n\n<div class="asc-math-display">{tok}</div>\n\n'

    parts = _FENCED_CODE_RE.split(markdown_text)
    out: list[str] = []
    for i, part in enumerate(parts):
        if i % 2 == 1:
            out.append(part)
            continue
        part = _KATEX_DISPLAY_DOLLAR.sub(stash_display, part)
        part = _KATEX_DISPLAY_LATEX.sub(stash_display, part)
        part = _KATEX_INLINE_DOLLAR.sub(stash_inline, part)
        part = _KATEX_INLINE_LATEX.sub(stash_inline, part)
        out.append(part)
    return "".join(out), placeholders


def restore_katex_math(html: str, placeholders: list[str]) -> str:
    """Put stashed math back into HTML for KaTeX auto-render."""

    def repl(match: re.Match[str]) -> str:
        idx = int(match.group(1))
        if 0 <= idx < len(placeholders):
            return html_lib.escape(placeholders[idx])
        return match.group(0)

    return _KATEX_PLACEHOLDER_RE.sub(repl, html)


def katex_assets_html(css_rel: str, js_rel: str, auto_rel: str) -> str:
    """``<link>`` + scripts for local KaTeX (file:// relative URLs)."""
    return f"""<link rel="stylesheet" href="{css_rel}">
<style>
  .katex {{
    display: inline-block !important;
    vertical-align: baseline;
    line-height: 1;
    font-size: 1.05em;
    text-indent: 0;
    white-space: nowrap;
  }}
  .katex-display {{
    display: block !important;
    margin: 0.55em 0;
    text-align: center;
    white-space: normal;
  }}
  .asc-math-display {{
    margin: 0.55em 0;
    text-align: center;
  }}
  .asc-math-display .katex-display {{
    margin: 0;
  }}
  .katex .katex-mathml {{
    display: none !important;
  }}
  .katex-display .vlist-t {{
    height: auto !important;
  }}
</style>
<script src="{js_rel}"></script>
<script src="{auto_rel}"></script>
"""


KATEX_RUN_JS = r"""
async function ascRunKatex() {
  if (typeof renderMathInElement !== 'function') return;
  try {
    renderMathInElement(document.body, {
      delimiters: [
        {left: '$$', right: '$$', display: true},
        {left: '\\[', right: '\\]', display: true},
        {left: '$', right: '$', display: false},
        {left: '\\(', right: '\\)', display: false}
      ],
      throwOnError: false,
      output: 'html',
      ignoredTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code'],
      ignoredClasses: ['mermaid', 'mermaid-wrap']
    });
  } catch (err) {
    console.error('KaTeX render failed', err);
  }
  document.querySelectorAll('.katex-mathml').forEach(function (el) { el.remove(); });
  document.querySelectorAll('.katex-error').forEach(function (el) {
    console.error('KaTeX error', el.getAttribute('title') || el.textContent);
  });
  document.querySelectorAll('.katex').forEach(function (el) {
    var isDisplay = el.classList.contains('katex-display')
      || (el.parentElement && el.parentElement.classList.contains('katex-display'));
    if (!isDisplay) {
      el.style.display = 'inline-block';
      el.style.verticalAlign = 'baseline';
      el.style.lineHeight = '1';
      el.style.whiteSpace = 'nowrap';
    }
    var parent = el.parentElement;
    if (
      parent
      && parent.tagName === 'SPAN'
      && !parent.className
      && parent.childElementCount === 1
      && parent.childNodes.length === 1
    ) {
      parent.replaceWith(el);
    }
  });
  var lineH = parseFloat(getComputedStyle(document.body).lineHeight) || 16;
  document.querySelectorAll('.katex-display').forEach(function (el) {
    if (el.offsetHeight <= 4 * lineH) return;
    el.style.lineHeight = '1';
    el.style.overflow = 'hidden';
    el.querySelectorAll('.katex, .katex-html').forEach(function (n) {
      n.style.lineHeight = '1';
      n.style.overflow = 'hidden';
    });
    el.querySelectorAll('.vlist-t').forEach(function (n) {
      n.style.height = 'auto';
    });
    var maxH = 6 * lineH;
    if (el.offsetHeight > maxH) {
      var s = maxH / el.offsetHeight;
      el.style.transformOrigin = 'top center';
      el.style.transform = 'scale(' + s + ')';
      el.style.height = maxH + 'px';
    }
  });
}
"""
