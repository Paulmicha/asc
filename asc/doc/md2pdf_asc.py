#!/usr/bin/env python3
"""
ASC-styled md2pdf wrapper (Spectral + Source Code Pro + compact type).

md2pdf's HTML engine ignores --font and hardcodes ~11pt system UI fonts.
This wraps convert_markdown_to_pdf_html, replacing the embedded <style>
with asc/doc/pdf_styles.css and @font-face rules for
Spectral (bundled under fonts/Spectral/) and Source Code Pro
(fonts/SourceCodePro-Powerline-Awesome-Regular.ttf) for monospace.

Mermaid: ```mermaid blocks become live HTML (.mermaid) rendered by the
local self-contained bundle at asc/vendor/mermaid.esm.min.mjs (IIFE,
no CDN). KaTeX: $...$ / $$...$$ in the HTML are typeset by the local
bundle at asc/vendor/katex/ (CSS + JS + auto-render, no CDN). Printable
HTML is written under data/tmp/ so Mermaid, KaTeX, and fonts load via
relative paths. Math spans are stashed before Markdown conversion so
underscores in TeX (e.g. ``$\\mathcal{D}_{\\mathrm{train}}$``) are not eaten
by emphasis. Local <img src> paths are rewritten from the markdown
file's directory to that print HTML, so images next to the .md resolve
under file://.

Usage:
  asc/doc/md2pdf_asc.py input.md -o output.pdf
"""
from __future__ import annotations

import argparse
import html as html_lib
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
# asc/doc -> asc -> project root (repo containing data/, docs/, asc/)
ASC_DIR = SCRIPT_DIR.parent
PROJECT_ROOT_DEFAULT = ASC_DIR.parent
STYLE_CSS = SCRIPT_DIR / "pdf_styles.css"
FONTS_DIR = SCRIPT_DIR / "fonts"
FONT_DIR = FONTS_DIR / "Spectral"
FONT_FAMILY = "Spectral"
MONO_FONT_FAMILY = "Source Code Pro"
MONO_FONT_FILE = FONTS_DIR / "SourceCodePro-Powerline-Awesome-Regular.ttf"
MERMAID_VENDOR = ASC_DIR / "vendor" / "mermaid.esm.min.mjs"
KATEX_VENDOR = ASC_DIR / "vendor" / "katex"
KATEX_FILES = ("katex.min.css", "katex.min.js", "auto-render.min.js")
# Match pdf_styles.css --asc-font-size. Mermaid sequence diagrams ignore
# themeVariables.fontSize for actors (hardcoded 16px) unless sequence.*FontSize
# is set — those options expect a px number, not pt.
MERMAID_FONT_SIZE = "8pt"
MERMAID_FONT_SIZE_PX = 11  # 8pt ≈ 10.67px at 96dpi

# Paths for the current conversion (relative Mermaid/font URLs).
_CURRENT_SOURCE_MD: Path | None = None
_PROJECT_ROOT: Path | None = None
_PRINT_HTML_PATH: Path | None = None

# Bundled static faces (Production Type Spectral / OFL).
FACE_FILES = {
    "regular": "Spectral-Regular.ttf",
    "bold": "Spectral-Bold.ttf",
    "italic": "Spectral-Italic.ttf",
    "bold_italic": "Spectral-BoldItalic.ttf",
}


def _face_path(kind: str) -> Path | None:
    name = FACE_FILES[kind]
    p = FONT_DIR / name
    return p if p.is_file() else None


def rel_url(from_file: Path, to_file: Path) -> str:
    """POSIX relative path from from_file's directory to to_file."""
    return Path(
        os.path.relpath(to_file.resolve(), start=from_file.resolve().parent)
    ).as_posix()


