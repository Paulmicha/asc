"""Graphviz fences → inline SVG (string-time, before Markdown)."""

from __future__ import annotations

import html as html_lib
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

GRAPHVIZ_FENCE_LANGS = frozenset(
    {"dot", "graphviz", "neato", "fdp", "sfdp", "circo", "twopi"}
)
GRAPHVIZ_FENCE_ALIASES = {"graphviz": "dot"}
GRAPHVIZ_ENGINES = ("dot", "neato", "fdp", "sfdp", "circo", "twopi")
GRAPHVIZ_TIMEOUT_SEC = 30

SVG_NS = "http://www.w3.org/2000/svg"
XLINK_NS = "http://www.w3.org/1999/xlink"
_FONT = '"Source Sans 3", system-ui, sans-serif'

_FENCE = re.compile(
    r"(?m)^```([^\n]*)\n(.*?)^```\s*$",
    re.DOTALL,
)
_URL_HASH = re.compile(r"url\(#([^)]+)\)")
_CSS_HASH = re.compile(r"#([A-Za-z_][\w.-]*)")
_XML_DECL = re.compile(r"<\?xml[^?]*\?>", re.I)
_DOCTYPE = re.compile(r"<!DOCTYPE[\s\S]*?>", re.I)


class GraphvizError(RuntimeError):
    """dot missing, non-zero, timeout, or empty SVG."""


def graphviz_engine_for(info: str) -> str | None:
    """First info-string token → engine, or None if not a Graphviz fence."""
    token = (info or "").strip().split(None, 1)
    if not token:
        return None
    name = token[0].lower()
    if name in GRAPHVIZ_FENCE_ALIASES:
        return GRAPHVIZ_FENCE_ALIASES[name]
    if name in GRAPHVIZ_ENGINES:
        return name
    return None


def iter_graphviz_fences(md: str) -> list[tuple[int, int, str, str]]:
    """List of (start, end, engine, source) for non-indented fences. end is exclusive."""
    found: list[tuple[int, int, str, str]] = []
    for match in _FENCE.finditer(md):
        if match.start() > 0 and md[match.start() - 1] not in "\n":
            continue
        engine = graphviz_engine_for(match.group(1))
        if engine is None:
            continue
        found.append((match.start(), match.end(), engine, match.group(2)))
    return found


def _local(tag: str) -> str:
    if tag.startswith("{") and "}" in tag:
        return tag.split("}", 1)[1]
    return tag


def _prefix_url_hash(value: str, id_prefix: str) -> str:
    def repl(match: re.Match[str]) -> str:
        ident = match.group(1)
        if ident.startswith(id_prefix):
            return match.group(0)
        return f"url(#{id_prefix}{ident})"

    return _URL_HASH.sub(repl, value)


def _prefix_fragment(value: str, id_prefix: str) -> str:
    if value.startswith("#") and not value[1:].startswith(id_prefix):
        return "#" + id_prefix + value[1:]
    return value


def _rewrite_style_text(css: str, id_prefix: str) -> str:
    css = css.replace("<![CDATA[", "").replace("]]>", "")
    css = re.sub(r"<!--.*?-->", "", css, flags=re.S)
    css = _prefix_url_hash(css, id_prefix)

    def hash_repl(match: re.Match[str]) -> str:
        ident = match.group(1)
        if ident.startswith(id_prefix):
            return match.group(0)
        return f"#{id_prefix}{ident}"

    css = _CSS_HASH.sub(hash_repl, css)

    def rule(match: re.Match[str]) -> str:
        sel, body = match.group(1).strip(), match.group(2)
        if not sel:
            return match.group(0)
        parts: list[str] = []
        for raw in sel.split(","):
            piece = raw.strip()
            if not piece:
                continue
            if piece.startswith(".graphviz-wrap"):
                parts.append(piece)
            else:
                parts.append(f".graphviz-wrap {piece}")
        return ",".join(parts) + "{" + body + "}"

    return re.sub(r"([^{}]+)\{([^{}]*)\}", rule, css)


def _rewrite_element(el: ET.Element, id_prefix: str) -> None:
    attrib = dict(el.attrib)
    for key, value in attrib.items():
        local = _local(key)
        if local == "id" and value and not value.startswith(id_prefix):
            el.set(key, id_prefix + value)
            continue
        if "url(#" in value:
            el.set(key, _prefix_url_hash(value, id_prefix))
            continue
        if local in {"href", "xlink:href"} or key == f"{{{XLINK_NS}}}href":
            el.set(key, _prefix_fragment(value, id_prefix))
            continue
        if local == "font-family":
            el.set(key, _FONT)

    if _local(el.tag) == "style" and el.text:
        el.text = _rewrite_style_text(el.text, id_prefix)
    if _local(el.tag) == "style" and el.tail:
        pass


