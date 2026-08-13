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
no CDN). Printable HTML is written under data/tmp/ so Mermaid and fonts
load via relative paths. Markdown hrefs are left as authored.

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


def patch_html_renderer() -> None:
    import md2pdf.html_renderer as hr

    patch_mermaid_as_html()

    orig = hr.markdown_to_html

    def markdown_to_html(markdown_text: str, title: str = "Document",
                         enable_mermaid: bool = True) -> str:
        html = orig(markdown_text, title=title, enable_mermaid=enable_mermaid)
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
        if enable_mermaid and 'class="mermaid"' in html2:
            if "</body>" not in html2:
                raise RuntimeError("HTML missing </body>; cannot inject Mermaid")
            html2 = html2.replace(
                "</body>", mermaid_boot_script(html_path) + "</body>", 1
            )
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
                else:
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
        "links as authored)"
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