def font_face_css(html_path: Path) -> str:
    faces = {k: _face_path(k) for k in FACE_FILES}
    if not faces["regular"]:
        print(
            f"ERROR: {FACE_FILES['regular']} not found under {FONT_DIR}\n"
            "Unpack Spectral static TTFs there (see OFL.txt / README.md).",
            file=sys.stderr,
        )
        sys.exit(1)
    if not MONO_FONT_FILE.is_file():
        print(
            f"ERROR: monospace TTF not found: {MONO_FONT_FILE}\n"
            "Place SourceCodePro-Powerline-Awesome-Regular.ttf under fonts/ "
            "(cleaned names; no '+' in PostScript name — breaks Chromium PDF widths).",
            file=sys.stderr,
        )
        sys.exit(1)

    def url(p: Path) -> str:
        return rel_url(html_path, p)

    rules = []
    mapping = [
        ("regular", "normal", "normal"),
        ("bold", "normal", "bold"),
        ("italic", "italic", "normal"),
        ("bold_italic", "italic", "bold"),
    ]
    for key, font_style, font_weight in mapping:
        path = faces.get(key) or faces["regular"]
        rules.append(
            f"""@font-face {{
  font-family: "{FONT_FAMILY}";
  font-style: {font_style};
  font-weight: {font_weight};
  src: url("{url(path)}") format("truetype");
  font-display: swap;
}}"""
        )
    mono_rel = url(MONO_FONT_FILE)
    for font_style, font_weight in (
        ("normal", "normal"),
        ("normal", "bold"),
        ("italic", "normal"),
        ("italic", "bold"),
    ):
        rules.append(
            f"""@font-face {{
  font-family: "{MONO_FONT_FAMILY}";
  font-style: {font_style};
  font-weight: {font_weight};
  src: url("{mono_rel}") format("truetype");
  font-display: swap;
}}"""
        )
    missing = [k for k, v in faces.items() if v is None]
    if missing:
        print(
            f"  note: Spectral faces missing ({', '.join(missing)}); "
            "falling back to Regular for those weights.",
            file=sys.stderr,
        )
    return "\n\n".join(rules)


def build_style_block(html_path: Path) -> str:
    css = STYLE_CSS.read_text(encoding="utf-8")
    return f"<style>\n{font_face_css(html_path)}\n\n{css}\n</style>"


def require_mermaid_vendor() -> Path:
    if not MERMAID_VENDOR.is_file():
        print(
            f"ERROR: local Mermaid not found: {MERMAID_VENDOR}\n"
            "Expected self-contained Mermaid bundle at asc/vendor/mermaid.esm.min.mjs",
            file=sys.stderr,
        )
        sys.exit(1)
    return MERMAID_VENDOR


def require_katex_vendor() -> Path:
    missing = [name for name in KATEX_FILES if not (KATEX_VENDOR / name).is_file()]
    if missing or not (KATEX_VENDOR / "fonts").is_dir():
        print(
            f"ERROR: local KaTeX not found under {KATEX_VENDOR}\n"
            "Expected katex.min.css, katex.min.js, auto-render.min.js, and fonts/",
            file=sys.stderr,
        )
        sys.exit(1)
    return KATEX_VENDOR


_KATEX_DELIM_RE = re.compile(r"\$\$[\s\S]+?\$\$|\$(?:\\.|[^$\n])+?\$")
_KATEX_DISPLAY_RE = re.compile(r"\$\$[\s\S]+?\$\$")
_KATEX_INLINE_RE = re.compile(r"(?<!\$)\$(?!\$)(?:\\.|[^$\n])+?\$(?!\$)")
_FENCED_CODE_RE = re.compile(r"(```[\s\S]*?```)")
# Plain-text tokens (not HTML comments): Markdown treats comments as block HTML
# and pulls them out of <p>, which drops mid-sentence math like $x$ / $H$.
_KATEX_PLACEHOLDER_FMT = "@@ASC_MATH_{i}@@"
_KATEX_PLACEHOLDER_RE = re.compile(r"@@ASC_MATH_(\d+)@@")