def sanitize_graphviz_svg(svg: str, id_prefix: str) -> str:
    """ElementTree XML → inline <svg>; rewrite fonts; prefix ids and url(#); scope <style>."""
    cleaned = _DOCTYPE.sub("", _XML_DECL.sub("", svg), count=1).strip()
    if "<svg" not in cleaned.lower():
        raise GraphvizError("Graphviz produced no SVG")
    ET.register_namespace("", SVG_NS)
    ET.register_namespace("xlink", XLINK_NS)
    root = ET.fromstring(cleaned)
    if _local(root.tag) != "svg":
        raise GraphvizError("Graphviz produced no SVG")

    for parent in list(root.iter()):
        for child in list(parent):
            if _local(child.tag) == "script":
                parent.remove(child)

    for el in root.iter():
        _rewrite_element(el, id_prefix)

    raw = ET.tostring(root, encoding="unicode")
    raw = re.sub(r">\s+<", "><", raw)
    raw = raw.replace("\n", " ").replace("\r", "")
    return raw


def render_dot_svg(
    source: str,
    engine: str,
    *,
    timeout: int = GRAPHVIZ_TIMEOUT_SEC,
    runner=None,
    which_dot=None,
) -> str:
    """Run ``dot -K<engine> -Tsvg``. Raise GraphvizError on missing binary / non-zero / timeout / empty SVG."""
    if engine not in GRAPHVIZ_ENGINES:
        raise GraphvizError(f"unsupported Graphviz engine: {engine}")
    which = which_dot or shutil.which
    binary = which("dot")
    if not binary:
        raise GraphvizError(
            "Graphviz 'dot' is not on PATH. Install with: sudo apt install graphviz"
        )
    run = runner or (
        lambda argv, input, timeout: subprocess.run(
            argv,
            input=input,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
    )
    try:
        proc = run([binary, f"-K{engine}", "-Tsvg"], source.encode("utf-8"), timeout)
    except subprocess.TimeoutExpired as exc:
        raise GraphvizError(f"Graphviz timed out after {timeout}s") from exc
    if proc.returncode != 0:
        err_raw = proc.stderr
        if isinstance(err_raw, (bytes, bytearray)):
            err = err_raw.decode("utf-8", "replace").strip()
        else:
            err = (err_raw or "").strip()
        raise GraphvizError(err or f"exit {proc.returncode}")
    out_raw = proc.stdout
    if isinstance(out_raw, (bytes, bytearray)):
        svg = out_raw.decode("utf-8", "replace")
    else:
        svg = out_raw or ""
    if "<svg" not in svg.lower():
        raise GraphvizError("Graphviz produced no SVG")
    return svg


def _error_block(engine: str, source: str, exc: BaseException) -> str:
    body = html_lib.escape(f"Graphviz ({engine}) failed: {exc}\n\n{source}")
    return (
        f'<pre class="graphviz-error" data-asc-gv-engine="{html_lib.escape(engine, quote=True)}">'
        f"{body}</pre>"
    )


def _wrap_svg(engine: str, svg: str) -> str:
    return (
        f'<div class="graphviz-wrap" data-asc-gv-engine="{html_lib.escape(engine, quote=True)}">'
        f"{svg}</div>"
    )


def render_graphviz_fences(md: str, *, runner=None, which_dot=None) -> str:
    """Replace Graphviz fences with .graphviz-wrap (or .graphviz-error). Never raises GraphvizError."""
    fences = iter_graphviz_fences(md)
    if not fences:
        return md
    out = md
    for index, (start, end, engine, source) in enumerate(reversed(fences)):
        n = len(fences) - 1 - index
        try:
            raw = render_dot_svg(
                source, engine, runner=runner, which_dot=which_dot
            )
            svg = sanitize_graphviz_svg(raw, f"gv{n}-")
            replacement = _wrap_svg(engine, svg)
        except GraphvizError as exc:
            print(
                f"warning: graphviz fence {n + 1} failed: {exc}",
                file=sys.stderr,
            )
            replacement = _error_block(engine, source, exc)
        out = out[:start] + replacement + out[end:]
    return out
