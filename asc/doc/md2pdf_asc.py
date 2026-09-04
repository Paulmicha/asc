#!/usr/bin/env python3
"""
ASC-styled md2pdf wrapper (Spectral + Source Code Pro + compact type).

Pipeline (do not reorder; pagination is last):
  protect math → markdown → restore math → explode code lines → inject CSS/boot
  → write HTML → fonts → Mermaid → KaTeX → emulate print → mark long paras
  → paginate orphans/widows → page.pdf
  Preview stops before paginate.

Usage:
  asc/doc/md2pdf_asc.py input.md -o output.pdf
  asc/doc/md2pdf_asc.py input.md -o output.pdf --no-paginate
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from pathlib import Path

from print_code import explode_pre_code_lines
from print_katex import (
    KATEX_RUN_JS,
    html_has_katex,
    katex_assets_html,
    protect_katex_math,
    restore_katex_math,
)
from print_mermaid import (
    inject_mermaid_candidates,
    mermaid_run_js,
    mermaid_vendor_tag,
    patch_mermaid_as_html,
)
from print_paginate import (
    ASC_MARK_LONG_PARAS_FN,
    MARK_LONG_PARAS_JS,
    apply_print_pushes,
    content_height_px,
    content_width_px,
)

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
SANS_DIR = FONTS_DIR / "SourceSans3"
SANS_FAMILY = "Source Sans 3"
SANS_FILES = {
    "regular": "SourceSans3-Regular.ttf",
    "bold": "SourceSans3-Bold.ttf",
    "italic": "SourceSans3-Italic.ttf",
    "bold_italic": "SourceSans3-BoldItalic.ttf",
}
MERMAID_VENDOR = ASC_DIR / "vendor" / "mermaid.esm.min.mjs"
KATEX_VENDOR = ASC_DIR / "vendor" / "katex"
KATEX_FILES = ("katex.min.css", "katex.min.js", "auto-render.min.js")

# Paths for the current conversion (relative Mermaid/font URLs).
_CURRENT_SOURCE_MD: Path | None = None
_PROJECT_ROOT: Path | None = None
_PRINT_HTML_PATH: Path | None = None
_NO_PAGINATE = False

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


def display_path(path: Path, *roots: Path) -> str:
    """Path relative to the first matching root; otherwise the absolute path."""
    resolved = path.resolve()
    for root in roots:
        try:
            return resolved.relative_to(root.resolve()).as_posix()
        except ValueError:
            continue
    return str(resolved)


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
    sans_map = [
        ("regular", "normal", "normal"),
        ("bold", "normal", "bold"),
        ("italic", "italic", "normal"),
        ("bold_italic", "italic", "bold"),
    ]
    sans_regular = SANS_DIR / SANS_FILES["regular"]
    if sans_regular.is_file():
        for key, font_style, font_weight in sans_map:
            sp = SANS_DIR / SANS_FILES[key]
            if not sp.is_file():
                sp = sans_regular
            rules.append(
                f"""@font-face {{
  font-family: "{SANS_FAMILY}";
  font-style: {font_style};
  font-weight: {font_weight};
  src: url("{url(sp)}") format("truetype");
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



def layout_boot_script(html_path: Path, has_mermaid: bool, has_katex: bool) -> str:
    """Single ordered boot: fonts → Mermaid → KaTeX → (preview) para-mark."""
    parts: list[str] = []
    if has_mermaid:
        parts.append(mermaid_vendor_tag(rel_url(html_path, require_mermaid_vendor())))
    if has_katex:
        katex_dir = require_katex_vendor()
        parts.append(
            katex_assets_html(
                rel_url(html_path, katex_dir / "katex.min.css"),
                rel_url(html_path, katex_dir / "katex.min.js"),
                rel_url(html_path, katex_dir / "auto-render.min.js"),
            )
        )
    mermaid_js = (
        mermaid_run_js(content_width_px(), content_height_px())
        if has_mermaid
        else "async function ascRunMermaid() {}\n"
    )
    katex_js = KATEX_RUN_JS if has_katex else "async function ascRunKatex() {}\n"
    parts.append(
        f"""<script>
{mermaid_js}
{katex_js}
{ASC_MARK_LONG_PARAS_FN}
async function ascLayoutBoot() {{
  try {{
    if (document.fonts && document.fonts.ready) await document.fonts.ready;
  }} catch (e) {{}}
  await ascRunMermaid();
  await ascRunKatex();
  if (!window.__ascPdfDriver) {{
    ascMarkLongParagraphs();
  }}
  window.__ascLayoutReady = true;
}}
ascLayoutBoot().catch(function (err) {{
  console.error('ascLayoutBoot failed', err);
  window.__ascLayoutReady = true;
}});
</script>
"""
    )
    return "".join(parts)



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


# Chromium writes HTML ids as PDF name dests. PDF 1.4 names max 127 bytes.
PDF_DEST_NAME_MAX = 120


def shorten_html_ids(html: str, max_len: int = PDF_DEST_NAME_MAX) -> str:
    """Truncate heading ids / fragment hrefs so PDF name tokens stay legal."""
    found = re.findall(r'\bid="([^"]+)"', html)
    mapping: dict[str, str] = {}
    taken = set(found)
    for old in found:
        if old in mapping:
            continue
        if len(old.encode("utf-8")) <= max_len:
            mapping[old] = old
            continue
        digest = hashlib.sha1(old.encode("utf-8")).hexdigest()[:8]
        budget = max(8, max_len - 9)
        stem = old.encode("utf-8")[:budget].decode("utf-8", "ignore").rstrip("-")
        new = f"{stem}-{digest}"
        n = 2
        while new in taken:
            new = f"{stem}-{digest}{n}"
            n += 1
        mapping[old] = new
        taken.add(new)
    for old, new in sorted(mapping.items(), key=lambda kv: -len(kv[0])):
        if old == new:
            continue
        html = html.replace(f'id="{old}"', f'id="{new}"')
        html = html.replace(f"id='{old}'", f"id='{new}'")
        html = html.replace(f'href="#{old}"', f'href="#{new}"')
        html = html.replace(f"href='#{old}'", f"href='#{new}'")
    return html


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
        html = explode_pre_code_lines(html)
        html = inject_mermaid_candidates(html)
        html = shorten_html_ids(html)
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
        has_mermaid = bool(enable_mermaid and 'class="mermaid"' in html2)
        has_katex = html_has_katex(html2)
        boot = layout_boot_script(html_path, has_mermaid, has_katex)
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

            # Playwright requires a URL; derived from project-local HTML only.
            goto_url = html_path.resolve().as_uri()

            async with async_playwright() as p:
                browser = await p.chromium.launch()
                page = await browser.new_page()
                # PIPELINE PDF: wait layout → emulate print → mark paras → paginate → pdf
                await page.add_init_script("window.__ascPdfDriver = true")
                await page.set_viewport_size(
                    {
                        "width": max(1, round(content_width_px())),
                        "height": max(1, round(content_height_px())),
                    }
                )
                await page.goto(goto_url)
                await page.wait_for_function(
                    "window.__ascLayoutReady === true",
                    timeout=120000,
                )
                failed = await page.evaluate(
                    "() => window.__ascMermaidFailed || []"
                )
                if failed:
                    print(
                        f"warning: {len(failed)} Mermaid diagram(s) left as source "
                        f"(#{', #'.join(str(n) for n in failed)})",
                        file=sys.stderr,
                    )
                await page.emulate_media(media="print")
                await page.evaluate(MARK_LONG_PARAS_JS)
                if not _NO_PAGINATE:
                    inserted = await apply_print_pushes(page, pdf_options)
                    print(f"  print pushes: {inserted}")
                err_n = await page.evaluate(
                    "() => document.querySelectorAll('.katex-error').length"
                )
                if err_n:
                    print(
                        f"warning: {err_n} KaTeX error span(s)",
                        file=sys.stderr,
                    )
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
    parser.add_argument(
        "--no-paginate",
        action="store_true",
        help="Skip heading/table <br> pagination (debug only)",
    )
    args = parser.parse_args()

    global _NO_PAGINATE
    _NO_PAGINATE = bool(args.no_paginate)

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
        f"  (ASC style: {FONT_FAMILY} + {MONO_FONT_FAMILY} + 9pt body; "
        f"Mermaid local {display_path(MERMAID_VENDOR, _PROJECT_ROOT, PROJECT_ROOT_DEFAULT)}; "
        f"KaTeX local {display_path(KATEX_VENDOR, _PROJECT_ROOT, PROJECT_ROOT_DEFAULT)}; "
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