def html_has_katex(html: str) -> bool:
    """True when HTML still contains $...$ or $$...$$ math delimiters."""
    return bool(_KATEX_DELIM_RE.search(html))


def protect_katex_math(markdown_text: str) -> tuple[str, list[str]]:
    """Stash $...$ / $$...$$ so Markdown emphasis cannot eat TeX underscores.

    Display math is wrapped in a <div> so it is not left inside a <p> (KaTeX
    display mode is block-level; block-in-<p> breaks Chromium PDF layout).
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
        part = _KATEX_DISPLAY_RE.sub(stash_display, part)
        part = _KATEX_INLINE_RE.sub(stash_inline, part)
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


def mermaid_boot_script(html_path: Path) -> str:
    """Classic script boot (IIFE vendor) — works with file:// relative src."""
    mermaid_path = require_mermaid_vendor()
    mermaid_rel = rel_url(html_path, mermaid_path)
    ff = f"{FONT_FAMILY}, Georgia, serif"
    px = MERMAID_FONT_SIZE_PX
    # Half of Mermaid flowchart default node padding (15 → 8).
    MERMAID_NODE_PADDING = 8
    theme_css = (
        ".mermaid text,.mermaid tspan,.mermaid .nodeLabel,"
        ".mermaid .edgeLabel,.mermaid .label,.mermaid .labelText,"
        ".mermaid .actor,.mermaid .messageText,.mermaid .noteText,"
        ".mermaid foreignObject,.mermaid foreignObject div,"
        ".mermaid foreignObject span{"
        f"font-size:{MERMAID_FONT_SIZE} !important;"
        f"font-family:{ff} !important;"
        "}"
        ".mermaid .nodeLabel p{margin:0!important;padding:0!important;}"
        ".mermaid foreignObject div{line-height:1.25!important;}"
    )
    # IIFE bundle exposes global `mermaid`. Avoid type=module: Chromium blocks
    # parent-directory ESM imports under file://.
    return f"""<script src="{mermaid_rel}"></script>
<script>
  (function () {{
    const m = (typeof mermaid !== 'undefined' && mermaid.default) ? mermaid.default : mermaid;
    m.initialize({{
      startOnLoad: false,
      theme: 'base',
      securityLevel: 'loose',
      fontFamily: '{ff}',
      fontSize: {px},
      themeVariables: {{
        fontSize: '{MERMAID_FONT_SIZE}',
        fontFamily: '{ff}'
      }},
      themeCSS: {theme_css!r},
      flowchart: {{
        useMaxWidth: true,
        htmlLabels: true,
        padding: {MERMAID_NODE_PADDING}
      }},
      sequence: {{
        useMaxWidth: true,
        actorFontSize: {px},
        messageFontSize: {px},
        noteFontSize: {px}
      }},
      er: {{ useMaxWidth: true }},
      journey: {{ useMaxWidth: true }}
    }});
    window.__ascMermaidReady = m.run().then(() => {{
      window.__ascMermaidDone = true;
    }}).catch((err) => {{
      console.error('Mermaid render failed', err);
      window.__ascMermaidDone = true;
    }});
  }})();
</script>
"""


def katex_boot_script(html_path: Path) -> str:
    """Local KaTeX auto-render — works with file:// relative src."""
    katex_dir = require_katex_vendor()
    css_rel = rel_url(html_path, katex_dir / "katex.min.css")
    js_rel = rel_url(html_path, katex_dir / "katex.min.js")
    auto_rel = rel_url(html_path, katex_dir / "auto-render.min.js")
    return f"""<link rel="stylesheet" href="{css_rel}">
<style>
  /*
   * Chromium PDF: KaTeX strut/vlist nesting inflates line boxes when .katex
   * stays display:inline. Atomic inline-block keeps baseline math in-flow.
   */
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
  /* Hidden MathML still pollutes Chromium's PDF text layer / copy-paste. */
  .katex .katex-mathml {{
    display: none !important;
  }}
</style>
<script src="{js_rel}"></script>
<script src="{auto_rel}"></script>
<script>
  (function () {{
    function ascFinishKatex() {{
      document.querySelectorAll('.katex-mathml').forEach(function (el) {{
        el.remove();
      }});
      /* auto-render wraps .katex in a bare <span>; unwrap so inline-block applies. */
      document.querySelectorAll('.katex').forEach(function (el) {{
        var isDisplay = el.classList.contains('katex-display')
          || (el.parentElement && el.parentElement.classList.contains('katex-display'));
        if (!isDisplay) {{
          el.style.display = 'inline-block';
          el.style.verticalAlign = 'baseline';
          el.style.lineHeight = '1';
          el.style.whiteSpace = 'nowrap';
        }}
        var parent = el.parentElement;
        if (
          parent
          && parent.tagName === 'SPAN'
          && !parent.className
          && parent.childElementCount === 1
          && parent.childNodes.length === 1
        ) {{
          parent.replaceWith(el);
        }}
      }});
      var ready = (document.fonts && document.fonts.ready)
        ? document.fonts.ready
        : Promise.resolve();
      ready.then(function () {{
        window.__ascKatexDone = true;
      }}).catch(function () {{
        window.__ascKatexDone = true;
      }});
    }}
    function ascRunKatex() {{
      try {{
        renderMathInElement(document.body, {{
          delimiters: [
            {{left: '$$', right: '$$', display: true}},
            {{left: '$', right: '$', display: false}}
          ],
          throwOnError: false,
          output: 'html'
        }});
      }} catch (err) {{
        console.error('KaTeX render failed', err);
      }}
      ascFinishKatex();
    }}
    if (window.__ascMermaidReady) {{
      window.__ascMermaidReady.then(ascRunKatex).catch(ascRunKatex);
    }} else {{
      ascRunKatex();
    }}
  }})();
</script>
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


def find_project_root(source_md: Path) -> Path:
    """Nearest ancestor with docs/ and (.git or asc/)."""
    for parent in (source_md.resolve().parent, *source_md.resolve().parents):
        if (parent / "docs").is_dir() and (
            (parent / ".git").exists() or (parent / "asc").is_dir()
        ):
            return parent
    if PROJECT_ROOT_DEFAULT.is_dir():
        return PROJECT_ROOT_DEFAULT
    return Path.cwd().resolve()


def print_html_path_for(source_md: Path, project_root: Path) -> Path:
    """Project-local HTML path so relative vendor/font URLs resolve."""
    try:
        rel = source_md.resolve().relative_to(project_root.resolve())
    except ValueError:
        rel = Path(source_md.name)
    safe = str(rel).replace("/", "__").replace(" ", "_")
    if safe.endswith(".md"):
        safe = safe[: -len(".md")]
    return project_root / "data" / "tmp" / "doc-print" / f"{safe}.html"


_IMG_SRC_RE = re.compile(
    r'(<img\b[^>]*?\bsrc=)(["\'])([^"\']+)\2',
    re.IGNORECASE,
)


def rewrite_local_img_srcs(html: str, source_md: Path, html_path: Path) -> str:
    """Point <img src> at files relative to print HTML, not the .md."""
    md_dir = source_md.resolve().parent
    html_dir = html_path.resolve().parent

    def repl(match: re.Match[str]) -> str:
        prefix, quote, src = match.group(1), match.group(2), match.group(3)
        if src.startswith(("http://", "https://", "data:", "file:", "#")):
            return match.group(0)
        raw = Path(src)
        target = raw if raw.is_absolute() else (md_dir / src)
        try:
            target = target.resolve()
        except OSError:
            return match.group(0)
        if not target.is_file():
            return match.group(0)
        rel = Path(os.path.relpath(target, start=html_dir)).as_posix()
        return f"{prefix}{quote}{rel}{quote}"

    return _IMG_SRC_RE.sub(repl, html)


def patch_html_renderer() -> None:
    import md2pdf.html_renderer as hr

    patch_mermaid_as_html()

    orig = hr.markdown_to_html

    def markdown_to_html(markdown_text: str, title: str = "Document",
                         enable_mermaid: bool = True) -> str:
        # Protect math before Python-Markdown turns _…_ into <em>.
        protected, katex_placeholders = protect_katex_math(markdown_text)
        html = orig(protected, title=title, enable_mermaid=enable_mermaid)
        html = restore_katex_math(html, katex_placeholders)
        html_path = _PRINT_HTML_PATH
        if html_path is None:
            raise RuntimeError("Internal error: print HTML path not set")
        style_block = build_style_block(html_path)
        html2, n = re.subn(
            r"<style>.*?</style>",
            lambda _m: style_block,
            html,
            count=1,
            flags=re.DOTALL,
        )
        if n != 1:
            raise RuntimeError("Failed to replace md2pdf embedded <style> block")
        boot = ""
        if enable_mermaid and 'class="mermaid"' in html2:
            boot += mermaid_boot_script(html_path)
        if html_has_katex(html2):
            boot += katex_boot_script(html_path)
        if boot:
            if "</body>" not in html2:
                raise RuntimeError("HTML missing </body>; cannot inject scripts")
            html2 = html2.replace("</body>", boot + "</body>", 1)
        source_md = _CURRENT_SOURCE_MD
        if source_md is not None:
            html2 = rewrite_local_img_srcs(html2, source_md, html_path)
        return html2

    hr.markdown_to_html = markdown_to_html

    async def html_to_pdf_playwright(html_content: str, output_path: str,
                                     page_size: str = "A4",
                                     orientation: str = "portrait") -> bool:
        try:
            from playwright.async_api import async_playwright
        except ImportError:
            print("Error: Playwright not available")
            return False

        html_path = _PRINT_HTML_PATH
        if html_path is None:
            print("Error: print HTML path not set")
            return False

        try:
            html_path.parent.mkdir(parents=True, exist_ok=True)
            html_path.write_text(html_content, encoding="utf-8")

            pdf_options = {
                "path": output_path,
                "format": page_size,
                "landscape": orientation.lower() == "landscape",
                "print_background": True,
                "display_header_footer": True,
                "header_template": "<div></div>",
                "footer_template": (
                    f'<div style="font-family: \'{FONT_FAMILY}\', sans-serif; '
                    "font-size: 7px; text-align: center; width: 100%; "
                    'color: #666;"><span class="pageNumber"></span> / '
                    '<span class="totalPages"></span></div>'
                ),
                "margin": {
                    "top": "0.6cm",
                    "right": "0.7cm",
                    "bottom": "1.0cm",
                    "left": "0.7cm",
                },
            }

            has_mermaid = 'class="mermaid"' in html_content
            has_katex = "auto-render.min.js" in html_content
            # Playwright requires a URL; derived from project-local HTML only.
            goto_url = html_path.resolve().as_uri()

            async with async_playwright() as p:
                browser = await p.chromium.launch()
                page = await browser.new_page()
                await page.goto(goto_url)
                if has_mermaid:
                    await page.wait_for_function(
                        """() => window.__ascMermaidDone === true""",
                        timeout=60000,
                    )
                    await page.wait_for_function(
                        """() => {
                          const nodes = [...document.querySelectorAll('.mermaid')];
                          return nodes.length === 0
                            || nodes.every(n => n.querySelector('svg'));
                        }""",
                        timeout=60000,
                    )
                if has_katex:
                    await page.wait_for_function(
                        """() => window.__ascKatexDone === true""",
                        timeout=60000,
                    )
                    # Ensure KaTeX webfonts are applied before print.
                    await page.evaluate(
                        """async () => {
                          if (document.fonts && document.fonts.ready) {
                            await document.fonts.ready;
                          }
                        }"""
                    )
                elif not has_mermaid:
                    await page.wait_for_load_state("networkidle")
                await page.pdf(**pdf_options)
                await browser.close()

            return True
        except Exception as e:
            print(f"Error converting HTML to PDF: {e}")
            import traceback

            traceback.print_exc()
            return False

    hr.html_to_pdf_playwright = html_to_pdf_playwright


def render_html(source_md: Path, project_root: Path | None = None,
                enable_mermaid: bool = True, title: str | None = None) -> str:
    """Render markdown to styled HTML (sets print path for relative assets)."""
    global _CURRENT_SOURCE_MD, _PROJECT_ROOT, _PRINT_HTML_PATH

    source_md = source_md.resolve()
    root = (project_root or find_project_root(source_md)).resolve()
    html_path = print_html_path_for(source_md, root)

    patch_html_renderer()
    from md2pdf.html_renderer import markdown_to_html

    _CURRENT_SOURCE_MD = source_md
    _PROJECT_ROOT = root
    _PRINT_HTML_PATH = html_path
    try:
        md = source_md.read_text(encoding="utf-8")
        return markdown_to_html(
            md, title=title or source_md.stem, enable_mermaid=enable_mermaid
        )
    finally:
        _CURRENT_SOURCE_MD = None
        _PROJECT_ROOT = None
        _PRINT_HTML_PATH = None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="ASC Spectral / Source Code Pro–styled Markdown→PDF"
    )
    parser.add_argument("input", help="Input Markdown file")
    parser.add_argument("-o", "--output", required=True, help="Output PDF path")
    parser.add_argument("--title", default=None, help="Document title")
    parser.add_argument("--no-mermaid", action="store_true")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    if not input_path.is_file():
        print(f"File not found: {input_path}", file=sys.stderr)
        return 1

    require_mermaid_vendor()
    require_katex_vendor()

    if Path.home().joinpath(".cache/ms-playwright").is_dir():
        os.environ.setdefault(
            "PLAYWRIGHT_BROWSERS_PATH",
            str(Path.home() / ".cache/ms-playwright"),
        )

    global _CURRENT_SOURCE_MD, _PROJECT_ROOT, _PRINT_HTML_PATH
    patch_html_renderer()
    from md2pdf.html_renderer import convert_markdown_to_pdf_html

    _CURRENT_SOURCE_MD = input_path.resolve()
    _PROJECT_ROOT = find_project_root(_CURRENT_SOURCE_MD)
    _PRINT_HTML_PATH = print_html_path_for(_CURRENT_SOURCE_MD, _PROJECT_ROOT)

    markdown_content = input_path.read_text(encoding="utf-8")
    title = args.title or input_path.stem
    print(f"Converting {input_path} to PDF...")
    print(
        f"  (ASC style: {FONT_FAMILY} + {MONO_FONT_FAMILY} + compact 8pt; "
        f"Mermaid local {MERMAID_VENDOR.relative_to(_PROJECT_ROOT)}; "
        f"KaTeX local {KATEX_VENDOR.relative_to(_PROJECT_ROOT)}; "
        "local images rewritten for print HTML)"
    )
    try:
        result = convert_markdown_to_pdf_html(
            markdown_content,
            str(output_path),
            title=title,
            page_size="A4",
            orientation="portrait",
            enable_mermaid=not args.no_mermaid,
        )
    finally:
        _CURRENT_SOURCE_MD = None
        _PROJECT_ROOT = None
        _PRINT_HTML_PATH = None

    if not result.get("success"):
        print(f"[FAIL] {result.get('error', 'unknown error')}", file=sys.stderr)
        return 1
    size_kb = output_path.stat().st_size / 1024
    print(f"[OK] PDF created: {output_path} ({size_kb:.1f} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
